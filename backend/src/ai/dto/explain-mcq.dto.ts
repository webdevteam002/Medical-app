import { IsString, IsNotEmpty, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ExplainMcqDto {
  @ApiProperty({ example: 'q_uuid' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  questionId!: string;

  @ApiProperty({ example: 'b' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(32)
  selectedOptionId!: string;
}
