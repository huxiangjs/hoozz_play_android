///
/// Created on 2025/7/26
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoozz_play/core/device_binding.dart';
import 'package:hoozz_play/core/device_config.dart';
import 'package:hoozz_play/core/parameter_stateful.dart';
import 'package:hoozz_play/core/simple_showdialog.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'package:hoozz_play/core/device_storage.dart';
import 'package:hoozz_play/core/simple_snackbar.dart';
import 'dart:developer' as developer;

import 'package:hoozz_play/themes/theme.dart';

const String _logName = 'Smart IR';

// IR ctrl page
class SmartIRDeviceCtrlPageState extends ParameterStatefulState {
  late SimpleCtrlHandle _simpleCtrlHandle;
  late DiscoverDeviceInfo _discoverDeviceInfo;
  late DeviceInfo _deviceInfo;
  late String _storageName;
  late Timer _timer;

  final int _irCmdGetCount = 0x00;
  final int _irCmdGetItem = 0x01;
  final int _irCmdTxTest = 0x02;
  final int _irCmdSave = 0x03;
  final int _irCmdRemove = 0x04;
  final int _irCmdTxSend = 0x05;

  final int _irNotifyTypeRx = 0x00;
  final int _irNotifyTypeKey = 0x01;
  final int _irNotifyTypeTx = 0x02;

  final int _irResultOk = 0x00;
  final int _irResultFail = 0x01;
  final int _irResultDone = 0x02;

  int _irRxCount = 0;
  int _irRxLength = 0;
  bool _irRxDataVaild = false;
  final TextEditingController _irKeyName = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  StateSetter? _dialogSetState;
  Map<String, int> _irKeyMap = {};
  bool _getKeyListRunning = false;

  bool _isFirstRender = true;

  void _setTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 500), (Timer timer) {
      bool build = false;
      for (String keyName in _irKeyMap.keys) {
        if (_irKeyMap[keyName] != 0) {
          _irKeyMap[keyName] = _irKeyMap[keyName]! - 1;
          build = true;
        }
      }
      if (build) {
        if (mounted) {
          setState(() {});
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _keyIconFlash(String keyName) {
    int? current = _irKeyMap[keyName];
    if (current != null && mounted) {
      setState(() {
        _irKeyMap[keyName] = current + 1;
      });
      if (!_timer.isActive) _setTimer();
    }
  }

  Future<void> _getKeyList(int keyCount) async {
    if (_getKeyListRunning) return;
    _getKeyListRunning = true;
    ByteData byteData = ByteData(5);
    byteData.setUint8(0, _irCmdGetItem);
    Map<String, int> newMap = {};
    bool firstLoad = _irKeyMap.isEmpty;
    // Read the information of each key
    for (int index = 0; index < keyCount; index++) {
      byteData.setUint32(1, index, Endian.little);
      Uint8List data = byteData.buffer.asUint8List();
      Uint8List? value = await _simpleCtrlHandle.request(data, true);
      // developer.log('Get return: $value', name: _logName);
      if (value != null && value.length > 2 && value[0] == _irCmdGetItem) {
        if (value[1] == _irResultOk) {
          String keyName = utf8.decode(value.sublist(2));
          developer.log('[$index] Key name: $keyName', name: _logName);
          if (firstLoad) {
            if (!mounted) return;
            setState(() {
              _irKeyMap[keyName] = 0;
            });
          } else {
            newMap[keyName] = 0;
          }
        } else if (value[1] == _irResultDone) {
          developer.log('Data loading completed in advance', name: _logName);
          break;
        }
      }
    }
    if (!firstLoad) {
      if (!mounted) return;
      setState(() {
        _irKeyMap = newMap;
      });
    }
    _getKeyListRunning = false;
  }

  void _stateNotifier() {
    // Connected
    if (_simpleCtrlHandle.stateNotifier.value ==
        SimpleCtrlHandle.stateConnected) {
      SimpleCtrlDataNotifier simpleCtrlDataNotifier =
          _simpleCtrlHandle.notifyNotifier;

      // Listen device notify
      simpleCtrlDataNotifier.addListener(() {
        Uint8List data = simpleCtrlDataNotifier.getData();
        int type = data[0];
        Uint8List playload = data.sublist(1);
        ByteData byteData = playload.buffer.asByteData();

        if (type == _irNotifyTypeRx) {
          int count = byteData.getUint32(0, Endian.little);
          int length = byteData.getUint16(4, Endian.little);

          // Update dialog
          try {
            _dialogSetState!(() {
              _irRxCount = count;
              _irRxLength = length;
              _irRxDataVaild = true;
              // random key name
              final Random random = Random();
              final int start = 'a'.codeUnits[0];
              final int stop = 'z'.codeUnits[0];
              final String result = String.fromCharCodes(
                List.generate(
                  8,
                  (index) => random.nextInt(stop - start + 1) + start,
                ),
              );
              _irKeyName.text = 'key_${result}_${count}_$length';
            });
            _focusNode.requestFocus();
          } catch (e) {
            developer.log('Dialog setState failed', name: _logName);
          }
          developer.log('IR data count: $count, len: $length', name: _logName);
        } else if (type == _irNotifyTypeKey) {
          int keyCount = byteData.getUint32(0, Endian.little);
          developer.log('IR key changed, key count: $keyCount', name: _logName);
          _getKeyList(keyCount);
        } else if (type == _irNotifyTypeTx) {
          String keyName = utf8.decode(playload);
          developer.log('IR send done, key name: $keyName', name: _logName);
          _keyIconFlash(keyName);
        }
      });

      // Read remote device key count (Once)
      ByteData byteData = ByteData(1);
      byteData.setUint8(0, _irCmdGetCount);
      Uint8List data = byteData.buffer.asUint8List();
      _simpleCtrlHandle.request(data, true).then((Uint8List? value) {
        // developer.log('Get return: $value', name: _logName);
        Navigator.pop(context);
        if (value != null &&
            value.length == 6 &&
            value[0] == _irCmdGetCount &&
            value[1] == _irResultOk) {
          ByteData byteData = ByteData.view(value.buffer, 2, 4);
          int keyCount = byteData.getUint32(0, Endian.little);
          developer.log('Key count: $keyCount', name: _logName);
          // Read the information of each key
          _getKeyList(keyCount);
        } else {
          Navigator.popUntil(
            context,
            (route) => route.settings.name == '/smart_ir',
          );
          SimpleSnackBar.show(context, 'Abnormal device data', Colors.red);
        }
      });

      // Disconnected or Failed
    } else if (_simpleCtrlHandle.stateNotifier.value ==
        SimpleCtrlHandle.stateDestroy) {
      Navigator.popUntil(
        context,
        (route) => route.settings.name == '/smart_ir',
      );
      SimpleSnackBar.show(context, 'Device connection failed', Colors.red);
    }
  }

  @override
  void initState() {
    super.initState();
    _discoverDeviceInfo = parameter[0] as DiscoverDeviceInfo;
    _deviceInfo = parameter[1] as DeviceInfo;
    _storageName = parameter[2] as String;

    _simpleCtrlHandle = SimpleCtrlHandle(_discoverDeviceInfo, _deviceInfo);
    _simpleCtrlHandle.stateNotifier.addListener(_stateNotifier);
    _simpleCtrlHandle.initHandle();

    _setTimer();
  }

  @override
  void dispose() {
    _simpleCtrlHandle.stateNotifier.removeListener(_stateNotifier);
    _simpleCtrlHandle.destroyHandle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstRender) {
      _isFirstRender = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => SimpleShowDialog.show(context, 'Device connecting...'),
      );
    }

    List<String> irKeyList = [];
    for (String item in _irKeyMap.keys) {
      irKeyList.add(item);
    }

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
                    page.parameter = [
                      _discoverDeviceInfo,
                      _storageName,
                      true,
                      _simpleCtrlHandle,
                    ];
                    return ParameterStatefulWidget(page);
                  },
                ),
              ).then((value) {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: irKeyList.length,
          padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
          itemBuilder: (context, index) {
            bool iconLight = _irKeyMap[irKeyList[index]]! != 0;
            return InkWell(
              onTap: () {
                developer.log('Send: ${irKeyList[index]}', name: _logName);
                // Sending IR signals
                ByteData byteData = ByteData(1);
                byteData.setUint8(0, _irCmdTxSend);
                BytesBuilder bb = BytesBuilder();
                bb.add(byteData.buffer.asUint8List());
                bb.add(utf8.encode(irKeyList[index]));
                Uint8List data = bb.toBytes();
                _simpleCtrlHandle.request(data, true).then((Uint8List? value) {
                  if (value != null &&
                      value.length == 2 &&
                      value[0] == _irCmdTxSend &&
                      value[1] == _irResultOk) {
                    developer.log('Send ok', name: _logName);
                  } else {
                    developer.log('Send failed', name: _logName);
                    if (mounted) {
                      SimpleSnackBar.show(context, 'Send failed', Colors.red);
                    }
                  }
                });
              },
              onLongPress: () {
                // Delete key
                showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Warning'),
                      content: const Text(
                        'Are you sure you want to delete this key?',
                        style: TextStyle(color: Colors.red),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Yes'),
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                        TextButton(
                          child: const Text(
                            'No',
                            style: TextStyle(color: Colors.black),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                        ),
                      ],
                    );
                  },
                ).then((bool? result) {
                  result ??= false;
                  developer.log(
                    'Delete key [${irKeyList[index]}]: $result',
                    name: _logName,
                  );
                  // Remove key
                  if (result) {
                    ByteData byteData = ByteData(1);
                    byteData.setUint8(0, _irCmdRemove);
                    BytesBuilder bb = BytesBuilder();
                    bb.add(byteData.buffer.asUint8List());
                    bb.add(utf8.encode(irKeyList[index]));
                    Uint8List data = bb.toBytes();
                    _simpleCtrlHandle.request(data, true).then((
                      Uint8List? value,
                    ) {
                      if (value != null &&
                          value.length == 2 &&
                          value[0] == _irCmdRemove &&
                          value[1] == _irResultOk) {
                        developer.log('Remove ok', name: _logName);
                        if (mounted) {
                          SimpleSnackBar.show(context, 'Removed', Colors.green);
                        }
                      } else {
                        developer.log('Remove failed', name: _logName);
                        if (mounted) {
                          SimpleSnackBar.show(
                            context,
                            'Remove failed',
                            Colors.red,
                          );
                        }
                      }
                    });
                  }
                });
              },
              child: Card(
                child: Padding(
                  padding: EdgeInsetsGeometry.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                        child: Icon(
                          iconLight
                              ? Icons.lightbulb
                              : Icons.lightbulb_outlined,
                          size: 24,
                          color: iconLight ? Colors.green : Colors.grey,
                        ),
                      ),
                      // Key name
                      Expanded(
                        child: Text(
                          irKeyList[index],
                          style: TextStyle(
                            fontFamily: subFontFamily,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _irRxDataVaild = false;
          _irKeyName.clear();
          // Add key
          showDialog<bool>(
            context: context,
            builder: (context) {
              developer.log('Dialog opened', name: _logName);
              return StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  _dialogSetState = setState;
                  return AlertDialog(
                    title: const Text('Add key'),
                    content: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          _irRxDataVaild
                              ? '$_irRxCount | ${_irRxLength}p'
                              : '--- | ---p',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blue, fontSize: 26),
                        ),
                        TextField(
                          controller: _irKeyName,
                          focusNode: _focusNode,
                          autofocus: false,
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: subFontFamily,
                          ),
                          decoration: InputDecoration(
                            labelText: "Enter key name",
                          ),
                          maxLength: 100,
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      Visibility(
                        visible: _irRxDataVaild && _irKeyName.text.isNotEmpty,
                        child: Wrap(
                          children: [
                            TextButton(
                              child: const Text('Save'),
                              onPressed: () => Navigator.of(context).pop(true),
                            ),
                            TextButton(
                              child: const Text(
                                'Test',
                                style: TextStyle(color: Colors.green),
                              ),
                              onPressed: () {
                                developer.log('Test', name: _logName);

                                ByteData byteData = ByteData(5);
                                byteData.setUint8(0, _irCmdTxTest);
                                byteData.setUint32(
                                  1,
                                  _irRxCount,
                                  Endian.little,
                                );
                                Uint8List data = byteData.buffer.asUint8List();
                                _simpleCtrlHandle.request(data, true).then((
                                  Uint8List? value,
                                ) {
                                  if (value != null &&
                                      value.length == 2 &&
                                      value[0] == _irCmdTxTest &&
                                      value[1] == _irResultOk) {
                                    developer.log('Test ok', name: _logName);
                                  } else {
                                    developer.log(
                                      'Test failed',
                                      name: _logName,
                                    );
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  );
                },
              );
            },
          ).then((value) {
            value ??= false;
            _dialogSetState = null;
            developer.log('Dialog closed, return: $value', name: _logName);
            if (value) {
              developer.log(
                'Save key, count: $_irRxCount, name: ${_irKeyName.text}',
                name: _logName,
              );
              // Save key
              ByteData byteData = ByteData(5);
              byteData.setUint8(0, _irCmdSave);
              byteData.setUint32(1, _irRxCount, Endian.little);
              BytesBuilder bb = BytesBuilder();
              bb.add(byteData.buffer.asUint8List());
              bb.add(utf8.encode(_irKeyName.text));
              Uint8List data = bb.toBytes();
              _simpleCtrlHandle.request(data, true).then((Uint8List? value) {
                if (value != null &&
                    value.length == 2 &&
                    value[0] == _irCmdSave &&
                    value[1] == _irResultOk) {
                  developer.log('Save ok', name: _logName);
                  if (mounted) {
                    SimpleSnackBar.show(context, 'Saved', Colors.green);
                  }
                } else {
                  developer.log('Save failed', name: _logName);
                  if (mounted) {
                    SimpleSnackBar.show(context, 'Save failed', Colors.red);
                  }
                }
              });
            }
          });
        },
        tooltip: 'Add key',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Config device page
class SmartIRConfigDevicePageState extends ParameterStatefulState {
  DeviceInfo _deviceInfo = DeviceInfo();
  late DiscoverDeviceInfo _discoverDeviceInfo;
  late String _storageName;
  late bool _allowSetPasswd;
  SimpleCtrlHandle? _simpleCtrlHandle;

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
    _allowSetPasswd = parameter[2] as bool;
    if (parameter.length > 3) {
      _simpleCtrlHandle = parameter[3] as SimpleCtrlHandle;
    }
    _deviceInfo.nickName = _discoverDeviceInfo.name;
    _deviceInfo.id = _discoverDeviceInfo.id;
    _deviceInfoLoad().then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return DeviceConfig(
      allowSetPasswd: _allowSetPasswd,
      discoverDeviceInfo: _discoverDeviceInfo,
      deviceInfo: _deviceInfo,
      onSavePressed: (deviceInfo) {
        if (_simpleCtrlHandle != null) {
          SimpleShowDialog.show(context, "Verifying device...");
          _simpleCtrlHandle!.setPassword(deviceInfo.accessKey).then((
            bool value,
          ) {
            if (value) {
              _deviceInfoSave();
              Navigator.popUntil(
                context,
                (route) => route.settings.name == '/smart_ir',
              );
              SimpleSnackBar.show(
                context,
                'Device information saved',
                Colors.green,
              );
            } else {
              Navigator.pop(context);
              SimpleSnackBar.show(
                context,
                'Failed to configure device information',
                Colors.red,
              );
            }
          });
        } else {
          if (_allowSetPasswd == false) {
            deviceInfo.accessKey = '';
          }
          _deviceInfoSave();
          Navigator.pop(context);
          SimpleSnackBar.show(context, 'Device saved', Colors.green);
        }
      },
    );
  }
}
