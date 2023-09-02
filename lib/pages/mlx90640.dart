import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hoozz_play/themes/theme.dart';

class MLX90640HomePage extends StatefulWidget {
  const MLX90640HomePage({super.key});

  final String title = "MLX90640";

  @override
  State<MLX90640HomePage> createState() => _MLX90640HomePageState();
}

class _MLX90640HomePageState extends State<MLX90640HomePage> {
  int _frameRate = 0;
  int _maxTemperature = 0;
  int _minTemperature = 0;
  int _crosshairTemperature = 0;
  bool _connectState = false;
  GlobalKey _globalKey = GlobalKey();

  void generateSnackBar(String str) {
    SnackBar snackBar = SnackBar(
        content: Text(
          str,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: mainFontFamily,
          ),
        ),
        backgroundColor: mainFillColor);
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget generateFrameRateRadioItem(int name) {
    return Expanded(
      child: ListTileTheme(
        contentPadding: const EdgeInsets.all(0),
        horizontalTitleGap: 0,
        minVerticalPadding: 0,
        dense: true,
        child: RadioListTile(
          value: name,
          groupValue: _frameRate,
          onChanged: (value) {
            setState(() {
              _frameRate = value!;
              generateSnackBar('Frame rate set to ${_frameRate}Hz');
            });
          },
          title: Text(
            name.toString(),
            style: const TextStyle(fontSize: 12),
          ),
          selected: _frameRate == name,
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
                    child: SizedBox(
                      width: 350,
                      child: Image.asset('images/product_view_mlx90640.png'),
                    ),
                  ),
                  SizedBox(
                    width: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAX: $_maxTemperature°C',
                          style: const TextStyle(fontSize: 20),
                        ),
                        Text(
                          'MIN: $_minTemperature°C',
                          style: const TextStyle(fontSize: 20),
                        ),
                        Text(
                          'Crosshair: $_crosshairTemperature°C',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const Divider(
                          height: 1,
                        ),
                        Row(
                          children: <Widget>[
                            const Text('Frame\nrate:'),
                            generateFrameRateRadioItem(2),
                            generateFrameRateRadioItem(4),
                            generateFrameRateRadioItem(8),
                            generateFrameRateRadioItem(16),
                            generateFrameRateRadioItem(32),
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
