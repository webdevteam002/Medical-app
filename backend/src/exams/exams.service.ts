import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { AttemptStatus, Difficulty, UserRole } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { SubscriptionsService } from '../subscriptions/subscriptions.service';
import { JwtPayloadUser } from '../common/decorators/current-user.decorator';
import {
  CreateExamDto,
  CreateQuestionDto,
  SubmitExamDto,
  UpdateExamDto,
  UpdateQuestionDto,
} from './dto/exams.dto';

type QuestionOption = { id: string; text: string };

@Injectable()
export class ExamsService {
  constructor(
    private prisma: PrismaService,
    private subscriptions: SubscriptionsService,
  ) {}

  // ─── Student ───────────────────────────────────────────────

  async listExams(user: JwtPayloadUser, filters: { yearSlug?: string; subjectId?: string }) {
    const accessible = await this.subscriptions.getAccessibleYearSlugs(
      user.sub,
      user.role as UserRole,
    );

    const yearFilter = filters.yearSlug
      ? accessible.includes(filters.yearSlug)
        ? { slug: filters.yearSlug }
        : { slug: '__none__' }
      : { slug: { in: accessible } };

    const exams = await this.prisma.exam.findMany({
      where: {
        isPublished: true,
        ...(filters.subjectId ? { subjectId: filters.subjectId } : {}),
        subject: { year: yearFilter },
      },
      include: {
        subject: { select: { name: true, slug: true, year: { select: { slug: true, name: true } } } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return exams.map((e) => ({
      id: e.id,
      title: e.title,
      durationMinutes: e.durationMinutes,
      questionCount: e.questionCount,
      subject: e.subject,
    }));
  }

  async startExam(examId: string, user: JwtPayloadUser) {
    const exam = await this.getPublishedExam(examId);
    await this.assertSubjectAccess(user, exam.subjectId);

    const existing = await this.prisma.examAttempt.findFirst({
      where: { userId: user.sub, examId, status: AttemptStatus.IN_PROGRESS },
    });
    if (existing) {
      throw new ConflictException({
        code: 'ATTEMPT_IN_PROGRESS',
        message: 'You already have an active attempt for this exam',
      });
    }

    const examQuestions = await this.prisma.examQuestion.findMany({
      where: { examId },
      include: { question: true },
      orderBy: { sortOrder: 'asc' },
    });

    if (!examQuestions.length) {
      throw new BadRequestException({ code: 'NO_QUESTIONS', message: 'Exam has no questions' });
    }

    let questions = examQuestions.map((eq) => eq.question);

    if (exam.shuffleQuestions) {
      questions = this.shuffle(questions);
    }

    const attempt = await this.prisma.examAttempt.create({
      data: {
        userId: user.sub,
        examId,
        status: AttemptStatus.IN_PROGRESS,
        total: questions.length,
      },
    });

    return {
      attemptId: attempt.id,
      durationMinutes: exam.durationMinutes,
      startedAt: attempt.startedAt,
      questions: questions.map((q) => this.toClientQuestion(q, exam.shuffleOptions)),
    };
  }

  async submitExam(attemptId: string, user: JwtPayloadUser, dto: SubmitExamDto) {
    const attempt = await this.prisma.examAttempt.findUnique({
      where: { id: attemptId },
      include: {
        exam: {
          include: {
            examQuestions: { include: { question: true } },
          },
        },
      },
    });

    if (!attempt || attempt.userId !== user.sub) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Attempt not found' });
    }

    if (attempt.status !== AttemptStatus.IN_PROGRESS) {
      throw new ConflictException({ code: 'ALREADY_SUBMITTED', message: 'Exam already submitted' });
    }

    await this.assertSubjectAccess(user, attempt.exam.subjectId);

    const elapsedMs = Date.now() - attempt.startedAt.getTime();
    const maxMs = attempt.exam.durationMinutes * 60 * 1000 + 60000; // 1 min grace
    if (elapsedMs > maxMs) {
      throw new ForbiddenException({ code: 'TIME_EXPIRED', message: 'Exam time has expired' });
    }

    const questionMap = new Map(
      attempt.exam.examQuestions.map((eq) => [eq.questionId, eq.question]),
    );

    let score = 0;
    const details: Array<{
      questionId: string;
      selectedOptionId: string | null;
      correctOptionId: string;
      isCorrect: boolean;
      explanation: string;
      timeSpentSeconds: number;
    }> = [];

    for (const answer of dto.answers) {
      const question = questionMap.get(answer.questionId);
      if (!question) continue;

      const isCorrect = answer.selectedOptionId === question.correctOptionId;
      if (isCorrect) score++;

      details.push({
        questionId: question.id,
        selectedOptionId: answer.selectedOptionId ?? null,
        correctOptionId: question.correctOptionId,
        isCorrect,
        explanation: question.explanation,
        timeSpentSeconds: answer.timeSpentSeconds ?? 0,
      });

      await this.prisma.examAttemptDetail.create({
        data: {
          attemptId,
          questionId: question.id,
          selectedOptionId: answer.selectedOptionId,
          isCorrect,
          timeSpentSeconds: answer.timeSpentSeconds ?? 0,
        },
      });
    }

    const total = attempt.total ?? questionMap.size;
    const percentage = total > 0 ? Math.round((score / total) * 10000) / 100 : 0;

    await this.prisma.examAttempt.update({
      where: { id: attemptId },
      data: {
        status: AttemptStatus.COMPLETED,
        score,
        total,
        percentage,
        completedAt: new Date(),
      },
    });

    return { score, total, percentage, details };
  }

  async listAttempts(user: JwtPayloadUser) {
    const attempts = await this.prisma.examAttempt.findMany({
      where: { userId: user.sub, status: AttemptStatus.COMPLETED },
      include: { exam: { select: { title: true, subject: { select: { name: true } } } } },
      orderBy: { completedAt: 'desc' },
    });

    return attempts.map((a) => ({
      id: a.id,
      examTitle: a.exam.title,
      subjectName: a.exam.subject.name,
      score: a.score,
      total: a.total,
      percentage: a.percentage,
      startedAt: a.startedAt,
      completedAt: a.completedAt,
    }));
  }

  async getAttemptReview(attemptId: string, user: JwtPayloadUser) {
    const attempt = await this.prisma.examAttempt.findUnique({
      where: { id: attemptId },
      include: {
        exam: { select: { title: true, durationMinutes: true } },
        details: { include: { question: true } },
      },
    });

    if (!attempt || attempt.userId !== user.sub) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Attempt not found' });
    }

    return {
      id: attempt.id,
      examTitle: attempt.exam.title,
      score: attempt.score,
      total: attempt.total,
      percentage: attempt.percentage,
      startedAt: attempt.startedAt,
      completedAt: attempt.completedAt,
      details: attempt.details.map((d) => ({
        questionId: d.questionId,
        stem: d.question.stem,
        options: d.question.options,
        selectedOptionId: d.selectedOptionId,
        correctOptionId: d.question.correctOptionId,
        isCorrect: d.isCorrect,
        explanation: d.question.explanation,
        timeSpentSeconds: d.timeSpentSeconds,
      })),
    };
  }

  // ─── Admin: Questions ──────────────────────────────────────

  createQuestion(dto: CreateQuestionDto) {
    this.validateQuestionOptions(dto.options, dto.correctOptionId);
    return this.prisma.question.create({
      data: {
        subjectId: dto.subjectId,
        stem: dto.stem,
        options: dto.options,
        correctOptionId: dto.correctOptionId,
        explanation: dto.explanation,
        difficulty: dto.difficulty ?? Difficulty.MEDIUM,
        tags: dto.tags ?? [],
        imageKey: dto.imageKey,
        isPublished: false,
      },
    });
  }

  listQuestions(subjectId?: string, published?: boolean) {
    return this.prisma.question.findMany({
      where: {
        ...(subjectId ? { subjectId } : {}),
        ...(published !== undefined ? { isPublished: published } : {}),
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateQuestion(id: string, dto: UpdateQuestionDto) {
    const q = await this.prisma.question.findUnique({ where: { id } });
    if (!q) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Question not found' });

    if (dto.options && dto.correctOptionId) {
      this.validateQuestionOptions(dto.options, dto.correctOptionId);
    } else if (dto.options) {
      this.validateQuestionOptions(dto.options, q.correctOptionId);
    }

    return this.prisma.question.update({ where: { id }, data: dto });
  }

  async deleteQuestion(id: string) {
    await this.prisma.question.delete({ where: { id } });
    return { success: true };
  }

  async importQuestionsCsv(subjectId: string, csvContent: string, dryRun = false) {
    const subject = await this.prisma.subject.findUnique({ where: { id: subjectId } });
    if (!subject) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Subject not found' });
    }

    const normalized = csvContent.replace(/^\uFEFF/, '').trim();
    const lines = normalized.split(/\r?\n/).filter((line) => line.trim().length > 0);
    if (lines.length < 2) {
      throw new BadRequestException({ code: 'INVALID_CSV', message: 'CSV must have header + rows' });
    }

    const header = this.parseCsvLine(lines[0]).map((h) => h.trim().toLowerCase());
    this.assertRequiredCsvColumns(header);

    const results = {
      dryRun,
      imported: 0,
      skipped: 0,
      errors: [] as { row: number; reason: string }[],
    };

    for (let i = 1; i < lines.length; i++) {
      const row = this.parseCsvLine(lines[i]);
      if (!row.length || !row[0]?.trim()) {
        results.skipped++;
        continue;
      }

      try {
        const record = this.mapCsvRow(header, row);
        const options: QuestionOption[] = [
          { id: 'a', text: record.option_a },
          { id: 'b', text: record.option_b },
          { id: 'c', text: record.option_c },
          { id: 'd', text: record.option_d },
        ];
        if (record.option_e?.trim()) options.push({ id: 'e', text: record.option_e });

        const correctOptionId = this.normalizeCorrectOption(record.correct_option);
        this.validateQuestionOptions(options, correctOptionId);

        const difficulty = this.normalizeDifficulty(record.difficulty);
        const tags = record.tags
          ? record.tags.split(';').map((t: string) => t.trim()).filter(Boolean)
          : [];

        if (!dryRun) {
          await this.prisma.question.create({
            data: {
              subjectId,
              stem: record.stem,
              options,
              correctOptionId,
              explanation: record.explanation || 'No explanation provided.',
              difficulty,
              tags,
              imageKey: record.image_key || null,
              isPublished: false,
            },
          });
        }
        results.imported++;
      } catch (err) {
        results.errors.push({
          row: i + 1,
          reason: err instanceof Error ? err.message : 'Unknown error',
        });
      }
    }

    return results;
  }

  // ─── Admin: Exams ──────────────────────────────────────────

  async createExam(dto: CreateExamDto) {
    return this.prisma.exam.create({
      data: {
        title: dto.title,
        subjectId: dto.subjectId,
        durationMinutes: dto.durationMinutes,
        questionCount: 0,
        shuffleQuestions: dto.shuffleQuestions ?? true,
        shuffleOptions: dto.shuffleOptions ?? false,
        isPublished: false,
      },
    });
  }

  listAllExams(subjectId?: string) {
    return this.prisma.exam.findMany({
      where: subjectId ? { subjectId } : undefined,
      include: {
        subject: { select: { name: true, year: { select: { name: true } } } },
        _count: { select: { examQuestions: true, attempts: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateExam(id: string, dto: UpdateExamDto) {
    return this.prisma.exam.update({ where: { id }, data: dto });
  }

  async deleteExam(id: string) {
    await this.prisma.exam.delete({ where: { id } });
    return { success: true };
  }

  async setExamQuestions(examId: string, questionIds: string[]) {
    const exam = await this.prisma.exam.findUnique({ where: { id: examId } });
    if (!exam) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Exam not found' });

    await this.prisma.examQuestion.deleteMany({ where: { examId } });

    await this.prisma.examQuestion.createMany({
      data: questionIds.map((questionId, index) => ({
        examId,
        questionId,
        sortOrder: index,
      })),
    });

    return this.prisma.exam.update({
      where: { id: examId },
      data: { questionCount: questionIds.length },
    });
  }

  async getExamAnalytics(examId: string) {
    const attempts = await this.prisma.examAttempt.findMany({
      where: { examId, status: AttemptStatus.COMPLETED },
      select: { score: true, total: true, percentage: true },
    });

    if (!attempts.length) {
      return { attemptCount: 0, averageScore: 0, averagePercentage: 0 };
    }

    const avgScore = attempts.reduce((s, a) => s + (a.score ?? 0), 0) / attempts.length;
    const avgPct =
      attempts.reduce((s, a) => s + Number(a.percentage ?? 0), 0) / attempts.length;

    return {
      attemptCount: attempts.length,
      averageScore: Math.round(avgScore * 100) / 100,
      averagePercentage: Math.round(avgPct * 100) / 100,
    };
  }

  // ─── Helpers ───────────────────────────────────────────────

  private async getPublishedExam(examId: string) {
    const exam = await this.prisma.exam.findUnique({ where: { id: examId } });
    if (!exam?.isPublished) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Exam not found' });
    }
    return exam;
  }

  private async assertSubjectAccess(user: JwtPayloadUser, subjectId: string) {
    const subject = await this.prisma.subject.findUnique({
      where: { id: subjectId },
      include: { year: true },
    });
    if (!subject) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Subject not found' });
    }

    const hasAccess = await this.subscriptions.hasAccess(
      user.sub,
      user.role as UserRole,
      subject.year.slug,
    );
    if (!hasAccess) {
      throw new ForbiddenException({
        code: 'SUBSCRIPTION_REQUIRED',
        message: 'Active subscription required',
      });
    }
  }

  private toClientQuestion(
    question: { id: string; stem: string; options: unknown; imageKey: string | null },
    shuffleOptions: boolean,
  ) {
    let options = question.options as QuestionOption[];
    if (shuffleOptions) {
      options = this.shuffle([...options]);
    }
    return {
      id: question.id,
      stem: question.stem,
      options,
      imageKey: question.imageKey,
    };
  }

  private validateQuestionOptions(options: QuestionOption[], correctId: string) {
    if (options.length < 4 || options.length > 5) {
      throw new BadRequestException({ code: 'INVALID_OPTIONS', message: 'Need 4-5 options' });
    }
    if (!options.find((o) => o.id === correctId)) {
      throw new BadRequestException({ code: 'INVALID_ANSWER', message: 'Correct option not in list' });
    }
  }

  private shuffle<T>(arr: T[]): T[] {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
  }

  private parseCsvLine(line: string): string[] {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
      const ch = line[i];
      if (ch === '"') {
        if (inQuotes && line[i + 1] === '"') {
          current += '"';
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch === ',' && !inQuotes) {
        result.push(this.cleanCsvField(current));
        current = '';
      } else {
        current += ch;
      }
    }
    result.push(this.cleanCsvField(current));
    return result;
  }

  private cleanCsvField(value: string): string {
    return value.trim().replace(/^"|"$/g, '').replace(/""/g, '"');
  }

  private mapCsvRow(header: string[], row: string[]): Record<string, string> {
    const record: Record<string, string> = {};
    header.forEach((h, i) => {
      record[h] = row[i] ?? '';
    });
    return record;
  }

  private assertRequiredCsvColumns(header: string[]) {
    const required = ['stem', 'option_a', 'option_b', 'option_c', 'option_d', 'correct_option'];
    const missing = required.filter((col) => !header.includes(col));
    if (missing.length) {
      throw new BadRequestException({
        code: 'INVALID_CSV',
        message: `Missing columns: ${missing.join(', ')}`,
      });
    }
  }

  private normalizeCorrectOption(value: string): string {
    const normalized = value.trim().toLowerCase();
    if (['a', 'b', 'c', 'd', 'e'].includes(normalized)) return normalized;
    if (normalized === 'option_a') return 'a';
    if (normalized === 'option_b') return 'b';
    if (normalized === 'option_c') return 'c';
    if (normalized === 'option_d') return 'd';
    if (normalized === 'option_e') return 'e';
    throw new BadRequestException({
      code: 'INVALID_ANSWER',
      message: `Invalid correct_option "${value}" — use a, b, c, d, or e`,
    });
  }

  private normalizeDifficulty(value?: string): Difficulty {
    const upper = value?.trim().toUpperCase();
    if (upper === 'EASY' || upper === 'MEDIUM' || upper === 'HARD') {
      return upper as Difficulty;
    }
    return Difficulty.MEDIUM;
  }
}
