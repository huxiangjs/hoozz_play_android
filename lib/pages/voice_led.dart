///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/themes/theme.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

const String _logName = 'Voice LED';

class VoiceLEDHomePage extends StatefulWidget {
  const VoiceLEDHomePage({super.key});

  final String title = 'Voice LED';

  @override
  State<VoiceLEDHomePage> createState() => _VoiceLEDHomePageState();
}

// Home page
class _VoiceLEDHomePageState extends State<VoiceLEDHomePage> {
  final SimpleCtrl _simpleCtrl = SimpleCtrl();

  @override
  void initState() {
    super.initState();
    _simpleCtrl.initDiscover();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Add device button
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_add),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _simpleCtrl.destroyDiscovery();
    super.dispose();
  }
}
