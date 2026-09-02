import { Module } from '@nestjs/common';
import { AdminUsersController } from './admin-users.controller';
import { AdminUsersService } from './admin-users.service';
import { AdminSubscriptionsController } from './admin-subscriptions.controller';

@Module({
  controllers: [AdminUsersController, AdminSubscriptionsController],
  providers: [AdminUsersService],
})
export class AdminModule {}
