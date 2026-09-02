import { Module } from '@nestjs/common';
import { ExamsService } from './exams.service';
import { ExamsController } from './exams.controller';
import { AdminExamsController } from './admin-exams.controller';

@Module({
  controllers: [ExamsController, AdminExamsController],
  providers: [ExamsService],
  exports: [ExamsService],
})
export class ExamsModule {}
