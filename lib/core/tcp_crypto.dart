///
/// Created on 2026/11/13
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

const String _logName = 'tcp_crypto';

///
/// AES128-CBC encrypted frame transport over a TCP socket
/// (the app-side counterpart of the device's tcp_crypto layer).
///
/// A frame is: len(2, LE plaintext length) + IV(16 random bytes) +
/// AES128-CBC ciphertext (the plaintext is zero-padded to a 16-byte
/// boundary). One frame carries at most [TcpCrypto.maxFrameSize]
/// plaintext bytes.
///
class TcpCrypto {
  static const int keyLength = 16;

  final int _maxFrameSize;
  final int _timeoutMs;

  final Socket _socket;
  final Encrypter _encrypter;
  final Random _random = Random.secure();

  final Queue<int> _rxQueue = Queue<int>();
  Completer<void>? _rxWake;
  bool _rxClosed = false;

  ///
  /// Wrap an already-connected [socket] with the encrypted frame
  /// protocol, using the 16-byte AES [key].
  ///
  /// [maxFrameSize] is the largest plaintext size one frame may carry
  /// (larger frames are dropped; the device enforces its own limit).
  /// [timeoutMs] bounds each blocking read.
  ///
  TcpCrypto(
    Socket socket,
    Uint8List key, {
    int maxFrameSize = 1024,
    int timeoutMs = 10000,
  })  : _maxFrameSize = maxFrameSize,
        _timeoutMs = timeoutMs,
        _socket = socket,
        _encrypter = Encrypter(
          AES(Key(key), mode: AESMode.cbc, padding: null),
        ) {
    socket.listen(
      _onSocketData,
      onDone: _onSocketClosed,
      onError: (Object error) {
        developer.log('Socket error: $error', name: _logName);
        _onSocketClosed();
      },
      cancelOnError: true,
    );
  }

  ///
  /// Whether the socket is still open.
  ///
  bool get isOpen => !_rxClosed;

  Uint8List _buildFrame(Uint8List plaintext) {
    int pad = (16 - (plaintext.length % 16)) % 16;
    Uint8List padded = Uint8List(plaintext.length + pad);
    padded.setRange(0, plaintext.length, plaintext);
    Uint8List iv =
        Uint8List.fromList(List<int>.generate(keyLength,
            (index) => _random.nextInt(256)));
    Encrypted ct = _encrypter.encryptBytes(padded, iv: IV(iv));

    BytesBuilder bb = BytesBuilder(copy: false);
    bb.addByte(plaintext.length & 0xff);
    bb.addByte((plaintext.length >> 8) & 0xff);
    bb.add(iv);
    bb.add(ct.bytes);
    return bb.toBytes();
  }

  void _onSocketData(Uint8List data) {
    _rxQueue.addAll(data);
    Completer<void>? wake = _rxWake;
    if (wake != null && !wake.isCompleted) {
      wake.complete();
    }
  }

  void _onSocketClosed() {
    _rxClosed = true;
    Completer<void>? wake = _rxWake;
    if (wake != null && !wake.isCompleted) {
      wake.complete();
    }
  }

  Future<Uint8List> _readExact(int count) async {
    Uint8List out = Uint8List(count);
    int got = 0;
    while (got < count) {
      while (_rxQueue.isNotEmpty && got < count) {
        out[got++] = _rxQueue.removeFirst();
      }
      if (got < count) {
        if (_rxClosed) {
          throw const SocketException('Connection closed');
        }
        Completer<void> wake = Completer<void>();
        _rxWake = wake;
        try {
          await wake.future.timeout(Duration(milliseconds: _timeoutMs));
        } on TimeoutException {
          _rxWake = null;
          throw const SocketException('Read timeout');
        }
        _rxWake = null;
      }
    }
    return out;
  }

  ///
  /// Send [plaintext] as one encrypted frame.
  /// Returns false on failure (the socket may be broken then).
  ///
  Future<bool> sendFrame(Uint8List plaintext) async {
    if (plaintext.length > _maxFrameSize) {
      developer.log('Frame too large: ${plaintext.length}', name: _logName);
      return false;
    }
    try {
      _socket.add(_buildFrame(plaintext));
      await _socket.flush();
    } catch (e) {
      developer.log('Send frame failed: $e', name: _logName);
      return false;
    }
    return true;
  }

  ///
  /// Receive one encrypted frame.
  /// Returns the plaintext, or null on failure/timeout/closed.
  ///
  Future<Uint8List?> recvFrame() async {
    try {
      Uint8List len = await _readExact(2);
      int size = len[0] | (len[1] << 8);
      if (size > _maxFrameSize) {
        developer.log('Frame too large: $size', name: _logName);
        return null;
      }
      Uint8List iv = await _readExact(keyLength);
      int ctTotal = (size + 15) & ~15;
      Uint8List ct = await _readExact(ctTotal);
      Uint8List plain = Uint8List.fromList(
        _encrypter.decryptBytes(Encrypted(ct), iv: IV(iv)),
      );
      return plain.sublist(0, size);
    } catch (e) {
      developer.log('Read frame exception: $e', name: _logName);
      return null;
    }
  }

  ///
  /// Close the socket.
  ///
  Future<void> close() async {
    try {
      await _socket.close();
    } catch (e) {
      developer.log('Close socket exception: $e', name: _logName);
    }
  }
}
