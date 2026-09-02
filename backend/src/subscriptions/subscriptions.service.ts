import { Injectable, NotFoundException } from '@nestjs/common';
import { PlanType, SubscriptionStatus, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

const PLAN_YEAR_SLUGS: Record<PlanType, string[]> = {
  YEAR_1: ['year-1'],
  YEAR_2: ['year-2'],
  YEAR_3: ['year-3'],
  YEAR_4: ['year-4'],
  YEAR_5: ['year-5'],
  FCPS_PART_1: ['fcps-part-1'],
  FCPS_PART_2: ['fcps-part-2'],
  ALL_MBBS: ['year-1', 'year-2', 'year-3', 'year-4', 'year-5'],
  ULTIMATE_BUNDLE: [
    'year-1',
    'year-2',
    'year-3',
    'year-4',
    'year-5',
    'fcps-part-1',
    'fcps-part-2',
  ],
};

@Injectable()
export class SubscriptionsService {
  constructor(private prisma: PrismaService) {}

  async hasAccess(userId: string, role: UserRole, yearSlug: string): Promise<boolean> {
    if (role === UserRole.ADMIN || role === UserRole.SUPER_ADMIN) {
      return true;
    }

    const activeSubs = await this.prisma.subscription.findMany({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
        endDate: { gt: new Date() },
      },
      include: { plan: true },
    });

    for (const sub of activeSubs) {
      const slugs = PLAN_YEAR_SLUGS[sub.plan.planType] ?? [];
      if (slugs.includes(yearSlug)) {
        return true;
      }
    }

    return false;
  }

  async getAccessibleYearSlugs(userId: string, role: UserRole): Promise<string[]> {
    if (role === UserRole.ADMIN || role === UserRole.SUPER_ADMIN) {
      const years = await this.prisma.year.findMany({ select: { slug: true } });
      return years.map((y) => y.slug);
    }

    const activeSubs = await this.prisma.subscription.findMany({
      where: {
        userId,
        status: SubscriptionStatus.ACTIVE,
        endDate: { gt: new Date() },
      },
      include: { plan: true },
    });

    const slugSet = new Set<string>();
    for (const sub of activeSubs) {
      const slugs = PLAN_YEAR_SLUGS[sub.plan.planType] ?? [];
      slugs.forEach((s) => slugSet.add(s));
    }
    return [...slugSet];
  }

  async grantManualSubscription(userId: string, planType: PlanType, days = 365) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'User not found' });
    }

    const plan = await this.prisma.subscriptionPlan.findUnique({
      where: { planType },
    });
    if (!plan) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: `Plan not found: ${planType}` });
    }

    const startDate = new Date();
    const endDate = new Date();
    endDate.setDate(endDate.getDate() + days);

    await this.prisma.subscription.updateMany({
      where: { userId, status: SubscriptionStatus.ACTIVE },
      data: { status: SubscriptionStatus.CANCELLED },
    });

    return this.prisma.subscription.create({
      data: {
        userId,
        planId: plan.id,
        status: SubscriptionStatus.ACTIVE,
        startDate,
        endDate,
      },
      include: { plan: true, user: { select: { email: true, fullName: true } } },
    });
  }

  listPlans() {
    return this.prisma.subscriptionPlan.findMany({
      where: { isActive: true },
      orderBy: { pricePkr: 'asc' },
      select: {
        id: true,
        name: true,
        planType: true,
        pricePkr: true,
        durationDays: true,
      },
    });
  }

  listSubscriptions(filters?: { status?: SubscriptionStatus; userId?: string }) {
    return this.prisma.subscription.findMany({
      where: {
        ...(filters?.status ? { status: filters.status } : {}),
        ...(filters?.userId ? { userId: filters.userId } : {}),
      },
      include: {
        plan: true,
        user: { select: { id: true, email: true, fullName: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async revokeSubscription(subscriptionId: string) {
    const sub = await this.prisma.subscription.findUnique({ where: { id: subscriptionId } });
    if (!sub) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Subscription not found' });
    }

    return this.prisma.subscription.update({
      where: { id: subscriptionId },
      data: { status: SubscriptionStatus.CANCELLED, endDate: new Date() },
    });
  }

  getPaymentInstructions() {
    return {
      methods: ['jazzcash', 'easypaisa', 'bank'],
      jazzcashNumber: process.env.PAYMENT_JAZZCASH_NUMBER || '',
      easypaisaNumber: process.env.PAYMENT_EASYPAISA_NUMBER || '',
      bankDetails: process.env.PAYMENT_BANK_DETAILS || '',
      whatsappNumber: process.env.PAYMENT_WHATSAPP_NUMBER || '',
      instructions:
        process.env.PAYMENT_INSTRUCTIONS ||
        'Send payment to the number above, then share screenshot on WhatsApp. Access is activated within 24 hours.',
    };
  }
}
