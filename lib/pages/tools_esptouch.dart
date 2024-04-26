///
/// Created on 2024/4/21
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/material.dart';
import 'package:hoozz_play/themes/theme.dart';
import 'package:hoozz_play/adapter/esptouch_adapter.dart';

class EspTouchPage extends StatefulWidget {
  const EspTouchPage({super.key});

  final String title = 'ESP Touch';

  @override
  State<EspTouchPage> createState() => _EspTouchPageState();
}

class _ItemInfo {
  IconData icon;
  String name;
  String ip;
  String page;
  _ItemInfo(this.icon, this.name, this.ip, this.page);
}

class _WifiInputDecoration extends InputDecoration {
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

  _WifiInputDecoration(labelText, hintText)
      : super(
          labelText: labelText,
          hintText: hintText,
          labelStyle: const TextStyle(fontSize: 20, fontFamily: mainFontFamily),
          hintStyle: const TextStyle(fontSize: 16, fontFamily: subFontFamily),
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

class _EspTouchPageState extends State<EspTouchPage> {
  final List<_ItemInfo> _itemList = [];

  Widget _generateItem(int index) {
    return InkWell(
      onTap: () {
        // Navigator.pushNamed(
        //   context,
        //   _itemList[index].page,
        // );
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 3, 0, 3),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 15, 5),
                      child: Icon(
                        _itemList[index].icon,
                        size: 40,
                        color: mainFillColor,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _itemList[index].name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: subFontFamily,
                            fontWeight: FontWeight.bold,
                            color: subTextColor,
                          ),
                        ),
                        Text(
                          _itemList[index].ip,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: subFontFamily,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text(
                    'Go',
                    style: TextStyle(color: Colors.green),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _generateSnackBar(String str, Color bgColor) {
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

  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final TextEditingController _wifiName = TextEditingController();
  final TextEditingController _wifiPassword = TextEditingController();
  bool _configState = false;
  double _configProgress = 0;
  final double _maxDelay = 60;

  Future<void> _waitDone() async {
    for (double i = 0; mounted && i < _maxDelay; i += 0.05) {
      if (mounted) {
        setState(() {
          _configProgress = i / _maxDelay;
        });
      }
      await Future.delayed(const Duration(seconds: 0, milliseconds: 50));
    }
    if (mounted) {
      setState(() {
        _configProgress = 0;
      });
    }
  }

  void _updateResult(String ip, String mac) {
    if (mounted) {
      setState(() {
        _itemList
            .add(_ItemInfo(Icons.devices_other_outlined, 'UNKNOWN', ip, ''));
      });
    }
  }

  void _doStartConfig() {
    if (mounted) {
      setState(() {
        _configState = true;
      });
    }
    ESPTouchAdapter.startConfig(
            _wifiName.text, _wifiPassword.text, _updateResult)
        .then(
      (value) {
        // Started
        if (value) {
          // Wait
          _waitDone().then(
            (value) {
              if (mounted) {
                setState(() {
                  _configState = false;
                });
              }
              ESPTouchAdapter.stopConfig();
            },
          );
        } else {
          if (mounted) {
            setState(() {
              _configState = false;
            });
            _generateSnackBar('Unable to start configuration', Colors.red);
          }
        }
      },
    );
  }

  void _updateWifiName() {
    ESPTouchAdapter.getWifiName().then(
      (value) {
        if (value == null) {
          _generateSnackBar('Can\'t get WiFi information', Colors.red);
        } else {
          if (mounted) {
            setState(() {
              _wifiName.text = value;
            });
          }
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _updateWifiName();
  }

  @override
  void dispose() {
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
          padding: const EdgeInsets.fromLTRB(10, 24, 10, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: TextField(
                  controller: _wifiName,
                  autofocus: false,
                  focusNode: _focusNode1,
                  style:
                      const TextStyle(fontSize: 20, fontFamily: subFontFamily),
                  decoration: _WifiInputDecoration(
                    'SSID',
                    'It\'s your Wi-Fi network name (SSID)',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: TextField(
                  controller: _wifiPassword,
                  autofocus: false,
                  focusNode: _focusNode2,
                  style:
                      const TextStyle(fontSize: 20, fontFamily: subFontFamily),
                  decoration: _WifiInputDecoration(
                    'PASSWORD',
                    'It\'s your Wi-Fi network password',
                  ),
                ),
              ),
              const Divider(height: 10),
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 4, 10, 4),
                child: Text(
                  'Only supports 2.4GHz network',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
              ),
              const Divider(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 24),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Visibility(
                        visible: _configState,
                        child:
                            CircularProgressIndicator(value: _configProgress),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 170),
                        shape: const CircleBorder(),
                      ),
                      onPressed: _configState
                          ? null
                          : () {
                              _focusNode1.unfocus();
                              _focusNode2.unfocus();
                              _doStartConfig();
                            },
                      child: const Text(
                        "CONFIG",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 10),
              const Divider(height: 10),
              const Padding(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Text(
                  'Configured devices:',
                  style: TextStyle(fontSize: 18, color: Colors.green),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _itemList.length,
                padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
                itemBuilder: (context, index) {
                  return _generateItem(index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
