import 'listing.dart';

class ListingDraft {
  ListingDraft({
    this.id,
    this.ownerUserId,
    this.title = '',
    this.description = '',
    this.province = '',
    this.district = '',
    this.propertyType = 'Daire',
    this.listingPurpose = 'Kiralık',
    this.roomCount = '2+1',
    this.grossSquareMeters = 100,
    this.netSquareMeters = 80,
    this.buildingAge = 5,
    this.floor = 1,
    this.totalFloors = 5,
    this.bathroomCount = 1,
    this.heatingType = 'Kombi Doğalgaz',
    this.furnished = false,
    this.balcony = false,
    this.elevator = false,
    this.parking = false,
    this.inSite = false,
    this.hasPool = false,
    this.monthlyPrice = 25000,
    this.deposit = 0,
    this.dues = 0,
    this.imageUrl = '',
    this.imageUrls = const [],
    this.additionalImageUrls = '',
    this.isAdminRecommended = false,
  });

  final int? id;
  final int? ownerUserId;
  final String title;
  final String description;
  final String province;
  final String district;
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
  final List<String> imageUrls;
  final String additionalImageUrls;
  final bool isAdminRecommended;

  factory ListingDraft.fromListing(Listing listing,
      {List<String> imageUrls = const []}) {
    return ListingDraft(
      id: listing.id,
      ownerUserId: listing.ownerUserId,
      title: listing.title,
      description: listing.description,
      province: listing.province,
      district: listing.district,
      propertyType: listing.propertyType,
      listingPurpose: listing.listingPurpose,
      roomCount: listing.roomCount,
      grossSquareMeters: listing.grossSquareMeters,
      netSquareMeters: listing.netSquareMeters,
      buildingAge: listing.buildingAge,
      floor: listing.floor,
      totalFloors: listing.totalFloors,
      bathroomCount: listing.bathroomCount,
      heatingType: listing.heatingType,
      furnished: listing.furnished,
      balcony: listing.balcony,
      elevator: listing.elevator,
      parking: listing.parking,
      inSite: listing.inSite,
      hasPool: listing.hasPool,
      monthlyPrice: listing.monthlyPrice,
      deposit: listing.deposit,
      dues: listing.dues,
      imageUrl: listing.imageUrl,
      imageUrls: imageUrls,
      isAdminRecommended: listing.isAdminRecommended,
    );
  }

  Map<String, dynamic> toJson() {
    final images = <String>[];
    if (imageUrl.trim().isNotEmpty) {
      images.add(imageUrl.trim());
    }
    for (final value in imageUrls) {
      final normalized = value.trim();
      if (normalized.isNotEmpty && !images.contains(normalized)) {
        images.add(normalized);
      }
    }
    return {
      'ownerUserId': ownerUserId,
      'title': title.trim(),
      'description': description.trim(),
      'province': province.trim(),
      'district': district.trim(),
      'propertyType': propertyType.trim(),
      'listingPurpose': listingPurpose.trim(),
      'roomCount': roomCount.trim(),
      'grossSquareMeters': grossSquareMeters,
      'netSquareMeters': netSquareMeters,
      'buildingAge': buildingAge,
      'floor': floor,
      'totalFloors': totalFloors,
      'bathroomCount': bathroomCount,
      'heatingType': heatingType.trim(),
      'furnished': furnished,
      'balcony': balcony,
      'elevator': elevator,
      'parking': parking,
      'inSite': inSite,
      'hasPool': hasPool,
      'monthlyPrice': monthlyPrice,
      'deposit': deposit,
      'dues': dues,
      'imageUrl': images.isNotEmpty ? images.first : '',
      'imageUrls': images,
      'additionalImageUrls': additionalImageUrls,
      'isAdminRecommended': isAdminRecommended,
    };
  }
}
