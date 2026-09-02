import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import {
  ApiTags,
  ApiBearerAuth,
  ApiHeader,
  ApiOperation,
  ApiConsumes,
  ApiBody,
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { ContentService } from './content.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceSessionGuard } from '../common/guards/device-session.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import {
  CreateSubjectDto,
  CreateTopicDto,
  CreateYearDto,
  UploadMaterialDto,
  UpdateMaterialDto,
} from './dto/content.dto';

@ApiTags('admin-content')
@ApiBearerAuth()
@ApiHeader({ name: 'X-Device-Id', required: true })
@UseGuards(JwtAuthGuard, DeviceSessionGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@Controller('admin')
export class AdminContentController {
  constructor(private contentService: ContentService) {}

  // Years
  @Get('years')
  @ApiOperation({ summary: 'List all years' })
  listYears() {
    return this.contentService.listAllYears();
  }

  @Post('years')
  @ApiOperation({ summary: 'Create a year' })
  createYear(@Body() dto: CreateYearDto) {
    return this.contentService.createYear(dto);
  }

  // Subjects
  @Get('subjects')
  @ApiOperation({ summary: 'List subjects' })
  listSubjects(@Query('yearId') yearId?: string) {
    return this.contentService.listAllSubjects(yearId);
  }

  @Post('subjects')
  @ApiOperation({ summary: 'Create a subject' })
  createSubject(@Body() dto: CreateSubjectDto) {
    return this.contentService.createSubject(dto);
  }

  // Topics
  @Get('subjects/:subjectId/topics')
  @ApiOperation({ summary: 'List topics for a subject' })
  listTopics(@Param('subjectId') subjectId: string) {
    return this.contentService.listTopics(subjectId);
  }

  @Post('topics')
  @ApiOperation({ summary: 'Create a topic' })
  createTopic(@Body() dto: CreateTopicDto) {
    return this.contentService.createTopic(dto);
  }

  // Materials
  @Get('materials')
  @ApiOperation({ summary: 'List all materials (including unpublished)' })
  listMaterials(@Query('subjectId') subjectId?: string) {
    return this.contentService.listAllMaterials(subjectId);
  }

  @Post('materials/upload')
  @ApiOperation({ summary: 'Upload PDF/material to storage' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      required: ['file', 'subjectId', 'title'],
      properties: {
        file: { type: 'string', format: 'binary' },
        subjectId: { type: 'string', format: 'uuid' },
        topicId: { type: 'string', format: 'uuid' },
        title: { type: 'string' },
        type: { type: 'string', enum: ['PDF', 'VIDEO', 'NOTES'] },
        isDownloadable: { type: 'boolean' },
        isPastPaper: { type: 'boolean' },
        pastPaperYear: { type: 'integer' },
        pastPaperSession: { type: 'string' },
      },
    },
  })
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 50 * 1024 * 1024 } }))
  uploadMaterial(
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: UploadMaterialDto,
  ) {
    return this.contentService.uploadMaterial(file, dto);
  }

  @Patch('materials/:id')
  @ApiOperation({ summary: 'Update material metadata or publish' })
  updateMaterial(@Param('id') id: string, @Body() dto: UpdateMaterialDto) {
    return this.contentService.updateMaterial(id, dto);
  }

  @Delete('materials/:id')
  @ApiOperation({ summary: 'Delete material and file from storage' })
  deleteMaterial(@Param('id') id: string) {
    return this.contentService.deleteMaterial(id);
  }
}
