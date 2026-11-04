# ادبي خزانه

د پښتو شعرونو او ادب لپاره Flutter / Material 3 اپلیکیشن.

## د اپ ځانګړنې
- بشپړ پښتو RTL انٹرفېس او Vazirmatn فونټ
- Splash او متحرک Onboarding
- Material 3، شین ـ طلایي رنګونه، Light او Dark بڼه
- د شعرونو ژوندی لېست د Firebase Realtime Database له لارې
- د شعر بشپړ متن، کټګورۍ، شاعران او لټون
- خوښ شوي شعرونه په موبایل کې خوندي ساتل
- لایک، شریکول، لیدنې او د خوندي کولو شمېر
- د اډمین مدیریت: شعرونه، کټګورۍ او شاعران؛ شعر جوړول، سمول او ړنګول
- اختیاري عنوان، شاعر او انځور؛ د شعر متن او کټګوري حتمي دي
- About او د اپ تنظیمات

## Firebase تنظیمول

دا پروژه د Firebase پروژې arwapoh او Realtime Database لاندې پته کاروي:

https://arwapoh-default-rtdb.firebaseio.com

1. په Firebase Console کې د Android اپلیکیشن package name باید com.obaidapp.soraerahman وي.
2. د پروژې اصلي فولډر کې معتبر google-services.json وساتئ. د GitHub Actions workflow یې د Android فولډر ته کاپي کوي.
3. په Firebase Authentication کې Email/Password provider فعال کړئ او د اډمین حساب جوړ کړئ.
4. د اډمین حساب UID د Realtime Database په admins/{uid} کې داسې ثبت کړئ: { "role": "admin" }.
   دا ریکارډ یوازې د باوري Firebase Console یا Admin SDK له لارې جوړ کړئ.
5. د firebase/database.rules.json قواعد په Firebase Console کې د Realtime Database Rules برخې ته کاپي او Publish کړئ. یوازې په GitHub کې د فایل شتون قواعد نه فعالوي.
6. د انځورونو د پورته کولو لپاره د firebase/storage.rules قواعد هم په Storage کې Publish کړئ. دا قواعد د Firebase Auth custom claim admin: true غواړي؛ د اډمین حساب لپاره دا claim باید د باوري Admin SDK چاپېریال له لارې تنظیم شي. د RTDB د admins/{uid} رول په یوازې ځان Storage ته اجازه نه ورکوي. که Storage اجازه ورنه کړي، اپ شعر بې انځوره خپروي.

## جوړول

flutter pub get
flutter run

د Android APK جوړولو لپاره د GitHub Actions له لارې Build Android APK workflow وچلوئ. د بریالي Build وروسته APK د workflow په Artifacts کې وي.

## مهم یادښت

د شعرونو محتوا یوازې هغه وخت ښکاري چې اډمین یې په ډیټابېس کې خپره کړي. اپ کې نمونه یا له مخکې لیکل شوي شعرونه نشته.
