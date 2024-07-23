///
/// Created on 2024/07/21
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:typed_data';

abstract class Crypto {
  static const int typeNone = 0x00;
  static const int typeXOR = 0x01;
  static const int typeMax = 0x02;

  late int cryptoType;

  bool passwdSet(Uint8List passwd);
  bool en(Uint8List data);
  bool de(Uint8List data);
  Uint8List done();
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
