///
/// Created on 2023/09/03
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'themes/theme.dart';
import 'pages/home.dart';
import 'pages/settings.dart';
import 'pages/settings_about.dart';
import 'pages/settings_author.dart';
import 'pages/settings_license.dart';
import 'pages/mlx90640.dart';
import "pages/remote_switch.dart";

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
        '/settings': (context) => const HoozzPlaySettingsPage(),
        '/about': (context) => const HoozzPlayAboutPage(),
        '/author': (context) => const HoozzPlayAuthorPage(),
        '/license': (context) => const HoozzPlayLicensePage(),
        '/mlx90640': (context) => const MLX90640HomePage(),
        "/remote_sw": (context) => const RemoteSwitchHomePage(),
      },
    );
  }
}
