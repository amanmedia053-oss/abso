# Adabi Khazana Telegram API

FastAPI service for receiving new channel posts and serving poems in cursor-based pages of 20.

## Required environment variables

Set these privately in the hosting dashboard. Never commit real tokens or passwords.

- `DATABASE_URL`: managed PostgreSQL connection string (persistent database).
- `TELEGRAM_BOT_TOKEN`: a newly generated bot token.
- `TELEGRAM_WEBHOOK_SECRET`: random secret used to authenticate Telegram webhook calls.
- `ADMIN_SETUP_KEY`: separate random secret for one-time webhook setup.
- `CHANNEL_USERNAME`: public channel username without @ (default: pashto_Novel).
- `PUBLIC_BASE_URL`: deployed service URL, without trailing slash.

## Run

```bash
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Deploy

Create a Python web service from this repository with root directory `backend`, build command `pip install -r requirements.txt`, and start command `uvicorn main:app --host 0.0.0.0 --port $PORT`. Attach a persistent managed PostgreSQL database and set its connection string as `DATABASE_URL`.

After deployment, add the bot as an administrator of the public channel with permission to read channel posts. Then call `POST /admin/set-webhook` with header `X-Admin-Key: <ADMIN_SETUP_KEY>` once.

## API

- `GET /health`
- `GET /poems?limit=20` — newest 20.
- `GET /poems?limit=20&before_id=<next_cursor>` — next page.
- `POST /telegram/webhook` — Telegram channel updates.

The Bot API delivers new channel posts to the bot; it does not provide a general history-reading endpoint for old channel posts. Database paging is stable and avoids duplicates.
