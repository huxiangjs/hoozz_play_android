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
  String classId;
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

class SimpleCtrl {
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

  Future<void> initDiscover() async {
    LinkedHashMap<String, DiscoverDeviceInfo> deviceList =
        deviceListNotifier.deviceList;

    if (_discoverRunning) {
      developer.log('Discover is already running', name: _logName);
      return;
    }
    _discoverRunning = true;

    developer.log('Start SimpleCtrl', name: _logName);

    _udpSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, _discoverUDPPort);
    _udpSocket.broadcastEnabled = true;

    // Read data
    _udpSocket.listen((e) {
      Datagram? dg = _udpSocket.receive();
      if (dg != null) {
        try {
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
            developer.log(
                '[$ip:$port] CLASS:$classId ID:$id NAME:$name TIME:${time.toString()}',
                name: _logName);
            if (id.length == _idLength) {
              deviceListNotifier.set(
                  id, DiscoverDeviceInfo(id, ip, port, classId, name, time));
              developer.log('Device count: ${deviceList.length}',
                  name: _logName);
            }
          }
        } catch (e) {
          developer.log('Receive exception', name: _logName);
        }
      }
    });

    // Send data
    List<int> data = utf8.encode(_discoverSay);
    InternetAddress destinationAddress = InternetAddress("255.255.255.255");

    void sayHello(Timer timer) {
      developer.log('Say hello', name: _logName);
      try {
        () async {
          for (int i = 0; i < 5; i++) {
            _udpSocket.send(data, destinationAddress, _discoverUDPPort);
            await Future.delayed(const Duration(seconds: 0, milliseconds: 100));
          }
        }.call();
      } catch (e) {
        developer.log('Send exception', name: _logName);
        _discoverTimer.cancel();
      }
    }

    // Interval call
    _discoverTimer =
        Timer.periodic(Duration(seconds: _discoveryInterval), sayHello);
    // Manual execution for the first time
    sayHello(_discoverTimer);
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
