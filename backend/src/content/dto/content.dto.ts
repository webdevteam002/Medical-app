import {
  IsString,
  IsInt,
  IsOptional,
  IsBoolean,
  IsEnum,
  IsUUID,
  MinLength,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MaterialType, PlanType } from '@prisma/client';
import { Type } from 'class-transformer';

export class CreateYearDto {
  @ApiProperty()
  @IsString()
  @MinLength(2)
  name!: string;

  @ApiProperty({ example: 'year-1' })
  @IsString()
  slug!: string;

  @ApiProperty()
  @Type(() => Number)
  @IsInt()
  sortOrder!: number;

  @ApiProperty({ enum: PlanType })
  @IsEnum(PlanType)
  planType!: PlanType;
}

export class CreateSubjectDto {
  @ApiProperty()
  @IsUUID()
  yearId!: string;

  @ApiProperty()
  @IsString()
  name!: string;

  @ApiProperty()
  @IsString()
  slug!: string;

  @ApiProperty()
  @Type(() => Number)
  @IsInt()
  sortOrder!: number;
}

export class CreateTopicDto {
  @ApiProperty()
  @IsUUID()
  subjectId!: string;

  @ApiProperty()
  @IsString()
  name!: string;

  @ApiProperty()
  @Type(() => Number)
  @IsInt()
  sortOrder!: number;
}

export class UploadMaterialDto {
  @ApiProperty()
  @IsUUID()
  subjectId!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  topicId?: string;

  @ApiProperty()
  @IsString()
  @MinLength(2)
  @MaxLength(500)
  title!: string;

  @ApiPropertyOptional({ enum: MaterialType })
  @IsOptional()
  @IsEnum(MaterialType)
  type?: MaterialType;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isDownloadable?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPastPaper?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  pastPaperYear?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  pastPaperSession?: string;
}

export class UpdateMaterialDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  topicId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isDownloadable?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPublished?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isPastPaper?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  pastPaperYear?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  pastPaperSession?: string;
}

export class GrantSubscriptionDto {
  @ApiProperty({ enum: PlanType })
  @IsEnum(PlanType)
  planType!: PlanType;

  @ApiPropertyOptional({ default: 365 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  durationDays?: number;
}
