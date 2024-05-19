///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:collection';
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

class _VoiceLEDDeviceInfo {
  String nickName = '';
  String id = '';
  String accessKey = '';
}

class _VoiceLEDDeviceInfoStorage {
  final String _storageName = 'Voice LED';
  final LinkedHashMap<String, _VoiceLEDDeviceInfo> deviceList =
      LinkedHashMap<String, _VoiceLEDDeviceInfo>();

  Future<void> save() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    int count = 0;
    for (_VoiceLEDDeviceInfo item in deviceList.values) {
      sharedPreferences.setStringList('$_storageName: Device$count', [
        item.nickName,
        item.id,
        item.accessKey,
      ]);
      count++;
    }

    sharedPreferences.setInt('$_storageName: Device Count', count);
    developer.log('$_storageName: Device Count: $count', name: _logName);
  }

  Future<void> load() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    int? count = sharedPreferences.getInt('$_storageName: Device Count');
    count ??= 0;
    developer.log('$_storageName: Device Count: $count', name: _logName);
    for (int i = 0; i < count; i++) {
      List<String>? deviceInfo =
          sharedPreferences.getStringList('$_storageName: Device$i');
      deviceInfo ??= [];
      _VoiceLEDDeviceInfo info = _VoiceLEDDeviceInfo();
      info.nickName = deviceInfo[0];
      info.id = deviceInfo[1];
      info.accessKey = deviceInfo[2];
      deviceList[info.id] = info;
    }
  }
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
class VoiceLEDConfigDevicePageState extends ClassBindingWidgetState {
  _VoiceLEDDeviceInfo _deviceInfo = _VoiceLEDDeviceInfo();
  late DiscoverDeviceInfo _discoverDeviceInfo;

  Future<void> _deviceInfoLoad() async {
    _VoiceLEDDeviceInfoStorage storage = _VoiceLEDDeviceInfoStorage();
    await storage.load();
    if (storage.deviceList[_deviceInfo.id] != null) {
      _deviceInfo = storage.deviceList[_deviceInfo.id]!;
    }
  }

  Future<void> _deviceInfoSave() async {
    _VoiceLEDDeviceInfoStorage storage = _VoiceLEDDeviceInfoStorage();
    await storage.load();
    storage.deviceList[_deviceInfo.id] = _deviceInfo;
    await storage.save();
  }

  @override
  void initState() {
    super.initState();

    _discoverDeviceInfo = parameter[0] as DiscoverDeviceInfo;
    _deviceInfo.nickName = _discoverDeviceInfo.name;
    _deviceInfoLoad().then((value) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      _discoverDeviceInfo.name,
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
                      ClassList.classIdList[_discoverDeviceInfo.classId] == null
                          ? 'Unknown'
                          : ClassList.classIdList[_discoverDeviceInfo.classId]!
                              .describe,
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
                      _discoverDeviceInfo.id,
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
                      '${_discoverDeviceInfo.ip} : ${_discoverDeviceInfo.port}',
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
                controller: TextEditingController(text: _deviceInfo.nickName),
                onChanged: (value) =>
                    _deviceInfo.nickName = value.replaceAll('\r\n', '\n'),
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
                controller: TextEditingController(text: _deviceInfo.accessKey),
                onChanged: (value) =>
                    _deviceInfo.accessKey = value.replaceAll('\r\n', '\n'),
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
                  developer.log('Nick name: ${_deviceInfo.nickName}',
                      name: _logName);
                  developer.log('Access key: ${_deviceInfo.accessKey}',
                      name: _logName);

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
                    _deviceInfoSave();
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
