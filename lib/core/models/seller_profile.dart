import 'listing.dart';
import 'user.dart';

class SellerProfileResponse {
  SellerProfileResponse({
    required this.user,
    required this.totalListings,
    required this.rentedListings,
    required this.pendingOffers,
    required this.conversionRate,
    required this.listings,
  });

  final User user;
  final int totalListings;
  final int rentedListings;
  final int pendingOffers;
  final num conversionRate;
  final List<Listing> listings;

  factory SellerProfileResponse.fromJson(Map<String, dynamic> json,
      {String baseUrl = ''}) {
    final rawListings =
        (json['listings'] ?? json['Listings'] ?? const []) as List;

    return SellerProfileResponse(
      user: User.fromJson(json),
      totalListings: _asInt(json['totalListings'] ?? json['TotalListings']),
      rentedListings: _asInt(json['rentedListings'] ?? json['RentedListings']),
      pendingOffers: _asInt(json['pendingOffers'] ?? json['PendingOffers']),
      conversionRate: _asNum(json['conversionRate'] ?? json['ConversionRate']),
      listings: rawListings
          .map((e) => Listing.fromJson(Map<String, dynamic>.from(e as Map),
              baseUrl: baseUrl))
          .toList(),
    );
  }
}

int _asInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
num _asNum(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
