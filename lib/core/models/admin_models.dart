import 'listing.dart';
import 'user.dart';

class AdminDashboardResponse {
  AdminDashboardResponse({
    required this.totalListings,
    required this.activeListings,
    required this.rentedListings,
    required this.totalUsers,
    required this.totalAdmins,
    required this.pendingSellers,
    required this.totalOffers,
    required this.pendingOffers,
    required this.acceptedOffers,
    required this.rejectedOffers,
    required this.totalRentals,
    required this.totalMessages,
    required this.unreadMessages,
    required this.totalRatings,
    required this.averageListingRating,
    required this.averageSellerRating,
    required this.thisMonthOffers,
    required this.thisMonthRentals,
    required this.rentalRate,
    required this.approvalRate,
    required this.totalRevenuePotential,
    required this.averageListingPrice,
    required this.adminRecommendedCount,
    required this.dailyRecommendedCount,
    required this.topCities,
    required this.topSellers,
    required this.latestListings,
    required this.latestUsers,
    required this.isSuperAdmin,
  });

  final int totalListings;
  final int activeListings;
  final int rentedListings;
  final int totalUsers;
  final int totalAdmins;
  final int pendingSellers;
  final int totalOffers;
  final int pendingOffers;
  final int acceptedOffers;
  final int rejectedOffers;
  final int totalRentals;
  final int totalMessages;
  final int unreadMessages;
  final int totalRatings;
  final num averageListingRating;
  final num averageSellerRating;
  final int thisMonthOffers;
  final int thisMonthRentals;
  final int rentalRate;
  final int approvalRate;
  final num totalRevenuePotential;
  final num averageListingPrice;
  final int adminRecommendedCount;
  final int dailyRecommendedCount;
  final List<AdminCityStat> topCities;
  final List<AdminSellerStat> topSellers;
  final List<Listing> latestListings;
  final List<User> latestUsers;
  final bool isSuperAdmin;

  factory AdminDashboardResponse.fromJson(Map<String, dynamic> json,
      {String baseUrl = ''}) {
    return AdminDashboardResponse(
      totalListings: _asInt(json['totalListings'] ?? json['TotalListings']),
      activeListings: _asInt(json['activeListings'] ?? json['ActiveListings']),
      rentedListings: _asInt(json['rentedListings'] ?? json['RentedListings']),
      totalUsers: _asInt(json['totalUsers'] ?? json['TotalUsers']),
      totalAdmins: _asInt(json['totalAdmins'] ?? json['TotalAdmins']),
      pendingSellers: _asInt(json['pendingSellers'] ?? json['PendingSellers']),
      totalOffers: _asInt(json['totalOffers'] ?? json['TotalOffers']),
      pendingOffers: _asInt(json['pendingOffers'] ?? json['PendingOffers']),
      acceptedOffers: _asInt(json['acceptedOffers'] ?? json['AcceptedOffers']),
      rejectedOffers: _asInt(json['rejectedOffers'] ?? json['RejectedOffers']),
      totalRentals: _asInt(json['totalRentals'] ?? json['TotalRentals']),
      totalMessages: _asInt(json['totalMessages'] ?? json['TotalMessages']),
      unreadMessages: _asInt(json['unreadMessages'] ?? json['UnreadMessages']),
      totalRatings: _asInt(json['totalRatings'] ?? json['TotalRatings']),
      averageListingRating:
          _asNum(json['averageListingRating'] ?? json['AverageListingRating']),
      averageSellerRating:
          _asNum(json['averageSellerRating'] ?? json['AverageSellerRating']),
      thisMonthOffers:
          _asInt(json['thisMonthOffers'] ?? json['ThisMonthOffers']),
      thisMonthRentals:
          _asInt(json['thisMonthRentals'] ?? json['ThisMonthRentals']),
      rentalRate: _asInt(json['rentalRate'] ?? json['RentalRate']),
      approvalRate: _asInt(json['approvalRate'] ?? json['ApprovalRate']),
      totalRevenuePotential: _asNum(
          json['totalRevenuePotential'] ?? json['TotalRevenuePotential']),
      averageListingPrice:
          _asNum(json['averageListingPrice'] ?? json['AverageListingPrice']),
      adminRecommendedCount: _asInt(
          json['adminRecommendedCount'] ?? json['AdminRecommendedCount']),
      dailyRecommendedCount: _asInt(
          json['dailyRecommendedCount'] ?? json['DailyRecommendedCount']),
      topCities: ((json['topCities'] ?? json['TopCities']) as List? ?? const [])
          .map((e) =>
              AdminCityStat.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      topSellers:
          ((json['topSellers'] ?? json['TopSellers']) as List? ?? const [])
              .map((e) =>
                  AdminSellerStat.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
      latestListings:
          ((json['latestListings'] ?? json['LatestListings']) as List? ??
                  const [])
              .map((e) => Listing.fromJson(Map<String, dynamic>.from(e as Map),
                  baseUrl: baseUrl))
              .toList(),
      latestUsers:
          ((json['latestUsers'] ?? json['LatestUsers']) as List? ?? const [])
              .map((e) => User.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
      isSuperAdmin: _asBool(json['isSuperAdmin'] ?? json['IsSuperAdmin']),
    );
  }
}

class AdminCityStat {
  AdminCityStat(
      {required this.city, required this.count, required this.avgPrice});

  final String city;
  final int count;
  final num avgPrice;

  factory AdminCityStat.fromJson(Map<String, dynamic> json) {
    return AdminCityStat(
      city: _asString(json['city'] ?? json['City']),
      count: _asInt(json['count'] ?? json['Count']),
      avgPrice: _asNum(json['avgPrice'] ?? json['AvgPrice']),
    );
  }
}

class AdminSellerStat {
  AdminSellerStat({
    required this.sellerId,
    required this.seller,
    required this.listingCount,
    required this.rentedCount,
    required this.offerCount,
    required this.acceptanceRate,
  });

  final int sellerId;
  final String seller;
  final int listingCount;
  final int rentedCount;
  final int offerCount;
  final int acceptanceRate;

  factory AdminSellerStat.fromJson(Map<String, dynamic> json) {
    return AdminSellerStat(
      sellerId: _asInt(json['sellerId'] ?? json['SellerId']),
      seller: _asString(json['seller'] ?? json['Seller']),
      listingCount: _asInt(json['listingCount'] ?? json['ListingCount']),
      rentedCount: _asInt(json['rentedCount'] ?? json['RentedCount']),
      offerCount: _asInt(json['offerCount'] ?? json['OfferCount']),
      acceptanceRate: _asInt(json['acceptanceRate'] ?? json['AcceptanceRate']),
    );
  }
}

class AdminReportResponse {
  AdminReportResponse({
    required this.startAt,
    required this.endAt,
    required this.sellerUserId,
    required this.featureFilter,
    required this.eventFilter,
    required this.totalOffers,
    required this.totalComments,
    required this.totalRatings,
    required this.totalSales,
    required this.uniqueOfferUsers,
    required this.uniqueCommentUsers,
    required this.uniqueRatingUsers,
    required this.uniqueBuyers,
    required this.thisMonthOfferCount,
    required this.thisMonthCommentCount,
    required this.thisMonthRatingCount,
    required this.sellerOptions,
    required this.offers,
    required this.comments,
    required this.ratings,
    required this.sales,
    required this.sellerPerformance,
  });

  final String startAt;
  final String endAt;
  final int? sellerUserId;
  final String featureFilter;
  final String eventFilter;
  final int totalOffers;
  final int totalComments;
  final int totalRatings;
  final int totalSales;
  final int uniqueOfferUsers;
  final int uniqueCommentUsers;
  final int uniqueRatingUsers;
  final int uniqueBuyers;
  final int thisMonthOfferCount;
  final int thisMonthCommentCount;
  final int thisMonthRatingCount;
  final List<AdminReportSellerOption> sellerOptions;
  final List<AdminReportOffer> offers;
  final List<AdminReportComment> comments;
  final List<AdminReportRating> ratings;
  final List<AdminReportSale> sales;
  final List<AdminReportSellerPerformance> sellerPerformance;

  factory AdminReportResponse.fromJson(Map<String, dynamic> json) {
    return AdminReportResponse(
      startAt: _asString(json['startAt'] ?? json['StartAt']),
      endAt: _asString(json['endAt'] ?? json['EndAt']),
      sellerUserId: _nullableInt(json['sellerUserId'] ?? json['SellerUserId']),
      featureFilter: _asString(json['featureFilter'] ?? json['FeatureFilter']),
      eventFilter: _asString(json['eventFilter'] ?? json['EventFilter']),
      totalOffers: _asInt(json['totalOffers'] ?? json['TotalOffers']),
      totalComments: _asInt(json['totalComments'] ?? json['TotalComments']),
      totalRatings: _asInt(json['totalRatings'] ?? json['TotalRatings']),
      totalSales: _asInt(json['totalSales'] ?? json['TotalSales']),
      uniqueOfferUsers:
          _asInt(json['uniqueOfferUsers'] ?? json['UniqueOfferUsers']),
      uniqueCommentUsers:
          _asInt(json['uniqueCommentUsers'] ?? json['UniqueCommentUsers']),
      uniqueRatingUsers:
          _asInt(json['uniqueRatingUsers'] ?? json['UniqueRatingUsers']),
      uniqueBuyers: _asInt(json['uniqueBuyers'] ?? json['UniqueBuyers']),
      thisMonthOfferCount:
          _asInt(json['thisMonthOfferCount'] ?? json['ThisMonthOfferCount']),
      thisMonthCommentCount: _asInt(
          json['thisMonthCommentCount'] ?? json['ThisMonthCommentCount']),
      thisMonthRatingCount:
          _asInt(json['thisMonthRatingCount'] ?? json['ThisMonthRatingCount']),
      sellerOptions:
          ((json['sellerOptions'] ?? json['SellerOptions']) as List? ??
                  const [])
              .map((e) => AdminReportSellerOption.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList(),
      offers: ((json['offers'] ?? json['Offers']) as List? ?? const [])
          .map((e) =>
              AdminReportOffer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      comments: ((json['comments'] ?? json['Comments']) as List? ?? const [])
          .map((e) =>
              AdminReportComment.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      ratings: ((json['ratings'] ?? json['Ratings']) as List? ?? const [])
          .map((e) =>
              AdminReportRating.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      sales: ((json['sales'] ?? json['Sales']) as List? ?? const [])
          .map((e) =>
              AdminReportSale.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      sellerPerformance:
          ((json['sellerPerformance'] ?? json['SellerPerformance']) as List? ??
                  const [])
              .map((e) => AdminReportSellerPerformance.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList(),
    );
  }
}

class AdminReportSellerOption {
  AdminReportSellerOption({required this.sellerId, required this.sellerName});
  final int sellerId;
  final String sellerName;

  factory AdminReportSellerOption.fromJson(Map<String, dynamic> json) {
    return AdminReportSellerOption(
      sellerId: _asInt(json['sellerId'] ?? json['SellerId']),
      sellerName: _asString(json['sellerName'] ?? json['SellerName']),
    );
  }
}

class AdminReportOffer {
  AdminReportOffer({
    required this.offerId,
    required this.listingId,
    required this.listingTitle,
    required this.sellerName,
    required this.customerName,
    required this.offerType,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  final int offerId;
  final int listingId;
  final String listingTitle;
  final String sellerName;
  final String customerName;
  final String offerType;
  final num amount;
  final String status;
  final DateTime createdAt;

  factory AdminReportOffer.fromJson(Map<String, dynamic> json) {
    return AdminReportOffer(
      offerId: _asInt(json['offerId'] ?? json['OfferId']),
      listingId: _asInt(json['listingId'] ?? json['ListingId']),
      listingTitle: _asString(json['listingTitle'] ?? json['ListingTitle']),
      sellerName: _asString(json['sellerName'] ?? json['SellerName']),
      customerName: _asString(json['customerName'] ?? json['CustomerName']),
      offerType: _asString(json['offerType'] ?? json['OfferType']),
      amount: _asNum(json['amount'] ?? json['Amount']),
      status: _asString(json['status'] ?? json['Status']),
      createdAt: DateTime.tryParse(
              _asString(json['createdAt'] ?? json['CreatedAt'])) ??
          DateTime.now(),
    );
  }
}

class AdminReportComment {
  AdminReportComment({
    required this.listingId,
    required this.listingTitle,
    required this.sellerName,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final int listingId;
  final String listingTitle;
  final String sellerName;
  final String authorName;
  final String content;
  final DateTime createdAt;

  factory AdminReportComment.fromJson(Map<String, dynamic> json) {
    return AdminReportComment(
      listingId: _asInt(json['listingId'] ?? json['ListingId']),
      listingTitle: _asString(json['listingTitle'] ?? json['ListingTitle']),
      sellerName: _asString(json['sellerName'] ?? json['SellerName']),
      authorName: _asString(json['authorName'] ?? json['AuthorName']),
      content: _asString(json['content'] ?? json['Content']),
      createdAt: DateTime.tryParse(
              _asString(json['createdAt'] ?? json['CreatedAt'])) ??
          DateTime.now(),
    );
  }
}

class AdminReportRating {
  AdminReportRating({
    required this.listingId,
    required this.listingTitle,
    required this.sellerName,
    required this.renterName,
    required this.listingScore,
    required this.sellerScore,
    required this.comment,
    required this.createdAt,
  });

  final int listingId;
  final String listingTitle;
  final String sellerName;
  final String renterName;
  final int listingScore;
  final int sellerScore;
  final String comment;
  final DateTime createdAt;

  factory AdminReportRating.fromJson(Map<String, dynamic> json) {
    return AdminReportRating(
      listingId: _asInt(json['listingId'] ?? json['ListingId']),
      listingTitle: _asString(json['listingTitle'] ?? json['ListingTitle']),
      sellerName: _asString(json['sellerName'] ?? json['SellerName']),
      renterName: _asString(json['renterName'] ?? json['RenterName']),
      listingScore: _asInt(json['listingScore'] ?? json['ListingScore']),
      sellerScore: _asInt(json['sellerScore'] ?? json['SellerScore']),
      comment: _asString(json['comment'] ?? json['Comment']),
      createdAt: DateTime.tryParse(
              _asString(json['createdAt'] ?? json['CreatedAt'])) ??
          DateTime.now(),
    );
  }
}

class AdminReportSale {
  AdminReportSale({
    required this.listingId,
    required this.listingTitle,
    required this.sellerName,
    required this.buyerName,
    required this.amount,
    required this.soldAt,
  });

  final int listingId;
  final String listingTitle;
  final String sellerName;
  final String buyerName;
  final num amount;
  final DateTime soldAt;

  factory AdminReportSale.fromJson(Map<String, dynamic> json) {
    return AdminReportSale(
      listingId: _asInt(json['listingId'] ?? json['ListingId']),
      listingTitle: _asString(json['listingTitle'] ?? json['ListingTitle']),
      sellerName: _asString(json['sellerName'] ?? json['SellerName']),
      buyerName: _asString(json['buyerName'] ?? json['BuyerName']),
      amount: _asNum(json['amount'] ?? json['Amount']),
      soldAt: DateTime.tryParse(_asString(json['soldAt'] ?? json['SoldAt'])) ??
          DateTime.now(),
    );
  }
}

class AdminReportSellerPerformance {
  AdminReportSellerPerformance({
    required this.sellerId,
    required this.sellerName,
    required this.listingCount,
    required this.offerCount,
    required this.acceptedOfferCount,
    required this.commentCount,
    required this.ratingCount,
    required this.salesCount,
  });

  final int sellerId;
  final String sellerName;
  final int listingCount;
  final int offerCount;
  final int acceptedOfferCount;
  final int commentCount;
  final int ratingCount;
  final int salesCount;

  factory AdminReportSellerPerformance.fromJson(Map<String, dynamic> json) {
    return AdminReportSellerPerformance(
      sellerId: _asInt(json['sellerId'] ?? json['SellerId']),
      sellerName: _asString(json['sellerName'] ?? json['SellerName']),
      listingCount: _asInt(json['listingCount'] ?? json['ListingCount']),
      offerCount: _asInt(json['offerCount'] ?? json['OfferCount']),
      acceptedOfferCount:
          _asInt(json['acceptedOfferCount'] ?? json['AcceptedOfferCount']),
      commentCount: _asInt(json['commentCount'] ?? json['CommentCount']),
      ratingCount: _asInt(json['ratingCount'] ?? json['RatingCount']),
      salesCount: _asInt(json['salesCount'] ?? json['SalesCount']),
    );
  }
}

int _asInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
num _asNum(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
int? _nullableInt(dynamic value) =>
    value == null || '$value'.isEmpty ? null : _asInt(value);
bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = '$value'.toLowerCase();
  return normalized == 'true' || normalized == '1';
}

String _asString(dynamic value) => value == null ? '' : '$value';
