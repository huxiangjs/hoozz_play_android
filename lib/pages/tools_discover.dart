///
/// Created on 2024/5/15
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/core/device_binding.dart';
import 'package:hoozz_play/core/period_call.dart';
import 'package:hoozz_play/themes/theme.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'package:hoozz_play/core/parameter_stateful.dart';
import 'dart:developer' as developer;

const String _logName = 'Discover';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  final String title = 'Discover';

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final SimpleCtrlDiscover _simpleCtrlDiscover = SimpleCtrlDiscover();

  List<DiscoverDeviceInfo> _deviceList = [];
  final int _deviceRefreshTime = 1000;
  late PeriodCall _periodCall;

  Widget _generateItem(int index) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 22, 10, 22),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 5, 15, 5),
                      child: Icon(
                        Icons.important_devices_outlined,
                        size: 40,
                        color: mainFillColor,
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
                              _deviceList[index].name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontFamily: subFontFamily,
                                fontWeight: FontWeight.bold,
                                color: mainTextColor,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 1, 0, 0),
                            child: Text(
                              _deviceList[index].id,
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: subFontFamily,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 1, 0, 0),
                            child: Text(
                              '${_deviceList[index].time.year.toString().padLeft(4, '0')}-${_deviceList[index].time.month.toString().padLeft(2, '0')}-${_deviceList[index].time.day.toString().padLeft(2, '0')} ${_deviceList[index].time.hour.toString().padLeft(2, '0')}:${_deviceList[index].time.minute.toString().padLeft(2, '0')}:${_deviceList[index].time.second.toString().padLeft(2, '0')}',
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
                Visibility(
                  visible:
                      DeviceBindingList.binding[_deviceList[index].classId] !=
                          null,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            DeviceBindingBody body = DeviceBindingList
                                .binding[_deviceList[index].classId]!;
                            ParameterStatefulState page = body.configPage();
                            // Set parameter
                            page.parameter = [
                              _deviceList[index],
                              body.describe
                            ];
                            return ParameterStatefulWidget(page);
                          },
                        ),
                      ).then((value) {});
                    },
                    child: const Text(
                      'Go',
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _simpleCtrlDiscover.initDiscover();

    _periodCall = PeriodCall(_deviceRefreshTime, () {
      setState(() {
        _deviceList = _simpleCtrlDiscover.getDeviceList();
      });
      developer.log('Refresh once', name: _logName);
    });
    // First updata
    _periodCall.ping();

    // Listen update
    _simpleCtrlDiscover.deviceListNotifier
        .addListener(() => _periodCall.ping());
  }

  @override
  void dispose() {
    _periodCall.cancel();
    _simpleCtrlDiscover.destroyDiscovery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
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
      ),
    );
  }
}
