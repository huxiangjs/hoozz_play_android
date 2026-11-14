///
/// Created on 2026/11/09
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hoozz_play/core/device_binding.dart';
import 'package:hoozz_play/core/device_config.dart';
import 'package:hoozz_play/core/parameter_stateful.dart';
import 'package:hoozz_play/core/simple_showdialog.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'package:hoozz_play/core/device_storage.dart';
import 'package:hoozz_play/core/simple_snackbar.dart';
import 'dart:developer' as developer;

import 'package:hoozz_play/themes/theme.dart';

const String _logName = 'Switch';

//
// Protocol (must match MCU/main/main.c)
//
// Hardware version (SWITCH_CMD_GET_VERSION):
//   0 : simple version   - relay control only
//   1 : advanced version - relay + voltage/current/power + energy metering
//
// Commands (REQUEST load):
//   0x00 SET_STATE  : [cmd, 0/1]            -> [cmd, result]
//   0x01 GET_STATE  : [cmd]                 -> [cmd, result, state]
//   0x02 GET_VERSION: [cmd]                 -> [cmd, result, version]
//   0x03 GET_MEASURE: [cmd] (v1 only)       -> [cmd, result, V(4B), I(4B), P(4B)]
//   0x04 GET_ENERGY : [cmd] (v1 only)       -> [cmd, result, energy(4B)]
//   All 32-bit values are little-endian.
//   Units: voltage 0.001V, current 0.001A, power 0.001W, energy 0.001kWh
//
// Notification (NOTIFY load):
//   0x00 STATE_CHANGE : [type, state]
//   0x01 MEASURE      : [type, V(4B), I(4B), P(4B), energy(4B)]
//

// Switch control page
class SwitchDeviceCtrlPageState extends ParameterStatefulState {
  late SimpleCtrlHandle _simpleCtrlHandle;
  late DiscoverDeviceInfo _discoverDeviceInfo;
  late DeviceInfo _deviceInfo;
  late String _storageName;

  // Commands
  static const int _switchCmdSetState = 0x00;
  static const int _switchCmdGetState = 0x01;
  static const int _switchCmdGetVersion = 0x02;
  static const int _switchCmdGetMeasure = 0x03;
  static const int _switchCmdGetEnergy = 0x04;

  static const int _switchResultOk = 0x00;

  // Hardware versions
  static const int _switchVersion1 = 1; // advanced

  // Notification types
  static const int _switchNotifyStateChange = 0x00;
  static const int _switchNotifyMeasure = 0x01;

  bool _switchOn = false;
  bool _requesting = false;
  bool _pressing = false;
  // -1: unknown, 0: simple, 1: advanced
  int _hardwareVersion = -1;

  // Advanced version measurement data
  int _voltage = 0; // 0.001V
  int _current = 0; // 0.001A
  int _power = 0; // 0.001W
  int _energy = 0; // 0.001kWh

  bool _isFirstRender = true;

  //
  // The "Device connecting..." dialog is up (its dismissal pops that
  // dialog, not the page; on a reconnect it is not shown, so the pop must
  // be skipped).
  //
  bool _connectingDialog = false;

  // Query the hardware version
  Future<void> _queryVersion() async {
    ByteData byteData = ByteData(1);
    byteData.setUint8(0, _switchCmdGetVersion);
    Uint8List data = byteData.buffer.asUint8List();
    Uint8List? value = await _simpleCtrlHandle.request(data, true);
    // developer.log('Get version return: $value', name: _logName);
    if (value != null &&
        value.length >= 3 &&
        value[0] == _switchCmdGetVersion &&
        value[1] == _switchResultOk) {
      _hardwareVersion = value[2];
      developer.log('Hardware version: $_hardwareVersion', name: _logName);
    } else {
      developer.log('Get version failed, value: $value', name: _logName);
    }
  }

  // Query the current relay state
  Future<void> _queryState() async {
    ByteData byteData = ByteData(1);
    byteData.setUint8(0, _switchCmdGetState);
    Uint8List data = byteData.buffer.asUint8List();
    Uint8List? value = await _simpleCtrlHandle.request(data, true);
    if (value != null &&
        value.length >= 3 &&
        value[0] == _switchCmdGetState &&
        value[1] == _switchResultOk) {
      _switchOn = value[2] != 0;
    }
  }

  // Set the relay state, return true on success
  Future<bool> _setSwitchState(bool on) async {
    ByteData byteData = ByteData(2);
    byteData.setUint8(0, _switchCmdSetState);
    byteData.setUint8(1, on ? 1 : 0);
    Uint8List data = byteData.buffer.asUint8List();
    Uint8List? value = await _simpleCtrlHandle.request(data, true);
    developer.log('Set state return: $value', name: _logName);
    return value != null &&
        value.length >= 2 &&
        value[0] == _switchCmdSetState &&
        value[1] == _switchResultOk;
  }

  // Query the measurement data (advanced version only)
  Future<void> _queryMeasure() async {
    if (_hardwareVersion != _switchVersion1) return;

    // GET_MEASURE
    ByteData byteData = ByteData(1);
    byteData.setUint8(0, _switchCmdGetMeasure);
    Uint8List data = byteData.buffer.asUint8List();
    Uint8List? value = await _simpleCtrlHandle.request(data, true);
    if (value != null &&
        value.length >= 14 &&
        value[0] == _switchCmdGetMeasure &&
        value[1] == _switchResultOk) {
      ByteData bd = ByteData.view(value.buffer, value.offsetInBytes);
      _voltage = bd.getUint32(2, Endian.little);
      _current = bd.getUint32(6, Endian.little);
      _power = bd.getUint32(10, Endian.little);
    }

    // GET_ENERGY
    ByteData energyCmd = ByteData(1);
    energyCmd.setUint8(0, _switchCmdGetEnergy);
    Uint8List energyData = energyCmd.buffer.asUint8List();
    Uint8List? energyValue = await _simpleCtrlHandle.request(energyData, true);
    if (energyValue != null &&
        energyValue.length >= 6 &&
        energyValue[0] == _switchCmdGetEnergy &&
        energyValue[1] == _switchResultOk) {
      ByteData bd = ByteData.view(
        energyValue.buffer,
        energyValue.offsetInBytes,
      );
      _energy = bd.getUint32(2, Endian.little);
    }
  }

  // Handle one notification payload
  void _handleNotify(Uint8List data) {
    if (data.isEmpty) return;
    int type = data[0];
    switch (type) {
      case _switchNotifyStateChange:
        // [type, state]
        if (data.length < 2) return;
        if (!mounted) return;
        setState(() {
          _switchOn = data[1] != 0;
        });
        break;
      case _switchNotifyMeasure:
        // [type, V(4B), I(4B), P(4B), energy(4B)]
        if (data.length < 17) return;
        ByteData byteData = ByteData.view(data.buffer, data.offsetInBytes);
        if (!mounted) return;
        setState(() {
          _voltage = byteData.getUint32(1, Endian.little);
          _current = byteData.getUint32(5, Endian.little);
          _power = byteData.getUint32(9, Endian.little);
          _energy = byteData.getUint32(13, Endian.little);
        });
        break;
      default:
        developer.log('Unknown notify type: $type', name: _logName);
    }
  }

  // Startup query: version -> state -> (measure if advanced)
  Future<void> _startupQuery() async {
    await _queryVersion();
    if (!mounted) return;
    // Dismiss the "Device connecting..." dialog only if it is up (on a
    // reconnect it is not shown and the pop would remove the page)
    if (_connectingDialog) {
      _connectingDialog = false;
      Navigator.pop(context);
    }
    setState(() {});
    await _queryState();
    if (!mounted) return;
    setState(() {});
    if (_hardwareVersion == _switchVersion1) {
      await _queryMeasure();
      if (!mounted) return;
      setState(() {});
    }
  }

  void _stateNotifier() {
    // Connected
    if (_simpleCtrlHandle.stateNotifier.value ==
        SimpleCtrlHandle.stateConnected) {
      SimpleCtrlDataNotifier simpleCtrlDataNotifier =
          _simpleCtrlHandle.notifyNotifier;

      // Listen device notify
      simpleCtrlDataNotifier.addListener(() {
        Uint8List data = simpleCtrlDataNotifier.getData();
        _handleNotify(data);
      });

      // Startup query: version -> state -> (measure if advanced)
      _startupQuery();
    } else if (_simpleCtrlHandle.stateNotifier.value ==
        SimpleCtrlHandle.stateDestroy) {
      // A deliberate cancellation (e.g. of an OTA transfer) makes the
      // device drop this connection; reconnect the same handle in place
      // and stay on the page
      if (_simpleCtrlHandle.reconnecting) return;
      _simpleCtrlHandle.maybeReconnect().then((bool ok) {
        if (!ok && mounted) {
          Navigator.popUntil(context, (route) => route.settings.name == '/switch');
          SimpleSnackBar.show(context, 'Device connection failed', Colors.red);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _discoverDeviceInfo = parameter[0] as DiscoverDeviceInfo;
    _deviceInfo = parameter[1] as DeviceInfo;
    _storageName = parameter[2] as String;

    _simpleCtrlHandle = SimpleCtrlHandle(_discoverDeviceInfo, _deviceInfo);
    _simpleCtrlHandle.stateNotifier.addListener(_stateNotifier);
    _simpleCtrlHandle.initHandle();
  }

  @override
  void dispose() {
    _simpleCtrlHandle.stateNotifier.removeListener(_stateNotifier);
    // Abort a pending reconnect (avoids an orphaned socket and ping timer
    // when the page is left while one is in flight)
    _simpleCtrlHandle.cancelReconnect();
    _simpleCtrlHandle.destroyHandle();
    super.dispose();
  }

  Future<void> _onSwitchChanged(bool newValue) async {
    if (_requesting) return;
    setState(() {
      _switchOn = newValue; // Optimistic update
      _requesting = true;
    });
    bool success = await _setSwitchState(newValue);
    if (!mounted) return;
    setState(() {
      _requesting = false;
      if (!success) {
        _switchOn = !newValue; // Revert
        SimpleSnackBar.show(context, 'Set switch state failed', Colors.red);
      }
    });
  }

  // Big round relay button
  Widget _buildRelayButton(double size) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _requesting
          ? null
          : (_) {
              if (mounted) setState(() => _pressing = true);
            },
      onTapUp: _requesting
          ? null
          : (_) {
              if (mounted) setState(() => _pressing = false);
            },
      onTapCancel: () {
        if (mounted) setState(() => _pressing = false);
      },
      onTap: _requesting ? null : () => _onSwitchChanged(!_switchOn),
      child: AnimatedScale(
        scale: _pressing ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _switchOn
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [mainFillColor, Colors.orange],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF5F5F5), Color(0xFFE2E2E2)],
                  ),
            boxShadow: _switchOn
                ? [
                    BoxShadow(
                      color: mainFillColor.withValues(alpha: 0.55),
                      blurRadius: 48,
                      spreadRadius: 6,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Icon(
            Icons.power,
            size: size * 0.49,
            color: _switchOn ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  // One measurement card (advanced version only)
  Widget _buildMeasureCard(
    IconData icon,
    String label,
    String value,
    String unit,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.cyan),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: subFontFamily,
                  fontSize: 15,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$value $unit',
                style: const TextStyle(
                  fontFamily: subFontFamily,
                  fontSize: 20,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // One compact measurement card (landscape, advanced version)
  Widget _buildMeasureCardH(
    IconData icon,
    String label,
    String value,
    String unit,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.cyan),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: subFontFamily,
                        fontSize: 14,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$value $unit',
                      style: const TextStyle(
                        fontFamily: subFontFamily,
                        fontSize: 18,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
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

  //
  // Advanced version: measurement / energy panel.
  // Portrait: 2x2 grid; landscape: 1x4 row of compact cards.
  //
  Widget _buildMeasurePanel(bool landscape) {
    if (landscape) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(5, 20, 5, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMeasureCardH(
              Icons.electric_bolt,
              'Voltage',
              (_voltage / 1000).toStringAsFixed(3),
              'V',
            ),
            const SizedBox(width: 10),
            _buildMeasureCardH(
              Icons.speed,
              'Current',
              (_current / 1000).toStringAsFixed(3),
              'A',
            ),
            const SizedBox(width: 10),
            _buildMeasureCardH(
              Icons.bolt,
              'Power',
              (_power / 1000).toStringAsFixed(3),
              'W',
            ),
            const SizedBox(width: 10),
            _buildMeasureCardH(
              Icons.electric_meter,
              'Energy',
              (_energy / 1000).toStringAsFixed(3),
              'kWh',
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMeasureCard(
                Icons.electric_bolt,
                'Voltage',
                (_voltage / 1000).toStringAsFixed(3),
                'V',
              ),
              const SizedBox(width: 10),
              _buildMeasureCard(
                Icons.speed,
                'Current',
                (_current / 1000).toStringAsFixed(3),
                'A',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMeasureCard(
                Icons.bolt,
                'Power',
                (_power / 1000).toStringAsFixed(3),
                'W',
              ),
              const SizedBox(width: 10),
              _buildMeasureCard(
                Icons.electric_meter,
                'Energy',
                (_energy / 1000).toStringAsFixed(3),
                'kWh',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirstRender) {
      _isFirstRender = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          // A very fast connection may be up before this runs; showing the
          // dialog then would leave it undismissed (the first response that
          // would pop it is already gone)
          if (!mounted ||
              _simpleCtrlHandle.stateNotifier.value ==
                  SimpleCtrlHandle.stateConnected) {
            return;
          }
          _connectingDialog = true;
          SimpleShowDialog.show(context, 'Device connecting...');
        },
      );
    }

    bool isAdvanced = _hardwareVersion == _switchVersion1;

    return Scaffold(
      appBar: AppBar(
        title: Text(_discoverDeviceInfo.name),
        actions: [
          // Config device button
          IconButton(
            icon: const Icon(Icons.perm_data_setting_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    ParameterStatefulState page = DeviceBindingList
                        .binding[_discoverDeviceInfo.classId]!
                        .configPage();
                    // Set parameter
                    page.parameter = [
                      _discoverDeviceInfo,
                      _storageName,
                      true,
                      _simpleCtrlHandle,
                    ];
                    return ParameterStatefulWidget(page);
                  },
                ),
              ).then((value) {});
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool landscape = constraints.maxWidth > constraints.maxHeight;

            //
            // The content is centered when it fits, and scrollable when it
            // does not (e.g. landscape with the measurement panel), so the
            // page never overflows.
            //
            // Centering is done by the Center (Align) widget, not by
            // mainAxisAlignment: inside the scroll view the max height
            // constraint is unbounded, so a Column (even with
            // MainAxisSize.max) shrinks to the sum of its children and has
            // no free space to distribute.
            //
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Relay control: big round button
                      _buildRelayButton(landscape ? 120 : 180),
                      const SizedBox(height: 28),
                      Text(
                        _switchOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontFamily: mainFontFamily,
                          fontSize: landscape ? 26 : 32,
                          fontWeight: FontWeight.bold,
                          color: _switchOn ? mainFillColor : subTextColor,
                        ),
                      ),
                      // Advanced version: measurement / energy panel
                      if (isAdvanced) _buildMeasurePanel(landscape),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Switch config page
class SwitchConfigDevicePageState extends ParameterStatefulState {
  final InfoEdit _infoEdit = InfoEdit(deviceInfo: DeviceInfo());
  late DiscoverDeviceInfo _discoverDeviceInfo;
  late String _storageName;
  late bool _allowSetPasswd;
  SimpleCtrlHandle? _simpleCtrlHandle;

  Future<void> _deviceInfoLoad() async {
    DeviceStorage storage = DeviceStorage(_storageName);
    await storage.load();
    if (storage.deviceList[_infoEdit.deviceInfo.id] != null) {
      _infoEdit.deviceInfo = storage.deviceList[_infoEdit.deviceInfo.id]!;
    }
  }

  Future<void> _deviceInfoSave() async {
    DeviceStorage storage = DeviceStorage(_storageName);
    await storage.load();
    storage.deviceList[_infoEdit.deviceInfo.id] = _infoEdit.deviceInfo;
    await storage.save();
  }

  @override
  void initState() {
    super.initState();

    _discoverDeviceInfo = parameter[0] as DiscoverDeviceInfo;
    _storageName = parameter[1] as String;
    _allowSetPasswd = parameter[2] as bool;
    if (parameter.length > 3) {
      _simpleCtrlHandle = parameter[3] as SimpleCtrlHandle;
      _infoEdit.ctrlReady = true;
    }
    _infoEdit.deviceInfo.nickName = _discoverDeviceInfo.name;
    _infoEdit.deviceInfo.id = _discoverDeviceInfo.id;
    _deviceInfoLoad().then((value) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return DeviceConfig(
      allowSetPasswd: _allowSetPasswd,
      discoverDeviceInfo: _discoverDeviceInfo,
      infoEdit: _infoEdit,
      ctrlHandle: _simpleCtrlHandle,
      onSavePressed: (infoEdit) {
        if (infoEdit.ctrlReady) {
          SimpleShowDialog.show(context, "Verifying device...");
          Future<bool> result = () async {
            // Set name
            if (infoEdit.syncName) {
              bool ret = await _simpleCtrlHandle!.setName(
                infoEdit.deviceInfo.nickName,
              );
              if (ret != true) return false;
            }
            // Set password
            return await _simpleCtrlHandle!.setPassword(
              infoEdit.deviceInfo.accessKey,
            );
          }.call();
          result.then((bool value) {
            if (value) {
              _deviceInfoSave();
              Navigator.popUntil(
                context,
                (route) => route.settings.name == '/switch',
              );
              SimpleSnackBar.show(
                context,
                'Device information saved',
                Colors.green,
              );
            } else {
              Navigator.pop(context);
              SimpleSnackBar.show(
                context,
                'Failed to configure device information',
                Colors.red,
              );
            }
          });
        } else {
          if (_allowSetPasswd == false) {
            infoEdit.deviceInfo.accessKey = '';
          }
          _deviceInfoSave();
          Navigator.pop(context);
          SimpleSnackBar.show(context, 'Device saved', Colors.green);
        }
      },
    );
  }
}
