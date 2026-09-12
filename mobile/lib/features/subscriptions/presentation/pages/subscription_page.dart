import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/subscriptions_remote_datasource.dart';
import '../../data/models/payment_instructions_model.dart';
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
  bool _isSubscribing = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  UserSubscriptionsModel? _userSubscriptions;
  List<SubscriptionPlanModel> _availablePlans = [];
  PaymentInstructionsModel? _paymentInstructions;
  String? _selectedPlanType;
  ManualPaymentIntentResult? _pendingIntent;

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
        _dataSource.getPaymentInstructions(),
      ]);

      if (mounted) {
        setState(() {
          _userSubscriptions = results[0] as UserSubscriptionsModel;
          _availablePlans = results[1] as List<SubscriptionPlanModel>;
          _paymentInstructions = results[2] as PaymentInstructionsModel;
          if (_availablePlans.isNotEmpty && _selectedPlanType == null) {
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

  Future<void> _handleSubscribe() async {
    final planType = _selectedPlanType;
    if (planType == null || _isSubscribing) return;

    setState(() => _isSubscribing = true);

    try {
      final result = await _dataSource.createManualIntent(planType);
      if (!mounted) return;
      setState(() {
        _pendingIntent = result;
        _paymentInstructions = result.instructions;
        _isSubscribing = false;
      });
      await _loadData();
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() => _isSubscribing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubscribing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start payment. Please try again.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleRefreshAccess() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    await _loadData();
    if (!mounted) return;
    setState(() => _isRefreshing = false);
    final hasAccess = (_userSubscriptions?.accessibleYears.isNotEmpty ?? false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          hasAccess
              ? 'Access updated. Your subscription is active.'
              : 'Still pending. After payment, admin will activate within 24 hours.',
        ),
        backgroundColor: hasAccess ? Colors.green : AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _copyText(String label, String value) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied')),
    );
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
            onPressed: _isRefreshing ? null : _handleRefreshAccess,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded,
                    color: Colors.white, size: 18),
            label: const Text(
              'Refresh',
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
    final pendingSubs = _userSubscriptions?.subscriptions
            .where((s) => s.status.toUpperCase() == 'PENDING')
            .toList() ??
        [];
    final accessibleYears = _userSubscriptions?.accessibleYears ?? [];
    final instructions = _paymentInstructions;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(activeSubs, accessibleYears, pendingSubs),
          const SizedBox(height: AppTheme.spacingXl),
          Text(
            'Available Subscription Plans',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          const Text(
            '1) Choose a plan  2) Pay via JazzCash/Easypaisa  3) WhatsApp screenshot  4) Admin activates',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
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
            RadioGroup<String>(
              groupValue: _selectedPlanType,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedPlanType = val);
                }
              },
              child: Column(
                children: _availablePlans.map(_buildPlanTile).toList(),
              ),
            ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSubscribing ? null : _handleSubscribe,
              icon: _isSubscribing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.payments_rounded),
              label: Text(
                _isSubscribing ? 'Preparing payment…' : 'Continue to Payment',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                ),
              ),
            ),
          ),
          if (_pendingIntent != null || instructions != null) ...[
            const SizedBox(height: AppTheme.spacingXl),
            _buildPaymentInstructionsCard(instructions),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(
    List activeSubs,
    List<String> accessibleYears,
    List pendingSubs,
  ) {
    final hasActive = activeSubs.isNotEmpty;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        side: BorderSide(
          color: hasActive ? Colors.green.shade300 : const Color(0xFFE2E8F0),
        ),
      ),
      color: hasActive ? Colors.green.withValues(alpha: 0.08) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasActive
                      ? Icons.verified_rounded
                      : Icons.lock_outline_rounded,
                  color: hasActive ? Colors.green : AppTheme.textSecondaryColor,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  hasActive
                      ? 'Active Subscription'
                      : pendingSubs.isNotEmpty
                          ? 'Payment Pending Activation'
                          : 'Free Student Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasActive
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
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ] else ...[
              Text(
                pendingSubs.isNotEmpty
                    ? 'Your payment request is waiting. After you WhatsApp the screenshot, admin will activate access.'
                    : 'Register is free. Subscribe to unlock study materials, past papers, and exams.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTile(SubscriptionPlanModel plan) {
    final isSelected = plan.planType == _selectedPlanType;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: InkWell(
        onTap: () => setState(() => _selectedPlanType = plan.planType),
        hoverColor: AppTheme.primaryColor.withValues(alpha: 0.05),
        focusColor: AppTheme.primaryColor.withValues(alpha: 0.15),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.06)
                : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
            border: Border.all(
              color:
                  isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<String>(
                value: plan.planType,
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
  }

  Widget _buildPaymentInstructionsCard(PaymentInstructionsModel? instructions) {
    final data = instructions;
    if (data == null) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to pay & get access',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.instructions,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (data.jazzcashNumber.isNotEmpty)
              _paymentRow('JazzCash', data.jazzcashNumber),
            if (data.easypaisaNumber.isNotEmpty)
              _paymentRow('Easypaisa', data.easypaisaNumber),
            if (data.bankDetails.isNotEmpty)
              _paymentRow('Bank', data.bankDetails),
            if (data.whatsappNumber.isNotEmpty)
              _paymentRow('WhatsApp screenshot to', data.whatsappNumber),
            if (data.jazzcashNumber.isEmpty &&
                data.easypaisaNumber.isEmpty &&
                data.bankDetails.isEmpty)
              const Text(
                'Payment numbers will appear here once admin configures them in server settings.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            if (_pendingIntent != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Request saved for ${_pendingIntent!.planType}. Status: ${_pendingIntent!.status}. After payment, wait for admin activation, then tap Refresh.',
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _paymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            onPressed: () => _copyText(label, value),
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
