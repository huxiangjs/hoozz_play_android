///
/// Created on 2024/04/23
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

// refs: https://zywi.cn/1385.html
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

const String _logName = 'esptouch';
typedef OnChanged = void Function(String, String);

abstract class ESPTouchAdapter {
// Create an EventChannel object with a unique name and a codec
  static const EventChannel _eventChannel =
      EventChannel('ESPTOUCH_EVENT', StandardMethodCodec());
  static StreamSubscription<dynamic>? _subscription;
  static const MethodChannel _methodChannel = MethodChannel('ESPTOUCH_METHOD');

  static const int maxConfig = 10;

  static void _startEventListen(OnChanged onChanged) {
    // Get a Stream object from the EventChannel object
    Stream<dynamic> stream = _eventChannel.receiveBroadcastStream();
    // Listen to the stream and handle each event
    _subscription = stream.listen(
      (event) {
        if (event is String) {
          // Convert the event to a string value
          String value = event;
          List<String> devInfo = value.split(' ');
          String ip = devInfo[0];
          String mac = devInfo[1];
          onChanged(ip, mac);
        } else {
          developer.log('Unknown event', name: _logName);
        }
      },
    );
  }

  static void _stopEventListen() {
    _subscription?.cancel();
    _subscription = null;
  }

  static Future<bool> _requestPermission() async {
    bool retval = false;
    /* Request permission */
    var status = await Permission.location.status;
    if (!status.isGranted) {
      PermissionStatus ret = await Permission.location.request();
      if (ret != PermissionStatus.granted) {
        developer.log('Permission not granted', name: _logName);
        retval = false;
      } else {
        developer.log('Permission granted', name: _logName);
        retval = true;
      }
    } else {
      return true;
    }
    return retval;
  }

  static Future<void> testWifiInfo() async {
    await _requestPermission();
    final info = NetworkInfo();
    final wifiName = await info.getWifiName();
    final wifiBSSID = await info.getWifiBSSID();
    final wifiIP = await info.getWifiIP();
    final wifiIPv6 = await info.getWifiIPv6();
    final wifiSubmask = await info.getWifiSubmask();
    final wifiBroadcast = await info.getWifiBroadcast();
    final wifiGateway = await info.getWifiGatewayIP();
    developer.log(
        'Wifi info: $wifiName;$wifiBSSID;$wifiIP;$wifiIPv6;$wifiSubmask;$wifiBroadcast;$wifiGateway',
        name: _logName);
  }

  static Future<String?> getWifiName() async {
    await _requestPermission();
    final info = NetworkInfo();
    String? wifiName = await info.getWifiName();
    if (wifiName == null) return null;

    wifiName = wifiName.substring(1, wifiName.length - 1);
    developer.log('Wifi name: $wifiName', name: _logName);
    return wifiName;
  }

  static Future<String?> getWiFiMacAddress() async {
    await _requestPermission();
    final info = NetworkInfo();
    String? wifiMac = await info.getWifiBSSID();
    if (wifiMac == null) return null;

    wifiMac = wifiMac.substring(1, wifiMac.length - 1);
    developer.log('Wifi MAC: $wifiMac', name: _logName);
    return wifiMac;
  }

  static Future<bool> startConfig(
      String wifiName, String wifiPassword, OnChanged onChanged) async {
    String? wifiMac = await getWiFiMacAddress();
    _startEventListen(onChanged);
    int ret = await _methodChannel.invokeMethod('startConfig', {
      'name': wifiName,
      'pwd': wifiPassword,
      'mac': wifiMac,
      'max': '$maxConfig'
    });
    if (ret != 0) {
      developer.log('Unable to start configuration', name: _logName);
      _stopEventListen();
      return false;
    }

    return true;
  }

  static Future<void> stopConfig() async {
    await _methodChannel.invokeMethod('stopConfig');
    _stopEventListen();
  }
}
