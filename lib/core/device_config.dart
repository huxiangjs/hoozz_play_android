///
/// Created on 2024/08/04
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoozz_play/core/device_binding.dart';
import 'package:hoozz_play/core/device_storage.dart';
import 'package:hoozz_play/core/firmware_version_row.dart';
import 'package:hoozz_play/core/simple_ctrl.dart';
import 'package:hoozz_play/themes/theme.dart';
import 'dart:developer' as developer;

const String _logName = 'Device Configure';

//
// An info row of the configure page (the table in _InfoTable). The label
// is right-aligned; the table's IntrinsicColumnWidth sizes the label
// column to the widest label of the rows that are present (no fixed
// width), and the value column takes the remaining space and wraps on
// narrow screens.
//
TableRow _infoRow(String label, Widget value,
    {EdgeInsets padding = const EdgeInsets.fromLTRB(10, 2, 10, 2)}) {
  return TableRow(
    children: [
      Padding(
        padding: padding,
        child: Text(
          label,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 18),
        ),
      ),
      Padding(
        padding: padding,
        child: value,
      ),
    ],
  );
}

//
// The info table of the configure page (name/class/id/ip/version). It
// fetches the firmware version from the device asynchronously; the version
// row is only present when a version could be fetched (old firmware
// without OTA support does not answer the command), so the
// IntrinsicColumnWidth label column adapts to the rows that are actually
// shown.
//
class _InfoTable extends StatefulWidget {
  final DiscoverDeviceInfo device;
  final SimpleCtrlHandle? ctrl;

  const _InfoTable({required this.device, this.ctrl});

  @override
  State<_InfoTable> createState() => _InfoTableState();
}

class _InfoTableState extends State<_InfoTable> {
  // The firmware version fetched from the device (null until fetched, or
  // when it could not be fetched - the version row is hidden then)
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    if (widget.ctrl == null) return;
    String? version;
    try {
      version = await widget.ctrl!.fwVersion();
    } catch (e) {
      developer.log('Get fw version failed: $e', name: _logName);
    }
    if (!mounted || version == null || version.isEmpty) return;
    setState(() => _version = version);
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(1.0),
      },
      children: [
        _infoRow(
          'NAME:',
          Text(
            widget.device.name,
            style: const TextStyle(fontSize: 18, fontFamily: subFontFamily),
          ),
          padding: const EdgeInsets.fromLTRB(10, 24, 10, 2),
        ),
        _infoRow(
          'CLASS:',
          Text(
            DeviceBindingList.binding[widget.device.classId] == null
                ? 'Unknown'
                : DeviceBindingList.binding[widget.device.classId]!.describe,
            style: const TextStyle(fontSize: 18, fontFamily: subFontFamily),
          ),
        ),
        _infoRow(
          'ID:',
          Text(
            widget.device.id,
            style: const TextStyle(fontSize: 18, fontFamily: subFontFamily),
          ),
        ),
        _infoRow(
          'IP:',
          Text(
            '${widget.device.ip} : ${widget.device.port}',
            style: const TextStyle(fontSize: 18, fontFamily: subFontFamily),
          ),
        ),
        // The firmware version row (offers the OTA update); hidden until
        // the version could be fetched from the device
        if (_version != null)
          _infoRow(
            'VERSION:',
            FirmwareVersionRow(
              device: widget.device,
              ctrl: widget.ctrl!,
              version: _version!,
            ),
          ),
      ],
    );
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

  _DeviceInofInputDecoration(labelText, hintText, [Widget? suffixIcon])
    : super(
        labelText: labelText,
        hintText: hintText,
        suffixIcon: suffixIcon,
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

class InfoEdit {
  DeviceInfo deviceInfo;
  bool ctrlReady = false;
  bool syncName = false;

  InfoEdit({required this.deviceInfo});
}

class DeviceConfig extends StatelessWidget {
  final bool allowSetPasswd;
  final DiscoverDeviceInfo discoverDeviceInfo;
  final InfoEdit infoEdit;
  final Widget child;
  final Function(InfoEdit infoEdit) onSavePressed;

  // The control handle used to query the firmware version (the version
  // row is shown only when a version could be fetched; null for device
  // types without an esp8266 firmware update)
  final SimpleCtrlHandle? ctrlHandle;

  const DeviceConfig({
    super.key,
    required this.allowSetPasswd,
    required this.discoverDeviceInfo,
    required this.infoEdit,
    this.child = const Text(''),
    required this.onSavePressed,
    this.ctrlHandle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configure device")),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The info rows (name/class/id/ip/version) as a table: the
                // right-aligned label column is sized to the widest label
                // of the rows that are present (IntrinsicColumnWidth - it
                // adapts when the version row is hidden), and the value
                // column takes the remaining space and wraps on narrow
                // screens
                _InfoTable(
                  device: discoverDeviceInfo,
                  ctrl: ctrlHandle,
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: TextEditingController(
                      text: infoEdit.deviceInfo.nickName,
                    ),
                    onChanged: (value) => infoEdit.deviceInfo.nickName = value
                        .replaceAll('\r\n', '\n'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: subFontFamily,
                    ),
                    // maxLines: 2,
                    decoration: _DeviceInofInputDecoration(
                      'Device nick name',
                      'Set a nick name for your device',
                    ),
                  ),
                ),
                Visibility(
                  visible: allowSetPasswd,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      inputFormatters: [
                        // FilteringTextInputFormatter.allow(RegExp("[a-zA-Z.,!?]")),
                        FilteringTextInputFormatter.allow(RegExp('[ -~]')),
                      ],
                      controller: TextEditingController(
                        text: infoEdit.deviceInfo.accessKey,
                      ),
                      onChanged: (value) => infoEdit.deviceInfo.accessKey =
                          value.replaceAll('\r\n', '\n'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: subFontFamily,
                      ),
                      maxLength: SimpleCtrlHandle.accessKeyLength,
                      // maxLines: 2,
                      keyboardType: TextInputType.multiline,
                      decoration: _DeviceInofInputDecoration(
                        'Access key',
                        'Set access key for your device',
                        IconButton(
                          onPressed: () {
                            final Random random = Random();
                            final int start = ' '.codeUnits[0];
                            final int stop = '~'.codeUnits[0];
                            final String result = String.fromCharCodes(
                              List.generate(
                                SimpleCtrlHandle.accessKeyLength,
                                (index) =>
                                    random.nextInt(stop - start + 1) + start,
                              ),
                            );
                            setState(() {
                              infoEdit.deviceInfo.accessKey = result;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: infoEdit.ctrlReady,
                  child: CheckboxListTile(
                    title: const Text('Sync name to remote'),
                    // subtitle: const Text('subtitle'),
                    value: infoEdit.syncName,
                    onChanged: (bool? value) =>
                        setState(() => infoEdit.syncName = value!),
                    secondary: const Icon(Icons.sync_rounded),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                child,
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      developer.log(
                        'Nick name: ${infoEdit.deviceInfo.nickName}',
                        name: _logName,
                      );
                      developer.log(
                        'Access key: ${infoEdit.deviceInfo.accessKey}',
                        name: _logName,
                      );
                      onSavePressed(infoEdit);
                    },
                    child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 20, fontFamily: subFontFamily),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
