///
/// Created on 2024/05/26
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';

class GradientCall<T> {
  late T _expectValue;
  late T _currentValue;
  final Function _clone;
  final Function _compare;
  final Function _step;
  final Function _call;
  late Timer _timer;
  final int _interval;
  final T _stepSize;

  GradientCall(T initValue, this._interval, this._stepSize, this._clone,
      this._compare, this._step, this._call) {
    _expectValue = _clone(initValue);
    _currentValue = _clone(initValue);
    _setTimer();
  }

  void _setTimer() {
    _timer = Timer.periodic(Duration(milliseconds: _interval), (Timer timer) {
      T newValue = _step(_expectValue, _currentValue, _stepSize);
      if (_compare(newValue, _currentValue) == true) {
        timer.cancel();
      } else {
        _currentValue = newValue;
        _call(_currentValue);
      }
    });
  }

  void set(T value) {
    _expectValue = value;
    if (!_timer.isActive) _setTimer();
  }
}

class GradientListCall<T> extends GradientCall<List<T>> {
  GradientListCall(
      List<T> initValue, int interval, T stepSize, Function step, Function call)
      : super(initValue, interval, [stepSize], (List<T> src) {
          return [...src];
        }, (List<T> src, List<T> dst) {
          if (src.length != dst.length) return false;
          for (int index = 0; index < src.length; index++) {
            if (src[index] != dst[index]) return false;
          }
          return true;
        }, step, call);
}
