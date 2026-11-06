import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ادبي خزانه | اډمین',
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Vazirmatn',
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF245B50)),
      scaffoldBackgroundColor: const Color(0xFFF5F4F0),
      cardTheme: CardThemeData(
        elevation: 0, color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
    home: const Directionality(textDirection: TextDirection.rtl, child: AuthGate()),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseAuth.instance.authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.data == null) return const LoginPage();
      return FutureBuilder<DatabaseEvent>(
        future: FirebaseDatabase.instance.ref('admins/${snapshot.data!.uid}').once(),
        builder: (context, role) {
          if (role.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!role.hasData || role.data!.snapshot.value == null) {
            return Scaffold(body: Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.gpp_bad_rounded, size: 55, color: Colors.red),
                const SizedBox(height: 12),
                const Text('دا حساب د اډمین اجازه نه لري.'),
                const SizedBox(height: 14),
                FilledButton(onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('وتل')),
              ]),
            )));
          }
          return const AdminHome();
        },
      );
    },
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
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
    body: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430),
        child: Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(height: 76, width: 76, alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF245B50), Color(0xFFB77928)]),
                borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 39)),
            const SizedBox(height: 18),
            const Text('ادبي خزانه', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
            const Text('د اډمین مدیریت پینل', textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 26),
            TextField(controller: email, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'ایمیل', prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder())),
            const SizedBox(height: 13),
            TextField(controller: password, obscureText: true,
              decoration: const InputDecoration(labelText: 'پټ نوم', prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder())),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 10),
              child: Text(error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: loading ? null : login,
              child: loading ? const SizedBox(height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('ننوتل')),
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
    final pages = [const PoemsAdminPage(),
      const SimpleListAdmin(path: 'poets', title: 'شاعران'),
      const GalleryAdminPage(), const AdminCommentsPage(),
      const TelegramArchiveAdminPage()];
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
          NavigationDestination(icon: Icon(Icons.forum_outlined), selectedIcon: Icon(Icons.forum_rounded), label: 'تبصرې'),
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
  bool hideToken = true;
  @override
  void dispose() { channel.dispose(); token.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(16), children: [
    Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF173D69), Color(0xFF287CA5), Color(0xFF38A58A)]),
      borderRadius: BorderRadius.circular(24)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.telegram, color: Colors.white, size: 38), SizedBox(height: 10),
        Text('د ټیلیګرام پوسټونو استخراج', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        Text('د چینل لینک او Bot Token ورکړئ؛ له نښلولو وروسته نوي پوسټونه آرشیف ته راټولېږي.', style: TextStyle(color: Colors.white70, height: 1.7)),
      ])),
    const SizedBox(height: 18),
    TextField(controller: channel, keyboardType: TextInputType.url, textDirection: TextDirection.ltr,
      decoration: const InputDecoration(labelText: 'د ټیلیګرام چینل لینک', hintText: 'https://t.me/channelname', prefixIcon: Icon(Icons.link), border: OutlineInputBorder())),
    const SizedBox(height: 12),
    TextField(controller: token, obscureText: hideToken, textDirection: TextDirection.ltr,
      decoration: InputDecoration(labelText: 'د Bot Token', prefixIcon: const Icon(Icons.key), suffixIcon: IconButton(
        onPressed: () => setState(() => hideToken = !hideToken), icon: Icon(hideToken ? Icons.visibility : Icons.visibility_off)), border: const OutlineInputBorder())),
    const SizedBox(height: 14),
    const Text('بوټ باید د چینل اډمین وي. د امنیت لپاره ټوکن باید خوندي HTTPS سرور ته ولېږل شي. عادي Bot API زاړه پوسټونه نه راوباسي؛ یوازې نوي پوسټونه ترلاسه کوي.', style: TextStyle(height: 1.7, fontSize: 12)),
    const SizedBox(height: 14),
    FilledButton.icon(onPressed: () {
      if (channel.text.trim().isEmpty || token.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('د چینل لینک او Bot Token دواړه ولیکئ.')));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('د خوندي ټیلیګرام سرور نښلون لا نه دی بشپړ شوی؛ ټوکن مو نه دی لېږل شوی.')));
    }, icon: const Icon(Icons.cloud_download_outlined), label: const Text('د پوسټونو استخراج پیل')),
  ]);
}

class AdminCommentsPage extends StatelessWidget {
  const AdminCommentsPage({super.key});

  Future<void> _reply(BuildContext context, String poemId, String commentId) async {
    final controller = TextEditingController();
    final value = await showModalBottomSheet<String>(
      context: context, isScrollControlled: true, showDragHandle: true,
      builder: (ctx) => Directionality(textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('د لوستونکي تبصرې ته ځواب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(controller: controller, autofocus: true, minLines: 2, maxLines: 5,
              maxLength: 500, decoration: const InputDecoration(hintText: 'ځواب ولیکئ...')),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) Navigator.pop(ctx, controller.text.trim());
              }, child: const Text('ځواب خپرول'))),
          ]),
        )),
    );
    controller.dispose();
    if (value == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseDatabase.instance.ref('comments/$poemId/$commentId/adminReply').set({
      'text': value, 'adminUid': user.uid,
      'adminName': user.displayName ?? 'د ادبي خزانه اداره',
      'createdAt': ServerValue.timestamp,
    });
  }

  Future<void> _delete(BuildContext context, String poemId, String commentId) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) =>
      Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
        title: const Text('تبصره ړنګول؟'),
        content: const Text('دا تبصره به د شعر له پاڼې هم حذف شي.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('بندول')),
          FilledButton.tonal(onPressed: () => Navigator.pop(ctx, true), child: const Text('ړنګول')),
        ],
      )));
    if (yes == true) {
      await FirebaseDatabase.instance.ref('comments/$poemId/$commentId').remove();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<DatabaseEvent>(
    stream: FirebaseDatabase.instance.ref('comments').onValue,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('تبصرې نه لوډ کېږي: ${snapshot.error}'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final root = snapshot.data!.snapshot.value;
      if (root is! Map || root.isEmpty) return const Center(child: Text('تر اوسه تبصرې نشته.'));
      final rows = <({String poemId, String commentId, Map<String, dynamic> data})>[];
      for (final poemEntry in root.entries) {
        if (poemEntry.value is! Map) continue;
        for (final commentEntry in (poemEntry.value as Map).entries) {
          if (commentEntry.value is! Map) continue;
          rows.add((
            poemId: poemEntry.key.toString(),
            commentId: commentEntry.key.toString(),
            data: Map<String, dynamic>.from(commentEntry.value as Map),
          ));
        }
      }
      rows.sort((a, b) => ((b.data['createdAt'] as num?) ?? 0)
          .compareTo((a.data['createdAt'] as num?) ?? 0));
      return ListView.separated(
        padding: const EdgeInsets.all(14), itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 9),
        itemBuilder: (context, index) {
          final row = rows[index];
          final data = row.data;
          final reply = data['adminReply'] is Map
              ? Map<String, dynamic>.from(data['adminReply'] as Map) : null;
          final likes = data['likes'] is Map ? (data['likes'] as Map).length : 0;
          return Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
                const SizedBox(width: 9),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text((data['displayName'] ?? 'لوستونکی').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text('د شعر پېژند: ${row.poemId}',
                    style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ])),
                Text('$likes خوښونې', style: const TextStyle(fontSize: 11)),
              ]),
              const SizedBox(height: 10),
              Text((data['text'] ?? '').toString(), style: const TextStyle(height: 1.6)),
              if (reply != null) Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('اوسنی ځواب: ${reply['text'] ?? ''}',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _reply(context, row.poemId, row.commentId),
                  icon: const Icon(Icons.reply_rounded), label: const Text('ځواب'))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton.tonalIcon(
                  onPressed: () => _delete(context, row.poemId, row.commentId),
                  icon: const Icon(Icons.delete_outline_rounded), label: const Text('ړنګول'))),
              ]),
            ]),
          ));
        },
      );
    },
  );
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
            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => FirebaseDatabase.instance.ref('poems/$id').remove()),
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
          child: StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref('gallery').onValue,
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
    final imageUrl = await _chooseGalleryImage();
    try {
      final ref = FirebaseDatabase.instance.ref(widget.path);
      if (id == null) {
        await ref.push().set({'name': name.trim(), if (imageUrl != null) 'imageUrl': imageUrl, 'createdAt': ServerValue.timestamp});
      } else {
        await ref.child(id).update({'name': name.trim(), if (imageUrl != null) 'imageUrl': imageUrl, 'updatedAt': ServerValue.timestamp});
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('په بریالیتوب خوندي شو.')));
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

class GalleryAdminPage extends StatelessWidget {
  const GalleryAdminPage({super.key});
  Future<void> upload(BuildContext context) async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1800);
    if (file == null) return;
    try {
      final ref = FirebaseDatabase.instance.ref('gallery').push();
      final storage = FirebaseStorage.instance.ref('gallery/${ref.key}.jpg');
      await storage.putFile(File(file.path));
      final url = await storage.getDownloadURL();
      await ref.set({'name': file.name, 'url': url, 'storagePath': storage.fullPath,
        'createdAt': ServerValue.timestamp, 'createdBy': FirebaseAuth.instance.currentUser?.uid});
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
                      final path = d['storagePath']?.toString();
                      if (path != null) { try { await FirebaseStorage.instance.ref(path).delete(); } catch (_) {} }
                    })),
                ])),
                Padding(padding: const EdgeInsets.all(8), child: Text((d['name'] ?? 'انځور').toString(), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]));
            })),
      ]);
    });
}

class PoemEditor extends StatefulWidget {
  const PoemEditor({super.key});
  @override
  State<PoemEditor> createState() => _PoemEditorState();
}
class _PoemEditorState extends State<PoemEditor> {
  final title = TextEditingController();
  final text = TextEditingController();
  final picker = ImagePicker();
  String? categoryId, poetId;
  XFile? image;
  String? existingImageUrl;
  bool featured = false, saving = false;
  static const List<String> offlineCategoryNames = [
    'حمدیه شاعري', 'نعتیه شاعري', 'حماسي شاعري', 'عشقي شاعري',
    'غنایي شاعري', 'عرفاني شاعري', 'تصوفي شاعري', 'فلسفي شاعري',
    'اخلاقي شاعري', 'اصلاحي شاعري', 'ټولنیزه شاعري', 'سیاسي شاعري',
    'ملي شاعري', 'وطني شاعري', 'رزمي شاعري', 'انتقادي شاعري',
    'طنزي شاعري', 'هجوي شاعري', 'مرثیه', 'تاریخي شاعري',
    'تعلیمي شاعري', 'طبیعي شاعري', 'حماسي وطني شاعري',
    'فراق او هجران', 'تصوف او معرفت', 'نور بېلابېل شعرونه',
  ];
  Future<void> save() async {
    if (text.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('د شعر متن حتمي دی.')));
      return;
    }
    setState(() => saving = true);
    try {
      final ref = FirebaseDatabase.instance.ref('poems').push();
      final imageUrl = existingImageUrl;
      final data = <String, dynamic>{
        'text': text.text.trim(),
        'categoryId': categoryId ?? 'offline_category_${offlineCategoryNames.length - 1}',
        'createdAt': ServerValue.timestamp,
        'featured': featured,
        'isPublished': true,
      };
      if (title.text.trim().isNotEmpty) data['title'] = title.text.trim();
      if (poetId != null) data['poetId'] = poetId;
      if (imageUrl != null) data['imageUrl'] = imageUrl;
      await ref.set(data);
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
    appBar: AppBar(title: const Text('نوی شعر ثبتول')),
    body: FutureBuilder<DataSnapshot>(
      future: FirebaseDatabase.instance.ref('poets').get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final poets = snap.data!.value is Map
          ? Map<String, dynamic>.from(snap.data!.value as Map) : <String, dynamic>{};
        return ListView(padding: const EdgeInsets.all(16), children: [
          TextField(controller: title, decoration: const InputDecoration(
            labelText: 'د شعر عنوان (اختیاري)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: text, minLines: 5, maxLines: 12,
            decoration: const InputDecoration(labelText: 'د شعر متن *',
              alignLabelWithHint: true, border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: categoryId,
            decoration: const InputDecoration(labelText: 'کټګوري (اختیاري)',
              helperText: 'که کټګوري و نه ټاکئ، شعر به «نور بېلابېل شعرونه» کې ښکاره شي.',
              border: OutlineInputBorder()),
            items: [
              const DropdownMenuItem<String>(
                value: null, child: Text('کټګوري نه ټاکل کېږي')),
              ...List.generate(offlineCategoryNames.length, (index) =>
                DropdownMenuItem<String>(
                  value: 'offline_category_$index',
                  child: Text(offlineCategoryNames[index]))),
            ],
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
              final selected = await showModalBottomSheet<Map<String, dynamic>>(
                context: context, isScrollControlled: true, showDragHandle: true,
                builder: (ctx) => Directionality(textDirection: TextDirection.rtl,
                  child: SizedBox(height: MediaQuery.of(ctx).size.height * .72,
                    child: Column(children: [
                      const Padding(padding: EdgeInsets.all(14), child: Text('له ګالري انځور وټاکئ',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                      Expanded(child: StreamBuilder<DatabaseEvent>(
                        stream: FirebaseDatabase.instance.ref('gallery').onValue,
                        builder: (ctx, snap) {
                          final raw = snap.data?.snapshot.value;
                          final items = raw is Map ? raw.entries.toList().reversed.toList() : <dynamic>[];
                          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                          if (items.isEmpty) return const Center(child: Text('ګالري تشه ده؛ لومړی انځور پورته کړئ.'));
                          return GridView.builder(padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                            itemCount: items.length, itemBuilder: (_, i) {
                              final d = Map<String, dynamic>.from(items[i].value as Map);
                              return InkWell(onTap: () => Navigator.pop(ctx, d),
                                child: Image.network((d['url'] ?? '').toString(), fit: BoxFit.cover));
                            });
                        })),
                    ]))),
              );
              if (selected != null) setState(() => existingImageUrl = selected['url']?.toString());
            },
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(existingImageUrl == null ? 'له ګالري انځور وټاکئ (اختیاري)' : 'د ګالري انځور وټاکل شو')),
          SwitchListTile(contentPadding: EdgeInsets.zero, value: featured,
            onChanged: (v) => setState(() => featured = v), title: const Text('د ورځې غوره شعر')),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: saving ? null : save,
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(saving ? 'خوندي کېږي...' : 'شعر خپرول')),
        ]);
      },
    ),
  );
}
