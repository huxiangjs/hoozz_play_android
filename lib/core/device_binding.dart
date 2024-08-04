///
/// Created on 2024/05/16
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:hoozz_play/pages/button_led.dart';
import 'package:hoozz_play/pages/voice_led.dart';

class DeviceBindingBody {
  int id;
  Function configPage;
  Function ctrlPage;
  String describe;

  DeviceBindingBody(this.id, this.configPage, this.ctrlPage, this.describe);
}

class DeviceBindingList {
  static const int idVoiceLed = 0x01; /* Voice LED class */
  static const int idButtonLed = 0x02; /* Button LED class */

  static final Map<int, DeviceBindingBody> binding = {
    idVoiceLed: DeviceBindingBody(
        idVoiceLed,
        () => VoiceLEDConfigDevicePageState(),
        () => VoiceLEDDeviceCtrlPageState(),
        'Voice LED'),
    idButtonLed: DeviceBindingBody(
        idButtonLed,
        () => ButtonLEDConfigDevicePageState(),
        () => ButtonLEDDeviceCtrlPageState(),
        'Button LED'),
  };
}
