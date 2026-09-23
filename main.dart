import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDb.instance.init();
  runApp(const BillingApp());
}

class BillingApp extends StatelessWidget {
  const BillingApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'School Book Billing',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const HomePage(),
  );
}

class AppDb {
  AppDb._();
  static final instance = AppDb._();
  Database? _db;
  Future<void> init() async {
    final dir = await getDatabasesPath();
    _db = await openDatabase(join(dir, 'school_book_billing.db'), version: 1,
      onCreate: (db, v) async {
        await db.execute('CREATE TABLE schools(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL)');
        await db.execute('CREATE TABLE standards(id INTEGER PRIMARY KEY AUTOINCREMENT,schoolId INTEGER,year TEXT,name TEXT)');
        await db.execute('CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT,schoolId INTEGER,year TEXT,standardId INTEGER,section TEXT,sr INTEGER,name TEXT,subject TEXT,price REAL)');
        await db.execute('CREATE TABLE invoices(id INTEGER PRIMARY KEY AUTOINCREMENT,invoiceNo TEXT,date TEXT,student TEXT,mobile TEXT,schoolId INTEGER,school TEXT,year TEXT,standard TEXT,textbookTotal REAL,stationeryTotal REAL,grandTotal REAL)');
        await db.execute('CREATE TABLE invoice_items(id INTEGER PRIMARY KEY AUTOINCREMENT,invoiceId INTEGER,section TEXT,sr INTEGER,name TEXT,subject TEXT,price REAL,qty INTEGER,amount REAL)');
        final s = await db.insert('schools', {'name':'Venus World School'});
        final st = await db.insert('standards', {'schoolId':s,'year':'2026-27','name':'4th Standard'});
        final books = [
          ['Spendid Science','Science',575],['The World Around Us','Science',490],['Maths Milestone','Mathematics',585],['Level Up Vantage','English',610],['English Grammer','English',430],['Shivai','Marathi',290],['Maitri Vyakaran','Marathi',180],['Veena','Hindi',430],['Dyanmay-Grammar','Hindi',415],['Computer Science Success','Computer',395],['The GK Odyssey','GK',398],['Art Smart Drawing','Drawing',180],['Chatrapati Shivaji Maharaj','EVS Textbook 2',68],
        ];
        for (var i=0;i<books.length;i++) await db.insert('items', {'schoolId':s,'year':'2026-27','standardId':st,'section':'TextBooks','sr':i+1,'name':books[i][0],'subject':books[i][1],'price':books[i][2]});
        final station = [['1 Line Notebook 100 Pages',25],['1 Line Notebook 200 Pages',50],['2 Line Notebook 200 Pages',50],['Drawing Book A4 size',65],['Crayon Colour 12 Shades',35]];
        for (var i=0;i<station.length;i++) await db.insert('items', {'schoolId':s,'year':'2026-27','standardId':st,'section':'Notebook and Stationary','sr':i+1,'name':station[i][0],'subject':'','price':station[i][1]});
      });
  }
  Database get db => _db!;
  Future<List<Map<String,dynamic>>> schools() => db.query('schools', orderBy:'name');
  Future<List<Map<String,dynamic>>> years() async { final r=await db.rawQuery('SELECT DISTINCT year FROM standards ORDER BY year DESC'); return r; }
  Future<List<Map<String,dynamic>>> standards(int schoolId,String year) => db.query('standards',where:'schoolId=? AND year=?',whereArgs:[schoolId,year]);
  Future<List<Map<String,dynamic>>> items(int schoolId,String year,int standardId) => db.query('items',where:'schoolId=? AND year=? AND standardId=?',whereArgs:[schoolId,year,standardId],orderBy:'section,sr');
  Future<int> nextInvoice() async { final r=await db.rawQuery('SELECT COUNT(*) c FROM invoices'); final n=(Sqflite.firstIntValue(r)??0)+1; return n; }
}

class HomePage extends StatefulWidget { const HomePage({super.key}); @override State<HomePage> createState()=>_HomePageState(); }
class _HomePageState extends State<HomePage> {
  int tab=0;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('School Book Billing'), actions:[IconButton(onPressed:()=>setState((){}),icon:const Icon(Icons.refresh))]),
    body: IndexedStack(index:tab,children:[const DashboardPage(), const NewBillPage(), const HistoryPage(), const MastersPage()]),
    bottomNavigationBar: NavigationBar(selectedIndex:tab,onDestinationSelected:(i)=>setState(()=>tab=i),destinations:const [
      NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'Home'),
      NavigationDestination(icon:Icon(Icons.receipt_long_outlined),selectedIcon:Icon(Icons.receipt_long),label:'New Bill'),
      NavigationDestination(icon:Icon(Icons.history),label:'Bills'),
      NavigationDestination(icon:Icon(Icons.settings_outlined),selectedIcon:Icon(Icons.settings),label:'Masters'),
    ]),
  );
}

class DashboardPage extends StatelessWidget { const DashboardPage({super.key});
  @override Widget build(BuildContext context)=>FutureBuilder<List<Map<String,dynamic>>>(future:AppDb.instance.schools(),builder:(c,s)=>FutureBuilder<List<Map<String,dynamic>>>(future:AppDb.instance.db.query('invoices'),builder:(c,i){final bills=i.data??[];final sales=bills.fold<double>(0,(a,b)=>a+(b['grandTotal'] as num).toDouble());return ListView(padding:const EdgeInsets.all(16),children:[Wrap(spacing:12,runSpacing:12,children:[_k('Bills',bills.length.toString()),_k('Sales','₹${sales.toStringAsFixed(2)}'),_k('Schools',(s.data??[]).length.toString())]),const SizedBox(height:20),const Card(child:Padding(padding:EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Offline billing',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)),SizedBox(height:8),Text('All billing data stays on this phone. No server or monthly hosting is required.'),SizedBox(height:8),Text('Use Masters to maintain schools, standards, books and stationery. Use New Bill for daily billing.')])))]);});
  Widget _k(String a,String b)=>SizedBox(width:170,child:Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(a),Text(b,style:const TextStyle(fontSize:24,fontWeight:FontWeight.bold))]))));
}

class NewBillPage extends StatefulWidget { const NewBillPage({super.key}); @override State<NewBillPage> createState()=>_NewBillPageState(); }
class _NewBillPageState extends State<NewBillPage> {
  final student=TextEditingController(), mobile=TextEditingController();
  List<Map<String,dynamic>> schools=[],years=[],standards=[],items=[]; int? schoolId,standardId; String? year; final Map<int,int> qty={};
  @override void initState(){super.initState();load();}
  Future<void> load() async { schools=await AppDb.instance.schools();years=await AppDb.instance.years();if(schools.isNotEmpty)schoolId=schools.first['id'];if(years.isNotEmpty)year=years.first['year'];await loadStandards();setState((){}); }
  Future<void> loadStandards() async { standards=schoolId==null||year==null?[]:await AppDb.instance.standards(schoolId!,year!);standardId=standards.isNotEmpty?standards.first['id']:null;await loadItems(); }
  Future<void> loadItems() async { items=standardId==null?[]:await AppDb.instance.items(schoolId!,year!,standardId!);qty.clear(); }
  double get totalA=>items.where((x)=>x['section']=='TextBooks').fold(0,(a,x)=>a+(x['price'] as num)*((qty[x['id']]??0)));
  double get totalB=>items.where((x)=>x['section']!='TextBooks').fold(0,(a,x)=>a+(x['price'] as num)*((qty[x['id']]??0)));
  Future<void> saveBill() async { if(student.text.trim().isEmpty||schoolId==null||standardId==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Enter student, school and standard.')));return;} final selected=items.where((x)=>(qty[x['id']]??0)>0).toList(); if(selected.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Select at least one item.')));return;} final no=await AppDb.instance.nextInvoice();final inv='INV-${DateTime.now().year}-${no.toString().padLeft(4,'0')}';final school=schools.firstWhere((x)=>x['id']==schoolId)['name'];final st=standards.firstWhere((x)=>x['id']==standardId)['name'];final id=await AppDb.instance.db.insert('invoices',{'invoiceNo':inv,'date':DateTime.now().toIso8601String(),'student':student.text.trim(),'mobile':mobile.text.trim(),'schoolId':schoolId,'school':school,'year':year,'standard':st,'textbookTotal':totalA,'stationeryTotal':totalB,'grandTotal':totalA+totalB});for(final x in selected){final q=qty[x['id']]!;await AppDb.instance.db.insert('invoice_items',{'invoiceId':id,'section':x['section'],'sr':x['sr'],'name':x['name'],'subject':x['subject'],'price':x['price'],'qty':q,'amount':(x['price'] as num)*q});}if(!mounted)return;final bill=await loadInvoice(id);await showBillActions(context,bill);setState((){}); }
  Future<Map<String,dynamic>> loadInvoice(int id) async {final h=(await AppDb.instance.db.query('invoices',where:'id=?',whereArgs:[id])).first;final it=await AppDb.instance.db.query('invoice_items',where:'invoiceId=?',whereArgs:[id],orderBy:'section,sr');return {'h':h,'it':it};}
  @override Widget build(BuildContext context){final books=items.where((x)=>x['section']=='TextBooks').toList();final stat=items.where((x)=>x['section']!='TextBooks').toList();return ListView(padding:const EdgeInsets.all(12),children:[Card(child:Padding(padding:const EdgeInsets.all(12),child:Column(children:[TextField(controller:student,decoration:const InputDecoration(labelText:'Student Name *')),TextField(controller:mobile,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Mobile No.')),DropdownButtonFormField<int>(value:schoolId,decoration:const InputDecoration(labelText:'School'),items:schools.map((x)=>DropdownMenuItem(value:x['id'] as int,child:Text(x['name']))).toList(),onChanged:(v)async{schoolId=v;await loadStandards();setState((){});}),DropdownButtonFormField<String>(value:year,decoration:const InputDecoration(labelText:'Academic Year'),items:years.map((x)=>DropdownMenuItem(value:x['year'] as String,child:Text(x['year']))).toList(),onChanged:(v)async{year=v;await loadStandards();setState((){});}),DropdownButtonFormField<int>(value:standardId,decoration:const InputDecoration(labelText:'Standard'),items:standards.map((x)=>DropdownMenuItem(value:x['id'] as int,child:Text(x['name']))).toList(),onChanged:(v)async{standardId=v;await loadItems();setState((){});})]))),_section('TextBooks (A)',books,true),_section('Notebook and Stationary (B)',stat,false),Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[_line('Total (A)',totalA),_line('Total (B)',totalB),const Divider(),_line('Grand Total',totalA+totalB,big:true),const SizedBox(height:10),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:saveBill,icon:const Icon(Icons.save),label:const Text('SAVE & VIEW BILL')))])))];}
  Widget _section(String title,List<Map<String,dynamic>> list,bool book){return Card(child:Padding(padding:const EdgeInsets.all(8),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Padding(padding:const EdgeInsets.all(8),child:Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))),...list.map((x)=>ListTile(title:Text(x['name']),subtitle:Text(book?'${x['subject']} • ₹${x['price']}':'₹${x['price']}'),trailing:SizedBox(width:115,child:Row(mainAxisAlignment:MainAxisAlignment.end,children:[IconButton(onPressed:()=>setState(()=>qty[x['id']]=maxInt(0,(qty[x['id']]??0)-1)),icon:const Icon(Icons.remove_circle_outline)),Text('${qty[x['id']]??0}'),IconButton(onPressed:()=>setState(()=>qty[x['id']]=((qty[x['id']]??0)+1)),icon:const Icon(Icons.add_circle_outline))])))).toList()]));}
  int maxInt(int a,int b)=>a>b?a:b;
  Widget _line(String a,double b,{bool big=false})=>Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(a,style:TextStyle(fontWeight:FontWeight.bold,fontSize:big?20:16)),Text('₹${b.toStringAsFixed(2)}',style:TextStyle(fontWeight:FontWeight.bold,fontSize:big?20:16))]);
}

Future<void> showBillActions(BuildContext context,Map<String,dynamic> bill) async {await Navigator.push(context,MaterialPageRoute(builder:(_)=>BillPage(bill:bill)));}

class BillPage extends StatelessWidget {final Map<String,dynamic> bill;const BillPage({super.key,required this.bill});
  Future<Uint8List> pdf() async {final h=bill['h'] as Map<String,dynamic>;final it=bill['it'] as List<Map<String,dynamic>>;final doc=pw.Document();final books=it.where((x)=>x['section']=='TextBooks').toList();final stat=it.where((x)=>x['section']!='TextBooks').toList();pw.Widget table(List<Map<String,dynamic>> a,bool book)=>pw.Table.fromTextArray(headers:book?['Sr.No','Name','Subject','Qty','Amount']:['Sr.No','Name','Price','Qty','Amount'],data:a.map((x)=>book?[x['sr'],x['name'],x['subject'],x['qty'],'₹${(x['amount'] as num).toStringAsFixed(2)}']:[x['sr'],x['name'],'₹${(x['price'] as num).toStringAsFixed(2)}',x['qty'],'₹${(x['amount'] as num).toStringAsFixed(2)}']).toList());doc.addPage(pw.Page(pageFormat:PdfPageFormat.a4,build:(c)=>pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[pw.Center(child:pw.Text(h['school'],style:pw.TextStyle(fontSize:18,fontWeight:pw.FontWeight.bold))),pw.Center(child:pw.Text('Book List ${h['year']}')),pw.Center(child:pw.Text(h['standard'])),pw.SizedBox(height:10),pw.Text('Invoice No: ${h['invoiceNo']}    Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(h['date']))}'),pw.Text('Student Name: ${h['student']}'),pw.Text('Mobile No.: ${h['mobile']}'),pw.SizedBox(height:12),pw.Text('TextBooks (A)',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)),table(books,true),pw.Align(alignment:pw.Alignment.centerRight,child:pw.Text('Total (A): ₹${(h['textbookTotal'] as num).toStringAsFixed(2)}')),pw.SizedBox(height:10),pw.Text('Notebook and Stationary (B)',style:pw.TextStyle(fontWeight:pw.FontWeight.bold)),table(stat,false),pw.Align(alignment:pw.Alignment.centerRight,child:pw.Text('Total (B): ₹${(h['stationeryTotal'] as num).toStringAsFixed(2)}')),pw.SizedBox(height:10),pw.Align(alignment:pw.Alignment.centerRight,child:pw.Text('GRAND TOTAL (A+B): ₹${(h['grandTotal'] as num).toStringAsFixed(2)}',style:pw.TextStyle(fontSize:16,fontWeight:pw.FontWeight.bold))) ]));return doc.save();}
  @override Widget build(BuildContext context){final h=bill['h'];return Scaffold(appBar:AppBar(title:const Text('Bill Preview'),actions:[IconButton(onPressed:()async=>Printing.layoutPdf(onLayout:(_)=>pdf()),icon:const Icon(Icons.print)),IconButton(onPressed:()async{final bytes=await pdf();final dir=await getTemporaryDirectory();final f=File('${dir.path}/${h['invoiceNo']}.pdf');await f.writeAsBytes(bytes);await Share.shareXFiles([XFile(f.path)],text:'School book bill ${h['invoiceNo']}');},icon:const Icon(Icons.share))]),body:PdfPreview(build:(_)=>pdf(),canChangePageFormat:false,canChangeOrientation:false,allowPrinting:true,allowSharing:true)]);}
}

class HistoryPage extends StatefulWidget{const HistoryPage({super.key});@override State<HistoryPage> createState()=>_HistoryPageState();}
class _HistoryPageState extends State<HistoryPage>{String q='';@override Widget build(BuildContext context)=>FutureBuilder<List<Map<String,dynamic>>>(future:AppDb.instance.db.query('invoices',orderBy:'id DESC'),builder:(c,s){final all=s.data??[];final list=all.where((x)=>q.isEmpty||('${x['invoiceNo']} ${x['student']} ${x['mobile']} ${x['school']}'.toLowerCase().contains(q.toLowerCase()))).toList();return ListView(padding:const EdgeInsets.all(12),children:[TextField(decoration:const InputDecoration(prefixIcon:Icon(Icons.search),labelText:'Search invoice / student / mobile'),onChanged:(v)=>setState(()=>q=v)),...list.map((x)=>ListTile(title:Text('${x['invoiceNo']} • ${x['student']}'),subtitle:Text('${x['school']} • ${x['standard']}'),trailing:Text('₹${(x['grandTotal'] as num).toStringAsFixed(2)}'),onTap:()async{final it=await AppDb.instance.db.query('invoice_items',where:'invoiceId=?',whereArgs:[x['id']]);await Navigator.push(context,MaterialPageRoute(builder:(_)=>BillPage(bill:{'h':x,'it':it})));setState((){});}))];});}}

class MastersPage extends StatelessWidget{const MastersPage({super.key});@override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.all(12),children:[_MasterCard(title:'Schools',icon:Icons.school,child:const SchoolMaster()),_MasterCard(title:'Standards',icon:Icons.class_,child:const StandardMaster()),_MasterCard(title:'Books & Stationery',icon:Icons.menu_book,child:const ItemMaster())]);}
class _MasterCard extends StatelessWidget{final String title;final IconData icon;final Widget child;const _MasterCard({required this.title,required this.icon,required this.child});@override Widget build(BuildContext context)=>Card(child:ExpansionTile(leading:Icon(icon),title:Text(title),children:[Padding(padding:const EdgeInsets.all(12),child:child)]));}
class SchoolMaster extends StatefulWidget{const SchoolMaster({super.key});@override State<SchoolMaster> createState()=>_SchoolMasterState();}
class _SchoolMasterState extends State<SchoolMaster>{final c=TextEditingController();@override Widget build(BuildContext context)=>Column(children:[TextField(controller:c,decoration:const InputDecoration(labelText:'School name')),FilledButton(onPressed:()async{if(c.text.trim().isEmpty)return;await AppDb.instance.db.insert('schools',{'name':c.text.trim()});c.clear();setState((){});},child:const Text('Add School')),FutureBuilder<List<Map<String,dynamic>>>(future:AppDb.instance.schools(),builder:(c,s)=>Column(children:(s.data??[]).map((x)=>ListTile(title:Text(x['name']))).toList()))]);}
class StandardMaster extends StatefulWidget{const StandardMaster({super.key});@override State<StandardMaster> createState()=>_StandardMasterState();}
class _StandardMasterState extends State<StandardMaster>{final name=TextEditingController(),year=TextEditingController(text:'2026-27');int? sid;List<Map<String,dynamic>> schools=[];@override void initState(){super.initState();AppDb.instance.schools().then((x){schools=x;if(x.isNotEmpty)sid=x.first['id'];setState((){});});}@override Widget build(BuildContext context)=>Column(children:[DropdownButtonFormField<int>(value:sid,items:schools.map((x)=>DropdownMenuItem(value:x['id'] as int,child:Text(x['name']))).toList(),onChanged:(v)=>setState(()=>sid=v),decoration:const InputDecoration(labelText:'School')),TextField(controller:year,decoration:const InputDecoration(labelText:'Academic Year')),TextField(controller:name,decoration:const InputDecoration(labelText:'Standard')),FilledButton(onPressed:()async{if(sid==null||name.text.isEmpty)return;await AppDb.instance.db.insert('standards',{'schoolId':sid,'year':year.text,'name':name.text});name.clear();setState((){});},child:const Text('Add Standard'))]);}
class ItemMaster extends StatelessWidget{const ItemMaster({super.key});@override Widget build(BuildContext context)=>const Padding(padding:EdgeInsets.all(8),child:Text('For the first version, the supplied 4th Standard book/stationery master is preloaded. A full editable item-master screen can be expanded here for additional schools and standards.'))}
