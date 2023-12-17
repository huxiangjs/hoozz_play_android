///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HoozzPlayAboutPage extends StatefulWidget {
  const HoozzPlayAboutPage({super.key});

  final String title = 'About';

  @override
  State<HoozzPlayAboutPage> createState() => _HoozzPlayAboutPageState();
}

class _HoozzPlayAboutPageState extends State<HoozzPlayAboutPage> {
  String _appName = '';
  String _version = '';
  final String _description =
      'Hoozz Play is a personal open source project where all the fun things will be shared';
  final String _githubUrl = 'https://github.com/huxiangjs/hoozz_play.git';

  Future<void> _getVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appName = packageInfo.appName;
      _version = packageInfo.version;
    });
  }

  @override
  void initState() {
    super.initState();
    _getVersion();
  }

  void _launchGitHub() async {
    Uri uri = Uri.parse(_githubUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.fromLTRB(4, 60, 4, 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'images/app_icon.png',
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 10),
            Text(
              _appName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Version: $_version',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _description,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _launchGitHub();
              },
              child: Text(
                _githubUrl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
