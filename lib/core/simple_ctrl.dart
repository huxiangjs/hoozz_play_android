///
/// Created on 2024/05/09
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';

const String _logName = 'simple_ctrl';

class DiscoverDeviceInfo {
  String id;
  String ip;
  int port;
  int classId;
  String name;
  DateTime time;

  DiscoverDeviceInfo(
      this.id, this.ip, this.port, this.classId, this.name, this.time);
}

class DeviceListChangeNotifier extends ChangeNotifier {
  LinkedHashMap<String, DiscoverDeviceInfo> deviceList =
      LinkedHashMap<String, DiscoverDeviceInfo>();

  void set(String key, DiscoverDeviceInfo value) {
    deviceList[key] = value;
    notifyListeners();
  }
}

class SimpleCtrlTool {
  static String macToId(String mac) {
    return '${mac}00';
  }
}

class SimpleCtrlDiscover {
  final int _discoverUDPPort = 54542;
  final String _discoverSay = 'HOOZZ?';
  final String _discoverRespond = 'HOOZZ:';
  final int _idLength = 14;
  final int _discoveryInterval = 10;
  bool _discoverRunning = false;

  late RawDatagramSocket _udpSocket;

  late Timer _discoverTimer;

  DeviceListChangeNotifier deviceListNotifier = DeviceListChangeNotifier();

  List<DiscoverDeviceInfo> getDeviceList() {
    List<DiscoverDeviceInfo> retval = [];

    for (DiscoverDeviceInfo item in deviceListNotifier.deviceList.values) {
      retval.add(item);
    }

    return retval;
  }

  Future<bool> initDiscover() async {
    if (_discoverRunning) {
      developer.log('Discover is already running', name: _logName);
      return true;
    }
    _discoverRunning = true;

    developer.log('Start SimpleCtrl', name: _logName);

    try {
      _udpSocket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4, _discoverUDPPort);
      _udpSocket.broadcastEnabled = true;

      // Read data
      _udpSocket.listen((e) {
        try {
          Datagram? dg = _udpSocket.receive();
          if (dg != null) {
            // developer.log('received: ${dg.data}', name: _logName);
            String data = utf8.decode(dg.data);
            String ip = dg.address.address;
            int port = dg.port;
            if (data.startsWith(_discoverRespond)) {
              int start = _discoverRespond.length;
              String classId = data.substring(start, start + 2);
              String id = data.substring(start + 2, start + 2 + _idLength);
              String name = data.substring(start + 2 + _idLength);
              DateTime time = DateTime.now();
              // developer.log(
              //     '[$ip:$port] CLASS:$classId ID:$id NAME:$name TIME:${time.toString()}',
              //     name: _logName);
              if (id.length == _idLength) {
                int classIdNum = int.parse(classId, radix: 16);
                deviceListNotifier.set(id,
                    DiscoverDeviceInfo(id, ip, port, classIdNum, name, time));
                // LinkedHashMap<String, DiscoverDeviceInfo> deviceList =
                //     deviceListNotifier.deviceList;
                // developer.log('Device count: ${deviceList.length}',
                //     name: _logName);
              }
            }
          }
        } catch (e) {
          developer.log('Receive exception', name: _logName);
        }
      });
    } catch (e) {
      developer.log('UDP socket exception', name: _logName);
      _discoverRunning = false;
      return false;
    }

    // Send data
    List<int> data = utf8.encode(_discoverSay);
    InternetAddress destinationAddress = InternetAddress("255.255.255.255");

    void sayHello(Timer timer) {
      developer.log('Say hello', name: _logName);
      () async {
        for (int i = 0; i < 5; i++) {
          try {
            _udpSocket.send(data, destinationAddress, _discoverUDPPort);
            await Future.delayed(const Duration(seconds: 0, milliseconds: 100));
          } catch (e) {
            developer.log('Send exception', name: _logName);
          }
        }
      }.call();
    }

    // Interval call
    _discoverTimer =
        Timer.periodic(Duration(seconds: _discoveryInterval), sayHello);
    // Manual execution for the first time
    sayHello(_discoverTimer);

    return true;
  }

  void destroyDiscovery() {
    if (!_discoverRunning) {
      developer.log('Discover is not running', name: _logName);
      return;
    }

    try {
      _discoverTimer.cancel();
      _udpSocket.close();
    } catch (e) {
      developer.log('Close socket exception', name: _logName);
    }

    developer.log('Stop SimpleCtrl', name: _logName);
    _discoverRunning = false;
  }
}

class SimpleCtrlHandle {
  static const int stateInit = 0; // Init
  static const int stateConnecting = 1; // Connecting
  static const int stateConnected = 2; // Connected
  static const int stateDisconnected = 3; // Disconnected
  static const int stateFailed = 4; // Failed

  final DiscoverDeviceInfo _discoverDeviceInfo;

  final ValueNotifier<int> stateNotifier = ValueNotifier<int>(stateInit);

  late Socket _tcpSocket;

  final int _pingInterval = 5;

  late Timer _pingTimer;

  SimpleCtrlHandle(this._discoverDeviceInfo);

  Future<bool> initHandle() async {
    try {
      stateNotifier.value = stateConnecting;
      developer.log(
          'Connecting: ${_discoverDeviceInfo.ip}:${_discoverDeviceInfo.port}',
          name: _logName);
      _tcpSocket = await Socket.connect(
          _discoverDeviceInfo.ip, _discoverDeviceInfo.port);
      stateNotifier.value = stateConnected;
      developer.log(
          'Connected: ${_discoverDeviceInfo.ip}:${_discoverDeviceInfo.port}',
          name: _logName);
      // Listen disconnected
      _tcpSocket.drain().then((_) => destroyHandle());
    } catch (e) {
      stateNotifier.value = stateFailed;
      developer.log(
          'Connection failed: ${_discoverDeviceInfo.ip}:${_discoverDeviceInfo.port}',
          name: _logName);
      return false;
    }

    // ping remote
    _pingTimer =
        Timer.periodic(Duration(seconds: _pingInterval), (Timer timer) {
      developer.log('Connect ping', name: _logName);
      () async {
        try {
          _tcpSocket.write('Hello, Server!');
        } catch (e) {
          developer.log('Write exception', name: _logName);
        }
      }.call();
    });

    // _tcpSocket.cast<List<int>>().transform(utf8.decoder).listen(print);

    return true;
  }

  void destroyHandle() {
    if (stateNotifier.value == stateDisconnected) return;
    stateNotifier.value = stateDisconnected;
    developer.log(
        'Disconnected: ${_discoverDeviceInfo.ip}:${_discoverDeviceInfo.port}',
        name: _logName);
    try {
      _pingTimer.cancel();
      _tcpSocket.close();
    } catch (e) {
      developer.log('Close socket exception', name: _logName);
    }
  }
}
