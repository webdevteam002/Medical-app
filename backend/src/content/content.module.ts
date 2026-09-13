import { Module } from '@nestjs/common';
import { ContentService } from './content.service';
import { ContentController } from './content.controller';
import { AdminContentController } from './admin-content.controller';

import { StorageModule } from '../storage/storage.module';

@Module({
  imports: [StorageModule],
  controllers: [ContentController, AdminContentController],
  providers: [ContentService],
  exports: [ContentService],
})
export class ContentModule {}
