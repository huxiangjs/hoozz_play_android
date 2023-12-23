///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:io';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import 'generated/bindings_generated.dart';
import 'dart:isolate';
import 'package:dartssh2/dartssh2.dart';
import 'package:async/async.dart';

const String _logName = 'remote_switch';
bool _runing = false;

void _remoteSwitchIsolateEntry(SendPort sendPort) async {
  final ReceivePort receivePort = ReceivePort();
  final events = StreamQueue<dynamic>(receivePort);
  sendPort.send(receivePort.sendPort);

  int func = await events.next;
  switch (func) {
    case 0:
      List<String> lists = await events.next;
      int retval = -1;
      Pointer<Char> repositoryPtr = lists[0].toNativeUtf8().cast<Char>();
      Pointer<Char> privkeyPtr = lists[1].toNativeUtf8().cast<Char>();
      try {
        retval = _bindings.remote_sw_init(repositoryPtr, privkeyPtr);
      } catch (e) {
        retval = -1;
        developer.log(e.toString(), name: _logName);
      }
      malloc.free(repositoryPtr);
      malloc.free(privkeyPtr);

      sendPort.send(retval);
      break;
    case 1:
      int retval = _bindings.remote_sw_press();
      sendPort.send(retval);
      break;
    case 2:
      int timeout = await events.next;
      int retval = _bindings.remote_sw_result(timeout);
      sendPort.send(retval);
      break;
    case 3:
      int retval = _bindings.remote_sw_report();
      sendPort.send(retval);
      break;
  }

  Isolate.exit();
}

Future<int> _remoteSwitchFunction(int func, dynamic param) async {
  if (_runing) return -1;

  _runing = true;

  // refs: https://dart.cn/guides/language/concurrency
  // https://github.com/dart-lang/samples/blob/main/isolates/bin/long_running_isolate.dart
  final ReceivePort receivePort = ReceivePort();
  await Isolate.spawn(_remoteSwitchIsolateEntry, receivePort.sendPort);
  final events = StreamQueue<dynamic>(receivePort);
  int retval = -1;

  SendPort receive = await events.next;
  receive.send(func);
  switch (func) {
    case 0:
      receive.send(param);
      retval = await events.next;
      break;
    case 1:
      retval = await events.next;
      break;
    case 2:
      receive.send(param);
      retval = await events.next;
      break;
    case 3:
      retval = await events.next;
      break;
  }

  // Dispose the StreamQueue.
  await events.cancel();

  _runing = false;
  return retval;
}

Future<int> remoteSwitchInit(String repository, String privkey) async {
  return _remoteSwitchFunction(0, [repository, privkey]);
}

Future<int> remoteSwitchPress() async {
  return _remoteSwitchFunction(1, null);
}

Future<int> remoteSwitchResult(int timeout) async {
  return _remoteSwitchFunction(2, timeout);
}

Future<int> remoteSwitchReport() async {
  return _remoteSwitchFunction(3, null);
}

final DynamicLibrary _dylib = Platform.isAndroid
    ? DynamicLibrary.open('libremote_sw.so')
    : DynamicLibrary.process();

/// The bindings to the native functions in [_dylib].
final HoozzPlayBindings _bindings = HoozzPlayBindings(_dylib);

class _SSH_Object {
  SSHClient client;
  SSHSession session;
  List<int> byteList = [];
  Completer completer = Completer();
  _SSH_Object(this.client, this.session);
}

void _remoteSshDaemonIsolateEntry(SendPort mainSendPort) async {
  developer.log('SSH daemon started', name: _logName);
  _bindings.gitt_ssh_daemon_init();
  developer.log('SSH daemon init done', name: _logName);

  const int SSH_CMD_TYPE_CONNECT = 0;
  const int SSH_CMD_TYPE_READ = 1;
  const int SSH_CMD_TYPE_WRITE = 2;
  const int SSH_CMD_TYPE_DISCONNECT = 3;
  const int SSH_CMD_TYPE_ERROR = -1;

  int ret;
  Pointer<Int> sshId = malloc.allocate(sizeOf<Pointer<Int>>());
  Pointer<Pointer<Char>> cBuff =
      malloc.allocate(sizeOf<Pointer<Pointer<Char>>>());
  Pointer<Int> swapSize = malloc.allocate(sizeOf<Pointer<Int>>());

  Map sshObjMap = {};
  bool run = true;
  while (run) {
    ret = _bindings.gitt_ssh_daemon_wait(sshId, cBuff, swapSize);
    // developer.log('Wait result: $ret', name: _logName);

    switch (ret) {
      case SSH_CMD_TYPE_CONNECT:
        String str =
            cBuff.value.cast<Utf8>().toDartString(length: swapSize.value);
        // developer.log('Str: $str', name: _logName);
        List<String> list = str.split(';');
        // developer.log('Info Size: ${swapSize.value}', name: _logName);
        if (list.length != 5) {
          developer.log('Invalid argument', name: _logName);
          _bindings.gitt_ssh_daemon_write(-1, -1, 0);
          break;
        }

        String user = list[0];
        String host = list[1];
        String port = list[2];
        String exec = list[3];
        String privkey = list[4];
        developer.log('User: $user', name: _logName);
        developer.log('Host: $host', name: _logName);
        developer.log('Port: $port', name: _logName);
        developer.log('Exec: $exec', name: _logName);

        try {
          // Create SSHClient
          final SSHClient client = SSHClient(
            await SSHSocket.connect(host, int.parse(port)),
            username: user,
            // onPasswordRequest: () => 'password',
            identities: [
              // A single private key file may contain multiple keys.
              // ...SSHKeyPair.fromPem(await File('path/to/id_rsa').readAsString()),
              ...SSHKeyPair.fromPem(privkey),
            ],
          );

          try {
//       final output =
//           await client.run("git-upload-pack 'huxiangjs/gitt_example.git'");
//       setState(() {
//         _text = utf8.decode(output);
//       });
//       print(_text);
            final SSHSession session = await client.execute(exec);
            _SSH_Object sshObject2 = _SSH_Object(client, session);
            sshObjMap[sshObject2.hashCode] = sshObject2;

            // Listen stdout
            sshObject2.session.stdout.listen(
              (event) {
                for (final int byte in event) {
                  sshObject2.byteList.add(byte);
                }
                if (sshObject2.completer.isCompleted == false) {
                  sshObject2.completer.complete();
                }
              },
            );

            // Listen stderr
            // sshObject2.session.stderr.listen(
            //   (event) {
            //     var string = String.fromCharCodes(event);
            //     developer.log('Remote: $string', name: _logName);
            //   },
            // );

            developer.log('SSH Connected', name: _logName);

            _bindings.gitt_ssh_daemon_write(0, sshObject2.hashCode, 0);
          } catch (e) {
            client.close();
            _bindings.gitt_ssh_daemon_write(-1, -1, 0);
            developer.log('SSHSession: ${e.toString()}', name: _logName);
          }
        } catch (e) {
          _bindings.gitt_ssh_daemon_write(-1, -1, 0);
          developer.log('SSHClient: ${e.toString()}', name: _logName);
        }
        break;
      case SSH_CMD_TYPE_READ:
        try {
          // String out =
          //     await utf8.decoder.bind(_sshObject.session.stdout).join();
          // developer.log(out, name: _logName);
          // String err =
          //     await utf8.decoder.bind(_sshObject.session.stderr).join();
          // developer.log(err, name: _logName);
          // developer.log('Need size: ${swapSize.value}', name: _logName);
          _SSH_Object sshObject = sshObjMap[sshId.value];

          sshObject.completer = Completer();
          if (sshObject.byteList.length < swapSize.value) {
            // Wait finish
            await sshObject.completer.future
                .timeout(const Duration(seconds: 10));
          }

          // List => cBuff
          int offset = 0;
          while (sshObject.byteList.isNotEmpty && offset < swapSize.value) {
            cBuff.value[offset] = sshObject.byteList[0];
            offset++;
            sshObject.byteList.removeAt(0);
          }

          // developer.log('Read size: $offset', name: _logName);
          _bindings.gitt_ssh_daemon_write(offset, sshId.value, offset);
        } catch (e) {
          _bindings.gitt_ssh_daemon_write(-1, -1, 0);
          developer.log('SSHRead: ${e.toString()}', name: _logName);
        }
        break;
      case SSH_CMD_TYPE_WRITE:
        try {
          _SSH_Object sshObject0 = sshObjMap[sshId.value];
          // developer.log('Write size: ${swapSize.value}', name: _logName);

          Pointer<Uint8> ptr = cBuff.value.cast<Uint8>();
          // convert to Uint8List
          // NOTE: asTypedList will share the same memory, so we need fromList!
          Uint8List bytesList =
              Uint8List.fromList(ptr.asTypedList(swapSize.value));

          // String hex = '';
          // for (int i = 0; i < bytesList.lengthInBytes; i++) {
          //   hex += '${bytesList[i].toRadixString(16)} ';
          // }
          // developer.log('Write data: $hex', name: _logName);

          sshObject0.session.stdin.add(bytesList);

          _bindings.gitt_ssh_daemon_write(
              swapSize.value, sshId.value, swapSize.value);
        } catch (e) {
          _bindings.gitt_ssh_daemon_write(-1, -1, 0);
          developer.log('SSHWrite: ${e.toString()}', name: _logName);
        }
        break;
      case SSH_CMD_TYPE_DISCONNECT:
        try {
          _SSH_Object sshObject1 = sshObjMap[sshId.value];
          // _sshObject.session.stdin.close();
          sshObject1.session.close();
          // await _sshObject.session.done;
          // print(_sshObject.session.exitCode);
          // Close client
          sshObject1.client.close();
          sshObjMap.remove(sshId.value);
          developer.log('SSH Closed', name: _logName);
          _bindings.gitt_ssh_daemon_write(0, -1, 0);
        } catch (e) {
          _bindings.gitt_ssh_daemon_write(-1, -1, 0);
          developer.log('SSHClose: ${e.toString()}', name: _logName);
        }
        break;
      case SSH_CMD_TYPE_ERROR:
      default:
        _bindings.gitt_ssh_daemon_write(-1, -1, 0);
        run = false;
        break;
    }
  }

  developer.log('Map length: ${sshObjMap.length}', name: _logName);
  developer.log('SSH daemon exited', name: _logName);

  malloc.free(swapSize);
  malloc.free(cBuff);
  malloc.free(sshId);

  Isolate.exit();
}

void remoteSshDaemonStart() async {
  ReceivePort mainReceivePort = ReceivePort();
  await Isolate.spawn(_remoteSshDaemonIsolateEntry, mainReceivePort.sendPort);
}

void remoteSshDaemonStop() async {
  _bindings.gitt_ssh_daemon_deinit();
}
