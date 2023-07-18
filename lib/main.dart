import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:nav/web_view_page.dart';
Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true,
  );
  
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NAV',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple,),
        useMaterial3: true,
      ),
      home: const WebViewPage(),
    );
  }
}