import 'package:equatable/equatable.dart';

class BusinessProfile extends Equatable {
  final String id;
  final String businessName;
  final String ownerName;
  final String? tagline;
  final String? address;
  final String phone1;
  final String? phone2;
  final String? email;
  final String? upiId;
  final String? upiQrImagePath;
  final String? logoPath;
  final String? gstin;
  final String? youtubeChannel;
  final String? instagramHandle;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessProfile({
    required this.id,
    required this.businessName,
    required this.ownerName,
    this.tagline,
    this.address,
    required this.phone1,
    this.phone2,
    this.email,
    this.upiId,
    this.upiQrImagePath,
    this.logoPath,
    this.gstin,
    this.youtubeChannel,
    this.instagramHandle,
    required this.createdAt,
    required this.updatedAt,
  });

  BusinessProfile copyWith({
    String? id,
    String? businessName,
    String? ownerName,
    String? tagline,
    String? address,
    String? phone1,
    String? phone2,
    String? email,
    String? upiId,
    String? upiQrImagePath,
    String? logoPath,
    String? gstin,
    String? youtubeChannel,
    String? instagramHandle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      tagline: tagline ?? this.tagline,
      address: address ?? this.address,
      phone1: phone1 ?? this.phone1,
      phone2: phone2 ?? this.phone2,
      email: email ?? this.email,
      upiId: upiId ?? this.upiId,
      upiQrImagePath: upiQrImagePath ?? this.upiQrImagePath,
      logoPath: logoPath ?? this.logoPath,
      gstin: gstin ?? this.gstin,
      youtubeChannel: youtubeChannel ?? this.youtubeChannel,
      instagramHandle: instagramHandle ?? this.instagramHandle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'businessName': businessName,
    'ownerName': ownerName,
    'tagline': tagline,
    'address': address,
    'phone1': phone1,
    'phone2': phone2,
    'email': email,
    'upiId': upiId,
    'upiQrImagePath': upiQrImagePath,
    'logoPath': logoPath,
    'gstin': gstin,
    'youtubeChannel': youtubeChannel,
    'instagramHandle': instagramHandle,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory BusinessProfile.fromJson(Map<String, dynamic> json) => BusinessProfile(
    id: json['id'] as String,
    businessName: json['businessName'] as String,
    ownerName: json['ownerName'] as String,
    tagline: json['tagline'] as String?,
    address: json['address'] as String?,
    phone1: json['phone1'] as String,
    phone2: json['phone2'] as String?,
    email: json['email'] as String?,
    upiId: json['upiId'] as String?,
    upiQrImagePath: json['upiQrImagePath'] as String?,
    logoPath: json['logoPath'] as String?,
    gstin: json['gstin'] as String?,
    youtubeChannel: json['youtubeChannel'] as String?,
    instagramHandle: json['instagramHandle'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  static BusinessProfile get defaultProfile => BusinessProfile(
    id: 'default',
    businessName: 'Gopal Photography Studio',
    ownerName: 'Gopal',
    tagline: 'Capturing Memory, Creating Story',
    address: 'Jalesarganj Road, Lalganj Ajhara, Pratapgarh',
    phone1: '9935006921',
    phone2: '8115989543',
    youtubeChannel: '@GopalPhotographyStudio',
    instagramHandle: '@gopal_photography_studio',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  List<Object?> get props => [id, businessName, phone1, youtubeChannel, instagramHandle];
}
