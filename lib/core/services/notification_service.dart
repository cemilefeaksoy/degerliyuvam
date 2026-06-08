import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const _channel = MethodChannel('degerliyuvam/notifications');

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> initialize() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('initialize');
    } on PlatformException {
      // Bildirim desteği uygulamanın temel akışını engellemez.
    }
  }

  static Future<void> showUnreadMessages(int count) async {
    if (!_isAndroid || count <= 0) return;
    try {
      await _channel.invokeMethod<void>('show', {
        'title': 'Değerli Yuvam',
        'body': '$count okunmamış mesajınız var.',
      });
    } on PlatformException {
      // Kullanıcı bildirime izin vermediyse sessizce devam edilir.
    }
  }
}
