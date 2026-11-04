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
    final pages = [const PoemsAdminPage(), const SimpleListAdmin(path: 'categories', title: 'کټګورۍ'),
      const SimpleListAdmin(path: 'poets', title: 'شاعران')];
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
            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => FirebaseDatabase.instance.ref('poems/$id').remove()),
          ));
        });
    },
  );
}

class SimpleListAdmin extends StatelessWidget {
  const SimpleListAdmin({super.key, required this.path, required this.title});
  final String path, title;
  @override
  Widget build(BuildContext context) => StreamBuilder<DatabaseEvent>(
    stream: FirebaseDatabase.instance.ref(path).onValue,
    builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      final raw = snap.data!.snapshot.value;
      if (raw is! Map) return Center(child: Text('$title لا نه دي ثبت شوې.'));
      return ListView(children: raw.entries.map((e) {
        final value = e.value is Map ? (e.value['name'] ?? '') : e.value;
        return Card(margin: const EdgeInsets.fromLTRB(14, 5, 14, 5),
          child: ListTile(leading: const Icon(Icons.label_outline), title: Text('$value')));
      }).toList());
    },
  );
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
  bool featured = false, saving = false;
  Future<void> save() async {
    if (text.text.trim().isEmpty || categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('د شعر متن او کټګوري حتمي دي.')));
      return;
    }
    setState(() => saving = true);
    try {
      final ref = FirebaseDatabase.instance.ref('poems').push();
      String? imageUrl;
      if (image != null) {
        final upload = await FirebaseStorage.instance.ref('poems/${ref.key}.jpg')
          .putFile(File(image!.path));
        imageUrl = await upload.ref.getDownloadURL();
      }
      final data = <String, dynamic>{
        'text': text.text.trim(),
        'categoryId': categoryId,
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
              final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
              if (picked != null) setState(() => image = picked);
            },
            icon: const Icon(Icons.image_outlined),
            label: Text(image == null ? 'انځور (اختیاري)' : 'انځور وټاکل شو')),
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
