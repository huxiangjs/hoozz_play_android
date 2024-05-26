///
/// Created on 2024/05/26
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'dart:async';
import 'dart:collection';

class DelayedCall<T> {
  final Queue<T> _valueQueue = Queue<T>();
  final Function _function;
  late Timer _timer;
  final int _timeout;

  DelayedCall(this._timeout, this._function) {
    _setTimer();
  }

  void _setTimer() {
    _timer = Timer.periodic(Duration(milliseconds: _timeout), (Timer timer) {
      if (_valueQueue.isNotEmpty) {
        T value = _valueQueue.removeLast();
        _valueQueue.clear();
        _function(value);
      } else {
        timer.cancel();
      }
    });
  }

  void set(T value) {
    _valueQueue.add(value);
    if (!_timer.isActive) _setTimer();
  }
}
