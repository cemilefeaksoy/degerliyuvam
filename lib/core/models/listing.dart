import 'dart:convert';

import '../utils/image_url.dart';

class Listing {
  Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.province,
    required this.district,
    required this.city,
    required this.propertyType,
    required this.listingPurpose,
    required this.roomCount,
    required this.grossSquareMeters,
    required this.netSquareMeters,
    required this.buildingAge,
    required this.floor,
    required this.totalFloors,
    required this.bathroomCount,
    required this.heatingType,
    required this.furnished,
    required this.balcony,
    required this.elevator,
    required this.parking,
    required this.inSite,
    required this.hasPool,
    required this.monthlyPrice,
    required this.deposit,
    required this.dues,
    required this.imageUrl,
    required this.ownerUserId,
    required this.ownerName,
    required this.isRented,
    required this.isDailyRecommended,
    required this.isAdminRecommended,
    required this.createdAt,
    this.galleryImages = const [],
  });

  final int id;
  final String title;
  final String description;
  final String province;
  final String district;
  final String city;
  final String propertyType;
  final String listingPurpose;
  final String roomCount;
  final int grossSquareMeters;
  final int netSquareMeters;
  final int buildingAge;
  final int floor;
  final int totalFloors;
  final int bathroomCount;
  final String heatingType;
  final bool furnished;
  final bool balcony;
  final bool elevator;
  final bool parking;
  final bool inSite;
  final bool hasPool;
  final num monthlyPrice;
  final num deposit;
  final num dues;
  final String imageUrl;
  final int ownerUserId;
  final String ownerName;
  final bool isRented;
  final bool isDailyRecommended;
  final bool isAdminRecommended;
  final DateTime createdAt;
  final List<String> galleryImages;

  factory Listing.fromJson(Map<String, dynamic> json, {String baseUrl = ''}) {
    final gallery = <String>[];
    final rawGallery = json['galleryImages'] ?? json['GalleryImages'];
    if (rawGallery is List) {
      gallery.addAll(rawGallery.map((e) => resolveImageUrl(baseUrl, '$e')));
    }
    final rawGalleryJson = json['imageGalleryJson'] ?? json['ImageGalleryJson'];
    if (gallery.isEmpty &&
        rawGalleryJson is String &&
        rawGalleryJson.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(rawGalleryJson) as List<dynamic>;
        gallery.addAll(parsed.map((e) => resolveImageUrl(baseUrl, '$e')));
      } catch (_) {
        // Ignore invalid legacy gallery payloads.
      }
    }

    return Listing(
      id: _asInt(json['id'] ?? json['Id']),
      title: _asString(json['title'] ?? json['Title']),
      description: _asString(json['description'] ?? json['Description']),
      province: _asString(json['province'] ?? json['Province']),
      district: _asString(json['district'] ?? json['District']),
      city: _asString(json['city'] ?? json['City']),
      propertyType: _asString(json['propertyType'] ?? json['PropertyType']),
      listingPurpose:
          _asString(json['listingPurpose'] ?? json['ListingPurpose']),
      roomCount: _asString(json['roomCount'] ?? json['RoomCount']),
      grossSquareMeters:
          _asInt(json['grossSquareMeters'] ?? json['GrossSquareMeters']),
      netSquareMeters:
          _asInt(json['netSquareMeters'] ?? json['NetSquareMeters']),
      buildingAge: _asInt(json['buildingAge'] ?? json['BuildingAge']),
      floor: _asInt(json['floor'] ?? json['Floor']),
      totalFloors: _asInt(json['totalFloors'] ?? json['TotalFloors']),
      bathroomCount: _asInt(json['bathroomCount'] ?? json['BathroomCount']),
      heatingType: _asString(json['heatingType'] ?? json['HeatingType']),
      furnished: _asBool(json['furnished'] ?? json['Furnished']),
      balcony: _asBool(json['balcony'] ?? json['Balcony']),
      elevator: _asBool(json['elevator'] ?? json['Elevator']),
      parking: _asBool(json['parking'] ?? json['Parking']),
      inSite: _asBool(json['inSite'] ?? json['InSite']),
      hasPool: _asBool(json['hasPool'] ?? json['HasPool']),
      monthlyPrice: _asNum(json['monthlyPrice'] ?? json['MonthlyPrice']),
      deposit: _asNum(json['deposit'] ?? json['Deposit']),
      dues: _asNum(json['dues'] ?? json['Dues']),
      imageUrl: resolveImageUrl(
          baseUrl, _asString(json['imageUrl'] ?? json['ImageUrl'])),
      ownerUserId: _asInt(json['ownerUserId'] ?? json['OwnerUserId']),
      ownerName: _asString(json['ownerName'] ?? json['OwnerName']),
      isRented: _asBool(json['isRented'] ?? json['IsRented']),
      isDailyRecommended:
          _asBool(json['isDailyRecommended'] ?? json['IsDailyRecommended']),
      isAdminRecommended:
          _asBool(json['isAdminRecommended'] ?? json['IsAdminRecommended']),
      createdAt: DateTime.tryParse(
              _asString(json['createdAt'] ?? json['CreatedAt'])) ??
          DateTime.now(),
      galleryImages: gallery.isEmpty
          ? [
              resolveImageUrl(
                  baseUrl, _asString(json['imageUrl'] ?? json['ImageUrl']))
            ]
          : gallery,
    );
  }

  String get purposeLabel {
    final normalized = listingPurpose.toLowerCase();
    return normalized.startsWith('sat') ? 'Satılık' : 'Kiralık';
  }
}

int _asInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
num _asNum(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
String _asString(dynamic value) => value == null ? '' : '$value';
bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = '$value'.toLowerCase();
  return normalized == 'true' || normalized == '1';
}
