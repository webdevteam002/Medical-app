import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { aiConfigFrom } from './ai.config';
import { clampAiConfig, validateAiConfig } from './ai-config.validation';

/**
 * AI-7/8 bootstrap: validate AI env at process start.
 * Refuses to start in production when AI is enabled without a key / with dim mismatch.
 */
@Injectable()
export class AiBootstrapService implements OnModuleInit {
  private readonly logger = new Logger(AiBootstrapService.name);

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    const raw = aiConfigFrom(this.config);
    const cfg = clampAiConfig(raw);
    const nodeEnv = String(this.config.get('NODE_ENV') ?? 'development');
    const issues = validateAiConfig(cfg, { nodeEnv });

    for (const issue of issues) {
      if (issue.severity === 'error') {
        this.logger.error(`AI config: ${issue.code} — ${issue.message}`);
      } else {
        this.logger.warn(`AI config: ${issue.code} — ${issue.message}`);
      }
    }

    const fatal = issues.filter((i) => i.severity === 'error');
    if (fatal.length > 0 && nodeEnv.toLowerCase() === 'production') {
      throw new Error(
        `AI configuration invalid for production: ${fatal.map((f) => f.code).join(', ')}`,
      );
    }

    this.logger.log(
      `AI bootstrap enabled=${cfg.enabled} rag=${cfg.rag.enabled} providerReady=${Boolean(
        cfg.enabled && cfg.geminiApiKeys.length > 0,
      )} keyPool=${cfg.geminiApiKeys.length} cooldownMs=${cfg.geminiKeyCooldownMs} embedDims=${cfg.rag.embeddingDimensions}`,
    );
  }
}
