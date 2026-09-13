import { createHmac, timingSafeEqual } from 'crypto';
import { basename } from 'path';
import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { StorageService } from '../storage/storage.service';

const IMAGE_EXT = /\.(jpe?g|png|gif|webp|bmp|svg)$/i;

@Injectable()
export class QuestionMediaService implements OnModuleInit {
  private readonly logger = new Logger(QuestionMediaService.name);
  private basenameIndex = new Map<string, string>();
  private indexBuiltAt = 0;

  constructor(
    private storage: StorageService,
    private config: ConfigService,
  ) {}

  onModuleInit() {
    this.refreshIndex();
  }

  refreshIndex() {
    this.basenameIndex = this.storage.buildLocalBasenameIndex('images');
    this.indexBuiltAt = Date.now();
    this.logger.log(
      `Question image index ready: ${this.basenameIndex.size} files under uploads/images`,
    );
  }

  getIndexStats() {
    return {
      storageMode: this.storage.getMode(),
      indexedFiles: this.basenameIndex.size,
      indexedAt: this.indexBuiltAt ? new Date(this.indexBuiltAt).toISOString() : null,
    };
  }

  /** Resolve a CSV/HTML filename or relative key to a storage object key. */
  async resolveStorageKey(raw: string | null | undefined): Promise<string | null> {
    if (!raw?.trim()) return null;
    let value = raw.trim().replace(/\\/g, '/');

    // Strip accidental absolute/local paths and query strings.
    value = value.split('?')[0].split('#')[0];
    if (/^https?:\/\//i.test(value)) {
      try {
        value = basename(new URL(value).pathname);
      } catch {
        value = basename(value);
      }
    }
    value = value.replace(/^(\.\/|\/)+/, '');
    if (value.startsWith('content/images/')) {
      value = value.slice('content/'.length);
    }

    const base = basename(value);
    const candidates = [
      value,
      value.startsWith('images/') ? value : `images/${value}`,
      `images/${base}`,
      `images/uworld/${base}`,
      `images/amboss/${base}`,
      `images/usmle-rx/${base}`,
      `images/usmlerx/${base}`,
    ];

    for (const key of candidates) {
      if (await this.storage.exists(key)) {
        return key;
      }
    }

    const indexed = this.basenameIndex.get(basename(value).toLowerCase());
    if (indexed && (await this.storage.exists(indexed))) {
      return indexed;
    }

    // Rebuild once if index may be stale after a bulk sync.
    if (Date.now() - this.indexBuiltAt > 5_000) {
      this.refreshIndex();
      const again = this.basenameIndex.get(basename(value).toLowerCase());
      if (again && (await this.storage.exists(again))) {
        return again;
      }
    }

    return null;
  }

  buildSignedMediaUrl(storageKey: string, ttlSeconds = 6 * 60 * 60): string {
    const exp = Math.floor(Date.now() / 1000) + ttlSeconds;
    const sig = this.sign(storageKey, exp);
    const publicBase = this.config
      .get<string>('PUBLIC_API_BASE_URL')
      ?.trim()
      .replace(/\/$/, '');
    const prefix = this.config.get<string>('API_PREFIX', 'v1');
    const port = this.config.get<number>('PORT', 3000);
    const base = publicBase || `http://localhost:${port}/${prefix}`;
    const params = new URLSearchParams({
      key: storageKey,
      exp: String(exp),
      sig,
    });
    return `${base}/media/question-images?${params.toString()}`;
  }

  verifySignedRequest(key: string, expRaw: string, sig: string) {
    const exp = Number(expRaw);
    if (!key || !sig || !Number.isFinite(exp)) {
      throw new UnauthorizedException({
        code: 'INVALID_SIGNATURE',
        message: 'Invalid media signature',
      });
    }
    if (exp < Math.floor(Date.now() / 1000)) {
      throw new UnauthorizedException({
        code: 'URL_EXPIRED',
        message: 'Media URL expired',
      });
    }
    const expected = this.sign(key, exp);
    const a = Buffer.from(expected);
    const b = Buffer.from(sig);
    if (a.length !== b.length || !timingSafeEqual(a, b)) {
      throw new UnauthorizedException({
        code: 'INVALID_SIGNATURE',
        message: 'Invalid media signature',
      });
    }
  }

  async enrichQuestionMedia(input: {
    stem: string;
    explanation?: string | null;
    imageKey?: string | null;
  }) {
    const stemRefs = this.extractImgSrcs(input.stem);
    const explanationRefs = this.extractImgSrcs(input.explanation || '');
    const allRefs = [
      ...(input.imageKey ? [input.imageKey] : []),
      ...stemRefs,
      ...explanationRefs,
    ];

    const urlByRef = new Map<string, string>();
    for (const ref of allRefs) {
      if (urlByRef.has(ref)) continue;
      const storageKey = await this.resolveStorageKey(ref);
      if (!storageKey) continue;
      urlByRef.set(ref, this.buildSignedMediaUrl(storageKey));
    }

    let imageUrl: string | null = null;
    if (input.imageKey) {
      imageUrl = urlByRef.get(input.imageKey) ?? null;
      if (!imageUrl) {
        const key = await this.resolveStorageKey(input.imageKey);
        if (key) imageUrl = this.buildSignedMediaUrl(key);
      }
    }

    // If stem has no <img> but imageKey resolved, inject once above content.
    let stem = this.rewriteHtmlImgs(input.stem, urlByRef);
    if (imageUrl && !/<img[\s>]/i.test(stem)) {
      stem = `<p><img src="${imageUrl}" alt="Question figure" /></p>${stem}`;
    }

    const explanation = input.explanation
      ? this.rewriteHtmlImgs(input.explanation, urlByRef)
      : input.explanation;

    return {
      stem,
      explanation,
      imageKey: input.imageKey ?? null,
      imageUrl,
    };
  }

  async streamBySignedQuery(key: string, exp: string, sig: string) {
    this.verifySignedRequest(key, exp, sig);
    const resolved = (await this.resolveStorageKey(key)) || key;
    if (!(await this.storage.exists(resolved))) {
      throw new NotFoundException({
        code: 'NOT_FOUND',
        message: 'Question image not found',
      });
    }
    return this.storage.openReadStream(resolved);
  }

  async uploadImages(
    files: Express.Multer.File[],
    folder?: string,
  ): Promise<{
    uploaded: number;
    keys: string[];
    storage: 'r2' | 'local';
    destinationPrefix: string;
  }> {
    if (!files?.length) {
      throw new BadRequestException({
        code: 'NO_FILES',
        message: 'At least one image file is required',
      });
    }

    const safeFolder = (folder || '')
      .trim()
      .replace(/\\/g, '/')
      .replace(/^\/+|\/+$/g, '')
      .replace(/\.\./g, '');

    const keys: string[] = [];
    for (const file of files) {
      const original = basename(file.originalname || 'image.bin');
      if (!IMAGE_EXT.test(original)) {
        continue;
      }
      const key = safeFolder
        ? `images/${safeFolder}/${original}`
        : `images/${original}`;
      await this.storage.upload(
        key,
        file.buffer,
        file.mimetype || this.storage.guessContentType(original),
      );
      keys.push(key);
    }

    this.refreshIndex();
    return {
      uploaded: keys.length,
      keys,
      storage: this.storage.getMode(),
      destinationPrefix: safeFolder ? `images/${safeFolder}/` : 'images/',
    };
  }

  extractImgSrcs(html: string): string[] {
    if (!html) return [];
    const out: string[] = [];
    const re = /<img\b[^>]*\bsrc\s*=\s*(["'])(.*?)\1/gi;
    let match: RegExpExecArray | null;
    while ((match = re.exec(html))) {
      const src = match[2]?.trim();
      if (src) out.push(src);
    }
    return out;
  }

  rewriteHtmlImgs(html: string, urlByRef: Map<string, string>): string {
    if (!html || urlByRef.size === 0) return html;
    return html.replace(
      /(<img\b[^>]*\bsrc\s*=\s*)(["'])(.*?)\2/gi,
      (full, prefix: string, quote: string, src: string) => {
        const mapped =
          urlByRef.get(src) ||
          urlByRef.get(basename(src)) ||
          [...urlByRef.entries()].find(
            ([k]) => basename(k).toLowerCase() === basename(src).toLowerCase(),
          )?.[1];
        if (!mapped) return full;
        return `${prefix}${quote}${mapped}${quote}`;
      },
    );
  }

  private sign(key: string, exp: number): string {
    const secret =
      this.config.get<string>('JWT_SECRET') ||
      this.config.get<string>('MEDIA_SIGNING_SECRET') ||
      'dev-media-secret';
    return createHmac('sha256', secret)
      .update(`${key}:${exp}`)
      .digest('hex');
  }
}
