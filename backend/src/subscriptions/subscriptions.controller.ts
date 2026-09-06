import { Controller, Get, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiHeader, ApiOperation } from '@nestjs/swagger';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceSessionGuard } from '../common/guards/device-session.guard';
import { CurrentUser, JwtPayloadUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateManualIntentDto } from './dto/manual-intent.dto';

@ApiTags('subscriptions')
@ApiBearerAuth()
@ApiHeader({ name: 'X-Device-Id', required: true })
@UseGuards(JwtAuthGuard, DeviceSessionGuard)
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(
    private subscriptionsService: SubscriptionsService,
    private prisma: PrismaService,
  ) {}

  @Get('me')
  @ApiOperation({ summary: 'Current user subscriptions and entitlements' })
  async me(@CurrentUser() user: JwtPayloadUser) {
    const subs = await this.prisma.subscription.findMany({
      where: { userId: user.sub },
      include: { plan: true },
      orderBy: { createdAt: 'desc' },
    });

    const accessibleYears = await this.subscriptionsService.getAccessibleYearSlugs(
      user.sub,
      user.role as UserRole,
    );

    return {
      subscriptions: subs.map((s) => ({
        id: s.id,
        planName: s.plan.name,
        planType: s.plan.planType,
        status: s.status,
        startDate: s.startDate,
        endDate: s.endDate,
      })),
      accessibleYears,
    };
  }

  @Post('manual-intent')
  @ApiOperation({ summary: 'Register intent for manual payment (e.g. JazzCash)' })
  async createManualIntent(
    @CurrentUser() user: JwtPayloadUser,
    @Body() dto: CreateManualIntentDto,
  ) {
    return this.subscriptionsService.createManualIntent(user.sub, dto.planType);
  }
}
