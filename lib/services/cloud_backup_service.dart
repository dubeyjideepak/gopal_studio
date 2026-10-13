import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../shared/models/bill_model.dart';
import '../shared/models/customer_model.dart';
import '../shared/models/business_profile_model.dart';
import 'app_activation_service.dart';
import 'local_db_service.dart';

class BackupSyncStatus {
  final bool isSyncing;
  final bool isOnline;
  final DateTime? lastBackupAt;
  final int billsCount;
  final int customersCount;
  final int pendingCount;
  final String? lastError;
  final String? lastSuccessMessage;

  const BackupSyncStatus({
    this.isSyncing = false,
    this.isOnline = true,
    this.lastBackupAt,
    this.billsCount = 0,
    this.customersCount = 0,
    this.pendingCount = 0,
    this.lastError,
    this.lastSuccessMessage,
  });

  BackupSyncStatus copyWith({
    bool? isSyncing,
    bool? isOnline,
    DateTime? lastBackupAt,
    int? billsCount,
    int? customersCount,
    int? pendingCount,
    String? lastError,
    String? lastSuccessMessage,
  }) {
    return BackupSyncStatus(
      isSyncing: isSyncing ?? this.isSyncing,
      isOnline: isOnline ?? this.isOnline,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      billsCount: billsCount ?? this.billsCount,
      customersCount: customersCount ?? this.customersCount,
      pendingCount: pendingCount ?? this.pendingCount,
      lastError: lastError,
      lastSuccessMessage: lastSuccessMessage,
    );
  }
}

final cloudBackupStateProvider =
    StateNotifierProvider<CloudBackupNotifier, BackupSyncStatus>((ref) {
  return CloudBackupNotifier();
});

class CloudBackupNotifier extends StateNotifier<BackupSyncStatus> {
  CloudBackupNotifier() : super(const BackupSyncStatus()) {
    CloudBackupService.instance.registerNotifier(this);
    loadStatus();
  }

  void updateState(BackupSyncStatus status) {
    state = status;
  }

  void syncStateUpdate({
    bool? isSyncing,
    bool? isOnline,
    DateTime? lastBackupAt,
    int? billsCount,
    int? customersCount,
    int? pendingCount,
    String? lastError,
    String? lastSuccessMessage,
  }) {
    state = state.copyWith(
      isSyncing: isSyncing,
      isOnline: isOnline,
      lastBackupAt: lastBackupAt,
      billsCount: billsCount,
      customersCount: customersCount,
      pendingCount: pendingCount,
      lastError: lastError,
      lastSuccessMessage: lastSuccessMessage,
    );
  }

  Future<void> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final epoch = prefs.getInt('cloud_backup_last_epoch');
    final bills = await LocalDbService.instance.getAllBills();
    final customers = await LocalDbService.instance.getAllCustomers();
    final pendingCount = CloudBackupService.instance.getPendingCount();

    state = state.copyWith(
      lastBackupAt: epoch != null ? DateTime.fromMillisecondsSinceEpoch(epoch) : null,
      billsCount: bills.length,
      customersCount: customers.length,
      pendingCount: pendingCount,
    );
  }

  Future<bool> restoreAll() async {
    state = state.copyWith(isSyncing: true, lastError: null);
    try {
      final result = await CloudBackupService.instance.restoreAllFromCloud();
      final bills = await LocalDbService.instance.getAllBills();
      final customers = await LocalDbService.instance.getAllCustomers();
      state = state.copyWith(
        isSyncing: false,
        billsCount: bills.length,
        customersCount: customers.length,
        pendingCount: 0,
        lastSuccessMessage:
            'Restored ${result.billsRestored} bills and ${result.customersRestored} clients from cloud!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSyncing: false, lastError: e.toString());
      return false;
    }
  }
}

class RestoreResult {
  final int billsRestored;
  final int customersRestored;
  final bool profileRestored;

  RestoreResult({
    required this.billsRestored,
    required this.customersRestored,
    required this.profileRestored,
  });
}

class CloudBackupService {
  static CloudBackupService? _instance;
  static CloudBackupService get instance => _instance ??= CloudBackupService._();
  CloudBackupService._();

  static const String _keyLastBackup = 'cloud_backup_last_epoch';
  static const String _keyPendingBills = 'cloud_backup_pending_bills';
  static const String _keyPendingCustomers = 'cloud_backup_pending_customers';
  static const String _keyPendingProfile = 'cloud_backup_pending_profile';

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicSyncTimer;
  CloudBackupNotifier? _notifier;

  bool _isSyncing = false;
  bool _isOnline = true;
  final Set<String> _pendingBillIds = {};
  final Set<String> _pendingCustomerIds = {};
  bool _isProfilePending = false;
  bool _listenerStarted = false;

  void registerNotifier(CloudBackupNotifier notifier) {
    _notifier = notifier;
  }

  int getPendingCount() => _pendingBillIds.length + _pendingCustomerIds.length + (_isProfilePending ? 1 : 0);

  void _notifyState() {
    _notifier?.syncStateUpdate(
      isSyncing: _isSyncing,
      isOnline: _isOnline,
      pendingCount: getPendingCount(),
    );
  }

  // ─── Auto-Sync Listener ───────────────────────────────────────────────────

  /// Initialize real-time auto-sync: monitors connectivity and syncs when back online
  Future<void> startAutoSyncListener() async {
    if (_listenerStarted) return;
    _listenerStarted = true;

    // Load persisted offline queue
    await _loadPendingQueue();

    // Check current connectivity
    final connectivity = Connectivity();
    final initialResults = await connectivity.checkConnectivity();
    _isOnline = _hasConnection(initialResults);
    _notifyState();

    if (_isOnline) {
      // Auto-sync immediately on launch
      triggerAutoSync().ignore();
    }

    // Listen to real-time network changes: trigger auto-sync the moment internet returns
    _connectivitySub = connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = _hasConnection(results);
      _notifyState();

      if (wasOffline && _isOnline) {
        debugPrint('[CloudAutoSync] Internet restored! Triggering automatic background sync...');
        triggerAutoSync().ignore();
      }
    });

    // Periodic safety sync (every 15 minutes)
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (_isOnline && !_isSyncing) {
        triggerAutoSync().ignore();
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return !results.contains(ConnectivityResult.none);
  }

  Future<void> _loadPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    _pendingBillIds.addAll(prefs.getStringList(_keyPendingBills) ?? []);
    _pendingCustomerIds.addAll(prefs.getStringList(_keyPendingCustomers) ?? []);
    _isProfilePending = prefs.getBool(_keyPendingProfile) ?? false;
  }

  Future<void> _savePendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyPendingBills, _pendingBillIds.toList());
    await prefs.setStringList(_keyPendingCustomers, _pendingCustomerIds.toList());
    await prefs.setBool(_keyPendingProfile, _isProfilePending);
    _notifyState();
  }

  Future<DocumentReference<Map<String, dynamic>>> _getClientDocRef() async {
    await AppActivationService.instance.ensureFirebase();
    final clientId = await AppActivationService.instance.getClientId();
    return FirebaseFirestore.instance
        .collection('apps')
        .doc(AppActivationService.appId)
        .collection('clients')
        .doc(clientId);
  }

  // ─── Realtime Automatic Sync on Mutation ──────────────────────────────────

  /// Automatically called whenever a bill is created, edited, or settled
  Future<void> backupBill(Bill bill) async {
    try {
      final clientRef = await _getClientDocRef();
      final data = bill.toJson();
      data['app_id'] = AppActivationService.appId;
      data['client_id'] = clientRef.id;
      data['updated_at'] = FieldValue.serverTimestamp();

      await clientRef
          .collection('bills')
          .doc(bill.id)
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));

      _pendingBillIds.remove(bill.id);
      await _savePendingQueue();
      _isOnline = true;
    } catch (e) {
      debugPrint('[CloudAutoSync] Bill offline, queued for auto-sync: ${bill.id}');
      _isOnline = false;
      _pendingBillIds.add(bill.id);
      await _savePendingQueue();
    }
  }

  /// Automatically delete bill from cloud when deleted locally
  Future<void> deleteBill(String billId) async {
    _pendingBillIds.remove(billId);
    await _savePendingQueue();
    try {
      final clientRef = await _getClientDocRef();
      await clientRef.collection('bills').doc(billId).delete().timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// Automatically called whenever a customer is created or edited
  Future<void> backupCustomer(Customer customer) async {
    try {
      final clientRef = await _getClientDocRef();
      final data = customer.toJson();
      data['app_id'] = AppActivationService.appId;
      data['client_id'] = clientRef.id;
      data['updated_at'] = FieldValue.serverTimestamp();

      await clientRef
          .collection('customers')
          .doc(customer.id)
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));

      _pendingCustomerIds.remove(customer.id);
      await _savePendingQueue();
      _isOnline = true;
    } catch (e) {
      debugPrint('[CloudAutoSync] Customer offline, queued for auto-sync: ${customer.id}');
      _isOnline = false;
      _pendingCustomerIds.add(customer.id);
      await _savePendingQueue();
    }
  }

  /// Automatically delete customer from cloud when deleted locally
  Future<void> deleteCustomer(String customerId) async {
    _pendingCustomerIds.remove(customerId);
    await _savePendingQueue();
    try {
      final clientRef = await _getClientDocRef();
      await clientRef.collection('customers').doc(customerId).delete().timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  /// Automatically called when business profile is saved in Settings
  Future<void> backupBusinessProfile(BusinessProfile profile) async {
    try {
      final clientRef = await _getClientDocRef();
      final data = profile.toJson();
      data['app_id'] = AppActivationService.appId;
      data['client_id'] = clientRef.id;
      data['updated_at'] = FieldValue.serverTimestamp();

      await clientRef
          .collection('profile')
          .doc('current')
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));

      await clientRef.set({
        'client_name': profile.businessName,
        'owner_name': profile.ownerName,
        'phone': profile.phone1,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));

      _isProfilePending = false;
      await _savePendingQueue();
      _isOnline = true;
    } catch (e) {
      debugPrint('[CloudAutoSync] Profile offline, queued for auto-sync');
      _isOnline = false;
      _isProfilePending = true;
      await _savePendingQueue();
    }
  }

  // ─── Automatic Background Queue Drain & Full Sync ─────────────────────────

  /// Triggered automatically when internet is restored or on launch
  Future<void> triggerAutoSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _notifyState();

    try {
      await AppActivationService.instance.ensureFirebase();
      final clientRef = await _getClientDocRef();
      final now = DateTime.now();

      final bills = await LocalDbService.instance.getAllBills();
      final customers = await LocalDbService.instance.getAllCustomers();
      final profile = await LocalDbService.instance.getBusinessProfile();

      // 1. Sync Profile if pending or full sync
      final profileData = profile.toJson();
      profileData['app_id'] = AppActivationService.appId;
      profileData['client_id'] = clientRef.id;
      profileData['updated_at'] = FieldValue.serverTimestamp();
      await clientRef.collection('profile').doc('current').set(profileData, SetOptions(merge: true));
      _isProfilePending = false;

      // 2. Sync all bills
      final billsCol = clientRef.collection('bills');
      for (final bill in bills) {
        final data = bill.toJson();
        data['app_id'] = AppActivationService.appId;
        data['client_id'] = clientRef.id;
        data['updated_at'] = FieldValue.serverTimestamp();
        await billsCol.doc(bill.id).set(data, SetOptions(merge: true));
      }
      _pendingBillIds.clear();

      // 3. Sync all customers
      final customersCol = clientRef.collection('customers');
      for (final customer in customers) {
        final data = customer.toJson();
        data['app_id'] = AppActivationService.appId;
        data['client_id'] = clientRef.id;
        data['updated_at'] = FieldValue.serverTimestamp();
        await customersCol.doc(customer.id).set(data, SetOptions(merge: true));
      }
      _pendingCustomerIds.clear();

      // 4. Save latest backup snapshot
      await clientRef.collection('backups').doc('latest').set({
        'app_id': AppActivationService.appId,
        'client_id': clientRef.id,
        'backup_timestamp': FieldValue.serverTimestamp(),
        'backup_str': now.toIso8601String(),
        'total_bills': bills.length,
        'total_customers': customers.length,
        'platform': AppActivationService.currentPlatform,
        'app_version': AppConstants.appVersion,
        'sync_type': 'auto_sync',
      }, SetOptions(merge: true));

      // Persist success
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastBackup, now.millisecondsSinceEpoch);
      await _savePendingQueue();

      _isOnline = true;
      _notifier?.syncStateUpdate(
        lastBackupAt: now,
        billsCount: bills.length,
        customersCount: customers.length,
        pendingCount: 0,
        isOnline: true,
        isSyncing: false,
      );
      debugPrint('[CloudAutoSync] Auto-sync completed successfully (${bills.length} bills, ${customers.length} clients)!');
    } catch (e) {
      debugPrint('[CloudAutoSync] Auto-sync failed (network issue): $e');
      _isOnline = false;
    } finally {
      _isSyncing = false;
      _notifyState();
    }
  }

  // ─── Disaster Recovery Restore ─────────────────────────────────────────────

  Future<RestoreResult> restoreAllFromCloud() async {
    await AppActivationService.instance.ensureFirebase();
    final clientRef = await _getClientDocRef();

    int billsRestored = 0;
    int customersRestored = 0;
    bool profileRestored = false;

    // 1. Restore Profile
    final profileDoc = await clientRef.collection('profile').doc('current').get();
    if (profileDoc.exists && profileDoc.data() != null) {
      final profile = BusinessProfile.fromJson(profileDoc.data()!);
      await LocalDbService.instance.saveBusinessProfile(profile, syncToCloud: false);
      profileRestored = true;
    }

    // 2. Restore Bills
    final billsSnap = await clientRef.collection('bills').get();
    for (final doc in billsSnap.docs) {
      try {
        final bill = Bill.fromJson(doc.data());
        await LocalDbService.instance.saveBill(bill, syncToCloud: false);
        billsRestored++;
      } catch (e) {
        debugPrint('Error restoring bill ${doc.id}: $e');
      }
    }

    // 3. Restore Customers
    final custSnap = await clientRef.collection('customers').get();
    for (final doc in custSnap.docs) {
      try {
        final cust = Customer.fromJson(doc.data());
        await LocalDbService.instance.saveCustomer(cust, syncToCloud: false);
        customersRestored++;
      } catch (e) {
        debugPrint('Error restoring customer ${doc.id}: $e');
      }
    }

    _pendingBillIds.clear();
    _pendingCustomerIds.clear();
    _isProfilePending = false;
    await _savePendingQueue();

    return RestoreResult(
      billsRestored: billsRestored,
      customersRestored: customersRestored,
      profileRestored: profileRestored,
    );
  }

  void dispose() {
    _connectivitySub?.cancel();
    _periodicSyncTimer?.cancel();
  }
}
