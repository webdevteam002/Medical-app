import { Injectable } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { SubscriptionsService } from '../../subscriptions/subscriptions.service';

export type AssistantToolName =
  | 'getAccessibleYears'
  | 'getSubjects'
  | 'getTopics'
  | 'getMaterials'
  | 'getExams'
  | 'getMySubscription'
  | 'getMaterialMeta'
  | 'getAppHelp';

export const ASSISTANT_TOOL_NAMES: readonly AssistantToolName[] = [
  'getAccessibleYears',
  'getSubjects',
  'getTopics',
  'getMaterials',
  'getExams',
  'getMySubscription',
  'getMaterialMeta',
  'getAppHelp',
] as const;

export type AssistantToolCall = {
  name: AssistantToolName;
  args?: Record<string, unknown>;
};

/**
 * Allowlisted read-only MedStudy application tools.
 * No mutations, no SQL, no unpublished content, no cross-user data.
 */
@Injectable()
export class AssistantToolsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly subscriptions: SubscriptionsService,
  ) {}

  isAllowlisted(name: string): name is AssistantToolName {
    return (ASSISTANT_TOOL_NAMES as readonly string[]).includes(name);
  }

  async execute(
    userId: string,
    role: UserRole,
    call: AssistantToolCall,
  ): Promise<{ name: AssistantToolName; result: unknown }> {
    if (!this.isAllowlisted(call.name)) {
      throw new Error(`Tool not allowlisted: ${call.name}`);
    }

    const args = call.args ?? {};
    switch (call.name) {
      case 'getAccessibleYears':
        return { name: call.name, result: await this.getAccessibleYears(userId, role) };
      case 'getSubjects':
        return {
          name: call.name,
          result: await this.getSubjects(userId, role, asOptionalString(args.yearSlug)),
        };
      case 'getTopics':
        return {
          name: call.name,
          result: await this.getTopics(userId, role, asRequiredString(args.subjectId, 'subjectId')),
        };
      case 'getMaterials':
        return {
          name: call.name,
          result: await this.getMaterials(
            userId,
            role,
            asRequiredString(args.subjectId, 'subjectId'),
            asOptionalString(args.topicId),
          ),
        };
      case 'getExams':
        return {
          name: call.name,
          result: await this.getExams(
            userId,
            role,
            asOptionalString(args.yearSlug),
            asOptionalString(args.subjectId),
          ),
        };
      case 'getMySubscription':
        return { name: call.name, result: await this.getMySubscription(userId, role) };
      case 'getMaterialMeta':
        return {
          name: call.name,
          result: await this.getMaterialMeta(
            userId,
            role,
            asRequiredString(args.materialId, 'materialId'),
          ),
        };
      case 'getAppHelp':
        return { name: call.name, result: this.getAppHelp() };
      default: {
        const name = String((call as { name: string }).name);
        throw new Error(`Unhandled tool: ${name}`);
      }
    }
  }

  private async getAccessibleYears(userId: string, role: UserRole) {
    const slugs = await this.subscriptions.getAccessibleYearSlugs(userId, role);
    if (slugs.length === 0) return { years: [] };
    const years = await this.prisma.year.findMany({
      where: { slug: { in: slugs } },
      orderBy: { sortOrder: 'asc' },
      select: { id: true, name: true, slug: true },
    });
    return { years };
  }

  private async getSubjects(userId: string, role: UserRole, yearSlug?: string) {
    const accessible = await this.subscriptions.getAccessibleYearSlugs(userId, role);
    if (accessible.length === 0) return { subjects: [] };
    const slugFilter = yearSlug
      ? accessible.includes(yearSlug)
        ? [yearSlug]
        : []
      : accessible;
    if (slugFilter.length === 0) return { subjects: [], denied: true };

    const subjects = await this.prisma.subject.findMany({
      where: { year: { slug: { in: slugFilter } } },
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        name: true,
        slug: true,
        year: { select: { name: true, slug: true } },
      },
      take: 100,
    });
    return { subjects };
  }

  private async getTopics(userId: string, role: UserRole, subjectId: string) {
    const subject = await this.prisma.subject.findUnique({
      where: { id: subjectId },
      select: { id: true, name: true, year: { select: { slug: true } } },
    });
    if (!subject) return { topics: [], notFound: true };
    const ok = await this.subscriptions.hasAccess(userId, role, subject.year.slug);
    if (!ok) return { topics: [], denied: true };

    const topics = await this.prisma.topic.findMany({
      where: { subjectId },
      orderBy: { sortOrder: 'asc' },
      select: { id: true, name: true, sortOrder: true },
      take: 100,
    });
    return { subjectName: subject.name, topics };
  }

  private async getMaterials(
    userId: string,
    role: UserRole,
    subjectId: string,
    topicId?: string,
  ) {
    const subject = await this.prisma.subject.findUnique({
      where: { id: subjectId },
      select: { id: true, name: true, year: { select: { slug: true } } },
    });
    if (!subject) return { materials: [], notFound: true };
    const ok = await this.subscriptions.hasAccess(userId, role, subject.year.slug);
    if (!ok) return { materials: [], denied: true };

    const materials = await this.prisma.material.findMany({
      where: {
        subjectId,
        isPublished: true,
        ...(topicId ? { topicId } : {}),
      },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        title: true,
        type: true,
        topicId: true,
        isDownloadable: true,
        isPastPaper: true,
      },
      take: 50,
    });
    return { subjectName: subject.name, materials };
  }

  private async getExams(
    userId: string,
    role: UserRole,
    yearSlug?: string,
    subjectId?: string,
  ) {
    const accessible = await this.subscriptions.getAccessibleYearSlugs(userId, role);
    if (accessible.length === 0) return { exams: [] };

    let subjectFilter: string | undefined = subjectId;
    if (subjectId) {
      const subject = await this.prisma.subject.findUnique({
        where: { id: subjectId },
        select: { year: { select: { slug: true } } },
      });
      if (!subject || !accessible.includes(subject.year.slug)) {
        return { exams: [], denied: true };
      }
    }

    const yearFilter = yearSlug
      ? accessible.includes(yearSlug)
        ? yearSlug
        : null
      : undefined;
    if (yearFilter === null) return { exams: [], denied: true };

    const exams = await this.prisma.exam.findMany({
      where: {
        isPublished: true,
        subject: {
          ...(subjectFilter ? { id: subjectFilter } : {}),
          year: {
            slug: yearFilter ? yearFilter : { in: accessible },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        title: true,
        durationMinutes: true,
        subject: { select: { name: true, year: { select: { slug: true, name: true } } } },
        _count: { select: { examQuestions: true } },
      },
      take: 40,
    });

    return {
      exams: exams.map((e) => ({
        id: e.id,
        title: e.title,
        durationMinutes: e.durationMinutes,
        questionCount: e._count.examQuestions,
        subjectName: e.subject.name,
        yearSlug: e.subject.year.slug,
        yearName: e.subject.year.name,
      })),
    };
  }

  private async getMySubscription(userId: string, role: UserRole) {
    const years = await this.subscriptions.getAccessibleYearSlugs(userId, role);
    const subs = await this.prisma.subscription.findMany({
      where: {
        userId,
        status: 'ACTIVE',
        endDate: { gt: new Date() },
      },
      include: { plan: { select: { name: true, planType: true } } },
      orderBy: { endDate: 'desc' },
      take: 5,
    });
    return {
      role,
      accessibleYearSlugs: years,
      activeSubscriptions: subs.map((s) => ({
        planName: s.plan.name,
        planType: s.plan.planType,
        endDate: s.endDate ? s.endDate.toISOString() : null,
      })),
    };
  }

  private async getMaterialMeta(userId: string, role: UserRole, materialId: string) {
    const material = await this.prisma.material.findUnique({
      where: { id: materialId },
      select: {
        id: true,
        title: true,
        type: true,
        isPublished: true,
        isDownloadable: true,
        isPastPaper: true,
        pastPaperYear: true,
        subject: {
          select: {
            name: true,
            year: { select: { slug: true, name: true } },
          },
        },
        topic: { select: { name: true } },
      },
    });
    if (!material || !material.isPublished) {
      return { notFound: true };
    }
    const ok = await this.subscriptions.hasAccess(
      userId,
      role,
      material.subject.year.slug,
    );
    if (!ok) return { denied: true };

    return {
      id: material.id,
      title: material.title,
      type: material.type,
      isDownloadable: material.isDownloadable,
      isPastPaper: material.isPastPaper,
      pastPaperYear: material.pastPaperYear,
      subjectName: material.subject.name,
      yearName: material.subject.year.name,
      yearSlug: material.subject.year.slug,
      topicName: material.topic?.name ?? null,
      // Never expose fileKey / storage paths
    };
  }

  private getAppHelp() {
    return {
      summary:
        'MedStudy is an educational platform for MBBS/FCPS study materials, exams, and AI tutoring.',
      tips: [
        'Use Study to browse years → subjects → topics → materials.',
        'Use Exams to take published practice exams for years you can access.',
        'Ask AI to Explain on exam review for structured MCQ help.',
        'Subscriptions control which years you can access.',
        'This assistant is educational only — not a substitute for a clinician.',
      ],
    };
  }
}

function asOptionalString(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const t = value.trim();
  return t ? t : undefined;
}

function asRequiredString(value: unknown, field: string): string {
  const v = asOptionalString(value);
  if (!v) throw new Error(`Missing required tool arg: ${field}`);
  return v;
}
