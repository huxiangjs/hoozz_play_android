// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names

// AUTO GENERATED FILE, DO NOT EDIT.
//
// Generated by `package:ffigen`.
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

/// Bindings for `android/app/src/main/cpp/export.h`.
///
/// Regenerate bindings with `flutter pub run ffigen --config ffigen.yaml`.
///
class HoozzPlayBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  HoozzPlayBindings(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  HoozzPlayBindings.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  /// See: ffigen.yaml
  int remote_sw_init(
    ffi.Pointer<ffi.Char> repository,
    ffi.Pointer<ffi.Char> privkey,
  ) {
    return _remote_sw_init(
      repository,
      privkey,
    );
  }

  late final _remote_sw_initPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)>>('remote_sw_init');
  late final _remote_sw_init = _remote_sw_initPtr
      .asFunction<int Function(ffi.Pointer<ffi.Char>, ffi.Pointer<ffi.Char>)>();

  int remote_sw_press() {
    return _remote_sw_press();
  }

  late final _remote_sw_pressPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('remote_sw_press');
  late final _remote_sw_press =
      _remote_sw_pressPtr.asFunction<int Function()>();

  int remote_sw_result(
    int timeout,
  ) {
    return _remote_sw_result(
      timeout,
    );
  }

  late final _remote_sw_resultPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function(ffi.Int)>>(
          'remote_sw_result');
  late final _remote_sw_result =
      _remote_sw_resultPtr.asFunction<int Function(int)>();

  int remote_sw_report() {
    return _remote_sw_report();
  }

  late final _remote_sw_reportPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('remote_sw_report');
  late final _remote_sw_report =
      _remote_sw_reportPtr.asFunction<int Function()>();

  int gitt_ssh_daemon_wait(
    ffi.Pointer<ffi.Int> ssh_id,
    ffi.Pointer<ffi.Pointer<ffi.Char>> buff,
    ffi.Pointer<ffi.Int> size,
  ) {
    return _gitt_ssh_daemon_wait(
      ssh_id,
      buff,
      size,
    );
  }

  late final _gitt_ssh_daemon_waitPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Int>,
              ffi.Pointer<ffi.Pointer<ffi.Char>>,
              ffi.Pointer<ffi.Int>)>>('gitt_ssh_daemon_wait');
  late final _gitt_ssh_daemon_wait = _gitt_ssh_daemon_waitPtr.asFunction<
      int Function(ffi.Pointer<ffi.Int>, ffi.Pointer<ffi.Pointer<ffi.Char>>,
          ffi.Pointer<ffi.Int>)>();

  void gitt_ssh_daemon_write(
    int ret,
    int ssh_id,
    int size,
  ) {
    return _gitt_ssh_daemon_write(
      ret,
      ssh_id,
      size,
    );
  }

  late final _gitt_ssh_daemon_writePtr =
      _lookup<ffi.NativeFunction<ffi.Void Function(ffi.Int, ffi.Int, ffi.Int)>>(
          'gitt_ssh_daemon_write');
  late final _gitt_ssh_daemon_write =
      _gitt_ssh_daemon_writePtr.asFunction<void Function(int, int, int)>();

  void gitt_ssh_daemon_init() {
    return _gitt_ssh_daemon_init();
  }

  late final _gitt_ssh_daemon_initPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>('gitt_ssh_daemon_init');
  late final _gitt_ssh_daemon_init =
      _gitt_ssh_daemon_initPtr.asFunction<void Function()>();

  void gitt_ssh_daemon_deinit() {
    return _gitt_ssh_daemon_deinit();
  }

  late final _gitt_ssh_daemon_deinitPtr =
      _lookup<ffi.NativeFunction<ffi.Void Function()>>(
          'gitt_ssh_daemon_deinit');
  late final _gitt_ssh_daemon_deinit =
      _gitt_ssh_daemon_deinitPtr.asFunction<void Function()>();
}
