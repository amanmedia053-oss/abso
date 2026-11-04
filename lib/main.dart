import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String selectedCategory = 'ټول';
  bool _exitDialogOpen = false;

  List<Poem> get filteredPoems => poems.where((poem) {
    final text = '${poem.title} ${poem.poet} ${poem.category} ${poem.lines.join(' ')}';
    final matchesQuery = text.contains(query);
    final matchesCategory = selectedCategory == 'ټول' || poem.category == selectedCategory;
    return matchesQuery && matchesCategory;
  }).toList();

  List<Poem> get favoritePoems =>
      poems.where((poem) => favorites.contains(poem.title)).toList();

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
        body: IndexedStack(
          index: selectedPage,
          children: [
            _homePage(), _favoritesPage(), _aboutPage(), _settingsPage(),
          ],
        ),
        bottomNavigationBar: _luxuryBottomNavigation(),
        ),
      ),
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
                  borderRadius: BorderRadius.circular(20),
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
                                Color(0xFF5146D8),
                                Color(0xFF8657D8),
                                Color(0xFFE56B9A),
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
                    colors: [Color(0xFF392B91), Color(0xFF7652CE), Color(0xFFE17AA7)],
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

  Widget _homePage() {
    final colors = Theme.of(context).colorScheme;
    final visible = filteredPoems;
    final categories = <String>['ټول', ...{for (final poem in poems) poem.category}];
    final poets = <String>{for (final poem in poems) poem.poet}.toList();

    return CustomScrollView(
      key: const PageStorageKey('home'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (poems.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _featuredPoemCard(poems.first),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: _sectionHeader(Icons.category_rounded, 'د شعرونو کټګورۍ',
              'خپله خوښه برخه وټاکئ'),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 49,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected = selectedCategory == category;
                return ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  avatar: Icon(category == 'ټول'
                    ? Icons.apps_rounded : Icons.auto_stories_rounded,
                    size: 17, color: selected ? colors.onPrimary : colors.primary),
                  label: Text(category),
                  onSelected: (_) => setState(() => selectedCategory = category),
                  labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                    color: selected ? colors.onPrimary : colors.onSurface),
                  selectedColor: colors.primary,
                  backgroundColor: colors.surface,
                  side: BorderSide(color: colors.outlineVariant.withValues(alpha: .6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                );
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
            child: SearchBar(
              hintText: 'د شعر یا شاعر نوم ولټوئ...',
              textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13)),
              leading: Icon(Icons.search_rounded, size: 22, color: colors.primary),
              onChanged: (value) => setState(() => query = value.trim()),
              elevation: const WidgetStatePropertyAll(0),
              constraints: const BoxConstraints(minHeight: 54),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 18)),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 17, 16, 10),
            child: _sectionHeader(Icons.fiber_new_rounded, 'نوي شعرونه',
              '${visible.length} شعرونه'),
          ),
        ),
        if (visible.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: Text('کوم شعر پیدا نه شو.')),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _poemCard(visible[index]),
                childCount: visible.length,
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _sectionHeader(Icons.person_pin_rounded, 'شاعران',
              '${poets.length} شاعران'),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 112,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
              scrollDirection: Axis.horizontal,
              itemCount: poets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 11),
              itemBuilder: (context, index) {
                final poet = poets[index];
                return Container(
                  width: 104,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.outlineVariant.withValues(alpha: .55)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 43, height: 43,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.primary, colors.tertiary],
                            begin: Alignment.topRight, end: Alignment.bottomLeft,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 7),
                      Text(poet, maxLines: 1, overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
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
          name: 'عبيدالله غفاري',
          description: 'د ادبي خزانې د مفکورې او تخنیکي جوړښت تر شا هڅاند کس؛ د پښتو ادب د مینه‌والو لپاره د یوې ښکلې او اسانه ډیجیټلي تجربې په جوړولو کې یې ونډه اخیستې ده.',
          accent: const Color(0xFF287C68), delay: 0),
        const SizedBox(height: 13),
        _aboutPersonFeature(
          icon: Icons.auto_awesome_rounded,
          role: 'ترتیب کوونکی',
          name: 'الحاج ډاکټر فريدون احرار',
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

  Widget _poemCard(Poem poem) {
    final colors = Theme.of(context).colorScheme;
    final saved = favorites.contains(poem.title);
    return Card(margin: const EdgeInsets.only(bottom: 14), clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
            colors: [colors.surface, colors.surfaceContainerLow.withValues(alpha:.75)]),
          border: Border(right: BorderSide(color: colors.secondary, width: 4))),
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton.filledTonal(
                  tooltip: saved ? 'له خوښو لرې کول' : 'خوښ شعر',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() {
                    saved ? favorites.remove(poem.title) : favorites.add(poem.title);
                  }),
                  icon: Icon(saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 19, color: saved ? colors.error : colors.primary),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(poem.title, style: TextStyle(fontSize: 18,
              fontWeight: FontWeight.w900, color: colors.primary)),
            const SizedBox(height: 12),
            Container(width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              decoration: BoxDecoration(color: colors.surfaceContainerHighest.withValues(alpha:.48),
                borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final line in poem.lines)
                  Padding(padding: const EdgeInsets.only(bottom: 6),
                    child: Text(line, style: TextStyle(fontSize: 14, height: 2,
                      color: colors.onSurface, fontWeight: FontWeight.w500))),
              ])),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.edit_note_rounded, size: 19, color: colors.secondary),
              const SizedBox(width: 6),
              Text(poem.poet, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: colors.onSurfaceVariant)),
              const Spacer(), Icon(Icons.format_quote_rounded, size: 20, color: colors.outline),
            ]),
          ]),
        ),
      ),
    );
  }
}
