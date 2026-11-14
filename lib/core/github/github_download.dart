///
/// Created on 2026/11/14
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'github_release.dart';

const String _logName = 'github_download';

const Duration _connectTimeout = Duration(seconds: 30);

///
/// Abort the download when no data is received for this long (a stalled
/// connection), the connect timeout only covers the request itself.
///
const Duration _chunkTimeout = Duration(seconds: 30);

///
/// Thrown by [GitHubDownload.downloadAsset] when the download is
/// cancelled through [DownloadCancelToken].
///
class DownloadCancelledException implements Exception {
  const DownloadCancelledException();

  @override
  String toString() => 'DownloadCancelledException: download cancelled';
}

///
/// Cancels an in-flight [GitHubDownload.downloadAsset] call.
///
/// Cancellation is picked up as soon as the next chunk arrives, or
/// immediately when the connection is stalled (no chunk at all); the
/// partial file is removed on cancellation.
///
class DownloadCancelToken {
  final Completer<void> _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }

  ///
  /// Completes when the download is cancelled.
  ///
  Future<void> get cancelled => _completer.future;
}

///
/// GitHub download helpers.
///
/// Downloaded files are kept in the app-specific external storage
/// (the 'github_downloads' subdir, see [getDownloadDir]) so they are
/// visible in a file manager; when external storage is unavailable
/// the app's private internal storage is used instead.
///
/// The module is repository-agnostic and asset-agnostic: any release
/// asset can be downloaded. The app update flow downloads the APK from
/// the app repository; future device firmware updates (smart IR, button
/// LED, ...) will download firmware assets from their own repositories
/// and hand the file to the device through the corresponding protocol.
///
class GitHubDownload {
  static const String _dirName = 'github_downloads';

  ///
  /// The download directory (created on demand).
  ///
  /// The app-specific external storage
  /// (on Android: the 'github_downloads' subdir of
  /// /sdcard/Android/data/&lt;package&gt;/files) so the files are
  /// visible in a file manager; falls back to the
  /// app's private internal storage when external storage is
  /// unavailable. The FileProvider (res/xml/file_provider_paths.xml)
  /// maps both roots, so the downloaded APK can always be shared with
  /// the package installer.
  ///
  static Future<Directory> getDownloadDir() async {
    Directory? appDir = await getExternalStorageDirectory();
    appDir ??= await getApplicationSupportDirectory();
    Directory dir = Directory(p.join(appDir.path, _dirName));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  ///
  /// Remove all files previously downloaded from GitHub.
  ///
  /// Called at app startup so that leftovers of past updates (e.g. the
  /// APK installed last time) do not accumulate.
  ///
  static Future<void> cleanDownloadDir() async {
    try {
      Directory dir = await getDownloadDir();
      int count = 0;
      for (FileSystemEntity entity in dir.listSync()) {
        entity.deleteSync(recursive: true);
        count++;
      }
      developer.log('Download dir cleaned, removed: $count', name: _logName);
    } catch (e) {
      developer.log('Clean download dir exception: $e', name: _logName);
    }
  }

  ///
  /// Download [asset] into [dir] (default: the download directory, see
  /// [getDownloadDir]) under its original asset name.
  ///
  /// [onProgress] is called with (receivedBytes, totalBytes) while the
  /// download runs; total is 0 when the server did not send a
  /// content-length.
  ///
  /// Returns the downloaded file. A partial file is removed on failure.
  ///
  /// [cancel] can be used to abort the download; the partial file is
  /// removed and a [DownloadCancelledException] is thrown.
  ///
  /// When the file (matched by name) already exists with a matching
  /// size, the download is skipped and the existing file is returned;
  /// the download directory is cleaned at app startup, so any existing
  /// file must have been downloaded during this app run.
  ///
  static Future<File> downloadAsset(
    ReleaseAsset asset, {
    Directory? dir,
    void Function(int received, int total)? onProgress,
    http.Client? client,
    DownloadCancelToken? cancel,
  }) async {
    Directory destDir = dir ?? await getDownloadDir();
    File file = File(p.join(destDir.path, asset.name));

    // Skip the download when the file is already here: the download
    // directory is cleaned at app startup, so an existing file must
    // have been downloaded during this app run. A size mismatch means
    // a corrupt/partial file, which is re-downloaded.
    if (file.existsSync()) {
      int length = file.lengthSync();
      if (asset.size <= 0 || length == asset.size) {
        developer.log(
          'Skip download, file already exists: ${asset.name} ($length bytes)',
          name: _logName,
        );
        return file;
      }
      file.deleteSync();
    }

    final bool ownClient = client == null;
    final http.Client httpClient = client ?? http.Client();

    try {
      developer.log('Download: ${asset.name}', name: _logName);

      http.Request request = http.Request('GET', Uri.parse(asset.url));
      http.StreamedResponse response = await httpClient
          .send(request)
          .timeout(_connectTimeout);

      if (response.statusCode != 200) {
        throw Exception('Download failed: HTTP ${response.statusCode}');
      }

      int total = int.tryParse(response.headers['content-length'] ?? '') ?? 0;
      int received = 0;
      onProgress?.call(0, total);

      IOSink sink = file.openWrite();
      StreamIterator<List<int>> iterator = StreamIterator<List<int>>(response.stream);
      try {
        while (true) {
          if (cancel != null && cancel.isCancelled) {
            throw const DownloadCancelledException();
          }

          // Wait for the next chunk, aborting on a stalled connection
          // (_chunkTimeout) or a cancellation (picked up even when no
          // chunk is arriving at all)
          Future<bool> next = iterator.moveNext();
          bool hasNext;
          if (cancel != null) {
            hasNext = await Future.any([
              next,
              cancel.cancelled.then((_) => false),
            ]).timeout(_chunkTimeout);
            if (cancel.isCancelled) {
              throw const DownloadCancelledException();
            }
          } else {
            hasNext = await next.timeout(_chunkTimeout);
          }
          if (!hasNext) break;

          List<int> chunk = iterator.current;
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
        await sink.flush();
      } finally {
        await iterator.cancel();
        await sink.close();
      }

      developer.log('Downloaded: ${file.path} ($received bytes)', name: _logName);
      return file;
    } catch (e) {
      // Remove the partial file
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
      developer.log('Download exception: $e', name: _logName);
      rethrow;
    } finally {
      if (ownClient) httpClient.close();
    }
  }
}
