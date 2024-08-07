///
/// Created on 2024/4/21
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:hoozz_play/core/device_binding.dart';
import 'package:hoozz_play/core/period_call.dart';
import 'package:hoozz_play/themes/theme.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'package:hoozz_play/core/device_storage.dart';
import 'package:hoozz_play/core/parameter_stateful.dart';
import 'dart:developer' as developer;

const String _logName = 'Device List';

class DeviceListHomePage extends StatefulWidget {
  late String title;
  late DeviceBindingBody _deviceBindingBody;

  DeviceListHomePage(int classId, {super.key}) {
    _deviceBindingBody = DeviceBindingList.binding[classId]!;
    title = _deviceBindingBody.describe;
  }

  @override
  State<DeviceListHomePage> createState() => _DeviceListHomePageState();
}

// Home page
class _DeviceListHomePageState extends State<DeviceListHomePage> {
  final SimpleCtrlDiscover _simpleCtrlDiscover = SimpleCtrlDiscover();
  final List<DeviceInfo> _deviceList = [];
  final int _deviceRefreshTime = 1000;
  final int _deviceOnlineTimeout = 30;
  late PeriodCall _periodCall;

  Future<void> refreshDeviceList() async {
    _deviceList.clear();

    final DeviceStorage deviceStorage = DeviceStorage(widget.title);
    await deviceStorage.load();

    for (DeviceInfo item in deviceStorage.deviceList.values) {
      _deviceList.add(item);
    }
  }

  Future<void> _delecteDevice(String deviceId) async {
    DeviceStorage storage = DeviceStorage(widget.title);
    await storage.load();

    storage.deviceList.remove(deviceId);
    await storage.save();
  }

  @override
  void initState() {
    super.initState();
    _simpleCtrlDiscover.initDiscover();

    _periodCall = PeriodCall(_deviceRefreshTime, () => setState(() {}));
    // First updata
    _periodCall.ping();

    // Listen update
    _simpleCtrlDiscover.deviceListNotifier
        .addListener(() => _periodCall.ping());

    // Load device info
    refreshDeviceList().then((value) => setState(() {}));
  }

  Widget _generateItem(int index) {
    DeviceInfo deviceInfo = _deviceList[index];
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
          _simpleCtrlDiscover.destroyDiscovery();
          _periodCall.cancel();
          Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
            developer.log('Click Device: ${widget.title}', name: _logName);
            ParameterStatefulState page = widget._deviceBindingBody.ctrlPage();
            page.parameter = [discoverDeviceInfo, deviceInfo, widget.title];
            // To device ctrl
            return ParameterStatefulWidget(page);
          })).then((value) {
            _periodCall.restart();
            _simpleCtrlDiscover.initDiscover();
            // Load device info
            refreshDeviceList().then((value) => setState(() {}));
          });
        }
      },
      onLongPress: () {
        developer.log('Long Press Device: ${widget.title}', name: _logName);
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
                    _delecteDevice(_deviceList[index].id).then((value) {
                      setState(() => _deviceList.removeAt(index));
                      Navigator.of(context).pop();
                    });
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
              _periodCall.cancel();
              Navigator.pushNamed(context, '/tools').then((value) {
                _periodCall.restart();
                _simpleCtrlDiscover.initDiscover();
                // Load device info
                refreshDeviceList().then((value) => setState(() {}));
              });
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
    _periodCall.cancel();
    _simpleCtrlDiscover.destroyDiscovery();
    super.dispose();
  }
}
