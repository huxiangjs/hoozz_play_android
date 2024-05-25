///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hoozz_play/core/device_binding.dart';
import 'package:hoozz_play/core/parameter_stateful.dart';
import 'package:hoozz_play/themes/theme.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'package:hoozz_play/core/device_storage.dart';
import 'dart:developer' as developer;

const String _logName = 'Voice LED';

// LED ctrl page
class VoiceLEDDeviceCtrlPageState extends ParameterStatefulState {
  final List<int> _colorIndex = [0, 1, 2];
  final List<Color> _colorShow = [Colors.redAccent, Colors.green, Colors.blue];
  final List<double> _colorValue = [0.0, 0.0, 0.0];
  late SimpleCtrlHandle _simpleCtrlDiscoverHandle;
  bool _allowNotifierUpdate = true;
  late DiscoverDeviceInfo _discoverDeviceInfo;
  late String _storageName;

  @override
  void initState() {
    super.initState();
    _discoverDeviceInfo = parameter[0] as DiscoverDeviceInfo;
    _storageName = parameter[1] as String;
    _simpleCtrlDiscoverHandle = SimpleCtrlHandle(_discoverDeviceInfo);
    _simpleCtrlDiscoverHandle.stateNotifier.addListener(() {});
    _simpleCtrlDiscoverHandle.initHandle();

    SimpleCtrlDataNotifier simpleCtrlDataNotifier =
        _simpleCtrlDiscoverHandle.notifyNotifier;

    simpleCtrlDataNotifier.addListener(() {
      Uint8List data = simpleCtrlDataNotifier.dataQueue.removeFirst();
      developer.log('Update color: $data', name: _logName);
      if (data.length == 3 && _allowNotifierUpdate) {
        _colorValue[0] = data[2].toDouble();
        _colorValue[1] = data[1].toDouble();
        _colorValue[2] = data[0].toDouble();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _simpleCtrlDiscoverHandle.destroyHandle();
    super.dispose();
  }

  void _remoteUpdateColor() {
    ByteData byteData = ByteData(3);
    byteData.setUint8(0, _colorValue[2].toInt());
    byteData.setUint8(1, _colorValue[1].toInt());
    byteData.setUint8(2, _colorValue[0].toInt());

    Uint8List data = byteData.buffer.asUint8List();
    _simpleCtrlDiscoverHandle.request(data);

    int rgb = _colorValue[0].toInt() << 16 |
        _colorValue[1].toInt() << 8 |
        _colorValue[2].toInt();
    developer.log('changed rgb: 0x${rgb.toRadixString(16)}', name: toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_discoverDeviceInfo.name),
        actions: [
          // Config device button
          IconButton(
            icon: const Icon(Icons.perm_data_setting_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    ParameterStatefulState page = DeviceBindingList
                        .binding[_discoverDeviceInfo.classId]!
                        .configPage();
                    // Set parameter
                    page.parameter = [_discoverDeviceInfo, _storageName];
                    return ParameterStatefulWidget(page);
                  },
                ),
              ).then((value) {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ColorPicker(
            paletteType: PaletteType.hueWheel,
            labelTypes: const [ColorLabelType.hsv, ColorLabelType.rgb],
            enableAlpha: false,
            onColorChanged: (Color value) {
              setState(() {
                _colorValue[0] = value.red.toDouble();
                _colorValue[1] = value.green.toDouble();
                _colorValue[2] = value.blue.toDouble();
              });
            },
            pickerColor: Color.fromARGB(0xFF, _colorValue[0].toInt(),
                _colorValue[1].toInt(), _colorValue[2].toInt()),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _colorIndex.map((int index) {
              return SizedBox(
                height: 80,
                child: Slider(
                  value: _colorValue[index],
                  onChanged: (data) {
                    setState(() {
                      _colorValue[index] = data;
                    });
                    _remoteUpdateColor();
                  },
                  onChangeStart: (data) {
                    _allowNotifierUpdate = false;
                  },
                  onChangeEnd: (data) {
                    _allowNotifierUpdate = true;
                  },
                  min: 0.0,
                  max: 0xff,
                  divisions: 0xff,
                  label: '${_colorValue[index]}',
                  activeColor: _colorShow[index],
                ),
              );
            }).toList(),
          ),
          const Divider(),
        ],
      ),
    );
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
class VoiceLEDConfigDevicePageState extends ParameterStatefulState {
  DeviceInfo _deviceInfo = DeviceInfo();
  late DiscoverDeviceInfo _discoverDeviceInfo;
  late String _storageName;

  Future<void> _deviceInfoLoad() async {
    DeviceStorage storage = DeviceStorage(_storageName);
    await storage.load();
    if (storage.deviceList[_deviceInfo.id] != null) {
      _deviceInfo = storage.deviceList[_deviceInfo.id]!;
    }
  }

  Future<void> _deviceInfoSave() async {
    DeviceStorage storage = DeviceStorage(_storageName);
    await storage.load();
    storage.deviceList[_deviceInfo.id] = _deviceInfo;
    await storage.save();
  }

  @override
  void initState() {
    super.initState();

    _discoverDeviceInfo = parameter[0] as DiscoverDeviceInfo;
    _storageName = parameter[1] as String;
    _deviceInfo.nickName = _discoverDeviceInfo.name;
    _deviceInfo.id = _discoverDeviceInfo.id;
    _deviceInfoLoad().then((value) => setState(() {}));
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
                      DeviceBindingList.binding[_discoverDeviceInfo.classId] ==
                              null
                          ? 'Unknown'
                          : DeviceBindingList
                              .binding[_discoverDeviceInfo.classId]!.describe,
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
