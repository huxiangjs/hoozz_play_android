///
/// Created on 2026/6/22
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hoozz_play/core/device_binding.dart';
import 'package:hoozz_play/core/device_config.dart';
import 'package:hoozz_play/core/parameter_stateful.dart';
import 'package:hoozz_play/core/simple_showdialog.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'package:hoozz_play/core/device_storage.dart';
import 'package:hoozz_play/core/simple_snackbar.dart';
import 'dart:developer' as developer;

import 'package:hoozz_play/themes/theme.dart';

const String _logName = 'PWD SYNC';

// IR ctrl page
class PwdSyncDeviceCtrlPageState extends ParameterStatefulState {
  late SimpleCtrlHandle _simpleCtrlHandle;
  late DiscoverDeviceInfo _discoverDeviceInfo;
  late DeviceInfo _deviceInfo;
  late String _storageName;

  final int _syncCmdGetCount = 0x00;
  final int _syncCmdGetItem = 0x01;
  final int _syncCmdSetDev = 0x02;
  final int _syncCmdAddDev = 0x03;
  final int _syncCmdRemoveDev = 0x04;

  final int _syncResultOk = 0x00;
  final int _syncResultFail = 0x01;
  final int _syncResultDone = 0x02;

  final Map<String, Map<String, dynamic>> _deviceMap = {};
  bool _getDeviceListRunning = false;
  bool _remoteDataReady = false;
  bool _localDataReady = false;
  bool _syncRunning = false;

  bool _isFirstRender = true;

  Future<void> _getDeviceList(int devCount) async {
    if (_getDeviceListRunning) return;
    _getDeviceListRunning = true;
    ByteData byteData = ByteData(5);
    byteData.setUint8(0, _syncCmdGetItem);
    // Read the information of each dev
    for (int index = 0; index < devCount; index++) {
      byteData.setUint32(1, index, Endian.little);
      Uint8List data = byteData.buffer.asUint8List();
      Uint8List? value = await _simpleCtrlHandle.request(data, true);
      // developer.log('Get return: $value', name: _logName);
      if (value != null && value.length > 2 && value[0] == _syncCmdGetItem) {
        if (value[1] == _syncResultOk) {
          String devInfo = utf8.decode(value.sublist(2));
          String devId = devInfo.substring(0, 14);
          String devPassword = devInfo.substring(14);
          developer.log('[$index] Device id: $devId', name: _logName);
          // Check and save
          Map<String, dynamic> dev = {};
          if (_deviceMap.containsKey(devId)) {
            dev = _deviceMap[devId]!;
          }
          dev['rmt_pwd'] = devPassword;
          dev['sel'] = false;
          if (!mounted) return;
          setState(() {
            _deviceMap[devId] = dev;
          });
        } else if (value[1] == _syncResultDone) {
          // Ignore devices that have been removed
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _remoteDataReady = true;
    });
    _getDeviceListRunning = false;
  }

  void _stateNotifier() {
    // Connected
    if (_simpleCtrlHandle.stateNotifier.value ==
        SimpleCtrlHandle.stateConnected) {
      // Read remote device count (Once)
      ByteData byteData = ByteData(1);
      byteData.setUint8(0, _syncCmdGetCount);
      Uint8List data = byteData.buffer.asUint8List();
      _simpleCtrlHandle.request(data, true).then((Uint8List? value) {
        // developer.log('Get return: $value', name: _logName);
        Navigator.pop(context);
        if (value != null &&
            value.length == 6 &&
            value[0] == _syncCmdGetCount &&
            value[1] == _syncResultOk) {
          ByteData byteData = ByteData.view(value.buffer, 2, 4);
          int devCount = byteData.getUint32(0, Endian.little);
          developer.log('Device count: $devCount', name: _logName);
          // Read the information of each device
          _getDeviceList(devCount);
        } else {
          Navigator.popUntil(
            context,
            (route) => route.settings.name == '/pwd_sync',
          );
          SimpleSnackBar.show(context, 'Abnormal device data', Colors.red);
        }
      });

      // Disconnected or Failed
    } else if (_simpleCtrlHandle.stateNotifier.value ==
        SimpleCtrlHandle.stateDestroy) {
      Navigator.popUntil(
        context,
        (route) => route.settings.name == '/pwd_sync',
      );
      SimpleSnackBar.show(context, 'Device connection failed', Colors.red);
    }
  }

  // Load locally saved device information
  Future<void> _loadDeviceList() async {
    for (DeviceBindingBody dev in DeviceBindingList.binding.values) {
      String storageName = dev.describe;
      developer.log('Device class: $storageName', name: _logName);
      DeviceStorage storage = DeviceStorage(storageName);
      await storage.load();
      for (DeviceInfo item in storage.deviceList.values) {
        Map<String, dynamic> dev = {};
        if (_deviceMap.containsKey(item.id)) {
          dev = _deviceMap[item.id]!;
        }
        dev['lc_pwd'] = item.accessKey;
        dev['sel'] = false;
        _deviceMap[item.id] = dev;
      }
    }
    if (!mounted) return;
    setState(() {
      _localDataReady = true;
    });
  }

  Future<void> _startSync(List<Map<String, dynamic>> changelist) async {
    setState(() => _syncRunning = true);

    for (Map<String, dynamic> change in changelist) {
      String id = change['id'];

      switch (change['op']) {
        case 'ADD':
          String pwd = change['pwd'];
          final BytesBuilder builder = BytesBuilder();
          builder.addByte(_syncCmdAddDev);
          builder.add(utf8.encode(id));
          builder.add(utf8.encode(pwd));
          Uint8List requestData = builder.toBytes();
          Uint8List? value = await _simpleCtrlHandle.request(requestData, true);
          // developer.log('Add return: $value', name: _logName);
          if (value != null &&
              value.length == 2 &&
              value[0] == _syncCmdAddDev) {
            if (value[1] == _syncResultOk) {
              setState(() {
                _deviceMap[id]!['rmt_pwd'] = pwd;
                _deviceMap[id]!['sel'] = false;
              });
            } else if (value[1] == _syncResultDone) {
              // Ignore devices that have been removed
            }
          }
          break;
        case 'REMOVE':
          final BytesBuilder builder = BytesBuilder();
          builder.addByte(_syncCmdRemoveDev);
          builder.add(utf8.encode(id));
          Uint8List requestData = builder.toBytes();
          Uint8List? value = await _simpleCtrlHandle.request(requestData, true);
          // developer.log('Remove return: $value', name: _logName);
          if (value != null &&
              value.length == 2 &&
              value[0] == _syncCmdRemoveDev) {
            if (value[1] == _syncResultOk) {
              setState(() => _deviceMap.remove(id));
            } else if (value[1] == _syncResultDone) {
              // Ignore devices that have been removed
            }
          }
          break;
        case 'CHANGE':
          String pwd = change['pwd'];
          final BytesBuilder builder = BytesBuilder();
          builder.addByte(_syncCmdSetDev);
          builder.add(utf8.encode(id));
          builder.add(utf8.encode(pwd));
          Uint8List requestData = builder.toBytes();
          Uint8List? value = await _simpleCtrlHandle.request(requestData, true);
          // developer.log('Change return: $value', name: _logName);
          if (value != null &&
              value.length == 2 &&
              value[0] == _syncCmdSetDev) {
            if (value[1] == _syncResultOk) {
              setState(() {
                _deviceMap[id]!['rmt_pwd'] = pwd;
                _deviceMap[id]!['sel'] = false;
              });
            } else if (value[1] == _syncResultDone) {
              // Ignore devices that have been removed
            }
          }
          break;
      }
    }

    setState(() => _syncRunning = false);
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

    _loadDeviceList();
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

    String getChange(Map<String, dynamic> info) {
      bool existLocal = info.containsKey('lc_pwd');
      bool existRemote = info.containsKey('rmt_pwd');
      if (existLocal && !existRemote) {
        return 'ADD';
      } else if (!existLocal && existRemote) {
        return 'REMOVE';
      } else if (info['lc_pwd'] != info['rmt_pwd']) {
        return 'CHANGE';
      }
      return 'KEEP';
    }

    List<String> deviceList = _deviceMap.keys.toList();

    const TextStyle textStyle = TextStyle(fontFamily: subFontFamily);

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
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: deviceList.length,
          padding: const EdgeInsets.fromLTRB(5, 15, 10, 30),
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(color: Color.fromARGB(0x30, 0, 0, 0)),
          itemBuilder: (context, index) {
            String devId = deviceList[index];
            Map<String, dynamic> info = _deviceMap[devId]!;
            bool existLocal = info.containsKey('lc_pwd');
            bool existRemote = info.containsKey('rmt_pwd');
            String change = getChange(info);
            Color leftTextColor = mainTextColor;
            Color rightTextColor = mainTextColor;
            // Set text color
            switch (change) {
              case 'ADD':
                leftTextColor = Colors.green;
                break;
              case 'REMOVE':
                rightTextColor = Colors.red;
                break;
              case 'CHANGE':
                leftTextColor = Colors.blue;
                rightTextColor = Colors.blue;
                break;
              case 'KEEP':
              default:
            }
            return InkWell(
              onTap: (_syncRunning || change == 'KEEP')
                  ? null
                  : () {
                      setState(
                        () => _deviceMap[devId]!['sel'] =
                            !_deviceMap[devId]!['sel'],
                      );
                    },
              onLongPress: (_syncRunning || change == 'KEEP')
                  ? null
                  : () {
                      showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Select'),
                            content: const Text(
                              'Select All or Deselect All',
                              style: textStyle,
                            ),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: Text('Select All', style: textStyle),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text('Deselect All', style: textStyle),
                              ),
                            ],
                          );
                        },
                      ).then((bool? result) {
                        if (result == null) return;
                        // Select All or Deselect All
                        for (Map<String, dynamic> item in _deviceMap.values) {
                          String change = getChange(item);
                          if (change == 'KEEP') continue;
                          setState(() => item['sel'] = result);
                        }
                      });
                    },
              child: IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _deviceMap[devId]!['sel'],
                      onChanged: (_syncRunning || change == 'KEEP')
                          ? null
                          : (bool? value) {
                              setState(() => _deviceMap[devId]!['sel'] = value);
                            },
                    ),
                    VerticalDivider(
                      color: Color.fromARGB(0x20, 0, 0, 0),
                      thickness: 1,
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        existLocal ? devId : '',
                        style: TextStyle(
                          fontFamily: subFontFamily,
                          fontSize: 20,
                          color: leftTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    VerticalDivider(
                      color: Color.fromARGB(0x20, 0, 0, 0),
                      thickness: 1,
                      width: 10,
                    ),
                    Expanded(
                      child: Text(
                        existRemote ? devId : '',
                        style: TextStyle(
                          fontFamily: subFontFamily,
                          fontSize: 20,
                          color: rightTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: Visibility(
        visible: _localDataReady && _remoteDataReady && !_syncRunning,
        child: FloatingActionButton(
          onPressed: () {
            // Build Changelist
            List<Map<String, dynamic>> changelist = [];
            for (String devId in _deviceMap.keys) {
              Map<String, dynamic> info = _deviceMap[devId]!;
              if (!info['sel']) continue;
              String change = getChange(info);
              Map<String, dynamic> devChange = {};
              switch (change) {
                case 'ADD':
                  devChange['op'] = 'ADD';
                  devChange['id'] = devId;
                  devChange['cl'] = Colors.green;
                  devChange['pwd'] = info['lc_pwd'];
                  break;
                case 'REMOVE':
                  devChange['op'] = 'REMOVE';
                  devChange['id'] = devId;
                  devChange['cl'] = Colors.red;
                  break;
                case 'CHANGE':
                  devChange['op'] = 'CHANGE';
                  devChange['id'] = devId;
                  devChange['cl'] = Colors.blue;
                  devChange['pwd'] = info['lc_pwd'];
                  break;
                case 'KEEP':
                default:
              }
              if (devChange.isNotEmpty) {
                changelist.add(devChange);
              }
            }
            if (changelist.isEmpty) {
              SimpleSnackBar.show(
                context,
                'No devices have been selected',
                Colors.grey,
              );
              return;
            }
            showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Changelist'),
                  content: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(changelist.length, (index) {
                          Map<String, dynamic> change = changelist[index];
                          String op = change['op'];
                          String id = change['id'];
                          Color cl = change['cl'];
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 70,
                                child: Text(
                                  '$op:',
                                  style: TextStyle(
                                    color: cl,
                                    fontFamily: subFontFamily,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                id,
                                style: TextStyle(
                                  color: cl,
                                  fontFamily: subFontFamily,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Start'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ],
                );
              },
            ).then((bool? result) {
              if (result == null) return;
              if (result) {
                _startSync(changelist);
              }
            });
          },
          tooltip: 'Sync',
          child: const Icon(Icons.sync_alt),
        ),
      ),
    );
  }
}

// Config device page
class PwdSyncConfigDevicePageState extends ParameterStatefulState {
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
                (route) => route.settings.name == '/pwd_sync',
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
