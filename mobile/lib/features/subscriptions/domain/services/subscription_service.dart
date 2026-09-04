import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../data/datasources/subscriptions_remote_datasource.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/models/user_subscriptions_model.dart';

class RevenueCatConfig {
  static const String androidApiKey = 'goog_placeholder_public_sdk_key';
  static const String iosApiKey = 'appl_placeholder_public_sdk_key';

  static const String entitlementYear1 = 'year-1';
  static const String entitlementYear2 = 'year-2';
  static const String entitlementYear3 = 'year-3';
  static const String entitlementYear4 = 'year-4';
  static const String entitlementYear5 = 'year-5';
  static const String entitlementFcps1 = 'fcps-part-1';
  static const String entitlementFcps2 = 'fcps-part-2';
  static const String entitlementAllMbbs = 'all_mbbs';
  static const String entitlementUltimateBundle = 'ultimate_bundle';

  static const Map<String, String> planTypeToStoreProductId = {
    'YEAR_1': 'medstudy_year_1',
    'YEAR_2': 'medstudy_year_2',
    'YEAR_3': 'medstudy_year_3',
    'YEAR_4': 'medstudy_year_4',
    'YEAR_5': 'medstudy_year_5',
    'FCPS_PART_1': 'medstudy_fcps_part_1',
    'FCPS_PART_2': 'medstudy_fcps_part_2',
    'ALL_MBBS': 'medstudy_all_mbbs',
    'ULTIMATE_BUNDLE': 'medstudy_ultimate_bundle',
  };
}

class SubscriptionService {
  final SubscriptionsRemoteDataSource _remoteDataSource;
  String? _currentUserId;
  UserSubscriptionsModel? _cachedUserSubscriptions;
  bool _isRevenueCatConfigured = false;

  SubscriptionService({SubscriptionsRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? SubscriptionsRemoteDataSource();

  Future<void> initializeRevenueCat() async {
    if (_isRevenueCatConfigured || kIsWeb) return;

    try {
      String apiKey = '';
      if (Platform.isAndroid) {
        apiKey = RevenueCatConfig.androidApiKey;
      } else if (Platform.isIOS) {
        apiKey = RevenueCatConfig.iosApiKey;
      }

      if (apiKey.isNotEmpty && !apiKey.contains('placeholder')) {
        await Purchases.configure(PurchasesConfiguration(apiKey));
        _isRevenueCatConfigured = true;
      }
    } catch (_) {
      // SDK initialization logged without breaking application flow
    }
  }

  Future<void> initialize(String userId) async {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _cachedUserSubscriptions = null;

      await initializeRevenueCat();

      if (_isRevenueCatConfigured) {
        try {
          await Purchases.logIn(userId);
        } catch (_) {
          // Failure logged without crashing
        }
      }
    }
  }

  Future<void> clearSession() async {
    if (_isRevenueCatConfigured) {
      try {
        await Purchases.logOut();
      } catch (_) {
        // Logged out
      }
    }
    _currentUserId = null;
    _cachedUserSubscriptions = null;
  }

  Future<UserSubscriptionsModel> getUserSubscriptions({
    bool forceRefresh = false,
  }) async {
    if (_cachedUserSubscriptions != null && !forceRefresh) {
      return _cachedUserSubscriptions!;
    }

    final model = await _remoteDataSource.getUserSubscriptions();
    _cachedUserSubscriptions = model;
    return model;
  }

  Future<List<SubscriptionPlanModel>> getAvailablePlans() async {
    return await _remoteDataSource.getAvailablePlans();
  }

  bool isYearAccessible(String yearSlug, List<String> accessibleYears) {
    return accessibleYears.contains(yearSlug);
  }

  Future<bool> restorePurchases() async {
    if (_isRevenueCatConfigured) {
      try {
        await Purchases.restorePurchases();
      } catch (_) {
        // Store restore attempted
      }
    }

    _cachedUserSubscriptions = null;
    await getUserSubscriptions(forceRefresh: true);
    return true;
  }
}
