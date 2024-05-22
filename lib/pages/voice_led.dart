///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hoozz_play/core/class_id.dart';
import 'package:hoozz_play/themes/theme.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

const String _logName = 'Voice LED';

class VoiceLEDHomePage extends StatefulWidget {
  const VoiceLEDHomePage({super.key});

  final String title = 'Voice LED';

  @override
  State<VoiceLEDHomePage> createState() => _VoiceLEDHomePageState();
}

class _VoiceLEDDeviceInfo {
  String nickName = '';
  String id = '';
  String accessKey = '';
}

class _VoiceLEDDeviceInfoStorage {
  final String _storageName = 'Voice LED';
  final LinkedHashMap<String, _VoiceLEDDeviceInfo> deviceList =
      LinkedHashMap<String, _VoiceLEDDeviceInfo>();

  Future<void> save() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    int count = 0;
    for (_VoiceLEDDeviceInfo item in deviceList.values) {
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
      _VoiceLEDDeviceInfo info = _VoiceLEDDeviceInfo();
      info.nickName = deviceInfo[0];
      info.id = deviceInfo[1];
      info.accessKey = deviceInfo[2];
      deviceList[info.id] = info;
    }
  }
}

class _ConfigDevicePage extends StatefulWidget {
  final ClassBindingWidgetState _page;

  const _ConfigDevicePage(this._page);

  @override
  State<StatefulWidget> createState() => _page;
}

// LED ctrl page
class _VoiceLEDDeviceCtrlPage extends StatefulWidget {
  final DiscoverDeviceInfo _discoverDeviceInfo;

  const _VoiceLEDDeviceCtrlPage(this._discoverDeviceInfo);

  @override
  State<_VoiceLEDDeviceCtrlPage> createState() =>
      _VoiceLEDDeviceCtrlPageState();
}

class _VoiceLEDDeviceCtrlPageState extends State<_VoiceLEDDeviceCtrlPage> {
  final List<int> _colorIndex = [0, 1, 2];
  final List<Color> _colorShow = [Colors.redAccent, Colors.green, Colors.blue];
  final List<double> _colorValue = [0.0, 0.0, 0.0];
  late SimpleCtrlHandle _simpleCtrlDiscoverHandle;

  @override
  void initState() {
    super.initState();
    _simpleCtrlDiscoverHandle = SimpleCtrlHandle(widget._discoverDeviceInfo);
    _simpleCtrlDiscoverHandle.stateNotifier.addListener(() {});
    _simpleCtrlDiscoverHandle.initHandle();
  }

  @override
  void dispose() {
    _simpleCtrlDiscoverHandle.destroyHandle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._discoverDeviceInfo.name),
        actions: [
          // Config device button
          IconButton(
            icon: const Icon(Icons.perm_data_setting_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    ClassBindingWidgetState page = ClassList
                        .classIdList[widget._discoverDeviceInfo.classId]!
                        .page();
                    // Set parameter
                    page.parameter = [widget._discoverDeviceInfo];
                    return _ConfigDevicePage(page);
                  },
                ),
              ).then((value) {});
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ColorPicker(
            paletteType: PaletteType.hueWheel,
            labelTypes: const [ColorLabelType.hsv, ColorLabelType.rgb],
            enableAlpha: false,
            onColorChanged: (Color value) {
              setState(() {
                _colorValue[0] = value.red.toDouble();
                _colorValue[1] = value.green.toDouble();
                _colorValue[2] = value.blue.toDouble();
              });
            },
            pickerColor: Color.fromARGB(0xFF, _colorValue[0].toInt(),
                _colorValue[1].toInt(), _colorValue[2].toInt()),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _colorIndex.map((int index) {
              return SizedBox(
                height: 80,
                child: Slider(
                  value: _colorValue[index],
                  onChanged: (data) {
                    setState(() {
                      _colorValue[index] = data;
                    });
                    // int rgb = _colorValue[0].toInt() << 16 |
                    //     _colorValue[1].toInt() << 8 |
                    //     _colorValue[2].toInt();
                    // developer.log('changed rgb: 0x${rgb.toRadixString(16)}',
                    //     name: toString());
                  },
                  onChangeStart: (data) {},
                  onChangeEnd: (data) {},
                  min: 0.0,
                  max: 0xff,
                  divisions: 0xff,
                  label: '${_colorValue[index]}',
                  activeColor: _colorShow[index],
                ),
              );
            }).toList(),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

// Home page
class _VoiceLEDHomePageState extends State<VoiceLEDHomePage> {
  final SimpleCtrlDiscover _simpleCtrlDiscover = SimpleCtrlDiscover();
  final List<_VoiceLEDDeviceInfo> _deviceList = [];
  final int _deviceRefreshTime = 1;
  final int _deviceOnlineTimeout = 30;
  late Timer _refreshTimer;

  Future<void> refreshDeviceList() async {
    _deviceList.clear();

    final _VoiceLEDDeviceInfoStorage deviceInfoStorage =
        _VoiceLEDDeviceInfoStorage();
    await deviceInfoStorage.load();

    for (_VoiceLEDDeviceInfo item in deviceInfoStorage.deviceList.values) {
      _deviceList.add(item);
    }
  }

  void _refreshDeviceState(Timer timer) => setState(() {});

  void _startRefreshTimer() {
    // Regular refresh
    _refreshTimer = Timer.periodic(
        Duration(seconds: _deviceRefreshTime), _refreshDeviceState);
  }

  @override
  void initState() {
    super.initState();
    _simpleCtrlDiscover.initDiscover();
    // Listen update
    // _simpleCtrlDiscover.deviceListNotifier.addListener(() => setState(() {}));
    _startRefreshTimer();

    // Load device info
    refreshDeviceList().then((value) => setState(() {}));
  }

  Widget _generateItem(int index) {
    _VoiceLEDDeviceInfo deviceInfo = _deviceList[index];
    String deviceId = deviceInfo.id;
    String deviceNickName = deviceInfo.nickName;
    LinkedHashMap<String, DiscoverDeviceInfo> discoverDeviceList =
        _simpleCtrlDiscover.deviceListNotifier.deviceList;
    bool deviceOnline = false;
    if (discoverDeviceList[deviceId] != null) {
      DateTime time = DateTime.now();
      Duration difference = time.difference(discoverDeviceList[deviceId]!.time);
      int seconds = difference.inSeconds;
      // Online
      if (seconds < _deviceOnlineTimeout) {
        deviceOnline = true;
      }
    }

    return InkWell(
      onTap: () {
        if (discoverDeviceList[deviceId] != null) {
          DiscoverDeviceInfo discoverDeviceInfo = discoverDeviceList[deviceId]!;
          _refreshTimer.cancel();
          _simpleCtrlDiscover.destroyDiscovery();
          Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
            return _VoiceLEDDeviceCtrlPage(discoverDeviceInfo);
          })).then((value) {
            _simpleCtrlDiscover.initDiscover();
            _startRefreshTimer();
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 24, 10, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(0x20, 0x00, 0x00, 0x00),
                blurRadius: 10,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                child: Icon(
                  deviceOnline
                      ? Icons.sentiment_satisfied_outlined
                      : Icons.sentiment_dissatisfied_outlined,
                  size: 60,
                  color: deviceOnline ? Colors.green : Colors.grey,
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 1),
                      child: Text(
                        deviceNickName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontFamily: subFontFamily,
                          fontWeight: FontWeight.bold,
                          color: mainTextColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 1, 0, 0),
                      child: Text(
                        deviceOnline ? '[online]' : '[offline]',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: subFontFamily,
                          fontWeight: FontWeight.bold,
                          color: deviceOnline ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 1, 0, 0),
                      child: Text(
                        'id: $deviceId',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: subFontFamily,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // Add device button
          IconButton(
            icon: const Icon(Icons.format_list_bulleted_add),
            onPressed: () {
              _simpleCtrlDiscover.destroyDiscovery();
              Navigator.pushNamed(context, '/tools')
                  .then((value) => _simpleCtrlDiscover.initDiscover());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _deviceList.length,
          padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
          itemBuilder: (context, index) {
            return _generateItem(index);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    _simpleCtrlDiscover.destroyDiscovery();
    super.dispose();
  }
}

class _DeviceInofInputDecoration extends InputDecoration {
  static final OutlineInputBorder disabledOutlineInputBorder =
      OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: const BorderSide(color: Colors.grey, width: 1.0),
    gapPadding: 6,
  );

  static final OutlineInputBorder enabledOutlineInputBorder =
      OutlineInputBorder(
    borderRadius: BorderRadius.circular(24),
    borderSide: const BorderSide(color: mainFillColor, width: 2.0),
    gapPadding: 6,
  );

  _DeviceInofInputDecoration(labelText, hintText)
      : super(
          labelText: labelText,
          hintText: hintText,
          labelStyle: const TextStyle(fontSize: 20, fontFamily: mainFontFamily),
          hintStyle: const TextStyle(fontSize: 20, fontFamily: subFontFamily),
          // floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 15,
          ),
          border: disabledOutlineInputBorder,
          enabledBorder: disabledOutlineInputBorder,
          focusedBorder: enabledOutlineInputBorder,
          disabledBorder: disabledOutlineInputBorder,
        );
}

// Config device page
class VoiceLEDConfigDevicePageState extends ClassBindingWidgetState {
  _VoiceLEDDeviceInfo _deviceInfo = _VoiceLEDDeviceInfo();
  late DiscoverDeviceInfo _discoverDeviceInfo;

  Future<void> _deviceInfoLoad() async {
    _VoiceLEDDeviceInfoStorage storage = _VoiceLEDDeviceInfoStorage();
    await storage.load();
    if (storage.deviceList[_deviceInfo.id] != null) {
      _deviceInfo = storage.deviceList[_deviceInfo.id]!;
    }
  }

  Future<void> _deviceInfoSave() async {
    _VoiceLEDDeviceInfoStorage storage = _VoiceLEDDeviceInfoStorage();
    await storage.load();
    storage.deviceList[_deviceInfo.id] = _deviceInfo;
    await storage.save();
  }

  @override
  void initState() {
    super.initState();

    _discoverDeviceInfo = parameter[0] as DiscoverDeviceInfo;
    _deviceInfo.nickName = _discoverDeviceInfo.name;
    _deviceInfo.id = _discoverDeviceInfo.id;
    _deviceInfoLoad().then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure device"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 24, 10, 2),
              child: Row(
                children: [
                  const Text(' NAME: ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      _discoverDeviceInfo.name,
                      style: const TextStyle(
                          fontSize: 18, fontFamily: subFontFamily),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Row(
                children: [
                  const Text('CLASS: ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      ClassList.classIdList[_discoverDeviceInfo.classId] == null
                          ? 'Unknown'
                          : ClassList.classIdList[_discoverDeviceInfo.classId]!
                              .describe,
                      style: const TextStyle(
                          fontSize: 18, fontFamily: subFontFamily),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Row(
                children: [
                  const Text('    ID: ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      _discoverDeviceInfo.id,
                      style: const TextStyle(
                          fontSize: 18, fontFamily: subFontFamily),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
              child: Row(
                children: [
                  const Text('    IP: ', style: TextStyle(fontSize: 18)),
                  Expanded(
                    child: Text(
                      '${_discoverDeviceInfo.ip} : ${_discoverDeviceInfo.port}',
                      style: const TextStyle(
                          fontSize: 18, fontFamily: subFontFamily),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: TextEditingController(text: _deviceInfo.nickName),
                onChanged: (value) =>
                    _deviceInfo.nickName = value.replaceAll('\r\n', '\n'),
                style: const TextStyle(fontSize: 20, fontFamily: subFontFamily),
                // maxLines: 2,
                decoration: _DeviceInofInputDecoration(
                  'Device nick name',
                  'Set a nick name for your device',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: TextEditingController(text: _deviceInfo.accessKey),
                onChanged: (value) =>
                    _deviceInfo.accessKey = value.replaceAll('\r\n', '\n'),
                style: const TextStyle(fontSize: 20, fontFamily: subFontFamily),
                // maxLines: 2,
                keyboardType: TextInputType.multiline,
                decoration: _DeviceInofInputDecoration(
                  'Access key',
                  'Set access key for your device',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  developer.log('Nick name: ${_deviceInfo.nickName}',
                      name: _logName);
                  developer.log('Access key: ${_deviceInfo.accessKey}',
                      name: _logName);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return WillPopScope(
                        onWillPop: () async => false, // Disable return key
                        child: AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const <Widget>[
                              CircularProgressIndicator(),
                              Padding(
                                padding: EdgeInsets.only(top: 26.0),
                                child: Text("Verifying device..."),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  Future.delayed(const Duration(seconds: 3, milliseconds: 0))
                      .then((value) {
                    _deviceInfoSave();
                    Navigator.pop(context);
                  });
                },
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 20, fontFamily: subFontFamily),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
