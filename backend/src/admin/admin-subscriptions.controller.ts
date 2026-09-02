import { Controller, Get, Post, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiHeader, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { SubscriptionStatus, UserRole } from '@prisma/client';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceSessionGuard } from '../common/guards/device-session.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { GrantSubscriptionDto } from '../content/dto/content.dto';

@ApiTags('admin-subscriptions')
@ApiBearerAuth()
@ApiHeader({ name: 'X-Device-Id', required: true })
@UseGuards(JwtAuthGuard, DeviceSessionGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@Controller('admin/subscriptions')
export class AdminSubscriptionsController {
  constructor(private subscriptionsService: SubscriptionsService) {}

  @Get()
  @ApiOperation({ summary: 'List all subscriptions (JazzCash manual tracking)' })
  @ApiQuery({ name: 'status', required: false, enum: SubscriptionStatus })
  @ApiQuery({ name: 'userId', required: false })
  list(
    @Query('status') status?: SubscriptionStatus,
    @Query('userId') userId?: string,
  ) {
    return this.subscriptionsService.listSubscriptions({ status, userId });
  }

  @Post('users/:userId/grant')
  @ApiOperation({ summary: 'Manually grant subscription after JazzCash/Easypaisa payment' })
  grant(@Param('userId') userId: string, @Body() dto: GrantSubscriptionDto) {
    return this.subscriptionsService.grantManualSubscription(
      userId,
      dto.planType,
      dto.durationDays ?? 365,
    );
  }

  @Post(':subscriptionId/revoke')
  @ApiOperation({ summary: 'Revoke/cancel a subscription immediately' })
  revoke(@Param('subscriptionId') subscriptionId: string) {
    return this.subscriptionsService.revokeSubscription(subscriptionId);
  }
}
