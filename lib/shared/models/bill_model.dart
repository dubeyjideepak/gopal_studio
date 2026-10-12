import 'package:equatable/equatable.dart';

enum BillStatus { pending, partial, paid, cancelled }
enum PaymentType { cash, upi, both }

class BillItem extends Equatable {
  final String id;
  final String particulars;
  final String? size;
  final double quantity;
  final double rate;
  final double amount;

  const BillItem({
    required this.id,
    required this.particulars,
    this.size,
    required this.quantity,
    required this.rate,
    required this.amount,
  });

  BillItem copyWith({
    String? id,
    String? particulars,
    String? size,
    double? quantity,
    double? rate,
    double? amount,
  }) {
    return BillItem(
      id: id ?? this.id,
      particulars: particulars ?? this.particulars,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'particulars': particulars,
    'size': size,
    'quantity': quantity,
    'rate': rate,
    'amount': amount,
  };

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
    id: json['id'] as String,
    particulars: json['particulars'] as String,
    size: json['size'] as String?,
    quantity: (json['quantity'] as num).toDouble(),
    rate: (json['rate'] as num).toDouble(),
    amount: (json['amount'] as num).toDouble(),
  );

  @override
  List<Object?> get props => [id, particulars, size, quantity, rate, amount];
}

class PaymentEntry extends Equatable {
  final String id;
  final double amount;
  final PaymentType type;
  final DateTime date;
  final String? note;
  final String? upiRef;

  const PaymentEntry({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    this.note,
    this.upiRef,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type.name,
    'date': date.toIso8601String(),
    'note': note,
    'upiRef': upiRef,
  };

  factory PaymentEntry.fromJson(Map<String, dynamic> json) => PaymentEntry(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    type: PaymentType.values.firstWhere((e) => e.name == json['type']),
    date: DateTime.parse(json['date'] as String),
    note: json['note'] as String?,
    upiRef: json['upiRef'] as String?,
  );

  @override
  List<Object?> get props => [id, amount, type, date];
}

class Bill extends Equatable {
  final String id;
  final int billNumber;
  final String customerId;
  final String customerName;
  final String? customerMobile;
  final DateTime createdAt;
  final DateTime? deliveryDate;
  final List<BillItem> items;
  final double totalAmount;
  final double advanceAmount;
  final double balanceAmount;
  final double paidAmount;
  final BillStatus status;
  final List<PaymentEntry> paymentHistory;
  final String? notes;
  final bool isSyncedToCloud;

  const Bill({
    required this.id,
    required this.billNumber,
    required this.customerId,
    required this.customerName,
    this.customerMobile,
    required this.createdAt,
    this.deliveryDate,
    required this.items,
    required this.totalAmount,
    this.advanceAmount = 0,
    required this.balanceAmount,
    this.paidAmount = 0,
    required this.status,
    this.paymentHistory = const [],
    this.notes,
    this.isSyncedToCloud = false,
  });

  double get remainingBalance => totalAmount - paidAmount;
  bool get isFullyPaid => remainingBalance <= 0;
  bool get hasAdvance => advanceAmount > 0;

  Bill copyWith({
    String? id,
    int? billNumber,
    String? customerId,
    String? customerName,
    String? customerMobile,
    DateTime? createdAt,
    DateTime? deliveryDate,
    List<BillItem>? items,
    double? totalAmount,
    double? advanceAmount,
    double? balanceAmount,
    double? paidAmount,
    BillStatus? status,
    List<PaymentEntry>? paymentHistory,
    String? notes,
    bool? isSyncedToCloud,
  }) {
    return Bill(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      createdAt: createdAt ?? this.createdAt,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      balanceAmount: balanceAmount ?? this.balanceAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      notes: notes ?? this.notes,
      isSyncedToCloud: isSyncedToCloud ?? this.isSyncedToCloud,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'billNumber': billNumber,
    'customerId': customerId,
    'customerName': customerName,
    'customerMobile': customerMobile,
    'createdAt': createdAt.toIso8601String(),
    'deliveryDate': deliveryDate?.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
    'totalAmount': totalAmount,
    'advanceAmount': advanceAmount,
    'balanceAmount': balanceAmount,
    'paidAmount': paidAmount,
    'status': status.name,
    'paymentHistory': paymentHistory.map((e) => e.toJson()).toList(),
    'notes': notes,
    'isSyncedToCloud': isSyncedToCloud,
  };

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json['id'] as String,
    billNumber: json['billNumber'] as int,
    customerId: json['customerId'] as String,
    customerName: json['customerName'] as String,
    customerMobile: json['customerMobile'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    deliveryDate: json['deliveryDate'] != null
        ? DateTime.parse(json['deliveryDate'] as String)
        : null,
    items: (json['items'] as List)
        .map((e) => BillItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    advanceAmount: (json['advanceAmount'] as num?)?.toDouble() ?? 0,
    balanceAmount: (json['balanceAmount'] as num).toDouble(),
    paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
    status: BillStatus.values.firstWhere((e) => e.name == json['status']),
    paymentHistory: (json['paymentHistory'] as List? ?? [])
        .map((e) => PaymentEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    notes: json['notes'] as String?,
    isSyncedToCloud: json['isSyncedToCloud'] as bool? ?? false,
  );

  @override
  List<Object?> get props => [id, billNumber, status];
}
