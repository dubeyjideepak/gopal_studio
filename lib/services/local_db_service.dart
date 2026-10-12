import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../shared/models/bill_model.dart';
import '../shared/models/customer_model.dart';
import '../shared/models/business_profile_model.dart';
import '../core/constants/app_constants.dart';

class LocalDbService {
  static LocalDbService? _instance;
  static LocalDbService get instance => _instance ??= LocalDbService._();
  LocalDbService._();

  late SharedPreferences _prefs;
  bool _initialized = false;
  final _uuid = const Uuid();

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ─── Business Profile ────────────────────────────────────────────────────

  Future<BusinessProfile> getBusinessProfile() async {
    await init();
    final json = _prefs.getString(AppConstants.keyBusinessProfile);
    if (json == null) return BusinessProfile.defaultProfile;
    return BusinessProfile.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    await init();
    await _prefs.setString(
      AppConstants.keyBusinessProfile,
      jsonEncode(profile.toJson()),
    );
  }

  // ─── Bill Number ─────────────────────────────────────────────────────────

  Future<int> getNextBillNumber() async {
    await init();
    final last = _prefs.getInt(AppConstants.keyLastBillNumber) ?? 0;
    final next = last + 1;
    await _prefs.setInt(AppConstants.keyLastBillNumber, next);
    return next;
  }

  Future<int> getCurrentBillNumber() async {
    await init();
    return _prefs.getInt(AppConstants.keyLastBillNumber) ?? 0;
  }

  // ─── Bills ───────────────────────────────────────────────────────────────

  Future<List<Bill>> getAllBills() async {
    await init();
    final json = _prefs.getString('all_bills');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Bill?> getBillById(String id) async {
    final bills = await getAllBills();
    try {
      return bills.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBill(Bill bill) async {
    await init();
    final bills = await getAllBills();
    final idx = bills.indexWhere((b) => b.id == bill.id);
    if (idx >= 0) {
      bills[idx] = bill;
    } else {
      bills.add(bill);
    }
    await _prefs.setString(
      'all_bills',
      jsonEncode(bills.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> deleteBill(String id) async {
    final bills = await getAllBills();
    bills.removeWhere((b) => b.id == id);
    await _prefs.setString(
      'all_bills',
      jsonEncode(bills.map((b) => b.toJson()).toList()),
    );
  }

  Future<List<Bill>> getBillsByCustomer(String customerId) async {
    final bills = await getAllBills();
    return bills.where((b) => b.customerId == customerId).toList();
  }

  Future<List<Bill>> getPendingBills() async {
    final bills = await getAllBills();
    return bills
        .where((b) => b.status == BillStatus.pending || b.status == BillStatus.partial)
        .toList();
  }

  // ─── Customers ────────────────────────────────────────────────────────────

  Future<List<Customer>> getAllCustomers() async {
    await init();
    final json = _prefs.getString('all_customers');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<Customer?> getCustomerById(String id) async {
    final customers = await getAllCustomers();
    try {
      return customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCustomer(Customer customer) async {
    await init();
    final customers = await getAllCustomers();
    final idx = customers.indexWhere((c) => c.id == customer.id);
    if (idx >= 0) {
      customers[idx] = customer;
    } else {
      customers.add(customer);
    }
    await _prefs.setString(
      'all_customers',
      jsonEncode(customers.map((c) => c.toJson()).toList()),
    );
  }

  Future<void> deleteCustomer(String id) async {
    final customers = await getAllCustomers();
    customers.removeWhere((c) => c.id == id);
    await _prefs.setString(
      'all_customers',
      jsonEncode(customers.map((c) => c.toJson()).toList()),
    );
  }

  Future<Customer> createCustomer({
    required String name,
    String? mobile,
    String? address,
    String? email,
  }) async {
    final customer = Customer(
      id: _uuid.v4(),
      name: name,
      mobile: mobile,
      address: address,
      email: email,
      createdAt: DateTime.now(),
    );
    await saveCustomer(customer);
    return customer;
  }

  // ─── Recalculate customer balance ─────────────────────────────────────────

  Future<void> recalculateCustomerBalance(String customerId) async {
    final bills = await getBillsByCustomer(customerId);
    final customer = await getCustomerById(customerId);
    if (customer == null) return;

    double totalDue = 0;
    double totalAdvance = 0;
    DateTime? lastBillDate;

    for (final bill in bills) {
      if (bill.status != BillStatus.cancelled) {
        totalDue += bill.remainingBalance;
        totalAdvance += bill.advanceAmount;
        if (lastBillDate == null || bill.createdAt.isAfter(lastBillDate)) {
          lastBillDate = bill.createdAt;
        }
      }
    }

    final updated = customer.copyWith(
      totalDue: totalDue < 0 ? 0 : totalDue,
      totalAdvance: totalAdvance,
      lastBillDate: lastBillDate,
    );
    await saveCustomer(updated);
  }

  // ─── First Run ────────────────────────────────────────────────────────────

  Future<bool> isFirstRun() async {
    await init();
    return _prefs.getBool(AppConstants.keyIsFirstRun) ?? true;
  }

  Future<void> setFirstRunDone() async {
    await init();
    await _prefs.setBool(AppConstants.keyIsFirstRun, false);
  }

  String generateId() => _uuid.v4();
}
