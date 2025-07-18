///
/// Created on 2023/09/03
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class MLX90640Adapter {
  // Create an EventChannel object with a unique name and a codec
  static const EventChannel _eventChannel = EventChannel(
    'MLX90640_EVENT',
    StandardMethodCodec(),
  );
  static StreamSubscription<dynamic>? _subscription;
  static const MethodChannel _methodChannel = MethodChannel('MLX90640_METHOD');

  static bool mirror = false;
  static bool connectState = false;
  static int refreshRate = 0;
  static double emissivity = 0;
  static double taShift = 0;

  static const int TYPE_CONNECT_STATE = 0;
  static const int TYPE_ERROR_MESSAGE = 1;
  static const int TYPE_SUCCESS_MESSAGE = 2;
  static const int TYPE_UPDATE_REFRESH_RATE = 3;
  static const int TYPE_UPDATE_EMISSIVITY = 4;
  static const int TYPE_UPDATE_TA_SHIFT = 5;
  static const int TYPE_UPDATE_FRAME_DATA = 6;
  static const int TYPE_UPDATE_TEMP_DATA = 7;

  static void start(void Function(int type, Object value) onChanged) {
    // Get a Stream object from the EventChannel object
    Stream<dynamic> stream = _eventChannel.receiveBroadcastStream();
    // Listen to the stream and handle each event
    _subscription = stream.listen((event) {
      if (event is String) {
        // Convert the event to a string value
        String value = event;
        String type = value.substring(0, 1);
        String data = value.substring(1);

        switch (type) {
          case 'O':
            connectState = true;
            onChanged(TYPE_CONNECT_STATE, true);
            break;
          case 'C':
            connectState = false;
            onChanged(TYPE_CONNECT_STATE, false);
            break;
          case 'E':
            onChanged(TYPE_ERROR_MESSAGE, data);
            break;
          case 'S':
            onChanged(TYPE_SUCCESS_MESSAGE, data);
            break;
          case 'R':
            refreshRate = int.parse(data);
            onChanged(TYPE_UPDATE_REFRESH_RATE, refreshRate);
            break;
          case 'F':
            emissivity = double.parse(data);
            onChanged(TYPE_UPDATE_EMISSIVITY, emissivity);
            break;
          case 'T':
            taShift = double.parse(data);
            onChanged(TYPE_UPDATE_TA_SHIFT, taShift);
            break;
        }
      } else if (event is Float32List) {
        // Float32List data = Float32List.fromList(event.cast<double>());
        Float32List data = event;

        if (mirror == false) {
          for (int i = 0; i < 24; i++) {
            for (int j = 0; j < 32 / 2; j++) {
              double t = data[i * 32 + j];
              data[i * 32 + j] = data[(i + 1) * 32 - j - 1];
              data[(i + 1) * 32 - j - 1] = t;
            }
          }
        }

        double max = data[0];
        double min = data[0];
        List<int> maxOffset = [0, 0];
        List<int> minOffset = [0, 0];

        for (int i = 0; i < 24; i++) {
          for (int j = 0; j < 32; j++) {
            double t = data[i * 32 + j];
            if (t < min) {
              min = t;
              minOffset[0] = j;
              minOffset[1] = i;
            }
            if (t > max) {
              max = t;
              maxOffset[0] = j;
              maxOffset[1] = i;
            }
          }
        }

        double distance = max - min;
        // if (distance < 10) distance = 10;
        // print('max $max, min $min, distance $distance');

        List<Color> colors = List<Color>.filled(32 * 24, Colors.black);

        // Modify the hue value in HSV coordinates to achieve a gradient from blue to red
        const HSVColor red = HSVColor.fromAHSV(1.0, 0, 1.0, 1.0);
        const HSVColor blue = HSVColor.fromAHSV(1.0, 260, 1.0, 1.0);

        for (int i = 0; i < data.length; i++) {
          // Convert a numeric value to a ratio between 0 and 1
          double ratio = (data[i] - min) / distance;
          ratio = ratio.clamp(0.0, 1.0);
          // nterpolation using HSVColor.lerp() method
          colors[i] = HSVColor.lerp(red, blue, ratio)!.toColor();
        }

        Int32List intList = Int32List.fromList(
          colors.map((color) => color.value).toList(),
        );
        Uint8List uint8List = intList.buffer.asUint8List();
        // Build image
        ui.decodeImageFromPixels(uint8List, 32, 24, ui.PixelFormat.rgba8888, (
          ui.Image image,
        ) {
          RawImage newImage = RawImage(
            filterQuality: FilterQuality.high,
            image: image,
            fit: BoxFit.fill,
          );
          // Update
          onChanged(TYPE_UPDATE_TEMP_DATA, [
            min,
            max,
            data[data.length ~/ 2 + 16],
            minOffset,
            maxOffset,
          ]);
          onChanged(TYPE_UPDATE_FRAME_DATA, newImage);
        });
      } else {
        onChanged(TYPE_ERROR_MESSAGE, 'Unknown event');
      }
    });
  }

  static void setTaShift(
    double newValue,
    void Function(bool success, double value) result,
  ) {
    _methodChannel.invokeMethod('setTaShift', {"value": newValue}).then((
      value,
    ) {
      if (value == 0) {
        taShift = newValue;
        result(true, taShift);
      } else {
        result(false, taShift);
      }
    });
  }

  static void setEmissivity(
    double newValue,
    void Function(bool success, double value) result,
  ) {
    _methodChannel.invokeMethod('setEmissivity', {"value": newValue}).then((
      value,
    ) {
      if (value == 0) {
        emissivity = newValue;
        result(true, emissivity);
      } else {
        result(false, emissivity);
      }
    });
  }

  static void setRefreshRate(
    int newValue,
    void Function(bool success, int value) result,
  ) {
    _methodChannel.invokeMethod('setRefreshRate', {"value": newValue}).then((
      value,
    ) {
      if (value == 0) {
        refreshRate = newValue;
        result(true, refreshRate);
      } else {
        result(false, refreshRate);
      }
    });
  }

  static void stop() {
    _subscription!.cancel();
  }
}
