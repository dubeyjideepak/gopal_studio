import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import 'local_db_service.dart';

/// Represents the current activation status of the application
class ActivationInfo {
  final bool isActive;
  final String appId;
  final String clientId;
  final DateTime? lastConnectedAt;
  final int daysDisconnected;
  final String? deactivationReason;
  final bool isOnline;
  final String platform;

  const ActivationInfo({
    required this.isActive,
    required this.appId,
    required this.clientId,
    this.lastConnectedAt,
    this.daysDisconnected = 0,
    this.deactivationReason,
    this.isOnline = false,
    this.platform = 'unknown',
  });

  bool get isGracePeriod => isActive && daysDisconnected > 0 && daysDisconnected <= 15;
  int get daysRemaining => (15 - daysDisconnected).clamp(0, 15);

  ActivationInfo copyWith({
    bool? isActive,
    String? appId,
    String? clientId,
    DateTime? lastConnectedAt,
    int? daysDisconnected,
    String? deactivationReason,
    bool? isOnline,
    String? platform,
  }) {
    return ActivationInfo(
      isActive: isActive ?? this.isActive,
      appId: appId ?? this.appId,
      clientId: clientId ?? this.clientId,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      daysDisconnected: daysDisconnected ?? this.daysDisconnected,
      deactivationReason: deactivationReason ?? this.deactivationReason,
      isOnline: isOnline ?? this.isOnline,
      platform: platform ?? this.platform,
    );
  }
}

/// Riverpod StateNotifier to track live activation status throughout the app
final activationStateProvider = StateNotifierProvider<ActivationNotifier, AsyncValue<ActivationInfo>>((ref) {
  return ActivationNotifier();
});

class ActivationNotifier extends StateNotifier<AsyncValue<ActivationInfo>> {
  ActivationNotifier() : super(const AsyncValue.loading()) {
    checkActivation();
  }

  Future<ActivationInfo> checkActivation({bool forceOnlineCheck = false}) async {
    state = const AsyncValue.loading();
    try {
      final info = await AppActivationService.instance.checkAndSyncActivation(force: forceOnlineCheck);
      state = AsyncValue.data(info);
      return info;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

class AppActivationService {
  static AppActivationService? _instance;
  static AppActivationService get instance => _instance ??= AppActivationService._();
  AppActivationService._();

  // ─── Multi-App Identifiers ──────────────────────────────────────────────────
  static const String appId = 'studiobill_pro';
  static const int maxOfflineDaysAllowed = 15;

  static const String _keyClientId = 'app_activation_client_id';
  static const String _keyPlatform = 'app_activation_platform';
  static const String _keyLastConnected = 'app_activation_last_connected_epoch';
  static const String _keyLocalIsActive = 'app_activation_local_is_active';
  static const String _keyDeactivationReason = 'app_activation_deactivation_reason';
  static const String _keyWasDeactivatedByTimeout = 'app_activation_timeout_locked';

  /// Standardized operating system platform name ('macos', 'windows', 'android', 'ios', 'linux', 'web')
  static String get currentPlatform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        try {
          return Platform.operatingSystem.toLowerCase();
        } catch (_) {
          return 'unknown';
        }
    }
  }

  /// Detailed OS name and kernel/build version
  static String get platformDetails {
    if (kIsWeb) return 'Web Browser';
    try {
      return '${Platform.operatingSystem} (${Platform.operatingSystemVersion})';
    } catch (_) {
      return currentPlatform;
    }
  }

  bool _firebaseInitialized = false;

  /// Ensure Firebase is ready
  Future<void> ensureFirebase() async {
    if (_firebaseInitialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseInitialized = true;
    } catch (_) {
      // Offline or initialization handled gracefully
    }
  }

  /// Retrieve or generate a unique persistent client ID for this installation
  Future<String> getClientId() async {
    final prefs = await SharedPreferences.getInstance();
    var clientId = prefs.getString(_keyClientId);
    if (clientId == null || clientId.isEmpty) {
      // Generate clean high-entropy hardware/app identifier: SBP-XXXX-XXXX
      final hex = const Uuid().v4().replaceAll('-', '').substring(0, 8).toUpperCase();
      clientId = 'SBP-${hex.substring(0, 4)}-${hex.substring(4, 8)}';
      await prefs.setString(_keyClientId, clientId);
    }
    return clientId;
  }

  /// Check and sync activation with Firestore
  Future<ActivationInfo> checkAndSyncActivation({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final clientId = await getClientId();
    final platform = currentPlatform;
    await prefs.setString(_keyPlatform, platform);
    final now = DateTime.now();

    final lastConnectedEpoch = prefs.getInt(_keyLastConnected);
    final lastConnected = lastConnectedEpoch != null
        ? DateTime.fromMillisecondsSinceEpoch(lastConnectedEpoch)
        : null;

    final daysSinceConnection = lastConnected != null ? now.difference(lastConnected).inDays : 0;
    final wasTimeoutLocked = prefs.getBool(_keyWasDeactivatedByTimeout) ?? false;

    // 1. Check if offline period exceeds 15 days
    if (lastConnected != null && daysSinceConnection > maxOfflineDaysAllowed) {
      await prefs.setBool(_keyWasDeactivatedByTimeout, true);
      await prefs.setBool(_keyLocalIsActive, false);
      await prefs.setString(
        _keyDeactivationReason,
        'Disconnected from server for $daysSinceConnection days (exceeded 15-day limit). Re-activation required from Firebase.',
      );
    }

    // 2. Attempt Firestore sync
    await ensureFirebase();
    bool isOnline = false;

    try {
      if (_firebaseInitialized) {
        final profile = await LocalDbService.instance.getBusinessProfile();

        final clientDocRef = FirebaseFirestore.instance
            .collection('apps')
            .doc(appId)
            .collection('clients')
            .doc(clientId);

        final mirrorDocRef = FirebaseFirestore.instance
            .collection('app_activations')
            .doc('${appId}_$clientId');

        // Fetch current document from Firestore with a 6-second timeout
        final snapshot = await clientDocRef.get().timeout(const Duration(seconds: 6));
        isOnline = true;

        if (snapshot.exists) {
          final data = snapshot.data();
          final bool serverIsActive = data?['is_active'] == true;

          if (!serverIsActive) {
            // Admin deactivated this client in Firebase
            await prefs.setBool(_keyLocalIsActive, false);
            await prefs.setBool(_keyWasDeactivatedByTimeout, false);
            await prefs.setString(_keyDeactivationReason, 'Deactivated by administrator in Firebase Console.');

            return ActivationInfo(
              isActive: false,
              appId: appId,
              clientId: clientId,
              lastConnectedAt: lastConnected,
              daysDisconnected: 0,
              deactivationReason: 'Deactivated by administrator in Firebase Console.',
              isOnline: true,
              platform: platform,
            );
          } else {
            // Server says ACTIVE
            // Update Firestore with latest heartbeat, platform, and metadata
            final updateData = {
              'app_id': appId,
              'client_id': clientId,
              'is_active': true,
              'client_name': profile.businessName,
              'phone': profile.phone1,
              'platform': platform,
              'platform_details': platformDetails,
              'app_version': AppConstants.appVersion,
              'last_connected_at': FieldValue.serverTimestamp(),
              'last_connected_str': now.toIso8601String(),
              'days_offline': 0,
            };

            await clientDocRef.set(updateData, SetOptions(merge: true));
            await mirrorDocRef.set(updateData, SetOptions(merge: true));

            // Record local success
            await prefs.setBool(_keyLocalIsActive, true);
            await prefs.setBool(_keyWasDeactivatedByTimeout, false);
            await prefs.remove(_keyDeactivationReason);
            await prefs.setInt(_keyLastConnected, now.millisecondsSinceEpoch);

            return ActivationInfo(
              isActive: true,
              appId: appId,
              clientId: clientId,
              lastConnectedAt: now,
              daysDisconnected: 0,
              isOnline: true,
              platform: platform,
            );
          }
        } else {
          // Document does not exist yet -> Register new client (Active by default)
          final initialData = {
            'app_id': appId,
            'app_name': AppConstants.appName,
            'client_id': clientId,
            'is_active': true, // Active by default on registration
            'client_name': profile.businessName,
            'owner_name': profile.ownerName,
            'phone': profile.phone1,
            'platform': platform,
            'platform_details': platformDetails,
            'app_version': AppConstants.appVersion,
            'created_at': FieldValue.serverTimestamp(),
            'created_str': now.toIso8601String(),
            'last_connected_at': FieldValue.serverTimestamp(),
            'last_connected_str': now.toIso8601String(),
            'days_offline': 0,
          };

          await clientDocRef.set(initialData);
          await mirrorDocRef.set(initialData);

          await prefs.setBool(_keyLocalIsActive, true);
          await prefs.setBool(_keyWasDeactivatedByTimeout, false);
          await prefs.remove(_keyDeactivationReason);
          await prefs.setInt(_keyLastConnected, now.millisecondsSinceEpoch);

          return ActivationInfo(
            isActive: true,
            appId: appId,
            clientId: clientId,
            lastConnectedAt: now,
            daysDisconnected: 0,
            isOnline: true,
            platform: platform,
          );
        }
      }
    } catch (_) {
      isOnline = false;
    }

    // 3. Fallback: Offline state evaluation
    final localActive = prefs.getBool(_keyLocalIsActive) ?? true;
    final savedReason = prefs.getString(_keyDeactivationReason);

    // If first ever run with no local record, allow initial activation
    if (lastConnected == null) {
      await prefs.setInt(_keyLastConnected, now.millisecondsSinceEpoch);
      await prefs.setBool(_keyLocalIsActive, true);
      return ActivationInfo(
        isActive: true,
        appId: appId,
        clientId: clientId,
        lastConnectedAt: now,
        daysDisconnected: 0,
        isOnline: false,
        platform: platform,
      );
    }

    // If disconnected for > 15 days or locked by timeout
    if (daysSinceConnection > maxOfflineDaysAllowed || wasTimeoutLocked || !localActive) {
      return ActivationInfo(
        isActive: false,
        appId: appId,
        clientId: clientId,
        lastConnectedAt: lastConnected,
        daysDisconnected: daysSinceConnection,
        deactivationReason: savedReason ??
            'Disconnected from server for $daysSinceConnection days (limit: 15 days). Connect to internet and activate via Firebase.',
        isOnline: isOnline,
        platform: platform,
      );
    }

    // Still within 15-day offline grace period
    return ActivationInfo(
      isActive: true,
      appId: appId,
      clientId: clientId,
      lastConnectedAt: lastConnected,
      daysDisconnected: daysSinceConnection,
      isOnline: isOnline,
      platform: platform,
    );
  }
}
