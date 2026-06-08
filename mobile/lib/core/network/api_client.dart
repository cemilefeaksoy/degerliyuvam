import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/admin_models.dart';
import '../models/dashboard.dart';
import '../models/listing.dart';
import '../models/listing_detail.dart';
import '../models/listing_form.dart';
import '../models/message.dart';
import '../models/seller_profile.dart';
import '../models/user.dart';
import '../models/offer.dart';
import 'http_client_factory.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    SharedPreferences? prefs,
  })  : _client = httpClient ?? http.Client(),
        _prefs = prefs;

  final String baseUrl;
  final http.Client _client;
  final SharedPreferences? _prefs;
  final Map<String, String> _cookies = {};
  User? _cachedUser;

  static Future<ApiClient> create({String? baseUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    final client = ApiClient(
      baseUrl: baseUrl ?? AppConfig.defaultBaseUrl,
      httpClient: createHttpClient(),
      prefs: prefs,
    );
    await client._restoreCookies();
    return client;
  }

  User? get cachedUser => _cachedUser;

  Future<void> _restoreCookies() async {
    final raw = _prefs?.getStringList('degerliyuvam.cookies') ?? const [];
    for (final item in raw) {
      final index = item.indexOf('=');
      if (index <= 0) continue;
      _cookies[item.substring(0, index)] = item.substring(index + 1);
    }
  }

  Future<void> _persistCookies() async {
    if (_prefs == null) return;
    await _prefs.setStringList(
      'degerliyuvam.cookies',
      _cookies.entries.map((entry) => '${entry.key}=${entry.value}').toList(),
    );
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    final headers = <String, String>{};
    if (jsonBody) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }
    if (!kIsWeb && _cookies.isNotEmpty) {
      headers['Cookie'] =
          _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
    }
    return headers;
  }

  void _captureCookies(http.Response response) {
    final raw = response.headers['set-cookie'];
    if (raw == null || raw.isEmpty) return;

    final parts = raw.split(',');
    for (final part in parts) {
      final firstChunk = part.split(';').first.trim();
      final index = firstChunk.indexOf('=');
      if (index <= 0) continue;
      _cookies[firstChunk.substring(0, index)] =
          firstChunk.substring(index + 1);
    }

    unawaited(_persistCookies());
  }

  Future<T> _decode<T>(
      Future<http.Response> future, T Function(dynamic json) parser) async {
    final response = await future;
    _captureCookies(response);
    final body = utf8.decode(response.bodyBytes);
    final json = body.isEmpty ? null : jsonDecode(body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parser(json);
    }

    final message = json is Map<String, dynamic>
        ? (json['message'] ?? json['Message'] ?? body)
        : body;
    throw ApiException(message.toString(), response.statusCode);
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(baseUrl);
    final mergedQuery = <String, String>{};
    query?.forEach((key, value) {
      if (value == null) return;
      final text = value.toString();
      if (text.isNotEmpty) {
        mergedQuery[key] = text;
      }
    });
    return base.replace(
      path: '${base.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: mergedQuery.isEmpty ? null : mergedQuery,
    );
  }

  Future<List<Listing>> getListings({
    String? city,
    String? purpose,
    num? minPrice,
    num? maxPrice,
  }) async {
    return _decode(
      _client.get(
        _uri('/api/listings', {
          'city': city,
          'purpose': purpose,
          'minPrice': minPrice,
          'maxPrice': maxPrice,
        }),
        headers: _headers(),
      ),
      (json) {
        final items = json as List<dynamic>;
        return items
            .map((e) => Listing.fromJson(Map<String, dynamic>.from(e as Map),
                baseUrl: baseUrl))
            .toList();
      },
    );
  }

  Future<ListingDetailResponse> getListing(int id) async {
    return _decode(
      _client.get(_uri('/api/listings/$id'), headers: _headers()),
      (json) => ListingDetailResponse.fromJson(
          Map<String, dynamic>.from(json as Map),
          baseUrl: baseUrl),
    );
  }

  Future<List<Listing>> getMyListings() async {
    return _decode(
      _client.get(_uri('/api/listings/mine'), headers: _headers()),
      (json) {
        final items = json as List<dynamic>;
        return items
            .map((e) => Listing.fromJson(Map<String, dynamic>.from(e as Map),
                baseUrl: baseUrl))
            .toList();
      },
    );
  }

  Future<User> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    final user = await _decode(
      _client.post(
        _uri('/api/accounts/login'),
        headers: _headers(jsonBody: true),
        body: jsonEncode(
            {'email': email, 'password': password, 'rememberMe': rememberMe}),
      ),
      (json) => User.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    _cachedUser = user;
    return user;
  }

  Future<User> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    bool rememberMe = false,
  }) async {
    final user = await _decode(
      _client.post(
        _uri('/api/accounts/register'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
          'rememberMe': rememberMe,
        }),
      ),
      (json) => User.fromJson(Map<String, dynamic>.from(json as Map)),
    );
    _cachedUser = user;
    return user;
  }

  Future<User?> me() async {
    try {
      final user = await _decode(
        _client.get(_uri('/api/accounts/me'), headers: _headers()),
        (json) => User.fromJson(Map<String, dynamic>.from(json as Map)),
      );
      _cachedUser = user;
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await _decode(
      _client.post(_uri('/api/accounts/logout'), headers: _headers()),
      (_) => null,
    );
    _cachedUser = null;
    _cookies.clear();
    await _persistCookies();
  }

  Future<String?> forgotPassword(String email) async {
    return _decode(
      _client.post(
        _uri('/api/accounts/forgot-password'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({'email': email}),
      ),
      (json) {
        final map = Map<String, dynamic>.from(json as Map);
        final code = map['resetCode'];
        return code == null ? null : '$code';
      },
    );
  }

  Future<void> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    await _decode(
      _client.post(
        _uri('/api/accounts/reset-password'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({
          'email': email,
          'resetCode': resetCode,
          'newPassword': newPassword,
        }),
      ),
      (_) => null,
    );
  }

  Future<List<ConversationItem>> inbox() async {
    return _decode(
      _client.get(_uri('/api/messages/inbox'), headers: _headers()),
      (json) {
        final items = json as List<dynamic>;
        return items
            .map((e) =>
                ConversationItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
    );
  }

  Future<ConversationDetail> conversation(int withUserId) async {
    return _decode(
      _client.get(_uri('/api/messages/conversation/$withUserId'),
          headers: _headers()),
      (json) =>
          ConversationDetail.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<MessageItem> sendMessage({
    required int toUserId,
    required String content,
    String? imageUrl,
    int? offerId,
  }) async {
    return _decode(
      _client.post(
        _uri('/api/messages/send'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({
          'toUserId': toUserId,
          'content': content,
          'imageUrl': imageUrl,
          'offerId': offerId,
        }),
      ),
      (json) => MessageItem.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<void> editMessage({
    required int messageId,
    required String content,
  }) async {
    await _decode(
      _client.put(
        _uri('/api/messages/$messageId'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({'content': content}),
      ),
      (_) => null,
    );
  }

  Future<void> deleteMessage(int messageId) async {
    await _decode(
      _client.delete(_uri('/api/messages/$messageId'), headers: _headers()),
      (_) => null,
    );
  }

  Future<String> uploadImage({
    required List<int> bytes,
    required String fileName,
    required String category,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/uploads/image', {'category': category}),
    );
    request.headers.addAll(_headers());
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: fileName),
    );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    return _decode(
      Future.value(response),
      (json) => '${(json as Map)['url'] ?? ''}',
    );
  }

  Future<int> unreadCount() async {
    return _decode(
      _client.get(_uri('/api/messages/unread-count'), headers: _headers()),
      (json) => json is Map<String, dynamic>
          ? _asInt(json['unreadCount'] ?? json['UnreadCount'])
          : 0,
    );
  }

  Future<SellerProfileResponse> sellerProfile(int id) async {
    return _decode(
      _client.get(_uri('/api/profile/seller/$id'), headers: _headers()),
      (json) {
        final map = Map<String, dynamic>.from(json as Map);
        return SellerProfileResponse.fromJson(map, baseUrl: baseUrl);
      },
    );
  }

  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
    required String bio,
    String? profileImageUrl,
    String? currentPassword,
    String? newPassword,
  }) async {
    await _decode(
      _client.put(
        _uri('/api/profile/me'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'bio': bio,
          'profileImageUrl': profileImageUrl,
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ),
      (_) => null,
    );
  }

  Future<SellerDashboard> sellerDashboard() async {
    return _decode(
      _client.get(_uri('/api/seller/dashboard'), headers: _headers()),
      (json) => SellerDashboard.fromJson(Map<String, dynamic>.from(json as Map),
          baseUrl: baseUrl),
    );
  }

  Future<List<Offer>> sellerOffers() async {
    return _decode(
      _client.get(_uri('/api/seller/offers'), headers: _headers()),
      (json) {
        final items = json as List<dynamic>;
        return items
            .map((e) => Offer.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
    );
  }

  Future<void> updateOfferStatus({
    required int offerId,
    required bool accepted,
  }) async {
    await _decode(
      _client.post(
        _uri('/api/seller/offers/$offerId'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({'status': accepted ? 1 : 2}),
      ),
      (_) => null,
    );
  }

  Future<Listing> createListing(ListingDraft draft) async {
    return _decode(
      _client.post(
        _uri('/api/listings'),
        headers: _headers(jsonBody: true),
        body: jsonEncode(draft.toJson()),
      ),
      (json) => Listing.fromJson(Map<String, dynamic>.from(json as Map),
          baseUrl: baseUrl),
    );
  }

  Future<Listing> updateListing(ListingDraft draft) async {
    final id = draft.id;
    if (id == null) {
      throw ArgumentError('draft.id is required for updateListing');
    }

    return _decode(
      _client.put(
        _uri('/api/listings/$id'),
        headers: _headers(jsonBody: true),
        body: jsonEncode(draft.toJson()),
      ),
      (json) => Listing.fromJson(Map<String, dynamic>.from(json as Map),
          baseUrl: baseUrl),
    );
  }

  Future<void> deleteListing(int id) async {
    await _decode(
      _client.delete(_uri('/api/listings/$id'), headers: _headers()),
      (_) => null,
    );
  }

  Future<void> toggleAdminRecommendation(int id) async {
    await _decode(
      _client.post(_uri('/api/listings/$id/toggle-admin-recommendation'),
          headers: _headers()),
      (_) => null,
    );
  }

  Future<void> toggleDailyRecommendation(int id) async {
    await _decode(
      _client.post(_uri('/api/listings/$id/toggle-daily-recommendation'),
          headers: _headers()),
      (_) => null,
    );
  }

  Future<AdminDashboardResponse> adminDashboard() async {
    return _decode(
      _client.get(_uri('/api/admin/dashboard'), headers: _headers()),
      (json) => AdminDashboardResponse.fromJson(
          Map<String, dynamic>.from(json as Map),
          baseUrl: baseUrl),
    );
  }

  Future<List<User>> adminUsers() async {
    return _decode(
      _client.get(_uri('/api/admin/users'), headers: _headers()),
      (json) {
        final items = json as List<dynamic>;
        return items
            .map((e) => User.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      },
    );
  }

  Future<User> createAdminUser({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required String role,
    required bool isSellerApproved,
    String bio = '',
    String profileImageUrl = '',
  }) async {
    return _decode(
      _client.post(
        _uri('/api/admin/users'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
          'confirmPassword': password,
          'role': role == 'Admin' ? 1 : 0,
          'isSellerApproved': isSellerApproved,
          'bio': bio,
          'profileImageUrl': profileImageUrl,
        }),
      ),
      (json) => User.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<User> updateAdminUser({
    required int id,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String role,
    required bool isSellerApproved,
    String bio = '',
    String profileImageUrl = '',
    String newPassword = '',
  }) async {
    return _decode(
      _client.put(
        _uri('/api/admin/users/$id'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({
          'id': id,
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'role': role == 'Admin' ? 1 : 0,
          'isSellerApproved': isSellerApproved,
          'bio': bio,
          'profileImageUrl': profileImageUrl,
          'newPassword': newPassword,
          'confirmNewPassword': newPassword,
        }),
      ),
      (json) => User.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<void> deleteAdminUser(int id) async {
    await _decode(
      _client.delete(_uri('/api/admin/users/$id'), headers: _headers()),
      (_) => null,
    );
  }

  Future<void> setSellerApproval(int id, bool approved) async {
    await _decode(
      _client.post(
        _uri('/api/admin/users/$id/seller-approval'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({'approved': approved}),
      ),
      (_) => null,
    );
  }

  Future<void> setAdminRole(int id, bool makeAdmin) async {
    await _decode(
      _client.post(
        _uri('/api/admin/users/$id/role'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({'makeAdmin': makeAdmin}),
      ),
      (_) => null,
    );
  }

  Future<AdminReportResponse> adminReports({
    String? reportStart,
    String? reportEnd,
    int? reportSellerId,
    String? reportFeature,
    String? reportEvent,
  }) async {
    return _decode(
      _client.get(
        _uri('/api/admin/reports', {
          'reportStart': reportStart,
          'reportEnd': reportEnd,
          'reportSellerId': reportSellerId,
          'reportFeature': reportFeature,
          'reportEvent': reportEvent,
        }),
        headers: _headers(),
      ),
      (json) =>
          AdminReportResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<Offer> createOffer({
    required int listingId,
    required num amount,
    String? note,
  }) async {
    return _decode(
      _client.post(
        _uri('/api/listings/$listingId/offer'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({
          'amount': amount,
          'note': note,
        }),
      ),
      (json) => Offer.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<Offer> createRentalRequest({
    required int listingId,
    required String cardLast4,
  }) async {
    return _decode(
      _client.post(
        _uri('/api/listings/$listingId/rental-request'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({
          'cardLast4': cardLast4,
        }),
      ),
      (json) => Offer.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<void> addComment({
    required int listingId,
    required String content,
  }) async {
    await _decode(
      _client.post(
        _uri('/api/listings/$listingId/comment'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({'content': content}),
      ),
      (_) => null,
    );
  }

  Future<void> addRating({
    required int listingId,
    required int listingScore,
    required int sellerScore,
    String? comment,
  }) async {
    await _decode(
      _client.post(
        _uri('/api/listings/$listingId/rating'),
        headers: _headers(jsonBody: true),
        body: jsonEncode({
          'listingScore': listingScore,
          'sellerScore': sellerScore,
          'comment': comment,
        }),
      ),
      (_) => null,
    );
  }
}

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

int _asInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
