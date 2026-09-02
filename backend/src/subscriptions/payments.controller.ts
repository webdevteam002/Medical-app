import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { SubscriptionsService } from './subscriptions.service';
import { Public } from '../common/decorators/roles.decorator';

@ApiTags('payments')
@Controller('payments')
export class PaymentsController {
  constructor(private subscriptionsService: SubscriptionsService) {}

  @Public()
  @Get('plans')
  @ApiOperation({ summary: 'List subscription plans and PKR prices' })
  listPlans() {
    return this.subscriptionsService.listPlans();
  }

  @Public()
  @Get('instructions')
  @ApiOperation({ summary: 'JazzCash/Easypaisa payment instructions for manual subscription' })
  instructions() {
    return this.subscriptionsService.getPaymentInstructions();
  }
}
