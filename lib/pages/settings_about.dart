///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';

class HoozzPlayAboutPage extends StatefulWidget {
  const HoozzPlayAboutPage({super.key});

  final String title = 'About';

  @override
  State<HoozzPlayAboutPage> createState() => _HoozzPlayAboutPageState();
}

class _HoozzPlayAboutPageState extends State<HoozzPlayAboutPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Text(widget.title),
      ),
      body: const Text(""),
    );
  }
}
