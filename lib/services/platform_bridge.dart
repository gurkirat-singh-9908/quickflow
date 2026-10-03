import 'package:flutter/services.dart';

class PlatformBridge {
  static const MethodChannel _channel = MethodChannel('com.snaphack.quickflow/bridge');

  static final PlatformBridge instance = PlatformBridge._internal();
  PlatformBridge._internal();

  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool? result = await _channel.invokeMethod('isAccessibilityEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  Future<bool> isOverlayPermissionGranted() async {
    try {
      final bool? result = await _channel.invokeMethod('isOverlayPermissionGranted');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openOverlaySettings() async {
    try {
      await _channel.invokeMethod('openOverlaySettings');
    } catch (_) {}
  }

  Future<bool> toggleFloatingBubble(bool enable) async {
    try {
      final bool? result = await _channel.invokeMethod('toggleFloatingBubble', {'enable': enable});
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isFloatingBubbleRunning() async {
    try {
      final bool? result = await _channel.invokeMethod('isFloatingBubbleRunning');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncDataToNative(String jsonPayload) async {
    try {
      await _channel.invokeMethod('syncData', {'data': jsonPayload});
    } catch (_) {}
  }

  Future<void> resetSmartHistory() async {
    try {
      await _channel.invokeMethod('resetSmartHistory');
    } catch (_) {}
  }
}
