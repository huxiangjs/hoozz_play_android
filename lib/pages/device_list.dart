///
/// Created on 2023/5/25
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:hoozz_play/core/device_binding.dart';
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
  final int _deviceRefreshTime = 1;
  final int _deviceOnlineTimeout = 30;
  late Timer _refreshTimer;

  Future<void> refreshDeviceList() async {
    _deviceList.clear();

    final DeviceStorage deviceStorage = DeviceStorage(widget.title);
    await deviceStorage.load();

    for (DeviceInfo item in deviceStorage.deviceList.values) {
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
          _refreshTimer.cancel();
          _simpleCtrlDiscover.destroyDiscovery();
          Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext context) {
            developer.log('Ctrl Device: ${widget.title}', name: _logName);
            ParameterStatefulState page = widget._deviceBindingBody.ctrlPage();
            page.parameter = [discoverDeviceInfo, widget.title];
            // To device ctrl
            return ParameterStatefulWidget(page);
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
