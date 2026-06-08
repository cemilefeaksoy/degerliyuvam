class Offer {
  Offer({
    required this.offerId,
    required this.listingId,
    required this.listingTitle,
    required this.fromUserName,
    required this.amount,
    required this.note,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  final int offerId;
  final int listingId;
  final String listingTitle;
  final String fromUserName;
  final num amount;
  final String note;
  final String type;
  final String status;
  final DateTime createdAt;

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      offerId: _asInt(
          json['offerId'] ?? json['OfferId'] ?? json['id'] ?? json['Id']),
      listingId: _asInt(json['listingId'] ?? json['ListingId']),
      listingTitle: _asString(json['listingTitle'] ?? json['ListingTitle']),
      fromUserName: _asString(json['fromUserName'] ?? json['FromUserName']),
      amount: _asNum(json['amount'] ?? json['Amount']),
      note: _asString(json['note'] ?? json['Note']),
      type: _typeLabel(json['type'] ?? json['Type']),
      status: _statusLabel(json['status'] ?? json['Status']),
      createdAt: DateTime.tryParse(
              _asString(json['createdAt'] ?? json['CreatedAt'])) ??
          DateTime.now(),
    );
  }
}

int _asInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
num _asNum(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
String _asString(dynamic value) => value == null ? '' : '$value';
String _typeLabel(dynamic value) {
  if (value is num) {
    return value == 1 ? 'Kiralama Talebi' : 'Fiyat Teklifi';
  }
  final raw = '$value';
  if (raw == '0') return 'Fiyat Teklifi';
  if (raw == '1') return 'Kiralama Talebi';
  return raw;
}

String _statusLabel(dynamic value) {
  if (value is num) {
    return switch (value) {
      1 => 'Kabul Edildi',
      2 => 'Reddedildi',
      _ => 'Beklemede',
    };
  }
  final raw = '$value';
  if (raw == '0') return 'Beklemede';
  if (raw == '1') return 'Kabul Edildi';
  if (raw == '2') return 'Reddedildi';
  return raw;
}
