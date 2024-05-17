///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/core/class_id.dart';
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

class _DeviceInofInputDecoration extends InputDecoration {
  static final OutlineInputBorder disabledOutlineInputBorder =
      OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: const BorderSide(color: Colors.grey, width: 1.0),
    gapPadding: 6,
  );

  static final OutlineInputBorder enabledOutlineInputBorder =
      OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: const BorderSide(color: mainFillColor, width: 2.0),
    gapPadding: 6,
  );

  _DeviceInofInputDecoration(labelText, hintText)
      : super(
          labelText: labelText,
          hintText: hintText,
          labelStyle: const TextStyle(fontSize: 20, fontFamily: mainFontFamily),
          hintStyle: const TextStyle(fontSize: 20, fontFamily: subFontFamily),
          // floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 15,
          ),
          border: disabledOutlineInputBorder,
          enabledBorder: disabledOutlineInputBorder,
          focusedBorder: enabledOutlineInputBorder,
          disabledBorder: disabledOutlineInputBorder,
        );
}

// Config device page
class VoiceLEDConfigDevicePage extends ClassBindingWidget {
  String _nickName = '';
  String _accessKey = '';

  @override
  Widget build(BuildContext context) {
    DiscoverDeviceInfo info = parameter as DiscoverDeviceInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure device"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 24, 10, 2),
              child: Row(
                children: [
                  const Text(' NAME: ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      info.name,
                      style: const TextStyle(
                          fontSize: 18, fontFamily: subFontFamily),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Row(
                children: [
                  const Text('CLASS: ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      ClassList.classIdList[info.classId] == null
                          ? 'Unknown'
                          : ClassList.classIdList[info.classId]!.describe,
                      style: const TextStyle(
                          fontSize: 18, fontFamily: subFontFamily),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Row(
                children: [
                  const Text('    ID: ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      info.id,
                      style: const TextStyle(
                          fontSize: 18, fontFamily: subFontFamily),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Row(
                children: [
                  const Text('    IP: ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      '${info.ip} : ${info.port}',
                      style: const TextStyle(
                          fontSize: 18, fontFamily: subFontFamily),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                onChanged: (value) =>
                    _nickName = value.replaceAll('\r\n', '\n'),
                style: const TextStyle(fontSize: 20, fontFamily: subFontFamily),
                // maxLines: 2,
                decoration: _DeviceInofInputDecoration(
                  'Device nick name',
                  'Set a nick name for your device',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                onChanged: (value) =>
                    _accessKey = value.replaceAll('\r\n', '\n'),
                style: const TextStyle(fontSize: 20, fontFamily: subFontFamily),
                // maxLines: 2,
                keyboardType: TextInputType.multiline,
                decoration: _DeviceInofInputDecoration(
                  'Access key',
                  'Set access key for your device',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  developer.log('Nick name: $_nickName', name: _logName);
                  developer.log('Access key: $_accessKey', name: _logName);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return WillPopScope(
                        onWillPop: () async => false, // Disable return key
                        child: AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const <Widget>[
                              CircularProgressIndicator(),
                              Padding(
                                padding: EdgeInsets.only(top: 26.0),
                                child: Text("Verifying device..."),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  Future.delayed(const Duration(seconds: 3, milliseconds: 0))
                      .then((value) {
                    Navigator.pop(context);
                  });
                },
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 20, fontFamily: subFontFamily),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
