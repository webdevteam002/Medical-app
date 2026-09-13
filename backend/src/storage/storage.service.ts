import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
  HeadObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import {
  createReadStream,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  statSync,
  unlinkSync,
  writeFileSync,
} from 'fs';
import { join, dirname, basename, extname } from 'path';
import { Readable } from 'stream';

export type StorageMode = 'r2' | 'local';

@Injectable()
export class StorageService implements OnModuleInit {
  private readonly logger = new Logger(StorageService.name);
  private mode: StorageMode = 'local';
  private s3?: S3Client;
  private bucket?: string;
  private localRoot: string;

  constructor(private config: ConfigService) {
    this.localRoot = join(process.cwd(), 'uploads');
  }

  onModuleInit() {
    const accountId = this.config.get<string>('R2_ACCOUNT_ID');
    const accessKey = this.config.get<string>('R2_ACCESS_KEY_ID');
    const secretKey = this.config.get<string>('R2_SECRET_ACCESS_KEY');
    this.bucket = this.config.get<string>('R2_BUCKET_NAME', 'medstudy-pdfs');

    if (accountId && accessKey && secretKey) {
      this.mode = 'r2';
      this.s3 = new S3Client({
        region: 'auto',
        endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
        credentials: {
          accessKeyId: accessKey,
          secretAccessKey: secretKey,
        },
      });
      this.logger.log('Storage: Cloudflare R2 enabled');
    } else {
      if (!existsSync(this.localRoot)) {
        mkdirSync(this.localRoot, { recursive: true });
      }
      this.logger.warn(
        'Storage: R2 credentials missing — using local uploads/ folder (dev only)',
      );
    }
  }

  getMode(): StorageMode {
    return this.mode;
  }

  getLocalRoot(): string {
    return this.localRoot;
  }

  async upload(key: string, buffer: Buffer, contentType: string): Promise<void> {
    if (this.mode !== 'r2') {
      const nodeEnv = this.config.get<string>('NODE_ENV', 'development');
      if (nodeEnv === 'production') {
        throw new Error(
          'R2 storage is required in production. Set R2_ACCOUNT_ID / R2_ACCESS_KEY_ID / R2_SECRET_ACCESS_KEY / R2_BUCKET_NAME.',
        );
      }
    }

    if (this.mode === 'r2' && this.s3 && this.bucket) {
      await this.s3.send(
        new PutObjectCommand({
          Bucket: this.bucket,
          Key: key,
          Body: buffer,
          ContentType: contentType,
        }),
      );
      return;
    }

    const filePath = join(this.localRoot, key);
    const dir = dirname(filePath);
    if (!existsSync(dir)) {
      mkdirSync(dir, { recursive: true });
    }
    writeFileSync(filePath, buffer);
  }

  async delete(key: string): Promise<void> {
    if (this.mode === 'r2' && this.s3 && this.bucket) {
      await this.s3.send(
        new DeleteObjectCommand({
          Bucket: this.bucket,
          Key: key,
        }),
      );
      return;
    }

    const filePath = join(this.localRoot, key);
    if (existsSync(filePath)) {
      unlinkSync(filePath);
    }
  }

  async exists(key: string): Promise<boolean> {
    if (this.mode === 'r2' && this.s3 && this.bucket) {
      try {
        await this.s3.send(
          new HeadObjectCommand({ Bucket: this.bucket, Key: key }),
        );
        return true;
      } catch {
        return false;
      }
    }
    return this.localFileExists(key);
  }

  async getPresignedUrl(key: string, expiresInSeconds = 900): Promise<string> {
    if (this.mode === 'r2' && this.s3 && this.bucket) {
      return getSignedUrl(
        this.s3,
        new GetObjectCommand({ Bucket: this.bucket, Key: key }),
        { expiresIn: expiresInSeconds },
      );
    }

    throw new Error('Presigned URLs require R2. Use stream endpoint in local mode.');
  }

  async downloadBuffer(key: string): Promise<Buffer> {
    if (this.mode === 'r2' && this.s3 && this.bucket) {
      const result = await this.s3.send(
        new GetObjectCommand({ Bucket: this.bucket, Key: key }),
      );
      if (!result.Body) {
        throw new Error(`Empty object body for key: ${key}`);
      }
      return Buffer.from(await result.Body.transformToByteArray());
    }
    return this.readLocalFile(key);
  }

  async openReadStream(key: string): Promise<{
    stream: Readable;
    contentType: string;
    contentLength?: number;
  }> {
    const contentType = this.guessContentType(key);
    if (this.mode === 'r2' && this.s3 && this.bucket) {
      const result = await this.s3.send(
        new GetObjectCommand({ Bucket: this.bucket, Key: key }),
      );
      if (!result.Body) {
        throw new Error(`Empty object body for key: ${key}`);
      }
      return {
        stream: result.Body as Readable,
        contentType: result.ContentType || contentType,
        contentLength: result.ContentLength,
      };
    }

    const filePath = join(this.localRoot, key);
    if (!existsSync(filePath)) {
      throw new Error(`File not found: ${key}`);
    }
    const st = statSync(filePath);
    return {
      stream: createReadStream(filePath),
      contentType,
      contentLength: st.size,
    };
  }

  readLocalFile(key: string): Buffer {
    const filePath = join(this.localRoot, key);
    if (!existsSync(filePath)) {
      throw new Error(`File not found: ${key}`);
    }
    return readFileSync(filePath);
  }

  createLocalReadStream(key: string): Readable {
    const filePath = join(this.localRoot, key);
    if (!existsSync(filePath)) {
      throw new Error(`File not found: ${key}`);
    }
    return createReadStream(filePath);
  }

  localFileExists(key: string): boolean {
    return existsSync(join(this.localRoot, key));
  }

  buildLocalBasenameIndex(prefix = 'images'): Map<string, string> {
    const index = new Map<string, string>();
    const root = join(this.localRoot, prefix);
    if (!existsSync(root)) {
      return index;
    }

    const walk = (dir: string, rel: string) => {
      for (const entry of readdirSync(dir)) {
        const abs = join(dir, entry);
        const childRel = rel ? `${rel}/${entry}` : entry;
        const st = statSync(abs);
        if (st.isDirectory()) {
          walk(abs, childRel);
          continue;
        }
        const name = basename(entry).toLowerCase();
        if (!index.has(name)) {
          index.set(name, `${prefix}/${childRel}`.replace(/\\/g, '/'));
        }
      }
    };
    walk(root, '');
    return index;
  }

  guessContentType(key: string): string {
    const ext = extname(key).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
