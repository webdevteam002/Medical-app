import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class VerifyQuestionDto {
  @ApiProperty({ example: 'q_uuid' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  questionId!: string;
}

export class DecideVerificationDto {
  @ApiProperty({ enum: ['APPROVED', 'REJECTED'] })
  @IsString()
  @IsNotEmpty()
  @IsIn(['APPROVED', 'REJECTED'])
  decision!: 'APPROVED' | 'REJECTED';

  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  adminNote?: string;
}
