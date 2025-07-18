# :rocket: Hoozz Play

Hoozz Play is a fun application through which all supported hardware will be used.

This is a sub-repository, and the main repository is located at [Hoozz Play](https://github.com/huxiangjs/hoozz_play)

## Pull code

```shell
git clone https://github.com/huxiangjs/hoozz_play_android.git
cd hoozz_play_android
git submodule update --init --recursive
```

## Build

This application is created based on Flutter, so you need to choose a version of the Flutter development environment to build. You can refer to the following versions:
```shell
> flutter --version
Flutter 3.32.7 • channel stable • https://github.com/flutter/flutter.git
Framework • revision d7b523b356 (3 days ago) • 2025-07-15 17:03:46 -0700
Engine • revision 39d6d6e699 (3 days ago) • 2025-07-15 15:39:12 -0700
Tools • Dart 3.8.1 • DevTools 2.45.1

> dart --version
Dart SDK version: 3.8.1 (stable) (Wed May 28 00:47:25 2025 -0700) on "windows_x64"
```

Use the following command when debugging:
```shell
flutter run
```

Use the following command when releasing:
```shell
flutter build apk
```

## Test

Tested version of Android:
* Android 4.4.4 (Versions 4.0.0 and later will no longer support)
* Android 5.1
* Android 6.0
* Android 7.1.2
* Android 12
* Android 13
