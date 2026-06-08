class User {
  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.bio = '',
    this.profileImageUrl = '',
    this.isSellerApproved = false,
    this.isSuperAdmin = false,
  });

  final int id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String role;
  final String bio;
  final String profileImageUrl;
  final bool isSellerApproved;
  final bool isSuperAdmin;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _asInt(json['id'] ?? json['Id']),
      fullName: _asString(json['fullName'] ?? json['FullName']),
      email: _asString(json['email'] ?? json['Email']),
      phoneNumber: _asString(json['phoneNumber'] ?? json['PhoneNumber']),
      role: _roleLabel(json['role'] ?? json['Role']),
      bio: _asString(json['bio'] ?? json['Bio']),
      profileImageUrl:
          _asString(json['profileImageUrl'] ?? json['ProfileImageUrl']),
      isSellerApproved:
          _asBool(json['isSellerApproved'] ?? json['IsSellerApproved']),
      isSuperAdmin: _asBool(json['isSuperAdmin'] ?? json['IsSuperAdmin']),
    );
  }
}

int _asInt(dynamic value) => value is int ? value : int.tryParse('$value') ?? 0;
String _asString(dynamic value) => value == null ? '' : '$value';
bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = '$value'.toLowerCase();
  return normalized == 'true' || normalized == '1';
}

String _roleLabel(dynamic value) {
  if (value is num) {
    return value == 1 ? 'Admin' : 'Müşteri';
  }
  final raw = '$value';
  if (raw == '0') return 'Müşteri';
  if (raw == '1') return 'Admin';
  return raw;
}
