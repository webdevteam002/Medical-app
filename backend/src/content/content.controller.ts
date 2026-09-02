import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Query,
  UseGuards,
  Res,
  StreamableFile,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiHeader, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { Response } from 'express';
import { ContentService } from './content.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceSessionGuard } from '../common/guards/device-session.guard';
import { CurrentUser, JwtPayloadUser } from '../common/decorators/current-user.decorator';

@ApiTags('content')
@ApiBearerAuth()
@ApiHeader({ name: 'X-Device-Id', required: true })
@UseGuards(JwtAuthGuard, DeviceSessionGuard)
@Controller()
export class ContentController {
  constructor(private contentService: ContentService) {}

  @Get('years')
  @ApiOperation({ summary: 'List years accessible to current user' })
  listYears(@CurrentUser() user: JwtPayloadUser) {
    return this.contentService.listYears(user);
  }

  @Get('years/:yearSlug/subjects')
  @ApiOperation({ summary: 'List subjects for a year' })
  listSubjects(@Param('yearSlug') yearSlug: string, @CurrentUser() user: JwtPayloadUser) {
    return this.contentService.listSubjects(yearSlug, user);
  }

  @Get('subjects/:subjectId/materials')
  @ApiOperation({ summary: 'List published materials for a subject' })
  @ApiQuery({ name: 'topicId', required: false })
  @ApiQuery({ name: 'search', required: false })
  @ApiQuery({ name: 'pastPapersOnly', required: false, type: Boolean })
  listMaterials(
    @Param('subjectId') subjectId: string,
    @CurrentUser() user: JwtPayloadUser,
    @Query('topicId') topicId?: string,
    @Query('search') search?: string,
    @Query('pastPapersOnly') pastPapersOnly?: string,
  ) {
    return this.contentService.listMaterials(subjectId, user, {
      topicId,
      search,
      pastPapersOnly: pastPapersOnly === 'true',
    });
  }

  @Get('materials/:id/access')
  @ApiOperation({ summary: 'Get presigned URL or stream URL for material' })
  getAccess(@Param('id') id: string, @CurrentUser() user: JwtPayloadUser) {
    return this.contentService.getMaterialAccess(id, user);
  }

  @Get('materials/:id/stream')
  @ApiOperation({ summary: 'Stream material file (local dev storage mode)' })
  async stream(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayloadUser,
    @Res({ passthrough: true }) res: Response,
  ) {
    const { stream, contentType, filename } = await this.contentService.streamMaterial(id, user);
    res.set({
      'Content-Type': contentType,
      'Content-Disposition': `inline; filename="${filename}.pdf"`,
    });
    return new StreamableFile(stream);
  }

  @Post('bookmarks/:materialId')
  @ApiOperation({ summary: 'Bookmark a material' })
  addBookmark(@Param('materialId') materialId: string, @CurrentUser() user: JwtPayloadUser) {
    return this.contentService.addBookmark(user.sub, materialId);
  }

  @Delete('bookmarks/:materialId')
  @ApiOperation({ summary: 'Remove bookmark' })
  removeBookmark(@Param('materialId') materialId: string, @CurrentUser() user: JwtPayloadUser) {
    return this.contentService.removeBookmark(user.sub, materialId);
  }

  @Get('bookmarks')
  @ApiOperation({ summary: 'List bookmarked materials' })
  listBookmarks(@CurrentUser() user: JwtPayloadUser) {
    return this.contentService.listBookmarks(user.sub);
  }
}
