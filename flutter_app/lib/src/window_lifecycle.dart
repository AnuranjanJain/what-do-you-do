import 'package:flutter/services.dart';

class WindowLifecycle {
  const WindowLifecycle();

  static const _channel = MethodChannel('wdyd/window_lifecycle');

  Future<void> show() async {
    await _channel.invokeMethod<void>('show');
  }

  Future<void> hideToTray() async {
    await _channel.invokeMethod<void>('hideToTray');
  }

  Future<void> exit() async {
    await _channel.invokeMethod<void>('exit');
  }
}
