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
} from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { ExamsService } from './exams.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceSessionGuard } from '../common/guards/device-session.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import {
  AddExamQuestionsDto,
  CreateExamDto,
  CreateQuestionDto,
  ImportQuestionsDto,
  UpdateExamDto,
  UpdateQuestionDto,
} from './dto/exams.dto';

@ApiTags('admin-exams')
@ApiBearerAuth()
@ApiHeader({ name: 'X-Device-Id', required: true })
@UseGuards(JwtAuthGuard, DeviceSessionGuard, RolesGuard)
@Roles(UserRole.ADMIN, UserRole.SUPER_ADMIN)
@Controller('admin')
export class AdminExamsController {
  constructor(private examsService: ExamsService) {}

  // Questions
  @Get('questions')
  @ApiOperation({ summary: 'List questions' })
  listQuestions(@Query('subjectId') subjectId?: string) {
    return this.examsService.listQuestions(subjectId);
  }

  @Post('questions')
  @ApiOperation({ summary: 'Create question' })
  createQuestion(@Body() dto: CreateQuestionDto) {
    return this.examsService.createQuestion(dto);
  }

  @Patch('questions/:id')
  @ApiOperation({ summary: 'Update question' })
  updateQuestion(@Param('id') id: string, @Body() dto: UpdateQuestionDto) {
    return this.examsService.updateQuestion(id, dto);
  }

  @Delete('questions/:id')
  @ApiOperation({ summary: 'Delete question' })
  deleteQuestion(@Param('id') id: string) {
    return this.examsService.deleteQuestion(id);
  }

  @Post('questions/import')
  @ApiOperation({ summary: 'Import questions from CSV file' })
  @ApiConsumes('multipart/form-data')
  @UseInterceptors(FileInterceptor('file'))
  importCsv(
    @UploadedFile() file: Express.Multer.File,
    @Body() dto: ImportQuestionsDto,
  ) {
    const content = file.buffer.toString('utf-8');
    return this.examsService.importQuestionsCsv(dto.subjectId, content, dto.dryRun ?? false);
  }

  // Exams
  @Get('exams')
  @ApiOperation({ summary: 'List all exams' })
  listExams(@Query('subjectId') subjectId?: string) {
    return this.examsService.listAllExams(subjectId);
  }

  @Post('exams')
  @ApiOperation({ summary: 'Create exam' })
  createExam(@Body() dto: CreateExamDto) {
    return this.examsService.createExam(dto);
  }

  @Patch('exams/:id')
  @ApiOperation({ summary: 'Update exam' })
  updateExam(@Param('id') id: string, @Body() dto: UpdateExamDto) {
    return this.examsService.updateExam(id, dto);
  }

  @Delete('exams/:id')
  @ApiOperation({ summary: 'Delete exam' })
  deleteExam(@Param('id') id: string) {
    return this.examsService.deleteExam(id);
  }

  @Post('exams/:id/questions')
  @ApiOperation({ summary: 'Set exam questions' })
  setQuestions(@Param('id') id: string, @Body() dto: AddExamQuestionsDto) {
    return this.examsService.setExamQuestions(id, dto.questionIds);
  }

  @Get('exams/:id/analytics')
  @ApiOperation({ summary: 'Exam attempt analytics' })
  analytics(@Param('id') id: string) {
    return this.examsService.getExamAnalytics(id);
  }
}
