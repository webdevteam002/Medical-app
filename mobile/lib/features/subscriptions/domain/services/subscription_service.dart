import '../../data/datasources/subscriptions_remote_datasource.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/models/user_subscriptions_model.dart';

class SubscriptionService {
  final SubscriptionsRemoteDataSource _remoteDataSource;
  String? _currentUserId;
  UserSubscriptionsModel? _cachedUserSubscriptions;

  SubscriptionService({SubscriptionsRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? SubscriptionsRemoteDataSource();

  Future<void> initialize(String userId) async {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _cachedUserSubscriptions = null;
    }
  }

  void clearSession() {
    _currentUserId = null;
    _cachedUserSubscriptions = null;
  }

  Future<UserSubscriptionsModel> getUserSubscriptions(
      {bool forceRefresh = false}) async {
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
    if (accessibleYears.contains(yearSlug)) {
      return true;
    }
    return false;
  }

  Future<bool> restorePurchases() async {
    // In production, syncs RevenueCat customer info & revalidates with backend
    _cachedUserSubscriptions = null;
    await getUserSubscriptions(forceRefresh: true);
    return true;
  }
}
