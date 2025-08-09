///
/// Created on 2024/05/16
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:hoozz_play/pages/button_led.dart';
import 'package:hoozz_play/pages/voice_led.dart';
import 'package:hoozz_play/pages/smart_ir.dart';
import 'package:hoozz_play/pages/smart_sensor.dart';

class DeviceBindingBody {
  Function configPage;
  Function ctrlPage;
  String describe;

  DeviceBindingBody(this.configPage, this.ctrlPage, this.describe);
}

class DeviceBindingList {
  static const int idVoiceLed = 0x01; /* Voice LED class */
  static const int idButtonLed = 0x02; /* Button LED class */
  static const int idSmartIr = 0x03; /* Smart IR class */
  static const int idSensor = 0x04; /* Sensor class */

  static final Map<int, DeviceBindingBody> binding = {
    idVoiceLed: DeviceBindingBody(
      () => VoiceLEDConfigDevicePageState(),
      () => VoiceLEDDeviceCtrlPageState(),
      'Voice LED',
    ),
    idButtonLed: DeviceBindingBody(
      () => ButtonLEDConfigDevicePageState(),
      () => ButtonLEDDeviceCtrlPageState(),
      'Button LED',
    ),
    idSmartIr: DeviceBindingBody(
      () => SmartIRConfigDevicePageState(),
      () => SmartIRDeviceCtrlPageState(),
      'Smart IR',
    ),
    idSensor: DeviceBindingBody(
      () => SensorConfigDevicePageState(),
      () => SensorDeviceCtrlPageState(),
      'Sensor',
    ),
  };
}
