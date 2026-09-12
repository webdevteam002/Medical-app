import { AssistantToolsService } from './assistant-tools.service';
import { UserRole } from '@prisma/client';

describe('AssistantToolsService', () => {
  function create() {
    const prisma = {
      year: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'y1', name: 'Year 1', slug: 'year-1' },
        ]),
      },
      subject: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn(),
      },
      topic: { findMany: jest.fn().mockResolvedValue([]) },
      material: {
        findMany: jest.fn().mockResolvedValue([]),
        findUnique: jest.fn().mockResolvedValue({
          id: 'm1',
          title: 'Secret',
          type: 'PDF',
          isPublished: false,
          isDownloadable: true,
          isPastPaper: false,
          pastPaperYear: null,
          subject: { name: 'A', year: { slug: 'year-1', name: 'Year 1' } },
          topic: null,
        }),
      },
      exam: { findMany: jest.fn().mockResolvedValue([]) },
      subscription: { findMany: jest.fn().mockResolvedValue([]) },
    };
    const subscriptions = {
      getAccessibleYearSlugs: jest.fn().mockResolvedValue(['year-1']),
      hasAccess: jest.fn().mockResolvedValue(true),
    };
    const svc = new AssistantToolsService(prisma as never, subscriptions as never);
    return { svc, prisma, subscriptions };
  }

  it('returns accessible years only', async () => {
    const { svc } = create();
    const out = await svc.execute('u1', UserRole.STUDENT, {
      name: 'getAccessibleYears',
    });
    expect(out.result).toEqual({
      years: [{ id: 'y1', name: 'Year 1', slug: 'year-1' }],
    });
  });

  it('hides unpublished material meta', async () => {
    const { svc } = create();
    const out = await svc.execute('u1', UserRole.STUDENT, {
      name: 'getMaterialMeta',
      args: { materialId: 'm1' },
    });
    expect(out.result).toEqual({ notFound: true });
  });

  it('rejects non-allowlisted tools', async () => {
    const { svc } = create();
    await expect(
      svc.execute('u1', UserRole.STUDENT, {
        name: 'grantSubscription' as never,
      }),
    ).rejects.toThrow(/allowlisted/);
  });

  it('denies subjects for inaccessible year', async () => {
    const { svc, prisma } = create();
    await svc.execute('u1', UserRole.STUDENT, {
      name: 'getSubjects',
      args: { yearSlug: 'year-5' },
    });
    expect(prisma.subject.findMany).not.toHaveBeenCalled();
  });
});
