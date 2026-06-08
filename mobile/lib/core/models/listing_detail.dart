import 'listing.dart';
import '../utils/image_url.dart';
import 'user.dart';
import 'offer.dart';

class ListingDetailResponse {
  ListingDetailResponse({
    required this.listing,
    required this.galleryImages,
    required this.listingRatingAverage,
    required this.listingRatingCount,
    required this.sellerRatingAverage,
    required this.sellerRatingCount,
    required this.comments,
    required this.ratings,
    required this.offers,
    required this.canEdit,
    required this.isAdmin,
    required this.isLoggedIn,
    required this.canRent,
    required this.canOffer,
    required this.canComment,
    required this.canRate,
    required this.myListingScore,
    required this.mySellerScore,
    required this.myRatingComment,
    required this.owner,
  });

  final Listing listing;
  final List<String> galleryImages;
  final num listingRatingAverage;
  final int listingRatingCount;
  final num sellerRatingAverage;
  final int sellerRatingCount;
  final List<ListingCommentItem> comments;
  final List<ListingRatingItem> ratings;
  final List<Offer> offers;
  final bool canEdit;
  final bool isAdmin;
  final bool isLoggedIn;
  final bool canRent;
  final bool canOffer;
  final bool canComment;
  final bool canRate;
  final int? myListingScore;
  final int? mySellerScore;
  final String myRatingComment;
  final User? owner;

  factory ListingDetailResponse.fromJson(Map<String, dynamic> json,
      {String baseUrl = ''}) {
    final rawListing = Map<String, dynamic>.from(
        json['listing'] ?? json['Listing'] ?? const {});
    final rawGallery =
        (json['galleryImages'] ?? json['GalleryImages'] ?? const []) as List;
    final rawRatings = (json['ratings'] ?? json['Ratings'] ?? const []) as List;
    final rawOffers = (json['offers'] ?? json['Offers'] ?? const []) as List;
    final rawComments =
        (json['comments'] ?? json['Comments'] ?? const []) as List;

    return ListingDetailResponse(
      listing: Listing.fromJson(rawListing, baseUrl: baseUrl),
      galleryImages: rawGallery
          .map((e) => resolveImageUrl(baseUrl, e.toString()))
          .toList(),
      listingRatingAverage:
          _asNum(json['listingRatingAverage'] ?? json['ListingRatingAverage']),
      listingRatingCount:
          _asInt(json['listingRatingCount'] ?? json['ListingRatingCount']),
      sellerRatingAverage:
          _asNum(json['sellerRatingAverage'] ?? json['SellerRatingAverage']),
      sellerRatingCount:
          _asInt(json['sellerRatingCount'] ?? json['SellerRatingCount']),
      comments: rawComments
          .map((e) =>
              ListingCommentItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      ratings: rawRatings
          .map((e) =>
              ListingRatingItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      offers: rawOffers
          .map((e) => Offer.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      canEdit: _asBool(json['canEdit'] ?? json['CanEdit']),
      isAdmin: _asBool(json['isAdmin'] ?? json['IsAdmin']),
      isLoggedIn: _asBool(json['isLoggedIn'] ?? json['IsLoggedIn']),
      canRent: _asBool(json['canRent'] ?? json['CanRent']),
      canOffer: _asBool(json['canOffer'] ?? json['CanOffer']),
      canComment: _asBool(json['canComment'] ?? json['CanComment']),
      canRate: _asBool(json['canRate'] ?? json['CanRate']),
      myListingScore:
          _nullableInt(json['myListingScore'] ?? json['MyListingScore']),
      mySellerScore:
          _nullableInt(json['mySellerScore'] ?? json['MySellerScore']),
      myRatingComment:
          _asString(json['myRatingComment'] ?? json['MyRatingComment']),
      owner: json['owner'] == null && json['Owner'] == null
          ? null
          : User.fromJson(
              Map<String, dynamic>.from(json['owner'] ?? json['Owner'])),
    );
  }
}

class ListingCommentItem {
  ListingCommentItem({
    required this.id,
    required this.listingId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final int listingId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  factory ListingCommentItem.fromJson(Map<String, dynamic> json) {
    return ListingCommentItem(
      id: _asInt(json['id'] ?? json['Id']),
      listingId: _asInt(json['listingId'] ?? json['ListingId']),
      authorName: _asString(json['authorName'] ?? json['AuthorName']),
      content: _asString(json['content'] ?? json['Content']),
      createdAt: DateTime.tryParse(
              _asString(json['createdAt'] ?? json['CreatedAt'])) ??
          DateTime.now(),
    );
  }
}

class ListingRatingItem {
  ListingRatingItem({
    required this.renterName,
    required this.listingScore,
    required this.sellerScore,
    required this.comment,
    required this.createdAt,
  });

  final String renterName;
  final int listingScore;
  final int sellerScore;
  final String comment;
  final DateTime createdAt;

  factory ListingRatingItem.fromJson(Map<String, dynamic> json) {
    return ListingRatingItem(
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
