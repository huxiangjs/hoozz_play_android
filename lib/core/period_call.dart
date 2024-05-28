///
/// Created on 2024/05/29
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';

class PeriodCall {
  final Function _function;
  late Timer _timer;
  final int _idleInterval;
  final int _activeInterval;
  late int _currentInterval;
  bool _pingOnce = true;

  PeriodCall(this._idleInterval, this._function, [this._activeInterval = 100]) {
    _currentInterval = _activeInterval;
    _setTimer();
  }

  void _setTimer() {
    _timer =
        Timer.periodic(Duration(milliseconds: _currentInterval), (Timer timer) {
      if (_pingOnce == false && _currentInterval == _activeInterval) {
        timer.cancel();
        _currentInterval = _idleInterval;
        _setTimer();
      }
      _function();
      _pingOnce = false;
    });
  }

  void ping() {
    if (_timer.isActive == false) return;
    _pingOnce = true;
    if (_currentInterval == _idleInterval) {
      _timer.cancel();
      _currentInterval = _activeInterval;
      _setTimer();
    }
  }

  void cancel() {
    if (_timer.isActive) _timer.cancel();
  }

  void restart() {
    if (_timer.isActive == false) _setTimer();
  }
}
