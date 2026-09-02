import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  GetObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { createReadStream, existsSync, mkdirSync, readFileSync, unlinkSync, writeFileSync } from 'fs';
import { join, dirname } from 'path';
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

  async upload(key: string, buffer: Buffer, contentType: string): Promise<void> {
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
}
