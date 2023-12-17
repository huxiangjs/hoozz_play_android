///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';

class HoozzPlayLicensePage extends StatefulWidget {
  const HoozzPlayLicensePage({super.key});

  final String title = 'License';

  @override
  State<HoozzPlayLicensePage> createState() => _HoozzPlayLicensePageState();
}

class _HoozzPlayLicensePageState extends State<HoozzPlayLicensePage> {
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
