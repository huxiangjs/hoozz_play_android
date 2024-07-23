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
import 'package:hoozz_play/core/crypto.dart';
import 'package:hoozz_play/core/device_storage.dart';

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

    developer.log('Start SimpleCtrl Discovery', name: _logName);

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

    developer.log('Stop SimpleCtrl Discovery', name: _logName);
    _discoverRunning = false;
  }
}

class _SimpleCtrlHandlePack {
  final int dataType;
  final Crypto crypto;
  final int dataLen;

  _SimpleCtrlHandlePack(this.dataType, this.crypto, this.dataLen);

  Uint8List get loadData => crypto.done();

  Uint8List pack() {
    ByteData byteData = ByteData(6);
    byteData.setUint8(0, dataType);
    byteData.setUint8(1, crypto.cryptoType);
    Uint8List lodeData = loadData;
    byteData.setUint32(2, lodeData.length, Endian.little);

    BytesBuilder builder = BytesBuilder();
    builder.add(byteData.buffer.asUint8List());
    builder.add(lodeData);

    return builder.toBytes();
  }

  bool addData(Uint8List data, [bool encrypto = true]) {
    bool retVal = false;
    if (encrypto) {
      retVal = crypto.en(data);
    } else {
      retVal = crypto.de(data);
    }
    return retVal;
  }

  static const int typeLen = 6;

  static _SimpleCtrlHandlePack? factory(Uint8List data, Uint8List? passwd) {
    ByteData byteData = data.buffer.asByteData();
    int dataType = byteData.getUint8(0);
    int cryptoType = byteData.getUint8(1);
    int dataLen = byteData.getUint32(2, Endian.little);

    if (cryptoType != Crypto.typeXOR) {
      developer.log('Mismatched encryption method: $cryptoType',
          name: _logName);
      return null;
    }

    return _SimpleCtrlHandlePack(dataType, CryptoXOR(passwd), dataLen);
  }
}

class SimpleCtrlDataNotifier extends ChangeNotifier {
  final Queue<Uint8List> _dataQueue = Queue<Uint8List>();
  final Queue<Completer> _completerQueue = Queue<Completer>();

  void addData(Uint8List data) {
    // Add data
    _dataQueue.add(data);
    notifyListeners();
    // Set complete
    if (_completerQueue.isNotEmpty) _completerQueue.removeFirst().complete();
  }

  Uint8List getData() {
    return _dataQueue.removeFirst();
  }

  Future<Uint8List?> waitData(int timeout, Function? ready,
      [Function? then]) async {
    Uint8List? retVal;
    Completer completer = Completer();
    _completerQueue.add(completer);
    if (ready != null) ready();
    try {
      await completer.future.timeout(Duration(seconds: timeout));
      retVal = getData();
      if (then != null) then(retVal);
    } catch (e) {
      retVal = null;
    }
    return retVal;
  }
}

class SimpleCtrlHandle {
  static const int stateInit = 0; // Init
  static const int stateConnected = 1; // Connected
  static const int stateDestroy = 2; // Destroy

  static const int _ctrlDataTypePing = 0x00;
  static const int _ctrlDataTypeInfo = 0x01;
  static const int _ctrlDataTypeRequest = 0x02;
  static const int _ctrlDataTypeNotify = 0x03;
  static const int _ctrlDataTypeMax = 0x04;

  final int _ctrlReturnOk = 0x00;
  final int _ctrlReturnFail = 0x01;

  static const String _ctrlDataHeaderString = 'HOOZZ';
  static final Uint8List _ctrlDataHeader =
      Uint8List.fromList(_ctrlDataHeaderString.codeUnits);

  final List<SimpleCtrlDataNotifier> _dataNotifier =
      List<SimpleCtrlDataNotifier>.generate(
          _ctrlDataTypeMax, (index) => SimpleCtrlDataNotifier());

  final DiscoverDeviceInfo _discoverDeviceInfo;
  final DeviceInfo _deviceInfo;
  Uint8List? _accessKey;

  final ValueNotifier<int> stateNotifier = ValueNotifier<int>(stateInit);

  Socket? _tcpSocket;

  final int _pingInterval = 5;

  Timer? _pingTimer;

  SimpleCtrlHandle(this._discoverDeviceInfo, this._deviceInfo) {
    if (_deviceInfo.accessKey.isNotEmpty) {
      List<int> list = _deviceInfo.accessKey.codeUnits;
      _accessKey = Uint8List.fromList(list);
    }
  }

  SimpleCtrlDataNotifier get notifyNotifier =>
      _dataNotifier[_ctrlDataTypeNotify];

  Uint8List _buildPingPackData() {
    _SimpleCtrlHandlePack simpleCtrlHandlePack = _SimpleCtrlHandlePack(
        _ctrlDataTypePing, CryptoXOR(_accessKey), _ctrlDataHeader.length + 1);

    ByteData byteData = ByteData(1);
    byteData.setUint8(0, _pingInterval);
    Uint8List data = byteData.buffer.asUint8List();

    simpleCtrlHandlePack.addData(_ctrlDataHeader);
    simpleCtrlHandlePack.addData(data);

    return simpleCtrlHandlePack.pack();
  }

  _SimpleCtrlHandlePack? _currentParsePack;
  final Queue<int> _dataQueue = Queue<int>();

  void _handlerPack(_SimpleCtrlHandlePack pack) {
    // developer.log('Pack load: ${pack.loadData}', name: _logName);

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

    // developer.log('Add data to: ${pack.dataType}', name: _logName);
    _dataNotifier[pack.dataType].addData(data);
  }

  void _parsePack(Uint8List data) {
    // developer.log('Read: $data', name: _logName);
    // Push to FIFO
    for (int item in data) {
      _dataQueue.add(item);
    }

    while (true) {
      if (_currentParsePack == null &&
          _dataQueue.length >= _SimpleCtrlHandlePack.typeLen) {
        Uint8List typeData = Uint8List(_SimpleCtrlHandlePack.typeLen);
        for (int i = 0; i < _SimpleCtrlHandlePack.typeLen; i++) {
          typeData[i] = _dataQueue.removeFirst();
        }
        // developer.log('Type data: $typeData', name: _logName);
        // Start
        _currentParsePack = _SimpleCtrlHandlePack.factory(typeData, _accessKey);
        if (_currentParsePack != null) {
          developer.log(
              'Pack: dataType ${_currentParsePack!.dataType}, dataLen ${_currentParsePack!.dataLen}',
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
          _currentParsePack!.addData(loadData, false);
          // Handler pack
          _handlerPack(_currentParsePack!);
          // End
          _currentParsePack = null;
        } else {
          // End
          _currentParsePack = null;
        }
      } else {
        // Not enough data
        break;
      }
    }
    // developer.log('FIFO length: ${_dataQueue.length}', name: _logName);
  }

  Future<void> _write(Uint8List data) async {
    try {
      // developer.log('Write: $data', name: _logName);
      // _tcpSocket.write('Hello!');
      _tcpSocket!.add(data);
      // developer.log('Write OK', name: _logName);
    } catch (e) {
      developer.log('Write exception', name: _logName);
    }
  }

  Uint8List _buildRequestPackData(Uint8List data) {
    _SimpleCtrlHandlePack simpleCtrlHandlePack = _SimpleCtrlHandlePack(
        _ctrlDataTypeRequest,
        CryptoXOR(_accessKey),
        _ctrlDataHeader.length + data.length);
    simpleCtrlHandlePack.addData(_ctrlDataHeader);
    simpleCtrlHandlePack.addData(data);
    return simpleCtrlHandlePack.pack();
  }

  Future<Uint8List?> request(Uint8List data, bool existReturn) async {
    Uint8List? retVal;
    Uint8List packData = _buildRequestPackData(data);
    if (existReturn) {
      await _dataNotifier[_ctrlDataTypeRequest]
          .waitData(5, () => _write(packData), (value) => retVal = value);
    } else {
      await _write(packData);
    }
    return retVal;
  }

  Future<bool> initHandle() async {
    try {
      developer.log(
          'Connecting: ${_discoverDeviceInfo.ip}:${_discoverDeviceInfo.port}',
          name: _logName);
      _tcpSocket = await Socket.connect(
          _discoverDeviceInfo.ip, _discoverDeviceInfo.port);
      developer.log(
          'Connected: ${_discoverDeviceInfo.ip}:${_discoverDeviceInfo.port}',
          name: _logName);
      stateNotifier.value = stateConnected;
      // Listen disconnected
      // _tcpSocket.drain().then((_) => destroyHandle());
      // Listen data and disconnected
      _tcpSocket!
          .listen(
            (Uint8List data) => _parsePack(data),
            onDone: () => destroyHandle(),
            onError: (error) => destroyHandle(),
            cancelOnError: true,
          )
          .asFuture()
          .catchError((error) => destroyHandle());
      _tcpSocket!.done.catchError((error) => destroyHandle());
      _tcpSocket!.done.onError((error, stackTrace) => destroyHandle());
    } catch (e) {
      destroyHandle();
      return false;
    }

    final Uint8List pingData = _buildPingPackData();
    // ping remote
    _pingTimer =
        Timer.periodic(Duration(seconds: _pingInterval), (Timer timer) {
      // developer.log('Ping start', name: _logName);
      _dataNotifier[_ctrlDataTypePing]
          .waitData(10, () => _write(pingData))
          .then((Uint8List? value) {
        if (value != null && value.length == 1 && value[0] == _ctrlReturnOk) {
          developer.log('Ping done', name: _logName);
        } else {
          developer.log('Ping failed, retVal: $value', name: _logName);
          destroyHandle();
        }
      });
    });

    return true;
  }

  void destroyHandle() {
    if (stateNotifier.value == stateDestroy) return;
    stateNotifier.value = stateDestroy;
    developer.log(
        'Destroy: ${_discoverDeviceInfo.ip}:${_discoverDeviceInfo.port}',
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
