const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();
const DRAW_PER_ATTEMPT = 40;

async function ensurePracticeExam(subject) {
  const title = `${subject.name} Practice Bank`;
  let exam = await prisma.exam.findFirst({
    where: { subjectId: subject.id, title },
  });

  if (!exam) {
    exam = await prisma.exam.create({
      data: {
        title,
        subjectId: subject.id,
        durationMinutes: 60,
        questionCount: DRAW_PER_ATTEMPT,
        shuffleQuestions: true,
        shuffleOptions: false,
        isPublished: true,
      },
    });
  }

  const questionIds = (
    await prisma.question.findMany({
      where: { subjectId: subject.id, isPublished: true },
      select: { id: true },
      orderBy: { createdAt: 'asc' },
    })
  ).map((q) => q.id);

  await prisma.examQuestion.deleteMany({ where: { examId: exam.id } });

  const chunkSize = 500;
  for (let i = 0; i < questionIds.length; i += chunkSize) {
    const chunk = questionIds.slice(i, i + chunkSize);
    await prisma.examQuestion.createMany({
      data: chunk.map((questionId, index) => ({
        examId: exam.id,
        questionId,
        sortOrder: i + index,
      })),
    });
  }

  const drawCount = Math.min(DRAW_PER_ATTEMPT, questionIds.length);
  exam = await prisma.exam.update({
    where: { id: exam.id },
    data: {
      questionCount: drawCount,
      isPublished: questionIds.length > 0,
    },
  });

  return {
    subject: `${subject.year.slug}/${subject.slug}`,
    examId: exam.id,
    pool: questionIds.length,
    draw: drawCount,
    published: exam.isPublished,
  };
}

async function main() {
  const publishResult = await prisma.question.updateMany({
    where: { isPublished: false },
    data: { isPublished: true },
  });

  const usmleSubjects = await prisma.subject.findMany({
    where: {
      OR: [
        { slug: { contains: 'uworld' } },
        { slug: { contains: 'usmle' } },
        { year: { slug: { contains: 'usmle' } } },
      ],
    },
    include: { year: { select: { slug: true, name: true } } },
  });

  const exams = [];
  for (const subject of usmleSubjects) {
    const count = await prisma.question.count({ where: { subjectId: subject.id } });
    if (count === 0) continue;
    exams.push(await ensurePracticeExam(subject));
  }

  const qTotal = await prisma.question.count();
  const qPub = await prisma.question.count({ where: { isPublished: true } });

  console.log(
    JSON.stringify(
      {
        publishedNow: publishResult.count,
        qTotal,
        qPub,
        practiceExams: exams,
      },
      null,
      2,
    ),
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
