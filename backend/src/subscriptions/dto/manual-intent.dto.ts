import { IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { PlanType } from '@prisma/client';

export class CreateManualIntentDto {
  @ApiProperty({ enum: PlanType, example: PlanType.YEAR_1 })
  @IsEnum(PlanType)
  planType!: PlanType;
}
