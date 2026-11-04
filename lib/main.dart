import 'package:flutter/material.dart';

void main() => runApp(const AbsoApp());

class AbsoApp extends StatefulWidget {
  const AbsoApp({super.key});
  @override
  State<AbsoApp> createState() => _AbsoAppState();
}

class _AbsoAppState extends State<AbsoApp> {
  ThemeMode mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6750A4);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ابسو | د شعرونو نړۍ',
      themeMode: mode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: PoetryHome(
        isDark: mode == ThemeMode.dark,
        onTheme: () => setState(() {
          mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
        }),
      ),
    );
  }
}

class Poem {
  const Poem(this.title, this.poet, this.category, this.lines);
  final String title, poet, category;
  final List<String> lines;
}

const samplePoems = <Poem>[
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

class PoetryHome extends StatefulWidget {
  const PoetryHome({super.key, required this.isDark, required this.onTheme});
  final bool isDark;
  final VoidCallback onTheme;

  @override
  State<PoetryHome> createState() => _PoetryHomeState();
}

class _PoetryHomeState extends State<PoetryHome> {
  final favorites = <String>{};
  String query = '';
  String category = 'ټول';
  final categories = const ['ټول', 'مینه', 'عرفاني', 'ژوند', 'وطن'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visible = samplePoems.where((p) {
      final matchesCategory = category == 'ټول' || p.category == category;
      final searchable = '${p.title} ${p.poet} ${p.lines.join(' ')}';
      return matchesCategory && searchable.contains(query);
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ابسو', style: TextStyle(fontWeight: FontWeight.w800)),
              Text('د شعرونو نړۍ', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            IconButton(
              onPressed: widget.onTheme,
              tooltip: 'د شپې او ورځې بڼه',
              icon: Icon(widget.isDark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.tertiary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_stories_rounded,
                          color: Colors.white, size: 36),
                      SizedBox(height: 16),
                      Text(
                        'د پښتو ادب ښکلی جهان',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'د خوږو شعرونو او شاعرانو له نړۍ سره مل شئ.',
                        style: TextStyle(color: Colors.white, height: 1.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SearchBar(
                  hintText: 'شعر یا شاعر ولټوئ...',
                  leading: const Icon(Icons.search_rounded),
                  onChanged: (v) => setState(() => query = v.trim()),
                  elevation: const WidgetStatePropertyAll(0),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 68,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ChoiceChip(
                    label: Text(categories[i]),
                    selected: category == categories[i],
                    onSelected: (_) =>
                        setState(() => category = categories[i]),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                child: Row(
                  children: [
                    Text('غوره شعرونه',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const Spacer(),
                    Text('${visible.length} شعرونه'),
                  ],
                ),
              ),
            ),
            if (visible.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('کوم شعر پیدا نه شو.')),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final poem = visible[index];
                      final saved = favorites.contains(poem.title);
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        color: colors.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(color: colors.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Chip(label: Text(poem.category)),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => setState(() {
                                      saved
                                          ? favorites.remove(poem.title)
                                          : favorites.add(poem.title);
                                    }),
                                    icon: Icon(
                                      saved
                                          ? Icons.favorite_rounded
                                          : Icons.favorite_border_rounded,
                                      color: saved ? colors.error : null,
                                    ),
                                  ),
                                ],
                              ),
                              Text(poem.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              for (final line in poem.lines)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Text(line,
                                      style: const TextStyle(height: 1.8)),
                                ),
                              const Divider(height: 22),
                              Row(
                                children: [
                                  const Icon(Icons.edit_note_rounded, size: 19),
                                  const SizedBox(width: 6),
                                  Text(poem.poet),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: visible.length,
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'کور',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              label: 'خوښ شوي',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              label: 'شاعران',
            ),
          ],
        ),
      ),
    );
  }
}
