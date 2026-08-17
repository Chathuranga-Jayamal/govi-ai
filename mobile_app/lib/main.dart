import 'package:flutter/material.dart';

void main() {
  runApp(const GoviAiApp());
}

class GoviAiApp extends StatelessWidget {
  const GoviAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Govi-AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text(
            'Govi-AI ✅ Setup working',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
