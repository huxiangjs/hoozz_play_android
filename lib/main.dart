import 'package:flutter/material.dart';
import 'themes/theme.dart';
import 'pages/home.dart';
import 'pages/mlx90640.dart';

void main() {
  runApp(const HoozzPlayApp());
}

class HoozzPlayApp extends StatelessWidget {
  const HoozzPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hoozz Play',
      theme: appTheme(),
      routes: {
        '/': (context) => const HoozzPlayHomePage(),
        '/home': (context) => const HoozzPlayHomePage(),
        '/mlx90640': (context) => const MLX90640HomePage(),
      },
    );
  }
}
