import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiHeader,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { UserRole } from '@prisma/client';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceSessionGuard } from '../common/guards/device-session.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import {
  CurrentUser,
  JwtPayloadUser,
} from '../common/decorators/current-user.decorator';
import { RagService } from './rag/rag.service';
import { AiVerifyQuestionService } from './verification/ai-verify-question.service';
import {
  DecideVerificationDto,
  VerifyQuestionDto,
} from './dto/ai-verify.dto';

/**
 * Admin-only AI control plane (RAG reindex + AI-5 verification).
 * Students cannot reach these routes (RolesGuard).
 */
@ApiTags('admin-ai')
@ApiBearerAuth()
@ApiHeader({ name: 'X-Device-Id', required: true })
@UseGuards(JwtAuthGuard, DeviceSessionGuard, RolesGuard, ThrottlerGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@Controller('admin/ai')
export class AdminAiController {
  constructor(
    private readonly rag: RagService,
    private readonly verifyService: AiVerifyQuestionService,
  ) {}

  @Post('materials/:id/reindex')
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @ApiOperation({
    summary:
      'Reindex a published PDF material for RAG (requires aiIngestAllowed=true)',
  })
  reindex(@Param('id') id: string) {
    return this.rag.reindexMaterial(id);
  }

  @Post('verify-question')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({
    summary:
      'Run advisory AI verification on an MCQ (does not modify the question)',
  })
  verifyQuestion(
    @CurrentUser() user: JwtPayloadUser,
    @Body() dto: VerifyQuestionDto,
  ) {
    return this.verifyService.verify(user, dto.questionId);
  }

  @Get('verifications')
  @Throttle({ default: { limit: 40, ttl: 60000 } })
  @ApiOperation({ summary: 'List AI MCQ verification records' })
  listVerifications(
    @CurrentUser() user: JwtPayloadUser,
    @Query('status') status?: string,
    @Query('issueType') issueType?: string,
    @Query('questionId') questionId?: string,
    @Query('subjectId') subjectId?: string,
    @Query('yearSlug') yearSlug?: string,
    @Query('take') take?: string,
    @Query('skip') skip?: string,
  ) {
    return this.verifyService.list(user, {
      status,
      issueType,
      questionId,
      subjectId,
      yearSlug,
      take: take ? Number.parseInt(take, 10) : undefined,
      skip: skip ? Number.parseInt(skip, 10) : undefined,
    });
  }

  @Get('verifications/:id')
  @Throttle({ default: { limit: 40, ttl: 60000 } })
  @ApiOperation({ summary: 'Get one AI MCQ verification record' })
  getVerification(
    @CurrentUser() user: JwtPayloadUser,
    @Param('id') id: string,
  ) {
    return this.verifyService.getById(user, id);
  }

  @Post('verifications/:id/decide')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({
    summary:
      'Approve or reject the AI REVIEW (never mutates Question / official key)',
  })
  decideVerification(
    @CurrentUser() user: JwtPayloadUser,
    @Param('id') id: string,
    @Body() dto: DecideVerificationDto,
  ) {
    return this.verifyService.decide(user, id, dto);
  }
}
