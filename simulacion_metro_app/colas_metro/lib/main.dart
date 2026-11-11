import 'package:flutter/material.dart';
import 'input_screen.dart';
import 'theme.dart';

void main() => runApp(const ColasMetroApp());

class ColasMetroApp extends StatelessWidget {
  const ColasMetroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colas Metro',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const InputScreen(),
    );
  }
}
