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
import { Transform, Type } from 'class-transformer';

/** Multipart form fields arrive as strings — coerce "true"/"false"/1/0 to boolean. */
function toOptionalBoolean({ value }: { value: unknown }): boolean | undefined {
  if (value === undefined || value === null || value === '') return undefined;
  if (typeof value === 'boolean') return value;
  if (value === true || value === 'true' || value === '1' || value === 1) return true;
  if (value === false || value === 'false' || value === '0' || value === 0) return false;
  return value as boolean;
}

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
  @Transform(toOptionalBoolean)
  @IsBoolean()
  isDownloadable?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(toOptionalBoolean)
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
  @Transform(toOptionalBoolean)
  @IsBoolean()
  isDownloadable?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(toOptionalBoolean)
  @IsBoolean()
  isPublished?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(toOptionalBoolean)
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

  /**
   * Copyright/AI governance gate. Default false on create.
   * Only ADMIN/SUPER_ADMIN can set this (this DTO is admin-only).
   * Students never receive a write path for this field.
   */
  @ApiPropertyOptional({
    description:
      'Allow AI RAG ingestion. Requires published PDF. Default false. Admin-only.',
  })
  @IsOptional()
  @Transform(toOptionalBoolean)
  @IsBoolean()
  aiIngestAllowed?: boolean;
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
