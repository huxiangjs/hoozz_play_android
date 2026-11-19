// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homeTitle => 'Hoozz Play Home';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTitle => 'Hoozz Play Settings';

  @override
  String get toolsTitle => 'Hoozz Play Tools';

  @override
  String get tools => 'Tools';

  @override
  String get vpn => 'VPN';

  @override
  String get about => 'About';

  @override
  String get author => 'Author';

  @override
  String get license => 'License';

  @override
  String get language => 'Language';

  @override
  String get followSystem => 'Follow system';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => 'Chinese';

  @override
  String get toolsEspTouchDesc => 'Smart configuration network';

  @override
  String get toolsDiscoverDesc => 'Discover configured devices';

  @override
  String get ssid => 'SSID';

  @override
  String get ssidHint => 'It\'s your Wi-Fi network name (SSID)';

  @override
  String get password => 'PASSWORD';

  @override
  String get passwordHint => 'It\'s your Wi-Fi network password';

  @override
  String get only24GHz => 'Only supports 2.4GHz network';

  @override
  String get config => 'CONFIG';

  @override
  String get configuredDevices => 'Configured devices:';

  @override
  String get unableStartConfig => 'Unable to start configuration';

  @override
  String get cantGetWifi => 'Can\'t get WiFi information';

  @override
  String get go => 'Go';

  @override
  String get cancel => 'Cancel';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get save => 'Save';

  @override
  String get start => 'Start';

  @override
  String get test => 'Test';

  @override
  String get restart => 'Restart';

  @override
  String get update => 'Update';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get select => 'Select';

  @override
  String get warning => 'Warning';

  @override
  String get deleteDeviceConfirm =>
      'Are you sure you want to delete this device?';

  @override
  String get online => '[online]';

  @override
  String get offline => '[offline]';

  @override
  String deviceId(String id) {
    return 'id: $id';
  }

  @override
  String get addNewDevice => 'Add new device';

  @override
  String get nickName => 'Nick name';

  @override
  String get nickNameHint => 'Give your device a name';

  @override
  String get repository => 'Repository';

  @override
  String get repositoryHint => 'Enter the device repository URL';

  @override
  String get privateKey => 'Private key';

  @override
  String get privateKeyHint =>
      'Enter your private key to access the repository';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get addedSuccessfully => 'Added successfully';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get deviceInit => 'Device Init...';

  @override
  String get callingDevice => 'Calling device...';

  @override
  String get waitResult => 'Wait result...';

  @override
  String stateLabel(String state) {
    return 'State: $state';
  }

  @override
  String get onState => 'ON';

  @override
  String get offState => 'OFF';

  @override
  String get unknown => 'Unknown';

  @override
  String get clickMe => 'Click Me';

  @override
  String errorSettingRefreshRate(String rate) {
    return 'Error setting refresh rate set to ${rate}Hz';
  }

  @override
  String get connectionSucceeded => 'Connection succeeded';

  @override
  String screenshotSaved(String path) {
    return 'Screenshot saved to $path';
  }

  @override
  String screenshotFailed(String error) {
    return 'Failed to take screenshot: $error';
  }

  @override
  String maxTemp(String temp) {
    return 'MAX: $temp°C';
  }

  @override
  String minTemp(String temp) {
    return 'MIN: $temp°C';
  }

  @override
  String crosshairTemp(String temp) {
    return 'Crosshair: $temp°C';
  }

  @override
  String tempValue(String temp) {
    return '$temp°C';
  }

  @override
  String get refreshRateLabel => 'Refresh\nrate(Hz):';

  @override
  String get rotateLabel => 'Rotate:';

  @override
  String get traceLabel => 'Trace:';

  @override
  String get mirrorLabel => 'Mirror:';

  @override
  String get emissivityLabel => 'Emissivity:';

  @override
  String errorSettingEmissivity(String value) {
    return 'Error setting emissivity set to $value';
  }

  @override
  String get taShiftLabel => 'Ta shift:';

  @override
  String errorSettingTaShift(String value) {
    return 'Error setting Ta shift set to $value';
  }

  @override
  String get screenshot => 'Screenshot';

  @override
  String get configureDevice => 'Configure device';

  @override
  String get nameLabel => 'NAME:';

  @override
  String get classLabel => 'CLASS:';

  @override
  String get idLabel => 'ID:';

  @override
  String get ipLabel => 'IP:';

  @override
  String get versionLabel => 'VERSION:';

  @override
  String get restartDevice => 'Restart device';

  @override
  String get restartDeviceConfirm =>
      'The device will restart shortly and may be unreachable for a while. Continue?';

  @override
  String get deviceIsRestarting => 'Device is restarting';

  @override
  String get restartRequestFailed => 'Restart request failed';

  @override
  String get deviceNickName => 'Device nick name';

  @override
  String get deviceNickNameHint => 'Set a nick name for your device';

  @override
  String get accessKey => 'Access key';

  @override
  String get accessKeyHint => 'Set access key for your device';

  @override
  String get syncNameToRemote => 'Sync name to remote';

  @override
  String get updateAvailable => 'Update available';

  @override
  String versionLine(String version) {
    return 'Version: $version';
  }

  @override
  String publishedLine(String time) {
    return 'Published: $time';
  }

  @override
  String downloadLine(String name, String size) {
    return 'Download: $name ($size)';
  }

  @override
  String get noFirmwareZip => 'No firmware zip in the release';

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String extractFirmwareFailed(String error) {
    return 'Extract firmware failed: $error';
  }

  @override
  String otaTransferFailed(String error) {
    return 'OTA transfer failed: $error';
  }

  @override
  String get downloadingFirmware => 'Downloading firmware';

  @override
  String get transferringFirmware => 'Transferring firmware';

  @override
  String get doNotPowerOff => 'Do not power off the device';

  @override
  String get connectingToDevice => 'Connecting to device...';

  @override
  String transferProgress(int percent, String sent, String total) {
    return 'Device: $percent%   ($sent / $total)';
  }

  @override
  String sizeProgress(String sent, String total) {
    return '$sent / $total';
  }

  @override
  String get appDescription =>
      'Hoozz Play is a personal open source project where all the fun things will be shared';

  @override
  String get downloadingUpdate => 'Downloading update';

  @override
  String get allowInstallUnknownApps =>
      'Allow \"Install unknown apps\" for Hoozz Play, then try again';

  @override
  String get installFailed => 'Install failed, try again';

  @override
  String get downloadCancelled => 'Download cancelled';

  @override
  String get onlineState => 'Online';

  @override
  String get offlineState => 'Offline';

  @override
  String portProtocol(String port, String protocol) {
    return 'port: $port  |  protocol: $protocol';
  }

  @override
  String get deleteConfigConfirm =>
      'Are you sure you want to delete this config?';

  @override
  String get clipboardEmpty => 'Clipboard is empty';

  @override
  String get addConfigFromClipboard => 'Add config from clipboard ...';

  @override
  String get contentFormatError => 'Content format error';

  @override
  String get operationCanceled => 'Operation canceled';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get addConfigFromFile => 'Add config from file ...';

  @override
  String get abnormalDeviceData => 'Abnormal device data';

  @override
  String get deviceConnectionFailed => 'Device connection failed';

  @override
  String get deviceConnecting => 'Device connecting...';

  @override
  String get verifyingDevice => 'Verifying device...';

  @override
  String get deviceInformationSaved => 'Device information saved';

  @override
  String get configureDeviceFailed => 'Failed to configure device information';

  @override
  String get deviceSaved => 'Device saved';

  @override
  String get noData => 'No data';

  @override
  String get unsupported => 'Unsupported';

  @override
  String get selectAllOrDeselectAll => 'Select All or Deselect All';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get noDevicesSelected => 'No devices have been selected';

  @override
  String get changelist => 'Changelist';

  @override
  String get sync => 'Sync';

  @override
  String get setSwitchStateFailed => 'Set switch state failed';

  @override
  String get voltage => 'Voltage';

  @override
  String get current => 'Current';

  @override
  String get power => 'Power';

  @override
  String get energy => 'Energy';

  @override
  String deletingKeys(int count) {
    return 'Deleting $count keys...';
  }

  @override
  String removedKeys(int count) {
    return 'Removed $count keys';
  }

  @override
  String removedKeysPartial(int ok, int count) {
    return 'Removed $ok/$count keys';
  }

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get keyNameTooLong => 'Key name too long';

  @override
  String get readFileFailed => 'Read file failed';

  @override
  String get keyDataSizeInvalid => 'Key data must be 1-1024 bytes';

  @override
  String importingFiles(int count) {
    return 'Importing $count files...';
  }

  @override
  String importedKeys(int count) {
    return 'Imported $count keys';
  }

  @override
  String importedKeysPartial(int ok, int count) {
    return 'Imported $ok/$count keys';
  }

  @override
  String get importFailed => 'Import failed';

  @override
  String exportingKeys(int count) {
    return 'Exporting $count keys...';
  }

  @override
  String savedTo(String folder) {
    return 'Saved: $folder';
  }

  @override
  String exportedKeysPartial(int ok, int count) {
    return 'Exported $ok/$count keys';
  }

  @override
  String get exportFailed => 'Export failed';

  @override
  String get selectKeysFirst => 'Select keys first';

  @override
  String get importKeys => 'Import keys';

  @override
  String get exportSelectedKeys => 'Export selected keys';

  @override
  String get deleteSelectedKeys => 'Delete selected keys';

  @override
  String get keyTransferMode => 'Key transfer mode';

  @override
  String get exitTransferMode => 'Exit transfer mode';

  @override
  String deleteKeysConfirm(int count) {
    return 'Are you sure you want to delete the selected $count keys?';
  }

  @override
  String get addKey => 'Add key';

  @override
  String irDataFormat(String count, String length) {
    return '$count | ${length}p';
  }

  @override
  String get irDataEmpty => '--- | ---p';

  @override
  String get enterKeyName => 'Enter key name';

  @override
  String get saved => 'Saved';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get sendFailed => 'Send failed';
}
