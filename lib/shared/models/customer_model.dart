import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String? mobile;
  final String? address;
  final String? email;
  final double totalDue;
  final double totalAdvance;
  final DateTime createdAt;
  final DateTime? lastBillDate;

  const Customer({
    required this.id,
    required this.name,
    this.mobile,
    this.address,
    this.email,
    this.totalDue = 0,
    this.totalAdvance = 0,
    required this.createdAt,
    this.lastBillDate,
  });

  double get netBalance => totalDue - totalAdvance;
  bool get hasOutstanding => netBalance > 0;

  Customer copyWith({
    String? id,
    String? name,
    String? mobile,
    String? address,
    String? email,
    double? totalDue,
    double? totalAdvance,
    DateTime? createdAt,
    DateTime? lastBillDate,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      email: email ?? this.email,
      totalDue: totalDue ?? this.totalDue,
      totalAdvance: totalAdvance ?? this.totalAdvance,
      createdAt: createdAt ?? this.createdAt,
      lastBillDate: lastBillDate ?? this.lastBillDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mobile': mobile,
    'address': address,
    'email': email,
    'totalDue': totalDue,
    'totalAdvance': totalAdvance,
    'createdAt': createdAt.toIso8601String(),
    'lastBillDate': lastBillDate?.toIso8601String(),
  };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    name: json['name'] as String,
    mobile: json['mobile'] as String?,
    address: json['address'] as String?,
    email: json['email'] as String?,
    totalDue: (json['totalDue'] as num?)?.toDouble() ?? 0,
    totalAdvance: (json['totalAdvance'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastBillDate: json['lastBillDate'] != null
        ? DateTime.parse(json['lastBillDate'] as String)
        : null,
  );

  @override
  List<Object?> get props => [id, name, mobile];
}
