///
/// Created on 2024/05/16
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:ffi';
import 'package:flutter/widgets.dart';
import 'package:hoozz_play/pages/voice_led.dart';

abstract class ClassBindingWidget extends StatelessWidget {
  Object parameter = nullptr;
}

class ClassBinding {
  int id;
  ClassBindingWidget page;
  String describe;

  ClassBinding(this.id, this.page, this.describe);
}

class ClassList {
  static const int _iddVoiceLed = 0x01; /* Voice LED class */

  static final Map<int, ClassBinding> classIdList = {
    _iddVoiceLed:
        ClassBinding(_iddVoiceLed, VoiceLEDConfigDevicePage(), 'Voice LED'),
  };
}
