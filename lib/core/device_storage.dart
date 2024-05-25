///
/// Created on 2023/5/25
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

const String _logName = 'Device Storage';

class DeviceInfo {
  String nickName = '';
  String id = '';
  String accessKey = '';
}

class DeviceStorage {
  final String _storageName;

  DeviceStorage(this._storageName);

  final LinkedHashMap<String, DeviceInfo> deviceList =
      LinkedHashMap<String, DeviceInfo>();

  Future<void> save() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    int count = 0;
    for (DeviceInfo item in deviceList.values) {
      sharedPreferences.setStringList('$_storageName: Device$count', [
        item.nickName,
        item.id,
        item.accessKey,
      ]);
      count++;
    }

    sharedPreferences.setInt('$_storageName: Device Count', count);
    developer.log('$_storageName: Device Count: $count', name: _logName);
  }

  Future<void> load() async {
    deviceList.clear();
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    int? count = sharedPreferences.getInt('$_storageName: Device Count');
    count ??= 0;
    developer.log('$_storageName: Device Count: $count', name: _logName);
    for (int i = 0; i < count; i++) {
      List<String>? deviceInfo =
          sharedPreferences.getStringList('$_storageName: Device$i');
      deviceInfo ??= [];
      DeviceInfo info = DeviceInfo();
      info.nickName = deviceInfo[0];
      info.id = deviceInfo[1];
      info.accessKey = deviceInfo[2];
      deviceList[info.id] = info;
    }
  }
}
