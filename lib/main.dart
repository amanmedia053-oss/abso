import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String cloudinaryCloudName = 'a3p2c6bi';
const String cloudinaryUploadPreset = 'adabi_gallery';

Future<String> uploadImageToCloudinary(XFile file) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload'),
  );
  request.fields['upload_preset'] = cloudinaryUploadPreset;
  request.files.add(http.MultipartFile.fromBytes(
    'file', await file.readAsBytes(), filename: file.name,
  ));
  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);
  final body = jsonDecode(response.body);
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final message = body is Map ? (body['error']?['message'] ?? 'Cloudinary upload failed') : 'Cloudinary upload failed';
    throw Exception(message);
  }
  final url = body is Map ? body['secure_url']?.toString() : null;
  if (url == null || url.isEmpty) throw Exception('Cloudinary did not return secure_url');
  return url;
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AbsoApp());
}

class AbsoApp extends StatefulWidget {
  const AbsoApp({super.key});
  @override
  State<AbsoApp> createState() => _AbsoAppState();
}

class _AbsoAppState extends State<AbsoApp> {
  ThemeMode mode = ThemeMode.light;
  String selectedFont = 'Vazirmatn';
  int selectedAccentValue = 0xFF245B50;

  @override
  void initState() {
    super.initState();
    _loadAppearance();
  }

  Future<void> _loadAppearance() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      mode = (prefs.getBool('dark_mode') ?? false)
          ? ThemeMode.dark : ThemeMode.light;
      selectedFont = prefs.getString('app_font') ?? 'Vazirmatn';
      selectedAccentValue = prefs.getInt('app_accent') ?? 0xFF245B50;
    });
  }

  Future<void> _setFont(String value) async {
    setState(() => selectedFont = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_font', value);
  }

  Future<void> _setAccent(Color value) async {
    setState(() => selectedAccentValue = value.toARGB32());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_accent', value.toARGB32());
  }

  Future<void> _toggleTheme() async {
    setState(() {
      mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', mode == ThemeMode.dark);
  }

  Future<void> _resetAppearance() async {
    setState(() {
      selectedFont = 'Vazirmatn';
      selectedAccentValue = 0xFF245B50;
      mode = ThemeMode.light;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_font', selectedFont);
    await prefs.setInt('app_accent', selectedAccentValue);
    await prefs.setBool('dark_mode', false);
  }

  ThemeData makeTheme(Brightness brightness) {
    final accent = Color(selectedAccentValue);
    const gold = Color(0xFFFFC857);
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: accent, brightness: brightness,
      primary: accent, secondary: gold, tertiary: const Color(0xFFE76F9A),
      surface: dark ? const Color(0xFF151725) : const Color(0xFFFFFBFF));
    final baseText = ThemeData(brightness: brightness).textTheme.apply(fontFamily: selectedFont);
    return ThemeData(
      useMaterial3: true, colorScheme: scheme, fontFamily: selectedFont,
      textTheme: baseText,
      primaryTextTheme: ThemeData(brightness: brightness).primaryTextTheme.apply(fontFamily: selectedFont),
      scaffoldBackgroundColor: dark ? const Color(0xFF10121D) : const Color(0xFFF6F4FA),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? const Color(0xFF10121D) : const Color(0xFFF6F4FA),
        surfaceTintColor: Colors.transparent, elevation: 0, centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: selectedFont, fontSize: 21,
          fontWeight: FontWeight.w900, color: scheme.onSurface),
        iconTheme: IconThemeData(color: scheme.primary)),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF1B1E2D) : Colors.white, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .42)))),
      listTileTheme: ListTileThemeData(iconColor: scheme.primary,
        titleTextStyle: TextStyle(fontFamily: selectedFont, fontSize: 14,
          fontWeight: FontWeight.w800, color: scheme.onSurface),
        subtitleTextStyle: TextStyle(fontFamily: selectedFont, fontSize: 11,
          height: 1.6, color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5)),
      navigationBarTheme: NavigationBarThemeData(height: 76,
        backgroundColor: dark ? const Color(0xFF1B1E2D) : Colors.white,
        surfaceTintColor: Colors.transparent, indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontFamily: selectedFont,
          fontSize: 10, fontWeight: FontWeight.w700))),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(dark ? const Color(0xFF202436) : Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(19),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)))),
        textStyle: WidgetStatePropertyAll(TextStyle(fontFamily: selectedFont, fontSize: 13)),
        hintStyle: WidgetStatePropertyAll(TextStyle(fontFamily: selectedFont, fontSize: 12,
          color: scheme.onSurfaceVariant))),
      chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        labelStyle: TextStyle(fontFamily: selectedFont, fontSize: 12)),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: .5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final systemBarColor = mode == ThemeMode.dark
        ? const Color(0xFF111715)
        : const Color(0xFFF7F5EF);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: systemBarColor,
      systemNavigationBarColor: systemBarColor,
      statusBarIconBrightness:
          mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness:
          mode == ThemeMode.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarDividerColor: systemBarColor,
    ));
    return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ادبي خزانه | د شعرونو نړۍ',
    theme: makeTheme(Brightness.light),
    darkTheme: makeTheme(Brightness.dark),
    themeMode: mode,
    home: LaunchGate(
      appBuilder: () => AuthGate(
        child: PoetryShell(
          isDark: mode == ThemeMode.dark,
          fontName: selectedFont,
          accentColor: Color(selectedAccentValue),
          onTheme: _toggleTheme,
          onFontChanged: _setFont,
          onAccentChanged: _setAccent,
          onResetAppearance: _resetAppearance,
        ),
      ),
    ),
    );
  }
}


class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      if (user != null) return child;
      return const AccountAccessPage();
    },
  );
}

class AccountAccessPage extends StatefulWidget {
  const AccountAccessPage({super.key});
  @override
  State<AccountAccessPage> createState() => _AccountAccessPageState();
}

class _AccountAccessPageState extends State<AccountAccessPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();
  final otp = TextEditingController();
  XFile? profileImage;
  String? uploadedProfileUrl;
  bool create = true, busy = false, codeSent = false;
  String? verificationId, error;

  @override
  void dispose() {
    name.dispose(); email.dispose(); password.dispose(); phone.dispose(); otp.dispose();
    super.dispose();
  }

  Future<void> _saveName(User user) async {
    final entered = name.text.trim();
    if (profileImage != null) uploadedProfileUrl = await uploadImageToCloudinary(profileImage!);
    final display = entered.isNotEmpty ? entered : (user.displayName ?? user.email?.split('@').first ?? 'لوستونکی');
    await user.updateDisplayName(display);
    await FirebaseDatabase.instance.ref('profiles/${user.uid}').update({
      'displayName': display, 'email': user.email ?? '', 'phoneNumber': user.phoneNumber ?? '',
      if (uploadedProfileUrl != null) 'photoUrl': uploadedProfileUrl,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> _run(Future<UserCredential> Function() action) async {
    setState(() { busy = true; error = null; });
    try {
      final result = await action();
      if (result.user != null) await _saveName(result.user!);
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'حساب ته ننوتل بریالي نه شول.');
    } catch (e) {
      setState(() => error = 'ستونزه رامنځته شوه: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _emailAuth() async {
    if (email.text.trim().isEmpty || password.text.length < 6 ||
        (create && name.text.trim().isEmpty)) {
      setState(() => error = create
          ? 'نوم، سم ایمیل او لږ تر لږه ۶ توري پټنوم ولیکئ.'
          : 'سم ایمیل او لږ تر لږه ۶ توري پټنوم ولیکئ.');
      return;
    }
    await _run(() async {
      final credential = create
        ? await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email.text.trim(), password: password.text)
        : await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email.text.trim(), password: password.text);
      return credential;
    });
  }

  Future<void> _continueAsGuest() async {
    setState(() { busy = true; error = null; });
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = e.message ?? 'د مېلمه ننوتل ناکام شول.');
    } catch (e) {
      if (mounted) setState(() => error = 'ستونزه: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _googleAuth() async {
    await _run(() async {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) throw FirebaseAuthException(code: 'cancelled', message: 'ننوتل لغوه شول.');
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      final current = FirebaseAuth.instance.currentUser;
      if (current?.isAnonymous == true) return current!.linkWithCredential(credential);
      return FirebaseAuth.instance.signInWithCredential(credential);
    });
  }

  Future<void> _phoneAuth() async {
    if (phone.text.trim().isEmpty) {
      setState(() => error = 'د هېواد له کوډ سره د ټیلیفون شمېره ولیکئ.');
      return;
    }
    setState(() { busy = true; error = null; });
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone.text.trim(),
      verificationCompleted: (credential) async {
        try {
          final current = FirebaseAuth.instance.currentUser;
          final result = current?.isAnonymous == true
              ? await current!.linkWithCredential(credential)
              : await FirebaseAuth.instance.signInWithCredential(credential);
          if (result.user != null) await _saveName(result.user!);
        } catch (e) { if (mounted) setState(() => error = '$e'); }
        finally { if (mounted) setState(() => busy = false); }
      },
      verificationFailed: (e) {
        if (mounted) setState(() { busy = false; error = e.message ?? 'د شمېرې تایید ناکام شو.'; });
      },
      codeSent: (id, _) {
        if (mounted) setState(() { verificationId = id; codeSent = true; busy = false; });
      },
      codeAutoRetrievalTimeout: (id) {
        verificationId = id;
      },
    );
  }

  Future<void> _verifyCode() async {
    final id = verificationId;
    if (id == null || otp.text.trim().isEmpty) return;
    final credential = PhoneAuthProvider.credential(
      verificationId: id, smsCode: otp.text.trim());
    await _run(() async {
      final current = FirebaseAuth.instance.currentUser;
      if (current?.isAnonymous == true) return current!.linkWithCredential(credential);
      return FirebaseAuth.instance.signInWithCredential(credential);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topRight, end: Alignment.bottomLeft,
          colors: [c.primaryContainer.withValues(alpha: .65), c.surface, c.surface])),
        child: SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 76, height: 76, alignment: Alignment.center,
                decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 40)),
              const SizedBox(height: 18),
              Center(child: Column(children: [
                CircleAvatar(
                  radius: 43,
                  backgroundColor: c.primaryContainer,
                  backgroundImage: uploadedProfileUrl != null
                      ? NetworkImage(uploadedProfileUrl!)
                      : (profileImage != null ? FileImage(File(profileImage!.path)) : null) as ImageProvider?,
                  child: profileImage == null && uploadedProfileUrl == null
                      ? Icon(Icons.person_rounded, size: 38, color: c.primary) : null,
                ),
                const SizedBox(height: 7),
                TextButton.icon(
                  onPressed: busy ? null : () async {
                    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 900);
                    if (picked != null && mounted) setState(() { profileImage = picked; uploadedProfileUrl = null; });
                  },
                  icon: const Icon(Icons.add_a_photo_outlined, size: 17),
                  label: const Text('د پروفایل انځور ټاکل'),
                ),
              ])),
              const SizedBox(height: 10),
              const Text('ادبي خزانه', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 7),
              Text('د خپلې خوښې له لارې خوندي حساب ته ننوځئ',
                textAlign: TextAlign.center, style: TextStyle(color: c.onSurfaceVariant)),
              const SizedBox(height: 25),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('نوی حساب')),
                  ButtonSegment(value: false, label: Text('ننوتل')),
                ],
                selected: {create},
                onSelectionChanged: (v) => setState(() { create = v.first; error = null; }),
              ),
              const SizedBox(height: 18),
              if (create) TextField(controller: name, decoration: const InputDecoration(
                labelText: 'ستاسو نوم', prefixIcon: Icon(Icons.person_outline_rounded))),
              if (create) const SizedBox(height: 12),
              TextField(controller: email, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'ایمیل', prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 12),
              TextField(controller: password, obscureText: true,
                decoration: const InputDecoration(labelText: 'پټنوم', prefixIcon: Icon(Icons.lock_outline_rounded))),
              const SizedBox(height: 14),
              FilledButton.icon(onPressed: busy ? null : _emailAuth,
                icon: const Icon(Icons.login_rounded),
                label: Text(create ? 'د ایمیل له لارې حساب جوړول' : 'ایمیل سره ننوتل')),
              const SizedBox(height: 10),
              const SizedBox(height: 18),
              const Divider(),
              OutlinedButton.icon(
                onPressed: busy ? null : _continueAsGuest,
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('د مېلمه په توګه دوام')),
              const SizedBox(height: 8),
              Text('مېلمه حساب د محدودو ځانګړنو لپاره دی؛ د شعرونو د تبصرو او شخصي حساب لپاره ایمیل وکاروئ.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.onSurfaceVariant, fontSize: 11)),
              if (busy) const Padding(padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator())),
              if (error != null) Padding(padding: const EdgeInsets.only(top: 12),
                child: Text(error!, textAlign: TextAlign.center,
                  style: TextStyle(color: c.error, fontSize: 12))),
            ]),
          ),
        ))),
      ),
    ));
  }
}

class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key, required this.appBuilder});
  final Widget Function() appBuilder;

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  bool showSplash = true;
  bool showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _launch();
  }

  Future<void> _launch() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    setState(() {
      showSplash = false;
      showOnboarding = !(prefs.getBool('onboarding_complete') ?? false);
    });
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    setState(() => showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (showSplash) return const SplashScreen();
    if (showOnboarding) return OnboardingScreen(onDone: _finishOnboarding);
    return widget.appBuilder();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1300))..forward();
  late final Animation<double> fade = CurvedAnimation(
    parent: controller, curve: Curves.easeInOut);
  late final Animation<double> scale = Tween<double>(
    begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: controller, curve: Curves.elasticOut));

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF123B32), Color(0xFF245B50), Color(0xFFB77928)],
            ),
          ),
          child: FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 112, height: 112,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(color: Colors.white24)),
                    child: const Icon(Icons.auto_stories_rounded,
                      size: 61, color: Colors.white),
                  ),
                  const SizedBox(height: 22),
                  const Text('ادبي خزانه',
                    style: TextStyle(color: Colors.white, fontSize: 35,
                      fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 7),
                  const Text('د پښتو شعر او ادب نړۍ',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 52),
                  const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();
  int page = 0;

  final slides = const [
    _IntroSlide(Icons.auto_stories_rounded, 'د شعرونو ښکلی جهان',
      'د پښتو خوږ شعرونه ولولئ او د ادب له رنګینې نړۍ خوند واخلئ.'),
    _IntroSlide(Icons.favorite_rounded, 'خپل خوښ شعرونه وساتئ',
      'د زړه نښه کېکاږئ، څو خوښ شعرونه مو په ځانګړې برخه کې خوندي وي.'),
    _IntroSlide(Icons.search_rounded, 'هر شعر په اسانه ومومئ',
      'شعرونه ولولئ، ولټوئ او خپلې خوښې شعرونه وساتئ.'),
  ];

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void next() {
    if (page == slides.length - 1) {
      widget.onDone();
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: widget.onDone,
                    child: const Text('تېرېدل')),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: slides.length,
                    onPageChanged: (value) => setState(() => page = value),
                    itemBuilder: (context, index) {
                      final slide = slides[index];
                      return AnimatedBuilder(
                        animation: pageController,
                        builder: (context, child) {
                          double value = 1;
                          if (pageController.hasClients && pageController.position.haveDimensions) {
                            value = (1 - (pageController.page! - index).abs() * 0.16)
                                .clamp(0.84, 1.0);
                          }
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 220, height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primaryContainer),
                              child: Center(
                                child: Icon(slide.icon, size: 104,
                                  color: colors.onPrimaryContainer)),
                            ),
                            const SizedBox(height: 42),
                            Text(slide.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 13),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(slide.description,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14, height: 1.9,
                                  color: colors.onSurfaceVariant)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (index) =>
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: page == index ? 25 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: page == index ? colors.primary
                          : colors.primary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10)),
                    )),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: next,
                    child: Text(page == slides.length - 1
                      ? 'پیل وکړئ' : 'بل ګام',
                      style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroSlide {
  const _IntroSlide(this.icon, this.title, this.description);
  final IconData icon;
  final String title;
  final String description;
}

class Poem {
  const Poem({
    required this.id, required this.title, required this.poet,
    required this.category, required this.text, required this.lines,
    this.views = 0, this.likes = 0, this.shares = 0, this.saves = 0,
    this.imageUrl, this.poetImageUrl, this.categoryImageUrl,
    this.poetId = '', this.categoryId = '', this.featured = false,
  });
  final String id, title, poet, category, text;
  final List<String> lines;
  final int views, likes, shares, saves;
  final String? imageUrl;
  final String? poetImageUrl, categoryImageUrl;
  final String poetId, categoryId;
  final bool featured;
}

class LocalPoetryCategory {
  const LocalPoetryCategory(this.title, this.icon);
  final String title;
  final IconData icon;
}

class PoetryShell extends StatefulWidget {
  const PoetryShell({
    super.key,
    required this.isDark,
    required this.fontName,
    required this.accentColor,
    required this.onTheme,
    required this.onFontChanged,
    required this.onAccentChanged,
    required this.onResetAppearance,
  });
  final bool isDark;
  final String fontName;
  final Color accentColor;
  final VoidCallback onTheme;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<Color> onAccentChanged;
  final VoidCallback onResetAppearance;
  @override
  State<PoetryShell> createState() => _PoetryShellState();
}

class _PoetryShellState extends State<PoetryShell> {
  int selectedPage = 0;
  int _featuredIndex = 0;
  final PageController _featuredController = PageController();
  Timer? _featuredTimer;
  final Set<String> favorites = {};
  final Set<String> likedPoems = {};
  final List<Poem> poems = [];
  static const List<LocalPoetryCategory> _offlineCategories = [
    LocalPoetryCategory('حمدیه شاعري', Icons.volunteer_activism_rounded),
    LocalPoetryCategory('نعتیه شاعري', Icons.mosque_rounded),
    LocalPoetryCategory('حماسي شاعري', Icons.shield_rounded),
    LocalPoetryCategory('عشقي شاعري', Icons.favorite_rounded),
    LocalPoetryCategory('غنایي شاعري', Icons.music_note_rounded),
    LocalPoetryCategory('عرفاني شاعري', Icons.auto_awesome_rounded),
    LocalPoetryCategory('تصوفي شاعري', Icons.spa_rounded),
    LocalPoetryCategory('فلسفي شاعري', Icons.psychology_rounded),
    LocalPoetryCategory('اخلاقي شاعري', Icons.balance_rounded),
    LocalPoetryCategory('اصلاحي شاعري', Icons.lightbulb_rounded),
    LocalPoetryCategory('ټولنیزه شاعري', Icons.groups_rounded),
    LocalPoetryCategory('سیاسي شاعري', Icons.account_balance_rounded),
    LocalPoetryCategory('ملي شاعري', Icons.flag_rounded),
    LocalPoetryCategory('وطني شاعري', Icons.public_rounded),
    LocalPoetryCategory('رزمي شاعري', Icons.military_tech_rounded),
    LocalPoetryCategory('انتقادي شاعري', Icons.rate_review_rounded),
    LocalPoetryCategory('طنزي شاعري', Icons.mood_rounded),
    LocalPoetryCategory('هجوي شاعري', Icons.theater_comedy_rounded),
    LocalPoetryCategory('مرثیه', Icons.local_florist_rounded),
    LocalPoetryCategory('تاریخي شاعري', Icons.history_edu_rounded),
    LocalPoetryCategory('تعلیمي شاعري', Icons.school_rounded),
    LocalPoetryCategory('طبیعي شاعري', Icons.nature_rounded),
    LocalPoetryCategory('حماسي وطني شاعري', Icons.emoji_events_rounded),
    LocalPoetryCategory('فراق او هجران', Icons.nights_stay_rounded),
    LocalPoetryCategory('تصوف او معرفت', Icons.self_improvement_rounded),
  ];
  Map<String, String> _categoryNames = {};
  Map<String, String> _poetNames = {};
  Map<String, String> _categoryImages = {};
  Map<String, String> _poetImages = {};
  StreamSubscription<DatabaseEvent>? _poemSub, _categorySub, _poetSub, _connectionSub;
  bool? _isDatabaseConnected;
  String query = '';
  bool _exitDialogOpen = false;
  bool _loadingPoems = true;
  String? _databaseError;
  String _profileName = '';

  @override
  void initState() {
    super.initState();
    _featuredTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || selectedPage != 0) return;
      final count = poems.where((p) => p.featured).length;
      if (count < 2 || !_featuredController.hasClients) return;
      final next = (_featuredIndex + 1) % count;
      _featuredController.animateToPage(next,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic);
    });
    _loadEngagementState();
    _loadProfileName();
    _connectionSub = FirebaseDatabase.instance.ref('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value == true;
      if (!mounted || _isDatabaseConnected == connected) return;
      setState(() => _isDatabaseConnected = connected);
      if (connected) {
        _reloadPoems();
      } else if (poems.isEmpty) {
        setState(() {
          _loadingPoems = false;
          _databaseError = 'انټرنېټ نشته؛ ډیټا نه لوډ کېږي.';
        });
      }
    });
    _initializeCachedDataAndListeners();
  }

  Future<void> _initializeCachedDataAndListeners() async {
    // Show the last successful dataset immediately, even without internet.
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesRaw = prefs.getString('cache_categories');
      final poetsRaw = prefs.getString('cache_poets');
      final poemsRaw = prefs.getString('cache_poems');
      if (categoriesRaw != null) {
        final value = jsonDecode(categoriesRaw);
        _categoryNames = _names(value);
        _categoryImages = _imageUrls(value);
      }
      if (poetsRaw != null) {
        final value = jsonDecode(poetsRaw);
        _poetNames = _names(value);
        _poetImages = _imageUrls(value);
      }
      if (poemsRaw != null) {
        _applyPoems(jsonDecode(poemsRaw));
      }
    } catch (_) {
      // A damaged/old cache is ignored; fresh data will replace it.
    }
    if (!mounted) return;
    _categorySub = FirebaseDatabase.instance.ref('categories').onValue.listen((e) {
      _categoryNames = _names(e.snapshot.value);
      _categoryImages = _imageUrls(e.snapshot.value);
      _saveCachedValue('cache_categories', e.snapshot.value);
      _reloadPoems();
    }, onError: (Object e) {
      if (mounted && poems.isEmpty) setState(() { _loadingPoems = false; _databaseError = e.toString(); });
    });
    _poetSub = FirebaseDatabase.instance.ref('poets').onValue.listen((e) {
      _poetNames = _names(e.snapshot.value);
      _poetImages = _imageUrls(e.snapshot.value);
      _saveCachedValue('cache_poets', e.snapshot.value);
      _reloadPoems();
    }, onError: (Object e) {
      if (mounted && poems.isEmpty) setState(() { _loadingPoems = false; _databaseError = e.toString(); });
    });
    _poemSub = FirebaseDatabase.instance.ref('poems').onValue.listen((e) {
      _saveCachedValue('cache_poems', e.snapshot.value);
      _applyPoems(e.snapshot.value);
    }, onError: (Object e) {
      if (mounted && poems.isEmpty) setState(() { _loadingPoems = false; _databaseError = e.toString(); });
    });
    // Avoid leaving the skeleton on screen forever when the device is offline
    // and there is no previously cached dataset.
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && _loadingPoems && poems.isEmpty) {
        setState(() {
          _loadingPoems = false;
          _databaseError = 'د انټرنېټ اړیکه نشته';
        });
      }
    });
  }

  Future<void> _saveCachedValue(String key, Object? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, jsonEncode(value));
      }
    } catch (_) {}
  }

  Future<void> _loadProfileName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseDatabase.instance.ref('profiles/${user.uid}/displayName').get();
      if (mounted && snap.exists) setState(() => _profileName = snap.value.toString());
    } catch (_) {}
  }

  Future<Map<String, String>?> _ensureProfile() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('د تبصرې لپاره لومړی د ایمیل، Google یا ټیلیفون له لارې حساب ته ننوځئ.')));
      return null;
    }
    var name = _profileName;
    var photoUrl = user.photoURL ?? '';
    if (name.trim().isEmpty || photoUrl.isEmpty) {
      final snap = await FirebaseDatabase.instance.ref('profiles/${user.uid}').get();
      if (snap.value is Map) {
        final profileData = Map<String, dynamic>.from(snap.value as Map);
        if (name.trim().isEmpty) name = profileData['displayName']?.toString() ?? '';
        if (photoUrl.isEmpty) photoUrl = profileData['photoUrl']?.toString() ?? '';
      }
    }
    if (name.trim().isEmpty) {
      final controller = TextEditingController();
      final entered = await showDialog<String>(context: context, barrierDismissible: false,
        builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
          title: const Text('خپل پروفایل جوړ کړئ'),
          content: TextField(controller: controller, autofocus: true, maxLength: 28,
            decoration: const InputDecoration(labelText: 'ستاسو نوم')),
          actions: [FilledButton(onPressed: () {
            if (controller.text.trim().isNotEmpty) Navigator.pop(ctx, controller.text.trim());
          }, child: const Text('خوندي کول'))],
        )));
      controller.dispose();
      if (entered == null || entered.trim().isEmpty) return null;
      name = entered.trim();
      await FirebaseDatabase.instance.ref('profiles/${user.uid}').update({
        'displayName': name, 'updatedAt': ServerValue.timestamp,
      });
    }
    if (mounted) setState(() => _profileName = name);
    return {'uid': user.uid, 'name': name, 'photoUrl': photoUrl};
  }

  Future<void> _editProfile() async {
    final profile = await _ensureProfile();
    if (profile == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('د پروفایل د بدلون لپاره لومړی ایمیل حساب جوړ کړئ.')));
      return;
    }
    final nameController = TextEditingController(text: profile['name']);
    final currentPassword = TextEditingController();
    final newPassword = TextEditingController();
    XFile? selectedPhoto;
    bool changePassword = false;
    final saved = await showDialog<bool>(context: context, builder: (ctx) =>
      StatefulBuilder(builder: (ctx, setLocal) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('د پروفایل تنظیمات'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: () async {
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery, imageQuality: 82, maxWidth: 900);
                if (picked != null) setLocal(() => selectedPhoto = picked);
              },
              child: CircleAvatar(radius: 38,
                backgroundImage: selectedPhoto != null
                  ? FileImage(File(selectedPhoto!.path))
                  : ((user.photoURL ?? profile['photoUrl'] ?? '').isNotEmpty
                      ? NetworkImage(user.photoURL ?? profile['photoUrl']!) : null) as ImageProvider?,
                child: selectedPhoto == null && (user.photoURL ?? profile['photoUrl'] ?? '').isEmpty
                  ? const Icon(Icons.add_a_photo_rounded, size: 27) : null),
            ),
            const SizedBox(height: 6),
            TextButton.icon(onPressed: () async {
              final picked = await ImagePicker().pickImage(
                source: ImageSource.gallery, imageQuality: 82, maxWidth: 900);
              if (picked != null) setLocal(() => selectedPhoto = picked);
            }, icon: const Icon(Icons.photo_camera_back_rounded),
              label: const Text('د پروفایل انځور بدلول')),
            TextField(controller: nameController, maxLength: 28,
              decoration: const InputDecoration(labelText: 'نوم')),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('پټنوم بدلول'),
              value: changePassword,
              onChanged: (v) => setLocal(() => changePassword = v)),
            if (changePassword) ...[
              TextField(controller: currentPassword, obscureText: true,
                decoration: const InputDecoration(labelText: 'اوسنی پټنوم')),
              TextField(controller: newPassword, obscureText: true,
                decoration: const InputDecoration(labelText: 'نوی پټنوم (لږ تر لږه ۶ توري)')),
            ],
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('بندول')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بدلونونه خوندي کول')),
          ],
        ))));
    final newName = nameController.text.trim();
    final oldPass = currentPassword.text;
    final nextPass = newPassword.text;
    nameController.dispose(); currentPassword.dispose(); newPassword.dispose();
    if (saved != true) return;
    try {
      if (newName.isEmpty) throw Exception('نوم تش نه شي پاتې کېدای.');
      String? photoUrl;
      if (selectedPhoto != null) photoUrl = await uploadImageToCloudinary(selectedPhoto!);
      if (changePassword) {
        if (oldPass.isEmpty || nextPass.length < 6) {
          throw Exception('اوسنی او نوی پټنوم سم ولیکئ؛ نوی پټنوم لږ تر لږه ۶ توري لري.');
        }
        final emailAddress = user.email;
        if (emailAddress == null) throw Exception('دا حساب د ایمیل له لارې نه دی جوړ شوی.');
        final credential = EmailAuthProvider.credential(email: emailAddress, password: oldPass);
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(nextPass);
      }
      await user.updateDisplayName(newName);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      await FirebaseDatabase.instance.ref('profiles/${user.uid}').update({
        'displayName': newName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': ServerValue.timestamp,
      });
      if (mounted) setState(() => _profileName = newName);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('پروفایل په بریالیتوب تازه شو.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('بدلون ترسره نه شو: $e')));
    }
  }

  Future<void> _loadEngagementState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      favorites..clear()..addAll(prefs.getStringList('favorite_poem_ids') ?? const []);
      likedPoems..clear()..addAll(prefs.getStringList('liked_poem_ids') ?? const []);
    });
  }

  Future<void> _toggleFavorite(Poem poem) async {
    final adding = !favorites.contains(poem.id);
    setState(() {
      if (adding) { favorites.add(poem.id); } else { favorites.remove(poem.id); }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_poem_ids', favorites.toList());
    if (adding) await _incrementPoemCounter(poem.id, 'saves');
  }

  Future<void> _likePoem(Poem poem) async {
    if (likedPoems.contains(poem.id)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('دا شعر مو مخکې خوښ کړی دی.')));
      return;
    }
    setState(() => likedPoems.add(poem.id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('liked_poem_ids', likedPoems.toList());
    await _incrementPoemCounter(poem.id, 'likes');
  }

  Future<void> _incrementPoemCounter(String poemId, String field) async {
    try {
      await FirebaseDatabase.instance.ref('poems/$poemId/$field').runTransaction((value) {
        final current = value is num ? value.toInt() : 0;
        return Transaction.success(current + 1);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('شمېر تازه نه شو: $e')));
    }
  }

  Future<void> _sharePoem(Poem poem) async {
    final author = poem.poet.isEmpty ? '' : poem.poet + '\n';
    final content = poem.title + '\n' + author + '\n' + poem.text + '\n\n— ادبي خزانه';
    await Share.share(content, subject: poem.title);
    await _incrementPoemCounter(poem.id, 'shares');
  }

  Map<String, String> _names(Object? raw) {
    final result = <String, String>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final value = entry.value;
        final name = value is Map ? value['name'] : value;
        if (name != null && name.toString().trim().isNotEmpty) {
          result[entry.key.toString()] = name.toString();
        }
      }
    }
    return result;
  }

  Map<String, String> _imageUrls(Object? raw) {
    final result = <String, String>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.value is Map) {
          final url = (entry.value as Map)['imageUrl']?.toString() ?? '';
          if (url.startsWith('http')) result[entry.key.toString()] = url;
        }
      }
    }
    return result;
  }

  int _count(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  void _reloadPoems() {
    FirebaseDatabase.instance.ref('poems').get().then((snapshot) {
      if (mounted) {
        _saveCachedValue('cache_poems', snapshot.value);
        _applyPoems(snapshot.value);
      }
    }).catchError((Object e) {
      if (mounted && poems.isEmpty) setState(() { _loadingPoems = false; _databaseError = e.toString(); });
    });
  }

  void _applyPoems(Object? raw) {
    final next = <Poem>[];
    if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.value is! Map) continue;
        final data = Map<String, dynamic>.from(entry.value as Map);
        final body = (data['text'] ?? '').toString().trim();
        final categoryId = (data['categoryId'] ?? '').toString();
        if (body.isEmpty || categoryId.isEmpty || data['isPublished'] == false) continue;
        next.add(Poem(
          id: entry.key.toString(),
          title: (data['title'] ?? '').toString().trim().isEmpty
              ? body.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(6).join(' ')
              : data['title'].toString().trim(),
          poetId: (data['poetId'] ?? '').toString(),
          categoryId: categoryId,
          poet: _poetNames[(data['poetId'] ?? '').toString()] ?? '',
          category: _categoryNames[categoryId] ?? '',
          poetImageUrl: _poetImages[(data['poetId'] ?? '').toString()],
          categoryImageUrl: _categoryImages[categoryId],
          text: body,
          lines: body.split(RegExp(r'\r?\n')),
          views: _count(data['views']), likes: _count(data['likes']),
          shares: _count(data['shares']), saves: _count(data['saves']),
          imageUrl: data['imageUrl']?.toString(), featured: data['featured'] == true,
        ));
      }
    }
    next.sort((a,b) => b.id.compareTo(a.id));
    if (!mounted) return;
    setState(() {
      poems..clear()..addAll(next);
      _loadingPoems = false;
      _databaseError = null;
    });
  }

  @override
  void dispose() {
    _poemSub?.cancel();
    _categorySub?.cancel();
    _poetSub?.cancel();
    _connectionSub?.cancel();
    _featuredTimer?.cancel();
    _featuredController.dispose();
    super.dispose();
  }

  List<Poem> get filteredPoems => poems.where((poem) {
    final text = '${poem.title} ${poem.poet} ${poem.category} ${poem.lines.join(' ')}';
    return text.toLowerCase().contains(query.toLowerCase());
  }).toList();

  List<Poem> get favoritePoems =>
      poems.where((poem) => favorites.contains(poem.id)).toList();

  @override
  Widget build(BuildContext context) {
    const titles = ['ادبي خزانه', 'خوښ شوي شعرونه', 'زموږ په اړه', 'تنظیمات'];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (selectedPage != 0) {
            setState(() => selectedPage = 0);
          } else {
            _confirmExit();
          }
        },
        child: Scaffold(
        drawer: _buildDrawer(),
        appBar: AppBar(
          title: Text(titles[selectedPage]),
          actions: [
            IconButton(
              tooltip: 'د شپې او ورځې بڼه',
              onPressed: widget.onTheme,
              icon: Icon(widget.isDark
                ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            if (selectedPage == 0 && _isDatabaseConnected == false)
              _offlineNotice(),
            Expanded(child: IndexedStack(
              index: selectedPage,
              children: [
                _homePage(), _favoritesPage(), _aboutPage(), _settingsPage(),
              ],
            )),
          ],
        ),
        bottomNavigationBar: _luxuryBottomNavigation(),
        ),
      ),
    );
  }

  Widget _offlineNotice() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 7, 14, 2),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.error.withValues(alpha: .22)),
      ),
      child: Row(children: [
        Icon(Icons.wifi_off_rounded, color: colors.onErrorContainer, size: 19),
        const SizedBox(width: 9),
        Expanded(child: Text(
          poems.isEmpty
              ? 'انټرنېټ نشته؛ لیکنې نه لوډ کېږي. اړیکه وګورئ.'
              : 'انټرنېټ نشته؛ خوندي شوې لیکنې درته ښودل کېږي.',
          style: TextStyle(color: colors.onErrorContainer,
            fontSize: 11, fontWeight: FontWeight.w700),
        )),
        TextButton(
          onPressed: _listenAgain,
          child: Text('بیا هڅه', style: TextStyle(
            color: colors.onErrorContainer, fontSize: 11,
            fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }

  Widget _luxuryBottomNavigation() {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    const items = <(IconData, IconData, String)>[
      (Icons.home_outlined, Icons.home_rounded, 'کور'),
      (Icons.favorite_border_rounded, Icons.favorite_rounded, 'خوښ شوي'),
      (Icons.info_outline_rounded, Icons.info_rounded, 'زموږ په اړه'),
      (Icons.settings_outlined, Icons.settings_rounded, 'تنظیمات'),
    ];
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 5, 12, 10),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1B1D2B) : Colors.white,
          borderRadius: BorderRadius.circular(27),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: .42),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? .22 : .075),
              blurRadius: 25,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (index) {
            final selected = selectedPage == index;
            final item = items[index];
            return Expanded(
              child: Semantics(
                button: true,
                selected: selected,
                label: item.$3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: () => setState(() => selectedPage = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: EdgeInsets.symmetric(
                      horizontal: selected ? 3 : 0,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Color(0xFF153F37),
                                Color(0xFF245B50),
                                Color(0xFFB77928),
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.08 : 1,
                          duration: const Duration(milliseconds: 240),
                          child: Icon(
                            selected ? item.$2 : item.$1,
                            size: 22,
                            color: selected
                                ? Colors.white
                                : colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            fontFamily: widget.fontName,
                            fontSize: selected ? 9.5 : 9,
                            height: 1.2,
                            fontWeight: selected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : colors.onSurfaceVariant,
                          ),
                          child: Text(
                            item.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final colors = Theme.of(context).colorScheme;
    return Drawer(
      width: 320,
      elevation: 18,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF153F37), Color(0xFF245B50), Color(0xFFB77928)],
                  ),
                  borderRadius: BorderRadius.circular(27),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7652CE).withValues(alpha: .28),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: -8,
                      top: -14,
                      child: Icon(Icons.auto_stories_rounded,
                          size: 112, color: Colors.white.withValues(alpha: .09)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .17),
                                borderRadius: BorderRadius.circular(21),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: .35)),
                              ),
                              child: const Icon(Icons.menu_book_rounded,
                                  color: Colors.white, size: 34),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.auto_awesome_rounded,
                                      color: Colors.white, size: 13),
                                  SizedBox(width: 5),
                                  Text('ادبي نړۍ',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 17),
                        const Text('ادبي خزانه',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(height: 5),
                        const Text('د پښتو شعر او ادب رنګینه نړۍ',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: .25),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 15),
                            SizedBox(width: 7),
                            Text('ولولئ • خوند واخلئ • یاد یې وساتئ',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 9),
              child: Row(
                children: [
                  Text('اصلي مینو',
                      style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                        height: 1,
                        color: colors.outlineVariant.withValues(alpha: .6)),
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.home_rounded, 'کور پاڼه', 0),
            _drawerItem(Icons.favorite_rounded, 'خوښ شوي شعرونه', 1),
            _drawerItem(Icons.info_rounded, 'زموږ په اړه', 2),
            _drawerItem(Icons.settings_rounded, 'تنظیمات', 3),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Material(
                color: colors.primary.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(17),
                child: ListTile(
                  leading: Icon(Icons.admin_panel_settings_rounded, color: colors.primary),
                  title: const Text('د اډمین مدیریت', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  subtitle: const Text('شعرونه او کټګورۍ اداره کړئ', style: TextStyle(fontSize: 10)),
                  trailing: Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: colors.primary),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) =>
                      const Directionality(textDirection: TextDirection.rtl, child: EmbeddedAdminGate())));
                  },
                ),
              ),
            ),
            const SizedBox(height: 9),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: .55)),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  secondary: Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      widget.isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: colors.primary,
                      size: 21,
                    ),
                  ),
                  title: const Text('تیاره بڼه',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  subtitle: Text(widget.isDark ? 'فعاله ده' : 'غیر فعاله ده',
                      style: TextStyle(
                          fontSize: 10, color: colors.onSurfaceVariant)),
                  value: widget.isDark,
                  onChanged: (_) {
                    Navigator.pop(context);
                    widget.onTheme();
                  },
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 5),
              child: Material(
                color: colors.errorContainer.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(17),
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmExit();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 13),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: colors.error, size: 21),
                        const SizedBox(width: 11),
                        Text('له اپلیکیشن څخه وتل',
                            style: TextStyle(
                                color: colors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Icon(Icons.arrow_back_ios_new_rounded,
                            color: colors.error, size: 13),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 5),
              child: Text('ادبي خزانه  •  نسخه 1.0.0',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: .3,
                      color: colors.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, int index) {
    final colors = Theme.of(context).colorScheme;
    final selected = selectedPage == index;
    return TweenAnimationBuilder<double>(
      key: ValueKey('drawer-item-$index-$selected'),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 380 + (index * 75)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(22 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
        child: Material(
          color: selected
              ? colors.primaryContainer.withValues(alpha: .8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () {
              Navigator.pop(context);
              setState(() => selectedPage = index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: selected
                      ? colors.primary.withValues(alpha: .22)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                              colors: [colors.primary, colors.tertiary])
                          : null,
                      color: selected ? null : colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon,
                        color: selected ? Colors.white : colors.onSurfaceVariant,
                        size: 21),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontSize: 12,
                            color: selected ? colors.primary : colors.onSurface,
                            fontWeight:
                                selected ? FontWeight.w900 : FontWeight.w600)),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded,
                        color: colors.primary, size: 19),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    if (_exitDialogOpen || !mounted) return;
    _exitDialogOpen = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.exit_to_app_rounded, size: 30),
        title: const Text('له اپلیکیشن څخه وتل؟',
          textAlign: TextAlign.center),
        content: const Text('ایا ډاډه یاست چې غواړئ له ادبي خزانه څخه ووځئ؟',
          textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('نه، پاتې کېږم'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.exit_to_app_rounded, size: 18),
            label: const Text('هو، ووځم'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;
    if (shouldExit == true && mounted) {
      await SystemNavigator.pop();
    }
  }

  Widget _skeletonBlock({double height = 105, double? width, double radius = 20}) {
    return _ShimmerBox(height: height, width: width, radius: radius);
  }

  Widget _refreshable(Widget child) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _refreshHome,
      color: colors.primary,
      backgroundColor: colors.surface,
      strokeWidth: 3,
      displacement: 58,
      edgeOffset: 8,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      elevation: 5,
      child: child,
    );
  }

  Future<void> _refreshHome() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('poems').get()
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      _saveCachedValue('cache_poems', snapshot.value);
      _applyPoems(snapshot.value);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شعرونه تازه شول.'), duration: Duration(seconds: 2)),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تازه کول ناکام شول؛ انټرنېټ وګورئ.'), duration: Duration(seconds: 2)),
      );
    }
  }

  Widget _homeSkeleton() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _skeletonBlock(height: 174, radius: 22),
        const SizedBox(height: 20),
        _skeletonBlock(height: 104, radius: 22),
        const SizedBox(height: 20),
        _skeletonBlock(height: 50, radius: 17),
        const SizedBox(height: 22),
        _skeletonBlock(height: 22, width: 150, radius: 8),
        const SizedBox(height: 12),
        ...List.generate(4, (_) => Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: _skeletonBlock(height: 112, radius: 20),
        )),
      ],
    );
  }

  void _openSearchPage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PoetrySearchPage(
      poems: poems,
      onPoemTap: (poem) {
        Navigator.pop(context);
        _openPoem(poem);
      },
    )));
  }

  Widget _homePage() {
    final colors = Theme.of(context).colorScheme;
    if (poems.isEmpty && _loadingPoems) return _refreshable(_homeSkeleton());
    if (poems.isEmpty && (_databaseError != null || !_loadingPoems || poems.isEmpty)) {
      return _refreshable(ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 24),
        children: [
          if (_loadingPoems)
            const Padding(padding: EdgeInsets.all(45), child: Center(child: CircularProgressIndicator()))
          else if (_databaseError != null)
            _emptyPoemsState(icon: Icons.cloud_off_rounded, title: 'له ډیټابېس سره اړیکه ټینګه نه شوه',
              subtitle: 'انټرنېټ وګورئ او بیا هڅه وکړئ.', action: 'بیا هڅه', onAction: _listenAgain)
          else
            _emptyPoemsState(icon: Icons.menu_book_outlined, title: 'د شعرونو لېست تش دی',
              subtitle: 'تر اوسه کوم شعر نه دی خپور شوی. کله چې اډمین شعر خپور کړي، دلته به ښکاره شي.'),
        ],
      ));
    }
    final visible = filteredPoems;
    final featuredPoems = poems.where((p) => p.featured).toList();
    final poetGroups = <String, List<Poem>>{};
    for (final poem in poems) {
      if (poem.poetId.isNotEmpty && poem.poet.trim().isNotEmpty) {
        poetGroups.putIfAbsent(poem.poetId, () => <Poem>[]).add(poem);
      }
    }
    return _refreshable(CustomScrollView(
      key: const PageStorageKey('home'),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        if (featuredPoems.isNotEmpty)
          SliverToBoxAdapter(child: Column(children: [
            SizedBox(height: 174, child: PageView.builder(
              controller: _featuredController,
              itemCount: featuredPoems.length,
              onPageChanged: (index) => setState(() => _featuredIndex = index),
              itemBuilder: (context, index) {
                final poem = featuredPoems[index];
                return Padding(padding: const EdgeInsets.fromLTRB(16, 7, 16, 3),
                  child: InkWell(borderRadius: BorderRadius.circular(20),
                    onTap: () => _openPoem(poem),
                    child: ClipRRect(borderRadius: BorderRadius.circular(20),
                      child: Stack(fit: StackFit.expand, children: [
                        if (poem.imageUrl != null && poem.imageUrl!.isNotEmpty)
                          Image.network(poem.imageUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _poemCardArtwork())
                        else _poemCardArtwork(),
                        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: .72)]))),
                        Positioned(right: 16, left: 16, bottom: 12, child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(poem.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(poem.text.replaceAll('\\n', ' ').trim(), maxLines: 3, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.45, fontWeight: FontWeight.w600)),
                          ],
                        )),
                      ]))));
              },
            )),
            const SizedBox(height: 5),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(
              featuredPoems.length, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _featuredIndex == index ? 17 : 6, height: 6,
                decoration: BoxDecoration(color: _featuredIndex == index ? colors.primary : colors.outlineVariant,
                  borderRadius: BorderRadius.circular(10))))),
          ])),
        SliverPadding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          sliver: SliverToBoxAdapter(child: Material(
            color: colors.surfaceContainerHighest.withValues(alpha: .55),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _openSearchPage,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                child: Row(children: [
                  Icon(Icons.search_rounded, color: colors.primary, size: 23),
                  const SizedBox(width: 12),
                  Expanded(child: Text('د شعر، شاعر او کټګورۍ لټون...',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13))),
                  Icon(Icons.tune_rounded, color: colors.primary, size: 20),
                ]),
              ),
            ),
          ))),
        SliverToBoxAdapter(child: _TypingCoupletBox(poems: poems)),
        SliverPadding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 9),
          sliver: SliverToBoxAdapter(child: _sectionHeader(Icons.auto_stories_rounded,
            'د شعرونو ټولګه', '${visible.length} شعرونه'))),
        if (visible.isEmpty)
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(20),
            child: Center(child: Text('په دې لټون کې څه پیدا نه شول.'))))
        else
          SliverToBoxAdapter(child: SizedBox(height: 176, child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
            itemCount: visible.length, separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _horizontalPoemCard(visible[index])))),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          sliver: SliverToBoxAdapter(
            child: _sectionHeader(
              Icons.category_rounded,
              'د شعرونو موضوعي کټګورۍ',
              '${_offlineCategories.length} کټګورۍ',
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 126,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _offlineCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = _offlineCategories[index];
                final remoteEntry = _categoryNames.entries.cast<MapEntry<String, String>?>()
                    .firstWhere(
                      (entry) => entry!.value.trim() == category.title,
                      orElse: () => null,
                    );
                final categoryId = remoteEntry?.key ?? 'offline_category_$index';
                final categoryImage = remoteEntry == null ? '' : (_categoryImages[categoryId] ?? '');
                final categoryPoems = poems.where((poem) =>
                  poem.category.trim() == category.title ||
                  (remoteEntry != null && poem.categoryId == categoryId)
                ).toList();

                // Muted topic accents: distinct, soft colors rather than saturated tones.
                const accents = <Color>[
                  Color(0xFF8D9B78), Color(0xFF7895A8), Color(0xFF9A806D),
                  Color(0xFFB47D86), Color(0xFF8C86A8), Color(0xFF78998F),
                  Color(0xFF9A9275), Color(0xFF7F91A8), Color(0xFF9B8878),
                  Color(0xFF829B87), Color(0xFF8B91A2), Color(0xFFA18478),
                ];
                final accent = accents[index % accents.length];
                final palette = Theme.of(context).colorScheme;

                return SizedBox(
                  width: 116,
                  child: Material(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _openCollectionPage(
                        category.title,
                        categoryImage,
                        categoryPoems,
                        collectionId: categoryId,
                        isCategory: true,
                        categoryIcon: category.icon,
                        categoryColor: accent,
                      ),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: accent.withValues(alpha: .075),
                          border: Border.all(
                            color: accent.withValues(alpha: .24),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(category.icon, color: accent, size: 23),
                            ),
                            const Spacer(),
                            Text(
                              category.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.onSurface,
                                fontSize: 11,
                                height: 1.2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${categoryPoems.length} شعرونه',
                              style: TextStyle(
                                color: palette.onSurfaceVariant,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (poetGroups.isNotEmpty) ...[
          SliverPadding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 9),
            sliver: SliverToBoxAdapter(child: _sectionHeader(Icons.people_alt_rounded,
              'شاعران', '${poetGroups.length} شاعران'))),
          SliverToBoxAdapter(child: SizedBox(height: 132, child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 10), scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(), itemCount: poetGroups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final entry = poetGroups.entries.elementAt(index);
              return _horizontalPoetCard(entry.key, _poetNames[entry.key] ?? '', entry.value);
            }))),
        ],
      ],
    ));
  }
  void _openCollectionPage(String title, String imageUrl, List<Poem> items, {required String collectionId, bool isCategory = false, IconData? categoryIcon, Color? categoryColor}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CollectionPoemsPage(
      title: title, imageUrl: imageUrl, poems: items, collectionId: collectionId,
      isCategory: isCategory, categoryIcon: categoryIcon,
      categoryColor: categoryColor, onPoemTap: _openPoem,
    )));
  }

  Widget _horizontalPoemCard(Poem poem) {
    final colors = Theme.of(context).colorScheme;
    final saved = favorites.contains(poem.id);
    return SizedBox(width: 148, child: Card(
      clipBehavior: Clip.antiAlias, elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(19)),
      child: InkWell(onTap: () => _openPoem(poem),
        child: Stack(fit: StackFit.expand, children: [
          if (poem.imageUrl != null && poem.imageUrl!.isNotEmpty)
            Image.network(poem.imageUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _poemCardArtwork())
          else _poemCardArtwork(),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: .05), Colors.black.withValues(alpha: .22),
              Colors.black.withValues(alpha: .84)], stops: const [0, .42, 1]))),
          Positioned(top: 10, right: 10, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: .28),
              borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white24)),
            child: Text(poem.category.isEmpty ? 'شعر' : poem.category,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)))),
          Positioned(top: 5, left: 5, child: IconButton(
            visualDensity: VisualDensity.compact, onPressed: () => _toggleFavorite(poem),
            icon: Icon(saved ? Icons.bookmark_added_rounded : Icons.bookmark_border_rounded,
              color: Colors.white, size: 23))),
          Positioned(left: 12, right: 12, bottom: 13, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
            children: [
              Text(poem.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12,
                  height: 1.55, fontWeight: FontWeight.w900)),
              if (poem.poet.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(poem.poet, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.visibility_rounded, color: Colors.white70, size: 13),
                const SizedBox(width: 4),
                Text('${poem.views}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(width: 12),
                const Icon(Icons.favorite_rounded, color: Color(0xFFFFA8B5), size: 13),
                const SizedBox(width: 4),
                Text('${poem.likes}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                const Spacer(),
                const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 15),
              ]),
            ])),
        ]))));
  }

  Widget _poemCardArtwork() {
    final colors = Theme.of(context).colorScheme;
    return Container(decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topRight, end: Alignment.bottomLeft,
      colors: [colors.primary.withValues(alpha: .96), const Color(0xFF273E58),
        const Color(0xFF9A6B37)])),
      child: Center(child: Icon(Icons.format_quote_rounded, size: 76,
        color: Colors.white.withValues(alpha: .20))));
  }

  Widget _horizontalPoetCard(String poetId, String name, List<Poem> poetPoems) {
    final colors = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? 'ش' : name.trim().characters.first;
    final poetImageUrl = _poetImages[poetId] ?? '';
    return SizedBox(width: 112, child: Card(
      elevation: 1, clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(onTap: () => _openCollectionPage(name, poetImageUrl, poetPoems, collectionId: poetId),
        child: Padding(padding: const EdgeInsets.fromLTRB(7, 8, 7, 7),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 54, height: 54,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
                  colors: [colors.primary.withValues(alpha: .16), colors.secondary.withValues(alpha: .28)]),
                border: Border.all(color: colors.primary.withValues(alpha: .12), width: 2)),
              clipBehavior: Clip.antiAlias,
              child: poetImageUrl.isNotEmpty
                ? Image.network(poetImageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(child: Text(initial, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colors.primary))))
                : Center(child: Text(initial, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colors.primary)))),
            const SizedBox(height: 6),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text('${poetPoems.length} شعرونه',
              style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
          ])))));
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 35, height: 35,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colors.primary, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15,
                fontWeight: FontWeight.w900, color: colors.onSurface)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 10,
                color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featuredPoemCard(Poem poem) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(19, 18, 19, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight, end: Alignment.bottomLeft,
          colors: [Color(0xFF173F38), Color(0xFF28695C), Color(0xFFB17A35)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: const Color(0xFF245B50).withValues(alpha: .22),
            blurRadius: 22, offset: const Offset(0, 9)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(left: -9, bottom: -14,
            child: Icon(Icons.format_quote_rounded, size: 112,
              color: Colors.white.withValues(alpha: .09))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(30)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD98A), size: 14),
                      SizedBox(width: 6),
                      Text('د ورځې غوره شعر', style: TextStyle(color: Colors.white,
                        fontSize: 10, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  const Spacer(),
                  Icon(Icons.bookmark_added_rounded,
                    color: const Color(0xFFFFD98A).withValues(alpha: .9), size: 22),
                ],
              ),
              const SizedBox(height: 17),
              Text(poem.title.isEmpty ? 'بې‌عنوانه' : poem.title,
                style: const TextStyle(color: Colors.white, fontSize: 20,
                  fontWeight: FontWeight.w900)),
              const SizedBox(height: 13),
              ...poem.lines.take(2).map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line, style: const TextStyle(color: Colors.white,
                  fontSize: 13, height: 1.9, fontWeight: FontWeight.w600)),
              )),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded,
                    color: Color(0xFFFFD98A), size: 18),
                  const SizedBox(width: 5),
                  Text(poem.poet, style: const TextStyle(color: Colors.white70,
                    fontSize: 11, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(poem.category, style: const TextStyle(color: Colors.white70,
                    fontSize: 10)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha:.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha:.12))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 15), const SizedBox(width: 5),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13,
            fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ]),
      ]),
    ));
  }

  Widget _favoritesPage() {
    final saved = favoritePoems;
    if (saved.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.favorite_border_rounded, size: 48),
            SizedBox(height: 12),
            Text('تر اوسه مو کوم شعر نه دی خوښ کړی.',
              textAlign: TextAlign.center),
            SizedBox(height: 5),
            Text('په کور پاڼه کې د زړه نښه کېکاږئ.',
              style: TextStyle(fontSize: 12)),
          ]),
        ),
      );
    }
    return ListView.builder(
      key: const PageStorageKey('favorites'),
      padding: const EdgeInsets.all(14),
      itemCount: saved.length,
      itemBuilder: (context, index) => _poemCard(saved[index]),
    );
  }

  


  Widget _settingsPage() {
    final colors = Theme.of(context).colorScheme;
    final dark = widget.isDark;
    const fonts = <Map<String, String>>[
      {'name': 'Vazirmatn', 'label': 'وزیرمتن', 'note': 'روښانه او منظم'},
      {'name': 'Noto Naskh Arabic', 'label': 'نوتو نسخ', 'note': 'د کتابونو کلاسیک سبک'},
      {'name': 'Amiri', 'label': 'اميري', 'note': 'ادبي او دودیز خط'},
      {'name': 'Cairo', 'label': 'کایرو', 'note': 'عصري او ساده'},
      {'name': 'Tajawal', 'label': 'تجوال', 'note': 'نرم او ښکلی'},
    ];
    const palettes = <Map<String, Object>>[
      {'name': 'ځنګلي شین', 'color': Color(0xFF245B50)},
      {'name': 'شاهي ارغواني', 'color': Color(0xFF6750A4)},
      {'name': 'سمندري آبي', 'color': Color(0xFF176B87)},
      {'name': 'یاقوتي سور', 'color': Color(0xFF9A3D50)},
      {'name': 'طلایي نارنجي', 'color': Color(0xFF9A641F)},
      {'name': 'فیروزه يي', 'color': Color(0xFF287C78)},
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        Card(clipBehavior: Clip.antiAlias, child: InkWell(
          onTap: _editProfile,
          child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            CircleAvatar(radius: 26,
              backgroundImage: (FirebaseAuth.instance.currentUser?.photoURL ?? '').isNotEmpty
                ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!) : null,
              backgroundColor: colors.primaryContainer,
              child: (FirebaseAuth.instance.currentUser?.photoURL ?? '').isEmpty
                ? Icon(Icons.person_rounded, color: colors.primary, size: 29) : null),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('زما پروفایل', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              Text(_profileName.isEmpty ? 'د تبصرو لپاره خپل نوم ثبت کړئ' : _profileName,
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
            ])),
            Icon(Icons.edit_rounded, color: colors.primary),
          ])),
        )),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: [Color(0xFF153F37), Color(0xFF245B50), Color(0xFFB77928)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: const Color(0xFF245B50).withValues(alpha: .23),
              blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 54, height: 54,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24)),
                child: const Icon(Icons.tune_rounded, color: Color(0xFFFFD98A), size: 29)),
              const SizedBox(width: 13),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('شخصي تنظیمات', style: TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.w900)),
                  SizedBox(height: 4),
                  Text('خپله ادبي نړۍ په خپله خوښه برابره کړئ.',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                ])),
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD98A), size: 24),
            ]),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.palette_outlined, color: Color(0xFFFFD98A), size: 19),
                const SizedBox(width: 9),
                const Expanded(child: Text('اوسنی رنګ او بڼه', style: TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                Text(dark ? 'تیاره بڼه' : 'روښانه بڼه',
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ])),
          ]),
        ),
        const SizedBox(height: 25),
        _settingsHeading(Icons.nightlight_round, 'د ښودنې بڼه'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: .55))),
          child: Row(children: [
            Expanded(child: _appearanceChoice(
              icon: Icons.light_mode_rounded, title: 'روښانه',
              selected: !dark, onTap: () { if (dark) widget.onTheme(); })),
            const SizedBox(width: 7),
            Expanded(child: _appearanceChoice(
              icon: Icons.dark_mode_rounded, title: 'تیاره',
              selected: dark, onTap: () { if (!dark) widget.onTheme(); })),
          ]),
        ),
        const SizedBox(height: 23),
        _settingsHeading(Icons.font_download_rounded, 'د لیکدود فونټونه'),
        const SizedBox(height: 9),
        ...fonts.map((font) {
          final selected = widget.fontName == font['name'];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.only(bottom: 9),
            decoration: BoxDecoration(
              gradient: selected ? LinearGradient(colors: [
                colors.primary.withValues(alpha: .13), colors.surface]) : null,
              color: selected ? null : colors.surface,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: selected ? colors.primary :
                colors.outlineVariant.withValues(alpha: .55), width: selected ? 1.5 : 1),
              boxShadow: selected ? [BoxShadow(color: colors.primary.withValues(alpha: .08),
                blurRadius: 14, offset: const Offset(0, 5))] : [],
            ),
            child: ListTile(
              onTap: () => widget.onFontChanged(font['name']!),
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
              leading: Container(width: 45, height: 45,
                decoration: BoxDecoration(color: selected ? colors.primary :
                  colors.surfaceContainerHighest, borderRadius: BorderRadius.circular(15)),
                child: Center(child: Text('Aa', style: TextStyle(fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: selected ? colors.onPrimary : colors.primary)))),
              title: Text(font['label']!, style: const TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(font['note']!),
              trailing: AnimatedContainer(duration: const Duration(milliseconds: 200),
                width: 25, height: 25,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: selected ? colors.primary : Colors.transparent,
                  border: Border.all(color: selected ? colors.primary : colors.outline)),
                child: selected ? Icon(Icons.check_rounded, size: 17, color: colors.onPrimary) : null),
            ),
          );
        }),
        const SizedBox(height: 14),
        _settingsHeading(Icons.color_lens_rounded, 'د اپلیکیشن رنګونه'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: .55))),
          child: Wrap(
            alignment: WrapAlignment.spaceAround, spacing: 12, runSpacing: 17,
            children: palettes.map((palette) {
              final color = palette['color'] as Color;
              final selected = widget.accentColor.toARGB32() == color.toARGB32();
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => widget.onAccentChanged(color),
                child: SizedBox(width: 82, child: Column(children: [
                  AnimatedContainer(duration: const Duration(milliseconds: 220),
                    width: selected ? 49 : 43, height: selected ? 49 : 43,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: color.withValues(alpha: .24),
                        blurRadius: selected ? 13 : 5, offset: const Offset(0, 4))],
                      border: Border.all(color: selected ? colors.onSurface :
                        Colors.transparent, width: 2.5)),
                    child: selected ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 24) : null),
                  const SizedBox(height: 7),
                  Text(palette['name'] as String, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w500)),
                ])),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 23),
        _settingsHeading(Icons.settings_suggest_rounded, 'نور انتخابونه'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: .55))),
          child: Column(children: [
            ListTile(
              leading: _settingsIcon(Icons.restart_alt_rounded, colors.primary),
              title: const Text('اصلي تنظیمات بېرته فعالول',
                style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('ټول رنګونه او فونټ لومړني حالت ته ستنوي.'),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => _showResetConfirmation(),
            ),
            Divider(height: 1, indent: 16, endIndent: 16,
              color: colors.outlineVariant.withValues(alpha: .5)),
            ListTile(
              leading: _settingsIcon(Icons.auto_stories_rounded, colors.secondary),
              title: const Text('ادبي خزانه', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('د پښتو شعر او ادب نړۍ'),
              trailing: const Text('۱.۰.۰', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Center(child: Text('په مینه، د پښتو ادب لپاره',
          style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w800))),
      ],
    );
  }

  Widget _appearanceChoice({required IconData icon, required String title,
    required bool selected, required VoidCallback onTap}) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(17), onTap: onTap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(17)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 19, color: selected ? colors.onPrimary : colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
            color: selected ? colors.onPrimary : colors.onSurfaceVariant)),
        ]),
      ),
    );
  }

  Widget _settingsIcon(IconData icon, Color color) => Container(
    width: 42, height: 42,
    decoration: BoxDecoration(color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(14)),
    child: Icon(icon, color: color));

  void _showResetConfirmation() {
    final colors = Theme.of(context).colorScheme;
    showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.restart_alt_rounded, color: colors.primary, size: 32),
      title: const Text('اصلي تنظیمات؟'),
      content: const Text('ایا غواړئ فونټ، رنګ او بڼه لومړني حالت ته ستانه کړئ؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext),
          child: const Text('نه، پرېږده')),
        FilledButton(onPressed: () {
          Navigator.pop(dialogContext);
          widget.onResetAppearance();
        }, child: const Text('هو، بېرته یې کړه')),
      ],
    ));
  }

  Widget _settingsHeading(IconData icon, String title) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 21),
        const SizedBox(width: 8),
        Text(title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
            color: colors.onSurface)),
      ],
    );
  }

  Widget _aboutPage() {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 950),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(opacity: value,
            child: Transform.translate(offset: Offset(0, 25 * (1 - value)), child: child)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [Color(0xFF123B32), Color(0xFF245B50), Color(0xFF9A6A2A)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: const Color(0xFF245B50).withValues(alpha: .22),
                blurRadius: 25, offset: const Offset(0, 11))],
            ),
            child: Column(children: [
              Container(width: 86, height: 86,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(color: const Color(0xFFFFD98A).withValues(alpha: .7), width: 1.3),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 15)]),
                child: const Icon(Icons.auto_stories_rounded, size: 48,
                  color: Color(0xFFFFD98A))),
              const SizedBox(height: 15),
              const Text('ادبي خزانه', style: TextStyle(color: Colors.white,
                fontSize: 27, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('د پښتو شعر او ادب رنګینه نړۍ',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 18),
              Container(height: 1, color: Colors.white24),
              const SizedBox(height: 14),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD98A), size: 16),
                SizedBox(width: 7),
                Text('ادب ژوندی وساتو، شعرونه خوندي کړو',
                  style: TextStyle(color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w700)),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 24),
        _aboutSectionTitle(Icons.people_alt_rounded, 'د دې پروژې ملګري'),
        const SizedBox(height: 11),
        _aboutPersonFeature(
          icon: Icons.code_rounded,
          role: 'د اپلیکیشن جوړوونکی',
          name: 'عبیدالله غفاري',
          description: 'د ادبي خزانې د مفکورې او تخنیکي جوړښت تر شا هڅاند کس؛ د پښتو ادب د مینه‌والو لپاره د یوې ښکلې او اسانه ډیجیټلي تجربې په جوړولو کې یې ونډه اخیستې ده.',
          accent: const Color(0xFF287C68), delay: 0),
        const SizedBox(height: 13),
        _aboutPersonFeature(
          icon: Icons.auto_awesome_rounded,
          role: 'ترتیب کوونکی',
          name: 'الحاج ډاکټر فریدون احرار',
          description: 'د ادبي خزانې د محتوا او ادبي چارو په ترتیب او سمون کې ونډه‌وال؛ د پښتو ژبې او ادب د ارزښتمنو اثارو د وړاندې کولو لپاره یې همکاري کړې ده.',
          accent: const Color(0xFFB77928), delay: 160),
        const SizedBox(height: 23),
        _aboutSectionTitle(Icons.menu_book_rounded, 'د ادبي خزانې په اړه'),
        const SizedBox(height: 11),
        Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: .55)),
            boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: .04),
              blurRadius: 16, offset: const Offset(0, 6))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _settingsIcon(Icons.format_quote_rounded, colors.primary),
              const SizedBox(width: 11),
              const Expanded(child: Text('زموږ موخه', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 12),
            Text('ادبي خزانه د پښتو ژبې د شعرونو او ادب د مینه‌والو لپاره یو ښکلی اپلیکیشن دی. موخه مو دا ده چې د پښتو شاعرۍ لوستل، لټول او د خوښې شعرونه ساتل اسانه او خوندور کړو.',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 12, height: 2, color: colors.onSurfaceVariant)),
            const SizedBox(height: 17),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _aboutFeatureChip(Icons.search_rounded, 'اسانه لټون'),
              _aboutFeatureChip(Icons.favorite_rounded, 'خوښ شعرونه'),
              _aboutFeatureChip(Icons.palette_rounded, 'شخصي بڼه'),
              _aboutFeatureChip(Icons.auto_stories_rounded, 'پښتو ادب'),
            ]),
          ]),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 18),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: .5))),
          child: Row(children: [
            Icon(Icons.verified_outlined, color: colors.primary, size: 25),
            const SizedBox(width: 11),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('د اپلیکیشن نسخه', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                SizedBox(height: 3),
                Text('ادبي خزانه • نسخه 1.0.0', style: TextStyle(fontSize: 11)),
              ])),
            const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB77928)),
          ]),
        ),
        const SizedBox(height: 18),
        Center(child: Text('په مینه، د پښتو ادب لپاره',
          style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.w900))),
      ],
    );
  }

  Widget _aboutSectionTitle(IconData icon, String title) {
    final colors = Theme.of(context).colorScheme;
    return Row(children: [
      Container(width: 34, height: 34,
        decoration: BoxDecoration(color: colors.primary.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(11)),
        child: Icon(icon, color: colors.primary, size: 19)),
      const SizedBox(width: 9),
      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
        color: colors.onSurface)),
    ]);
  }

  Widget _aboutFeatureChip(IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(color: colors.primary.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(13)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: colors.primary),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          color: colors.primary)),
      ]),
    );
  }

  Widget _aboutPersonFeature({
    required IconData icon,
    required String role,
    required String name,
    required String description,
    required Color accent,
    required int delay,
  }) {
    final colors = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 850 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 34 * (1 - value)),
          child: Transform.scale(
            scale: .94 + (.06 * value),
            child: child,
          ),
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              accent.withValues(alpha: .16),
              colors.surface,
              colors.surfaceContainerLow,
            ],
          ),
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: accent.withValues(alpha: .35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .12),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: .68)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(21),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .25),
                        blurRadius: 13,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 31),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role,
                          style: TextStyle(
                              color: accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 5),
                      Text(name,
                          style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Icon(Icons.verified_rounded, color: accent, size: 23),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withValues(alpha: .55), Colors.transparent],
                ),
              ),
            ),
            const SizedBox(height: 13),
            Text(description,
                textAlign: TextAlign.justify,
                style: TextStyle(
                    color: colors.onSurfaceVariant, fontSize: 12, height: 1.9)),
          ],
        ),
      ),
    );
  }

  void _listenAgain() {
    setState(() { _loadingPoems = true; _databaseError = null; });
    _reloadPoems();
  }

  Widget _emptyPoemsState({required IconData icon, required String title,
    required String subtitle, String? action, VoidCallback? onAction}) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 38),
      child: Container(
        width: double.infinity, padding: const EdgeInsets.fromLTRB(22, 28, 22, 26),
        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(30),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: .55)),
          boxShadow: [BoxShadow(color: colors.shadow.withValues(alpha: .05), blurRadius: 24, offset: const Offset(0, 9))]),
        child: Column(children: [
          Container(width: 78, height: 78,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primary.withValues(alpha: .13), colors.secondary.withValues(alpha: .18)]), borderRadius: BorderRadius.circular(25)),
            child: Icon(icon, size: 37, color: colors.primary)),
          const SizedBox(height: 17),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: colors.onSurface)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.9, color: colors.onSurfaceVariant)),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 17),
            FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.refresh_rounded), label: Text(action)),
          ],
        ]),
      ),
    );
  }

  void _openPoem(Poem poem) {
    _incrementPoemCounter(poem.id, 'views');
    Navigator.push(context, MaterialPageRoute(builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: PoemDetailScreen(poem: poem, ensureProfile: _ensureProfile,
        onLike: () => _likePoem(poem), onSave: () => _toggleFavorite(poem),
        onShare: () => _sharePoem(poem)),
    )));
  }

  Widget _statPill(IconData icon, int count) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(15)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 7), Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
    ]));

  Widget _poemCard(Poem poem) {
    final colors = Theme.of(context).colorScheme;
    final saved = favorites.contains(poem.id);
    return Card(clipBehavior: Clip.antiAlias, margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(onTap: () => _openPoem(poem),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: [colors.surface, colors.surfaceContainerLow.withValues(alpha: .8)]),
            border: Border(right: BorderSide(color: colors.secondary, width: 4))),
          child: Padding(padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (poem.imageUrl != null && poem.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    poem.imageUrl!,
                    width: double.infinity,
                    height: 168,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: colors.primary.withValues(alpha: .09), borderRadius: BorderRadius.circular(11)),
                  child: Text(poem.category, style: TextStyle(fontSize: 10, color: colors.primary, fontWeight: FontWeight.w800))),
                const Spacer(),
                IconButton.filledTonal(visualDensity: VisualDensity.compact,
                  tooltip: saved ? 'له خوښو لرې کول' : 'خوښ شعر',
                  onPressed: () => _toggleFavorite(poem),
                  icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: saved ? colors.error : colors.primary, size: 19)),
              ]),
              const SizedBox(height: 5),
              Text(poem.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: colors.primary)),
              if (poem.poet.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(poem.poet, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 13),
              Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(color: colors.surfaceContainerHighest.withValues(alpha: .45), borderRadius: BorderRadius.circular(17)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final line in poem.lines.take(3))
                    Padding(padding: const EdgeInsets.only(bottom: 5),
                      child: Text(line, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, height: 1.8, color: colors.onSurface, fontWeight: FontWeight.w500))),
                  if (poem.lines.length > 3) Text('... بشپړ شعر ولولئ', style: TextStyle(fontSize: 10, color: colors.primary, fontWeight: FontWeight.w800)),
                ])),
              const SizedBox(height: 13),
              Row(children: [
                _miniStat(Icons.visibility_outlined, poem.views),
                const SizedBox(width: 9), _miniStat(Icons.favorite_border_rounded, poem.likes),
                const SizedBox(width: 9), _miniStat(Icons.share_outlined, poem.shares),
                const SizedBox(width: 9), _miniStat(Icons.bookmark_border_rounded, poem.saves),
                const Spacer(), Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: colors.primary),
              ]),
            ]),
          ),
        )),
    );
  }

  Widget _miniStat(IconData icon, int value) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
    const SizedBox(width: 4), Text('$value', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
  ]);}


class EmbeddedAdminGate extends StatelessWidget {
  const EmbeddedAdminGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (auth.data == null) return const EmbeddedAdminLoginPage();
      return FutureBuilder<DatabaseEvent>(
        future: FirebaseDatabase.instance.ref('admins/${auth.data!.uid}').once(),
        builder: (context, role) {
          if (role.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final value = role.data?.snapshot.value;
          final allowed = value is Map && value['role'] == 'admin';
          if (!allowed) return Scaffold(
            appBar: AppBar(title: const Text('د اډمین اجازه')),
            body: Center(child: Padding(padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.gpp_bad_rounded, size: 58, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text('دا حساب د اډمین اجازه نه لري.'),
                const SizedBox(height: 14),
                FilledButton(onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) Navigator.pop(context);
                }, child: const Text('بندول')),
              ]))),
          );
          return const AdminHome();
        },
      );
    },
  );
}

class EmbeddedAdminLoginPage extends StatefulWidget {
  const EmbeddedAdminLoginPage({super.key});
  @override
  State<EmbeddedAdminLoginPage> createState() => _EmbeddedAdminLoginPageState();
}
class _EmbeddedAdminLoginPageState extends State<EmbeddedAdminLoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;
  Future<void> login() async {
    setState(() { loading = true; error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(), password: password.text);
    } on FirebaseAuthException catch (e) {
      setState(() => error = e.message ?? 'ننوتل بریالي نه شول.');
    } finally { if (mounted) setState(() => loading = false); }
  }
  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('د اډمین ننوتل')),
    body: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430),
        child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(height: 76, width: 76, alignment: Alignment.center,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF245B50), Color(0xFFB77928)]), borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 39)),
            const SizedBox(height: 18),
            const Text('د ادبي خزانې مدیریت', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 22),
            TextField(controller: email, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'ایمیل', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
            const SizedBox(height: 13),
            TextField(controller: password, obscureText: true,
              decoration: const InputDecoration(labelText: 'پټ نوم', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder())),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 18),
            FilledButton(onPressed: loading ? null : login,
              child: loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('ننوتل')),
          ],
        ))),
      ),
    )),
  );
}

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}
class _AdminHomeState extends State<AdminHome> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [const PoemsAdminPage(), const SimpleListAdmin(path: 'categories', title: 'کټګورۍ'),
      const SimpleListAdmin(path: 'poets', title: 'شاعران'), const GalleryAdminPage()];
    return Scaffold(
      appBar: AppBar(title: const Text('د ادبي خزانه مدیریت'),
        actions: [IconButton(onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout_rounded), tooltip: 'وتل')]),
      body: IndexedStack(index: tab, children: pages),
      floatingActionButton: tab == 0 ? FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoemEditor())),
        icon: const Icon(Icons.add_rounded), label: const Text('نوی شعر')) : null,
      bottomNavigationBar: NavigationBar(selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'شعرونه'),
          NavigationDestination(icon: Icon(Icons.category_outlined), label: 'کټګورۍ'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'شاعران'),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'ګالري'),
        ]),
    );
  }
}

class PoemsAdminPage extends StatelessWidget {
  const PoemsAdminPage({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<DatabaseEvent>(
    stream: FirebaseDatabase.instance.ref('poems').orderByChild('createdAt').onValue,
    builder: (context, snap) {
      if (snap.hasError) return Center(child: Text('ستونزه: ${snap.error}'));
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final raw = snap.data!.snapshot.value;
      if (raw is! Map) return const Center(child: Text('تر اوسه شعرونه نشته.'));
      final items = raw.entries.toList().reversed.toList();
      return ListView.separated(padding: const EdgeInsets.all(14), itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 9),
        itemBuilder: (context, i) {
          final id = items[i].key.toString();
          final data = Map<String, dynamic>.from(items[i].value as Map);
          return Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.auto_stories_rounded)),
            title: Text((data['title'] ?? 'بې‌عنوانه').toString(),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text((data['text'] ?? '').toString(), maxLines: 2,
              overflow: TextOverflow.ellipsis),
            trailing: Wrap(spacing: 0, children: [
              IconButton(
                tooltip: 'سمون',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PoemEditor(poemId: id, initialData: data))),
              ),
              IconButton(
                tooltip: 'ړنګول',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final ok = await showDialog<bool>(context: context, builder: (ctx) =>
                    Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
                      title: const Text('شعر ړنګول؟'),
                      content: const Text('دا شعر به له ډیټابېس څخه لرې شي.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('نه')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('هو، ړنګ یې کړه')),
                      ],
                    )));
                  if (ok == true) await FirebaseDatabase.instance.ref('poems/$id').remove();
                },
              ),
            ]),
          ));
        });
    },
  );
}

class SimpleListAdmin extends StatefulWidget {
  const SimpleListAdmin({super.key, required this.path, required this.title});
  final String path, title;
  @override
  State<SimpleListAdmin> createState() => _SimpleListAdminState();
}

class _SimpleListAdminState extends State<SimpleListAdmin> {
  bool get isCategory => widget.path == 'categories';

  Future<String?> _chooseGalleryImage() async {
    return showModalBottomSheet<String>(context: context, isScrollControlled: true, showDragHandle: true,
      builder: (ctx) => Directionality(textDirection: TextDirection.rtl,
        child: SizedBox(height: MediaQuery.of(ctx).size.height * .68,
          child: StreamBuilder<DatabaseEvent>(stream: FirebaseDatabase.instance.ref('gallery').onValue,
            builder: (ctx, snap) {
              final raw = snap.data?.snapshot.value;
              final items = raw is Map ? raw.entries.toList().reversed.toList() : <dynamic>[];
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              if (items.isEmpty) return const Center(child: Text('ګالري تشه ده؛ انځورونه لومړی هلته پورته کړئ.'));
              return GridView.builder(padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: items.length, itemBuilder: (_, i) {
                  final d = Map<String, dynamic>.from(items[i].value as Map);
                  return InkWell(onTap: () => Navigator.pop(ctx, d['url']?.toString()),
                    child: Image.network((d['url'] ?? '').toString(), fit: BoxFit.cover));
                });
            }))));
  }

  Future<void> _editItem({String? id, String? oldName}) async {
    final controller = TextEditingController(text: oldName ?? '');
    final colors = Theme.of(context).colorScheme;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Text(id == null ? 'نوې ${widget.title.substring(0, widget.title.length - 1)}' : 'سمون'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 55,
            decoration: InputDecoration(
              hintText: isCategory ? 'لکه: غزل، حماسي، عرفاني...' : 'د شاعر نوم',
              prefixIcon: Icon(isCategory ? Icons.category_rounded : Icons.person_rounded),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(alpha: .45),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(17)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('بندول')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('خوندي کول')),
          ],
        ),
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    try {
      // د شاعر یا کټګورۍ انځور مستقیم له موبایل څخه وټاکئ او Cloudinary ته یې پورته کړئ.
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 82, maxWidth: 1800);
      if (!mounted) return;
      String? imageUrl;
      if (pickedImage != null) {
        imageUrl = await uploadImageToCloudinary(pickedImage);
      }
      final ref = FirebaseDatabase.instance.ref(widget.path);
      final data = <String, dynamic>{
        'name': name.trim(),
        if (imageUrl != null) 'imageUrl': imageUrl,
      };
      if (id == null) {
        data['createdAt'] = ServerValue.timestamp;
        await ref.push().set(data);
      } else {
        data['updatedAt'] = ServerValue.timestamp;
        await ref.child(id).update(data);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(imageUrl == null
          ? 'نوم خوندي شو؛ انځور ونه ټاکل شو.'
          : 'نوم او انځور دواړه خوندي شول.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خوندي کول ناکام شول: $e')));
    }
  }

  Future<void> _deleteItem(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('ړنګول تاییدوئ؟'),
          content: const Text('دا توکی به له ډیټابېس څخه لرې شي.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('نه')),
            FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('هو، ړنګ یې کړه')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseDatabase.instance.ref('${widget.path}/$id').remove();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ړنګول ناکام شول: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref(widget.path).onValue,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('ستونزه: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final raw = snap.data!.snapshot.value;
        final entries = raw is Map ? raw.entries.toList() : <dynamic>[];
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight, end: Alignment.bottomLeft,
                  colors: isCategory
                    ? [const Color(0xFF263F78), const Color(0xFF7762C8), const Color(0xFFB77BC5)]
                    : [const Color(0xFF174E48), const Color(0xFF398D79), const Color(0xFFB28A4A)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: .15),
                  blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Row(children: [
                Container(width: 54, height: 54,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .17),
                    borderRadius: BorderRadius.circular(18)),
                  child: Icon(isCategory ? Icons.category_rounded : Icons.edit_note_rounded,
                    color: Colors.white, size: 29)),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.title, style: const TextStyle(color: Colors.white,
                    fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('${entries.length} ثبت شوي', style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
                ])),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .2),
                    foregroundColor: Colors.white),
                  onPressed: () => _editItem(),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: 'نوی اضافه کول',
                ),
              ]),
            ),
          ),
          Expanded(
            child: entries.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isCategory ? Icons.category_outlined : Icons.person_search_rounded,
                    size: 54, color: colors.outline),
                  const SizedBox(height: 12),
                  Text('تر اوسه ${widget.title} نه دي ثبت شوي.',
                    style: TextStyle(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: () => _editItem(),
                    icon: const Icon(Icons.add_rounded), label: const Text('لومړی توکی اضافه کړه')),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 9),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final id = entry.key.toString();
                    final value = entry.value;
                    final label = (value is Map ? (value['name'] ?? '') : value).toString();
                    final palette = [
                      const Color(0xFF5472C8), const Color(0xFF259B86),
                      const Color(0xFFB17A38), const Color(0xFF9A65B5),
                    ];
                    final tint = palette[index % palette.length];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        leading: Container(width: 46, height: 46,
                          decoration: BoxDecoration(color: tint.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(15)),
                          child: Icon(isCategory ? Icons.auto_awesome_mosaic_rounded : Icons.person_rounded,
                            color: tint)),
                        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: Text(isCategory ? 'د شعرونو کټګوري' : 'شاعر',
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
                        trailing: Wrap(spacing: 0, children: [
                          IconButton(onPressed: () => _editItem(id: id, oldName: label),
                            icon: const Icon(Icons.edit_outlined), tooltip: 'سمون'),
                          IconButton(onPressed: () => _deleteItem(id),
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            tooltip: 'ړنګول'),
                        ]),
                      ),
                    );
                  },
                ),
          ),
        ]);
      },
    );
  }
}

class PoetrySearchPage extends StatefulWidget {
  const PoetrySearchPage({super.key, required this.poems, required this.onPoemTap});
  final List<Poem> poems;
  final ValueChanged<Poem> onPoemTap;

  @override
  State<PoetrySearchPage> createState() => _PoetrySearchPageState();
}

class _PoetrySearchPageState extends State<PoetrySearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  String _category = 'ټولې کټګورۍ';
  String _poet = 'ټول شاعران';
  String _field = 'ټول';
  String _sort = 'اړوند';
  bool _onlyWithImage = false;

  List<String> get _categories => ['ټولې کټګورۍ',
    ...widget.poems.map((p) => p.category).where((v) => v.trim().isNotEmpty).toSet().toList()..sort()];
  List<String> get _poets => ['ټول شاعران',
    ...widget.poems.map((p) => p.poet).where((v) => v.trim().isNotEmpty).toSet().toList()..sort()];

  List<Poem> get _results {
    final q = _query.trim().toLowerCase();
    var result = widget.poems.where((p) {
      final title = p.title.toLowerCase();
      final poet = p.poet.toLowerCase();
      final category = p.category.toLowerCase();
      final body = ('${p.text} ${p.lines.join(' ')}').toLowerCase();
      final matchesQuery = q.isEmpty ||
        (_field == 'ټول' && '$title $poet $category $body'.contains(q)) ||
        (_field == 'عنوان' && title.contains(q)) ||
        (_field == 'شاعر' && poet.contains(q)) ||
        (_field == 'متن' && body.contains(q));
      return matchesQuery &&
        (_category == 'ټولې کټګورۍ' || p.category == _category) &&
        (_poet == 'ټول شاعران' || p.poet == _poet) &&
        (!_onlyWithImage || (p.imageUrl ?? '').isNotEmpty);
    }).toList();
    if (_sort == 'ډېر لوستل شوي') {
      result.sort((a, b) => b.views.compareTo(a.views));
    } else if (_sort == 'عنوان') {
      result.sort((a, b) => a.title.compareTo(b.title));
    }
    return result;
  }

  Future<void> _showFilterSettings() async {
    final c = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget optionChips({
              required String title,
              required List<String> options,
              required String selected,
              required ValueChanged<String> onSelected,
            }) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(title, style: TextStyle(
                      color: c.onSurface, fontSize: 14, fontWeight: FontWeight.w900,
                    )),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((value) {
                      final active = selected == value;
                      return ChoiceChip(
                        label: Text(value, style: TextStyle(
                          color: active ? Colors.white : c.onSurface,
                          fontSize: 12, fontWeight: FontWeight.w700,
                        )),
                        selected: active,
                        selectedColor: c.primary,
                        backgroundColor: c.surfaceContainerHighest,
                        checkmarkColor: Colors.white,
                        side: BorderSide(color: active ? c.primary : c.outlineVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        onSelected: (_) {
                          setState(() => onSelected(value));
                          setSheetState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * .86,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: .16),
                  blurRadius: 24, offset: const Offset(0, -5),
                )],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(width: 42, height: 4, decoration: BoxDecoration(
                    color: c.outlineVariant, borderRadius: BorderRadius.circular(10),
                  )),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 17, 16, 12),
                    child: Row(children: [
                      Container(width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: c.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.tune_rounded, color: c.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تنظیمات او فلټرونه', style: TextStyle(
                            color: c.onSurface, fontSize: 17, fontWeight: FontWeight.w900,
                          )),
                          Text('د لټون پایلې خپلې خوښې سره برابرې کړئ',
                            style: TextStyle(color: c.onSurfaceVariant, fontSize: 11)),
                        ],
                      )),
                      IconButton(
                        tooltip: 'بندول',
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: Icon(Icons.close_rounded, color: c.onSurfaceVariant),
                      ),
                    ]),
                  ),
                  Divider(height: 1, color: c.outlineVariant.withValues(alpha: .5)),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                      children: [
                        optionChips(
                          title: 'د لټون ساحه',
                          options: const ['ټول', 'عنوان', 'شاعر', 'متن'],
                          selected: _field,
                          onSelected: (v) => _field = v,
                        ),
                        const SizedBox(height: 20),
                        optionChips(
                          title: 'کټګوري',
                          options: _categories,
                          selected: _category,
                          onSelected: (v) => _category = v,
                        ),
                        const SizedBox(height: 20),
                        optionChips(
                          title: 'شاعر',
                          options: _poets,
                          selected: _poet,
                          onSelected: (v) => _poet = v,
                        ),
                        const SizedBox(height: 20),
                        optionChips(
                          title: 'ترتیب',
                          options: const ['اړوند', 'ډېر لوستل شوي', 'عنوان'],
                          selected: _sort,
                          onSelected: (v) => _sort = v,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          secondary: Icon(Icons.image_search_rounded, color: c.primary),
                          title: Text('یوازې انځور لرونکي شعرونه',
                            style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w800)),
                          subtitle: Text('هغه شعرونه وښیه چې انځور لري',
                            style: TextStyle(color: c.onSurfaceVariant, fontSize: 11)),
                          value: _onlyWithImage,
                          activeColor: c.primary,
                          onChanged: (v) {
                            setState(() => _onlyWithImage = v);
                            setSheetState(() {});
                          },
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('پایلې ښکاره کړه'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final results = _results;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(
        title: const Text('عمومي لټون'),
        actions: [
          IconButton(tooltip: 'پاکول', onPressed: () {
            _controller.clear();
            setState(() { _query = ''; _category = 'ټولې کټګورۍ'; _poet = 'ټول شاعران'; _field = 'ټول'; _sort = 'اړوند'; _onlyWithImage = false; });
          }, icon: const Icon(Icons.restart_alt_rounded)),
        ],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Container(
            decoration: BoxDecoration(color: c.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.outlineVariant.withValues(alpha: .55))),
            child: TextField(
              controller: _controller, focusNode: _focusNode, autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'د شعر، شاعر، کټګورۍ یا متن لټون...',
                prefixIcon: Icon(Icons.search_rounded, color: c.primary),
                suffixIcon: _query.isEmpty ? null : IconButton(
                  onPressed: () { _controller.clear(); setState(() => _query = ''); },
                  icon: const Icon(Icons.close_rounded)),
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 17)),
            ),
          )),
        SizedBox(height: 42, child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal,
          children: ['ټول', 'عنوان', 'شاعر', 'متن'].map((v) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(v, style: TextStyle(
                color: _field == v ? c.onPrimary : c.onSurface,
                fontWeight: FontWeight.w800,
              )),
              selected: _field == v,
              selectedColor: c.primary,
              backgroundColor: c.surface,
              side: BorderSide(color: c.outlineVariant.withValues(alpha: .7)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (_) => setState(() => _field = v),
            ),
          )).toList(),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.primaryContainer.withValues(alpha: .65),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${results.length} پایلې', style: TextStyle(
                color: c.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.w800,
              )),
            ),
            const Spacer(),
            Material(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _showFilterSettings,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(Icons.tune_rounded, color: c.onPrimaryContainer, size: 21),
                ),
              ),
            ),
          ]),
        ),

        Expanded(child: results.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.search_off_rounded, size: 54, color: c.outline),
              const SizedBox(height: 10),
              const Text('هیڅ شعر پیدا نه شو.'),
              const SizedBox(height: 5),
              Text('د لټون کلمه یا فلټرونه بدل کړئ.',
                style: TextStyle(color: c.onSurfaceVariant, fontSize: 12)),
            ]))
          : ListView.separated(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(14),
              itemCount: results.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final poem = results[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => widget.onPoemTap(poem),
                    leading: Container(width: 44, height: 44,
                      decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.auto_stories_rounded, color: c.primary)),
                    title: Text(poem.title.isEmpty ? 'بې عنوانه شعر' : poem.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text([poem.poet, poem.category].where((v) => v.isNotEmpty).join(' • '),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Icon(Icons.chevron_left_rounded, color: c.onSurfaceVariant),
                  ),
                );
              },
            )),
      ]),
    ));
  }
}

class _TypingCoupletBox extends StatefulWidget {
  const _TypingCoupletBox({required this.poems});
  final List<Poem> poems;
  @override
  State<_TypingCoupletBox> createState() => _TypingCoupletBoxState();
}

class _TypingCoupletBoxState extends State<_TypingCoupletBox> {
  Timer? _timer;
  int _poemIndex = 0;
  int _charIndex = 0;
  int _holdTicks = 0;

  List<String> _couplet(Poem poem) {
    String clean(String value) => value
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
    final lines = poem.lines
        .expand((line) => clean(line).split(RegExp(r'[\r\n]+')))
        .map(clean).where((line) => line.isNotEmpty).toList();
    if (lines.length >= 2) return lines.take(2).toList();
    final text = clean(poem.text);
    final textLines = text.split(RegExp(r'[\r\n]+')).map(clean)
        .where((line) => line.isNotEmpty).toList();
    if (textLines.length >= 2) return textLines.take(2).toList();
    final words = text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    if (words.length < 2) return [text];
    final middle = (words.length / 2).ceil();
    return [words.take(middle).join(' '), words.skip(middle).join(' ')];
  }

  String get _currentText {
    if (widget.poems.isEmpty) return '';
    return _couplet(widget.poems[_poemIndex % widget.poems.length]).join('\n');
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 65), (_) {
      if (!mounted || widget.poems.isEmpty) return;
      setState(() {
        if (_charIndex < _currentText.length) {
          _charIndex++;
        } else if (_holdTicks++ > 32) {
          _poemIndex = (_poemIndex + 1) % widget.poems.length;
          _charIndex = 0;
          _holdTicks = 0;
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant _TypingCoupletBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poems.length != widget.poems.length) {
      _poemIndex = 0;
      _charIndex = 0;
      _holdTicks = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final poem = widget.poems.isEmpty ? null : widget.poems[_poemIndex % widget.poems.length];
    final shown = _currentText.substring(0, _charIndex.clamp(0, _currentText.length));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [c.primaryContainer.withValues(alpha: .72), c.surface, const Color(0xFFB77928).withValues(alpha: .12)]),
          border: Border.all(color: c.primary.withValues(alpha: .18)),
          boxShadow: [BoxShadow(color: c.primary.withValues(alpha: .08), blurRadius: 16, offset: const Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.format_quote_rounded, color: c.primary, size: 19),
            const SizedBox(width: 6),
            Text('د ورځې دوه بيتي', style: TextStyle(color: c.primary, fontSize: 11, fontWeight: FontWeight.w900)),
            const Spacer(),
            Container(width: 6, height: 6, decoration: BoxDecoration(color: c.tertiary, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('ادبي شېبې', style: TextStyle(color: c.onSurfaceVariant, fontSize: 9)),
          ]),
          const SizedBox(height: 9),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Text(
              shown + (_charIndex < _currentText.length ? '▏' : ''),
              key: ValueKey(_poemIndex),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurface, fontSize: 14, height: 1.9, fontWeight: FontWeight.w800),
            ),
          ),
          if (poem != null && poem.poet.isNotEmpty) ...[
            const SizedBox(height: 5),
            Align(alignment: Alignment.centerLeft,
              child: Text('— ${poem.poet}', style: TextStyle(color: c.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w700))),
          ],
        ]),
      ),
    );
  }
}

class CollectionPoemsPage extends StatefulWidget {
  const CollectionPoemsPage({super.key, required this.title, required this.imageUrl,
    required this.poems, required this.collectionId, required this.onPoemTap,
    this.isCategory = false, this.categoryIcon, this.categoryColor});
  final String title, imageUrl, collectionId;
  final List<Poem> poems;
  final bool isCategory;
  final IconData? categoryIcon;
  final Color? categoryColor;
  final ValueChanged<Poem> onPoemTap;
  @override
  State<CollectionPoemsPage> createState() => _CollectionPoemsPageState();
}

class _CollectionPoemsPageState extends State<CollectionPoemsPage> {
  late final DatabaseReference _viewsRef;
  static const double _expandedHeaderHeight = 318;
  static const double _collapsedHeaderHeight = 76;

  @override
  void initState() {
    super.initState();
    final group = widget.isCategory ? 'categoryViews' : 'poetViews';
    _viewsRef = FirebaseDatabase.instance.ref('$group/${widget.collectionId}');
    _viewsRef.runTransaction((value) {
      final current = value is num ? value.toInt() : 0;
      return Transaction.success(current + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _CollectionHeaderDelegate(
              title: widget.title,
              imageUrl: widget.imageUrl,
              isCategory: widget.isCategory,
              categoryIcon: widget.categoryIcon,
              categoryColor: widget.categoryColor,
              poemCount: widget.poems.length,
              views: _viewsRef,
              expandedHeight: _expandedHeaderHeight,
              collapsedHeight: _collapsedHeaderHeight,
              background: c.surface,
              foreground: c.onSurface,
            ),
          ),
          if (widget.poems.isEmpty)
            const SliverFillRemaining(hasScrollBody: false,
              child: Center(child: Text('په دې برخه کې تر اوسه شعرونه نشته.')))
          else
            SliverPadding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              sliver: SliverList(delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _collectionPoemTile(context, widget.poems[index])),
                childCount: widget.poems.length))),
        ],
      ),
      ),
    ));
  }

  Widget _collectionPoemTile(BuildContext context, Poem poem) {
    final c = Theme.of(context).colorScheme;
    return Card(child: InkWell(borderRadius: BorderRadius.circular(20),
      onTap: () => widget.onPoemTap(poem),
      child: Padding(padding: const EdgeInsets.all(15), child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(
          color: c.primaryContainer, borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.auto_stories_rounded, color: c.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(poem.title.isEmpty ? 'بې عنوانه شعر' : poem.title, maxLines: 1,
            overflow: TextOverflow.ellipsis, style: TextStyle(color: c.onSurface, fontWeight: FontWeight.w900)),
          if (poem.poet.isNotEmpty) Text(poem.poet,
            style: TextStyle(color: c.onSurfaceVariant, fontSize: 11)),
        ])),
        Icon(Icons.chevron_left_rounded, color: c.onSurfaceVariant),
      ]))));
  }
}

class _CollectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CollectionHeaderDelegate({
    required this.title, required this.imageUrl, required this.isCategory,
    this.categoryIcon, this.categoryColor,
    required this.poemCount, required this.views, required this.expandedHeight,
    required this.collapsedHeight, required this.background, required this.foreground,
  });
  final String title, imageUrl;
  final bool isCategory;
  final IconData? categoryIcon;
  final Color? categoryColor;
  final int poemCount;
  final DatabaseReference views;
  final double expandedHeight, collapsedHeight;
  final Color background, foreground;

  @override
  double get maxExtent => expandedHeight;
  @override
  double get minExtent => collapsedHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    final avatarSize = 88 - (44 * t);
    final avatarRight = ((MediaQuery.sizeOf(context).width - avatarSize) / 2) * (1 - t) + 64 * t;
    final avatarTop = 132 - (118 * t);
    final titleTop = 222 - (198 * t);
    
    final bannerOpacity = (1 - t * 1.15).clamp(0.0, 1.0);
    final expandedTextOpacity = (1 - t * 1.4).clamp(0.0, 1.0);
    final collapsedTextOpacity = ((t - .55) / .35).clamp(0.0, 1.0);

    return Material(
      color: background,
      elevation: overlapsContent || t > .92 ? 3 : 0,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned(
          top: 8, left: 16, right: 16, height: 170,
          child: Opacity(opacity: bannerOpacity, child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(fit: StackFit.expand, children: [
              if (imageUrl.isNotEmpty)
                Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _headerFallback())
              else _headerFallback(),
              DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: .04), Colors.black.withValues(alpha: .48)]))),
            ]),
          )),
        ),
        Positioned(
          top: 8, right: 8,
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: Icon(Icons.arrow_forward_rounded,
              color: t < .8 ? Colors.white : foreground),
          ),
        ),
        Positioned(
          top: avatarTop, right: avatarRight,
          child: Container(
            width: avatarSize, height: avatarSize,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, color: background,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 12, offset: const Offset(0, 3))]),
            child: ClipOval(child: imageUrl.isNotEmpty
              ? Image.network(imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _avatarFallback())
              : _avatarFallback()),
          ),
        ),
        Positioned(
          top: titleTop, left: 0, right: 0,
          child: Opacity(opacity: expandedTextOpacity,
            child: Align(
              alignment: Alignment.lerp(Alignment.center, Alignment.centerRight, t)!,
              child: Padding(padding: EdgeInsets.only(left: 20, right: 20 + 96 * t),
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: foreground, fontSize: 20, fontWeight: FontWeight.w900))),
            )),
        ),
        Positioned(
          top: 270, right: 18, left: 18,
          child: Opacity(opacity: expandedTextOpacity,
            child: Row(children: [
              _headerStat(Icons.menu_book_rounded, '$poemCount شعرونه', foreground),
              const SizedBox(width: 18),
              StreamBuilder<DatabaseEvent>(stream: views.onValue,
                builder: (context, snapshot) {
                  final value = snapshot.data?.snapshot.value;
                  final count = value is num ? value.toInt() : 0;
                  return _headerStat(Icons.visibility_rounded, '$count لیدونکي', foreground);
                }),
            ]),
          ),
        ),
        Positioned(
          top: 16, right: 116, left: 60,
          child: Opacity(opacity: collapsedTextOpacity,
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: foreground, fontSize: 17, fontWeight: FontWeight.w900))),
        ),
      ]),
    );
  }

  Widget _headerFallback() => Container(
    decoration: const BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topRight, end: Alignment.bottomLeft,
      colors: [Color(0xFF123B32), Color(0xFF286B5D), Color(0xFFB77928)])),
    child: const Center(child: Icon(Icons.auto_stories_rounded, color: Colors.white70, size: 42)),
  );

  Widget _avatarFallback() => Container(
    color: (categoryColor ?? const Color(0xFF286B5D)).withValues(alpha: .20),
    child: Icon(isCategory
        ? (categoryIcon ?? Icons.category_rounded)
        : Icons.person_rounded,
      color: categoryColor ?? const Color(0xFF286B5D), size: 42),
  );

  Widget _headerStat(IconData icon, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color.withValues(alpha: .75), size: 16),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    ],
  );

  @override
  bool shouldRebuild(covariant _CollectionHeaderDelegate oldDelegate) =>
      title != oldDelegate.title || imageUrl != oldDelegate.imageUrl ||
      poemCount != oldDelegate.poemCount || views != oldDelegate.views ||
      expandedHeight != oldDelegate.expandedHeight ||
      collapsedHeight != oldDelegate.collapsedHeight ||
      background != oldDelegate.background || foreground != oldDelegate.foreground ||
      isCategory != oldDelegate.isCategory;
}

class PoemDetailScreen extends StatefulWidget {
  const PoemDetailScreen({super.key, required this.poem, required this.ensureProfile,
    required this.onLike, required this.onSave, required this.onShare});
  final Poem poem;
  final Future<Map<String, String>?> Function() ensureProfile;
  final Future<void> Function() onLike, onSave, onShare;
  @override
  State<PoemDetailScreen> createState() => _PoemDetailScreenState();
}

class _PoemDetailScreenState extends State<PoemDetailScreen> {
  final commentController = TextEditingController();
  bool sending = false, liked = false, saved = false;
  bool isAdmin = false;
  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snap = await FirebaseDatabase.instance.ref('admins/${user.uid}/role').get();
      if (mounted) setState(() => isAdmin = snap.value == 'admin');
    } catch (_) {}
  }

  Future<void> _toggleCommentLike(String commentId, bool alreadyLiked) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    final ref = FirebaseDatabase.instance.ref('comments/${widget.poem.id}/$commentId/likes/${user.uid}');
    try {
      if (alreadyLiked) {
        await ref.remove();
      } else {
        await ref.set(true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لایک ثبت نه شو: $e')));
    }
  }

  Future<void> _replyToComment(String commentId) async {
    if (!isAdmin) return;
    final controller = TextEditingController();
    final reply = await showModalBottomSheet<String>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (ctx) => Directionality(textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('د اډمین ځواب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(controller: controller, autofocus: true, minLines: 2, maxLines: 5,
              maxLength: 500, decoration: const InputDecoration(hintText: 'خپل ځواب ولیکئ...')),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) Navigator.pop(ctx, controller.text.trim());
              }, child: const Text('ځواب خپرول'))),
          ]),
        )),
    );
    controller.dispose();
    if (reply == null || reply.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseDatabase.instance.ref('comments/${widget.poem.id}/$commentId/adminReply').set({
        'text': reply,
        'adminUid': user.uid,
        'adminName': user.displayName ?? 'د ادبي خزانه اداره',
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ځواب ثبت نه شو: $e')));
    }
  }

  Future<void> _replyAsUser(String commentId) async {
    final profile = await widget.ensureProfile();
    if (profile == null) return;
    final controller = TextEditingController();
    final value = await showModalBottomSheet<String>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (ctx) => Directionality(textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('تبصرې ته ځواب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(controller: controller, autofocus: true, minLines: 2, maxLines: 5,
              maxLength: 500, decoration: const InputDecoration(hintText: 'خپل ځواب ولیکئ...')),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) Navigator.pop(ctx, controller.text.trim());
              }, child: const Text('ځواب خپرول'))),
          ]),
        )),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseDatabase.instance.ref('comments/${widget.poem.id}/$commentId/replies').push().set({
        'uid': user.uid,
        'displayName': profile['name'],
        'avatarUrl': profile['photoUrl'] ?? '',
        'text': value,
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ځواب ثبت نه شو: $e')));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    if (!isAdmin) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) =>
      Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
        title: const Text('تبصره ړنګول؟'),
        content: const Text('دا تبصره به د ټولو لوستونکو لپاره حذف شي.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('بندول')),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('هو، ړنګول')),
        ],
      )));
    if (confirm != true) return;
    try {
      await FirebaseDatabase.instance.ref('comments/${widget.poem.id}/$commentId').remove();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تبصره حذف نه شوه: $e')));
    }
  }

  @override
  void dispose() { commentController.dispose(); super.dispose(); }

  Future<void> _sendComment() async {
    final body = commentController.text.trim();
    if (body.isEmpty || sending) return;
    final profile = await widget.ensureProfile();
    if (profile == null) return;
    setState(() => sending = true);
    try {
      await FirebaseDatabase.instance.ref('comments/${widget.poem.id}').push().set({
        'uid': profile['uid'], 'displayName': profile['name'], 'avatarUrl': profile['photoUrl'] ?? '', 'text': body,
        'createdAt': ServerValue.timestamp,
      });
      commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تبصره ثبت نه شوه: $e')));
    } finally { if (mounted) setState(() => sending = false); }
  }

  Future<void> _report() async {
    final profile = await widget.ensureProfile();
    if (profile == null) return;
    final reason = await showModalBottomSheet<String>(context: context, showDragHandle: true,
      builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(16), child: Text('د شعر په اړه راپور',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          ...['ناسم یا سپکونکی متن', 'د لیکنې ناسم نسبت', 'تکراري خپرونه', 'بله ستونزه'].map((v) =>
            ListTile(leading: const Icon(Icons.flag_outlined), title: Text(v),
              onTap: () => Navigator.pop(ctx, v))),
          const SizedBox(height: 12),
        ]))));
    if (reason == null) return;
    try {
      await FirebaseDatabase.instance.ref('reports/${widget.poem.id}').push().set({
        'uid': profile['uid'], 'displayName': profile['name'], 'reason': reason,
        'status': 'new', 'createdAt': ServerValue.timestamp,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ستاسو راپور ثبت شو. مننه.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('راپور ثبت نه شو: $e')));
    }
  }

  String _date(dynamic value) {
    final ms = value is num ? value.toInt() : int.tryParse('$value');
    if (ms == null) return 'همدا اوس';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final poem = widget.poem;
    return Scaffold(
      appBar: AppBar(title: const Text('د شعر بشپړ متن'),
        actions: [IconButton(tooltip: 'راپور ورکول', onPressed: _report, icon: const Icon(Icons.flag_outlined))]),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 28), children: [
        Container(clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: c.primary.withValues(alpha: .18), blurRadius: 22, offset: const Offset(0, 9))]),
          child: Stack(children: [
            Positioned.fill(child: (poem.imageUrl ?? '').isNotEmpty
              ? Image.network(poem.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const DecoratedBox(decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
                      colors: [Color(0xFF123B32), Color(0xFF286B5D), Color(0xFFB77928)]))))
              : const DecoratedBox(decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
                    colors: [Color(0xFF123B32), Color(0xFF286B5D), Color(0xFFB77928)])))),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: .18), Colors.black.withValues(alpha: .72)])))),
            Positioned(left: -20, top: -25, child: Icon(Icons.format_quote_rounded, size: 145, color: Colors.white.withValues(alpha: .12))),
            Padding(padding: const EdgeInsets.fromLTRB(22, 25, 22, 23),
              child: Column(children: [
                Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.auto_stories_rounded, color: Color(0xFFFFD98A))),
                const SizedBox(height: 14),
                Text(poem.title, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, height: 1.55, fontWeight: FontWeight.w900)),
                if (poem.poet.isNotEmpty) ...[const SizedBox(height: 8), Text(poem.poet, style: const TextStyle(color: Colors.white70, fontSize: 13))],
                const SizedBox(height: 14), Container(height: 1, color: Colors.white38),
                const SizedBox(height: 11), Text(poem.category, style: const TextStyle(color: Color(0xFFFFD98A), fontSize: 12)),
              ])),
          ])),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.fromLTRB(21, 26, 21, 26),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
              colors: [c.surface.withValues(alpha: .97), c.primaryContainer.withValues(alpha: .38), c.surface.withValues(alpha: .97)]),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: c.outlineVariant.withValues(alpha: .65)),
            boxShadow: [BoxShadow(color: c.primary.withValues(alpha: .07), blurRadius: 18, offset: const Offset(0, 5))]),
          child: SelectableText(poem.text, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, height: 2.25, fontWeight: FontWeight.w600))),
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.spaceEvenly, spacing: 9, runSpacing: 9, children: [
          _stat(Icons.visibility_outlined, poem.views + 1), _stat(Icons.favorite_border_rounded, poem.likes),
          _stat(Icons.share_outlined, poem.shares), _stat(Icons.bookmark_border_rounded, poem.saves)]),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: FilledButton.tonalIcon(onPressed: () async {
            await widget.onLike(); if (mounted) setState(() => liked = true);
          }, icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded),
            label: Text(liked ? 'خوښ شوی' : 'خوښول'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton.tonalIcon(onPressed: () async {
            await widget.onSave(); if (mounted) setState(() => saved = !saved);
          }, icon: Icon(saved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined),
            label: Text(saved ? 'خوندي شو' : 'خوندي کول'))),
          const SizedBox(width: 8),
          IconButton.filledTonal(onPressed: widget.onShare, icon: const Icon(Icons.share_rounded)),
        ]),
        const SizedBox(height: 25),
        Row(children: [
          Icon(Icons.forum_rounded, color: c.primary), const SizedBox(width: 9),
          const Expanded(child: Text('د لوستونکو نظرونه', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
          StreamBuilder<DatabaseEvent>(stream: FirebaseDatabase.instance.ref('comments/${poem.id}').onValue,
            builder: (context, snap) { final v = snap.data?.snapshot.value; return Text('${v is Map ? v.length : 0} تبصرې',
              style: TextStyle(color: c.onSurfaceVariant, fontSize: 11)); }),
        ]),
        const SizedBox(height: 11),
        Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: c.surface,
          borderRadius: BorderRadius.circular(20), border: Border.all(color: c.outlineVariant.withValues(alpha: .5))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: TextField(controller: commentController, minLines: 1, maxLines: 4, maxLength: 500,
              decoration: InputDecoration(hintText: 'خپل نظر ولیکئ...', counterText: '', filled: true,
                fillColor: c.surfaceContainerHighest.withValues(alpha: .55),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: sending ? null : _sendComment,
              icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded)),
          ])),
        const SizedBox(height: 10),
        StreamBuilder<DatabaseEvent>(stream: FirebaseDatabase.instance.ref('comments/${poem.id}').onValue,
          builder: (context, snap) {
            if (snap.hasError) return const Text('تبصرې نه لوډ کېږي.');
            if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator()));
            final raw = snap.data!.snapshot.value;
            if (raw is! Map || raw.isEmpty) return Padding(padding: const EdgeInsets.all(22),
              child: Center(child: Text('تر اوسه تبصره نشته. لومړی خپل نظر ولیکئ.', style: TextStyle(color: c.onSurfaceVariant, fontSize: 12))));
            final entries = raw.entries.toList().reversed.toList();
            return Column(children: entries.map((entry) {
              final data = Map<String, dynamic>.from(entry.value as Map);
              final name = (data['displayName'] ?? 'لوستونکی').toString();
              final commentId = entry.key.toString();
              final user = FirebaseAuth.instance.currentUser;
              final likes = data['likes'] is Map ? Map<String, dynamic>.from(data['likes'] as Map) : <String, dynamic>{};
              final likedByMe = user != null && likes[user.uid] == true;
              final reply = data['adminReply'] is Map
                  ? Map<String, dynamic>.from(data['adminReply'] as Map) : null;
              return Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: c.surface,
                  borderRadius: BorderRadius.circular(18), border: Border.all(color: c.outlineVariant.withValues(alpha: .4))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    CircleAvatar(radius: 18, backgroundColor: c.primaryContainer,
                      backgroundImage: (data['avatarUrl'] ?? '').toString().isNotEmpty
                          ? NetworkImage(data['avatarUrl'].toString()) : null,
                      child: (data['avatarUrl'] ?? '').toString().isEmpty
                          ? Text(name.isEmpty ? 'ل' : name.characters.first, style: TextStyle(color: c.onPrimaryContainer, fontWeight: FontWeight.w900))
                          : null),
                    const SizedBox(width: 9), Expanded(child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
                    Text(_date(data['createdAt']), style: TextStyle(fontSize: 9, color: c.onSurfaceVariant)),
                    if (isAdmin) PopupMenuButton<String>(
                      tooltip: 'د تبصرې اداره',
                      onSelected: (v) {
                        if (v == 'reply') _replyToComment(commentId);
                        if (v == 'delete') _deleteComment(commentId);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'reply', child: ListTile(
                          dense: true, leading: Icon(Icons.reply_rounded), title: Text('ځواب ورکول'))),
                        PopupMenuItem(value: 'delete', child: ListTile(
                          dense: true, leading: Icon(Icons.delete_outline_rounded), title: Text('تبصره ړنګول'))),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 9),
                  Text((data['text'] ?? '').toString(), style: const TextStyle(fontSize: 13, height: 1.7)),
                  Row(children: [
                    TextButton.icon(
                      onPressed: () => _toggleCommentLike(commentId, likedByMe),
                      icon: Icon(likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 17, color: likedByMe ? c.error : c.onSurfaceVariant),
                      label: Text('${likes.length} خوښونې',
                        style: TextStyle(fontSize: 11, color: likedByMe ? c.error : c.onSurfaceVariant)),
                    ),
                    TextButton.icon(
                      onPressed: () => _replyAsUser(commentId),
                      icon: const Icon(Icons.reply_rounded, size: 17),
                      label: const Text('ځواب', style: TextStyle(fontSize: 11)),
                    ),
                    if (isAdmin) TextButton.icon(
                      onPressed: () => _replyToComment(commentId),
                      icon: const Icon(Icons.reply_rounded, size: 17),
                      label: const Text('ځواب', style: TextStyle(fontSize: 11)),
                    ),
                  ]),
                  if (data['replies'] is Map)
                    ...Map<String, dynamic>.from(data['replies'] as Map).entries.map((replyEntry) {
                      final replyData = Map<String, dynamic>.from(replyEntry.value as Map);
                      final replyName = (replyData['displayName'] ?? 'لوستونکی').toString();
                      return Container(
                        margin: const EdgeInsets.only(top: 7, right: 24),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: c.surfaceContainerHighest.withValues(alpha: .65),
                          borderRadius: BorderRadius.circular(14),
                          border: Border(right: BorderSide(color: c.secondary, width: 2)),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          CircleAvatar(radius: 14,
                            backgroundImage: (replyData['avatarUrl'] ?? '').toString().isNotEmpty
                                ? NetworkImage(replyData['avatarUrl'].toString()) : null,
                            child: (replyData['avatarUrl'] ?? '').toString().isEmpty
                                ? Text(replyName.isEmpty ? 'ل' : replyName.characters.first,
                                    style: const TextStyle(fontSize: 10)) : null),
                          const SizedBox(width: 8),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(replyName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 3),
                            Text((replyData['text'] ?? '').toString(),
                              style: const TextStyle(fontSize: 12, height: 1.55)),
                          ])),
                        ]),
                      );
                    }),
                  if (reply != null && (reply['text'] ?? '').toString().isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 5),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: c.primaryContainer.withValues(alpha: .48),
                        borderRadius: BorderRadius.circular(14),
                        border: Border(right: BorderSide(color: c.primary, width: 3)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Icon(Icons.verified_rounded, color: c.primary, size: 15),
                          const SizedBox(width: 5),
                          Text((reply['adminName'] ?? 'د ادبي خزانه اداره').toString(),
                            style: TextStyle(color: c.primary, fontSize: 11, fontWeight: FontWeight.w900)),
                          const Spacer(),
                          Text('د ادارې ځواب', style: TextStyle(color: c.onSurfaceVariant, fontSize: 9)),
                        ]),
                        const SizedBox(height: 6),
                        Text(reply['text'].toString(), style: const TextStyle(fontSize: 12, height: 1.6)),
                      ]),
                    ),
                ]));
            }).toList());
          }),
      ]),
    );
  }

  Widget _stat(IconData icon, int count) {
    final c = Theme.of(context).colorScheme;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: c.surfaceContainerHighest, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: c.primary), const SizedBox(width: 6),
        Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
      ]));
  }
}

class GalleryAdminPage extends StatelessWidget {
  const GalleryAdminPage({super.key});
  Future<void> upload(BuildContext context) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1800);
    if (file == null) return;
    try {
      final url = await uploadImageToCloudinary(file);
      final ref = FirebaseDatabase.instance.ref('gallery').push();
      await ref.set({'name': file.name, 'url': url,
        'createdAt': ServerValue.timestamp, 'createdBy': FirebaseAuth.instance.currentUser?.uid});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('انځور Cloudinary ته پورته او لینک یې خوندي شو.')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('اپلوډ ناکام شو: $e')));
    }
  }
  @override
  Widget build(BuildContext context) => StreamBuilder<DatabaseEvent>(
    stream: FirebaseDatabase.instance.ref('gallery').onValue,
    builder: (context, snap) {
      final raw = snap.data?.snapshot.value;
      final entries = raw is Map ? raw.entries.toList().reversed.toList() : <dynamic>[];
      return Column(children: [
        Padding(padding: const EdgeInsets.all(15), child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF174E48), Color(0xFF398D79), Color(0xFFB28A4A)]), borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            const Icon(Icons.photo_library_rounded, color: Colors.white, size: 34), const SizedBox(width: 12),
            const Expanded(child: Text('د انځورونو ګالري\nانځورونه یو ځل پورته کړئ او بیا یې په شعر، کټګورۍ او شاعر کې وکاروئ',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, height: 1.6))),
            IconButton.filledTonal(onPressed: () => upload(context), icon: const Icon(Icons.add_photo_alternate_outlined)),
          ]))),
        Expanded(child: !snap.hasData ? const Center(child: CircularProgressIndicator())
          : entries.isEmpty ? const Center(child: Text('ګالري تشه ده؛ لومړی انځور پورته کړئ.'))
          : GridView.builder(padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .9),
            itemCount: entries.length, itemBuilder: (context, i) {
              final id = entries[i].key.toString();
              final d = Map<String, dynamic>.from(entries[i].value as Map);
              return Card(clipBehavior: Clip.antiAlias, child: Column(children: [
                Expanded(child: Stack(fit: StackFit.expand, children: [
                  Image.network((d['url'] ?? '').toString(), fit: BoxFit.cover),
                  Positioned(top: 4, right: 4, child: IconButton.filledTonal(icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await FirebaseDatabase.instance.ref('gallery/$id').remove();
                    })),
                ])),
                Padding(padding: const EdgeInsets.all(8), child: Text((d['name'] ?? 'انځور').toString(), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]));
            })),
      ]);
    });
}

class PoemEditor extends StatefulWidget {
  const PoemEditor({super.key, this.poemId, this.initialData});
  final String? poemId;
  final Map<String, dynamic>? initialData;
  @override
  State<PoemEditor> createState() => _PoemEditorState();
}
class _PoemEditorState extends State<PoemEditor> {
  final title = TextEditingController();
  final text = TextEditingController();
  final picker = ImagePicker();
  String? categoryId, poetId, existingImageUrl;
  XFile? image;
  bool featured = false, saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? <String, dynamic>{};
    title.text = (data['title'] ?? '').toString();
    text.text = (data['text'] ?? '').toString();
    categoryId = data['categoryId']?.toString();
    poetId = data['poetId']?.toString();
    existingImageUrl = data['imageUrl']?.toString();
    featured = data['featured'] == true;
  }
  Future<void> save() async {
    if (text.text.trim().isEmpty || categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('د شعر متن او کټګوري حتمي دي.')));
      return;
    }
    setState(() => saving = true);
    try {
      final ref = widget.poemId == null
          ? FirebaseDatabase.instance.ref('poems').push()
          : FirebaseDatabase.instance.ref('poems/${widget.poemId}');
      var imageUrl = existingImageUrl;
      if (image != null) {
        try {
          imageUrl = await uploadImageToCloudinary(image!);
        } catch (_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('انځور پورته نه شو؛ شعر به بې انځوره خپور شي.')));
        }
      }
      final data = <String, dynamic>{
        'text': text.text.trim(),
        'categoryId': categoryId,
        'poetId': poetId,
        'title': title.text.trim().isEmpty ? null : title.text.trim(),
        'imageUrl': imageUrl,
        'featured': featured,
        'isPublished': true,
      };
      if (widget.poemId == null) {
        data['createdAt'] = ServerValue.timestamp;
        await ref.set(data);
      } else {
        data['updatedAt'] = ServerValue.timestamp;
        await ref.update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خوندي کول ناکام شو: $e')));
    } finally { if (mounted) setState(() => saving = false); }
  }
  @override
  void dispose() { title.dispose(); text.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.poemId == null ? 'نوی شعر ثبتول' : 'د شعر سمون')),
    body: FutureBuilder<List<DataSnapshot>>(
      future: Future.wait([
        FirebaseDatabase.instance.ref('categories').get(),
        FirebaseDatabase.instance.ref('poets').get(),
      ]),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final categories = snap.data![0].value is Map
          ? Map<String, dynamic>.from(snap.data![0].value as Map) : <String, dynamic>{};
        final poets = snap.data![1].value is Map
          ? Map<String, dynamic>.from(snap.data![1].value as Map) : <String, dynamic>{};
        return ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: title, decoration: const InputDecoration(
            labelText: 'د شعر عنوان (اختیاري)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: text, minLines: 5, maxLines: 12,
            decoration: const InputDecoration(labelText: 'د شعر متن *',
              alignLabelWithHint: true, border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: categoryId, decoration: const InputDecoration(labelText: 'کټګوري *',
              border: OutlineInputBorder()),
            items: categories.entries.map((e) => DropdownMenuItem(
              value: e.key, child: Text((e.value is Map ? e.value['name'] : e.value).toString()))).toList(),
            onChanged: (v) => setState(() => categoryId = v)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: poetId, decoration: const InputDecoration(labelText: 'شاعر (اختیاري)',
              border: OutlineInputBorder()),
            items: [const DropdownMenuItem<String>(value: null, child: Text('شاعر نه ټاکل کېږي')),
              ...poets.entries.map((e) => DropdownMenuItem(
                value: e.key, child: Text((e.value is Map ? e.value['name'] : e.value).toString())))],
            onChanged: (v) => setState(() => poetId = v)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showModalBottomSheet<Map<String, dynamic>>(context: context,
                isScrollControlled: true, showDragHandle: true,
                builder: (ctx) => Directionality(textDirection: TextDirection.rtl,
                  child: SizedBox(height: MediaQuery.of(ctx).size.height * .72,
                    child: Column(children: [
                      const Padding(padding: EdgeInsets.all(14), child: Text('له ګالري انځور وټاکئ')),
                      Expanded(child: StreamBuilder<DatabaseEvent>(stream: FirebaseDatabase.instance.ref('gallery').onValue,
                        builder: (ctx, snap) {
                          final raw = snap.data?.snapshot.value;
                          final items = raw is Map ? raw.entries.toList().reversed.toList() : <dynamic>[];
                          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                          if (items.isEmpty) return const Center(child: Text('ګالري تشه ده؛ لومړی انځور پورته کړئ.'));
                          return GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                            itemCount: items.length, itemBuilder: (_, i) {
                              final d = Map<String, dynamic>.from(items[i].value as Map);
                              return InkWell(onTap: () => Navigator.pop(ctx, d),
                                child: Image.network((d['url'] ?? '').toString(), fit: BoxFit.cover));
                            });
                        })),
                    ]))));
              if (selected != null) setState(() => existingImageUrl = selected['url']?.toString());
            },
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(existingImageUrl == null ? 'له ګالري انځور وټاکئ (اختیاري)' : 'د ګالري انځور وټاکل شو')),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: featured,
            onChanged: (v) => setState(() => featured = v), title: const Text('د ورځې غوره شعر')),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: saving ? null : save,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(saving ? 'خوندي کېږي...' : (widget.poemId == null ? 'شعر خپرول' : 'بدلونونه خوندي کول'))),
        ]);
      },
    ),
  );
}


class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({this.height = 105, this.width, this.radius = 20});
  final double height;
  final double? width;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1350),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final position = -1.5 + (_controller.value * 3);
            return DecoratedBox(
              decoration: BoxDecoration(
                color: c.surfaceContainerHighest.withValues(alpha: .78),
                gradient: LinearGradient(
                  begin: Alignment(position - .45, 0),
                  end: Alignment(position + .45, 0),
                  colors: [
                    c.surfaceContainerHighest.withValues(alpha: .55),
                    c.onSurface.withValues(alpha: .09),
                    c.surfaceContainerHighest.withValues(alpha: .55),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
