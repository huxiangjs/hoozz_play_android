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
import 'pages/settings_vpn.dart';
import 'pages/mlx90640.dart';
import "pages/remote_switch.dart";
import "pages/tools_esptouch.dart";
import "pages/device_list.dart";
import "pages/tools_discover.dart";
import 'core/device_binding.dart';
import 'core/github/github_download.dart';

void main() {
  // Initialize the binding so platform channels (the download directory)
  // can be used before the app is built
  WidgetsFlutterBinding.ensureInitialized();

  // Remove files left over from previous GitHub downloads (e.g. the APK
  // downloaded for the last app update) so they don't accumulate.
  // Deliberately not awaited: runs in the background and must not delay
  // the app startup (all errors are handled inside)
  GitHubDownload.cleanDownloadDir();

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
        '/tools_discover': (context) => const DiscoverPage(),
        '/about': (context) => const HoozzPlayAboutPage(),
        '/author': (context) => const HoozzPlayAuthorPage(),
        '/license': (context) => const HoozzPlayLicensePage(),
        '/vpn': (context) => const HoozzPlayVPNPage(),
        '/mlx90640': (context) => const MLX90640HomePage(),
        '/remote_sw': (context) => const RemoteSwitchHomePage(),
        '/voice_led': (context) =>
            DeviceListHomePage(DeviceBindingList.idVoiceLed),
        '/button_led': (context) =>
            DeviceListHomePage(DeviceBindingList.idButtonLed),
        '/smart_ir': (context) =>
            DeviceListHomePage(DeviceBindingList.idSmartIr),
        '/sensor': (context) => DeviceListHomePage(DeviceBindingList.idSensor),
        '/pwd_sync': (context) =>
            DeviceListHomePage(DeviceBindingList.idPwdSync),
        '/switch': (context) => DeviceListHomePage(DeviceBindingList.idSwitch),
      },
    );
  }
}
