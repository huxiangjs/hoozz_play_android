///
/// Created on 2025/7/26
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoozz_play/core/device_binding.dart';
import 'package:hoozz_play/core/device_config.dart';
import 'package:hoozz_play/core/parameter_stateful.dart';
import 'package:hoozz_play/core/simple_showdialog.dart';
import 'package:hoozz_play/core/simple_progress_dialog.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'package:hoozz_play/core/device_storage.dart';
import 'package:hoozz_play/core/simple_snackbar.dart';
import 'package:hoozz_play/core/tcp_crypto.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;

import 'package:hoozz_play/themes/theme.dart';

const String _logName = 'Smart IR';

///
/// AES128-CBC encrypted key transfer over the device tunnel (port 54550).
///
/// The encrypted frame transport (core/tcp_crypto.dart) is wrapped here
/// with the tunnel control protocol (over the simple_ctrl connection):
///   OPEN_TUNNEL (0x06): request [cmd], response [cmd, ok, port(2), key(16)]
///   CLOSE_TUNNEL (0x07): request [cmd], response [cmd, ok]
///   DOWNLOAD_KEY (0x08): request [cmd, name], response [cmd, ok, size(4)],
///       the key data then arrives as tunnel messages
///   UPLOAD_KEY (0x09): request [cmd, size(4), name], response [cmd, ok],
///       the key data is then sent as tunnel messages, and the device
///       replies with a 1-byte completion ack (1 = saved, 0 = failed)
///       once all the data has been received
///
/// The first tunnel message both ways is the 9-byte string "HoozzPlay"
/// (the handshake, which authenticates the key). A tunnel message carries
/// at most 1024 plaintext bytes; upload messages are limited to 256 bytes,
/// because the device reads at most 256 bytes per message.
///
/// The tunnel is single-user on the device: while a session is open a new
/// OPEN is rejected. open() therefore closes a possibly stale session
/// before the second attempt.
///
class TunnelCtrl {
  static const int _cmdOpen = 0x06;
  static const int _cmdClose = 0x07;
  static const int _cmdDownload = 0x08;
  static const int _cmdUpload = 0x09;

  static const int _resultOk = 0x00;
  static const int _ackOk = 1; /* device upload completion ack value */
  static const String _handshake = 'HoozzPlay';
  static const int _maxKeySize = 1024; /* device limit */
  static const int _uploadChunkSize = 256; /* device read granularity */

  final SimpleCtrlHandle _simpleCtrlHandle;
  final String _ip;

  TcpCrypto? _tcp;

  TunnelCtrl(this._simpleCtrlHandle, this._ip);

  ///
  /// Whether the tunnel is currently open (the socket is connected).
  ///
  bool get isOpen => _tcp != null;

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _sendClose() async {
    ByteData req = ByteData(1);
    req.setUint8(0, _cmdClose);
    try {
      await _simpleCtrlHandle.request(req.buffer.asUint8List(), true);
    } catch (e) {
      developer.log('Close tunnel exception: $e', name: _logName);
    }
  }

  Future<bool> _openOnce() async {
    ByteData req = ByteData(1);
    req.setUint8(0, _cmdOpen);
    Uint8List? resp = await _simpleCtrlHandle.request(
      req.buffer.asUint8List(),
      true,
    );
    if (resp == null ||
        resp.length != 2 + 2 + TcpCrypto.keyLength ||
        resp[0] != _cmdOpen ||
        resp[1] != _resultOk) {
      developer.log('Open tunnel failed, resp: $resp', name: _logName);
      return false;
    }
    int port = resp[2] | (resp[3] << 8);
    Uint8List key =
        Uint8List.fromList(resp.sublist(4, 4 + TcpCrypto.keyLength));

    Socket socket;
    try {
      socket = await Socket.connect(
        _ip,
        port,
        timeout: const Duration(seconds: 5),
      );
    } catch (e) {
      developer.log('Tunnel connect failed: $e', name: _logName);
      return false;
    }

    TcpCrypto tcp = TcpCrypto(socket, key);

    // Handshake: the first message both ways is "HoozzPlay"
    Uint8List handshake = Uint8List.fromList(utf8.encode(_handshake));
    if (!await tcp.sendFrame(handshake)) {
      developer.log('Tunnel handshake send failed', name: _logName);
      await tcp.close();
      return false;
    }
    Uint8List? reply = await tcp.recvFrame();
    if (reply == null || !_bytesEqual(reply, handshake)) {
      developer.log('Tunnel handshake failed, reply: $reply', name: _logName);
      await tcp.close();
      return false;
    }

    _tcp = tcp;
    developer.log('Tunnel opened (port $port)', name: _logName);
    return true;
  }

  ///
  /// Open the tunnel (control request + TCP connect + handshake).
  ///
  Future<bool> open() async {
    if (await _openOnce()) return true;
    // A previous (failed) operation may have left a session open on the
    // device: close it and try again. The device's session task needs a
    // moment to process the close and release the port, so wait a bit.
    await _sendClose();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _openOnce();
  }

  ///
  /// Download the key data of [name] from the device.
  /// Returns the data, or null on failure.
  ///
  Future<Uint8List?> downloadKey(String name) async {
    BytesBuilder bb = BytesBuilder(copy: false);
    bb.addByte(_cmdDownload);
    bb.add(utf8.encode(name));
    Uint8List? resp = await _simpleCtrlHandle.request(bb.toBytes(), true);
    if (resp == null ||
        resp.length != 6 ||
        resp[0] != _cmdDownload ||
        resp[1] != _resultOk) {
      developer.log('Download request failed, resp: $resp', name: _logName);
      return null;
    }
    int size =
        resp[2] | (resp[3] << 8) | (resp[4] << 16) | (resp[5] << 24);

    TcpCrypto? tcp = _tcp;
    if (tcp == null) return null;

    Uint8List out = Uint8List(size);
    int got = 0;
    while (got < size) {
      Uint8List? chunk = await tcp.recvFrame();
      if (chunk == null) return null;
      int n = (chunk.length < size - got) ? chunk.length : (size - got);
      out.setRange(got, got + n, chunk);
      got += n;
    }
    return out;
  }

  ///
  /// Upload [data] to the device as the key [name] (overwrites it if it
  /// exists). [data] must be 1..1024 bytes.
  ///
  Future<bool> uploadKey(String name, Uint8List data) async {
    if (data.isEmpty || data.length > _maxKeySize) return false;

    BytesBuilder bb = BytesBuilder(copy: false);
    bb.addByte(_cmdUpload);
    bb.addByte(data.length & 0xff);
    bb.addByte((data.length >> 8) & 0xff);
    bb.addByte((data.length >> 16) & 0xff);
    bb.addByte((data.length >> 24) & 0xff);
    bb.add(utf8.encode(name));
    Uint8List? resp = await _simpleCtrlHandle.request(bb.toBytes(), true);
    if (resp == null ||
        resp.length != 2 ||
        resp[0] != _cmdUpload ||
        resp[1] != _resultOk) {
      developer.log('Upload request failed, resp: $resp', name: _logName);
      return false;
    }

    TcpCrypto? tcp = _tcp;
    if (tcp == null) return false;

    int sent = 0;
    while (sent < data.length) {
      int n = (data.length - sent < _uploadChunkSize)
          ? (data.length - sent)
          : _uploadChunkSize;
      if (!await tcp.sendFrame(
          Uint8List.sublistView(data, sent, sent + n))) {
        developer.log('Upload write failed', name: _logName);
        return false;
      }
      sent += n;
    }

    // Wait for the completion ack (1 = saved, 0 = failed); the device
    // sends it once all the key data has been received, so the upload
    // is only considered done when the key is actually on the device
    Uint8List? ack = await tcp.recvFrame();
    if (ack == null || ack.length != 1 || ack[0] != _ackOk) {
      developer.log('Upload ack failed, ack: $ack', name: _logName);
      return false;
    }
    return true;
  }

  ///
  /// Close the tunnel (control request + socket close).
  ///
  Future<void> close() async {
    await _sendClose();
    TcpCrypto? tcp = _tcp;
    _tcp = null;
    if (tcp != null) await tcp.close();
  }
}

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

  // Device key limits (tunnel transfer and the add-key dialog share
  // them)
  static const int _maxKeyNameLength = 100; // bytes
  static const int _maxKeyDataSize = 1024; // bytes

  int _irRxCount = 0;
  int _irRxLength = 0;
  bool _irRxDataVaild = false;
  final TextEditingController _irKeyName = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  StateSetter? _dialogSetState;
  Map<String, int> _irKeyMap = {};
  bool _getKeyListRunning = false;

  // Key transfer mode: multi-select via checkboxes, then upload (key ->
  // phone file), download (phone file -> key) or delete the selected keys
  bool _transferMode = false;
  bool _transferBusy = false;
  String? _transferFolder;
  Set<String> _selectedKeys = {};

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

  //
  // Re-read the key count and the key list from the device (used after
  // a batch delete. The device also sends a key-changed notification
  // for each removed key; the _getKeyListRunning guard keeps the
  // refreshes from colliding).
  //
  Future<void> _refreshKeyList() async {
    ByteData byteData = ByteData(1);
    byteData.setUint8(0, _irCmdGetCount);
    Uint8List data = byteData.buffer.asUint8List();
    Uint8List? value = await _simpleCtrlHandle.request(data, true);
    if (value != null &&
        value.length == 6 &&
        value[0] == _irCmdGetCount &&
        value[1] == _irResultOk) {
      ByteData countData = ByteData.view(value.buffer, 2, 4);
      int keyCount = countData.getUint32(0, Endian.little);
      developer.log('Key count: $keyCount', name: _logName);
      await _getKeyList(keyCount);
    } else {
      developer.log('Key count request failed', name: _logName);
    }
  }

  //
  // Delete the selected keys (one REMOVE request per key), then refresh
  // the key list and clear the selection.
  //
  Future<void> _deleteSelectedKeys() async {
    List<String> keyNames = List<String>.from(_selectedKeys);
    if (keyNames.isEmpty) return;
    _transferBusy = true;
    ValueNotifier<double> progress = ValueNotifier<double>(0);
    SimpleProgressDialog.show(
      context,
      'Deleting ${keyNames.length} key${keyNames.length > 1 ? 's' : ''}...',
      progress,
    );
    int okCount = 0;
    for (int i = 0; i < keyNames.length; i++) {
      String keyName = keyNames[i];
      ByteData byteData = ByteData(1);
      byteData.setUint8(0, _irCmdRemove);
      BytesBuilder bb = BytesBuilder();
      bb.add(byteData.buffer.asUint8List());
      bb.add(utf8.encode(keyName));
      Uint8List data = bb.toBytes();
      Uint8List? value = await _simpleCtrlHandle.request(data, true);
      if (value != null &&
          value.length == 2 &&
          value[0] == _irCmdRemove &&
          value[1] == _irResultOk) {
        okCount++;
        developer.log('Removed [$keyName]', name: _logName);
      } else {
        developer.log('Remove of [$keyName] failed', name: _logName);
      }
      progress.value = (i + 1) / keyNames.length;
    }
    await _refreshKeyList();
    progress.dispose();
    _transferBusy = false;
    if (!mounted) return;
    Navigator.pop(context);
    setState(() {
      _selectedKeys.clear();
    });
    SimpleSnackBar.show(
      context,
      okCount == keyNames.length
          ? 'Removed ${keyNames.length} key${keyNames.length > 1 ? 's' : ''}'
          : okCount > 0
              ? 'Removed $okCount/${keyNames.length} keys'
              : 'Delete failed',
      okCount == keyNames.length ? Colors.green : Colors.red,
    );
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

  //
  // Escape a name for use as a file name. The characters that are
  // invalid in file names on Android/Windows become `~` plus a code
  // letter (`~` itself is doubled), so the original name can be
  // restored exactly from the file name:
  //   ~ -> ~~    / -> ~f    \ -> ~b    * -> ~a
  //   ? -> ~q    " -> ~d    < -> ~l    > -> ~g    | -> ~p
  // Control characters (newline etc.) become `_` (they cannot be
  // shown in a file name at all).
  //
  String _escapeFileName(String name) {
    const Map<String, String> escape = {
      '~': '~~',
      '/': '~f',
      '\\': '~b',
      '*': '~a',
      '?': '~q',
      '"': '~d',
      '<': '~l',
      '>': '~g',
      '|': '~p',
    };
    final RegExp invalid = RegExp(r'[~\/\\*?"<>|\r\n\t]');
    String result = '';
    for (int i = 0; i < name.length; i++) {
      String ch = name[i];
      result += invalid.hasMatch(ch) ? (escape[ch] ?? '_') : ch;
    }
    if (result.isEmpty) return 'key';
    return result;
  }

  //
  // Reverse of _escapeFileName: restore the original name from a
  // file name (used when importing, so the key name on the device
  // matches the exported one).
  //
  String _unescapeFileName(String name) {
    const Map<String, String> unescape = {
      '~~': '~',
      '~f': '/',
      '~b': '\\',
      '~a': '*',
      '~q': '?',
      '~d': '"',
      '~l': '<',
      '~g': '>',
      '~p': '|',
    };
    String result = '';
    int i = 0;
    while (i < name.length) {
      if (name[i] == '~' &&
          i + 1 < name.length &&
          unescape.containsKey(name.substring(i, i + 2))) {
        result += unescape[name.substring(i, i + 2)]!;
        i += 2;
      } else {
        result += name[i];
        i++;
      }
    }
    if (result.isEmpty) return 'key';
    return result;
  }

  String _timestamp() {
    DateTime now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year.toString().padLeft(4, '0')}'
        '${two(now.month)}${two(now.day)}'
        '_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  //
  // Storage permission (Android 9 and below): needed to write to the
  // public Download folder. On Android 10+ the legacy permission is
  // granted automatically; if the public location is still not
  // writable, the app's own documents directory is used instead.
  //
  Future<void> _ensureStoragePermission() async {
    // The result is not checked: _createExportFolder falls back to the
    // app's own documents directory when the public location is not
    // writable
    if (!Platform.isAndroid) return;
    PermissionStatus status = await Permission.storage.status;
    if (status.isDenied) {
      await Permission.storage.request();
    }
  }

  //
  // Create the export folder for this session: the public
  // Download/HoozzPlay folder (which the file picker can reach), named
  // after the device with a timestamp appended; falls back to the app's
  // own documents directory.
  //
  Future<String?> _createExportFolder() async {
    String sub =
        '${_escapeFileName(_discoverDeviceInfo.name)}_${_timestamp()}';
    // path_provider only exposes app-private directories on Android
    // (Android/data/...), which the file picker cannot reach, so use the
    // standard public external storage path directly (needs the storage
    // permission on Android 9 and below).
    List<String> bases = [
      '/storage/emulated/0/Download/HoozzPlay',
      (await getApplicationDocumentsDirectory()).path,
    ];
    for (String base in bases) {
      try {
        Directory dir = Directory('$base/$sub');
        await dir.create(recursive: true);
        return dir.path;
      } catch (e) {
        developer.log('Create export folder failed: $base: $e', name: _logName);
      }
    }
    return null;
  }

  //
  // Export: read the key data of all [keyNames] from the device (one
  // tunnel session) and save each key to a phone file. The files are
  // stored in a subfolder named after the device with a timestamp
  // appended.
  //
  Future<void> _exportKeys(List<String> keyNames) async {
    if (_transferBusy || keyNames.isEmpty) return;
    _transferBusy = true;
    ValueNotifier<double> progress = ValueNotifier<double>(0);
    SimpleProgressDialog.show(
      context,
      'Exporting ${keyNames.length} key${keyNames.length > 1 ? 's' : ''}...',
      progress,
    );
    await _ensureStoragePermission();
    int okCount = 0;
    String? savedFolder;
    TunnelCtrl tunnel = TunnelCtrl(
      _simpleCtrlHandle,
      _discoverDeviceInfo.ip,
    );
    try {
      if (await tunnel.open()) {
        for (int i = 0; i < keyNames.length; i++) {
          String keyName = keyNames[i];
          Uint8List? data = await tunnel.downloadKey(keyName);
          if (data == null) {
            developer.log('Key [$keyName] download failed', name: _logName);
            break;
          }
          if (_transferFolder == null) {
            _transferFolder = await _createExportFolder();
          }
          if (_transferFolder == null) {
            developer.log('No writable export folder', name: _logName);
            break;
          }
          String path = '$_transferFolder/${_escapeFileName(keyName)}.bin';
          File file = File(path);
          await file.writeAsBytes(data, flush: true);
          savedFolder = _transferFolder;
          okCount++;
          progress.value = (i + 1) / keyNames.length;
          developer.log('Key [$keyName] saved: $path', name: _logName);
        }
      }
    } catch (e) {
      developer.log('Transfer exception: $e', name: _logName);
    }
    await tunnel.close();
    progress.dispose();
    _transferBusy = false;
    _selectedKeys.clear();
    if (!mounted) return;
    Navigator.pop(context);
    setState(() {});
    SimpleSnackBar.show(
      context,
      okCount == keyNames.length
          ? 'Saved: $savedFolder'
          : okCount > 0
              ? 'Exported $okCount/${keyNames.length} keys'
              : 'Export failed',
      okCount == keyNames.length ? Colors.green : Colors.red,
    );
  }

  //
  // Derive the key name from a file path: the file name without the
  // extension, with the escaping applied on export reversed (so an
  // exported file gives back the original key name).
  //
  String _keyNameFromPath(String path) {
    String fileName = path.split(RegExp(r'[/\\]')).last;
    String keyName = fileName;
    int dot = fileName.lastIndexOf('.');
    if (dot > 0) keyName = fileName.substring(0, dot);
    return _unescapeFileName(keyName);
  }

  //
  // Upload one key with retries. The upload is only complete once the
  // device's completion ack has been received; on failure (busy queue,
  // dead session, or incomplete data) the tunnel is closed and reopened
  // (which clears the device's operation queue) and the upload is
  // retried.
  //
  Future<bool> _uploadKeyWithRetry(
    TunnelCtrl tunnel,
    String name,
    Uint8List data,
  ) async {
    const int maxAttempts = 4;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (await tunnel.uploadKey(name, data)) return true;
      developer.log(
        'Upload of [$name] failed (attempt ${attempt + 1}/$maxAttempts)',
        name: _logName,
      );
      await tunnel.close();
      if (!await tunnel.open()) return false;
    }
    return false;
  }

  //
  // Import: pick one or more phone files and upload their content to
  // the device as keys (one tunnel session, each key name is the file
  // name without the extension).
  //
  Future<void> _importKeysFromPhone() async {
    if (_transferBusy) return;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;

    // Validate all the files before starting the transfer
    List<PlatformFile> files = [];
    for (PlatformFile file in result.files) {
      String? path = file.path;
      if (path == null) continue;
      String keyName = _keyNameFromPath(path);
      if (utf8.encode(keyName).length > _maxKeyNameLength) {
        SimpleSnackBar.show(context, 'Key name too long', Colors.red);
        return;
      }
      int size;
      try {
        size = await File(path).length();
      } catch (e) {
        if (!mounted) return;
        SimpleSnackBar.show(context, 'Read file failed', Colors.red);
        return;
      }
      if (size < 1 || size > _maxKeyDataSize) {
        SimpleSnackBar.show(
          context,
          'Key data must be 1-1024 bytes',
          Colors.red,
        );
        return;
      }
      files.add(file);
    }
    if (files.isEmpty) return;

    _transferBusy = true;
    ValueNotifier<double> progress = ValueNotifier<double>(0);
    SimpleProgressDialog.show(
      context,
      'Importing ${files.length} file${files.length > 1 ? 's' : ''}...',
      progress,
    );
    int okCount = 0;
    TunnelCtrl tunnel = TunnelCtrl(
      _simpleCtrlHandle,
      _discoverDeviceInfo.ip,
    );
    try {
      if (await tunnel.open()) {
        for (int i = 0; i < files.length; i++) {
          String path = files[i].path!;
          String keyName = _keyNameFromPath(path);
          Uint8List data = await File(path).readAsBytes();
          if (!await _uploadKeyWithRetry(tunnel, keyName, data)) {
            developer.log('Upload of [$keyName] failed', name: _logName);
            if (!tunnel.isOpen) break; // The tunnel died, stop the batch
            continue; // Single key failed, try the rest
          }
          okCount++;
          progress.value = (i + 1) / files.length;
          developer.log('Key [$keyName] imported', name: _logName);
        }
      }
    } catch (e) {
      developer.log('Import exception: $e', name: _logName);
    }
    await tunnel.close();
    progress.dispose();
    _transferBusy = false;
    if (!mounted) return;
    Navigator.pop(context);
    SimpleSnackBar.show(
      context,
      okCount == files.length
          ? 'Imported ${files.length} keys'
          : okCount > 0
              ? 'Imported $okCount/${files.length} keys'
              : 'Import failed',
      okCount == files.length ? Colors.green : Colors.red,
    );
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
          // Import (upload from phone), export (download to phone) and
          // delete buttons, transfer mode only
          if (_transferMode) ...[
            IconButton(
              icon: const Icon(Icons.file_upload),
              onPressed: () {
                if (_transferBusy) return;
                _importKeysFromPhone();
              },
              tooltip: 'Import keys',
            ),
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () {
                if (_transferBusy) return;
                if (_selectedKeys.isEmpty) {
                  SimpleSnackBar.show(context, 'Select keys first', Colors.red);
                  return;
                }
                _exportKeys(List<String>.from(_selectedKeys));
              },
              tooltip: 'Export selected keys',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                if (_transferBusy) return;
                if (_selectedKeys.isEmpty) {
                  SimpleSnackBar.show(context, 'Select keys first', Colors.red);
                  return;
                }
                showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Warning'),
                      content: Text(
                        'Are you sure you want to delete the selected '
                        '${_selectedKeys.length} key'
                        '${_selectedKeys.length > 1 ? 's' : ''}?',
                        style: const TextStyle(color: Colors.red),
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
                    'Delete ${_selectedKeys.length} keys: $result',
                    name: _logName,
                  );
                  if (result) {
                    _deleteSelectedKeys();
                  }
                });
              },
              tooltip: 'Delete selected keys',
            ),
          ],
          // Key transfer (upload/download/delete) mode button
          IconButton(
            icon: Icon(
              _transferMode ? Icons.close : Icons.check_box,
            ),
            onPressed: () {
              if (_transferBusy) return;
              developer.log(
                'Transfer mode: ${!_transferMode}',
                name: _logName,
              );
              setState(() {
                _transferMode = !_transferMode;
                if (!_transferMode) {
                  _transferFolder = null;
                  _selectedKeys.clear();
                }
              });
            },
            tooltip:
                _transferMode ? 'Exit transfer mode' : 'Key transfer mode',
          ),
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
                // Transfer mode: toggle the selection of the key
                if (_transferMode) {
                  setState(() {
                    if (_selectedKeys.contains(irKeyList[index])) {
                      _selectedKeys.remove(irKeyList[index]);
                    } else {
                      _selectedKeys.add(irKeyList[index]);
                    }
                  });
                  developer.log(
                    'Select: ${irKeyList[index]}: '
                    '${_selectedKeys.contains(irKeyList[index])}',
                    name: _logName,
                  );
                  return;
                }
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
                // Transfer mode: select all / deselect all
                if (_transferMode) {
                  setState(() {
                    if (_selectedKeys.length == irKeyList.length) {
                      _selectedKeys.clear();
                    } else {
                      _selectedKeys.clear();
                      _selectedKeys.addAll(irKeyList);
                    }
                  });
                  developer.log(
                    'Select all: ${_selectedKeys.length}/${irKeyList.length}',
                    name: _logName,
                  );
                }
              },
              child: Card(
                child: Padding(
                  padding: EdgeInsetsGeometry.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Selection checkbox (transfer mode only, the tap is
                      // handled by the surrounding InkWell)
                      if (_transferMode)
                        Checkbox(
                          value: _selectedKeys.contains(irKeyList[index]),
                          onChanged: (bool? checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedKeys.add(irKeyList[index]);
                              } else {
                                _selectedKeys.remove(irKeyList[index]);
                              }
                            });
                          },
                          activeColor: mainFillColor,
                          // Keep the row height the same as in normal mode
                          // (the default 48px tap target makes the row taller)
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          // The default unchecked border is too dark
                          side: const BorderSide(color: Colors.grey, width: 2),
                        ),
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
      floatingActionButton: _transferMode
          ? null
          : FloatingActionButton(
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
                          maxLength: _maxKeyNameLength,
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
  final InfoEdit _infoEdit = InfoEdit(deviceInfo: DeviceInfo());
  late DiscoverDeviceInfo _discoverDeviceInfo;
  late String _storageName;
  late bool _allowSetPasswd;
  SimpleCtrlHandle? _simpleCtrlHandle;

  Future<void> _deviceInfoLoad() async {
    DeviceStorage storage = DeviceStorage(_storageName);
    await storage.load();
    if (storage.deviceList[_infoEdit.deviceInfo.id] != null) {
      _infoEdit.deviceInfo = storage.deviceList[_infoEdit.deviceInfo.id]!;
    }
  }

  Future<void> _deviceInfoSave() async {
    DeviceStorage storage = DeviceStorage(_storageName);
    await storage.load();
    storage.deviceList[_infoEdit.deviceInfo.id] = _infoEdit.deviceInfo;
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
      _infoEdit.ctrlReady = true;
    }
    _infoEdit.deviceInfo.nickName = _discoverDeviceInfo.name;
    _infoEdit.deviceInfo.id = _discoverDeviceInfo.id;
    _deviceInfoLoad().then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return DeviceConfig(
      allowSetPasswd: _allowSetPasswd,
      discoverDeviceInfo: _discoverDeviceInfo,
      infoEdit: _infoEdit,
      onSavePressed: (infoEdit) {
        if (infoEdit.ctrlReady) {
          SimpleShowDialog.show(context, "Verifying device...");
          Future<bool> result = () async {
            // Set name
            if (infoEdit.syncName) {
              bool ret = await _simpleCtrlHandle!.setName(
                infoEdit.deviceInfo.nickName,
              );
              if (ret != true) return false;
            }
            // Set password
            return await _simpleCtrlHandle!.setPassword(
              infoEdit.deviceInfo.accessKey,
            );
          }.call();
          result.then((bool value) {
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
            infoEdit.deviceInfo.accessKey = '';
          }
          _deviceInfoSave();
          Navigator.pop(context);
          SimpleSnackBar.show(context, 'Device saved', Colors.green);
        }
      },
    );
  }
}
