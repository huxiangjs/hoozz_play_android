///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HoozzPlayAuthorPage extends StatefulWidget {
  const HoozzPlayAuthorPage({super.key});

  final String title = 'Author';

  @override
  State<HoozzPlayAuthorPage> createState() => _HoozzPlayAuthorPageState();
}

class _HoozzPlayAuthorPageState extends State<HoozzPlayAuthorPage> {
  final String _name = 'Hoozz';
  final String _email = 'huxiangjs@foxmail.com';
  final String _bilibiliUrl = 'https://space.bilibili.com/425650287';

  @override
  void initState() {
    super.initState();
  }

  void _launchBilibili() async {
    Uri uri = Uri.parse(_bilibiliUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.fromLTRB(4, 60, 4, 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Image.asset(
                  'images/author_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'E-Mail: $_email',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      _launchBilibili();
                    },
                    child: Text(
                      _bilibiliUrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
