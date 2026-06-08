import 'listing.dart';
import 'offer.dart';

class SellerDashboard {
  SellerDashboard({
    required this.totalListings,
    required this.rentedListings,
    required this.pendingOffers,
    required this.conversionRate,
    required this.myListings,
    required this.incomingOffers,
  });

  final int totalListings;
  final int rentedListings;
  final int pendingOffers;
  final num conversionRate;
  final List<Listing> myListings;
  final List<Offer> incomingOffers;

  factory SellerDashboard.fromJson(Map<String, dynamic> json,
      {String baseUrl = ''}) {
    final listings =
        (json['myListings'] ?? json['MyListings'] ?? const []) as List;
    final offers =
        (json['incomingOffers'] ?? json['IncomingOffers'] ?? const []) as List;

    return SellerDashboard(
      totalListings: _asInt(json['totalListings'] ?? json['TotalListings']),
      rentedListings: _asInt(json['rentedListings'] ?? json['RentedListings']),
      pendingOffers: _asInt(json['pendingOffers'] ?? json['PendingOffers']),
      conversionRate: _asNum(json['conversionRate'] ?? json['ConversionRate']),
      myListings: listings
          .map((e) => Listing.fromJson(Map<String, dynamic>.from(e as Map),
              baseUrl: baseUrl))
          .toList(),
      incomingOffers: offers
          .map((e) => Offer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

int _asInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
num _asNum(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
