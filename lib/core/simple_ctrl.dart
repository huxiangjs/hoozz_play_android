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
import 'dart:typed_data';
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

class SimpleCtrlHandlePack {
  final int dataType;
  final int encrypType;
  final int dataLen;
  final BytesBuilder dataBuffer = BytesBuilder();

  SimpleCtrlHandlePack(this.dataType, this.encrypType, this.dataLen);

  Uint8List get loadData => dataBuffer.toBytes();

  Uint8List pack() {
    ByteData byteData = ByteData(6);
    byteData.setUint8(0, dataType);
    byteData.setUint8(1, encrypType);
    byteData.setUint32(2, dataBuffer.length, Endian.little);

    BytesBuilder builder = BytesBuilder();
    builder.add(byteData.buffer.asUint8List());
    builder.add(dataBuffer.toBytes());

    return builder.toBytes();
  }

  bool addData(Uint8List data) {
    if (data.length + dataBuffer.length > dataLen) {
      return false;
    }
    dataBuffer.add(data);
    return true;
  }

  static const int typeLen = 6;

  static SimpleCtrlHandlePack factory(Uint8List data) {
    ByteData byteData = data.buffer.asByteData();
    int dataType = byteData.getUint8(0);
    int encrypType = byteData.getUint8(1);
    int dataLen = byteData.getUint32(2, Endian.little);

    return SimpleCtrlHandlePack(dataType, encrypType, dataLen);
  }
}

class SimpleCtrlDataNotifier extends ChangeNotifier {
  Queue<Uint8List> dataQueue = Queue<Uint8List>();
  Completer? _completer;
  final int queueLength;

  SimpleCtrlDataNotifier(this.queueLength);

  void add(Uint8List data) {
    if (dataQueue.length == queueLength) {
      developer.log('Data is full', name: _logName);
      return;
    }
    dataQueue.add(data);
    notifyListeners();
    if (_completer != null) _completer!.complete();
  }

  Future<void> wait() async {
    if (dataQueue.isEmpty) {
      _completer = Completer();
      await _completer!.future;
      _completer = null;
    }
  }
}

class SimpleCtrlHandle {
  static const int stateInit = 0; // Init
  static const int stateConnecting = 1; // Connecting
  static const int stateConnected = 2; // Connected
  static const int stateDisconnected = 3; // Disconnected
  static const int stateFailed = 4; // Failed

  static const int _ctrlDataTypePing = 0x00;
  static const int _ctrlDataTypeInfo = 0x01;
  static const int _ctrlDataTypeRequest = 0x02;
  static const int _ctrlDataTypeNotify = 0x03;
  static const int _ctrlDataTypeMax = 0x04;

  static const String _ctrlDataHeaderString = 'HOOZZ';
  static final Uint8List _ctrlDataHeader =
      Uint8List.fromList(_ctrlDataHeaderString.codeUnits);

  final List<SimpleCtrlDataNotifier> _dataNotifier =
      List.filled(_ctrlDataTypeMax, SimpleCtrlDataNotifier(20));

  final DiscoverDeviceInfo _discoverDeviceInfo;

  final ValueNotifier<int> stateNotifier = ValueNotifier<int>(stateInit);

  Socket? _tcpSocket;

  final int _pingInterval = 5;

  Timer? _pingTimer;

  SimpleCtrlHandle(this._discoverDeviceInfo);

  SimpleCtrlDataNotifier get notifyNotifier =>
      _dataNotifier[_ctrlDataTypeNotify];

  Uint8List _buildPingPackData() {
    SimpleCtrlHandlePack simpleCtrlHandlePack =
        SimpleCtrlHandlePack(_ctrlDataTypePing, 0, 0);
    return simpleCtrlHandlePack.pack();
  }

  SimpleCtrlHandlePack? _currentParsePack;
  final Queue<int> _dataQueue = Queue<int>();

  void _handlerPack(SimpleCtrlHandlePack pack) {
    developer.log('Pack load: ${pack.loadData}', name: _logName);

    if (pack.dataType >= _ctrlDataTypeMax) {
      developer.log('Data type incorrect', name: _logName);
      return;
    }

    Uint8List dataHeader = pack.loadData.sublist(0, _ctrlDataHeader.length);
    Uint8List data = pack.loadData.sublist(_ctrlDataHeader.length);
    // developer.log('$dataHeader + $data', name: _logName);

    String header = String.fromCharCodes(dataHeader);
    if (header != _ctrlDataHeaderString) {
      developer.log('Data header incorrect: $header != $_ctrlDataHeaderString',
          name: _logName);
      return;
    }

    _dataNotifier[pack.dataType].add(data);
  }

  void _parsePack(Uint8List data) {
    // developer.log('Read: $data', name: _logName);
    // Push to FIFO
    for (int item in data) {
      _dataQueue.add(item);
    }

    if (_currentParsePack == null) {
      if (_dataQueue.length >= SimpleCtrlHandlePack.typeLen) {
        Uint8List typeData = Uint8List(SimpleCtrlHandlePack.typeLen);
        for (int i = 0; i < SimpleCtrlHandlePack.typeLen; i++) {
          typeData[i] = _dataQueue.removeFirst();
        }
        // developer.log('Type data: $typeData', name: _logName);
        // Start
        _currentParsePack = SimpleCtrlHandlePack.factory(typeData);
        developer.log(
            'Pack: dataType ${_currentParsePack!.dataType}, encrypType ${_currentParsePack!.encrypType}, dataLen ${_currentParsePack!.dataLen}',
            name: _logName);
      }
    }

    if (_currentParsePack != null &&
        _dataQueue.length >= _currentParsePack!.dataLen) {
      if (_currentParsePack!.dataLen > 0) {
        Uint8List loadData = Uint8List(_currentParsePack!.dataLen);
        for (int i = 0; i < _currentParsePack!.dataLen; i++) {
          loadData[i] = _dataQueue.removeFirst();
        }
        // developer.log('Add data: $loadData', name: _logName);
        _currentParsePack!.addData(loadData);
        // Handler pack
        _handlerPack(_currentParsePack!);
        // End
        _currentParsePack = null;
      } else {
        // End
        _currentParsePack = null;
      }
    }
  }

  Future<void> _write(Uint8List data) async {
    try {
      // developer.log('Write: $data', name: _logName);
      // _tcpSocket.write('Hello!');
      _tcpSocket!.add(data);
    } catch (e) {
      developer.log('Write exception', name: _logName);
    }
  }

  Uint8List _buildRequestPackData(Uint8List data) {
    SimpleCtrlHandlePack simpleCtrlHandlePack = SimpleCtrlHandlePack(
        _ctrlDataTypeRequest, 0, _ctrlDataHeader.length + data.length);
    simpleCtrlHandlePack.addData(_ctrlDataHeader);
    simpleCtrlHandlePack.addData(data);
    return simpleCtrlHandlePack.pack();
  }

  Future<bool> request(Uint8List data) async {
    Uint8List packData = _buildRequestPackData(data);
    await _write(packData);
    return true;
  }

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
      // _tcpSocket.drain().then((_) => destroyHandle());
      // Listen data and disconnected
      _tcpSocket!
          .listen(
            (Uint8List data) => _parsePack(data),
            onDone: () {},
            onError: (error) {},
            cancelOnError: true,
          )
          .asFuture()
          .then((_) => destroyHandle());
    } catch (e) {
      stateNotifier.value = stateFailed;
      developer.log(
          'Connection failed: ${_discoverDeviceInfo.ip}:${_discoverDeviceInfo.port}',
          name: _logName);
      return false;
    }

    final Uint8List pingData = _buildPingPackData();
    // ping remote
    _pingTimer =
        Timer.periodic(Duration(seconds: _pingInterval), (Timer timer) {
      developer.log('Connect ping', name: _logName);
      _write(pingData);
    });

    return true;
  }

  void destroyHandle() {
    if (stateNotifier.value == stateDisconnected) return;
    stateNotifier.value = stateDisconnected;
    developer.log(
        'Disconnected: ${_discoverDeviceInfo.ip}:${_discoverDeviceInfo.port}',
        name: _logName);
    try {
      _pingTimer!.cancel();
      _pingTimer = null;
      _tcpSocket!.close();
      _tcpSocket = null;
    } catch (e) {
      developer.log('Close socket exception', name: _logName);
    }
  }
}
