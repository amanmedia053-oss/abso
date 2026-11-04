import 'package:flutter/material.dart';
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

  ThemeData makeTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4), brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: GoogleFonts.vazirmatnTextTheme(
        ThemeData(brightness: brightness).textTheme),
      appBarTheme: AppBarTheme(
        titleTextStyle: GoogleFonts.vazirmatn(
          fontSize: 19, fontWeight: FontWeight.w700,
          color: scheme.onSurface)),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ابسو | د شعرونو نړۍ',
    theme: makeTheme(Brightness.light),
    darkTheme: makeTheme(Brightness.dark),
    themeMode: mode,
    home: LaunchGate(
      appBuilder: () => PoetryShell(
        isDark: mode == ThemeMode.dark,
        onTheme: () => setState(() {
          mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
        }),
      ),
    ),
  );
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
                  const Text('ابسو',
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
                          if (pageController.position.haveDimensions) {
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
  const PoetryShell({super.key, required this.isDark, required this.onTheme});
  final bool isDark;
  final VoidCallback onTheme;
  @override
  State<PoetryShell> createState() => _PoetryShellState();
}

class _PoetryShellState extends State<PoetryShell> {
  int selectedPage = 0;
  final Set<String> favorites = {};
  String query = '';
  String category = 'ټول';
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
    const titles = ['ابسو', 'خوښ شوي شعرونه', 'شاعران', 'زموږ په اړه'];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
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
          children: [_homePage(), _favoritesPage(), _poetsPage(), _aboutPage()],
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
          ],
        ),
      ),
    );
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
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: poets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final poet = poets[index];
        final count = poems.where((poem) => poem.poet == poet).length;
        return Card(
          elevation: 0,
          child: ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person_outline)),
            title: Text(poet, style: const TextStyle(fontSize: 14)),
            subtitle: Text('$count شعر',
              style: const TextStyle(fontSize: 11)),
          ),
        );
      },
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
        Center(child: Text('ابسو',
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
              'ابسو د پښتو ژبې د شعرونو او ادب د مینه‌والو لپاره یو ساده او ښکلی اپلیکیشن دی. زموږ موخه دا ده چې د پښتو شاعرۍ لوستلو، موندلو او له خوښو شعرونو سره د بیا لیدو تجربه اسانه کړو.',
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
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 9),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(color: colors.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(20)),
                child: Text(poem.category,
                  style: const TextStyle(fontSize: 10))),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minHeight: 34, minWidth: 34),
                padding: EdgeInsets.zero,
                onPressed: () => setState(() {
                  saved ? favorites.remove(poem.title)
                    : favorites.add(poem.title);
                }),
                icon: Icon(saved ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
                  size: 20, color: saved ? colors.error : null)),
            ]),
            Text(poem.title, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            for (final line in poem.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(line,
                  style: const TextStyle(fontSize: 12, height: 1.7))),
            const Divider(height: 17),
            Row(children: [
              const Icon(Icons.edit_note_rounded, size: 17),
              const SizedBox(width: 5),
              Text(poem.poet, style: const TextStyle(fontSize: 11)),
            ]),
          ],
        ),
      ),
    );
  }
}
