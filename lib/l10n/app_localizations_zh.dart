// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get homeTitle => 'Hoozz Play 主页';

  @override
  String get settings => '设置';

  @override
  String get settingsTitle => 'Hoozz Play 设置';

  @override
  String get toolsTitle => 'Hoozz Play 工具';

  @override
  String get tools => '工具';

  @override
  String get vpn => 'VPN';

  @override
  String get about => '关于';

  @override
  String get author => '作者';

  @override
  String get license => '许可协议';

  @override
  String get language => '语言';

  @override
  String get followSystem => '跟随系统';

  @override
  String get languageEnglish => '英文';

  @override
  String get languageChinese => '中文';

  @override
  String get toolsEspTouchDesc => '智能配网';

  @override
  String get toolsDiscoverDesc => '发现已配置的设备';

  @override
  String get ssid => 'SSID';

  @override
  String get ssidHint => '你的 Wi-Fi 网络名称 (SSID)';

  @override
  String get password => '密码';

  @override
  String get passwordHint => '你的 Wi-Fi 网络密码';

  @override
  String get only24GHz => '仅支持 2.4GHz 网络';

  @override
  String get config => '配置';

  @override
  String get configuredDevices => '已配置的设备:';

  @override
  String get unableStartConfig => '无法开始配置';

  @override
  String get cantGetWifi => '无法获取 WiFi 信息';

  @override
  String get go => '前往';

  @override
  String get cancel => '取消';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get save => '保存';

  @override
  String get start => '开始';

  @override
  String get test => '测试';

  @override
  String get restart => '重启';

  @override
  String get update => '更新';

  @override
  String get upgrade => '升级';

  @override
  String get select => '选择';

  @override
  String get warning => '警告';

  @override
  String get deleteDeviceConfirm => '确定要删除这个设备吗？';

  @override
  String get online => '[在线]';

  @override
  String get offline => '[离线]';

  @override
  String deviceId(String id) {
    return 'ID: $id';
  }

  @override
  String get addNewDevice => '添加新设备';

  @override
  String get nickName => '昵称';

  @override
  String get nickNameHint => '给你的设备起个名字';

  @override
  String get repository => '仓库';

  @override
  String get repositoryHint => '输入设备仓库 URL';

  @override
  String get privateKey => '私钥';

  @override
  String get privateKeyHint => '输入你的私钥以访问仓库';

  @override
  String get pleaseWait => '请稍候...';

  @override
  String get addedSuccessfully => '添加成功';

  @override
  String get verificationFailed => '验证失败';

  @override
  String get deviceInit => '设备初始化...';

  @override
  String get callingDevice => '调用设备中...';

  @override
  String get waitResult => '等待结果...';

  @override
  String stateLabel(String state) {
    return '状态: $state';
  }

  @override
  String get onState => '开';

  @override
  String get offState => '关';

  @override
  String get unknown => '未知';

  @override
  String get clickMe => '点我';

  @override
  String errorSettingRefreshRate(String rate) {
    return '设置刷新率 ${rate}Hz 失败';
  }

  @override
  String get connectionSucceeded => '连接成功';

  @override
  String screenshotSaved(String path) {
    return '截图已保存到 $path';
  }

  @override
  String screenshotFailed(String error) {
    return '截图失败: $error';
  }

  @override
  String maxTemp(String temp) {
    return '最高: $temp°C';
  }

  @override
  String minTemp(String temp) {
    return '最低: $temp°C';
  }

  @override
  String crosshairTemp(String temp) {
    return '准星: $temp°C';
  }

  @override
  String tempValue(String temp) {
    return '$temp°C';
  }

  @override
  String get refreshRateLabel => '刷新率(Hz):';

  @override
  String get rotateLabel => '旋转:';

  @override
  String get traceLabel => '标记:';

  @override
  String get mirrorLabel => '镜像:';

  @override
  String get emissivityLabel => '发射率:';

  @override
  String errorSettingEmissivity(String value) {
    return '设置发射率 $value 失败';
  }

  @override
  String get taShiftLabel => 'Ta 偏移:';

  @override
  String errorSettingTaShift(String value) {
    return '设置 Ta 偏移 $value 失败';
  }

  @override
  String get screenshot => '截图';

  @override
  String get configureDevice => '配置设备';

  @override
  String get nameLabel => '名称:';

  @override
  String get classLabel => '类型:';

  @override
  String get idLabel => 'ID:';

  @override
  String get ipLabel => 'IP:';

  @override
  String get versionLabel => '版本:';

  @override
  String get restartDevice => '重启设备';

  @override
  String get restartDeviceConfirm => '设备即将重启，期间可能无法连接。继续吗？';

  @override
  String get deviceIsRestarting => '设备正在重启';

  @override
  String get restartRequestFailed => '重启请求失败';

  @override
  String get deviceNickName => '设备昵称';

  @override
  String get deviceNickNameHint => '为你的设备设置昵称';

  @override
  String get accessKey => '访问密钥';

  @override
  String get accessKeyHint => '为设备设置访问密钥';

  @override
  String get syncNameToRemote => '名称同步到设备';

  @override
  String get updateAvailable => '有新版本可用';

  @override
  String versionLine(String version) {
    return '版本: $version';
  }

  @override
  String publishedLine(String time) {
    return '发布时间: $time';
  }

  @override
  String downloadLine(String name, String size) {
    return '下载: $name ($size)';
  }

  @override
  String get noFirmwareZip => '发布版本中没有固件 zip 文件';

  @override
  String downloadFailed(String error) {
    return '下载失败: $error';
  }

  @override
  String extractFirmwareFailed(String error) {
    return '解压固件失败: $error';
  }

  @override
  String otaTransferFailed(String error) {
    return 'OTA 传输失败: $error';
  }

  @override
  String get downloadingFirmware => '正在下载固件';

  @override
  String get transferringFirmware => '正在传输固件';

  @override
  String get doNotPowerOff => '请勿给设备断电';

  @override
  String get connectingToDevice => '正在连接设备...';

  @override
  String transferProgress(int percent, String sent, String total) {
    return '设备: $percent%   ($sent / $total)';
  }

  @override
  String sizeProgress(String sent, String total) {
    return '$sent / $total';
  }

  @override
  String get appDescription => 'Hoozz Play 是一个个人开源项目，所有有趣的东西都会在这里分享';

  @override
  String get downloadingUpdate => '正在下载更新';

  @override
  String get allowInstallUnknownApps => '请允许 Hoozz Play「安装未知应用」，然后重试';

  @override
  String get installFailed => '安装失败，请重试';

  @override
  String get downloadCancelled => '下载已取消';

  @override
  String get onlineState => '在线';

  @override
  String get offlineState => '离线';

  @override
  String portProtocol(String port, String protocol) {
    return '端口: $port  |  协议: $protocol';
  }

  @override
  String get deleteConfigConfirm => '确定要删除这个配置吗？';

  @override
  String get clipboardEmpty => '剪贴板为空';

  @override
  String get addConfigFromClipboard => '从剪贴板添加配置 ...';

  @override
  String get contentFormatError => '内容格式错误';

  @override
  String get operationCanceled => '操作已取消';

  @override
  String errorPrefix(String error) {
    return '错误: $error';
  }

  @override
  String get addConfigFromFile => '从文件添加配置 ...';

  @override
  String get abnormalDeviceData => '设备数据异常';

  @override
  String get deviceConnectionFailed => '设备连接失败';

  @override
  String get deviceConnecting => '设备连接中...';

  @override
  String get verifyingDevice => '正在验证设备...';

  @override
  String get deviceInformationSaved => '设备信息已保存';

  @override
  String get configureDeviceFailed => '配置设备信息失败';

  @override
  String get deviceSaved => '设备已保存';

  @override
  String get noData => '无数据';

  @override
  String get unsupported => '不支持';

  @override
  String get selectAllOrDeselectAll => '全选或全不选';

  @override
  String get selectAll => '全选';

  @override
  String get deselectAll => '全不选';

  @override
  String get noDevicesSelected => '未选择任何设备';

  @override
  String get changelist => '变更列表';

  @override
  String get sync => '同步';

  @override
  String get setSwitchStateFailed => '设置开关状态失败';

  @override
  String get voltage => '电压';

  @override
  String get current => '电流';

  @override
  String get power => '功率';

  @override
  String get energy => '电量';

  @override
  String deletingKeys(int count) {
    return '正在删除 $count 个按键...';
  }

  @override
  String removedKeys(int count) {
    return '已删除 $count 个按键';
  }

  @override
  String removedKeysPartial(int ok, int count) {
    return '已删除 $ok/$count 个按键';
  }

  @override
  String get deleteFailed => '删除失败';

  @override
  String get keyNameTooLong => '按键名称过长';

  @override
  String get readFileFailed => '读取文件失败';

  @override
  String get keyDataSizeInvalid => '按键数据必须为 1-1024 字节';

  @override
  String importingFiles(int count) {
    return '正在导入 $count 个文件...';
  }

  @override
  String importedKeys(int count) {
    return '已导入 $count 个按键';
  }

  @override
  String importedKeysPartial(int ok, int count) {
    return '已导入 $ok/$count 个按键';
  }

  @override
  String get importFailed => '导入失败';

  @override
  String exportingKeys(int count) {
    return '正在导出 $count 个按键...';
  }

  @override
  String savedTo(String folder) {
    return '已保存到: $folder';
  }

  @override
  String exportedKeysPartial(int ok, int count) {
    return '已导出 $ok/$count 个按键';
  }

  @override
  String get exportFailed => '导出失败';

  @override
  String get selectKeysFirst => '请先选择按键';

  @override
  String get importKeys => '导入按键';

  @override
  String get exportSelectedKeys => '导出所选按键';

  @override
  String get deleteSelectedKeys => '删除所选按键';

  @override
  String get keyTransferMode => '按键传输模式';

  @override
  String get exitTransferMode => '退出传输模式';

  @override
  String deleteKeysConfirm(int count) {
    return '确定要删除所选的 $count 个按键吗？';
  }

  @override
  String get addKey => '添加按键';

  @override
  String irDataFormat(String count, String length) {
    return '$count | ${length}p';
  }

  @override
  String get irDataEmpty => '--- | ---p';

  @override
  String get enterKeyName => '输入按键名称';

  @override
  String get saved => '已保存';

  @override
  String get saveFailed => '保存失败';

  @override
  String get sendFailed => '发送失败';
}
