///
/// OTA firmware update for the Hoozz Play esp8266 devices.
///
/// The transfer runs on a dedicated encrypted TCP tunnel (a separate port
/// from the control channel), reusing the same frame protocol as the
/// key-transfer tunnel (see tcp_crypto.dart). The device listens on the
/// port given in the FW_UPGRADE url; the app connects, authenticates with a
/// one-time key, and streams the firmware image.
///
/// The firmware image comes from the device's GitHub release zip: the zip
/// carries an "ota_file" that names the app bin the OTA update flashes, so
/// the app does not have to know each project's bin naming convention.
///

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'package:hoozz_play/core/tcp_crypto.dart';
import 'package:path/path.dart' as p;

const String _logName = 'ota_update';

///
/// The OTA tunnel port. Kept separate from the control (54542), discovery
/// (54543) and the on-demand key-transfer tunnel (54550) ports.
///
const int otaPort = 54551;

///
/// The entry name in the release zip that holds the app bin the OTA update
/// flashes.
///
const String _otaFileName = 'ota_file';

///
/// The alphabet the one-time OTA key is drawn from (visible, unambiguous
/// chars; the same set the device uses).
///
const String _otaKeyAlphabet = 'abcdefghijkmnpqrstuvwxyz23456789';

const int _otaKeyLength = 16;
const int _otaChunkSize = 1024;
const String _handshake = 'HoozzPlay';

///
/// Generate a random one-time OTA key (16 visible, unambiguous chars).
///
String generateOtaKey() {
  final Random random = Random.secure();
  return List.generate(
    _otaKeyLength,
    (index) => _otaKeyAlphabet[random.nextInt(_otaKeyAlphabet.length)],
  ).join();
}

///
/// Thrown when the OTA transfer is cancelled by the user.
///
class OtaCancelledException implements Exception {
  const OtaCancelledException();

  @override
  String toString() => 'OtaCancelledException: OTA transfer cancelled';
}

///
/// A one-shot token the caller can use to cancel an in-flight OTA transfer.
///
class OtaCancelToken {
  final Completer<void> _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  ///
  /// Set once the transfer reaches 100%: the device reboots (and drops the
  /// control connection) on its own, so a cancel at that point must not be
  /// treated as an expected disconnect.
  ///
  bool deviceDone = false;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

///
/// Progress callback: (bytesSent, totalBytes, deviceProgressPercent).
/// deviceProgressPercent is -1 when the device did not report it.
///
typedef OtaProgressCallback = void Function(int sent, int total, int devicePct);

///
/// Read the app bin the OTA update flashes (the zip's "ota_file") from the
/// release [zipFile] and extract the firmware it names to a file next to
/// the zip.
///
/// Returns the extracted firmware file.
///
Future<File> extractFirmwareFromZip(File zipFile) async {
  final Archive archive =
      ZipDecoder().decodeBytes(await zipFile.readAsBytes());

  // The ota_file names the app bin (e.g. "smart_ir.bin")
  ArchiveFile? otaEntry;
  for (ArchiveFile file in archive.files) {
    if (file.name.endsWith(_otaFileName)) {
      otaEntry = file;
      break;
    }
  }
  if (otaEntry == null) {
    throw const SocketException('the release zip has no ota_file entry');
  }
  final String binName = utf8.decode(otaEntry.content).trim();
  if (binName.isEmpty) {
    throw const SocketException('the release zip ota_file is empty');
  }
  developer.log('OTA firmware image: $binName', name: _logName);

  // Extract the named bin
  ArchiveFile? binEntry;
  for (ArchiveFile file in archive.files) {
    if (file.name.endsWith(binName)) {
      binEntry = file;
      break;
    }
  }
  if (binEntry == null) {
    throw SocketException('the firmware $binName is not in the release zip');
  }

  final File out = File(p.join(zipFile.parent.path, binName));
  await out.writeAsBytes(binEntry.content);
  return out;
}

///
/// Stream [fwFile] to the device over the OTA tunnel and wait until the
/// device reports 100%. The device reboots a few seconds later on its own;
/// this does not wait for the reboot (the control channel drops then and
/// the caller handles it).
///
/// [ctrl] is the already-connected control-channel handle used for the
/// FW_UPGRADE / FW_PROGRESS commands. [ip] is the device address (the
/// tunnel is opened on [port]). [cancel] optionally allows the caller to
/// abort the transfer; the device then keeps running the current firmware
/// (the image is only committed once fully written and verified) and
/// accepts a new update.
///
Future<void> performOtaTransfer(
  SimpleCtrlHandle ctrl,
  String ip,
  File fwFile, {
  int port = otaPort,
  OtaProgressCallback? onProgress,
  OtaCancelToken? cancel,
}) async {
  final Uint8List fw = await fwFile.readAsBytes();
  final int total = fw.length;
  if (total == 0) {
    throw const SocketException('the firmware file is empty');
  }

  final String otaKey = generateOtaKey();
  final String url = 'hoozz://$otaKey/$port';

  // The device refuses the request while it is busy - typically the 30 s
  // accept window of a previously interrupted OTA (e.g. the client crashed
  // before connecting to the tunnel). It clears itself, so retry until the
  // request is accepted (~45 s max).
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 45));
  bool accepted = false;
  while (!accepted && DateTime.now().isBefore(deadline)) {
    if (cancel != null && cancel.isCancelled) {
      throw const OtaCancelledException();
    }
    accepted = await ctrl.fwUpgrade(url);
    if (!accepted) {
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }
  if (!accepted) {
    throw const SocketException(
        'the device refused the OTA request (it is busy; it recovers '
        '~30 s after an interrupted OTA, then retry)');
  }

  // The device opens its listener right after accepting; retry for a while
  // (its accept window is 30 s).
  TcpCrypto? tunnel;
  final DateTime connectDeadline =
      DateTime.now().add(const Duration(seconds: 30));
  while (tunnel == null && DateTime.now().isBefore(connectDeadline)) {
    if (cancel != null && cancel.isCancelled) {
      throw const OtaCancelledException();
    }
    try {
      final Socket socket = await Socket.connect(ip, port);
      final TcpCrypto tc =
          TcpCrypto(socket, Uint8List.fromList(otaKey.codeUnits));
      // Handshake: the first message each way is "HoozzPlay"; the device
      // verifies the decrypted content, which authenticates the key
      final bool sent =
          await tc.sendFrame(Uint8List.fromList(_handshake.codeUnits));
      if (!sent) {
        await tc.close();
        continue;
      }
      final Uint8List? reply = await tc.recvFrame();
      if (reply == null ||
          reply.length != _handshake.length ||
          String.fromCharCodes(reply) != _handshake) {
        developer.log('OTA tunnel handshake failed (wrong key?)',
            name: _logName);
        await tc.close();
        continue;
      }
      tunnel = tc;
    } catch (e) {
      developer.log('OTA tunnel connect failed: $e', name: _logName);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
  if (tunnel == null) {
    throw SocketException('could not connect to the OTA port $port');
  }
  final TcpCrypto t = tunnel;

  try {
    // Total size (4 bytes, little endian)
    final ByteData sizeData = ByteData(4)..setUint32(0, total, Endian.little);
    final bool sizeSent = await t.sendFrame(sizeData.buffer.asUint8List());
    if (!sizeSent) {
      throw const SocketException('failed to send the firmware size');
    }

    // Stream the firmware in chunks, polling the device progress
    int sent = 0;
    while (sent < total) {
      if (cancel != null && cancel.isCancelled) {
        throw const OtaCancelledException();
      }
      final int end = (sent + _otaChunkSize) < total
          ? (sent + _otaChunkSize)
          : total;
      final bool ok = await t.sendFrame(fw.sublist(sent, end));
      if (!ok) {
        throw const SocketException('failed to send a firmware chunk');
      }
      sent = end;
      // fwProgress returns -1 when the control channel is in a hiccup
      // (the tunnel will fail hard then)
      final int devicePct = await ctrl.fwProgress();
      if (onProgress != null) onProgress(sent, total, devicePct);
    }

    // Wait for the device to reach 100 (it reboots ~3 s later). A lost
    // control channel means the device already rebooted
    int p = 0;
    for (int i = 0; i < 60; i++) {
      if (cancel != null && cancel.isCancelled) {
        throw const OtaCancelledException();
      }
      if (ctrl.stateNotifier.value == SimpleCtrlHandle.stateDestroy) {
        p = 100; // the control channel is gone: the device is rebooting
      } else {
        final int pct = await ctrl.fwProgress();
        if (pct >= 0) p = pct;
      }
      if (p >= 100) {
        // The transfer is complete and the device reboots on its own
        if (cancel != null) cancel.deviceDone = true;
        break;
      }
      if (onProgress != null) onProgress(total, total, p);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  } finally {
    await t.close();
  }
}
