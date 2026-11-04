# ادبي خزانه — Admin App

دا د اډمین جلا Flutter اپ دی، د اصلي اپ تر څنګ په همدې repository کې ساتل شوی.

## Android package
`com.obaidapp.adabikhazana.admin`

## Firebase setup
1. په Firebase Console کې د همدې package لپاره جلا Android app ثبت کړئ.
2. د هغې app ځانګړی `google-services.json` په `admin_app/android/app/google-services.json` کې کېږدئ.
3. د Realtime Database او Storage فعالول، او Email/Password Authentication فعالول.
4. د Firebase Authentication له لارې اډمین حساب جوړ کړئ.
5. د هماغه حساب UID په `admins/{uid}` کې د `{ "role": "admin" }` په بڼه ثبت کړئ.

اصلي اپ او اډمین اپ باید خپل خپل package IDs او Google Services config ولري. د اډمین اپ ته د اصلي اپ config مه کاروئ.

## د شعر ثبتولو قواعد
- د شعر متن او کټګوري حتمي دي.
- عنوان، شاعر او انځور اختیاري دي.
- د ثبت نېټه د Realtime Database server timestamp ده.
- انځورونه Firebase Storage ته پورته کېږي؛ URL یې Realtime Database کې ساتل کېږي.

## Build
```bash
cd admin_app
flutter pub get
flutter create --platforms=android --org com.obaidapp --project-name adabi_khazana_admin .
flutter build apk --release
```

د امنیت لپاره د Realtime Database او Storage rules باید د اډمین UID وڅېړي؛ یوازې د اپ د login سکرین امنیت نه شي تضمینولای.
