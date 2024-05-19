///
/// Created on 2023/12/17
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/themes/theme.dart';
import 'package:hoozz_play/adapter/remote_switch_adapter.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

const String _logName = 'Remote Switch';

void _generateSnackBar(BuildContext context, String str, Color bgColor) {
  SnackBar snackBar = SnackBar(
      content: Text(
        str,
        style: const TextStyle(
          fontSize: 18,
          fontFamily: mainFontFamily,
        ),
      ),
      backgroundColor: bgColor);
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
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

// Add device page
class _AddDevicePageWidget extends StatelessWidget {
  String _nickName = '';
  String _repository = '';
  String _privkey = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add new device"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
              child: TextField(
                onChanged: (value) =>
                    _nickName = value.replaceAll('\r\n', '\n'),
                autofocus: true,
                style: const TextStyle(fontSize: 20, fontFamily: subFontFamily),
                decoration: _DeviceInofInputDecoration(
                  'Nick name',
                  'Give your device a name',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                onChanged: (value) =>
                    _repository = value.replaceAll('\r\n', '\n'),
                style: const TextStyle(fontSize: 20, fontFamily: subFontFamily),
                decoration: _DeviceInofInputDecoration(
                  'Repository',
                  'Enter the device repository URL',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                onChanged: (value) => _privkey = value.replaceAll('\r\n', '\n'),
                style: const TextStyle(fontSize: 20, fontFamily: subFontFamily),
                maxLines: 10,
                keyboardType: TextInputType.multiline,
                decoration: _DeviceInofInputDecoration(
                  'Private key',
                  'Enter your private key to access the repository',
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
                  developer.log('Nick name: $_nickName', name: _logName);
                  developer.log('Repository: $_repository', name: _logName);
                  // developer.log('Privkey: $_privkey ${_privkey.length}', name: _logName);

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
                                child: Text("Please wait..."),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  remoteSwitchInit(_repository, _privkey).then(
                    (value) {
                      Navigator.pop(context);
                      if (value == 0) {
                        _generateSnackBar(
                            context, 'Added successfully', Colors.green);
                        Navigator.pop(
                            context, [_nickName, _repository, _privkey]);
                      } else {
                        _generateSnackBar(
                            context, 'Verification failed', Colors.red);
                      }
                    },
                  );
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

class _CtrlDevicePageWidget extends StatefulWidget {
  String _nickName = '';
  String _repository = '';
  String _privkey = '';

  _CtrlDevicePageWidget(this._nickName, this._repository, this._privkey);

  @override
  State<StatefulWidget> createState() => _CtrlDevicePageState();
}

// Ctrl device page
class _CtrlDevicePageState extends State<_CtrlDevicePageWidget> {
  bool _runing = false;
  String _stepState = '';
  int _devPowerState = -1;
  bool _devIsInit = false;

  Future<bool> _initDevice() async {
    bool retval = false;

    if (_runing) return false;

    setState(() {
      _stepState = 'Device Init...';
      _runing = true;
    });

    if (await remoteSwitchInit(widget._repository, widget._privkey) == 0) {
      _devIsInit = true;
      retval = true;
    }

    setState(() {
      _stepState = '';
      _runing = false;
    });

    return retval;
  }

  Future<bool> _getDeviceState() async {
    bool retval = false;

    if (_runing) return false;

    if (_devIsInit == false) {
      if (await _initDevice() == false) return false;
    }

    setState(() {
      _stepState = 'Calling device...';
      _runing = true;
    });

    if (await remoteSwitchReport() == 0) {
      setState(() => _stepState = 'Wait result...');
      _devPowerState = await remoteSwitchResult(15);
      retval = true;
    }

    setState(() {
      _stepState = '';
      _runing = false;
    });

    return retval;
  }

  Future<bool> _ctrlDevice() async {
    bool retval = false;

    if (_runing) return false;

    if (_devIsInit == false) {
      if (await _initDevice() == false) return false;
    }

    setState(() {
      _stepState = 'Calling device...';
      _runing = true;
    });

    if (await remoteSwitchPress() == 0) {
      setState(() => _stepState = 'Wait result...');
      _devPowerState = await remoteSwitchResult(30);
      retval = true;
    }

    setState(() {
      _stepState = '';
      _runing = false;
    });

    return retval;
  }

  @override
  void initState() {
    super.initState();
    _getDeviceState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._nickName),
        actions: [
          // Refresh device
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _getDeviceState(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 24, 10, 24),
          child: SizedBox(
            height: 400,
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 24, 10, 24),
                  child: Text(
                    _stepState,
                    style: const TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 24, 10, 24),
                  child: Text(
                    'State: ${_devPowerState == 1 ? 'ON' : (_devPowerState == 0 ? 'OFF' : 'Unknown')}',
                    style: TextStyle(
                        fontSize: 32,
                        color: _devPowerState == 1
                            ? Colors.green
                            : (_devPowerState == 0 ? Colors.grey : Colors.red)),
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Visibility(
                        visible: _runing,
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 170),
                        shape: const CircleBorder(),
                      ),
                      onPressed: !_runing
                          ? () {
                              _ctrlDevice();
                            }
                          : null,
                      child: const Text(
                        "Click Me",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceInfo {
  String name;
  String repository;
  String privkey;
  _DeviceInfo(this.name, this.repository, this.privkey);
}

class RemoteSwitchHomePage extends StatefulWidget {
  const RemoteSwitchHomePage({super.key});

  final String title = 'Remote Switch';

  @override
  State<RemoteSwitchHomePage> createState() => _RemoteSwitchHomePageState();
}

// Home page
class _RemoteSwitchHomePageState extends State<RemoteSwitchHomePage> {
  final String _storageName = 'Remote Switch';

  @override
  void initState() {
    super.initState();
    _deviceInfoLoad();
    remoteSshDaemonStart();
  }

  final List<_DeviceInfo> _deviceList = [];

  Widget _generateDevice(int index) {
    return InkWell(
      onTap: () {
        _DeviceInfo dev = _deviceList[index];
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  _CtrlDevicePageWidget(dev.name, dev.repository, dev.privkey)),
        );
      },
      onLongPress: () {
        showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Warning'),
              content: const Text(
                  'Are you sure you want to delete this device?',
                  style: TextStyle(color: Colors.red)),
              actions: <Widget>[
                // Delete device button
                TextButton(
                  child: const Text('Yes'),
                  onPressed: () {
                    setState(() {
                      _deviceList.removeAt(index);
                      _deviceInfoSave();
                    });
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child:
                      const Text('No', style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 24, 10, 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 10, 15, 10),
                // child: Icon(Icons.on_device_training),
                child: Text(
                  '🐉',
                  style: TextStyle(
                    fontSize: 30,
                    fontFamily: subFontFamily,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _deviceList[index].name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontFamily: subFontFamily,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deviceInfoLoad() {
    SharedPreferences.getInstance().then((value) {
      int? count = value.getInt('$_storageName: Device Count');
      count ??= 0;
      developer.log('$_storageName: Device Count: $count', name: _logName);
      for (int i = 0; i < count; i++) {
        List<String>? deviceInfo =
            value.getStringList('$_storageName: Device$i');
        deviceInfo ??= [];
        if (deviceInfo.length == 3) {
          setState(() {
            _deviceList
                .add(_DeviceInfo(deviceInfo![0], deviceInfo[1], deviceInfo[2]));
          });
        }
      }
    });
  }

  void _deviceInfoSave() {
    SharedPreferences.getInstance().then((value) {
      for (int i = 0; i < _deviceList.length; i++) {
        value.setStringList('$_storageName: Device$i', [
          _deviceList[i].name,
          _deviceList[i].repository,
          _deviceList[i].privkey
        ]);
      }

      value.setInt('$_storageName: Device Count', _deviceList.length);
      developer.log('$_storageName: Device Count: ${_deviceList.length}',
          name: _logName);
    });
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => _AddDevicePageWidget()),
              ).then((value) {
                if (value != null) {
                  List<String> info = value;
                  setState(() {
                    _deviceList.add(_DeviceInfo(info[0], info[1], info[2]));
                    _deviceInfoSave();
                  });
                }
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _deviceList.length,
        padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
        itemBuilder: (context, index) {
          return _generateDevice(index);
        },
      ),
    );
  }

  @override
  void dispose() {
    remoteSshDaemonStop();
    super.dispose();
  }
}
