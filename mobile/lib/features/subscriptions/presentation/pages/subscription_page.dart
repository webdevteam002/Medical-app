import 'package:flutter/material.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/subscriptions_remote_datasource.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/models/user_subscriptions_model.dart';

class SubscriptionPage extends StatefulWidget {
  final SubscriptionsRemoteDataSource? remoteDataSource;

  const SubscriptionPage({
    super.key,
    this.remoteDataSource,
  });

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late final SubscriptionsRemoteDataSource _dataSource;
  bool _isLoading = true;
  bool _isRestoring = false;
  String? _errorMessage;
  UserSubscriptionsModel? _userSubscriptions;
  List<SubscriptionPlanModel> _availablePlans = [];
  String? _selectedPlanType;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.remoteDataSource ?? SubscriptionsRemoteDataSource();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _dataSource.getUserSubscriptions(),
        _dataSource.getAvailablePlans(),
      ]);

      if (mounted) {
        setState(() {
          _userSubscriptions = results[0] as UserSubscriptionsModel;
          _availablePlans = results[1] as List<SubscriptionPlanModel>;
          if (_availablePlans.isNotEmpty) {
            _selectedPlanType = _availablePlans.first.planType;
          }
          _isLoading = false;
        });
      }
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load subscription information.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRestorePurchases() async {
    if (_isRestoring || !mounted) return;

    setState(() {
      _isRestoring = true;
    });

    await _loadData();

    if (mounted) {
      setState(() {
        _isRestoring = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases restored and synchronized successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions & Access'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isRestoring ? null : _handleRestorePurchases,
            icon: _isRestoring
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.restore_rounded,
                    color: Colors.white, size: 18),
            label: const Text(
              'Restore',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final activeSubs =
        _userSubscriptions?.subscriptions.where((s) => s.isActive).toList() ??
            [];
    final accessibleYears = _userSubscriptions?.accessibleYears ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status Banner
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
              side: BorderSide(
                color: activeSubs.isNotEmpty
                    ? Colors.green.shade300
                    : const Color(0xFFE2E8F0),
              ),
            ),
            color: activeSubs.isNotEmpty
                ? Colors.green.withValues(alpha: 0.08)
                : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        activeSubs.isNotEmpty
                            ? Icons.verified_rounded
                            : Icons.lock_outline_rounded,
                        color: activeSubs.isNotEmpty
                            ? Colors.green
                            : AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Text(
                        activeSubs.isNotEmpty
                            ? 'Active Subscription'
                            : 'Free Student Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: activeSubs.isNotEmpty
                              ? Colors.green.shade900
                              : AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  if (accessibleYears.isNotEmpty) ...[
                    const Text(
                      'Accessible Academic Modules:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: accessibleYears.map((slug) {
                        return Chip(
                          label: Text(
                            slug.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          backgroundColor:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    const Text(
                      'Subscribe to unlock full QBank access, medical study materials, and mock exams.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Text(
            'Available Subscription Plans',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          const Text(
            'Choose your academic year or full bundle plan',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          if (_availablePlans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No subscription plans available currently.'),
              ),
            )
          else
            ..._availablePlans.map((plan) {
              final isSelected = plan.planType == _selectedPlanType;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPlanType = plan.planType;
                    });
                  },
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withValues(alpha: 0.06)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusMd),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: plan.planType,
                          groupValue: _selectedPlanType,
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedPlanType = val;
                              });
                            }
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${plan.durationDays} Days Full Access',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Rs. ${plan.pricePkr}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Selected plan $_selectedPlanType. Contact admin or use JazzCash/Easypaisa manual grant to activate.',
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              },
              icon: const Icon(Icons.star_rounded),
              label: const Text('Subscribe Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
