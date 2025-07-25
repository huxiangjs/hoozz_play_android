///
/// Created on 2025/07/20
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:io';
import 'dart:async';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:convert';

const String _logName = 'vpn_ctrl';

class VPNCtrl {
  static const _configKey = 'OpenVPN_Config_0';
  static late void Function() _homeSetState;
  static void Function()? _settingSetState;
  static void Function(Map<String, dynamic> value)? _settingStatusUpdate;
  static late OpenVPN _engine;
  static late Map<String, dynamic> _lastStatus;
  static late String remoteProtocol;
  static late String remoteAddress;
  static late String remotePort;
  static bool configValid = false;
  static bool connected = false;
  static late String _config;

  static void settingInit(
    void Function() setState,
    void Function(Map<String, dynamic> value) statusUpdate,
  ) {
    _settingSetState = setState;
    _settingStatusUpdate = statusUpdate;
    setState();
    if (_lastStatus.isNotEmpty) statusUpdate(_lastStatus);
  }

  static void settingDeinit() {
    _settingSetState = null;
    _settingStatusUpdate = null;
  }

  static void _setState() {
    _homeSetState();
    if (_settingSetState != null) {
      _settingSetState!();
    }
  }

  static void _statusUpdate(VpnStatus status) {
    _lastStatus = status.toJson();
    if (_settingStatusUpdate != null) _settingStatusUpdate!(_lastStatus);
  }

  static void _stageCheck(String string) {
    switch (string) {
      case 'disconnected':
        connected = false;
        _setState();
        break;
      case 'connected':
        connected = true;
        _setState();
        break;
    }
  }

  static bool setConfig(String config) {
    List<String> lines = LineSplitter().convert(config);
    bool protoParseOK = false;
    bool remoteParseOK = false;

    if (lines.isEmpty || lines[0] != 'client') return false;

    for (String line in lines) {
      List<String> resule = line.split(' ');
      if (resule.isEmpty) {
        continue;
      }
      switch (resule[0]) {
        case 'proto':
          if (resule.length != 2) return false;
          remoteProtocol = resule[1];
          protoParseOK = true;
          developer.log('remoteProtocol: $remoteProtocol', name: _logName);
          break;
        case 'remote':
          if (resule.length != 3) return false;
          remoteAddress = resule[1];
          remotePort = resule[2];
          remoteParseOK = true;
          developer.log(
            'remoteAddress: $remoteAddress, remotePort: $remotePort',
            name: _logName,
          );
          break;
      }
    }

    if (!(protoParseOK && remoteParseOK)) return false;

    _config = config;
    configValid = true;
    _setState();

    return true;
  }

  static void clearConfig() {
    if (connected) disconnect();
    configValid = false;
    _setState();
  }

  static Future<void> saveConfig() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(_configKey, _config);
    developer.log('Config saved', name: _logName);
  }

  static Future<void> loadConfig() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? config = sharedPreferences.getString(_configKey);
    if (config != null) {
      setConfig(config);
      developer.log('Config loaded', name: _logName);
    } else {
      developer.log('Config does not exist', name: _logName);
    }
  }

  static Future<void> removeConfig() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.remove(_configKey);
    developer.log('Config removed', name: _logName);
  }

  static void init(void Function() stageUpdate) {
    developer.log('Init', name: _logName);

    _homeSetState = stageUpdate;

    _engine = OpenVPN(
      onVpnStatusChanged: (data) {
        // developer.log('onVpnStatusChanged: $data', name: _logName);
        if (data != null) _statusUpdate(data);
      },
      onVpnStageChanged: (data, raw) {
        developer.log('onVpnStageChanged: $data - $raw', name: _logName);
        _stageCheck(raw);
      },
    );

    _engine.initialize(
      lastStage: (stage) {
        developer.log('lastStage: ${stage.name}', name: _logName);
        _stageCheck(stage.name);
      },
      lastStatus: (status) {
        developer.log('lastStatus: $status', name: _logName);
        _statusUpdate(status);
      },
    );

    loadConfig();
  }

  static Future<bool> connect() async {
    bool granted = true;

    if (Platform.isAndroid) granted = await _engine.requestPermissionAndroid();
    developer.log('requestPermissionAndroid: $granted', name: _logName);

    if (granted) _engine.connect(_config, 'Hoozz Play', certIsRequired: true);

    return granted;
  }

  static Future<void> disconnect() async {
    _engine.disconnect();
  }
}
