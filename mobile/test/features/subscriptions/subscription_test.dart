import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medstudy/core/errors/failures.dart';
import 'package:medstudy/features/subscriptions/data/datasources/subscriptions_remote_datasource.dart';
import 'package:medstudy/features/subscriptions/data/models/subscription_plan_model.dart';
import 'package:medstudy/features/subscriptions/data/models/user_subscriptions_model.dart';
import 'package:medstudy/features/subscriptions/domain/services/subscription_service.dart';
import 'package:medstudy/features/subscriptions/presentation/pages/subscription_page.dart';

class FakeSubscriptionsRemoteDataSource extends SubscriptionsRemoteDataSource {
  final bool shouldFail;
  final String? errorMessage;
  int getUserSubscriptionsCallCount = 0;
  int getAvailablePlansCallCount = 0;

  FakeSubscriptionsRemoteDataSource({
    this.shouldFail = false,
    this.errorMessage,
  });

  @override
  Future<UserSubscriptionsModel> getUserSubscriptions() async {
    getUserSubscriptionsCallCount++;

    if (shouldFail) {
      throw NetworkFailure(
          errorMessage ?? 'Failed to load user subscriptions.');
    }

    return UserSubscriptionsModel(
      subscriptions: [
        UserSubscriptionItem(
          id: 'sub_99',
          planName: 'Year 1 MBBS Plan',
          planType: 'YEAR_1',
          status: 'ACTIVE',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 335)),
        ),
      ],
      accessibleYears: const ['year-1'],
    );
  }

  @override
  Future<List<SubscriptionPlanModel>> getAvailablePlans() async {
    getAvailablePlansCallCount++;

    if (shouldFail) {
      throw NetworkFailure(errorMessage ?? 'Failed to load plans.');
    }

    return const [
      SubscriptionPlanModel(
        id: 'plan_1',
        name: 'Year 1 MBBS',
        planType: 'YEAR_1',
        pricePkr: 5000,
        durationDays: 365,
      ),
      SubscriptionPlanModel(
        id: 'plan_bundle',
        name: 'Ultimate Medical Bundle',
        planType: 'ULTIMATE_BUNDLE',
        pricePkr: 20000,
        durationDays: 365,
      ),
    ];
  }
}

void main() {
  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Day 56-60 Subscriptions & Access Gating Unit & Widget Tests', () {
    test('1. UserSubscriptionsModel parses NestJS /subscriptions/me JSON', () {
      final json = {
        'subscriptions': [
          {
            'id': 'sub_123',
            'planName': 'Year 2 Annual Plan',
            'planType': 'YEAR_2',
            'status': 'ACTIVE',
            'startDate': '2026-09-01T00:00:00.000Z',
            'endDate': '2027-09-01T00:00:00.000Z',
          },
        ],
        'accessibleYears': ['year-1', 'year-2'],
      };

      final model = UserSubscriptionsModel.fromJson(json);

      expect(model.subscriptions.length, equals(1));
      expect(model.subscriptions.first.planName, equals('Year 2 Annual Plan'));
      expect(model.subscriptions.first.isActive, isTrue);
      expect(model.accessibleYears, equals(['year-1', 'year-2']));
    });

    test('2. SubscriptionPlanModel parses NestJS /payments/plans JSON', () {
      final json = {
        'id': 'plan_fcps',
        'name': 'FCPS Part 1 Preparation',
        'planType': 'FCPS_PART_1',
        'pricePkr': 12000,
        'durationDays': 180,
      };

      final plan = SubscriptionPlanModel.fromJson(json);

      expect(plan.id, equals('plan_fcps'));
      expect(plan.name, equals('FCPS Part 1 Preparation'));
      expect(plan.planType, equals('FCPS_PART_1'));
      expect(plan.pricePkr, equals(12000));
      expect(plan.durationDays, equals(180));
    });

    test('3. SubscriptionService initializes identity and evaluates access',
        () async {
      final fakeDataSource = FakeSubscriptionsRemoteDataSource();
      final service = SubscriptionService(remoteDataSource: fakeDataSource);

      await service.initialize('user_uuid_101');
      final model = await service.getUserSubscriptions();

      expect(model.accessibleYears, equals(['year-1']));
      expect(service.isYearAccessible('year-1', model.accessibleYears), isTrue);
      expect(
          service.isYearAccessible('year-5', model.accessibleYears), isFalse);

      service.clearSession();
    });

    testWidgets(
        '4. SubscriptionPage renders active status, accessible years, available plans & prices',
        (WidgetTester tester) async {
      final fakeDataSource = FakeSubscriptionsRemoteDataSource();

      await tester.pumpWidget(createWidgetUnderTest(
        SubscriptionPage(
          remoteDataSource: fakeDataSource,
        ),
      ));

      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeDataSource.getUserSubscriptionsCallCount, equals(1));
      expect(fakeDataSource.getAvailablePlansCallCount, equals(1));

      expect(find.text('Active Subscription'), findsOneWidget);
      expect(find.text('YEAR-1'), findsOneWidget);
      expect(find.text('Available Subscription Plans'), findsOneWidget);
      expect(find.text('Year 1 MBBS'), findsOneWidget);
      expect(find.text('Rs. 5000'), findsOneWidget);
      expect(find.text('Ultimate Medical Bundle'), findsOneWidget);
      expect(find.text('Rs. 20000'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Subscribe Now'), findsOneWidget);
    });

    testWidgets('5. Tapping Restore Purchases triggers synchronization',
        (WidgetTester tester) async {
      final fakeDataSource = FakeSubscriptionsRemoteDataSource();

      await tester.pumpWidget(createWidgetUnderTest(
        SubscriptionPage(
          remoteDataSource: fakeDataSource,
        ),
      ));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Restore'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeDataSource.getUserSubscriptionsCallCount, equals(2));
      expect(find.text('Purchases restored and synchronized successfully.'),
          findsOneWidget);
    });
  });
}
