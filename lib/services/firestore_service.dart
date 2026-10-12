import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/bill_model.dart';
import '../shared/models/customer_model.dart';
import '../shared/models/business_profile_model.dart';
import '../core/constants/app_constants.dart';

class FirestoreService {
  static FirestoreService? _instance;
  static FirestoreService get instance => _instance ??= FirestoreService._();
  FirestoreService._();

  FirebaseFirestore? _firestore;

  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  // ─── Sync Bill to Firestore ────────────────────────────────────────────────
  Future<void> syncBill(Bill bill) async {
    try {
      await firestore
          .collection(AppConstants.collectionBills)
          .doc(bill.id)
          .set(bill.toJson(), SetOptions(merge: true));
    } catch (_) {
      // Local copy remains safe; will sync on next online reconnect
    }
  }

  // ─── Stream Bills Realtime from Firestore ──────────────────────────────────
  Stream<List<Bill>> streamBills() {
    try {
      return firestore
          .collection(AppConstants.collectionBills)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Bill.fromJson(doc.data()))
              .toList());
    } catch (_) {
      return const Stream.empty();
    }
  }

  // ─── Sync Customer to Firestore ───────────────────────────────────────────
  Future<void> syncCustomer(Customer customer) async {
    try {
      await firestore
          .collection(AppConstants.collectionCustomers)
          .doc(customer.id)
          .set(customer.toJson(), SetOptions(merge: true));
    } catch (_) {}
  }

  // ─── Sync Studio Profile ──────────────────────────────────────────────────
  Future<void> syncBusinessProfile(BusinessProfile profile) async {
    try {
      await firestore
          .collection(AppConstants.collectionBusiness)
          .doc(profile.id)
          .set(profile.toJson(), SetOptions(merge: true));
    } catch (_) {}
  }
}
