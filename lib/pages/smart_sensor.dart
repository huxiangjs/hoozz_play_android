///
/// Created on 2025/8/10
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:convert';
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

const String _logName = 'Sensor';

class _SensorInfo {
  late String name;
  late String? data;
  late IconData icon;
  _SensorInfo(this.name, this.data, this.icon);
}

// Sensor page
class SensorDeviceCtrlPageState extends ParameterStatefulState {
  late SimpleCtrlHandle _simpleCtrlHandle;
  late DiscoverDeviceInfo _discoverDeviceInfo;
  late DeviceInfo _deviceInfo;
  late String _storageName;

  static const int _sensorCmdGetCount = 0x00;
  static const int _sensorCmdGetItem = 0x01;

  static const int _sensorResultOk = 0x00;
  static const int _sensorResultFail = 0x01;

  static const int _sensorTypeBrightness = 0x01;
  static const int _sensorTypeHumidity = 0x02;
  static const int _sensorTypeTemperature = 0x03;

  final Map<String, _SensorInfo> _sensorKeyMap = {};

  bool _isFirstRender = true;

  Future<void> _getSensorInfo(int sensorCount) async {
    ByteData byteData = ByteData(5);
    byteData.setUint8(0, _sensorCmdGetItem);
    // Read the information of each sensor
    for (int index = 0; index < sensorCount; index++) {
      byteData.setUint32(1, index, Endian.little);
      Uint8List data = byteData.buffer.asUint8List();
      Uint8List? value = await _simpleCtrlHandle.request(data, true);
      // developer.log('Get return: $value', name: _logName);
      if (value != null && value.length > 4 && value[0] == _sensorCmdGetItem) {
        if (value[1] == _sensorResultOk) {
          int sensorType = value[2];
          int sensorIndex = value[3];
          String sensorName = utf8.decode(value.sublist(4));
          developer.log(
            '[$index] Sensor type:$sensorType, index:$sensorIndex, name:$sensorName',
            name: _logName,
          );
          String key = '$sensorType:$sensorIndex';
          if (!mounted) return;
          setState(() {
            IconData icon;
            switch (sensorType) {
              case _sensorTypeBrightness:
                icon = Icons.light_mode_outlined;
                break;
              case _sensorTypeHumidity:
                icon = Icons.water_drop_outlined;
                break;
              case _sensorTypeTemperature:
                icon = Icons.device_thermostat;
                break;
              default:
                icon = Icons.device_unknown;
            }
            _sensorKeyMap[key] = _SensorInfo(
              '$sensorName$sensorIndex',
              null,
              icon,
            );
          });
        }
      }
    }
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
        int sensorType = data[0];
        int sensorIndex = data[1];
        Uint8List playload = data.sublist(2);
        String key = '$sensorType:$sensorIndex';
        _SensorInfo? sensorInfo = _sensorKeyMap[key];
        if (sensorInfo == null) return;
        late String tmp;
        switch (sensorType) {
          case _sensorTypeBrightness:
            ByteData byteData = playload.buffer.asByteData();
            int sensorData = byteData.getUint16(0, Endian.little);
            tmp = '$sensorData lx';
            break;
          case _sensorTypeHumidity:
            ByteData byteData = playload.buffer.asByteData();
            int sensorData = byteData.getUint16(0, Endian.little);
            tmp = '${sensorData / 10}%RH';
            break;
          case _sensorTypeTemperature:
            ByteData byteData = playload.buffer.asByteData();
            int sensorData = byteData.getUint16(0, Endian.little);
            tmp = '${sensorData / 10}℃';
            break;
        }

        if (!mounted) return;
        setState(() {
          sensorInfo.data = tmp;
        });

        // developer.log(
        //   'Sensor type:$sensorType, index:$sensorIndex',
        //   name: _logName,
        // );
      });

      // Read remote device sensor count (Once)
      ByteData byteData = ByteData(1);
      byteData.setUint8(0, _sensorCmdGetCount);
      Uint8List data = byteData.buffer.asUint8List();
      _simpleCtrlHandle.request(data, true).then((Uint8List? value) {
        // developer.log('Get return: $value', name: _logName);
        Navigator.pop(context);
        if (value != null &&
            value.length == 6 &&
            value[0] == _sensorCmdGetCount &&
            value[1] == _sensorResultOk) {
          ByteData byteData = ByteData.view(value.buffer, 2, 4);
          int sensorCount = byteData.getUint32(0, Endian.little);
          developer.log('Sensor count: $sensorCount', name: _logName);
          // Read the information of each sensor
          _getSensorInfo(sensorCount);
        } else {
          Navigator.popUntil(
            context,
            (route) => route.settings.name == '/sensor',
          );
          SimpleSnackBar.show(context, 'Abnormal device data', Colors.red);
        }
      });

      // Disconnected or Failed
    } else if (_simpleCtrlHandle.stateNotifier.value ==
        SimpleCtrlHandle.stateDestroy) {
      Navigator.popUntil(context, (route) => route.settings.name == '/sensor');
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

    List<_SensorInfo> sensorKeyList = _sensorKeyMap.values.toList();

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
          itemCount: sensorKeyList.length,
          padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
          itemBuilder: (context, index) {
            bool hasData = sensorKeyList[index].data != null;
            return Card(
              child: Padding(
                padding: EdgeInsetsGeometry.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon
                    Padding(
                      padding: const EdgeInsets.fromLTRB(5, 5, 15, 5),
                      child: Icon(
                        sensorKeyList[index].icon,
                        size: 40,
                        color: hasData ? Colors.cyan : Colors.grey,
                      ),
                    ),
                    // Key name
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sensorKeyList[index].name,
                          style: TextStyle(
                            fontFamily: subFontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          hasData ? sensorKeyList[index].data! : 'No data',
                          style: TextStyle(
                            fontFamily: subFontFamily,
                            fontSize: 16,
                            color: hasData ? Colors.blue : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Config device page
class SensorConfigDevicePageState extends ParameterStatefulState {
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
                (route) => route.settings.name == '/sensor',
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
