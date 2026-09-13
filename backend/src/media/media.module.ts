import { Module } from '@nestjs/common';
import { StorageModule } from '../storage/storage.module';
import { QuestionMediaService } from './question-media.service';
import {
  AdminQuestionImagesController,
  MediaController,
} from './media.controller';

@Module({
  imports: [StorageModule],
  controllers: [MediaController, AdminQuestionImagesController],
  providers: [QuestionMediaService],
  exports: [QuestionMediaService],
})
export class MediaModule {}
