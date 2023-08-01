import 'package:connection_notifier/connection_notifier.dart';
import 'package:flutter/material.dart';
import 'package:nav/SemInternetPage.dart';
import 'package:nav/web_view_page.dart';

main() async {
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.transparent,
        ),
        useMaterial3: true,
      ),
      home: const ConnectionNotifierToggler(
        connected: WebViewPage(),
        disconnected: SemInternetpage(),
      ),
    );
  }
}
