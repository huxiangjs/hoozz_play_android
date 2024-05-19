///
/// Created on 2024/5/15
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/core/class_id.dart';
import 'package:hoozz_play/themes/theme.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  final String title = 'Discover';

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _ConfigDevicePage extends StatefulWidget {
  final ClassBindingWidgetState _page;

  const _ConfigDevicePage(this._page);

  @override
  State<StatefulWidget> createState() => _page;
}

class _DiscoverPageState extends State<DiscoverPage> {
  final SimpleCtrl _simpleCtrl = SimpleCtrl();

  List<DiscoverDeviceInfo> _deviceList = [];

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
                      ClassList.classIdList[_deviceList[index].classId] != null,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            ClassBindingWidgetState page = ClassList
                                .classIdList[_deviceList[index].classId]!
                                .page();
                            // Set parameter
                            page.parameter = [_deviceList[index]];
                            return _ConfigDevicePage(page);
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
    _simpleCtrl.initDiscover();
    // Listen update
    _simpleCtrl.deviceListNotifier.addListener(() {
      setState(() {
        _deviceList = _simpleCtrl.getDeviceList();
      });
    });
  }

  @override
  void dispose() {
    _simpleCtrl.destroyDiscovery();
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
