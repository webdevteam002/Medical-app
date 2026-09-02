import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { JwtPayloadUser } from '../common/decorators/current-user.decorator';
import {
  CreateSubjectDto,
  CreateTopicDto,
  CreateYearDto,
  UpdateMaterialDto,
} from './dto/content.dto';
import { randomUUID } from 'crypto';

@Injectable()
export class ContentService {
  constructor(
    private prisma: PrismaService,
    private storage: StorageService,
    private subscriptions: SubscriptionsService,
    private config: ConfigService,
  ) {}

  // ─── Student ───────────────────────────────────────────────

  async listYears(user: JwtPayloadUser) {
    const accessible = await this.subscriptions.getAccessibleYearSlugs(
      user.sub,
      user.role as UserRole,
    );

    return this.prisma.year.findMany({
      where: { slug: { in: accessible } },
      orderBy: { sortOrder: 'asc' },
      select: { id: true, name: true, slug: true, sortOrder: true },
    });
  }

  async listSubjects(yearSlug: string, user: JwtPayloadUser) {
    await this.assertYearAccess(user, yearSlug);

    const year = await this.prisma.year.findUnique({ where: { slug: yearSlug } });
    if (!year) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Year not found' });
    }

    return this.prisma.subject.findMany({
      where: { yearId: year.id },
      orderBy: { sortOrder: 'asc' },
      select: { id: true, name: true, slug: true, sortOrder: true, yearId: true },
    });
  }

  async listMaterials(
    subjectId: string,
    user: JwtPayloadUser,
    opts: { topicId?: string; search?: string; pastPapersOnly?: boolean },
  ) {
    const subject = await this.getSubjectWithYear(subjectId);
    await this.assertYearAccess(user, subject.year.slug);

    const where: Record<string, unknown> = {
      subjectId,
      isPublished: true,
    };
    if (opts.topicId) where.topicId = opts.topicId;
    if (opts.pastPapersOnly) where.isPastPaper = true;
    if (opts.search) {
      where.title = { contains: opts.search, mode: 'insensitive' };
    }

    const materials = await this.prisma.material.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        title: true,
        type: true,
        isDownloadable: true,
        isPastPaper: true,
        pastPaperYear: true,
        pastPaperSession: true,
        fileSizeBytes: true,
        topicId: true,
        createdAt: true,
      },
    });

    return materials.map((m) => ({
      ...m,
      fileSizeBytes: m.fileSizeBytes.toString(),
    }));
  }

  async getMaterialAccess(materialId: string, user: JwtPayloadUser) {
    const material = await this.getPublishedMaterial(materialId);
    const subject = await this.getSubjectWithYear(material.subjectId);
    await this.assertYearAccess(user, subject.year.slug);

    const userRecord = await this.prisma.user.findUnique({
      where: { id: user.sub },
      select: { email: true, id: true },
    });

    const watermark = `${userRecord?.email ?? user.email} · ID:${user.sub.slice(0, 8)}`;
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    if (this.storage.getMode() === 'r2') {
      const url = await this.storage.getPresignedUrl(material.fileKey, 900);
      return { url, expiresAt, watermark };
    }

    const port = this.config.get<number>('PORT', 3000);
    const prefix = this.config.get<string>('API_PREFIX', 'v1');
    const url = `http://localhost:${port}/${prefix}/materials/${materialId}/stream`;

    return { url, expiresAt, watermark };
  }

  async streamMaterial(materialId: string, user: JwtPayloadUser) {
    const material = await this.getPublishedMaterial(materialId);
    const subject = await this.getSubjectWithYear(material.subjectId);
    await this.assertYearAccess(user, subject.year.slug);

    if (!this.storage.localFileExists(material.fileKey)) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'File not found on server' });
    }

    return {
      stream: this.storage.createLocalReadStream(material.fileKey),
      contentType: material.type === 'PDF' ? 'application/pdf' : 'application/octet-stream',
      filename: material.title,
    };
  }

  // ─── Admin ─────────────────────────────────────────────────

  createYear(dto: CreateYearDto) {
    return this.prisma.year.create({ data: dto });
  }

  listAllYears() {
    return this.prisma.year.findMany({ orderBy: { sortOrder: 'asc' } });
  }

  createSubject(dto: CreateSubjectDto) {
    return this.prisma.subject.create({ data: dto });
  }

  listAllSubjects(yearId?: string) {
    return this.prisma.subject.findMany({
      where: yearId ? { yearId } : undefined,
      orderBy: { sortOrder: 'asc' },
      include: { year: { select: { name: true, slug: true } } },
    });
  }

  createTopic(dto: CreateTopicDto) {
    return this.prisma.topic.create({ data: dto });
  }

  listTopics(subjectId: string) {
    return this.prisma.topic.findMany({
      where: { subjectId },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async uploadMaterial(
    file: Express.Multer.File,
    meta: {
      subjectId: string;
      topicId?: string;
      title: string;
      type?: string;
      isDownloadable?: boolean;
      isPastPaper?: boolean;
      pastPaperYear?: number;
      pastPaperSession?: string;
    },
  ) {
    if (!file) {
      throw new BadRequestException({ code: 'INVALID_FILE', message: 'File is required' });
    }

    const subject = await this.getSubjectWithYear(meta.subjectId);
    const ext = file.originalname.split('.').pop()?.toLowerCase() ?? 'bin';
    const fileKey = `materials/${subject.year.slug}/${subject.slug}/${randomUUID()}.${ext}`;

    await this.storage.upload(fileKey, file.buffer, file.mimetype);

    return this.prisma.material.create({
      data: {
        subjectId: meta.subjectId,
        topicId: meta.topicId,
        title: meta.title,
        type: meta.type === 'VIDEO' ? 'VIDEO' : meta.type === 'NOTES' ? 'NOTES' : 'PDF',
        fileKey,
        fileSizeBytes: BigInt(file.size),
        isDownloadable: meta.isDownloadable ?? true,
        isPastPaper: meta.isPastPaper ?? false,
        pastPaperYear: meta.pastPaperYear,
        pastPaperSession: meta.pastPaperSession,
        isPublished: false,
      },
    }).then((m) => ({ ...m, fileSizeBytes: m.fileSizeBytes.toString() }));
  }

  async updateMaterial(id: string, dto: UpdateMaterialDto) {
    const material = await this.prisma.material.findUnique({ where: { id } });
    if (!material) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Material not found' });
    }

    const updated = await this.prisma.material.update({ where: { id }, data: dto });
    return { ...updated, fileSizeBytes: updated.fileSizeBytes.toString() };
  }

  async deleteMaterial(id: string) {
    const material = await this.prisma.material.findUnique({ where: { id } });
    if (!material) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Material not found' });
    }

    await this.storage.delete(material.fileKey);
    await this.prisma.material.delete({ where: { id } });
    return { success: true };
  }

  listAllMaterials(subjectId?: string) {
    return this.prisma.material.findMany({
      where: subjectId ? { subjectId } : undefined,
      orderBy: { createdAt: 'desc' },
      include: {
        subject: { select: { name: true, slug: true, year: { select: { slug: true } } } },
      },
    }).then((rows) =>
      rows.map((m) => ({ ...m, fileSizeBytes: m.fileSizeBytes.toString() })),
    );
  }

  // ─── Bookmarks ─────────────────────────────────────────────

  async addBookmark(userId: string, materialId: string) {
    const material = await this.prisma.material.findUnique({
      where: { id: materialId, isPublished: true },
    });
    if (!material) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Material not found' });
    }

    await this.prisma.bookmark.upsert({
      where: { userId_materialId: { userId, materialId } },
      update: {},
      create: { userId, materialId },
    });
    return { success: true };
  }

  async removeBookmark(userId: string, materialId: string) {
    await this.prisma.bookmark.deleteMany({ where: { userId, materialId } });
    return { success: true };
  }

  async listBookmarks(userId: string) {
    const bookmarks = await this.prisma.bookmark.findMany({
      where: { userId },
      include: {
        material: {
          select: {
            id: true,
            title: true,
            type: true,
            subjectId: true,
            isPastPaper: true,
            fileSizeBytes: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return bookmarks.map((b) => ({
      ...b.material,
      fileSizeBytes: b.material.fileSizeBytes.toString(),
      bookmarkedAt: b.createdAt,
    }));
  }

  // ─── Helpers ───────────────────────────────────────────────

  private async assertYearAccess(user: JwtPayloadUser, yearSlug: string) {
    const hasAccess = await this.subscriptions.hasAccess(
      user.sub,
      user.role as UserRole,
      yearSlug,
    );
    if (!hasAccess) {
      throw new ForbiddenException({
        code: 'SUBSCRIPTION_REQUIRED',
        message: 'Active subscription required for this content',
      });
    }
  }

  private async getSubjectWithYear(subjectId: string) {
    const subject = await this.prisma.subject.findUnique({
      where: { id: subjectId },
      include: { year: true },
    });
    if (!subject) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Subject not found' });
    }
    return subject;
  }

  private async getPublishedMaterial(id: string) {
    const material = await this.prisma.material.findUnique({ where: { id } });
    if (!material || !material.isPublished) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Material not found' });
    }
    return material;
  }
}
