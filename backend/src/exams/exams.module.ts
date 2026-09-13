import { Module } from '@nestjs/common';
import { ExamsService } from './exams.service';
import { ExamsController } from './exams.controller';
import { AdminExamsController } from './admin-exams.controller';
import { GeminiGradingService } from './gemini-grading.service';
import { AiModule } from '../ai/ai.module';

@Module({
  imports: [AiModule],
  controllers: [ExamsController, AdminExamsController],
  providers: [ExamsService, GeminiGradingService],
  exports: [ExamsService],
})
export class ExamsModule {}
