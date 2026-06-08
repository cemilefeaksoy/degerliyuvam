import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../models/user.dart';
import '../services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController._({required this.api});

  final ApiClient api;

  User? currentUser;
  int unreadCount = 0;
  bool isLoading = true;

  static Future<AppController> create() async {
    final api = await ApiClient.create();
    final controller = AppController._(api: api);
    await NotificationService.initialize();
    await controller.bootstrap();
    return controller;
  }

  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();

    currentUser = await api.me();
    unreadCount = await _safeUnreadCount();
    await NotificationService.showUnreadMessages(unreadCount);
    isLoading = false;
    notifyListeners();
  }

  Future<int> _safeUnreadCount() async {
    try {
      return await api.unreadCount();
    } catch (_) {
      return 0;
    }
  }

  Future<void> refreshSession() async {
    final previousUnreadCount = unreadCount;
    currentUser = await api.me();
    unreadCount = await _safeUnreadCount();
    if (unreadCount > previousUnreadCount) {
      await NotificationService.showUnreadMessages(unreadCount);
    }
    notifyListeners();
  }

  Future<void> login(String email, String password,
      {bool rememberMe = false}) async {
    await api.login(email, password, rememberMe: rememberMe);
    currentUser = await api.me();
    unreadCount = await _safeUnreadCount();
    await NotificationService.showUnreadMessages(unreadCount);
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    bool rememberMe = false,
  }) async {
    await api.register(
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
      rememberMe: rememberMe,
    );
    currentUser = await api.me();
    unreadCount = await _safeUnreadCount();
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    currentUser = null;
    unreadCount = 0;
    notifyListeners();
  }
}
