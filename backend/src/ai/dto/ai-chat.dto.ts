import { IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AiChatDto {
  @ApiProperty({ description: 'Student message (untrusted)' })
  @IsString()
  @MinLength(1)
  @MaxLength(4000)
  message!: string;

  @ApiPropertyOptional({ description: 'Existing conversation owned by the caller' })
  @IsOptional()
  @IsUUID()
  conversationId?: string;

  @ApiPropertyOptional({
    description:
      'Optional MCQ context. Backend loads authoritative question data; client cannot supply the key.',
  })
  @IsOptional()
  @IsUUID()
  questionId?: string;
}
