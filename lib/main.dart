import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(WeatherFitApp());
}

class WeatherFitApp extends StatelessWidget {
  const WeatherFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}