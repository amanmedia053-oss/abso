import os
import re
import secrets
from contextlib import asynccontextmanager
from typing import Optional

import httpx
from fastapi import FastAPI, Header, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from psycopg_pool import ConnectionPool
from psycopg.rows import dict_row

DATABASE_URL = os.environ["DATABASE_URL"]
BOT_TOKEN = os.environ["TELEGRAM_BOT_TOKEN"]
CHANNEL_USERNAME = os.getenv("CHANNEL_USERNAME", "pashto_Novel").lstrip("@").lower()
WEBHOOK_SECRET = os.environ["TELEGRAM_WEBHOOK_SECRET"]
ADMIN_SETUP_KEY = os.environ["ADMIN_SETUP_KEY"]
PUBLIC_BASE_URL = os.getenv("PUBLIC_BASE_URL", "").rstrip("/")

if DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

pool = ConnectionPool(DATABASE_URL, kwargs={"row_factory": dict_row}, open=False)


def init_db():
    with pool.connection() as conn:
        conn.execute("""
            CREATE TABLE IF NOT EXISTS poems (
                id BIGSERIAL PRIMARY KEY,
                channel_message_id BIGINT NOT NULL UNIQUE,
                title TEXT NOT NULL DEFAULT '',
                body TEXT NOT NULL,
                author TEXT NOT NULL DEFAULT '',
                published_at TIMESTAMPTZ,
                created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
            )
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS poems_published_idx ON poems (id DESC)")
        conn.commit()


@asynccontextmanager
async def lifespan(app: FastAPI):
    pool.open()
    init_db()
    yield
    pool.close()


app = FastAPI(title="Adabi Khazana API", version="1.0.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


def parse_poem(message: dict) -> Optional[dict]:
    text = (message.get("text") or message.get("caption") or "").strip()
    if not text:
        return None
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    title = lines[0][:180] if lines else "شعر"
    author = ""
    if lines and re.match(r"^(#|ـ{2,}|[-–—])", lines[-1]):
        author = lines[-1].lstrip("#ـ-–— ").strip()[:120]
    chat = message.get("chat") or {}
    username = (chat.get("username") or "").lower()
    if username != CHANNEL_USERNAME:
        return None
    return {
        "message_id": int(message["message_id"]),
        "title": title,
        "body": text,
        "author": author,
        "published_at": message.get("date"),
    }


def save_message(message: dict):
    poem = parse_poem(message)
    if poem is None:
        return
    with pool.connection() as conn:
        conn.execute(
            """
            INSERT INTO poems (channel_message_id, title, body, author, published_at)
            VALUES (%s, %s, %s, %s, to_timestamp(%s))
            ON CONFLICT (channel_message_id) DO UPDATE SET
              title = EXCLUDED.title,
              body = EXCLUDED.body,
              author = EXCLUDED.author
            """,
            (poem["message_id"], poem["title"], poem["body"],
             poem["author"], poem["published_at"]),
        )
        conn.commit()


@app.get("/health")
def health():
    return {"ok": True, "service": "adabi-khazana-api"}


@app.get("/poems")
def get_poems(
    limit: int = Query(20, ge=1, le=50),
    before_id: Optional[int] = Query(None, ge=1),
):
    with pool.connection() as conn:
        if before_id is None:
            rows = conn.execute(
                "SELECT id, title, body, author, published_at FROM poems ORDER BY id DESC LIMIT %s",
                (limit,),
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT id, title, body, author, published_at FROM poems WHERE id < %s ORDER BY id DESC LIMIT %s",
                (before_id, limit),
            ).fetchall()
    next_cursor = rows[-1]["id"] if len(rows) == limit else None
    return {"items": rows, "next_cursor": next_cursor, "has_more": next_cursor is not None}


@app.post("/telegram/webhook")
async def telegram_webhook(
    request: Request,
    x_telegram_bot_api_secret_token: Optional[str] = Header(None),
):
    if not x_telegram_bot_api_secret_token or not secrets.compare_digest(
        x_telegram_bot_api_secret_token, WEBHOOK_SECRET
    ):
        raise HTTPException(status_code=403, detail="Invalid webhook secret")
    update = await request.json()
    message = update.get("channel_post") or update.get("edited_channel_post")
    if message:
        save_message(message)
    return {"ok": True}


@app.post("/admin/set-webhook")
async def set_webhook(x_admin_key: Optional[str] = Header(None)):
    if not x_admin_key or not secrets.compare_digest(x_admin_key, ADMIN_SETUP_KEY):
        raise HTTPException(status_code=403, detail="Forbidden")
    if not PUBLIC_BASE_URL:
        raise HTTPException(status_code=500, detail="PUBLIC_BASE_URL is not configured")
    url = f"{PUBLIC_BASE_URL}/telegram/webhook"
    async with httpx.AsyncClient(timeout=20) as client:
        response = await client.post(
            f"https://api.telegram.org/bot{BOT_TOKEN}/setWebhook",
            json={
                "url": url,
                "secret_token": WEBHOOK_SECRET,
                "allowed_updates": ["channel_post", "edited_channel_post"],
                "drop_pending_updates": False,
            },
        )
        response.raise_for_status()
        return response.json()
