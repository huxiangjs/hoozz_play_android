///
/// Created on 2024/08/04
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoozz_play/core/device_binding.dart';
import 'package:hoozz_play/core/device_storage.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'package:hoozz_play/themes/theme.dart';
import 'dart:developer' as developer;

const String _logName = 'Device Configure';

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

  _DeviceInofInputDecoration(labelText, hintText, [Widget? suffixIcon])
      : super(
          labelText: labelText,
          hintText: hintText,
          suffixIcon: suffixIcon,
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

class DeviceConfig extends StatelessWidget {
  final bool allowSetPasswd;
  final DiscoverDeviceInfo discoverDeviceInfo;
  final DeviceInfo deviceInfo;
  final Widget child;
  final Function(DeviceInfo deviceInfo) onSavePressed;

  const DeviceConfig(
      {super.key,
      required this.allowSetPasswd,
      required this.discoverDeviceInfo,
      required this.deviceInfo,
      this.child = const Text(''),
      required this.onSavePressed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure device"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
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
                          discoverDeviceInfo.name,
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
                          DeviceBindingList
                                      .binding[discoverDeviceInfo.classId] ==
                                  null
                              ? 'Unknown'
                              : DeviceBindingList
                                  .binding[discoverDeviceInfo.classId]!
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
                          discoverDeviceInfo.id,
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
                          '${discoverDeviceInfo.ip} : ${discoverDeviceInfo.port}',
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
                    controller:
                        TextEditingController(text: deviceInfo.nickName),
                    onChanged: (value) =>
                        deviceInfo.nickName = value.replaceAll('\r\n', '\n'),
                    style: const TextStyle(
                        fontSize: 20, fontFamily: subFontFamily),
                    // maxLines: 2,
                    decoration: _DeviceInofInputDecoration(
                      'Device nick name',
                      'Set a nick name for your device',
                    ),
                  ),
                ),
                Visibility(
                  visible: allowSetPasswd,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      inputFormatters: [
                        // FilteringTextInputFormatter.allow(RegExp("[a-zA-Z.,!?]")),
                        FilteringTextInputFormatter.allow(RegExp('[ -~]')),
                      ],
                      controller:
                          TextEditingController(text: deviceInfo.accessKey),
                      onChanged: (value) =>
                          deviceInfo.accessKey = value.replaceAll('\r\n', '\n'),
                      style: const TextStyle(
                          fontSize: 20, fontFamily: subFontFamily),
                      maxLength: SimpleCtrlHandle.accessKeyLength,
                      // maxLines: 2,
                      keyboardType: TextInputType.multiline,
                      decoration: _DeviceInofInputDecoration(
                          'Access key',
                          'Set access key for your device',
                          IconButton(
                              onPressed: () {
                                final Random random = Random();
                                final int start = ' '.codeUnits[0];
                                final int stop = '~'.codeUnits[0];
                                final String result = String.fromCharCodes(
                                    List.generate(
                                        SimpleCtrlHandle.accessKeyLength,
                                        (index) =>
                                            random.nextInt(stop - start + 1) +
                                            start));
                                setState(() {
                                  deviceInfo.accessKey = result;
                                });
                              },
                              icon: const Icon(Icons.refresh))),
                    ),
                  ),
                ),
                child,
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      developer.log('Nick name: ${deviceInfo.nickName}',
                          name: _logName);
                      developer.log('Access key: ${deviceInfo.accessKey}',
                          name: _logName);
                      onSavePressed(deviceInfo);
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 20, fontFamily: subFontFamily),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
