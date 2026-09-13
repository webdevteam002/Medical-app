import { Module } from '@nestjs/common';
import { ExamsService } from './exams.service';
import { ExamsController } from './exams.controller';
import { AdminExamsController } from './admin-exams.controller';
import { GeminiGradingService } from './gemini-grading.service';
import { AiModule } from '../ai/ai.module';
import { MediaModule } from '../media/media.module';
import { StorageModule } from '../storage/storage.module';

@Module({
  imports: [AiModule, MediaModule, StorageModule],
  controllers: [ExamsController, AdminExamsController],
  providers: [ExamsService, GeminiGradingService],
  exports: [ExamsService],
})
export class ExamsModule {}
