///
/// Created on 2025/07/120
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hoozz_play/core/simple_snackbar.dart';
import "package:hoozz_play/themes/theme.dart";
import 'package:hoozz_play/core/vpn_ctrl.dart';

class HoozzPlayVPNPage extends StatefulWidget {
  const HoozzPlayVPNPage({super.key});

  final String title = 'VPN';

  @override
  State<HoozzPlayVPNPage> createState() => _HoozzPlayVPNPageState();
}

class _HoozzPlayVPNPageState extends State<HoozzPlayVPNPage> {
  late MaterialColor _shadowColor;
  late bool _online;
  late bool _cfgReady;
  late String _connectedOn;
  late String _duration;
  late String _byteIn;
  late String _byteOut;
  late String _packetsIn;
  late String _packetsOut;
  late String _remoteProtocol;
  late String _remoteAddress;
  late String _remotePort;

  static MaterialColor _switchActiveTrackColor = Colors.purple;

  @override
  void initState() {
    VPNCtrl.settingInit(
      () {
        void parse() {
          _online = VPNCtrl.connected;
          if (_online) {
            _shadowColor = Colors.green;
            _switchActiveTrackColor = Colors.green;
          } else {
            _shadowColor = Colors.red;
            _switchActiveTrackColor = Colors.purple;
            _connectedOn = '';
            _duration = '--:--:--';
            _byteIn = 'Rx: - bytes';
            _byteOut = 'Tx: - bytes';
            _packetsIn = 'Rx: - packets';
            _packetsOut = 'Tx: - packets';
          }
          _cfgReady = VPNCtrl.configValid;
          if (_cfgReady) {
            _remoteProtocol = VPNCtrl.remoteProtocol;
            _remoteAddress = VPNCtrl.remoteAddress;
            _remotePort = VPNCtrl.remotePort;
          }
        }

        if (mounted) {
          setState(parse);
        } else {
          parse();
        }
      },
      (Map<String, dynamic> value) {
        if (mounted && _online) {
          setState(() {
            _connectedOn = value['connected_on'] == null
                ? ''
                : 'connected on ${value['connected_on'].toString()}';
            _duration = value['duration'];
            _byteIn = 'Rx: ${value['byte_in']} bytes';
            _byteOut = 'Tx: ${value['byte_out']} bytes';
            _packetsIn = 'Rx: ${value['packets_in']} packets';
            _packetsOut = 'Tx: ${value['packets_out']} packets';
          });
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    VPNCtrl.settingDeinit();
    super.dispose();
  }

  Widget _generateTableCell(String value, double fontSize) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(1, 12, 1, 12),
        child: Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: subFontFamily,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            Card(
              shadowColor: _shadowColor,
              // margin: EdgeInsetsGeometry.all(10),
              elevation: 8.0,
              surfaceTintColor: Colors.grey,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: EdgeInsets.fromLTRB(6, 24, 6, 20),
                child: Column(
                  children: [
                    Table(
                      columnWidths: {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(1),
                      },
                      // border: TableBorder.all(),
                      children: [
                        TableRow(
                          children: [
                            _generateTableCell(
                              _online ? 'Online' : 'Offline',
                              24,
                            ),
                            _generateTableCell(_duration, 18),
                          ],
                        ),
                        TableRow(
                          children: [
                            _generateTableCell(_byteIn, 14),
                            _generateTableCell(_byteOut, 14),
                          ],
                        ),
                        TableRow(
                          children: [
                            _generateTableCell(_packetsIn, 12),
                            _generateTableCell(_packetsOut, 12),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      _connectedOn,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: subFontFamily,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: _cfgReady
                  ? Card(
                      elevation: 4.0,
                      surfaceTintColor: Colors.grey,
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.fromLTRB(14, 16, 14, 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(0, 0, 0, 4),
                                  child: Text(
                                    _remoteAddress,
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: subFontFamily,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'port:$_remotePort  |  protocol:$_remoteProtocol',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontFamily: subFontFamily,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    activeTrackColor: _switchActiveTrackColor,
                                    value: _online,
                                    onChanged: (value) {
                                      if (_online) {
                                        VPNCtrl.disconnect();
                                      } else {
                                        VPNCtrl.connect().then((granted) {
                                          if (granted == false) {
                                            setState(() => _online = false);
                                          }
                                        });
                                      }
                                      setState(() {
                                        _online = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Warning'),
                                    content: const Text(
                                      'Are you sure you want to delete this config?',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Yes'),
                                        onPressed: () {
                                          VPNCtrl.clearConfig();
                                          VPNCtrl.removeConfig();
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text(
                                          'No',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            color: Colors.deepOrangeAccent,
                            icon: Icon(Icons.delete_rounded, size: 24),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        TextButton(
                          onPressed: () async {
                            final ClipboardData? data = await Clipboard.getData(
                              Clipboard.kTextPlain,
                            );

                            if (!mounted) return;

                            if (data != null && data.text != null) {
                              if (VPNCtrl.setConfig(data.text!)) {
                                VPNCtrl.saveConfig();
                                SimpleSnackBar.show(
                                  // ignore: use_build_context_synchronously
                                  context,
                                  'Added successfully',
                                  Colors.green,
                                );
                              } else {
                                SimpleSnackBar.show(
                                  // ignore: use_build_context_synchronously
                                  context,
                                  'Content format error',
                                  Colors.red,
                                );
                              }
                            } else {
                              SimpleSnackBar.show(
                                // ignore: use_build_context_synchronously
                                context,
                                'Clipboard is empty',
                                Colors.red,
                              );
                            }
                          },
                          child: Text(
                            'Add config from clipboard ...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontFamily: subFontFamily,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              FilePickerResult? result = await FilePicker
                                  .platform
                                  .pickFiles();

                              if (!mounted) return;

                              if (result != null) {
                                PlatformFile file = result.files.first;
                                File f = File(file.path!);
                                String config = f.readAsStringSync(
                                  encoding: utf8,
                                );
                                if (VPNCtrl.setConfig(config)) {
                                  VPNCtrl.saveConfig();
                                  SimpleSnackBar.show(
                                    // ignore: use_build_context_synchronously
                                    context,
                                    'Added successfully',
                                    Colors.green,
                                  );
                                } else {
                                  SimpleSnackBar.show(
                                    // ignore: use_build_context_synchronously
                                    context,
                                    'Content format error',
                                    Colors.red,
                                  );
                                }
                              } else {
                                SimpleSnackBar.show(
                                  // ignore: use_build_context_synchronously
                                  context,
                                  'Operation canceled',
                                  Colors.deepOrange,
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              SimpleSnackBar.show(
                                // ignore: use_build_context_synchronously
                                context,
                                'Error: $e',
                                Colors.red,
                              );
                            }
                          },
                          child: Text(
                            'Add config from file ...',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontFamily: subFontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
