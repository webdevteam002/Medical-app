import {
  Controller,
  Get,
  Post,
  Query,
  Body,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
  StreamableFile,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiHeader,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { QuestionMediaService } from './question-media.service';
import { Public, Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceSessionGuard } from '../common/guards/device-session.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

class UploadQuestionImagesDto {
  @ApiPropertyOptional({
    description: 'Optional subfolder under images/, e.g. uworld or amboss',
  })
  @IsOptional()
  @IsString()
  folder?: string;
}

@ApiTags('media')
@Controller()
export class MediaController {
  constructor(private questionMedia: QuestionMediaService) {}

  @Public()
  @Get('media/question-images')
  @ApiOperation({
    summary: 'Stream a question image with a short-lived signed URL',
  })
  async streamQuestionImage(
    @Query('key') key: string,
    @Query('exp') exp: string,
    @Query('sig') sig: string,
  ) {
    const { stream, contentType, contentLength } =
      await this.questionMedia.streamBySignedQuery(key, exp, sig);
    return new StreamableFile(stream, {
      type: contentType,
      length: contentLength,
      disposition: 'inline',
    });
  }
}

@ApiTags('admin-question-images')
@ApiBearerAuth()
@ApiHeader({ name: 'X-Device-Id', required: true })
@UseGuards(JwtAuthGuard, DeviceSessionGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@Controller('admin/question-images')
export class AdminQuestionImagesController {
  constructor(private questionMedia: QuestionMediaService) {}

  @Get('status')
  @ApiOperation({ summary: 'Question image storage index status' })
  status() {
    return this.questionMedia.getIndexStats();
  }

  @Post('reindex')
  @ApiOperation({ summary: 'Rebuild local basename → key index after bulk sync' })
  reindex() {
    this.questionMedia.refreshIndex();
    return this.questionMedia.getIndexStats();
  }

  @Post('upload')
  @ApiOperation({
    summary: 'Bulk upload question images (filenames must match CSV image_key)',
  })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        files: { type: 'array', items: { type: 'string', format: 'binary' } },
        folder: { type: 'string', example: 'uworld' },
      },
    },
  })
  @UseInterceptors(
    FilesInterceptor('files', 500, { limits: { fileSize: 20 * 1024 * 1024 } }),
  )
  upload(
    @UploadedFiles() files: Express.Multer.File[],
    @Body() dto: UploadQuestionImagesDto,
  ) {
    return this.questionMedia.uploadImages(files || [], dto.folder);
  }
}
