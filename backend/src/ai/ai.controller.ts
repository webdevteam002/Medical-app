import {
  Body,
  Controller,
  Delete,
  Get,
  Inject,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiHeader,
  ApiOperation,
  ApiTags,
} from '@nestjs/swagger';
import { Throttle, ThrottlerGuard } from '@nestjs/throttler';
import { ConfigService } from '@nestjs/config';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { DeviceSessionGuard } from '../common/guards/device-session.guard';
import {
  CurrentUser,
  JwtPayloadUser,
} from '../common/decorators/current-user.decorator';
import { ExplainMcqDto } from './dto/explain-mcq.dto';
import { AiChatDto } from './dto/ai-chat.dto';
import { McqExplainService } from './mcq-explain.service';
import { AiChatService } from './assistant/ai-chat.service';
import { aiConfigFrom } from './ai.config';
import { AI_PROVIDER, AiProvider } from './providers/ai-provider';

@ApiTags('ai')
@ApiBearerAuth()
@ApiHeader({ name: 'X-Device-Id', required: true })
@UseGuards(JwtAuthGuard, DeviceSessionGuard, ThrottlerGuard)
@Controller('ai')
export class AiController {
  constructor(
    private readonly mcqExplain: McqExplainService,
    private readonly chatService: AiChatService,
    private readonly config: ConfigService,
    @Inject(AI_PROVIDER) private readonly aiProvider: AiProvider,
  ) {}

  @Get('health')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'AI module health / dry-run readiness (no Gemini call)' })
  health() {
    const cfg = aiConfigFrom(this.config);
    return {
      enabled: cfg.enabled,
      provider: cfg.provider,
      modelConfigured: Boolean(cfg.geminiModel),
      /** True when enabled + API key present — never returns the key. */
      apiKeyConfigured: Boolean(cfg.geminiApiKey),
      providerReady: this.aiProvider.isReady(),
      dailyExplanationLimit: cfg.dailyExplanationLimit,
      dailyChatLimit: cfg.dailyChatLimit,
      dailyAdminVerifyLimit: cfg.dailyAdminVerifyLimit,
      timeoutMs: cfg.timeoutMs,
      maxOutputTokens: cfg.maxOutputTokens,
      rag: {
        enabled: cfg.rag.enabled,
        embeddingModel: cfg.rag.embeddingModel,
        embeddingDimensions: cfg.rag.embeddingDimensions,
        topK: cfg.rag.topK,
      },
    };
  }

  @Post('explain-mcq')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'Generate structured AI explanation for an MCQ' })
  explainMcq(@CurrentUser() user: JwtPayloadUser, @Body() dto: ExplainMcqDto) {
    return this.mcqExplain.explain(user, dto);
  }

  @Post('chat')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'Student AI assistant chat turn' })
  chat(@CurrentUser() user: JwtPayloadUser, @Body() dto: AiChatDto) {
    return this.chatService.chat(user, dto);
  }

  @Get('conversations')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'List own AI conversations' })
  listConversations(@CurrentUser() user: JwtPayloadUser) {
    return this.chatService.listConversations(user.sub);
  }

  @Get('conversations/:id')
  @Throttle({ default: { limit: 30, ttl: 60000 } })
  @ApiOperation({ summary: 'Get own AI conversation with messages' })
  getConversation(
    @CurrentUser() user: JwtPayloadUser,
    @Param('id') id: string,
  ) {
    return this.chatService.getConversation(user.sub, id);
  }

  @Delete('conversations/:id')
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: 'Delete own AI conversation' })
  deleteConversation(
    @CurrentUser() user: JwtPayloadUser,
    @Param('id') id: string,
  ) {
    return this.chatService.deleteConversation(user.sub, id);
  }
}
