import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gopal_studio_pro/services/app_activation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppActivationService Offline & Expiry Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('generates persistent unique client_id with SBP prefix', () async {
      final service = AppActivationService.instance;
      final clientId1 = await service.getClientId();
      final clientId2 = await service.getClientId();

      expect(clientId1, startsWith('SBP-'));
      expect(clientId1, equals(clientId2)); // Must remain identical across calls
    });

    test('active by default on fresh installation within grace period', () async {
      final service = AppActivationService.instance;
      final info = await service.checkAndSyncActivation();

      expect(info.isActive, isTrue);
      expect(info.appId, equals('studiobill_pro'));
      expect(info.clientId, startsWith('SBP-'));
      expect(info.platform, isNotEmpty);
      expect(info.daysDisconnected, equals(0));
    });

    test('deactivates if disconnected for more than 15 days', () async {
      final prefs = await SharedPreferences.getInstance();
      // Simulate last connected 16 days ago
      final sixteenDaysAgo = DateTime.now().subtract(const Duration(days: 16));
      await prefs.setInt('app_activation_last_connected_epoch', sixteenDaysAgo.millisecondsSinceEpoch);
      await prefs.setBool('app_activation_local_is_active', true);

      final service = AppActivationService.instance;
      final info = await service.checkAndSyncActivation();

      expect(info.isActive, isFalse);
      expect(info.daysDisconnected, greaterThanOrEqualTo(16));
      expect(info.deactivationReason, contains('15-day limit'));
    });

    test('remains active within 15-day grace period (e.g. 5 days offline)', () async {
      final prefs = await SharedPreferences.getInstance();
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
      await prefs.setInt('app_activation_last_connected_epoch', fiveDaysAgo.millisecondsSinceEpoch);
      await prefs.setBool('app_activation_local_is_active', true);

      final service = AppActivationService.instance;
      final info = await service.checkAndSyncActivation();

      expect(info.isActive, isTrue);
      expect(info.daysDisconnected, equals(5));
      expect(info.isGracePeriod, isTrue);
      expect(info.daysRemaining, equals(10));
    });
  });
}
