///
/// Created on 2024/07/21
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

abstract class Crypto {
  static const int typeNone = 0x00;
  static const int typeXOR = 0x01;
  static const int typeAES128ECB = 0x02;
  static const int typeAES128CBC = 0x03;
  static const int typeMax = 0x04;

  late int cryptoType;

  bool passwdSet(Uint8List passwd);
  bool en(Uint8List data);
  bool de(Uint8List data);
  Uint8List done();

  static Crypto? getCrypto(int type, Uint8List? passwd) {
    switch (type) {
      case typeXOR:
        return CryptoXOR(passwd);
      case typeAES128ECB:
        return CryptoAES128ECB(passwd);
      case typeAES128CBC:
        return CryptoAES128CBC(passwd);
    }
    return null;
  }
}

class CryptoXOR implements Crypto {
  static const int passwdMaxLength = 16;
  Uint8List? _passwd;
  int _count = 0;
  final BytesBuilder _builder = BytesBuilder();

  bool _xor(Uint8List data) {
    if (_passwd == null) {
      _builder.add(data);
      return true;
    }

    Uint8List byteData = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      byteData[i] = data[i] ^ _passwd![_count % _passwd!.length];
      _count++;
    }

    _builder.add(byteData);

    return true;
  }

  CryptoXOR([Uint8List? passwd]) {
    _passwd = passwd;
  }

  @override
  int cryptoType = Crypto.typeXOR;

  @override
  bool passwdSet(Uint8List passwd) {
    if (passwd.length >= passwdMaxLength) return false;
    _passwd = passwd;
    return true;
  }

  @override
  bool en(Uint8List data) => _xor(data);

  @override
  bool de(Uint8List data) => _xor(data);

  @override
  Uint8List done() => _builder.toBytes();
}

class CryptoAES128ECB implements Crypto {
  @override
  int cryptoType = Crypto.typeAES128ECB;

  static const _keyLength = 16;
  final Uint8List _passwd = Uint8List(_keyLength);
  final BytesBuilder _deBuilder = BytesBuilder();
  final BytesBuilder _enBuilder = BytesBuilder();

  CryptoAES128ECB([Uint8List? passwd]) {
    if (passwd != null) passwdSet(passwd);
  }

  @override
  Uint8List done() {
    final Key key = Key(_passwd);
    final IV iv = IV.fromLength(0);
    final Encrypter encrypter = Encrypter(
      AES(key, mode: AESMode.ecb, padding: null),
    );

    if (_enBuilder.length != 0) {
      // 16-byte alignment
      if ((_enBuilder.length % 16) != 0) {
        _enBuilder.add(Uint8List(16 - (_enBuilder.length % 16)));
      }
      final Encrypted encrypted = encrypter.encryptBytes(
        _enBuilder.toBytes(),
        iv: iv,
      );
      return encrypted.bytes;
    } else {
      // 16-byte alignment check
      if ((_deBuilder.length % 16) != 0) return Uint8List(0);
      final Encrypted encrypted = Encrypted(_deBuilder.toBytes());
      final Uint8List data = Uint8List.fromList(
        encrypter.decryptBytes(encrypted, iv: iv),
      );
      return data;
    }
  }

  @override
  bool de(Uint8List data) {
    _deBuilder.add(data);
    return true;
  }

  @override
  bool en(Uint8List data) {
    _enBuilder.add(data);
    return true;
  }

  @override
  bool passwdSet(Uint8List passwd) {
    if (passwd.length > _keyLength) return false;
    _passwd.fillRange(0, _passwd.length, 0);
    _passwd.setRange(0, passwd.length, passwd);
    return true;
  }
}

class CryptoAES128CBC implements Crypto {
  @override
  int cryptoType = Crypto.typeAES128CBC;

  static const int _headReserve = 16;
  static const int _keyLength = 16;
  final Uint8List _passwd = Uint8List(_keyLength);
  final BytesBuilder _deBuilder = BytesBuilder();
  final BytesBuilder _enBuilder = BytesBuilder();

  CryptoAES128CBC([Uint8List? passwd]) {
    if (passwd != null) passwdSet(passwd);
  }

  @override
  Uint8List done() {
    final Key key = Key(_passwd);
    final Encrypter encrypter = Encrypter(
      AES(key, mode: AESMode.cbc, padding: null),
    );

    if (_enBuilder.length != 0) {
      // 16-byte alignment
      if ((_enBuilder.length % 16) != 0) {
        _enBuilder.add(Uint8List(16 - (_enBuilder.length % 16)));
      }
      final IV iv = IV.fromLength(_headReserve);
      final Encrypted encrypted = encrypter.encryptBytes(
        _enBuilder.toBytes(),
        iv: iv,
      );
      final BytesBuilder result = BytesBuilder();
      result.add(iv.bytes);
      result.add(encrypted.bytes);
      return result.toBytes();
    } else {
      // 16-byte alignment check
      if ((_deBuilder.length % 16) != 0) return Uint8List(0);
      Uint8List tmp = _deBuilder.toBytes();
      Uint8List data = tmp.sublist(_headReserve);
      final IV iv = IV(tmp.sublist(0, _headReserve));
      final Encrypted encrypted = Encrypted(data);
      final Uint8List result = Uint8List.fromList(
        encrypter.decryptBytes(encrypted, iv: iv),
      );
      return result;
    }
  }

  @override
  bool de(Uint8List data) {
    _deBuilder.add(data);
    return true;
  }

  @override
  bool en(Uint8List data) {
    _enBuilder.add(data);
    return true;
  }

  @override
  bool passwdSet(Uint8List passwd) {
    if (passwd.length > _keyLength) return false;
    _passwd.fillRange(0, _passwd.length, 0);
    _passwd.setRange(0, passwd.length, passwd);
    return true;
  }
}
