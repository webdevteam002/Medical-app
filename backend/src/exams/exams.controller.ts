import { Controller, Get, Post, Param, Query, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiHeader, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { ExamsService } from './exams.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceSessionGuard } from '../common/guards/device-session.guard';
import { CurrentUser, JwtPayloadUser } from '../common/decorators/current-user.decorator';
import { SubmitExamDto } from './dto/exams.dto';

@ApiTags('exams')
@ApiBearerAuth()
@ApiHeader({ name: 'X-Device-Id', required: true })
@UseGuards(JwtAuthGuard, DeviceSessionGuard)
@Controller()
export class ExamsController {
  constructor(private examsService: ExamsService) {}

  @Get('exams')
  @ApiOperation({ summary: 'List published exams' })
  @ApiQuery({ name: 'yearSlug', required: false })
  @ApiQuery({ name: 'subjectId', required: false })
  listExams(
    @CurrentUser() user: JwtPayloadUser,
    @Query('yearSlug') yearSlug?: string,
    @Query('subjectId') subjectId?: string,
  ) {
    return this.examsService.listExams(user, { yearSlug, subjectId });
  }

  @Post('exams/:id/start')
  @ApiOperation({ summary: 'Start exam attempt' })
  startExam(@Param('id') id: string, @CurrentUser() user: JwtPayloadUser) {
    return this.examsService.startExam(id, user);
  }

  @Post('exams/attempts/:attemptId/submit')
  @ApiOperation({ summary: 'Submit exam answers for grading' })
  submit(
    @Param('attemptId') attemptId: string,
    @CurrentUser() user: JwtPayloadUser,
    @Body() dto: SubmitExamDto,
  ) {
    return this.examsService.submitExam(attemptId, user, dto);
  }

  @Get('exams/attempts')
  @ApiOperation({ summary: 'Exam attempt history' })
  listAttempts(@CurrentUser() user: JwtPayloadUser) {
    return this.examsService.listAttempts(user);
  }

  @Get('exams/attempts/:attemptId')
  @ApiOperation({ summary: 'Review past attempt with explanations' })
  review(@Param('attemptId') attemptId: string, @CurrentUser() user: JwtPayloadUser) {
    return this.examsService.getAttemptReview(attemptId, user);
  }
}
