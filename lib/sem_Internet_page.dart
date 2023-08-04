// ignore_for_file: file_names
import 'package:flutter/material.dart';

class SemInternerPage extends StatelessWidget {
  const SemInternerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Sem acesso a internet!',
          style: TextStyle(
            fontSize: 26,
          ),
        ),
      ),
    );
  }
}
