///
/// The value cell of the VERSION row of the Configure device page's info
/// table.
///
/// It is shown only when the firmware version could be fetched from the
/// device (old firmware without OTA support does not answer the command,
/// then the row stays hidden). Once a version is known, the device's
/// GitHub release is checked in the background (by the git hash the image
/// was built from, like the app self-update); a small red dot is shown when
/// a newer version is available. Tapping the cell offers to download the
/// firmware and transfer it to the device over the OTA tunnel; when the
/// transfer finishes, a countdown is shown while the device reboots (the
/// app exits the device page when the connection drops).
///

import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hoozz_play/core/device_binding.dart';
import 'package:hoozz_play/core/github/github_download.dart';
import 'package:hoozz_play/core/github/github_release.dart';
import 'package:hoozz_play/core/ota_update.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'package:hoozz_play/core/simple_snackbar.dart';
import 'package:hoozz_play/themes/theme.dart';

const String _logName = 'FirmwareVersionRow';

// The GitHub repositories publishing the esp8266 firmware releases, keyed
// by device class id. Only the esp8266 devices are listed (the esp32 OTA is
// not done yet).
const Map<int, (String, String)> _firmwareRepos = {
  DeviceBindingList.idSmartIr: ('huxiangjs', 'hoozz_play_esp8266_smart_ir'),
  DeviceBindingList.idSensor: ('huxiangjs', 'hoozz_play_esp8266_sensor'),
  DeviceBindingList.idSwitch: ('huxiangjs', 'hoozz_play_esp8266_switch'),
};

///
/// The small red dot shown after the version when an update is available.
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

class FirmwareVersionRow extends StatefulWidget {
  final DiscoverDeviceInfo device;
  final SimpleCtrlHandle ctrl;
  final String version;

  const FirmwareVersionRow({
    super.key,
    required this.device,
    required this.ctrl,
    required this.version,
  });

  @override
  State<FirmwareVersionRow> createState() => _FirmwareVersionRowState();
}

class _FirmwareVersionRowState extends State<FirmwareVersionRow> {
  LatestRelease? _release;
  bool _updateAvailable = false;
  // Whether the "is there a new release" check against GitHub is in flight
  // (the version cell shows a small spinner while it runs), and whether
  // the last check failed (the cell then offers a tap-to-retry icon)
  bool _checking = false;
  bool _checkFailed = false;
  bool _busy = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _checkUpdate(widget.version);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The value cell of the VERSION row: the whole cell is tappable while
    // an update is available (blue value + red dot, the same convention as
    // the clickable links in the about page); otherwise it is plain
    // information. The red dot sits right after the version (a short 7
    // char git sha). While the release info is being fetched from GitHub
    // a small spinner is shown (the fetch can take a while, or fail on an
    // unstable network); a failed check shows a small refresh icon that
    // re-runs the check on tap.
    return InkWell(
      onTap: _updateAvailable
          ? _onTap
          : (_checkFailed && !_checking ? _onRetryCheck : null),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.version,
            style: TextStyle(
              fontSize: 18,
              fontFamily: subFontFamily,
              color: _updateAvailable ? Colors.blue : null,
            ),
          ),
          if (_checking)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_checkFailed)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.refresh, size: 14, color: subTextColor),
            )
          else if (_updateAvailable)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: _RedDot(),
            ),
        ],
      ),
    );
  }

  Future<void> _checkUpdate(String version) async {
    final (String, String)? entry = _firmwareRepos[widget.device.classId];
    if (entry == null) return;
    if (mounted) {
      setState(() {
        _checking = true;
        _checkFailed = false;
      });
    }
    try {
      final LatestRelease? release =
          await fetchLatestRelease(entry.$1, entry.$2);
      if (!mounted) return;
      setState(() {
        _checking = false;
        if (release != null) {
          _release = release;
          _updateAvailable = !_isSameFirmware(version, release.commitHash);
        }
      });
      if (release == null) return;
      developer.log(
        'Firmware update available: $_updateAvailable '
        '(device: $version, release: ${release.commitHash})',
        name: _logName,
      );
    } catch (e) {
      developer.log('Check for update failed: $e', name: _logName);
      if (mounted) {
        setState(() {
          _checking = false;
          _checkFailed = true;
        });
      }
    }
  }

  ///
  /// Re-run the update check after it failed (the GitHub API can be
  /// flaky and is rate-limited when unauthenticated).
  ///
  void _onRetryCheck() {
    if (_busy || _checking) return;
    _checkUpdate(widget.version);
  }

  static bool _isSameFirmware(String deviceVersion, String releaseCommit) {
    // deviceVersion is a short (7 char) git sha, possibly with a "-dirty"
    // suffix; releaseCommit is the full 40 char sha the release is tagged at
    final String short = deviceVersion.split('-').first;
    return releaseCommit.startsWith(short);
  }

  void _onTap() {
    if (_busy) return;
    _showUpgradeDialog();
  }

  void _showUpgradeDialog() {
    final LatestRelease release = _release!;

    // The firmware zip asset (shown in the dialog, like the apk asset of
    // the app self-update)
    ReleaseAsset? zipAsset;
    for (final asset in release.assets) {
      if (asset.name.endsWith('.zip')) {
        zipAsset = asset;
        break;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Update available',
            style: TextStyle(fontFamily: subFontFamily),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The tag and the (short) git hash the release is tagged
                  // at, like the "Version: x.y.z/<hash>" of the about page
                  Text(
                    'Version: ${release.tag}/${_shortHash(release.commitHash)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: subFontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Published: ${_formatPublishTime(release.publishedAt)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: subFontFamily,
                    ),
                  ),
                  const Divider(),
                  Text(
                    release.message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: subFontFamily,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (zipAsset != null)
                    Text(
                      'Download: ${zipAsset.name} (${_formatSize(zipAsset.size)})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontFamily: subFontFamily,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: subFontFamily),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _upgrade(release);
              },
              child: const Text(
                'Upgrade',
                style: TextStyle(fontFamily: subFontFamily),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _upgrade(LatestRelease release) async {
    // Find the firmware zip asset
    ReleaseAsset? zipAsset;
    for (final asset in release.assets) {
      if (asset.name.endsWith('.zip')) {
        zipAsset = asset;
        break;
      }
    }
    if (zipAsset == null) {
      if (mounted) {
        SimpleSnackBar.show(context, 'No firmware zip in the release', Colors.red);
      }
      return;
    }

    setState(() => _busy = true);

    // Step 1: download the zip (progress dialog)
    final File zipFile;
    try {
      zipFile = await _downloadZip(zipAsset);
    } on DownloadCancelledException {
      if (mounted) setState(() => _busy = false);
      return;
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        SimpleSnackBar.show(context, 'Download failed: $e', Colors.red);
      }
      return;
    }
    if (!mounted) return;

    // Step 2: extract the firmware bin (named by the zip's ota_file)
    final File fwFile;
    try {
      fwFile = await extractFirmwareFromZip(zipFile);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        SimpleSnackBar.show(context, 'Extract firmware failed: $e', Colors.red);
      }
      return;
    }

    // Step 3: transfer the firmware to the device (progress dialog)
    try {
      await _transfer(fwFile);
    } on OtaCancelledException {
      if (mounted) setState(() => _busy = false);
      return;
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        SimpleSnackBar.show(context, 'OTA transfer failed: $e', Colors.red);
      }
      return;
    }

    // Step 4: the device reboots; the app exits when the connection drops
    if (!mounted) return;
    _showRebootCountdown();
  }

  ///
  /// Download [asset] (progress dialog, cancel button).
  ///
  Future<File> _downloadZip(ReleaseAsset asset) async {
    final ValueNotifier<double?> progress = ValueNotifier<double?>(0);
    final ValueNotifier<String> progressText = ValueNotifier<String>('0.0 MB');
    final DownloadCancelToken cancelToken = DownloadCancelToken();
    BuildContext? dialogContext;
    final Completer<void> dialogShown = Completer<void>();

    // Make the close idempotent: more than one path can ask for the dialog
    // to be closed (the Cancel button, plus the code that runs when the
    // operation ends). A second pop would target the route beneath the
    // dialog (e.g. the Configure page) and pop that instead, so only the
    // first close may pop.
    bool dialogClosed = false;

    void closeDialog() {
      if (dialogClosed) return;
      final BuildContext? ctx = dialogContext;
      if (ctx != null && ctx.mounted && Navigator.of(ctx).canPop()) {
        dialogClosed = true;
        Navigator.of(ctx).pop();
      }
    }

    Future<void> ensureDialogClosed() async {
      if (!dialogShown.isCompleted) {
        if (!mounted) return;
        // Give up if the dialog is never built (the download can finish
        // before the first frame, e.g. the file already exists)
        await dialogShown.future.timeout(const Duration(seconds: 2));
      }
      closeDialog();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        dialogContext = dialogCtx;
        if (!dialogShown.isCompleted) dialogShown.complete();
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('Downloading firmware'),
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
                  closeDialog();
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
      await ensureDialogClosed();
      return file;
    } on DownloadCancelledException {
      await ensureDialogClosed();
      throw const DownloadCancelledException();
    } catch (e) {
      await ensureDialogClosed();
      rethrow;
    }
  }

  ///
  /// Transfer [fwFile] to the device over the OTA tunnel (progress dialog,
  /// cancel button).
  ///
  Future<void> _transfer(File fwFile) async {
    final ValueNotifier<double?> progress = ValueNotifier<double?>(0);
    final ValueNotifier<String> progressText =
        ValueNotifier<String>('Connecting to device...');
    final OtaCancelToken cancelToken = OtaCancelToken();
    BuildContext? dialogContext;
    final Completer<void> dialogShown = Completer<void>();

    // Make the close idempotent: more than one path can ask for the dialog
    // to be closed (the Cancel button, plus the code that runs when the
    // operation ends). A second pop would target the route beneath the
    // dialog (e.g. the Configure page) and pop that instead, so only the
    // first close may pop.
    bool dialogClosed = false;

    void closeDialog() {
      if (dialogClosed) return;
      final BuildContext? ctx = dialogContext;
      if (ctx != null && ctx.mounted && Navigator.of(ctx).canPop()) {
        dialogClosed = true;
        Navigator.of(ctx).pop();
      }
    }

    Future<void> ensureDialogClosed() async {
      if (!dialogShown.isCompleted) {
        if (!mounted) return;
        await dialogShown.future.timeout(const Duration(seconds: 2));
      }
      closeDialog();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        dialogContext = dialogCtx;
        if (!dialogShown.isCompleted) dialogShown.complete();
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('Transferring firmware'),
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
                  // The device drops the control connection a few seconds
                  // after an interrupted OTA transfer; mark the handle so
                  // the device page reconnects in place instead of being
                  // popped (unless the transfer already finished and the
                  // device reboots on its own, when the pop is the desired
                  // behavior)
                  if (!cancelToken.deviceDone) {
                    widget.ctrl.expectDisconnect();
                  }
                  closeDialog();
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );

    try {
      await performOtaTransfer(
        widget.ctrl,
        widget.device.ip,
        fwFile,
        onProgress: (sent, total, devicePct) {
          progress.value = total > 0 ? sent / total : null;
          progressText.value = devicePct >= 0
              ? 'Device: $devicePct%   '
                  '(${_formatSize(sent)} / ${_formatSize(total)})'
              : '${_formatSize(sent)} / ${_formatSize(total)}';
        },
        cancel: cancelToken,
      );
      await ensureDialogClosed();
    } on OtaCancelledException {
      await ensureDialogClosed();
      throw const OtaCancelledException();
    } catch (e) {
      await ensureDialogClosed();
      rethrow;
    }
  }

  ///
  /// Show the "device is restarting" countdown. The device reboots a few
  /// seconds after the transfer finishes; the app exits the device page
  /// when the connection drops (the dialog is dismissed then). If the
  /// countdown runs out while still connected, or the user cancels, the
  /// upgrade is allowed to be retried.
  ///
  void _showRebootCountdown() {
    const int total = 10;
    final ValueNotifier<int> remaining = ValueNotifier<int>(total);
    BuildContext? dialogContext;

    // Make the close idempotent: more than one path can ask for the dialog
    // to be closed (the Cancel button, plus the code that runs when the
    // operation ends). A second pop would target the route beneath the
    // dialog (e.g. the Configure page) and pop that instead, so only the
    // first close may pop.
    bool dialogClosed = false;

    void closeDialog() {
      if (dialogClosed) return;
      final BuildContext? ctx = dialogContext;
      if (ctx != null && ctx.mounted && Navigator.of(ctx).canPop()) {
        dialogClosed = true;
        Navigator.of(ctx).pop();
      }
    }

    void onCancel() {
      // The device keeps rebooting on its own; the app exits the device
      // page when the connection drops. Just close the countdown and
      // allow a retry.
      _countdownTimer?.cancel();
      _countdownTimer = null;
      if (mounted) setState(() => _busy = false);
      closeDialog();
    }

    // The dialog is also dismissed automatically when the app exits the
    // device page (the connection drops on reboot)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        dialogContext = dialogCtx;
        // Guard against a rebuild of the dialog creating a second timer
        if (_countdownTimer == null) {
          _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
            int r = remaining.value - 1;
            remaining.value = r < 0 ? 0 : r;
            if (remaining.value <= 0) {
              t.cancel();
              _countdownTimer = null;
              // The device should have rebooted by now (the app would have
              // exited when the connection dropped). If it is still here,
              // allow a retry.
              if (mounted) {
                setState(() => _busy = false);
                closeDialog();
              }
            }
          });
        }
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: const Text('Device is restarting'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Do not power off the device',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<int>(
                  valueListenable: remaining,
                  builder: (context, value, _) {
                    return Text(
                      '$value',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  ///
  /// The (short, 12 char) git hash - the same format the about page shows
  /// for the app build.
  ///
  static String _shortHash(String hash) {
    return hash.length > 12 ? hash.substring(0, 12) : hash;
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
}
