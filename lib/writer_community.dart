import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class WriterCommunityPage extends StatefulWidget {
  const WriterCommunityPage({super.key});
  @override
  State<WriterCommunityPage> createState() => _WriterCommunityPageState();
}
class _WriterCommunityPageState extends State<WriterCommunityPage> with SingleTickerProviderStateMixin {
  final db = FirebaseDatabase.instance;
  late final tabs = TabController(length: 3, vsync: this);
  bool admin = false;
  bool checked = false;
  User? get current => FirebaseAuth.instance.currentUser;
  @override
  void initState() { super.initState(); _checkAdmin(); }
  @override
  void dispose() { tabs.dispose(); super.dispose(); }
  Future<void> _checkAdmin() async {
    final u = current;
    if (u != null && !u.isAnonymous) {
      try { final s = await db.ref('admins/' + u.uid + '/role').get(); admin = s.value == 'admin'; } catch (_) {}
    }
    if (mounted) setState(() => checked = true);
  }
  bool _signedIn() {
    final u = current;
    if (u != null && !u.isAnonymous) return true;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('د دې برخې لپاره لومړی خپل حساب ته ننوځئ.')));
    return false;
  }
  Future<void> _editProfile() async {
    if (!_signedIn()) return;
    final u = current!;
    final snap = await db.ref('profiles/' + u.uid).get();
    final map = snap.value is Map ? Map<String,dynamic>.from(snap.value as Map) : <String,dynamic>{};
    final name = TextEditingController(text: (map['displayName'] ?? u.displayName ?? '').toString());
    final bio = TextEditingController(text: (map['bio'] ?? '').toString());
    final ok = await showDialog<bool>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('زما ادبي پروفایل'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, maxLength: 28, decoration: const InputDecoration(labelText: 'ښکاره نوم')),
        TextField(controller: bio, maxLength: 180, maxLines: 3, decoration: const InputDecoration(labelText: 'لنډه پېژندنه')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c,false), child: const Text('لغوه')),
        FilledButton(onPressed: () => Navigator.pop(c,true), child: const Text('خوندي کول'))],
    )));
    if (ok == true && name.text.trim().isNotEmpty) {
      await db.ref('profiles/' + u.uid).update({'displayName':name.text.trim(),'bio':bio.text.trim(),'updatedAt':ServerValue.timestamp});
      await u.updateDisplayName(name.text.trim());
    }
    name.dispose(); bio.dispose();
  }
  Future<void> _submit() async {
    if (!_signedIn()) return;
    final title = TextEditingController();
    final body = TextEditingController();
    final category = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (c) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      title: const Text('نوی شعر د تایید لپاره'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller:title, maxLength:90, decoration:const InputDecoration(labelText:'د شعر عنوان')),
        TextField(controller:category, maxLength:60, decoration:const InputDecoration(labelText:'کټګوري')),
        TextField(controller:body, minLines:5, maxLines:10, decoration:const InputDecoration(labelText:'د شعر متن')),
        const SizedBox(height:8),
        const Text('شعر به د اډمین له تایید مخکې عام نه خپرېږي.',style:TextStyle(fontSize:12)),
      ])),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('لغوه')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('لېږل'))],
    )));
    if (ok == true && body.text.trim().isNotEmpty && category.text.trim().isNotEmpty) {
      final u = current!;
      final profile = await db.ref('profiles/' + u.uid + '/displayName').get();
      await db.ref('pendingPoems/' + u.uid).push().set({
        'title':title.text.trim(),'text':body.text.trim(),'categoryName':category.text.trim(),
        'authorUid':u.uid,'authorName':profile.value ?? u.displayName ?? 'لیکوال',
        'status':'pending','createdAt':ServerValue.timestamp,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('شعر د اډمین تایید ته ولېږل شو.')));
    }
    title.dispose(); body.dispose(); category.dispose();
  }
  Future<void> _follow(String author, bool following) async {
    if (!_signedIn()) return;
    final me = current!.uid;
    if (me == author) return;
    await db.ref().update({
      'followers/' + author + '/' + me: following ? null : true,
      'following/' + me + '/' + author: following ? null : true,
    });
  }
  Widget _authors() => StreamBuilder<DatabaseEvent>(stream:db.ref('profiles').onValue,builder:(c,s) {
    if (!s.hasData) return const Center(child:CircularProgressIndicator());
    final raw=s.data!.snapshot.value;
    if (raw is! Map || raw.isEmpty) return const Center(child:Text('تر اوسه لیکوال پروفایل نشته.'));
    final entries=raw.entries.toList();
    return ListView(padding:const EdgeInsets.all(12),children:[
      Row(children:[const Expanded(child:Text('د ادبي ټولنې لیکوالان',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18))),
        FilledButton.tonal(onPressed:_editProfile,child:const Text('زما پروفایل'))]),
      const SizedBox(height:8),
      ...entries.map((e) {
        final uid=e.key.toString();
        final p=e.value is Map ? Map<String,dynamic>.from(e.value as Map) : <String,dynamic>{};
        final name=(p['displayName']??'لیکوال').toString();
        return Card(clipBehavior:Clip.antiAlias,child:Column(children:[
          Container(height:58,decoration:BoxDecoration(gradient:LinearGradient(colors:[Theme.of(context).colorScheme.primary,Theme.of(context).colorScheme.tertiary]))),
          ListTile(leading:CircleAvatar(child:Text(name.isEmpty?'ل':name.substring(0,1))),
            title:Row(children:[Expanded(child:Text(name,style:const TextStyle(fontWeight:FontWeight.w900))),
              if(p['verified']==true || p['role']=='admin') const Icon(Icons.verified,color:Colors.blue,size:18)]),
            subtitle:Text((p['bio']??'د ادبي نړۍ لیکوال').toString(),maxLines:2,overflow:TextOverflow.ellipsis),
            trailing:current!=null && !current!.isAnonymous && current!.uid!=uid
              ? StreamBuilder<DatabaseEvent>(stream:db.ref('followers/'+uid+'/'+current!.uid).onValue,builder:(c,f) {
                  final yes=f.data?.snapshot.value==true;
                  return FilledButton.tonal(onPressed:()=>_follow(uid,yes),child:Text(yes?'تعقیب پرېږده':'تعقیب'));
                }) : const Icon(Icons.auto_stories_rounded)),
          StreamBuilder<DatabaseEvent>(stream:db.ref('followers/'+uid).onValue,builder:(c,f) {
            return Padding(padding:const EdgeInsets.only(bottom:10),child:Text('پلویان: '+(f.data?.snapshot.children.length??0).toString(),style:TextStyle(color:Theme.of(context).colorScheme.primary,fontWeight:FontWeight.w800)));
          }),
        ]));
      }),
    ]);
  });
  Widget _mySubmissions() {
    final u=current;
    if(u==null || u.isAnonymous) return const Center(child:Text('د شعر لېږلو لپاره حساب ته ننوځئ.'));
    return StreamBuilder<DatabaseEvent>(stream:db.ref('pendingPoems/'+u.uid).onValue,builder:(c,s) {
      if(!s.hasData) return const Center(child:CircularProgressIndicator());
      final raw=s.data!.snapshot.value;
      final entries=raw is Map ? raw.entries.toList() : [];
      return ListView(padding:const EdgeInsets.all(14),children:[
        FilledButton.icon(onPressed:_submit,icon:const Icon(Icons.add),label:const Text('نوی شعر ولېږئ')),
        const SizedBox(height:10),
        if(entries.isEmpty) const Padding(padding:EdgeInsets.all(25),child:Text('د تایید په تمه شعرونه نه لرئ.',textAlign:TextAlign.center)),
        ...entries.map((e) { final p=Map<String,dynamic>.from(e.value as Map); return Card(child:ListTile(
          leading:const Icon(Icons.hourglass_top_rounded),title:Text((p['title']??'بې عنوانه').toString()),
          subtitle:const Text('د اډمین تایید ته په تمه')));}),
      ]);
    });
  }
  Widget _moderation() {
    if(!admin) return const Center(child:Text('دا برخه یوازې اډمین ته ده.'));
    return StreamBuilder<DatabaseEvent>(stream:db.ref('pendingPoems').onValue,builder:(c,s) {
      if(!s.hasData) return const Center(child:CircularProgressIndicator());
      final raw=s.data!.snapshot.value;
      final cards=<Widget>[];
      if(raw is Map) for(final a in raw.entries) {
        if(a.value is! Map) continue;
        for(final e in (a.value as Map).entries) {
          if(e.value is! Map) continue;
          final p=Map<String,dynamic>.from(e.value as Map);
          final uid=a.key.toString(), id=e.key.toString();
          cards.add(Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Text((p['title']??'بې عنوانه').toString(),style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),
            Text('لیکوال: '+(p['authorName']??uid).toString()+' • '+(p['categoryName']??'').toString()),
            const SizedBox(height:8),Text((p['text']??'').toString(),maxLines:6,overflow:TextOverflow.ellipsis),
            Row(children:[
              Expanded(child:OutlinedButton(onPressed:() async {await db.ref('pendingPoems/'+uid+'/'+id).remove();},child:const Text('ردول'))),
              const SizedBox(width:8),
              Expanded(child:FilledButton(onPressed:() async {
                final categories=await db.ref('categories').get();
                String? categoryId;
                if(categories.value is Map && (categories.value as Map).isNotEmpty) categoryId=(categories.value as Map).keys.first.toString();
                if(categoryId==null) {if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('لومړی یوه کټګوري جوړه کړئ.')));return;}
                await db.ref('poems').push().set({'title':p['title'],'text':p['text'],'categoryId':categoryId,
                  'poetId':null,'authorUid':uid,'authorName':p['authorName'],'isPublished':true,'featured':false,
                  'createdAt':p['createdAt']??ServerValue.timestamp,'approvedAt':ServerValue.timestamp,'approvedBy':current!.uid});
                await db.ref('pendingPoems/'+uid+'/'+id).remove();
              },child:const Text('تایید او خپرول'))),
            ]),
          ]))));
        }
      }
      return cards.isEmpty?const Center(child:Text('د تایید لپاره شعر نشته.')):ListView(padding:const EdgeInsets.all(12),children:cards);
    });
  }
  @override
  Widget build(BuildContext context) {
    if(!checked) return const Scaffold(body:Center(child:CircularProgressIndicator()));
    return Directionality(textDirection:TextDirection.rtl,child:Scaffold(
      appBar:AppBar(title:const Text('د لیکوالانو ټولنه'),bottom:TabBar(controller:tabs,tabs:[
        const Tab(text:'لیکوالان',icon:Icon(Icons.people_alt_outlined)),
        const Tab(text:'زما شعرونه',icon:Icon(Icons.edit_note_rounded)),
        const Tab(text:'د اډمین تایید',icon:Icon(Icons.fact_check_outlined)),
      ])),
      body:TabBarView(controller:tabs,children:[_authors(),_mySubmissions(),_moderation()]),
      floatingActionButton:FloatingActionButton.extended(onPressed:_submit,icon:const Icon(Icons.add),label:const Text('شعر ولېږئ')),
    ));
  }
}
