import {
  IsString,
  IsUUID,
  IsOptional,
  IsEnum,
  IsInt,
  IsBoolean,
  IsArray,
  ValidateNested,
  MinLength,
  Min,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Difficulty } from '@prisma/client';
import { Type, Transform } from 'class-transformer';

export class CreateQuestionDto {
  @ApiProperty()
  @IsUUID()
  subjectId!: string;

  @ApiProperty()
  @IsString()
  @MinLength(5)
  stem!: string;

  @ApiProperty({ example: [{ id: 'a', text: 'Option A' }, { id: 'b', text: 'Option B' }] })
  @IsArray()
  options!: { id: string; text: string }[];

  @ApiProperty({ example: 'a', description: 'Optional when EXAM_GRADING_MODE=ai (Gemini grades on submit)' })
  @IsOptional()
  @IsString()
  correctOptionId?: string;

  @ApiProperty({ description: 'Optional when EXAM_GRADING_MODE=ai' })
  @IsOptional()
  @IsString()
  explanation?: string;

  @ApiPropertyOptional({ enum: Difficulty })
  @IsOptional()
  @IsEnum(Difficulty)
  difficulty?: Difficulty;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  tags?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  imageKey?: string;
}

export class UpdateQuestionDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  stem?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  options?: { id: string; text: string }[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  correctOptionId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  explanation?: string;

  @ApiPropertyOptional({ enum: Difficulty })
  @IsOptional()
  @IsEnum(Difficulty)
  difficulty?: Difficulty;

  @ApiPropertyOptional()
  @IsOptional()
  @IsArray()
  tags?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class CreateExamDto {
  @ApiProperty()
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  title!: string;

  @ApiProperty()
  @IsUUID()
  subjectId!: string;

  @ApiProperty()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  durationMinutes!: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  shuffleQuestions?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  shuffleOptions?: boolean;
}

export class UpdateExamDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  durationMinutes?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  shuffleQuestions?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  shuffleOptions?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;
}

export class AddExamQuestionsDto {
  @ApiProperty({ type: [String] })
  @IsArray()
  @IsUUID('4', { each: true })
  questionIds!: string[];

  @ApiPropertyOptional({
    description: 'How many questions to draw per attempt from the bank (defaults to pool size)',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  drawCount?: number;
}

export class SubmitAnswerDto {
  @ApiProperty()
  @IsUUID()
  questionId!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  selectedOptionId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  timeSpentSeconds?: number;
}

export class SubmitExamDto {
  @ApiProperty({ type: [SubmitAnswerDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => SubmitAnswerDto)
  answers!: SubmitAnswerDto[];
}

export class ImportQuestionsDto {
  @ApiProperty()
  @IsUUID()
  subjectId!: string;

  @ApiPropertyOptional({ description: 'Validate CSV without saving rows' })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === true || value === 'true')
  dryRun?: boolean;

  @ApiPropertyOptional({
    description: 'Publish imported questions immediately (default true)',
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => {
    if (value === undefined || value === null || value === '') return true;
    return value === true || value === 'true' || value === '1';
  })
  publish?: boolean;
}

export class BulkPublishQuestionsDto {
  @ApiPropertyOptional({ description: 'Limit publish to one subject' })
  @IsOptional()
  @IsUUID()
  subjectId?: string;

  @ApiPropertyOptional({ description: 'Set false to unpublish matching questions' })
  @IsOptional()
  @IsBoolean()
  @Transform(({ value }) => value === true || value === 'true' || value === '1')
  isPublished?: boolean;
}
