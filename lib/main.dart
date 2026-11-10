import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

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
  String appLanguage = 'ps';
  double appTextScale = 1.0;
  bool notificationsEnabled = true;
  int _selectedShellPage = 0;
  Timer? _textScaleSaveTimer;

  void _setSelectedShellPage(int page) {
    if (_selectedShellPage == page) return;
    setState(() => _selectedShellPage = page);
  }
  // Keep the shell state (selected tab/page and open drawer) alive when
  // app-wide settings rebuild MaterialApp for theme, font, or language.
  final GlobalKey<_PoetryShellState> _poetryShellKey =
      GlobalKey<_PoetryShellState>();

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
      appLanguage = prefs.getString('app_language') ?? 'ps';
      appTextScale = prefs.getDouble('app_text_scale') ?? 1.0;
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _setLanguage(String value) async {
    setState(() => appLanguage = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', value);
  }

  void _setTextScale(double value) {
    final next = value.clamp(.85, 1.30).toDouble();
    setState(() => appTextScale = next);
    // Persist only the latest slider value. Rapid asynchronous writes while
    // dragging could finish out of order and restore an older percentage.
    _textScaleSaveTimer?.cancel();
    _textScaleSaveTimer = Timer(const Duration(milliseconds: 350), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('app_text_scale', next);
    });
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => notificationsEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> _clearAppCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cache_poems');
    await prefs.remove('cache_categories');
    await prefs.remove('cache_poets');
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
    appLanguage = 'ps';
    appTextScale = 1.0;
    notificationsEnabled = true;
    await prefs.setString('app_language', appLanguage);
    await prefs.setDouble('app_text_scale', appTextScale);
    await prefs.setBool('notifications_enabled', notificationsEnabled);
    if (mounted) setState(() {});
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
  void dispose() {
    _textScaleSaveTimer?.cancel();
    super.dispose();
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
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(appTextScale)),
      child: child ?? const SizedBox.shrink()),
    debugShowCheckedModeBanner: false,
    title: 'ادبي خزانه | د شعرونو نړۍ',
    theme: makeTheme(Brightness.light),
    darkTheme: makeTheme(Brightness.dark),
    themeMode: mode,
    home: LaunchGate(
      appBuilder: () => AuthGate(
        child: PoetryShell(
          key: _poetryShellKey,
          selectedPage: _selectedShellPage,
          onSelectedPageChanged: _setSelectedShellPage,
          isDark: mode == ThemeMode.dark,
          fontName: selectedFont,
          accentColor: Color(selectedAccentValue),
          onTheme: _toggleTheme,
          onFontChanged: _setFont,
          onAccentChanged: _setAccent,
          onResetAppearance: _resetAppearance,
          language: appLanguage,
          onLanguageChanged: _setLanguage,
          textScale: appTextScale,
          onTextScaleChanged: _setTextScale,
          notificationsEnabled: notificationsEnabled,
          onNotificationsChanged: _setNotifications,
          onClearCache: _clearAppCache,
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
      return AccountAccessPage(
        allowGuest: true,
        onSkip: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => child),
        ),
      );
    },
  );
}

class AccountAccessPage extends StatefulWidget {
  const AccountAccessPage({super.key, this.onSkip, this.onAuthenticated, this.allowGuest = false});
  final VoidCallback? onSkip;
  final VoidCallback? onAuthenticated;
  final bool allowGuest;
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
      if (result.user != null) {
        await _saveName(result.user!);
        widget.onAuthenticated?.call();
      }
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
          if (result.user != null) {
            await _saveName(result.user!);
            widget.onAuthenticated?.call();
          }
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
              if (widget.onSkip != null)
                Align(alignment: Alignment.topRight, child: TextButton.icon(
                  onPressed: busy ? null : widget.onSkip,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Skip / تېرېدل'),
                )),
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
              if (widget.allowGuest) ...[
                const SizedBox(height: 18),
                const Divider(),
                OutlinedButton.icon(
                  onPressed: busy ? null : _continueAsGuest,
                  icon: const Icon(Icons.person_outline_rounded),
                  label: const Text('د مېلمه په توګه دوام')),
              ],
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

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController pageController = PageController();
  int page = 0;
  late final AnimationController _artController = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  static const List<_IntroSlide> slides = [
    _IntroSlide(
      Icons.auto_stories_rounded,
      'د پښتو ادب نوې نړۍ',
      'د پښتو شعرونو او ادبي اثارو یوه رنګینه خزانه؛ هره ورځ نوې ادبي شېبې تجربه کړئ.',
      [Color(0xFF123B32), Color(0xFF246B58)],
      '01',
      'ادب',
    ),
    _IntroSlide(
      Icons.edit_note_rounded,
      'د شاعرانو پېژندنه',
      'د خپلې خوښې شاعر ومومئ، د هغه ژوندلیک او غوره شعرونه په یوه ځای کې ولولئ.',
      [Color(0xFF34245F), Color(0xFF7652A8)],
      '02',
      'شاعران',
    ),
    _IntroSlide(
      Icons.menu_book_rounded,
      'ښکلی او اسانه لوست',
      'د لوستلو ارام چاپېریال، روښانه لیکدود او د شعرونو منظمې برخې.',
      [Color(0xFF173A68), Color(0xFF397DB2)],
      '03',
      'لوست',
    ),
    _IntroSlide(
      Icons.favorite_rounded,
      'خپل شعرونه خوندي کړئ',
      'خوښ شعرونه په نښه کړئ او هر وخت بېرته خپلې ځانګړې ټولګې ته ور وګرځئ.',
      [Color(0xFF6A2447), Color(0xFFB64E72)],
      '04',
      'خوښې',
    ),
    _IntroSlide(
      Icons.smart_display_rounded,
      'لنډې ویډیوګانې',
      'د ادب او شاعرۍ لنډې ویډیوګانې وګورئ او له ملګرو سره یې شریکې کړئ.',
      [Color(0xFF713B19), Color(0xFFC17A32)],
      '05',
      'ویډیو',
    ),
    _IntroSlide(
      Icons.cloud_off_rounded,
      'افلاين ادبي کټګورۍ',
      'د افلاين کټګوریو له لارې خپل شعرونه منظم کړئ او په اسانه یې ومومئ.',
      [Color(0xFF214C4C), Color(0xFF398B83)],
      '06',
      'افلاين',
    ),
    _IntroSlide(
      Icons.forum_rounded,
      'له ادب‌مینه‌والو سره',
      'خپل نظرونه او تبصرې شریکې کړئ، شعرونه ولټوئ او د ادب ملګرتیا پیاوړې کړئ.',
      [Color(0xFF3B315F), Color(0xFF7567A8)],
      '07',
      'ټولنه',
    ),
  ];

  @override
  void dispose() {
    pageController.dispose();
    _artController.dispose();
    super.dispose();
  }

  void next() {
    if (page == slides.length - 1) {
      widget.onDone();
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = slides[page];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ColoredBox(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F3),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFFE8EBE8)),
                        ),
                        child: Text(
                          '${slide.number}  /  07',
                          style: const TextStyle(color: Color(0xFF34423B), fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onDone,
                        child: const Text('تېرېدل', style: TextStyle(color: Color(0xFF66736C), fontSize: 14)),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: slides.length,
                      onPageChanged: (value) => setState(() => page = value),
                      itemBuilder: (context, index) {
                        final item = slides[index];
                        return AnimatedBuilder(
                          animation: pageController,
                          builder: (context, child) {
                            var scale = 1.0;
                            if (pageController.hasClients &&
                                pageController.position.haveDimensions) {
                              scale = (1 - (pageController.page! - index).abs() * 0.08)
                                  .clamp(0.90, 1.0);
                            }
                            return Transform.scale(scale: scale, child: child);
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 330,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFBFA),
                                  borderRadius: BorderRadius.circular(34),
                                  border: Border.all(color: const Color(0xFFEEF0EE)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF24352B).withValues(alpha: 0.07),
                                      blurRadius: 28,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedBuilder(
                                      animation: _artController,
                                      builder: (context, child) {
                                        final vertical = (_artController.value - 0.5) * 18;
                                        final angle = (_artController.value - 0.5) * 0.10;
                                        return Transform.translate(
                                          offset: Offset(0, vertical),
                                          child: Transform.rotate(angle: angle, child: child),
                                        );
                                      },
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 420),
                                        switchInCurve: Curves.easeOutBack,
                                        switchOutCurve: Curves.easeIn,
                                        transitionBuilder: (child, animation) =>
                                            FadeTransition(
                                              opacity: animation,
                                              child: ScaleTransition(scale: animation, child: child),
                                            ),
                                        child: Container(
                                          key: ValueKey<int>(index),
                                          width: 190,
                                          height: 190,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F4F1),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFFE2E9E3), width: 1.5),
                                          ),
                                          child: Icon(item.icon, size: 100, color: const Color(0xFF285B45)),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 26,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF3EF),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(color: const Color(0xFFDDE6DE)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(item.icon, color: const Color(0xFF285B45), size: 19),
                                            const SizedBox(width: 8),
                                            Text(item.tag, style: const TextStyle(color: Color(0xFF285B45), fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 38),
                              Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: const Color(0xFF202A24),
                                  fontSize: 27,
                                  height: 1.4,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  item.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF68736C),
                                    fontSize: 15,
                                    height: 2,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (index) {
                      final active = page == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 27 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active ? const Color(0xFF285B45) : const Color(0xFFD9DFDA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: next,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF285B45),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            page == slides.length - 1 ? 'ادبي خزانه ته ننوځئ' : 'راتلونکی',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(width: 9),
                          Icon(page == slides.length - 1 ? Icons.arrow_forward_rounded : Icons.chevron_left_rounded),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _onboardingOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _IntroSlide {
  const _IntroSlide(this.icon, this.title, this.description, this.colors, this.number, this.tag);
  final IconData icon;
  final String title;
  final String description;
  final List<Color> colors;
  final String number;
  final String tag;
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
    required this.selectedPage,
    required this.onSelectedPageChanged,
    required this.isDark,
    required this.fontName,
    required this.accentColor,
    required this.onTheme,
    required this.onFontChanged,
    required this.onAccentChanged,
    required this.onResetAppearance,
    required this.language,
    required this.onLanguageChanged,
    required this.textScale,
    required this.onTextScaleChanged,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.onClearCache,
  });
  final int selectedPage;
  final ValueChanged<int> onSelectedPageChanged;
  final bool isDark;
  final String fontName;
  final Color accentColor;
  final VoidCallback onTheme;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<Color> onAccentChanged;
  final VoidCallback onResetAppearance;
  final String language;
  final ValueChanged<String> onLanguageChanged;
  final double textScale;
  final ValueChanged<double> onTextScaleChanged;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final Future<void> Function() onClearCache;
  @override
  State<PoetryShell> createState() => _PoetryShellState();
}

class _PoetryShellState extends State<PoetryShell> {
  final GlobalKey<ScaffoldState> _shellScaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerVisible = false;
  String? _fontSelectionPreview;
  int? _accentSelectionPreview;
  String? _languageSelectionPreview;

  void _selectLanguage(String language) {
    setState(() => _languageSelectionPreview = language);
    _applyWithoutClosing(() => widget.onLanguageChanged(language));
  }

  void _selectFont(String fontName) {
    setState(() => _fontSelectionPreview = fontName);
    _applyWithoutClosing(() => widget.onFontChanged(fontName));
  }

  void _selectAccent(Color color) {
    setState(() => _accentSelectionPreview = color.toARGB32());
    _applyWithoutClosing(() => widget.onAccentChanged(color));
  }

  void _applyWithoutClosing(VoidCallback action) {
    // Capture the drawer and selected page before app-wide settings rebuild.
    final keepDrawerOpen = _isDrawerVisible ||
        (_shellScaffoldKey.currentState?.isDrawerOpen ?? false);
    final keepPage = selectedPage;
    // Synchronize the selected page before the root appearance update.
    widget.onSelectedPageChanged(keepPage);

    // Apply the selected preference immediately.
    action();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (selectedPage != keepPage) {
        setState(() => selectedPage = keepPage);
      }

      // Let Scaffold finish its drawer-route transition before reopening.
      if (keepDrawerOpen) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        final scaffold = _shellScaffoldKey.currentState;
        if (scaffold != null && !scaffold.isDrawerOpen) {
          scaffold.openDrawer();
        }
      }
    });
  }

  void _changeLanguageInPlace(String value) => _selectLanguage(value);

  void _toggleThemeInPlace() =>
      _applyWithoutClosing(widget.onTheme);

  late int selectedPage = widget.selectedPage;
  int _featuredIndex = 0;

  @override
  void didUpdateWidget(covariant PoetryShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the selected tab authoritative in the app root, so a rebuild
    // caused by theme, language, or font changes cannot reset to Home.
    if (selectedPage != widget.selectedPage) {
      selectedPage = widget.selectedPage;
    }
    if (_fontSelectionPreview == widget.fontName) {
      _fontSelectionPreview = null;
    }
    if (_languageSelectionPreview == widget.language) {
      _languageSelectionPreview = null;
    }
    if (_accentSelectionPreview == widget.accentColor.toARGB32()) {
      _accentSelectionPreview = null;
    }
  }
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
    LocalPoetryCategory('نور بېلابېل شعرونه', Icons.library_books_rounded),
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
      final authenticated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (routeContext) => AccountAccessPage(
          onAuthenticated: () => Navigator.pop(routeContext, true),
        )),
      );
      if (authenticated != true || !mounted) return null;
      user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) return null;
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
        final storedCategoryId = (data['categoryId'] ?? '').toString();
        final categoryId = storedCategoryId.isEmpty
            ? 'offline_category_${_offlineCategories.length - 1}'
            : storedCategoryId;
        if (body.isEmpty || data['isPublished'] == false) continue;
        final localCategoryIndex = categoryId.startsWith('offline_category_')
            ? int.tryParse(categoryId.substring('offline_category_'.length)) ?? -1
            : -1;
        final localCategoryName = localCategoryIndex >= 0 &&
                localCategoryIndex < _offlineCategories.length
            ? _offlineCategories[localCategoryIndex].title
            : '';
        next.add(Poem(
          id: entry.key.toString(),
          title: (data['title'] ?? '').toString().trim().isEmpty
              ? body.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(6).join(' ')
              : data['title'].toString().trim(),
          poetId: (data['poetId'] ?? '').toString(),
          categoryId: categoryId,
          poet: _poetNames[(data['poetId'] ?? '').toString()] ?? '',
          category: _categoryNames[categoryId] ?? localCategoryName,
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

  Future<void> _selectPage(int index) async {
    if (index == 3) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.isAnonymous) {
        final authenticated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (routeContext) => AccountAccessPage(
            onAuthenticated: () => Navigator.pop(routeContext, true),
          )),
        );
        if (authenticated != true || !mounted) return;
      }
    }
    if (mounted) {
      setState(() => selectedPage = index);
      widget.onSelectedPageChanged(index);
    }
  }

  String _tr(String ps, String fa, String en) =>
      widget.language == 'en' ? en : widget.language == 'fa' ? fa : ps;

  @override
  Widget build(BuildContext context) {
    final titles = widget.language == 'en' ? ['Literary Treasury','Favorites','About','Settings'] : widget.language == 'fa' ? ['گنجینه ادبی','پسندیده‌ها','درباره ما','تنظیمات'] : ['ادبي خزانه','خوښ شوي شعرونه','زموږ په اړه','تنظیمات'];
    return Directionality(
      textDirection: widget.language == 'en' ? TextDirection.ltr : TextDirection.rtl,
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (selectedPage != 0) {
            setState(() => selectedPage = 0);
            widget.onSelectedPageChanged(0);
          } else {
            _confirmExit();
          }
        },
        child: Scaffold(
        key: _shellScaffoldKey,
        onDrawerChanged: (isOpened) => _isDrawerVisible = isOpened,
        drawer: _buildDrawer(),
        appBar: AppBar(
          title: Text(titles[selectedPage]),
          actions: [
            IconButton(
              tooltip: _tr('د شپې او ورځې بڼه', 'حالت شب و روز', 'Light and dark mode'),
              onPressed: _toggleThemeInPlace,
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
              ? _tr('انټرنېټ نشته؛ لیکنې نه لوډ کېږي. اړیکه وګورئ.', 'اینترنت وصل نیست؛ نوشته‌ها بارگیری نمی‌شوند. اتصال را بررسی کنید.', 'No internet connection. Check your connection.')
              : _tr('انټرنېټ نشته؛ خوندي شوې لیکنې درته ښودل کېږي.', 'اینترنت وصل نیست؛ نوشته‌های ذخیره‌شده نمایش داده می‌شوند.', 'Offline: showing saved content.'),
          style: TextStyle(color: colors.onErrorContainer,
            fontSize: 11, fontWeight: FontWeight.w700),
        )),
        TextButton(
          onPressed: _listenAgain,
          child: Text(_tr('بیا هڅه', 'تلاش دوباره', 'Retry'), style: TextStyle(
            color: colors.onErrorContainer, fontSize: 11,
            fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }

  Widget _luxuryBottomNavigation() {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final labels = widget.language == 'en' ? ['Home','Favorites','About','Settings'] : widget.language == 'fa' ? ['خانه','پسندیده‌ها','درباره ما','تنظیمات'] : ['کور','خوښ شوي','زموږ په اړه','تنظیمات'];
    const items = <(IconData, IconData)>[(Icons.home_outlined,Icons.home_rounded),(Icons.favorite_border_rounded,Icons.favorite_rounded),(Icons.info_outline_rounded,Icons.info_rounded),(Icons.settings_outlined,Icons.settings_rounded)];
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
                label: labels[index],
                child: InkWell(
                  borderRadius: BorderRadius.circular(17),
                  onTap: () => _selectPage(index),
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
                            labels[index],
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
      width: 332,
      elevation: 24,
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(19, 24, 19, 22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF153F37), Color(0xFF245B50), Color(0xFFB77928)],
                  ),
                  borderRadius: BorderRadius.circular(29),
                  border: Border.all(color: Colors.white.withValues(alpha: .20)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF153F37).withValues(alpha: .30),
                      blurRadius: 28,
                      spreadRadius: 1,
                      offset: const Offset(0, 12),
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
                  subtitle: const Text('شعرونه او ټیلیګرام اداره کړئ', style: TextStyle(fontSize: 10)),
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
                    _toggleThemeInPlace();
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
              _selectPage(index);
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
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: .55),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .24),
                  blurRadius: 35,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(29),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(22, 25, 22, 23),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          Color(0xFF153F37),
                          Color(0xFF246052),
                          Color(0xFFB77928),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .16),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .35),
                              width: 1.4,
                            ),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'له اپلیکیشن څخه وتل؟',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'ایا غواړئ له ادبي خزانه څخه ووځئ؟',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .88),
                            fontSize: 12,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 19, 18, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 49),
                              foregroundColor: colors.onSurface,
                              side: BorderSide(
                                color: colors.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text(
                              'نه، پاتې کېږم',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.error,
                              foregroundColor: colors.onError,
                              minimumSize: const Size(0, 49),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pop(dialogContext, true),
                            icon: const Icon(
                              Icons.logout_rounded,
                              size: 17,
                            ),
                            label: const Text(
                              'هو، ووځم',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  Widget _shortVideosHomeSection() {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('short_videos').onValue,
      builder: (context, snapshot) {
        final raw = snapshot.data?.snapshot.value;
        final videos = <Map<String, dynamic>>[];
        if (raw is Map) {
          for (final entry in raw.entries) {
            if (entry.value is Map) {
              final item = Map<String, dynamic>.from(entry.value as Map)
                ..['id'] = entry.key.toString();
              if (item['isPublished'] == true && (item['embedUrl'] ?? '').toString().isNotEmpty) {
                videos.add(item);
              }
            }
          }
        }
        videos.sort((a, b) => ((b['createdAt'] ?? 0) as num).compareTo((a['createdAt'] ?? 0) as num));
        if (videos.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 9),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.video_collection_rounded, color: Color(0xFF16A6A0), size: 22),
              const SizedBox(width: 8),
              Expanded(child: Text(_tr('لنډې ویډیوګانې', 'ویدیوهای کوتاه', 'Short videos'),
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ShortVideoFeedPage(videos: videos))),
                child: Text(_tr('ټولې وګورئ', 'مشاهده همه', 'View all')),
              ),
            ]),
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: videos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(17),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ShortVideoFeedPage(videos: videos, initialIndex: index))),
                    child: Container(
                      width: 112,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [Color(0xFF173D69), Color(0xFF167D83), Color(0xFF20263D)]),
                      ),
                      child: Stack(fit: StackFit.expand, children: [
                        Positioned(
                          right: 0, left: 0, top: 0, bottom: 0,
                          child: Center(child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18),
                              shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34))),
                        ),
                        Positioned(left: 8, right: 8, bottom: 9,
                          child: Text((video['caption'] ?? video['channelTitle'] ?? 'ویډیو').toString(),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 10,
                              fontWeight: FontWeight.w800))),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _homePage() {
    final colors = Theme.of(context).colorScheme;
    if (poems.isEmpty && _loadingPoems) return _refreshable(_homeSkeleton());
    if (poems.isEmpty && (_databaseError != null || !_loadingPoems || poems.isEmpty)) {
      return _refreshable(ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 24),
        children: [
          _shortVideosHomeSection(),
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
                  Expanded(child: Text(_tr('د شعر، شاعر او کټګورۍ لټون...', 'جستجوی شعر، شاعر و دسته‌بندی...', 'Search poems, poets and categories...'),
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13))),
                  Icon(Icons.tune_rounded, color: colors.primary, size: 20),
                ]),
              ),
            ),
          ))),
        SliverToBoxAdapter(child: _TypingCoupletBox(poems: poems, onPoemTap: _openPoem)),
        SliverPadding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 9),
          sliver: SliverToBoxAdapter(child: _sectionHeader(Icons.auto_stories_rounded,
            _tr('د شعرونو ټولګه', 'مجموعه شعرها', 'Poem collection'), '${visible.length} ' + _tr('شعرونه', 'شعر', 'poems')))),
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
              _tr('د شعرونو موضوعي کټګورۍ', 'دسته‌بندی موضوعی شعرها', 'Poetry categories'),
              '${_offlineCategories.length} ' + _tr('کټګورۍ', 'دسته', 'categories'),
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
        SliverToBoxAdapter(child: _shortVideosHomeSection()),
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
    final fonts = <Map<String, String>>[
      {'name': 'Vazirmatn', 'label': 'وزیرمتن', 'note': _tr('روښانه او منظم', 'روشن و منظم', 'Clear and readable')},
      {'name': 'Noto Naskh Arabic', 'label': 'نوتو نسخ', 'note': _tr('د کتابونو کلاسیک سبک', 'سبک کلاسیک کتاب‌ها', 'Classic book style')},
      {'name': 'Amiri', 'label': 'اميري', 'note': _tr('ادبي او دودیز خط', 'قلم ادبی و سنتی', 'Traditional literary font')},
      {'name': 'Cairo', 'label': 'کایرو', 'note': _tr('عصري او ساده', 'مدرن و ساده', 'Modern and simple')},
      {'name': 'Tajawal', 'label': 'تجوال', 'note': _tr('نرم او ښکلی', 'نرم و زیبا', 'Soft and elegant')},
    ];
    final palettes = <Map<String, Object>>[
      {'name': _tr('ځنګلي شین', 'سبز جنگلی', 'Forest green'), 'color': const Color(0xFF245B50)},
      {'name': _tr('شاهي ارغواني', 'بنفش شاهانه', 'Royal purple'), 'color': const Color(0xFF6750A4)},
      {'name': _tr('سمندري آبي', 'آبی دریایی', 'Ocean blue'), 'color': const Color(0xFF176B87)},
      {'name': _tr('یاقوتي سور', 'سرخ یاقوتی', 'Ruby red'), 'color': const Color(0xFF9A3D50)},
      {'name': _tr('طلایي نارنجي', 'نارنجی طلایی', 'Golden orange'), 'color': const Color(0xFF9A641F)},
      {'name': _tr('فیروزه يي', 'فیروزه‌ای', 'Turquoise'), 'color': const Color(0xFF287C78)},
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
              Text(_tr('زما پروفایل', 'پروفایل من', 'My profile'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(height: 4),
              Text(_profileName.isEmpty ? _tr('د تبصرو لپاره خپل نوم ثبت کړئ', 'برای نظر دادن نام خود را ثبت کنید', 'Set your name to comment') : _profileName,
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
            ])),
            Icon(Icons.edit_rounded, color: colors.primary),
          ])),
        )),
        const SizedBox(height: 14),
        _settingsHeading(Icons.translate_rounded, widget.language == 'en' ? 'App language' : widget.language == 'fa' ? 'زبان برنامه' : 'د اپلیکیشن ژبه'),
        const SizedBox(height: 9),
        Container(decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: colors.outlineVariant.withValues(alpha: .55))),
          child: Column(children: [_languageOption('ps', 'پښتو', 'اصلي ژبه'), Divider(height: 1, indent: 16, endIndent: 16, color: colors.outlineVariant), _languageOption('fa', 'دری', 'زبان دری'), Divider(height: 1, indent: 16, endIndent: 16, color: colors.outlineVariant), _languageOption('en', 'English', 'English interface')])),
        const SizedBox(height: 20),
        _settingsHeading(Icons.nightlight_round, widget.language == 'en' ? 'Appearance' : widget.language == 'fa' ? 'نمایش' : 'د ښودنې بڼه'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: .55))),
          child: Row(children: [
            Expanded(child: _appearanceChoice(
              icon: Icons.light_mode_rounded, title: _tr('روښانه', 'روشن', 'Light'),
              selected: !dark, onTap: () { if (dark) _toggleThemeInPlace(); })),
            const SizedBox(width: 7),
            Expanded(child: _appearanceChoice(
              icon: Icons.dark_mode_rounded, title: _tr('تیاره', 'تیره', 'Dark'),
              selected: dark, onTap: () { if (!dark) _toggleThemeInPlace(); })),
          ]),
        ),
        const SizedBox(height: 23),
        _settingsHeading(Icons.font_download_rounded, widget.language == 'en' ? 'Font style' : widget.language == 'fa' ? 'قلم نوشتار' : 'د لیکدود فونټونه'),
        const SizedBox(height: 9),
        ...fonts.map((font) {
          final selected = (_fontSelectionPreview ?? widget.fontName) == font['name'];
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
              onTap: () => _selectFont(font['name']!),
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
        _settingsHeading(Icons.color_lens_rounded, widget.language == 'en' ? 'App colors' : widget.language == 'fa' ? 'رنگ‌های برنامه' : 'د اپلیکیشن رنګونه'),
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
              final selected = (_accentSelectionPreview ?? widget.accentColor.toARGB32()) == color.toARGB32();
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _selectAccent(color),
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
        _settingsHeading(Icons.settings_suggest_rounded, widget.language == 'en' ? 'More options' : widget.language == 'fa' ? 'گزینه‌های بیشتر' : 'نور انتخابونه'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.outlineVariant.withValues(alpha: .55))),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  _settingsIcon(Icons.text_fields_rounded, colors.primary),
                  const SizedBox(width: 11),
                  Expanded(child: Text(_tr('د لیکنو اندازه', 'اندازه نوشته', 'Text size'),
                    style: const TextStyle(fontWeight: FontWeight.w800))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: BorderRadius.circular(20)),
                    child: Text('${(widget.textScale * 100).round()}%',
                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.w900, fontSize: 11)),
                  ),
                ]),
                Slider(
                  value: widget.textScale.clamp(.85, 1.30).toDouble(),
                  min: .85, max: 1.30, divisions: 9,
                  label: '${(widget.textScale * 100).round()}%',
                  onChanged: (value) => _applyWithoutClosing(() => widget.onTextScaleChanged(value)),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_tr('کوچنی', 'کوچک', 'Small'), style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
                  Text(_tr('لوی', 'بزرگ', 'Large'), style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
                ]),
              ]),
            ),
            Divider(height: 1, indent: 16, endIndent: 16, color: colors.outlineVariant.withValues(alpha: .5)),
            SwitchListTile(secondary: _settingsIcon(Icons.notifications_active_rounded, colors.primary), title: Text(widget.language == 'en' ? 'Notifications' : widget.language == 'fa' ? 'اعلان‌ها' : 'خبرتیاوې', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(widget.language == 'en' ? 'Notification preference' : widget.language == 'fa' ? 'تنظیم اعلان‌ها' : 'د خبرتیاوو تنظیم'), value: widget.notificationsEnabled, onChanged: (value) => _applyWithoutClosing(() => widget.onNotificationsChanged(value))),
            Divider(height: 1, indent: 16, endIndent: 16, color: colors.outlineVariant.withValues(alpha: .5)),
            ListTile(leading: _settingsIcon(Icons.cleaning_services_rounded, colors.primary), title: Text(widget.language == 'en' ? 'Clear cached data' : widget.language == 'fa' ? 'پاک‌کردن حافظه موقت' : 'د لنډمهاله حافظې پاکول', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(widget.language == 'en' ? 'Remove locally cached poems and lists' : widget.language == 'fa' ? 'پاک‌کردن نسخه‌های موقت شعرها و فهرست‌ها' : 'په موبایل کې د شعرونو او لېستونو لنډمهاله کاپي پاکوي'), onTap: _confirmClearCache),
            Divider(height: 1, indent: 16, endIndent: 16, color: colors.outlineVariant.withValues(alpha: .5)),
            ListTile(leading: _settingsIcon(Icons.privacy_tip_rounded, colors.primary), title: Text(widget.language == 'en' ? 'Privacy and security' : widget.language == 'fa' ? 'حریم خصوصی و امنیت' : 'محرمیت او امنیت', style: const TextStyle(fontWeight: FontWeight.w800)), onTap: _showPrivacyInfo),
            Divider(height: 1, indent: 16, endIndent: 16, color: colors.outlineVariant.withValues(alpha: .5)),
            ListTile(leading: _settingsIcon(Icons.support_agent_rounded, colors.primary), title: Text(widget.language == 'en' ? 'Contact administrator' : widget.language == 'fa' ? 'تماس با مدیر' : 'له مدیر سره اړیکه', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(widget.language == 'en' ? 'Contact details are not configured' : widget.language == 'fa' ? 'اطلاعات تماس ثبت نشده' : 'د اړیکې معلومات لا نه دي ثبت شوي'), onTap: _showContactInfo),
            Divider(height: 1, indent: 16, endIndent: 16, color: colors.outlineVariant.withValues(alpha: .5)),
            ListTile(leading: _settingsIcon(Icons.info_outline_rounded, colors.primary), title: Text(widget.language == 'en' ? 'App information' : widget.language == 'fa' ? 'معلومات برنامه' : 'د اپلیکیشن معلومات', style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Adabi Khazana • 1.0.0')),
            Divider(height: 1, indent: 16, endIndent: 16, color: colors.outlineVariant.withValues(alpha: .5)),
            ListTile(
              leading: _settingsIcon(Icons.restart_alt_rounded, colors.primary),
              title: Text(_tr('اصلي تنظیمات بېرته فعالول', 'بازگرداندن تنظیمات پیش‌فرض', 'Reset settings to default'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(_tr('ټول رنګونه او فونټ لومړني حالت ته ستنوي.', 'همه رنگ‌ها و قلم‌ها را به حالت نخست برمی‌گرداند.', 'Restores colors and fonts to their defaults.')),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () => _showResetConfirmation(),
            ),
            Divider(height: 1, indent: 16, endIndent: 16,
              color: colors.outlineVariant.withValues(alpha: .5)),
            ListTile(
              leading: _settingsIcon(Icons.auto_stories_rounded, colors.secondary),
              title: Text(_tr('ادبي خزانه', 'گنجینه ادبی', 'Literary Treasury'), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(_tr('د پښتو شعر او ادب نړۍ', 'جهان شعر و ادب پشتو', 'The world of Pashto poetry and literature')),
              trailing: const Text('۱.۰.۰', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Center(child: Text(_tr('په مینه، د پښتو ادب لپاره', 'با مهر، برای ادبیات پشتو', 'With love, for Pashto literature'),
          style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w800))),
      ],
    );
  }

  Widget _languageOption(String code, String title, String subtitle) {
    final colors = Theme.of(context).colorScheme;
    final selected = (_languageSelectionPreview ?? widget.language) == code;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: selected ? colors.primary.withValues(alpha: .09) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected ? colors.primary : Colors.transparent,
          width: 1.4,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        onTap: () => _changeLanguageInPlace(code),
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: selected ? colors.primary : colors.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.language_rounded,
            color: selected ? colors.onPrimary : colors.onSurfaceVariant),
        ),
        title: Text(title, style: TextStyle(
          fontWeight: FontWeight.w900,
          color: selected ? colors.primary : colors.onSurface,
        )),
        subtitle: Text(subtitle),
        trailing: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? colors.primary : Colors.transparent,
            border: Border.all(
              color: selected ? colors.primary : colors.outline,
            ),
          ),
          child: selected
            ? Icon(Icons.check_rounded, size: 17, color: colors.onPrimary)
            : null,
        ),
      ),
    );
  }

  void _confirmClearCache() {
    final en = widget.language == 'en'; final fa = widget.language == 'fa';
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: Text(en ? 'Clear cached data?' : fa ? 'حافظه موقت پاک شود؟' : 'لنډمهاله معلومات پاک شي؟'), content: Text(en ? 'Only locally cached copies are removed. Online content is not deleted.' : fa ? 'فقط نسخه‌های موقت از موبایل پاک می‌شود؛ محتوای آنلاین حذف نمی‌شود.' : 'یوازې لنډمهاله کاپي له موبایل پاکېږي؛ آنلاین محتوا نه حذف کېږي.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(en ? 'Cancel' : fa ? 'لغو' : 'نه')), FilledButton(onPressed: () async { Navigator.pop(ctx); await widget.onClearCache(); if (!mounted) return; _listenAgain(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(en ? 'Cached data cleared' : fa ? 'حافظه موقت پاک شد' : 'لنډمهاله معلومات پاک شول'))); }, child: Text(en ? 'Clear' : fa ? 'پاک شود' : 'پاکول'))]));
  }

  void _showPrivacyInfo() {
    final en = widget.language == 'en'; final fa = widget.language == 'fa';
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: Text(en ? 'Privacy and security' : fa ? 'حریم خصوصی و امنیت' : 'محرمیت او امنیت'), content: Text(en ? 'Account details are used for sign-in and features that require an account. Never share your password. Browsing without signing in is supported.' : fa ? 'اطلاعات حساب برای ورود و قابلیت‌های نیازمند حساب استفاده می‌شود. رمز عبور خود را شریک نسازید. مرور برنامه بدون ورود ممکن است.' : 'د حساب معلومات د ننوتلو او هغو برخو لپاره کارېږي چې حساب ته اړتیا لري. خپل پټنوم له چا سره مه شریکوئ. اپلیکیشن بې له حسابه هم کتلای شئ.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(en ? 'Close' : fa ? 'بستن' : 'بندول'))]));
  }

  void _showContactInfo() {
    final en = widget.language == 'en'; final fa = widget.language == 'fa';
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: Text(en ? 'Contact administrator' : fa ? 'تماس با مدیر' : 'له مدیر سره اړیکه'), content: Text(en ? 'Contact details have not been configured by the administrator yet.' : fa ? 'مدیر هنوز اطلاعات تماس را ثبت نکرده است.' : 'مدیر تر اوسه د اړیکې معلومات نه دي ثبت کړي.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(en ? 'Close' : fa ? 'بستن' : 'بندول'))]));
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
          _applyWithoutClosing(widget.onResetAppearance);
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
      if (auth.data == null || auth.data!.isAnonymous) return const EmbeddedAdminLoginPage();
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
    final pages = [
      const PoemsAdminPage(),
      const TelegramArchiveAdminPage(),
      const SimpleListAdmin(path: 'poets', title: 'شاعران'),
      const GalleryAdminPage(),
    ];
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
          NavigationDestination(icon: Icon(Icons.telegram), selectedIcon: Icon(Icons.telegram), label: 'ټیلیګرام'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'شاعران'),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: 'ګالري'),
        ]),
    );
  }
}

class TelegramArchiveAdminPage extends StatefulWidget {
  const TelegramArchiveAdminPage({super.key});
  @override
  State<TelegramArchiveAdminPage> createState() => _TelegramArchiveAdminPageState();
}

class _TelegramArchiveAdminPageState extends State<TelegramArchiveAdminPage> {
  final channel = TextEditingController();
  final token = TextEditingController();
  bool hideToken = true, extracting = false, bulkUploading = false;
  String status = '';
  String? channelId;
  String? channelUsername;
  Map<String, String> categories = {};
  final Set<String> selectedPosts = {};
  final Map<String, String> postCategories = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() { channel.dispose(); token.dispose(); super.dispose(); }

  Future<void> _loadCategories() async {
    try {
      final snap = await FirebaseDatabase.instance.ref('categories').get();
      final value = snap.value;
      if (value is Map) {
        final loaded = <String, String>{};
        for (final entry in value.entries) {
          final item = entry.value;
          final name = item is Map ? (item['name'] ?? '').toString() : item.toString();
          if (name.trim().isNotEmpty) loaded[entry.key.toString()] = name;
        }
        if (mounted) setState(() => categories = loaded);
      }
    } catch (_) {}
  }

  String _channelName(String value) {
    final v = value.trim();
    final uri = Uri.tryParse(v);
    if (uri != null && uri.host.contains('t.me')) {
      final parts = uri.pathSegments.where((e) => e.isNotEmpty).toList();
      if (parts.isNotEmpty) return '@${parts.first}';
    }
    return v.startsWith('@') ? v : '@$v';
  }

  String _cleanPostText(String value) {
    return value
        .replaceAll(RegExp(r'(https?://\S+|www\.\S+|t\.me/\S+)', caseSensitive: false), '')
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n')
        .trim();
  }

  Future<Map<String, dynamic>> _api(String method, Map<String, dynamic> body) async {
    final key = token.text.trim();
    final response = await http.post(
      Uri.parse('https://api.telegram.org/bot$key/$method'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 35));
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['ok'] != true) {
      throw Exception(decoded is Map ? (decoded['description'] ?? 'Telegram API error') : 'ناسم ځواب');
    }
    return decoded;
  }

  Future<void> extractPosts() async {
    if (channel.text.trim().isEmpty || token.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('د چینل لینک او Bot Token دواړه ولیکئ.')));
      return;
    }
    setState(() { extracting = true; status = 'له ټیلیګرام سره نښلي...'; });
    try {
      final me = await _api('getMe', {});
      final bot = Map<String, dynamic>.from(me['result'] as Map);
      final chat = await _api('getChat', {'chat_id': _channelName(channel.text)});
      final chatData = Map<String, dynamic>.from(chat['result'] as Map);
      channelId = chatData['id'].toString();
      channelUsername = (chatData['username'] ?? '').toString();
      final member = await _api('getChatMember', {'chat_id': chatData['id'], 'user_id': bot['id']});
      final memberData = Map<String, dynamic>.from(member['result'] as Map);
      final role = memberData['status']?.toString();
      if (role != 'administrator' && role != 'creator') {
        throw Exception('بوټ د چینل اډمین نه دی؛ لومړی یې اډمین کړئ.');
      }
      setState(() => status = 'نوي پوسټونه لټوي...');
      final updates = await _api('getUpdates', {
        'allowed_updates': ['channel_post', 'edited_channel_post'],
        'limit': 100,
        'timeout': 0,
      });
      final list = updates['result'] as List? ?? [];
      var saved = 0;
      for (final raw in list) {
        if (raw is! Map) continue;
        final update = Map<String, dynamic>.from(raw);
        final postRaw = update['channel_post'] ?? update['edited_channel_post'];
        if (postRaw is! Map) continue;
        final post = Map<String, dynamic>.from(postRaw);
        final chatPost = post['chat'] is Map ? Map<String, dynamic>.from(post['chat'] as Map) : <String, dynamic>{};
        if (chatPost['id'].toString() != channelId) continue;
        final messageId = post['message_id'];
        final textValue = _cleanPostText((post['text'] ?? post['caption'] ?? '').toString());
        final photos = post['photo'] is List ? post['photo'] as List : const [];
        String? photoFileId;
        if (photos.isNotEmpty && photos.last is Map) photoFileId = (photos.last as Map)['file_id']?.toString();
        final videoData = post['video'] is Map ? Map<String, dynamic>.from(post['video'] as Map) :
            (post['video_note'] is Map ? Map<String, dynamic>.from(post['video_note'] as Map) : <String, dynamic>{});
        final videoFileId = videoData['file_id']?.toString();
        final postUrl = channelUsername != null && channelUsername!.isNotEmpty
            ? 'https://t.me/$channelUsername/$messageId' : null;
        final id = messageId?.toString() ?? update['update_id'].toString();
        await FirebaseDatabase.instance.ref('telegram_posts/$channelId/$id').update({
          'messageId': messageId,
          'text': textValue,
          'photoFileId': photoFileId,
          'videoFileId': videoFileId,
          'hasVideo': videoFileId != null && videoFileId.isNotEmpty,
          'postUrl': postUrl,
          'date': post['date'],
          'updateId': update['update_id'],
          'channelTitle': chatPost['title'] ?? '',
        });
        saved++;
      }
      if (list.isNotEmpty) {
        final last = list.map((e) => (e as Map)['update_id'] as int).reduce((a, b) => a > b ? a : b);
        await _api('getUpdates', {'offset': last + 1, 'limit': 1, 'timeout': 0,
          'allowed_updates': ['channel_post', 'edited_channel_post']});
      }
      if (!mounted) return;
      setState(() => status = saved == 0
          ? 'نوي پوسټونه ونه موندل شول. بوټ به له دې وروسته نوي پوسټونه ترلاسه کړي.'
          : '$saved پوسټونه په آرشیف کې خوندي شول.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status)));
    } catch (e) {
      if (mounted) {
        setState(() => status = 'ستونزه: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('استخراج ناکام شو: $e')));
      }
    } finally { if (mounted) setState(() => extracting = false); }
  }

  Future<void> _publishTelegramVideo(Map<String, dynamic> post) async {
    final postUrl = (post['postUrl'] ?? '').toString().trim();
    if (postUrl.isEmpty || (post['videoFileId'] ?? '').toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('د ویډیو عامه ټیلیګرام لینک یا ویډیو معلومات نشته.')));
      return;
    }
    try {
      final id = '${post['channelId']}_${post['key']}';
      final embedUrl = postUrl + (postUrl.contains('?') ? '&' : '?') + 'embed=1';
      await FirebaseDatabase.instance.ref('short_videos/$id').update({
        'postUrl': postUrl,
        'embedUrl': embedUrl,
        'caption': (post['text'] ?? '').toString(),
        'channelTitle': (post['channelTitle'] ?? 'Telegram').toString(),
        'createdAt': (post['date'] is num ? (post['date'] as num).toInt() * 1000 : ServerValue.timestamp),
        'source': 'telegram',
        'isPublished': true,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ویډیو د لنډو ویډیوګانو په برخه کې خپره شوه.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ویډیو خپره نه شوه: $e')));
    }
  }

  String _selectionKey(Map<String, dynamic> post) => '${post['channelId']}/${post['key']}';

  Future<void> _uploadSelected(List<Map<String, dynamic>> rows) async {
    if (selectedPosts.isEmpty || bulkUploading) return;
    final chosen = rows.where((p) => selectedPosts.contains(_selectionKey(p))).toList();
    if (chosen.isEmpty) return;
    setState(() { bulkUploading = true; status = 'ټاکل شوي پوسټونه اپلوډ کېږي...'; });
    var uploaded = 0;
    try {
      for (final post in chosen) {
        final cleanText = _cleanPostText((post['text'] ?? '').toString());
        if (cleanText.isEmpty) continue;
        final poemRef = FirebaseDatabase.instance.ref('poems').push();
        await poemRef.set({
          'text': cleanText,
          'poetId': null,
          'title': null,
          'imageUrl': null,
          'featured': false,
          'isPublished': true,
          'createdAt': ServerValue.timestamp,
          'source': 'telegram',
        });
        await FirebaseDatabase.instance
            .ref('telegram_posts/${post['channelId']}/${post['key']}')
            .update({'uploaded': true, 'poemId': poemRef.key});
        uploaded++;
      }
      if (mounted) {
        setState(() {
          status = '$uploaded پوسټونه بې له کټګورۍ په شعرونو کې خپاره شول. کټګوري وروسته د شعرونو له مدیریت څخه ټاکلی شئ.';
          selectedPosts.removeWhere((key) => chosen.any((p) => _selectionKey(p) == key));
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => status = 'اپلوډ کې ستونزه: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status)));
      }
    } finally {
      if (mounted) setState(() => bulkUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF173D69), Color(0xFF287CA5), Color(0xFF38A58A)]),
      borderRadius: BorderRadius.circular(24)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.telegram, color: Colors.white, size: 38), SizedBox(height: 10),
        Text('د ټیلیګرام پوسټونو استخراج', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        Text('پوسټونه راوباسئ او ټاکل شوي ټول بې له کټګورۍ په یوه کلیک خپاره کړئ؛ کټګوري وروسته د شعرونو له مدیریت څخه ټاکل کېږي.', style: TextStyle(color: Colors.white70, height: 1.7)),
      ])),
    const SizedBox(height: 18),
    TextField(controller: channel, keyboardType: TextInputType.url, textDirection: TextDirection.ltr,
      decoration: const InputDecoration(labelText: 'د ټیلیګرام چینل لینک', hintText: 'https://t.me/channelname', prefixIcon: Icon(Icons.link), border: OutlineInputBorder())),
    const SizedBox(height: 12),
    TextField(controller: token, obscureText: hideToken, textDirection: TextDirection.ltr,
      decoration: InputDecoration(labelText: 'د Bot Token', prefixIcon: const Icon(Icons.key), suffixIcon: IconButton(
        onPressed: () => setState(() => hideToken = !hideToken), icon: Icon(hideToken ? Icons.visibility : Icons.visibility_off)), border: const OutlineInputBorder())),
    const SizedBox(height: 14),
    const Text('ټوکن یوازې د دې اپ په حافظه کې د استعمال پر مهال وي او په کوډ، Firebase یا محلي ذخیره کې نه ساتل کېږي. بوټ باید د چینل اډمین وي. د Telegram Bot API له لارې زاړه تاریخي پوسټونه نه ترلاسه کېږي؛ یوازې هغه نوي پوسټونه راځي چې بوټ ته د update په بڼه رسېدلي وي. د اپ له تړلو وروسته اتومات شالیدي څارنه نه کېږي.', style: TextStyle(height: 1.7, fontSize: 12)),
    const SizedBox(height: 14),
    FilledButton.icon(onPressed: extracting ? null : extractPosts,
      icon: extracting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_download_outlined),
      label: Text(extracting ? 'پوسټونه راایستل کېږي...' : 'د پوسټونو استخراج پیل')),
    if (status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(status, style: const TextStyle(height: 1.6))),
    const SizedBox(height: 20),
    Row(children: [
      const Expanded(child: Text('راایستل شوي پوسټونه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
      Text('${selectedPosts.length} ټاکل شوي'),
    ]),
    const SizedBox(height: 8),
    StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('telegram_posts').onValue,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final root = snap.data!.snapshot.value;
        final rows = <Map<String, dynamic>>[];
        if (root is Map) {
          for (final channelEntry in root.entries) {
            final posts = channelEntry.value;
            if (posts is Map) for (final entry in posts.entries) {
              if (entry.value is Map) rows.add(Map<String, dynamic>.from(entry.value as Map)
                ..['key'] = entry.key.toString()
                ..['channelId'] = channelEntry.key.toString());
            }
          }
        }
        rows.sort((a,b) => ((b['date'] ?? 0) as num).compareTo((a['date'] ?? 0) as num));
        if (rows.isEmpty) return const Padding(padding: EdgeInsets.all(12), child: Text('تر اوسه پوسټونه نه دي استخراج شوي.'));
        final pending = rows.where((p) => p['uploaded'] != true).toList();
        return Column(children: [
          if (selectedPosts.isNotEmpty)
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: bulkUploading ? null : () => _uploadSelected(rows),
              icon: bulkUploading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.cloud_upload_outlined),
              label: Text(bulkUploading ? 'اپلوډ روان دی...' : 'ټاکل شوي پوسټونه په یوه کلیک اپلوډ کړئ (${selectedPosts.length})'))),
          ...rows.map((p) {
            final key = _selectionKey(p);
            final uploaded = p['uploaded'] == true;
            return Card(
              child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Checkbox(value: uploaded ? false : selectedPosts.contains(key),
                    onChanged: uploaded ? null : (v) => setState(() {
                      if (v == true) selectedPosts.add(key); else selectedPosts.remove(key);
                    })),
                  Expanded(child: Text((p['channelTitle'] ?? 'Telegram').toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                  if (uploaded) const Chip(label: Text('اپلوډ شوی'), avatar: Icon(Icons.check_circle, size: 16)),
                ]),
                const SizedBox(height: 4),
                SelectableText(_cleanPostText((p['text'] ?? '').toString())),
                if ((p['photoFileId'] ?? '').toString().isNotEmpty)
                  const Padding(padding: EdgeInsets.only(top: 6), child: Text('دا پوسټ انځور لري (Telegram file ID خوندي شوی).')),
                if ((p['videoFileId'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.video_library_rounded, color: Colors.teal),
                    const SizedBox(width: 7),
                    const Expanded(child: Text('د ټیلیګرام ویډیو پوسټ')),
                    FilledButton.icon(
                      onPressed: () => _publishTelegramVideo(p),
                      icon: const Icon(Icons.publish_rounded, size: 18),
                      label: const Text('ویډیو خپره کړه')),
                  ]),
                ],
              ])),
            );
          }),
          if (pending.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('ټول پوسټونه اپلوډ شوي دي.')),
        ]);
      },
    ),
  ]);
}

class PoemsAdminPage extends StatefulWidget {
  const PoemsAdminPage({super.key});
  @override
  State<PoemsAdminPage> createState() => _PoemsAdminPageState();
}

class _PoemsAdminPageState extends State<PoemsAdminPage> {
  final Set<String> selectedPoems = {};
  String? bulkCategory;
  bool assigning = false;

  Future<void> _assignCategory() async {
    final category = bulkCategory;
    if (selectedPoems.isEmpty || category == null || assigning) return;
    setState(() => assigning = true);
    var updated = 0;
    try {
      for (final id in selectedPoems.toList()) {
        await FirebaseDatabase.instance.ref('poems/$id').update({'categoryId': category});
        updated++;
      }
      if (mounted) {
        setState(() => selectedPoems.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$updated شعرونه په ټاکل شوې کټګورۍ کې شامل شول.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('د کټګورۍ ټاکلو کې ستونزه: $e')));
    } finally {
      if (mounted) setState(() => assigning = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<DatabaseEvent>(
    stream: FirebaseDatabase.instance.ref('poems').orderByChild('createdAt').onValue,
    builder: (context, snap) {
      if (snap.hasError) return Center(child: Text('ستونزه: ${snap.error}'));
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final raw = snap.data!.snapshot.value;
      if (raw is! Map) return const Center(child: Text('تر اوسه شعرونه نشته.'));
      final items = raw.entries.toList().reversed.toList();
      final ids = items.map((e) => e.key.toString()).toSet();
      selectedPoems.removeWhere((id) => !ids.contains(id));
      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
          child: Row(children: [
            Expanded(child: Text('${items.length} شعرونه | ${selectedPoems.length} ټاکل شوي',
              style: const TextStyle(fontWeight: FontWeight.w800))),
            TextButton(
              onPressed: () => setState(() {
                if (selectedPoems.length == items.length) {
                  selectedPoems.clear();
                } else {
                  selectedPoems.addAll(ids);
                }
              }),
              child: Text(selectedPoems.length == items.length ? 'ټول لغوه' : 'ټول وټاکه')),
          ]),
        ),
        if (selectedPoems.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Row(children: [
              Expanded(child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('categories').onValue,
                builder: (context, categorySnap) {
                  final value = categorySnap.data?.snapshot.value;
                  final cats = <String, String>{};
                  if (value is Map) {
                    for (final e in value.entries) {
                      final v = e.value;
                      final name = v is Map ? (v['name'] ?? '').toString() : v.toString();
                      if (name.trim().isNotEmpty) cats[e.key.toString()] = name;
                    }
                  }
                  if (cats.isEmpty) return const Text('لومړی کټګورۍ ثبت کړئ.');
                  if (!cats.containsKey(bulkCategory)) bulkCategory = null;
                  return DropdownButtonFormField<String>(
                    value: bulkCategory,
                    decoration: const InputDecoration(
                      labelText: 'ټاکل شویو شعرونو ته کټګوري',
                      border: OutlineInputBorder(), isDense: true),
                    items: cats.entries.map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: assigning ? null : (v) => setState(() => bulkCategory = v),
                  );
                },
              )),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: assigning || bulkCategory == null ? null : _assignCategory,
                child: assigning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('ټول شامل کړه'),
              ),
            ]),
          ),
        Expanded(child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 9),
          itemBuilder: (context, i) {
            final id = items[i].key.toString();
            final data = Map<String, dynamic>.from(items[i].value as Map);
            return Card(child: ListTile(
              leading: Checkbox(
                value: selectedPoems.contains(id),
                onChanged: (v) => setState(() {
                  if (v == true) selectedPoems.add(id); else selectedPoems.remove(id);
                })),
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
                    if (ok == true) {
                      await FirebaseDatabase.instance.ref('poems/$id').remove();
                      if (mounted) setState(() => selectedPoems.remove(id));
                    }
                  },
                ),
              ]),
            ));
          },
        )),
      ]);
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
  const _TypingCoupletBox({required this.poems, required this.onPoemTap});
  final List<Poem> poems;
  final ValueChanged<Poem> onPoemTap;
  @override
  State<_TypingCoupletBox> createState() => _TypingCoupletBoxState();
}

class _TypingCoupletBoxState extends State<_TypingCoupletBox> {
  Timer? _timer;
  int _itemIndex = 0;
  int _charIndex = 0;
  int _holdTicks = 0;
  bool _isDeleting = false;

  // هر شعر په خپلو کرښو/بیتونو وېشو؛ دوه دوه بیتونه یو کارت جوړوي.
  // که د بیتونو شمېر طاق وي، وروستی پاتې بیت یوازې ښودل کېږي.
  List<({Poem poem, String text})> get _items {
    final result = <({Poem poem, String text})>[];
    for (final poem in widget.poems) {
      String clean(String value) => value
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\r', '\r')
          .trim();
      final verses = poem.text
          .replaceAll(r'\n', '\n')
          .replaceAll(r'\r', '\r')
          .split(RegExp(r'[\r\n]+'))
          .map(clean)
          .where((line) => line.isNotEmpty)
          .toList();
      if (verses.isEmpty) continue;
      for (var i = 0; i < verses.length; i += 2) {
        final text = i + 1 < verses.length
            ? '${verses[i]}\n${verses[i + 1]}'
            : verses[i];
        result.add((poem: poem, text: text));
      }
    }
    return result;
  }

  String get _currentText {
    final items = _items;
    if (items.isEmpty) return '';
    return items[_itemIndex % items.length].text;
  }

  @override
  void initState() {
    super.initState();
    // لومړی شعر ورو ورو لیکل کېږي، لږ تم کېږي، بیا توري یو په یو پاکېږي.
    // کله چې متن بشپړ پاک شو، راتلونکی شعر له سره ټایپېږي.
    _timer = Timer.periodic(const Duration(milliseconds: 55), (_) {
      if (!mounted) return;
      final items = _items;
      if (items.isEmpty) return;
      setState(() {
        if (!_isDeleting) {
          if (_charIndex < _currentText.length) {
            _charIndex++;
          } else if (_holdTicks++ >= 28) {
            _isDeleting = true;
            _holdTicks = 0;
          }
        } else {
          if (_charIndex > 0) {
            _charIndex--;
          } else {
            _itemIndex = (_itemIndex + 1) % items.length;
            _isDeleting = false;
            _holdTicks = 0;
          }
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant _TypingCoupletBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poems != widget.poems) {
      _itemIndex = 0;
      _charIndex = 0;
      _holdTicks = 0;
      _isDeleting = false;
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
    final items = _items;
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items[_itemIndex % items.length];
    final poem = item.poem;
    final currentText = item.text;
    final shown = currentText.substring(0, _charIndex.clamp(0, currentText.length));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 25),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => widget.onPoemTap(poem),
          child: Ink(
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
                Icon(Icons.touch_app_rounded, color: c.onSurfaceVariant, size: 15),
              ]),
              const SizedBox(height: 9),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  shown + (_charIndex < currentText.length ? '▏' : ''),
                  key: ValueKey(_itemIndex),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.onSurface, fontSize: 14, height: 1.9, fontWeight: FontWeight.w800),
                ),
              ),
              if (poem.poet.isNotEmpty) ...[
                const SizedBox(height: 5),
                Align(alignment: Alignment.centerLeft,
                  child: Text('— ${poem.poet}', style: TextStyle(color: c.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.w700))),
              ],
            ]),
          ),
        ),
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
    final profile = await widget.ensureProfile();
    if (profile == null) return;
    final ref = FirebaseDatabase.instance.ref('comments/${widget.poem.id}/$commentId/likes/${profile['uid']}');
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
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: _heroMetric(Icons.visibility_rounded, poem.views + 1, 'کتنې')),
                  const SizedBox(width: 9),
                  Expanded(child: _heroMetric(Icons.favorite_rounded, poem.likes + (liked ? 1 : 0), 'خوښونې')),
                  const SizedBox(width: 9),
                  Expanded(child: _heroMetric(Icons.bookmark_rounded, poem.saves + (saved ? 1 : 0), 'خوندي')),
                ]),
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
        Row(children: [
          Expanded(child: _actionPill(
            icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: liked ? 'خوښ شوی' : 'خوښول', active: liked,
            color: const Color(0xFFE64D70),
            onTap: () async { await widget.onLike(); if (mounted) setState(() => liked = true); },
          )),
          const SizedBox(width: 9),
          Expanded(child: _actionPill(
            icon: saved ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
            label: saved ? 'خوندي شو' : 'خوندي کول', active: saved,
            color: const Color(0xFFB77928),
            onTap: () async { await widget.onSave(); if (mounted) setState(() => saved = !saved); },
          )),
          const SizedBox(width: 9),
          Material(color: c.primaryContainer, borderRadius: BorderRadius.circular(17),
            child: InkWell(borderRadius: BorderRadius.circular(17), onTap: widget.onShare,
              child: SizedBox(width: 54, height: 54, child: Icon(Icons.ios_share_rounded, color: c.primary)))),
        ]),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.fromLTRB(15, 16, 15, 14),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(23),
            border: Border.all(color: c.outlineVariant.withValues(alpha: .55)),
            boxShadow: [BoxShadow(color: c.primary.withValues(alpha: .05), blurRadius: 18, offset: const Offset(0, 6))]),
          child: Column(children: [
            Row(children: [
              Container(width: 42, height: 42,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [c.primary, c.tertiary]), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.forum_rounded, color: Colors.white, size: 21)),
              const SizedBox(width: 11),
              const Expanded(child: Text('د لوستونکو نظرونه', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
              StreamBuilder<DatabaseEvent>(stream: FirebaseDatabase.instance.ref('comments/${poem.id}').onValue,
                builder: (context, snap) {
                  final v = snap.data?.snapshot.value;
                  final count = v is Map ? v.values.where((item) => item is Map).length : 0;
                  return Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(30)),
                    child: Text('${count} تبصرې', style: TextStyle(color: c.primary, fontSize: 10, fontWeight: FontWeight.w900)));
                }),
            ]),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: TextField(controller: commentController, minLines: 1, maxLines: 4, maxLength: 500,
                decoration: InputDecoration(hintText: 'خپل نظر ولیکئ...', counterText: '', filled: true,
                  fillColor: c.surfaceContainerHighest.withValues(alpha: .55), prefixIcon: Icon(Icons.edit_note_rounded, color: c.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: c.outlineVariant.withValues(alpha: .4))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)))),
              const SizedBox(width: 9),
              Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [c.primary, c.tertiary]),
                borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: c.primary.withValues(alpha: .22), blurRadius: 12, offset: const Offset(0, 5))]),
                child: IconButton(onPressed: sending ? null : _sendComment, color: Colors.white,
                  icon: sending ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded))),
            ]),
          ]),
        ),
        const SizedBox(height: 10),
        StreamBuilder<DatabaseEvent>(stream: FirebaseDatabase.instance.ref('comments/${poem.id}').onValue,
          builder: (context, snap) {
            if (snap.hasError) return const Text('تبصرې نه لوډ کېږي.');
            if (!snap.hasData) return const Center(child: Padding(padding: EdgeInsets.all(18), child: CircularProgressIndicator()));
            final raw = snap.data!.snapshot.value;
            if (raw is! Map || raw.isEmpty) return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Center(child: Text('تر اوسه تبصره نشته. لومړی خپل نظر ولیکئ.',
                style: TextStyle(color: c.onSurfaceVariant, fontSize: 12))));
            // Ignore malformed/null nodes so one damaged comment cannot break
            // the whole poem detail page after a comment is deleted.
            final entries = raw.entries
                .where((entry) => entry.value is Map)
                .toList()
                .reversed
                .toList();
            if (entries.isEmpty) return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('تر اوسه تبصره نشته.',
                style: TextStyle(color: c.onSurfaceVariant, fontSize: 12))));
            return Column(children: entries.map((entry) {
              final data = Map<String, dynamic>.from(entry.value as Map);
              final name = (data['displayName'] ?? 'لوستونکی').toString();
              final commentId = entry.key.toString();
              final user = FirebaseAuth.instance.currentUser;
              final likes = data['likes'] is Map ? Map<String, dynamic>.from(data['likes'] as Map) : <String, dynamic>{};
              final likedByMe = user != null && likes[user.uid] == true;
              final reply = data['adminReply'] is Map
                  ? Map<String, dynamic>.from(data['adminReply'] as Map) : null;
              return Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 11),
                padding: const EdgeInsets.all(15), decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [c.surface, c.surfaceContainerLow]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.outlineVariant.withValues(alpha: .48)),
                  boxShadow: [BoxShadow(color: c.shadow.withValues(alpha: .035), blurRadius: 12, offset: const Offset(0, 4))]),
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
                    ...Map<String, dynamic>.from(data['replies'] as Map)
                        .entries.where((replyEntry) => replyEntry.value is Map).map((replyEntry) {
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

  Widget _heroMetric(IconData icon, int count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: .22))),
      child: Column(children: [
        Icon(icon, color: const Color(0xFFFFD98A), size: 17),
        const SizedBox(height: 4),
        Text('$count', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _actionPill({required IconData icon, required String label, required bool active,
    required Color color, required VoidCallback onTap}) {
    final c = Theme.of(context).colorScheme;
    return Material(
      color: active ? color.withValues(alpha: .12) : c.surfaceContainerLow,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17), onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220), height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(17),
            border: Border.all(color: active ? color.withValues(alpha: .45) : c.outlineVariant.withValues(alpha: .5))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: active ? color : c.onSurfaceVariant, size: 20),
            const SizedBox(width: 7),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: active ? color : c.onSurface))),
          ]),
        ),
      ),
    );
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
  const PoemEditor({super.key, this.poemId, this.initialData, this.initialText});
  final String? poemId;
  final Map<String, dynamic>? initialData;
  final String? initialText;
  @override
  State<PoemEditor> createState() => _PoemEditorState();
}
class _PoemEditorState extends State<PoemEditor> {
  static const List<String> offlineCategories = [
    'حمدیه شاعري', 'نعتیه شاعري', 'حماسي شاعري', 'عشقي شاعري',
    'غنایي شاعري', 'عرفاني شاعري', 'تصوفي شاعري', 'فلسفي شاعري',
    'اخلاقي شاعري', 'اصلاحي شاعري', 'ټولنیزه شاعري', 'سیاسي شاعري',
    'ملي شاعري', 'وطني شاعري', 'رزمي شاعري', 'انتقادي شاعري',
    'طنزي شاعري', 'هجوي شاعري', 'مرثیه', 'تاریخي شاعري',
    'تعلیمي شاعري', 'طبیعي شاعري', 'حماسي وطني شاعري',
    'فراق او هجران', 'تصوف او معرفت', 'نور بېلابېل شعرونه',
  ];
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
    text.text = (data['text'] ?? widget.initialText ?? '').toString();
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
            items: [
              ...categories.entries.map((e) => DropdownMenuItem<String>(
                value: e.key,
                child: Text((e.value is Map ? e.value['name'] : e.value).toString()),
              )),
              const DropdownMenuItem<String>(
                enabled: false,
                value: '__offline_categories_header__',
                child: Text('— افلاين کټګورۍ —'),
              ),
              ..._PoemEditorState.offlineCategories.asMap().entries.map((entry) =>
                DropdownMenuItem<String>(
                  value: 'offline_category_${entry.key}',
                  child: Row(children: [
                    const Icon(Icons.offline_pin_rounded, size: 17),
                    const SizedBox(width: 8),
                    Text(entry.value),
                  ]),
                )),
            ],
            onChanged: (v) {
              if (v != null && v != '__offline_categories_header__') {
                setState(() => categoryId = v);
              }
            }),
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


class ShortVideoFeedPage extends StatefulWidget {
  const ShortVideoFeedPage({super.key, required this.videos, this.initialIndex = 0});
  final List<Map<String, dynamic>> videos;
  final int initialIndex;

  @override
  State<ShortVideoFeedPage> createState() => _ShortVideoFeedPageState();
}

class _ShortVideoFeedPageState extends State<ShortVideoFeedPage> {
  late final PageController _controller;
  int _activeIndex = 0;
  List<String> _savedIds = [];
  List<String> _likedIds = [];

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.initialIndex);
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _savedIds = prefs.getStringList('saved_short_videos') ?? [];
      _likedIds = prefs.getStringList('liked_short_videos') ?? [];
    });
  }

  Future<void> _increment(String id, String field) async {
    await FirebaseDatabase.instance.ref('short_videos/$id/$field').runTransaction((value) {
      final count = value is num ? value.toInt() : 0;
      return Transaction.success(count + 1);
    });
  }

  Future<void> _like(Map<String, dynamic> video) async {
    final id = (video['id'] ?? '').toString();
    if (id.isEmpty || _likedIds.contains(id)) return;
    final next = [..._likedIds, id];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('liked_short_videos', next);
    if (mounted) setState(() => _likedIds = next);
    await _increment(id, 'likes');
  }

  Future<void> _save(Map<String, dynamic> video) async {
    final id = (video['id'] ?? '').toString();
    if (id.isEmpty || _savedIds.contains(id)) {
      if (id.isNotEmpty && _savedIds.contains(id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('دا ویډیو مخکې خوندي شوې ده.')));
      }
      return;
    }
    final next = [..._savedIds, id];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_short_videos', next);
    await _increment(id, 'saves');
    if (mounted) setState(() => _savedIds = next);
  }

  Future<void> _share(Map<String, dynamic> video) async {
    final url = (video['postUrl'] ?? '').toString();
    final caption = (video['caption'] ?? '').toString();
    await Share.share([caption, url, '— ادبي خزانه'].where((e) => e.trim().isNotEmpty).join('\n'));
    final id = (video['id'] ?? '').toString();
    if (id.isNotEmpty) await _increment(id, 'shares');
  }

  int _count(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videos.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black,
        body: Center(child: Text('تر اوسه ویډیو نشته.', style: TextStyle(color: Colors.white))));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          onPageChanged: (index) => setState(() => _activeIndex = index),
          itemCount: widget.videos.length,
          itemBuilder: (context, index) {
            final video = widget.videos[index];
            final id = (video['id'] ?? '').toString();
            return Stack(fit: StackFit.expand, children: [
              _TelegramVideoEmbed(url: (video['embedUrl'] ?? '').toString(), active: index == _activeIndex),
              const DecoratedBox(decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x88000000), Colors.transparent, Color(0xAA000000)],
                  stops: [0, .38, 1]))),
              Positioned(left: 16, right: 78, bottom: 28, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                children: [
                  Text((video['channelTitle'] ?? 'ادبي خزانه').toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 7),
                  Text((video['caption'] ?? '').toString(), maxLines: 4, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.45)),
                ],
              )),
              Positioned(right: 12, bottom: 90, child: Column(children: [
                _VideoAction(icon: _likedIds.contains(id) ? Icons.favorite : Icons.favorite_border,
                  label: _count(video['likes']) + (_likedIds.contains(id) ? 1 : 0),
                  color: _likedIds.contains(id) ? Colors.redAccent : Colors.white,
                  onTap: () => _like(video)),
                const SizedBox(height: 20),
                _VideoAction(icon: Icons.share_rounded, label: _count(video['shares']),
                  onTap: () => _share(video)),
                const SizedBox(height: 20),
                _VideoAction(icon: _savedIds.contains(id) ? Icons.bookmark : Icons.bookmark_border,
                  label: _count(video['saves']), color: _savedIds.contains(id) ? Colors.amber : Colors.white,
                  onTap: () => _save(video)),
              ])),
              Positioned(left: 12, top: MediaQuery.of(context).padding.top + 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45))),
            ]);
          },
        ),
      ]),
    );
  }
}

class _VideoAction extends StatelessWidget {
  const _VideoAction({required this.icon, required this.label, required this.onTap, this.color = Colors.white});
  final IconData icon;
  final int label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(28),
    child: SizedBox(width: 58, child: Column(children: [
      Container(width: 45, height: 45,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .34), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 27)),
      const SizedBox(height: 4),
      Text('$label', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    ])),
  );
}

class _TelegramVideoEmbed extends StatefulWidget {
  const _TelegramVideoEmbed({required this.url, required this.active});
  final String url;
  final bool active;

  @override
  State<_TelegramVideoEmbed> createState() => _TelegramVideoEmbedState();
}

class _TelegramVideoEmbedState extends State<_TelegramVideoEmbed> {
  late final WebViewController _webController;
  bool _loaded = false;
  Timer? _playerRetryTimer;

  // Telegram embed pages contain a full post. Keep its video player visible,
  // hide post details, and attempt muted autoplay in Android WebView.
  Future<void> _prepareTelegramPlayer() async {
    const script = r"""
      (function () {
        const styleId = 'adabi-video-only-style';
        if (!document.getElementById(styleId)) {
          const style = document.createElement('style');
          style.id = styleId;
          style.textContent = 'html,body{margin:0!important;padding:0!important;background:#000!important;overflow:hidden!important}' +
            '.tgme_widget_message_header,.tgme_widget_message_footer,.tgme_widget_message_text,.tgme_widget_message_reactions,.tgme_widget_message_meta,.tgme_widget_message_author,.tgme_widget_message_date,.tgme_widget_message_link,.tgme_widget_message_photo,.tgme_widget_message_video_duration{display:none!important;visibility:hidden!important;height:0!important}' +
            '.tgme_widget_message,.tgme_widget_message_wrap,.tgme_widget_message_bubble,.tgme_widget_message_video,.tgme_widget_message_video_player,.tgme_widget_message_video_wrap{margin:0!important;padding:0!important;border:0!important;border-radius:0!important;max-width:100%!important;width:100%!important;background:#000!important;box-shadow:none!important}' +
            '.tgme_widget_message_bubble{min-height:100vh!important}.tgme_widget_message_video,.tgme_widget_message_video video,video{width:100%!important;height:100%!important;max-height:100vh!important;object-fit:contain!important;background:#000!important}';
          document.head.appendChild(style);
        }
        const videos = Array.from(document.querySelectorAll('video'));
        videos.forEach(function(v) {
          v.setAttribute('playsinline', '');
          v.setAttribute('controls', '');
          v.muted = true;
          v.autoplay = true;
          const p = v.play();
          if (p && p.catch) p.catch(function(){});
        });
        if (!videos.length) {
          const play = document.querySelector('.tgme_widget_message_video_player,.tgme_widget_message_video_thumb,.video_play');
          if (play && !play.dataset.adabiPlayRequested) {
            play.dataset.adabiPlayRequested = '1';
            play.click();
          }
        }
        return videos.length;
      })();
    """;
    try {
      await _webController.runJavaScript(script);
    } catch (_) {}
  }

  void _startPlayerRetries() {
    _playerRetryTimer?.cancel();
    var attempts = 0;
    _playerRetryTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted || !widget.active || attempts++ >= 18) {
        timer.cancel();
        return;
      }
      _prepareTelegramPlayer();
    });
  }

  @override
  void initState() {
    super.initState();
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _loaded = true);
          if (widget.active) {
            _prepareTelegramPlayer();
            _startPlayerRetries();
          }
        },
        onWebResourceError: (error) {
          if (mounted && error.isForMainFrame == true) {
            setState(() => _loaded = true);
          }
        },
      ));
    final platformController = _webController.platform;
    if (platformController is AndroidWebViewController) {
      platformController.setMediaPlaybackRequiresUserGesture(false);
    }
    _webController.loadRequest(Uri.parse(widget.url));
  }

  @override
  void didUpdateWidget(covariant _TelegramVideoEmbed oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      if (!widget.active) {
        _playerRetryTimer?.cancel();
        _webController.runJavaScript("document.querySelectorAll('video').forEach((v) => v.pause());");
      } else {
        _prepareTelegramPlayer();
        _startPlayerRetries();
      }
    }
    if (oldWidget.url != widget.url) {
      setState(() => _loaded = false);
      _webController.loadRequest(Uri.parse(widget.url));
    }
  }

  @override
  void dispose() {
    _playerRetryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(child: Stack(children: [
    Positioned.fill(child: WebViewWidget(controller: _webController)),
    if (!_loaded) const Center(child: CircularProgressIndicator(color: Colors.white)),
  ]));
}
