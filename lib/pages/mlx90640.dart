///
/// Created on 2023/09/03
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:hoozz_play/themes/theme.dart';

import '../adapter/mlx90640_adapter.dart';

class MLX90640HomePage extends StatefulWidget {
  const MLX90640HomePage({super.key});

  final String title = "MLX90640";

  @override
  State<MLX90640HomePage> createState() => _MLX90640HomePageState();
}

class _MLX90640HomePageState extends State<MLX90640HomePage> {
  int _refreshRate = 0;
  double _maxTemperature = 0;
  double _minTemperature = 0;
  List<int> _maxOffset = [0, 0];
  List<int> _minOffset = [0, 0];
  double _crosshairTemperature = 0;
  bool _connectState = false;
  bool _trace = true;
  int _rotate = 180;
  double _emissivity = 0;
  double _taShift = 0;
  Widget _frame = Image.asset('images/white_32x24.png', fit: BoxFit.cover);
  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  double _renderWidth = 0;

  double get _renderScale {
    if (_rotate == 0 || _rotate == 180) {
      return _renderWidth / 32;
    } else {
      return _renderWidth / 24;
    }
  }

  double get _renderHeight {
    if (_rotate == 0 || _rotate == 180) {
      return 24 * _renderScale;
    } else {
      return 32 * _renderScale;
    }
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

  Widget _generateRefreshRateRadioItem(int rate, String desc) {
    return Expanded(
      child: ListTileTheme(
        contentPadding: const EdgeInsets.all(0),
        horizontalTitleGap: 0,
        minVerticalPadding: 0,
        dense: true,
        child: RadioListTile(
          value: rate,
          groupValue: _refreshRate,
          onChanged: (value) {
            setState(() {
              _refreshRate = value!;
              MLX90640Adapter.setRefreshRate(_refreshRate, (success, value) {
                if (success == false) {
                  setState(() {
                    _generateSnackBar(
                        'Error setting refresh rate set to ${desc}Hz',
                        Colors.red);
                    _refreshRate = value;
                  });
                }
              });
            });
          },
          title: Text(
            desc,
            style: const TextStyle(fontSize: 12),
          ),
          selected: _refreshRate == rate,
        ),
      ),
    );
  }

  Widget _generateRotateItem(int rotate) {
    return Expanded(
      child: ListTileTheme(
        contentPadding: const EdgeInsets.all(0),
        horizontalTitleGap: 0,
        minVerticalPadding: 0,
        dense: true,
        child: RadioListTile(
          value: rotate,
          groupValue: _rotate,
          onChanged: (value) {
            setState(() {
              _rotate = value!;
            });
          },
          title: Text(
            '$rotate°',
            style: const TextStyle(fontSize: 12),
          ),
          selected: _rotate == rotate,
        ),
      ),
    );
  }

  Future<void> _takeScreenshot() async {
    try {
      // Create a boundary with the same size as the widget
      RenderRepaintBoundary? boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary?;
      // Convert the boundary to an image
      ui.Image? image = await boundary?.toImage(pixelRatio: 2.0);
      // Convert the image to a byte array
      ByteData? byteData =
          await image!.toByteData(format: ui.ImageByteFormat.png);
      // Convert the byte array to a Uint8List
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get the app's directory
      // final directory = await getApplicationDocumentsDirectory();
      final directory = await getExternalStorageDirectory();
      // Create a file path with the current date and time
      final imagePath =
          '${directory!.path}/screenshot_${DateTime.now().toString()}.png';
      // Create a file and write the image bytes to it
      File file = File(imagePath);
      await file.writeAsBytes(pngBytes);

      // Display a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screenshot saved to $imagePath'),
        ),
      );
    } catch (e) {
      // Display an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to take screenshot: $e'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Get the actual render size after rendering is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BuildContext? context = _stackKey.currentContext;
      RenderBox renderBox = context!.findRenderObject() as RenderBox;
      Size size = renderBox.size;
      _renderWidth = size.width;
    });

    MLX90640Adapter.start(
      (type, value) {
        switch (type) {
          case MLX90640Adapter.TYPE_CONNECT_STATE:
            setState(() {
              _connectState = value as bool;
              if (_connectState == true) {
                _generateSnackBar('Connection succeeded', Colors.green);
              }
            });
            break;
          case MLX90640Adapter.TYPE_ERROR_MESSAGE:
            String msg = value as String;
            _generateSnackBar(msg, Colors.red);
            break;
          case MLX90640Adapter.TYPE_SUCCESS_MESSAGE:
            String msg = value as String;
            _generateSnackBar(msg, Colors.green);
            break;
          case MLX90640Adapter.TYPE_UPDATE_REFRESH_RATE:
            setState(() {
              _refreshRate = value as int;
            });
            break;
          case MLX90640Adapter.TYPE_UPDATE_EMISSIVITY:
            setState(() {
              _emissivity = value as double;
            });
            break;
          case MLX90640Adapter.TYPE_UPDATE_TA_SHIFT:
            setState(() {
              _taShift = value as double;
            });
            break;
          case MLX90640Adapter.TYPE_UPDATE_FRAME_DATA:
            setState(() {
              _frame = value as RawImage;
            });
            break;
          case MLX90640Adapter.TYPE_UPDATE_TEMP_DATA:
            setState(() {
              List<Object> temp = value as List<Object>;
              _minTemperature = temp[0] as double;
              _maxTemperature = temp[1] as double;
              _crosshairTemperature = temp[2] as double;
              List<int> minOffset = temp[3] as List<int>;
              List<int> maxOffset = temp[4] as List<int>;
              // Rotate X/Y
              switch (_rotate) {
                case 0:
                  _minOffset = minOffset;
                  _maxOffset = maxOffset;
                  break;
                case 90:
                  _minOffset[0] = minOffset[1];
                  _minOffset[1] = minOffset[0];
                  _maxOffset[0] = maxOffset[1];
                  _maxOffset[1] = maxOffset[0];
                  _minOffset[0] = 24 - _minOffset[0];
                  _maxOffset[0] = 24 - _maxOffset[0];
                  break;
                case 180:
                  _minOffset = minOffset;
                  _maxOffset = maxOffset;
                  _minOffset[0] = 32 - _minOffset[0];
                  _minOffset[1] = 24 - _minOffset[1];
                  _maxOffset[0] = 32 - _maxOffset[0];
                  _maxOffset[1] = 24 - _maxOffset[1];
                  break;
                case 270:
                  _minOffset[0] = minOffset[1];
                  _minOffset[1] = minOffset[0];
                  _maxOffset[0] = maxOffset[1];
                  _maxOffset[1] = maxOffset[0];
                  _minOffset[1] = 32 - _minOffset[1];
                  _maxOffset[1] = 32 - _maxOffset[1];
                  break;
              }
            });
        }
      },
    );
  }

  @override
  void dispose() {
    MLX90640Adapter.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MaterialColor stateColor = _connectState ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: RepaintBoundary(
        key: _globalKey,
        child: Container(
          color: mainBackgroundColor,
          child: SizedBox.expand(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: stateColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: stateColor.withOpacity(0.5),
                          offset: const Offset(0, 0),
                          blurRadius: 3,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Stack(
                      key: _stackKey,
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 350,
                          child: RotatedBox(
                            quarterTurns: _rotate ~/ 90,
                            child: _frame,
                          ),
                        ),
                        // Draw a cross
                        Positioned(
                          left: _renderWidth / 2 - 10,
                          top: _renderHeight / 2 - 10,
                          child: Visibility(
                            visible: _trace,
                            child: CustomPaint(
                              painter: CrossPainter(),
                              size: const Size(20, 20),
                            ),
                          ),
                        ),
                        Positioned(
                          left: _renderWidth / 2 + 5,
                          top: _renderHeight / 2 + 5,
                          child: Visibility(
                            visible: _trace,
                            child: Text(
                              '${_crosshairTemperature.toStringAsFixed(2)}°C',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontFamily: subFontFamily,
                                // fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Draw a cross
                        Positioned(
                          left: _maxOffset[0] * _renderScale - 10,
                          top: _maxOffset[1] * _renderScale - 10,
                          child: Visibility(
                            visible: _trace,
                            child: CustomPaint(
                              painter: CrossPainter(),
                              size: const Size(20, 20),
                            ),
                          ),
                        ),
                        Positioned(
                          left: _maxOffset[0] * _renderScale + 5,
                          top: _maxOffset[1] * _renderScale + 5,
                          child: Visibility(
                            visible: _trace,
                            child: Text(
                              '${_maxTemperature.toStringAsFixed(2)}°C',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontFamily: subFontFamily,
                                // fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Draw a cross
                        Positioned(
                          left: _minOffset[0] * _renderScale - 10,
                          top: _minOffset[1] * _renderScale - 10,
                          child: Visibility(
                            visible: _trace,
                            child: CustomPaint(
                              painter: CrossPainter(),
                              size: const Size(20, 20),
                            ),
                          ),
                        ),
                        Positioned(
                          left: _minOffset[0] * _renderScale + 5,
                          top: _minOffset[1] * _renderScale + 5,
                          child: Visibility(
                            visible: _trace,
                            child: Text(
                              '${_minTemperature.toStringAsFixed(2)}°C',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                                fontFamily: subFontFamily,
                                // fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAX: ${_maxTemperature.toStringAsFixed(2)}°C',
                          style: const TextStyle(fontSize: 20),
                        ),
                        Text(
                          'MIN: ${_minTemperature.toStringAsFixed(2)}°C',
                          style: const TextStyle(fontSize: 20),
                        ),
                        Text(
                          'Crosshair: ${_crosshairTemperature.toStringAsFixed(2)}°C',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const Divider(
                          height: 32,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const Text('Refresh\nrate(Hz):'),
                            _generateRefreshRateRadioItem(2, '2'),
                            _generateRefreshRateRadioItem(3, '4'),
                            _generateRefreshRateRadioItem(4, '8'),
                            _generateRefreshRateRadioItem(5, '16'),
                            _generateRefreshRateRadioItem(6, '32'),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const Text('Rotate:'),
                            _generateRotateItem(0),
                            _generateRotateItem(90),
                            _generateRotateItem(180),
                            _generateRotateItem(270),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const Text('Trace:'),
                            Switch(
                              value: _trace,
                              onChanged: (bool value) {
                                setState(() {
                                  _trace = value;
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const Text('Mirror:'),
                            Switch(
                              value: MLX90640Adapter.mirror,
                              onChanged: (bool value) {
                                setState(() {
                                  MLX90640Adapter.mirror = value;
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Emissivity:'),
                            Expanded(
                              child: Slider(
                                value: _emissivity,
                                min: 0.0,
                                max: 1.0,
                                divisions: 100,
                                label: '$_emissivity',
                                onChanged: (double newValue) {
                                  setState(() {
                                    _emissivity = newValue;
                                  });
                                },
                                onChangeEnd: (double newValue) {
                                  MLX90640Adapter.setEmissivity(newValue,
                                      (success, value) {
                                    if (success == false) {
                                      setState(() {
                                        _generateSnackBar(
                                            'Error setting emissivity set to ${_emissivity.toStringAsFixed(2)}',
                                            Colors.red);
                                        _emissivity = value;
                                      });
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('Ta shift:'),
                            Expanded(
                              child: Slider(
                                value: _taShift,
                                min: -20,
                                max: 20,
                                divisions: 80,
                                label: '$_taShift',
                                onChanged: (double newValue) {
                                  setState(() {
                                    _taShift = newValue;
                                  });
                                },
                                onChangeEnd: (double newValue) {
                                  MLX90640Adapter.setTaShift(newValue,
                                      (success, value) {
                                    if (success == false) {
                                      setState(() {
                                        _generateSnackBar(
                                            'Error setting Ta shift set to ${_taShift.toStringAsFixed(2)}',
                                            Colors.red);
                                        _taShift = value;
                                      });
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takeScreenshot,
        tooltip: 'Screenshot',
        child: const Icon(Icons.screenshot),
      ),
    );
  }
}

// CrossPainter, Draw a cross
class CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5;
    // Draw line
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
