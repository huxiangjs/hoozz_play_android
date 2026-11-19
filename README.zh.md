# :rocket: Hoozz Play

<div align="center">
  <a href="./README.md"><img src="https://img.shields.io/badge/README-English-2ea44f?style=for-the-badge" alt="English README"></a>
  <a href="./README.zh.md"><img src="https://img.shields.io/badge/README-%E4%B8%AD%E6%96%87-d3333f?style=for-the-badge" alt="中文 README"></a>
</div>

Hoozz Play 是一款有趣的安卓应用，所有支持的硬件设备都可以在其中使用。

本仓库是子仓库，主仓库位于 [Hoozz Play](https://github.com/huxiangjs/hoozz_play)。

**构建状态**
[![Android CI](https://github.com/huxiangjs/hoozz_play_android/actions/workflows/android.yml/badge.svg?branch=master)](https://github.com/huxiangjs/hoozz_play_android/actions/workflows/android.yml)

## 拉取代码

```shell
git clone https://github.com/huxiangjs/hoozz_play_android.git
cd hoozz_play_android
git submodule update --init --recursive
```

## 构建

本应用基于 Flutter 开发，构建时需要选择相应版本的 Flutter 开发环境。可参考以下版本：
```shell
> flutter --version
Flutter 3.32.7 • channel stable • https://github.com/flutter/flutter.git
Framework • revision d7b523b356 (3 days ago) • 2025-07-15 17:03:46 -0700
Engine • revision 39d6d6e699 (3 days ago) • 2025-07-15 15:39:12 -0700
Tools • Dart 3.8.1 • DevTools 2.45.1

> dart --version
Dart SDK version: 3.8.1 (stable) (Wed May 28 00:47:25 2025 -0700) on "windows_x64"
```

调试时使用以下命令：
```shell
flutter run
```

发布时使用以下命令：
```shell
flutter build apk
```

## 测试

已测试的 Android 版本：
* Android 4.4.4（4.0.0 及更早版本不再支持）
* Android 5.1
* Android 6.0
* Android 7.1.2
* Android 12
* Android 13
