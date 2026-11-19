import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hoozz Play Home'**
  String get homeTitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hoozz Play Settings'**
  String get settingsTitle;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hoozz Play Tools'**
  String get toolsTitle;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @vpn.
  ///
  /// In en, this message translates to:
  /// **'VPN'**
  String get vpn;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @followSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get languageChinese;

  /// No description provided for @toolsEspTouchDesc.
  ///
  /// In en, this message translates to:
  /// **'Smart configuration network'**
  String get toolsEspTouchDesc;

  /// No description provided for @toolsDiscoverDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover configured devices'**
  String get toolsDiscoverDesc;

  /// No description provided for @ssid.
  ///
  /// In en, this message translates to:
  /// **'SSID'**
  String get ssid;

  /// No description provided for @ssidHint.
  ///
  /// In en, this message translates to:
  /// **'It\'s your Wi-Fi network name (SSID)'**
  String get ssidHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'It\'s your Wi-Fi network password'**
  String get passwordHint;

  /// No description provided for @only24GHz.
  ///
  /// In en, this message translates to:
  /// **'Only supports 2.4GHz network'**
  String get only24GHz;

  /// No description provided for @config.
  ///
  /// In en, this message translates to:
  /// **'CONFIG'**
  String get config;

  /// No description provided for @configuredDevices.
  ///
  /// In en, this message translates to:
  /// **'Configured devices:'**
  String get configuredDevices;

  /// No description provided for @unableStartConfig.
  ///
  /// In en, this message translates to:
  /// **'Unable to start configuration'**
  String get unableStartConfig;

  /// No description provided for @cantGetWifi.
  ///
  /// In en, this message translates to:
  /// **'Can\'t get WiFi information'**
  String get cantGetWifi;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @restart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get restart;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @deleteDeviceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this device?'**
  String get deleteDeviceConfirm;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'[online]'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'[offline]'**
  String get offline;

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'id: {id}'**
  String deviceId(String id);

  /// No description provided for @addNewDevice.
  ///
  /// In en, this message translates to:
  /// **'Add new device'**
  String get addNewDevice;

  /// No description provided for @nickName.
  ///
  /// In en, this message translates to:
  /// **'Nick name'**
  String get nickName;

  /// No description provided for @nickNameHint.
  ///
  /// In en, this message translates to:
  /// **'Give your device a name'**
  String get nickNameHint;

  /// No description provided for @repository.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get repository;

  /// No description provided for @repositoryHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the device repository URL'**
  String get repositoryHint;

  /// No description provided for @privateKey.
  ///
  /// In en, this message translates to:
  /// **'Private key'**
  String get privateKey;

  /// No description provided for @privateKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your private key to access the repository'**
  String get privateKeyHint;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @addedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Added successfully'**
  String get addedSuccessfully;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @deviceInit.
  ///
  /// In en, this message translates to:
  /// **'Device Init...'**
  String get deviceInit;

  /// No description provided for @callingDevice.
  ///
  /// In en, this message translates to:
  /// **'Calling device...'**
  String get callingDevice;

  /// No description provided for @waitResult.
  ///
  /// In en, this message translates to:
  /// **'Wait result...'**
  String get waitResult;

  /// No description provided for @stateLabel.
  ///
  /// In en, this message translates to:
  /// **'State: {state}'**
  String stateLabel(String state);

  /// No description provided for @onState.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get onState;

  /// No description provided for @offState.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get offState;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @clickMe.
  ///
  /// In en, this message translates to:
  /// **'Click Me'**
  String get clickMe;

  /// No description provided for @errorSettingRefreshRate.
  ///
  /// In en, this message translates to:
  /// **'Error setting refresh rate set to {rate}Hz'**
  String errorSettingRefreshRate(String rate);

  /// No description provided for @connectionSucceeded.
  ///
  /// In en, this message translates to:
  /// **'Connection succeeded'**
  String get connectionSucceeded;

  /// No description provided for @screenshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Screenshot saved to {path}'**
  String screenshotSaved(String path);

  /// No description provided for @screenshotFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to take screenshot: {error}'**
  String screenshotFailed(String error);

  /// No description provided for @maxTemp.
  ///
  /// In en, this message translates to:
  /// **'MAX: {temp}°C'**
  String maxTemp(String temp);

  /// No description provided for @minTemp.
  ///
  /// In en, this message translates to:
  /// **'MIN: {temp}°C'**
  String minTemp(String temp);

  /// No description provided for @crosshairTemp.
  ///
  /// In en, this message translates to:
  /// **'Crosshair: {temp}°C'**
  String crosshairTemp(String temp);

  /// No description provided for @tempValue.
  ///
  /// In en, this message translates to:
  /// **'{temp}°C'**
  String tempValue(String temp);

  /// No description provided for @refreshRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Refresh\nrate(Hz):'**
  String get refreshRateLabel;

  /// No description provided for @rotateLabel.
  ///
  /// In en, this message translates to:
  /// **'Rotate:'**
  String get rotateLabel;

  /// No description provided for @traceLabel.
  ///
  /// In en, this message translates to:
  /// **'Trace:'**
  String get traceLabel;

  /// No description provided for @mirrorLabel.
  ///
  /// In en, this message translates to:
  /// **'Mirror:'**
  String get mirrorLabel;

  /// No description provided for @emissivityLabel.
  ///
  /// In en, this message translates to:
  /// **'Emissivity:'**
  String get emissivityLabel;

  /// No description provided for @errorSettingEmissivity.
  ///
  /// In en, this message translates to:
  /// **'Error setting emissivity set to {value}'**
  String errorSettingEmissivity(String value);

  /// No description provided for @taShiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Ta shift:'**
  String get taShiftLabel;

  /// No description provided for @errorSettingTaShift.
  ///
  /// In en, this message translates to:
  /// **'Error setting Ta shift set to {value}'**
  String errorSettingTaShift(String value);

  /// No description provided for @screenshot.
  ///
  /// In en, this message translates to:
  /// **'Screenshot'**
  String get screenshot;

  /// No description provided for @configureDevice.
  ///
  /// In en, this message translates to:
  /// **'Configure device'**
  String get configureDevice;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'NAME:'**
  String get nameLabel;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'CLASS:'**
  String get classLabel;

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID:'**
  String get idLabel;

  /// No description provided for @ipLabel.
  ///
  /// In en, this message translates to:
  /// **'IP:'**
  String get ipLabel;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'VERSION:'**
  String get versionLabel;

  /// No description provided for @restartDevice.
  ///
  /// In en, this message translates to:
  /// **'Restart device'**
  String get restartDevice;

  /// No description provided for @restartDeviceConfirm.
  ///
  /// In en, this message translates to:
  /// **'The device will restart shortly and may be unreachable for a while. Continue?'**
  String get restartDeviceConfirm;

  /// No description provided for @deviceIsRestarting.
  ///
  /// In en, this message translates to:
  /// **'Device is restarting'**
  String get deviceIsRestarting;

  /// No description provided for @restartRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Restart request failed'**
  String get restartRequestFailed;

  /// No description provided for @deviceNickName.
  ///
  /// In en, this message translates to:
  /// **'Device nick name'**
  String get deviceNickName;

  /// No description provided for @deviceNickNameHint.
  ///
  /// In en, this message translates to:
  /// **'Set a nick name for your device'**
  String get deviceNickNameHint;

  /// No description provided for @accessKey.
  ///
  /// In en, this message translates to:
  /// **'Access key'**
  String get accessKey;

  /// No description provided for @accessKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Set access key for your device'**
  String get accessKeyHint;

  /// No description provided for @syncNameToRemote.
  ///
  /// In en, this message translates to:
  /// **'Sync name to remote'**
  String get syncNameToRemote;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @versionLine.
  ///
  /// In en, this message translates to:
  /// **'Version: {version}'**
  String versionLine(String version);

  /// No description provided for @publishedLine.
  ///
  /// In en, this message translates to:
  /// **'Published: {time}'**
  String publishedLine(String time);

  /// No description provided for @downloadLine.
  ///
  /// In en, this message translates to:
  /// **'Download: {name} ({size})'**
  String downloadLine(String name, String size);

  /// No description provided for @noFirmwareZip.
  ///
  /// In en, this message translates to:
  /// **'No firmware zip in the release'**
  String get noFirmwareZip;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @extractFirmwareFailed.
  ///
  /// In en, this message translates to:
  /// **'Extract firmware failed: {error}'**
  String extractFirmwareFailed(String error);

  /// No description provided for @otaTransferFailed.
  ///
  /// In en, this message translates to:
  /// **'OTA transfer failed: {error}'**
  String otaTransferFailed(String error);

  /// No description provided for @downloadingFirmware.
  ///
  /// In en, this message translates to:
  /// **'Downloading firmware'**
  String get downloadingFirmware;

  /// No description provided for @transferringFirmware.
  ///
  /// In en, this message translates to:
  /// **'Transferring firmware'**
  String get transferringFirmware;

  /// No description provided for @doNotPowerOff.
  ///
  /// In en, this message translates to:
  /// **'Do not power off the device'**
  String get doNotPowerOff;

  /// No description provided for @connectingToDevice.
  ///
  /// In en, this message translates to:
  /// **'Connecting to device...'**
  String get connectingToDevice;

  /// No description provided for @transferProgress.
  ///
  /// In en, this message translates to:
  /// **'Device: {percent}%   ({sent} / {total})'**
  String transferProgress(int percent, String sent, String total);

  /// No description provided for @sizeProgress.
  ///
  /// In en, this message translates to:
  /// **'{sent} / {total}'**
  String sizeProgress(String sent, String total);

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Hoozz Play is a personal open source project where all the fun things will be shared'**
  String get appDescription;

  /// No description provided for @downloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Downloading update'**
  String get downloadingUpdate;

  /// No description provided for @allowInstallUnknownApps.
  ///
  /// In en, this message translates to:
  /// **'Allow \"Install unknown apps\" for Hoozz Play, then try again'**
  String get allowInstallUnknownApps;

  /// No description provided for @installFailed.
  ///
  /// In en, this message translates to:
  /// **'Install failed, try again'**
  String get installFailed;

  /// No description provided for @downloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled'**
  String get downloadCancelled;

  /// No description provided for @onlineState.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onlineState;

  /// No description provided for @offlineState.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineState;

  /// No description provided for @portProtocol.
  ///
  /// In en, this message translates to:
  /// **'port: {port}  |  protocol: {protocol}'**
  String portProtocol(String port, String protocol);

  /// No description provided for @deleteConfigConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this config?'**
  String get deleteConfigConfirm;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get clipboardEmpty;

  /// No description provided for @addConfigFromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Add config from clipboard ...'**
  String get addConfigFromClipboard;

  /// No description provided for @contentFormatError.
  ///
  /// In en, this message translates to:
  /// **'Content format error'**
  String get contentFormatError;

  /// No description provided for @operationCanceled.
  ///
  /// In en, this message translates to:
  /// **'Operation canceled'**
  String get operationCanceled;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// No description provided for @addConfigFromFile.
  ///
  /// In en, this message translates to:
  /// **'Add config from file ...'**
  String get addConfigFromFile;

  /// No description provided for @abnormalDeviceData.
  ///
  /// In en, this message translates to:
  /// **'Abnormal device data'**
  String get abnormalDeviceData;

  /// No description provided for @deviceConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Device connection failed'**
  String get deviceConnectionFailed;

  /// No description provided for @deviceConnecting.
  ///
  /// In en, this message translates to:
  /// **'Device connecting...'**
  String get deviceConnecting;

  /// No description provided for @verifyingDevice.
  ///
  /// In en, this message translates to:
  /// **'Verifying device...'**
  String get verifyingDevice;

  /// No description provided for @deviceInformationSaved.
  ///
  /// In en, this message translates to:
  /// **'Device information saved'**
  String get deviceInformationSaved;

  /// No description provided for @configureDeviceFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to configure device information'**
  String get configureDeviceFailed;

  /// No description provided for @deviceSaved.
  ///
  /// In en, this message translates to:
  /// **'Device saved'**
  String get deviceSaved;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @unsupported.
  ///
  /// In en, this message translates to:
  /// **'Unsupported'**
  String get unsupported;

  /// No description provided for @selectAllOrDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All or Deselect All'**
  String get selectAllOrDeselectAll;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @noDevicesSelected.
  ///
  /// In en, this message translates to:
  /// **'No devices have been selected'**
  String get noDevicesSelected;

  /// No description provided for @changelist.
  ///
  /// In en, this message translates to:
  /// **'Changelist'**
  String get changelist;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @setSwitchStateFailed.
  ///
  /// In en, this message translates to:
  /// **'Set switch state failed'**
  String get setSwitchStateFailed;

  /// No description provided for @voltage.
  ///
  /// In en, this message translates to:
  /// **'Voltage'**
  String get voltage;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @power.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get power;

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @deletingKeys.
  ///
  /// In en, this message translates to:
  /// **'Deleting {count} keys...'**
  String deletingKeys(int count);

  /// No description provided for @removedKeys.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} keys'**
  String removedKeys(int count);

  /// No description provided for @removedKeysPartial.
  ///
  /// In en, this message translates to:
  /// **'Removed {ok}/{count} keys'**
  String removedKeysPartial(int ok, int count);

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @keyNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Key name too long'**
  String get keyNameTooLong;

  /// No description provided for @readFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Read file failed'**
  String get readFileFailed;

  /// No description provided for @keyDataSizeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Key data must be 1-1024 bytes'**
  String get keyDataSizeInvalid;

  /// No description provided for @importingFiles.
  ///
  /// In en, this message translates to:
  /// **'Importing {count} files...'**
  String importingFiles(int count);

  /// No description provided for @importedKeys.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} keys'**
  String importedKeys(int count);

  /// No description provided for @importedKeysPartial.
  ///
  /// In en, this message translates to:
  /// **'Imported {ok}/{count} keys'**
  String importedKeysPartial(int ok, int count);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed'**
  String get importFailed;

  /// No description provided for @exportingKeys.
  ///
  /// In en, this message translates to:
  /// **'Exporting {count} keys...'**
  String exportingKeys(int count);

  /// No description provided for @savedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved: {folder}'**
  String savedTo(String folder);

  /// No description provided for @exportedKeysPartial.
  ///
  /// In en, this message translates to:
  /// **'Exported {ok}/{count} keys'**
  String exportedKeysPartial(int ok, int count);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get exportFailed;

  /// No description provided for @selectKeysFirst.
  ///
  /// In en, this message translates to:
  /// **'Select keys first'**
  String get selectKeysFirst;

  /// No description provided for @importKeys.
  ///
  /// In en, this message translates to:
  /// **'Import keys'**
  String get importKeys;

  /// No description provided for @exportSelectedKeys.
  ///
  /// In en, this message translates to:
  /// **'Export selected keys'**
  String get exportSelectedKeys;

  /// No description provided for @deleteSelectedKeys.
  ///
  /// In en, this message translates to:
  /// **'Delete selected keys'**
  String get deleteSelectedKeys;

  /// No description provided for @keyTransferMode.
  ///
  /// In en, this message translates to:
  /// **'Key transfer mode'**
  String get keyTransferMode;

  /// No description provided for @exitTransferMode.
  ///
  /// In en, this message translates to:
  /// **'Exit transfer mode'**
  String get exitTransferMode;

  /// No description provided for @deleteKeysConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the selected {count} keys?'**
  String deleteKeysConfirm(int count);

  /// No description provided for @addKey.
  ///
  /// In en, this message translates to:
  /// **'Add key'**
  String get addKey;

  /// No description provided for @irDataFormat.
  ///
  /// In en, this message translates to:
  /// **'{count} | {length}p'**
  String irDataFormat(String count, String length);

  /// No description provided for @irDataEmpty.
  ///
  /// In en, this message translates to:
  /// **'--- | ---p'**
  String get irDataEmpty;

  /// No description provided for @enterKeyName.
  ///
  /// In en, this message translates to:
  /// **'Enter key name'**
  String get enterKeyName;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// No description provided for @sendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed'**
  String get sendFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
