import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(GullyScoreApp());
}

class GullyScoreApp extends StatelessWidget {
  const GullyScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gully Score',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
