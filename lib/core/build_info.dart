///
/// Created on 2026/11/14
///
/// Author: Hoozz (huxiangjs@foxmail.com)
///

import 'package:flutter/services.dart';

///
/// Build-time information.
///
/// The git hash of the commit the app was built from is injected by the
/// Android gradle build (see android/app/build.gradle.kts) into
/// BuildConfig and handed over through the update method channel.
///
class BuildInfo {
  static const MethodChannel _channel = MethodChannel('UPDATE_METHOD');

  static const String unknown = 'unknown';

  ///
  /// The (short, 12 char) git hash this build was compiled from.
  /// [unknown] when it could not be determined at build time.
  ///
  static Future<String> getGitHash() async {
    try {
      String? hash = await _channel.invokeMethod<String>('getGitHash');
      if (hash == null || hash.isEmpty) return unknown;
      return hash;
    } on PlatformException {
      return unknown;
    }
  }
}
