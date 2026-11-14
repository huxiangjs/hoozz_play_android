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
  bool hasPassword;
  int cryptoType;
  String name;
  DateTime time;

  DiscoverDeviceInfo(
    this.id,
    this.ip,
    this.port,
    this.classId,
    this.hasPassword,
    this.cryptoType,
    this.name,
    this.time,
  );
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
  final int _discoverSendUDPPort = 54542;
  final int _discoverRecvUDPPort = 54543;
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
        InternetAddress.anyIPv4,
        _discoverRecvUDPPort,
      );
      _udpSocket.broadcastEnabled = true;

      // Read data
      _udpSocket.listen((e) {
        try {
          Datagram? dg = _udpSocket.receive();
          if (dg != null) {
            // developer.log('received: ${dg.data}', name: _logName);
            int endIndex = 0;
            for (endIndex = 0; endIndex < dg.data.length; endIndex++) {
              if (dg.data[endIndex] == 0) break;
            }
            String data = utf8.decode(dg.data.sublist(0, endIndex));
            String ip = dg.address.address;
            int port = dg.port;
            if (data.startsWith(_discoverRespond)) {
              int start = _discoverRespond.length;
              String classId = data.substring(start, start + 2);
              start += 2;
              int cryptoType = int.parse(
                data.substring(start, start + 2),
                radix: 16,
              );
              start += 2;
              // '-': no password; '*': has a password
              bool hasPassword = data.substring(start, start + 1) != '-';
              start += 1;
              String id = data.substring(start, start + _idLength);
              start += _idLength;
              String name = data.substring(start);
              DateTime time = DateTime.now();
              // Read this parameter when using the discovery proxy
              if (dg.data.length - endIndex > 7) {
                String realIp = utf8.decode(dg.data.sublist(endIndex + 1));
                developer.log('real ip: $realIp', name: _logName);
                ip = realIp;
              }
              // developer.log(
              //     '[$ip:$port] CLASS:$classId ID:$id NAME:$name TIME:${time.toString()}',
              //     name: _logName);
              if (id.length == _idLength) {
                int classIdNum = int.parse(classId, radix: 16);
                deviceListNotifier.set(
                  id,
                  DiscoverDeviceInfo(
                    id,
                    ip,
                    port,
                    classIdNum,
                    hasPassword,
                    cryptoType,
                    name,
                    time,
                  ),
                );
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
    // for discovery proxy
    InternetAddress destinationProxyAddress = InternetAddress("10.0.0.1");

    void sayHello(Timer timer) {
      developer.log('Say hello', name: _logName);
      () async {
        for (int i = 0; i < 5; i++) {
          try {
            _udpSocket.send(data, destinationAddress, _discoverSendUDPPort);
            // for discovery proxy
            _udpSocket.send(
              data,
              destinationProxyAddress,
              _discoverSendUDPPort,
            );
            await Future.delayed(const Duration(seconds: 0, milliseconds: 100));
          } catch (e) {
            developer.log('Send exception', name: _logName);
          }
        }
      }.call();
    }

    // Interval call
    _discoverTimer = Timer.periodic(
      Duration(seconds: _discoveryInterval),
      sayHello,
    );
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
  final int loadType;
  final Crypto crypto;
  final int loadLen;

  _SimpleCtrlHandlePack(this.loadType, this.crypto, this.loadLen);

  Uint8List get loadData => crypto.done();

  static const int typeLen = 5;

  Uint8List pack() {
    ByteData byteData = ByteData(typeLen);
    byteData.setUint8(0, loadType);
    Uint8List lodeData = loadData;
    byteData.setUint32(1, lodeData.length, Endian.little);

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

  static _SimpleCtrlHandlePack? factory(
    Uint8List data,
    int cryptoType,
    Uint8List? passwd,
  ) {
    ByteData byteData = data.buffer.asByteData();
    int loadType = byteData.getUint8(0);
    int loadLen = byteData.getUint32(1, Endian.little);
    Crypto? crypto = Crypto.getCrypto(cryptoType, passwd);

    if (crypto == null) {
      developer.log(
        'Unsupported encryption method: $cryptoType',
        name: _logName,
      );
      return null;
    }
    return _SimpleCtrlHandlePack(loadType, crypto, loadLen);
  }
}

class SimpleCtrlDataNotifier extends ChangeNotifier {
  final Queue<Uint8List> _dataQueue = Queue<Uint8List>();
  final Queue<Completer<Uint8List>> _completerQueue =
      Queue<Completer<Uint8List>>();

  void addData(Uint8List data) {
    if (_completerQueue.isNotEmpty) {
      // A pending request owns this response (the device answers in
      // request order, so the FIFO matching stays in sync); complete it
      // directly with the data
      _completerQueue.removeFirst().complete(data);
    } else {
      // No pending request: keep the data for the listeners (e.g. the
      // notify type)
      _dataQueue.add(data);
      notifyListeners();
    }
  }

  Uint8List getData() {
    return _dataQueue.removeFirst();
  }

  Future<Uint8List?> waitData(
    int timeout,
    Function? ready, [
    Function? then,
  ]) async {
    Uint8List? retVal;
    Completer<Uint8List> completer = Completer<Uint8List>();
    _completerQueue.add(completer);
    if (ready != null) ready();
    try {
      retVal = await completer.future.timeout(Duration(seconds: timeout));
      if (then != null) then(retVal);
    } catch (e) {
      // Timed out: drop the stale completer so a late response cannot
      // be handed to a later request (which would desynchronize the
      // request/response matching)
      _completerQueue.remove(completer);
      retVal = null;
    }
    return retVal;
  }

  ///
  /// Discard the pending requests and the queued data. Called when the
  /// handle is destroyed so a re-initialized handle starts with a clean
  /// queue (a late response of the old session must not be matched to a
  /// request of the next one).
  ///
  void reset() {
    _completerQueue.clear();
    _dataQueue.clear();
  }
}

class SimpleCtrlHandle {
  static const int stateInit = 0; // Init
  static const int stateConnected = 1; // Connected
  static const int stateDestroy = 2; // Destroy

  static const int _ctrlLoadTypePing = 0x00;
  static const int _ctrlLoadTypeInfo = 0x01;
  static const int _ctrlLoadTypeRequest = 0x02;
  static const int _ctrlLoadTypeNotify = 0x03;
  static const int _ctrlLoadTypeMax = 0x04;

  static const int _ctrlInfoTypeGetName = 0x00;
  static const int _ctrlInfoTypeSetName = 0x01;
  static const int _ctrlInfoTypeGetClassId = 0x02;
  static const int _ctrlInfoTypeSetPasswd = 0x03;
  static const int _ctrlInfoTypeFwVersion = 0x04;
  static const int _ctrlInfoTypeFwUpgrade = 0x05;
  static const int _ctrlInfoTypeFwProgress = 0x06;

  final int _ctrlReturnOk = 0x00;
  final int _ctrlReturnFail = 0x01;

  static const int _ctrlLoadHeaderSize = 16;
  static const String _ctrlLoadMagicString = 'HOOZZ';
  static final Uint8List _ctrlLoadMagic = Uint8List.fromList(
    _ctrlLoadMagicString.codeUnits,
  );

  static const int accessKeyLength = 16;

  final List<SimpleCtrlDataNotifier> _dataNotifier =
      List<SimpleCtrlDataNotifier>.generate(
        _ctrlLoadTypeMax,
        (index) => SimpleCtrlDataNotifier(),
      );

  final DiscoverDeviceInfo _discoverDeviceInfo;
  final DeviceInfo _deviceInfo;
  Uint8List? _accessKey;
  late int _cryptoType;

  final ValueNotifier<int> stateNotifier = ValueNotifier<int>(stateInit);

  ///
  /// Set when the user deliberately cancels an operation (e.g. an OTA
  /// transfer) that makes the device drop the control connection as a
  /// side effect. The next destroy is consumed by [maybeReconnect] so
  /// the page reconnects in place instead of being popped off the stack.
  ///
  bool _expectDisconnect = false;

  ///
  /// A [maybeReconnect] is in progress; the page's state listener must
  /// not handle the destroys in between (the final outcome is reported
  /// by [maybeReconnect]).
  ///
  bool _reconnecting = false;

  ///
  /// Incremented for every successful session. A stale ping callback of
  /// a previous session (its pending request was dropped by
  /// [destroyHandle]) must not tear down the current session when it
  /// times out.
  ///
  int _generation = 0;

  Socket? _tcpSocket;

  final int _pingInterval = 5;

  Timer? _pingTimer;

  SimpleCtrlHandle(this._discoverDeviceInfo, this._deviceInfo) {
    if (_deviceInfo.accessKey.isNotEmpty) {
      List<int> list = _deviceInfo.accessKey.codeUnits;
      _accessKey = Uint8List.fromList(list);
    }
    _cryptoType = _discoverDeviceInfo.cryptoType;
  }

  SimpleCtrlDataNotifier get notifyNotifier =>
      _dataNotifier[_ctrlLoadTypeNotify];

  Uint8List _buildLoadHeader(int dataLen) {
    ByteData byteData = ByteData(_ctrlLoadHeaderSize);
    // Set magic
    for (int index = 0; index < _ctrlLoadMagic.length; index++) {
      byteData.setUint8(index, _ctrlLoadMagic[index]);
    }
    // Set data length
    byteData.setUint32(12, dataLen, Endian.little);
    return byteData.buffer.asUint8List();
  }

  Uint8List _buildPingPackData() {
    Crypto? crypto = Crypto.getCrypto(_cryptoType, _accessKey);
    if (crypto == null) return Uint8List(0);
    _SimpleCtrlHandlePack simpleCtrlHandlePack = _SimpleCtrlHandlePack(
      _ctrlLoadTypePing,
      crypto,
      _ctrlLoadHeaderSize + 1,
    );
    // Set header
    simpleCtrlHandlePack.addData(_buildLoadHeader(1));
    // Set data
    ByteData byteData = ByteData(1);
    byteData.setUint8(0, _pingInterval);
    Uint8List data = byteData.buffer.asUint8List();
    simpleCtrlHandlePack.addData(data);

    return simpleCtrlHandlePack.pack();
  }

  _SimpleCtrlHandlePack? _currentParsePack;
  final Queue<int> _dataQueue = Queue<int>();

  void _handlerPack(_SimpleCtrlHandlePack pack) {
    // developer.log('Pack load: ${pack.loadData}', name: _logName);

    if (pack.loadType >= _ctrlLoadTypeMax) {
      developer.log('Load type incorrect', name: _logName);
      return;
    }

    /* |--Magic(6bytes)--|--Reserved(6bytes)--|--Data size(4bytes)--| */
    Uint8List load = pack.loadData;
    if (load.length < _ctrlLoadHeaderSize) {
      developer.log('Load heander length incorrect', name: _logName);
      return;
    }

    Uint8List header = load.sublist(0, _ctrlLoadHeaderSize);
    Uint8List loadMagic = header.sublist(0, _ctrlLoadMagic.length);
    ByteData byteData = header.buffer.asByteData();
    int dataLen = byteData.getUint32(12, Endian.little);
    if (load.length < _ctrlLoadHeaderSize + dataLen) {
      developer.log('Load data length incorrect', name: _logName);
      return;
    }

    Uint8List data = load.sublist(
      _ctrlLoadHeaderSize,
      _ctrlLoadHeaderSize + dataLen,
    );
    // developer.log('$data', name: _logName);

    String magic = String.fromCharCodes(loadMagic);
    if (magic != _ctrlLoadMagicString) {
      developer.log(
        'Magic incorrect: $magic != $_ctrlLoadMagicString',
        name: _logName,
      );
      return;
    }

    // developer.log('Add data to: ${pack.loadType}', name: _logName);
    _dataNotifier[pack.loadType].addData(data);
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
        _currentParsePack = _SimpleCtrlHandlePack.factory(
          typeData,
          _cryptoType,
          _accessKey,
        );
        if (_currentParsePack != null) {
          developer.log(
            'Pack: loadType ${_currentParsePack!.loadType}, loadLen ${_currentParsePack!.loadLen}',
            name: _logName,
          );
        }
      }

      if (_currentParsePack != null &&
          _dataQueue.length >= _currentParsePack!.loadLen) {
        if (_currentParsePack!.loadLen > 0) {
          Uint8List loadData = Uint8List(_currentParsePack!.loadLen);
          for (int i = 0; i < _currentParsePack!.loadLen; i++) {
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
    Crypto? crypto = Crypto.getCrypto(_cryptoType, _accessKey);
    if (crypto == null) return Uint8List(0);
    _SimpleCtrlHandlePack simpleCtrlHandlePack = _SimpleCtrlHandlePack(
      _ctrlLoadTypeRequest,
      crypto,
      _ctrlLoadHeaderSize + data.length,
    );
    // Set header
    simpleCtrlHandlePack.addData(_buildLoadHeader(data.length));
    // Set data
    simpleCtrlHandlePack.addData(data);
    return simpleCtrlHandlePack.pack();
  }

  Uint8List _buildTypeInfoPackData(int cmd, Uint8List data) {
    Crypto? crypto = Crypto.getCrypto(_cryptoType, _accessKey);
    if (crypto == null) return Uint8List(0);
    _SimpleCtrlHandlePack simpleCtrlHandlePack = _SimpleCtrlHandlePack(
      _ctrlLoadTypeInfo,
      crypto,
      _ctrlLoadHeaderSize + 1 + data.length,
    );
    // Set header
    simpleCtrlHandlePack.addData(_buildLoadHeader(1 + data.length));
    // Set cmd
    ByteData byteData = ByteData(1);
    byteData.setUint8(0, cmd);
    simpleCtrlHandlePack.addData(byteData.buffer.asUint8List());
    // Set data
    simpleCtrlHandlePack.addData(data);
    return simpleCtrlHandlePack.pack();
  }

  Future<bool> setName(String name) async {
    Uint8List data = utf8.encode(name);
    if (data.length > 64) {
      developer.log(
        'Name must be less than or equal to 64 bytes. (${data.length})',
        name: _logName,
      );
      return false;
    }

    Uint8List setData = _buildTypeInfoPackData(_ctrlInfoTypeSetName, data);
    await _dataNotifier[_ctrlLoadTypeInfo]
        .waitData(5, () => _write(setData))
        .then((Uint8List? value) {
          if (value != null &&
              value.length == 2 &&
              value[0] == _ctrlInfoTypeSetName &&
              value[1] == _ctrlReturnOk) {
            developer.log('Set name done', name: _logName);
          } else {
            developer.log('Set name failed, retVal: $value', name: _logName);
            return false;
          }
        });

    return true;
  }

  Future<bool> setPassword(String passwd) async {
    Uint8List data = utf8.encode(passwd);
    if (data.length > 16) {
      developer.log(
        'Key must be less than or equal to 16 bytes. (${data.length})',
        name: _logName,
      );
      return false;
    }

    Uint8List setData = _buildTypeInfoPackData(_ctrlInfoTypeSetPasswd, data);
    await _dataNotifier[_ctrlLoadTypeInfo]
        .waitData(5, () => _write(setData))
        .then((Uint8List? value) {
          if (value != null &&
              value.length == 2 &&
              value[0] == _ctrlInfoTypeSetPasswd &&
              value[1] == _ctrlReturnOk) {
            developer.log('Set password done', name: _logName);
          } else {
            developer.log(
              'Set password failed, retVal: $value',
              name: _logName,
            );
            return false;
          }
        });

    return true;
  }

  ///
  /// Query the device's firmware version (the git hash the image was
  /// built from, possibly with a "-dirty" suffix).
  ///
  /// Returns the version string, or null when the device does not support
  /// OTA (old firmware, the command is rejected) or the request fails.
  ///
  Future<String?> fwVersion() async {
    Uint8List setData =
        _buildTypeInfoPackData(_ctrlInfoTypeFwVersion, Uint8List(0));
    String? version;
    bool ok = false;
    await _dataNotifier[_ctrlLoadTypeInfo]
        .waitData(5, () => _write(setData))
        .then((Uint8List? value) {
      if (value != null &&
          value.length >= 2 &&
          value[0] == _ctrlInfoTypeFwVersion &&
          value[1] == _ctrlReturnOk) {
        version = utf8.decode(value.sublist(2), allowMalformed: true);
        ok = true;
      }
    });
    if (!ok) {
      developer.log('Get fw version failed', name: _logName);
      return null;
    }
    final String trimmed = version!.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  ///
  /// Ask the device to start an OTA transfer from [url]
  /// ("hoozz://<key>/<port>").
  ///
  /// Returns true when the device accepted the request, false when it
  /// refused (it is busy - typically the 30 s accept window of a
  /// previously interrupted OTA) or the request failed.
  ///
  Future<bool> fwUpgrade(String url) async {
    Uint8List setData =
        _buildTypeInfoPackData(_ctrlInfoTypeFwUpgrade, utf8.encode(url));
    bool ok = false;
    await _dataNotifier[_ctrlLoadTypeInfo]
        .waitData(5, () => _write(setData))
        .then((Uint8List? value) {
      if (value != null &&
          value.length == 2 &&
          value[0] == _ctrlInfoTypeFwUpgrade &&
          value[1] == _ctrlReturnOk) {
        ok = true;
      }
    });
    developer.log('Fw upgrade ${ok ? 'accepted' : 'refused'}', name: _logName);
    return ok;
  }

  ///
  /// Query the OTA transfer progress (0-100).
  ///
  /// Returns the progress, or -1 when the device does not support OTA,
  /// the request times out, or the control channel is gone.
  ///
  Future<int> fwProgress() async {
    Uint8List setData =
        _buildTypeInfoPackData(_ctrlInfoTypeFwProgress, Uint8List(0));
    int progress = -1;
    try {
      await _dataNotifier[_ctrlLoadTypeInfo]
          .waitData(5, () => _write(setData))
          .then((Uint8List? value) {
        if (value != null &&
            value.length >= 3 &&
            value[0] == _ctrlInfoTypeFwProgress &&
            value[1] == _ctrlReturnOk) {
          progress = value[2];
        }
      });
    } catch (e) {
      // The control channel is gone (e.g. the device is rebooting)
      progress = -1;
    }
    return progress;
  }

  Future<Uint8List?> request(Uint8List data, bool existReturn) async {
    Uint8List? retVal;
    Uint8List packData = _buildRequestPackData(data);
    if (existReturn) {
      await _dataNotifier[_ctrlLoadTypeRequest].waitData(
        5,
        () => _write(packData),
        (value) => retVal = value,
      );
    } else {
      await _write(packData);
    }
    return retVal;
  }

  Future<bool> initHandle() async {
    try {
      developer.log(
        'Connecting: ${_discoverDeviceInfo.ip}:${_discoverDeviceInfo.port}',
        name: _logName,
      );
      _tcpSocket = await Socket.connect(
        _discoverDeviceInfo.ip,
        _discoverDeviceInfo.port,
      );
      developer.log(
        'Connected: ${_discoverDeviceInfo.ip}:${_discoverDeviceInfo.port}',
        name: _logName,
      );
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
    // Each successful session gets a generation; a stale ping callback of
    // a previous session (its pending request was dropped by
    // destroyHandle's queue reset) must not tear down this session when
    // it times out
    final int generation = ++_generation;
    // ping remote
    _pingTimer = Timer.periodic(Duration(seconds: _pingInterval), (
      Timer timer,
    ) {
      if (generation != _generation) return;
      // developer.log('Ping start', name: _logName);
      _dataNotifier[_ctrlLoadTypePing]
          .waitData(10, () => _write(pingData))
          .then((Uint8List? value) {
            if (generation != _generation) return;
            if (value != null &&
                value.length == 1 &&
                value[0] == _ctrlReturnOk) {
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
      name: _logName,
    );
    try {
      // Both fields may be null (a failed initHandle also calls this)
      _pingTimer?.cancel();
      _pingTimer = null;
      _tcpSocket?.close();
      _tcpSocket = null;
    } catch (e) {
      developer.log('Close socket exception', name: _logName);
    }
    // Drop the parse state and the pending request/response queues so a
    // re-initialized session starts clean (a late packet of the old
    // session must not be matched to a request of the next one)
    _currentParsePack = null;
    _dataQueue.clear();
    for (final SimpleCtrlDataNotifier notifier in _dataNotifier) {
      notifier.reset();
    }
  }

  ///
  /// Mark the next destroy as expected (the user deliberately cancelled an
  /// operation that makes the device drop the control connection as a side
  /// effect). The page's state listener then reconnects the same handle in
  /// place instead of leaving the page.
  ///
  void expectDisconnect() {
    _expectDisconnect = true;
  }

  ///
  /// A [maybeReconnect] is in progress.
  ///
  bool get reconnecting => _reconnecting;

  ///
  /// Abort a pending [maybeReconnect] (the page is being disposed, so no
  /// further destroy should be turned into a reconnect).
  ///
  void cancelReconnect() {
    _reconnecting = false;
    _expectDisconnect = false;
  }

  ///
  /// Reconnect this same handle in place: a fresh socket, the state goes
  /// back to connected, and every existing reference to the handle stays
  /// valid. Retried a few times because the device's accept loop is briefly
  /// busy right after an interrupted OTA transfer. Returns true when the
  /// reconnect succeeded.
  ///
  Future<bool> maybeReconnect() async {
    // Consume the mark synchronously so the destroy that triggered this
    // (and any racing one) is not treated as expected twice
    final bool expected = _expectDisconnect;
    _expectDisconnect = false;
    if (!expected) return false;
    _reconnecting = true;
    try {
      for (int attempt = 0; attempt < 3; attempt++) {
        if (!_reconnecting) return false; // The page gave up
        final bool ok = await initHandle();
        if (!_reconnecting) {
          // The page was disposed while initHandle was in flight (on a
          // reconnect there is no modal dialog blocking navigation away);
          // tear down the session it just created (orphaned socket + ping
          // timer)
          destroyHandle();
          return false;
        }
        if (ok) return true;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      return false;
    } finally {
      _reconnecting = false;
    }
  }
}
