///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:hoozz_play/core/build_info.dart';
import 'package:hoozz_play/core/github/github_download.dart';
import 'package:hoozz_play/core/github/github_release.dart';
import 'package:hoozz_play/core/simple_snackbar.dart';

const String _logName = 'About';

// The repository that publishes the app APK releases
// (.github/workflows/android.yml creates a release on every tag push)
const String _updateRepoOwner = 'huxiangjs';
const String _updateRepoName = 'hoozz_play_android';

///
/// The small red dot shown after the version line when an update is
/// available.
///
class _RedDot extends StatelessWidget {
  const _RedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}

class HoozzPlayAboutPage extends StatefulWidget {
  const HoozzPlayAboutPage({super.key});

  final String title = 'About';

  @override
  State<HoozzPlayAboutPage> createState() => _HoozzPlayAboutPageState();
}

class _HoozzPlayAboutPageState extends State<HoozzPlayAboutPage>
    with WidgetsBindingObserver {
  static const MethodChannel _updateChannel = MethodChannel('UPDATE_METHOD');

  String _appName = '';
  String _version = '';
  String _gitHash = '';
  final String _description =
      'Hoozz Play is a personal open source project where all the fun things will be shared';
  final String _githubUrl = 'https://github.com/huxiangjs/hoozz_play.git';

  /* Update state */
  LatestRelease? _latestRelease;
  bool _updateAvailable = false;
  // The already-downloaded APK whose install was blocked by the missing
  // "Install unknown apps" permission; retried when the app comes back
  // to the foreground (e.g. after the settings page was opened)
  String? _pendingApkPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // When the app returns to the foreground (e.g. the user granted
  // "Install unknown apps" in the settings page), retry the install of
  // the already-downloaded APK
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed || _pendingApkPath == null) return;
    _retryPendingInstall();
  }

  Future<void> _retryPendingInstall() async {
    String path = _pendingApkPath!;
    _pendingApkPath = null;

    if (!await _canInstallApk()) {
      _pendingApkPath = path;
      if (mounted) {
        SimpleSnackBar.show(
          context,
          'Allow "Install unknown apps" for Hoozz Play, then try again',
          Colors.red,
        );
      }
      return;
    }

    bool launched = await _installApk(path);
    if (mounted && !launched) {
      SimpleSnackBar.show(context, 'Install failed, try again', Colors.red);
    }
  }

  Future<void> _loadInfo() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String gitHash = await BuildInfo.getGitHash();
    if (!mounted) return;
    setState(() {
      _appName = packageInfo.appName;
      _version = packageInfo.version;
      _gitHash = gitHash;
    });
    // Check for an update in the background: compare the git hash this
    // build was compiled from with the commit the latest release was
    // tagged at
    _checkUpdate(gitHash);
  }

  Future<void> _checkUpdate(String buildHash) async {
    try {
      LatestRelease? release = await fetchLatestRelease(
        _updateRepoOwner,
        _updateRepoName,
      );
      if (!mounted) return;
      if (release == null) {
        developer.log('No release found', name: _logName);
        return;
      }
      if (release.apkAsset == null) {
        developer.log('Release ${release.tag} has no apk asset', name: _logName);
        return;
      }
      setState(() {
        _latestRelease = release;
        _updateAvailable = !_isSameCommit(buildHash, release.commitHash);
      });
      developer.log(
        'Update available: $_updateAvailable '
        '(build: $buildHash, release: ${release.commitHash})',
        name: _logName,
      );
    } catch (e) {
      developer.log('Check update exception: $e', name: _logName);
    }
  }

  static bool _isSameCommit(String buildHash, String releaseHash) {
    // buildHash is a short (12 char) prefix of the full 40 char sha
    if (buildHash == BuildInfo.unknown) return false;
    return releaseHash.startsWith(buildHash);
  }

  ///
  /// Launch the system APK installer for [path] (the file lives in the
  /// GitHub download directory, see GitHubDownload.getDownloadDir; the
  /// Java side shares it through a FileProvider).
  ///
  /// Returns true when the installer was launched, false when the user
  /// still has to grant "Install unknown apps" (the settings page is
  /// opened then) or the launch failed.
  ///
  Future<bool> _installApk(String path) async {
    try {
      bool? result =
          await _updateChannel.invokeMethod<bool>('installApk', {'path': path});
      return result == true;
    } on PlatformException catch (e) {
      developer.log('installApk exception: $e', name: _logName);
      return false;
    }
  }

  Future<bool> _canInstallApk() async {
    try {
      bool? result = await _updateChannel.invokeMethod<bool>('canInstallApk');
      return result == true;
    } on PlatformException {
      return true;
    }
  }

  void _showUpdateDialog() {
    LatestRelease release = _latestRelease!;
    ReleaseAsset? asset = release.apkAsset;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update available'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version: ${release.tag}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Published: ${_formatPublishTime(release.publishedAt)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const Divider(),
                  Text(
                    release.message,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 10),
                  if (asset != null)
                    Text(
                      'Download: ${asset.name} (${_formatSize(asset.size)})',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _update(release);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  ///
  /// Download the release APK (progress dialog) and launch the system
  /// installer when done.
  ///
  Future<void> _update(LatestRelease release) async {
    ReleaseAsset? asset = release.apkAsset;
    if (asset == null) return;

    // null => indeterminate bar (no content-length from the server)
    final ValueNotifier<double?> progress = ValueNotifier<double?>(0);
    final ValueNotifier<String> progressText = ValueNotifier<String>('0.0 MB');
    final DownloadCancelToken cancelToken = DownloadCancelToken();
    BuildContext? dialogContext;
    // Completes when the dialog is actually built (the builder runs on
    // the first frame). The download can finish before that (e.g. the
    // file already exists and the download is skipped), so closing has
    // to wait until the dialog is really on screen
    final Completer<void> dialogShown = Completer<void>();

    void closeProgressDialog() {
      final BuildContext? dialogCtx = dialogContext;
      if (dialogCtx != null &&
          dialogCtx.mounted &&
          Navigator.of(dialogCtx).canPop()) {
        Navigator.of(dialogCtx).pop();
      }
    }

    Future<void> ensureDialogClosed() async {
      if (!dialogShown.isCompleted) {
        if (!mounted) return;
        // Give up if the dialog is never built (e.g. the page was
        // disposed before the first frame)
        await dialogShown.future.timeout(const Duration(seconds: 2));
      }
      closeProgressDialog();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        dialogContext = dialogCtx;
        if (!dialogShown.isCompleted) dialogShown.complete();
        return WillPopScope(
          onWillPop: () async => false, // Disable return key
          child: AlertDialog(
            title: const Text('Downloading update'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<double?>(
                  valueListenable: progress,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 20,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: ValueListenableBuilder<String>(
                    valueListenable: progressText,
                    builder: (context, value, _) {
                      return Text(
                        value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cancelToken.cancel();
                  closeProgressDialog();
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );

    try {
      File file = await GitHubDownload.downloadAsset(
        asset,
        onProgress: (received, total) {
          if (total > 0) {
            progress.value = received / total;
            progressText.value =
                '${_formatSize(received)} / ${_formatSize(total)}  '
                '${(received * 100 / total).toStringAsFixed(0)}%';
          } else {
            progress.value = null; // Indeterminate
            progressText.value = _formatSize(received);
          }
        },
        cancel: cancelToken,
      );

      // The user may have cancelled at the very last moment
      if (cancelToken.isCancelled) return;

      await ensureDialogClosed();

      bool launched = await _installApk(file.path);
      if (!mounted) return;
      if (!launched) {
        // The settings page was opened; the install is retried
        // automatically when the app comes back to the foreground
        _pendingApkPath = file.path;
        SimpleSnackBar.show(
          context,
          'Allow "Install unknown apps" for Hoozz Play, then try again',
          Colors.red,
        );
      }
    } on DownloadCancelledException {
      await ensureDialogClosed();
      if (mounted) {
        SimpleSnackBar.show(context, 'Download cancelled', Colors.grey);
      }
    } catch (e) {
      developer.log('Download update failed: $e', name: _logName);
      await ensureDialogClosed();
      if (mounted) {
        SimpleSnackBar.show(context, 'Download failed: $e', Colors.red);
      }
    }
  }

  static String _formatPublishTime(String iso) {
    try {
      DateTime dt = DateTime.parse(iso).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
          '${two(dt.hour)}:${two(dt.minute)}';
    } catch (e) {
      return iso;
    }
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  void _launchGitHub() async {
    Uri uri = Uri.parse(_githubUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.fromLTRB(4, 60, 4, 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              'images/app_icon.png',
              // fit: BoxFit.fill,
            ),
            const SizedBox(height: 10),
            Text(
              _appName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            /* Version line: red dot + clickable when an update is available */
            InkWell(
              onTap: _updateAvailable ? () => _showUpdateDialog() : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Version: $_version/$_gitHash',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  if (_updateAvailable)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: _RedDot(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _description,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _launchGitHub();
              },
              child: Text(
                _githubUrl,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
