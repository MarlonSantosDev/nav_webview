import 'package:flutter/material.dart';

class SemInternetpage extends StatefulWidget {
  const SemInternetpage({super.key});

  @override
  State<SemInternetpage> createState() => _SemInternetpageState();
}

class _SemInternetpageState extends State<SemInternetpage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Sem acesso a internet!',
          style: TextStyle(
            fontSize: 25,
          ),
        ),
      ),
    );
  }
}
