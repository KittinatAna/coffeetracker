// lib/services/device_service.dart
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceService {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  Future<String> getDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.id; // Unique ID on Android
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return iosInfo.identifierForVendor ?? ''; // Unique ID on iOS
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
