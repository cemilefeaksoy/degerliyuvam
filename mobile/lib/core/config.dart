import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get defaultBaseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }

    if (kReleaseMode) {
      return 'https://degerliyuvam.com';
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:35929';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:35929';
      case TargetPlatform.iOS:
        return 'http://localhost:35929';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1:35929';
    }
  }
}
