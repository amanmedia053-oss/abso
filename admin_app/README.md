# ادبي خزانه — Admin App

دا د اډمین جلا Flutter اپ دی، د اصلي اپ تر څنګ په همدې repository کې ساتل شوی.

## Android package
`Com.obaidapp.arwapoh`

## Firebase setup
1. د اپلوډ شوي Firebase فایل له مخې د اډمین package نوم `Com.obaidapp.arwapoh` دی.
2. د همدې package لپاره د `google-services.json` فایل د Android اپ په `android/app/` فولډر کې کېږدئ.
3. د Realtime Database او Storage فعالول، او Email/Password Authentication فعالول.
4. د Firebase Authentication له لارې اډمین حساب جوړ کړئ.
5. د هماغه حساب UID په `admins/{uid}` کې د `{ "role": "admin" }` په بڼه ثبت کړئ.

د کاروونکي اپ package نوم `com.obaidapp.soraerahman` دی؛ د اډمین اپ package نوم `Com.obaidapp.arwapoh` دی. په اپلوډ شوي فایل کې دواړه Firebase clients موجود دي، نو د Google Services plugin د package له مخې سم client ټاکي.

## د شعر ثبتولو قواعد
- د شعر متن او کټګوري حتمي دي.
- عنوان، شاعر او انځور اختیاري دي.
- د ثبت نېټه د Realtime Database server timestamp ده.
- انځورونه Firebase Storage ته پورته کېږي؛ URL یې Realtime Database کې ساتل کېږي.

## Build
```bash
cd admin_app
flutter pub get
flutter create --platforms=android --project-name adabi_khazana_admin .
# په android/app/build.gradle(.kts) کې applicationId او namespace د پورته اډمین package سره برابر کړئ.
flutter build apk --release
```

د امنیت لپاره د Realtime Database او Storage rules باید د اډمین UID وڅېړي؛ یوازې د اپ د login سکرین امنیت نه شي تضمینولای.
