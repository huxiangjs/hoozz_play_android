///
/// Created on 2023/09/03
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'themes/theme.dart';
import 'pages/home.dart';
import 'pages/settings.dart';
import 'pages/tools.dart';
import 'pages/settings_about.dart';
import 'pages/settings_author.dart';
import 'pages/settings_license.dart';
import 'pages/mlx90640.dart';
import "pages/remote_switch.dart";
import "pages/tools_esptouch.dart";
import "pages/voice_led.dart";

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
        '/tools': (context) => const HoozzPlayToolsPage(),
        '/tools_esptouch': (context) => const EspTouchPage(),
        '/about': (context) => const HoozzPlayAboutPage(),
        '/author': (context) => const HoozzPlayAuthorPage(),
        '/license': (context) => const HoozzPlayLicensePage(),
        '/mlx90640': (context) => const MLX90640HomePage(),
        "/remote_sw": (context) => const RemoteSwitchHomePage(),
        "/voice_led": (context) => const VoiceLEDHomePage(),
      },
    );
  }
}
