import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const AbsoApp());

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
    final forest = Color(selectedAccentValue);
    const gold = Color(0xFFC49A45);
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: brightness,
      primary: forest,
      secondary: gold,
      surface: brightness == Brightness.light
          ? const Color(0xFFFFFCF5) : const Color(0xFF171D1B),
    );
    final baseText = GoogleFonts.getTextTheme(
      selectedFont,
      ThemeData(brightness: brightness).textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: GoogleFonts.getFont(selectedFont).fontFamily,
      textTheme: baseText,
      primaryTextTheme: GoogleFonts.getTextTheme(selectedFont, 
        ThemeData(brightness: brightness).primaryTextTheme,
      ),
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F5EF) : const Color(0xFF111715),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFFF7F5EF) : const Color(0xFF111715),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.getFont(selectedFont, 
          fontSize: 19, fontWeight: FontWeight.w800, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.light
            ? const Color(0xFFFFFEFA) : const Color(0xFF202925),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .55)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        titleTextStyle: GoogleFonts.getFont(selectedFont, 
          fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onSurface),
        subtitleTextStyle: GoogleFonts.getFont(selectedFont, 
          fontSize: 11, height: 1.6, color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFFFFFEFA) : const Color(0xFF202925),
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStatePropertyAll(GoogleFonts.getFont(selectedFont, 
          fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(scheme.surface),
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
          side: BorderSide(color: scheme.outlineVariant))),
        textStyle: WidgetStatePropertyAll(GoogleFonts.getFont(selectedFont, fontSize: 13)),
        hintStyle: WidgetStatePropertyAll(GoogleFonts.getFont(selectedFont, 
          fontSize: 12, color: scheme.onSurfaceVariant)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: GoogleFonts.getFont(selectedFont, fontSize: 12),
      ),
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
      appBuilder: () => PoetryShell(
        isDark: mode == ThemeMode.dark,
        fontName: selectedFont,
        accentColor: Color(selectedAccentValue),
        onTheme: _toggleTheme,
        onFontChanged: _setFont,
        onAccentChanged: _setAccent,
        onResetAppearance: _resetAppearance,
      ),
    ),
    );
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
              colors: [Color(0xFF30205F), Color(0xFF6750A4), Color(0xFF9878C8)],
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
      'د شعرونو او شاعرانو نومونه ولټوئ او خپلې خوښې کټګورۍ وټاکئ.'),
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
  const Poem(this.title, this.poet, this.category, this.lines);
  final String title, poet, category;
  final List<String> lines;
}

const poems = <Poem>[
  Poem('د ژوند لار', 'رحمان بابا', 'عرفاني', [
    'چې د مینې په لار لاړ شي، منزل ومومي',
    'د زړه سترګې چې روښانه شي، جهان ومومي',
  ]),
  Poem('د زړه خبرې', 'حمزه شینواری', 'مینه', [
    'د خیالونو په نړۍ کې دې یادونه راسره دي',
    'د سپرلي د ښکلو ګلونو رنګونه راسره دي',
  ]),
  Poem('هیله', 'اجمل خټک', 'ژوند', [
    'د سبا په تمه خپل مزل روان ساته',
    'د امید څراغ په زړه کې تل روښان ساته',
  ]),
  Poem('وطن', 'ګل پاچا الفت', 'وطن', [
    'وطن د مینې کور دی، د زړونو ارمان دی',
    'د هرې خاورې ذرې کې یې د ژوند داستان دی',
  ]),
];

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
  final Set<String> favorites = {};
  String query = '';
  String category = 'ټول';
  bool _exitDialogOpen = false;
  final categories = const ['ټول', 'مینه', 'عرفاني', 'ژوند', 'وطن'];

  List<Poem> get filteredPoems => poems.where((poem) {
    final matchesCategory = category == 'ټول' || poem.category == category;
    final text = '${poem.title} ${poem.poet} ${poem.lines.join(' ')}';
    return matchesCategory && text.contains(query);
  }).toList();

  List<Poem> get favoritePoems =>
      poems.where((poem) => favorites.contains(poem.title)).toList();

  @override
  Widget build(BuildContext context) {
    const titles = ['ادبي خزانه', 'خوښ شوي شعرونه', 'شاعران', 'زموږ په اړه', 'تنظیمات'];
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
        body: IndexedStack(
          index: selectedPage,
          children: [
            _homePage(), _favoritesPage(), _poetsPage(), _aboutPage(),
            _settingsPage(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          height: 66,
          selectedIndex: selectedPage,
          onDestinationSelected: (index) =>
              setState(() => selectedPage = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded), label: 'کور'),
            NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_rounded), label: 'خوښ شوي'),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded), label: 'شاعران'),
            NavigationDestination(
              icon: Icon(Icons.info_outline_rounded),
              selectedIcon: Icon(Icons.info_rounded), label: 'زموږ په اړه'),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded), label: 'تنظیمات'),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final colors = Theme.of(context).colorScheme;
    return Drawer(
      width: 300,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.tertiary],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 29,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.auto_stories_rounded,
                      size: 32, color: Colors.white),
                  ),
                  SizedBox(height: 13),
                  Text('ادبي خزانه',
                    style: TextStyle(color: Colors.white,
                      fontSize: 21, fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Text('د پښتو شعر او ادب نړۍ',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _drawerItem(Icons.home_rounded, 'کور پاڼه', 0),
            _drawerItem(Icons.favorite_rounded, 'خوښ شوي شعرونه', 1),
            _drawerItem(Icons.people_alt_rounded, 'شاعران', 2),
            _drawerItem(Icons.info_rounded, 'زموږ په اړه', 3),
            _drawerItem(Icons.settings_rounded, 'تنظیمات', 4),
            const Divider(height: 24, indent: 18, endIndent: 18),
            SwitchListTile(
              secondary: Icon(widget.isDark
                ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: colors.primary),
              title: const Text('تیاره بڼه'),
              value: widget.isDark,
              onChanged: (_) {
                Navigator.pop(context);
                widget.onTheme();
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.exit_to_app_rounded, color: colors.error),
              title: Text('له اپلیکیشن څخه وتل',
                style: TextStyle(color: colors.error,
                  fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _confirmExit();
              },
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 4),
              child: Text('نسخه 1.0.0',
                style: TextStyle(fontSize: 10,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        selected: selected,
        selectedTileColor: colors.secondaryContainer.withValues(alpha: .65),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon),
        title: Text(title,
          style: TextStyle(fontWeight: selected
            ? FontWeight.w800 : FontWeight.w500)),
        trailing: selected
          ? Icon(Icons.check_circle_rounded, size: 18, color: colors.primary)
          : null,
        onTap: () {
          Navigator.pop(context);
          setState(() => selectedPage = index);
        },
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

  Widget _homePage() {
    final colors = Theme.of(context).colorScheme;
    final visible = filteredPoems;
    return CustomScrollView(
      key: const PageStorageKey('home'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary, colors.tertiary],
                  begin: Alignment.topRight, end: Alignment.bottomLeft),
                borderRadius: BorderRadius.circular(20)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_stories_rounded,
                    color: Colors.white, size: 27),
                  SizedBox(height: 8),
                  Text('د پښتو ادب ښکلی جهان',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('د خوږو شعرونو او شاعرانو له نړۍ سره مل شئ.',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SearchBar(
              hintText: 'شعر یا شاعر ولټوئ...',
              textStyle: const WidgetStatePropertyAll(
                TextStyle(fontSize: 13)),
              leading: const Icon(Icons.search_rounded, size: 20),
              onChanged: (value) => setState(() => query = value.trim()),
              elevation: const WidgetStatePropertyAll(0),
              constraints: const BoxConstraints(minHeight: 46),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 55,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 9, 14, 5),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) => ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: Text(categories[index],
                  style: const TextStyle(fontSize: 12)),
                selected: category == categories[index],
                onSelected: (_) =>
                  setState(() => category = categories[index]),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Row(children: [
              Text('غوره شعرونه',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${visible.length} شعرونه',
                style: const TextStyle(fontSize: 11)),
            ]),
          ),
        ),
        if (visible.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.all(28),
              child: Center(child: Text('کوم شعر پیدا نه شو.'))))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            sliver: SliverList(delegate: SliverChildBuilderDelegate(
              (context, index) => _poemCard(visible[index]),
              childCount: visible.length)),
          ),
      ],
    );
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

  Widget _poetsPage() {
    final poets = poems.map((poem) => poem.poet).toSet().toList();
    final colors = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: poets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final poet = poets[index];
        final count = poems.where((poem) => poem.poet == poet).length;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              radius: 23,
              backgroundColor: colors.primaryContainer,
              child: Icon(Icons.person_rounded,
                color: colors.onPrimaryContainer),
            ),
            title: Text(poet),
            subtitle: Text('$count شعر په ټولګه کې'),
            trailing: Icon(Icons.arrow_back_ios_new_rounded,
              size: 15, color: colors.outline),
          ),
        );
      },
    );
  }


  Widget _settingsPage() {
    final colors = Theme.of(context).colorScheme;
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.tertiary],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              Icon(Icons.tune_rounded, color: Colors.white, size: 34),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('د اپلیکیشن تنظیمات',
                      style: TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('بڼه او لیکدود د خپلې خوښې سره برابر کړئ.',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _settingsHeading(Icons.font_download_rounded, 'د لیکدود فونټونه'),
        const SizedBox(height: 8),
        ...fonts.map((font) {
          final selected = widget.fontName == font['name'];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: selected ? colors.primaryContainer : colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              onTap: () => widget.onFontChanged(font['name']!),
              leading: CircleAvatar(
                backgroundColor: selected ? colors.primary : colors.surfaceContainerHighest,
                child: Icon(Icons.text_fields_rounded,
                  color: selected ? colors.onPrimary : colors.primary),
              ),
              title: Text(font['label']!,
                style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(font['note']!),
              trailing: selected
                  ? Icon(Icons.check_circle_rounded, color: colors.primary)
                  : const Icon(Icons.circle_outlined, size: 19),
            ),
          );
        }),
        const SizedBox(height: 15),
        _settingsHeading(Icons.palette_rounded, 'د اپلیکیشن رنګونه'),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 13,
              runSpacing: 14,
              children: palettes.map((palette) {
                final color = palette['color'] as Color;
                final selected = widget.accentColor.toARGB32() == color.toARGB32();
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => widget.onAccentChanged(color),
                  child: SizedBox(
                    width: 82,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: selected ? 47 : 42,
                          height: selected ? 47 : 42,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? colors.onSurface : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: selected
                              ? const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 24)
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(palette['name'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 15),
        _settingsHeading(Icons.display_settings_rounded, 'نور تنظیمات'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: Icon(widget.isDark
                    ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: colors.primary),
                title: const Text('تیاره بڼه'),
                subtitle: const Text('د شپې لپاره تیاره رنګونه فعال کړئ.'),
                value: widget.isDark,
                onChanged: (_) => widget.onTheme(),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(Icons.restart_alt_rounded, color: colors.primary),
                title: const Text('اصلي تنظیمات بېرته فعالول'),
                subtitle: const Text('فونټ، رنګ او بڼه لومړني حالت ته ستنوي.'),
                onTap: () => widget.onResetAppearance(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text('ستاسو خوښه، ستاسو ادبي خزانه',
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
        ),
      ],
    );
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
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 92, height: 92,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(28)),
            child: Icon(Icons.auto_stories_rounded,
              size: 48, color: colors.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 15),
        Center(child: Text('ادبي خزانه',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold))),
        const SizedBox(height: 5),
        Center(child: Text('د پښتو شعر او ادب نړۍ',
          style: TextStyle(color: colors.onSurfaceVariant))),
        const SizedBox(height: 22),
        Card(
          elevation: 0,
          color: colors.surfaceContainerLow,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'ادبي خزانه د پښتو ژبې د شعرونو او ادب د مینه‌والو لپاره یو ساده او ښکلی اپلیکیشن دی. زموږ موخه دا ده چې د پښتو شاعرۍ لوستلو، موندلو او له خوښو شعرونو سره د بیا لیدو تجربه اسانه کړو.',
              style: TextStyle(fontSize: 13, height: 1.9),
              textAlign: TextAlign.justify,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: colors.surfaceContainerLow,
          child: const Column(children: [
            ListTile(
              leading: Icon(Icons.menu_book_rounded),
              title: Text('د شعرونو ټولګه'),
              subtitle: Text('شعرونه په بېلابېلو کټګوریو کې ولولئ.')),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.favorite_rounded),
              title: Text('خوښ شوي شعرونه'),
              subtitle: Text('خپل د خوښې شعرونه په نښه او بیا یې ومومئ.')),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.search_rounded),
              title: Text('اسانه لټون'),
              subtitle: Text('د شعر یا شاعر نوم په چټکۍ ولټوئ.')),
          ]),
        ),
        const SizedBox(height: 20),
        Center(child: Text('نسخه 1.0.0',
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant))),
        const SizedBox(height: 8),
        Center(child: Text('په مینه، د پښتو ادب لپاره',
          style: TextStyle(fontSize: 12, color: colors.primary))),
      ],
    );
  }

  Widget _poemCard(Poem poem) {
    final colors = Theme.of(context).colorScheme;
    final saved = favorites.contains(poem.title);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: colors.secondary, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(30)),
                  child: Text(poem.category,
                    style: TextStyle(fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.onSecondaryContainer)),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: saved ? 'له خوښو لرې کول' : 'خوښ شعر',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    saved ? favorites.remove(poem.title)
                      : favorites.add(poem.title);
                  }),
                  icon: Icon(saved ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded, size: 19),
                ),
              ]),
              const SizedBox(height: 5),
              Text(poem.title,
                style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w800, color: colors.primary)),
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 13, vertical: 11),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in poem.lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(line,
                          style: TextStyle(fontSize: 13, height: 1.9,
                            color: colors.onSurface)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.edit_note_rounded,
                  size: 18, color: colors.secondary),
                const SizedBox(width: 5),
                Text(poem.poet,
                  style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant)),
                const Spacer(),
                Icon(Icons.menu_book_rounded,
                  size: 16, color: colors.outline),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
