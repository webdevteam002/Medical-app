import { PrismaClient, PlanType, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const adminEmail = 'admin@medstudy.local';
  const adminPassword = await bcrypt.hash('Admin123!', 12);

  await prisma.user.upsert({
    where: { email: adminEmail },
    update: {},
    create: {
      email: adminEmail,
      passwordHash: adminPassword,
      fullName: 'MedStudy Admin',
      role: UserRole.SUPER_ADMIN,
    },
  });

  const plans = [
    { name: 'Year 1', planType: PlanType.YEAR_1, pricePkr: 4000 },
    { name: 'Year 2', planType: PlanType.YEAR_2, pricePkr: 4000 },
    { name: 'Year 3', planType: PlanType.YEAR_3, pricePkr: 4000 },
    { name: 'Year 4', planType: PlanType.YEAR_4, pricePkr: 4000 },
    { name: 'Year 5', planType: PlanType.YEAR_5, pricePkr: 4000 },
    { name: 'FCPS Part 1', planType: PlanType.FCPS_PART_1, pricePkr: 6000 },
    { name: 'FCPS Part 2', planType: PlanType.FCPS_PART_2, pricePkr: 6000 },
    { name: 'All MBBS Years', planType: PlanType.ALL_MBBS, pricePkr: 15000 },
    { name: 'Ultimate Bundle', planType: PlanType.ULTIMATE_BUNDLE, pricePkr: 25000 },
  ];

  for (const plan of plans) {
    await prisma.subscriptionPlan.upsert({
      where: { planType: plan.planType },
      update: { name: plan.name, pricePkr: plan.pricePkr },
      create: {
        name: plan.name,
        planType: plan.planType,
        pricePkr: plan.pricePkr,
        durationDays: 365,
        isActive: true,
      },
    });
  }

  const years = [
    { name: 'Year 1', slug: 'year-1', sortOrder: 1, planType: PlanType.YEAR_1 },
    { name: 'Year 2', slug: 'year-2', sortOrder: 2, planType: PlanType.YEAR_2 },
    { name: 'Year 3', slug: 'year-3', sortOrder: 3, planType: PlanType.YEAR_3 },
    { name: 'Year 4', slug: 'year-4', sortOrder: 4, planType: PlanType.YEAR_4 },
    { name: 'Year 5', slug: 'year-5', sortOrder: 5, planType: PlanType.YEAR_5 },
    { name: 'FCPS Part 1', slug: 'fcps-part-1', sortOrder: 6, planType: PlanType.FCPS_PART_1 },
    { name: 'FCPS Part 2', slug: 'fcps-part-2', sortOrder: 7, planType: PlanType.FCPS_PART_2 },
  ];

  for (const year of years) {
    await prisma.year.upsert({
      where: { slug: year.slug },
      update: { name: year.name, sortOrder: year.sortOrder, planType: year.planType },
      create: year,
    });
  }

  const year1 = await prisma.year.findUnique({ where: { slug: 'year-1' } });
  if (year1) {
    const subjects = [
      { name: 'Anatomy', slug: 'anatomy', sortOrder: 1 },
      { name: 'Physiology', slug: 'physiology', sortOrder: 2 },
      { name: 'Biochemistry', slug: 'biochemistry', sortOrder: 3 },
    ];
    for (const subject of subjects) {
      await prisma.subject.upsert({
        where: { yearId_slug: { yearId: year1.id, slug: subject.slug } },
        update: { name: subject.name, sortOrder: subject.sortOrder },
        create: { ...subject, yearId: year1.id },
      });
    }

    // Sample questions + exam for API testing
    const anatomy = await prisma.subject.findUnique({
      where: { yearId_slug: { yearId: year1.id, slug: 'anatomy' } },
    });
    if (anatomy) {
      const sampleQuestions = [
        {
          stem: 'Which bone forms the forehead?',
          options: [
            { id: 'a', text: 'Frontal bone' },
            { id: 'b', text: 'Parietal bone' },
            { id: 'c', text: 'Occipital bone' },
            { id: 'd', text: 'Temporal bone' },
          ],
          correctOptionId: 'a',
          explanation: 'The frontal bone forms the forehead and superior part of the orbit.',
        },
        {
          stem: 'The largest artery in the body is the:',
          options: [
            { id: 'a', text: 'Pulmonary artery' },
            { id: 'b', text: 'Aorta' },
            { id: 'c', text: 'Carotid artery' },
            { id: 'd', text: 'Femoral artery' },
          ],
          correctOptionId: 'b',
          explanation: 'The aorta is the largest artery, carrying oxygenated blood from the left ventricle.',
        },
        {
          stem: 'Which muscle is primarily responsible for abduction of the arm at the shoulder?',
          options: [
            { id: 'a', text: 'Deltoid' },
            { id: 'b', text: 'Pectoralis major' },
            { id: 'c', text: 'Latissimus dorsi' },
            { id: 'd', text: 'Trapezius' },
          ],
          correctOptionId: 'a',
          explanation: 'The deltoid (especially middle fibers) is the primary abductor of the arm.',
        },
      ];

      const questionIds: string[] = [];
      for (const q of sampleQuestions) {
        const existing = await prisma.question.findFirst({
          where: { subjectId: anatomy.id, stem: q.stem },
        });
        if (existing) {
          questionIds.push(existing.id);
        } else {
          const created = await prisma.question.create({
            data: {
              subjectId: anatomy.id,
              stem: q.stem,
              options: q.options,
              correctOptionId: q.correctOptionId,
              explanation: q.explanation,
              tags: ['year-1', 'anatomy', 'sample'],
              isPublished: true,
            },
          });
          questionIds.push(created.id);
        }
      }

      let exam = await prisma.exam.findFirst({
        where: { subjectId: anatomy.id, title: 'Anatomy Sample Quiz' },
      });
      if (!exam) {
        exam = await prisma.exam.create({
          data: {
            title: 'Anatomy Sample Quiz',
            subjectId: anatomy.id,
            durationMinutes: 15,
            questionCount: questionIds.length,
            shuffleQuestions: true,
            isPublished: true,
          },
        });
        await prisma.examQuestion.createMany({
          data: questionIds.map((questionId, i) => ({
            examId: exam!.id,
            questionId,
            sortOrder: i,
          })),
        });
      }
    }
  }

  // Test student for API/content testing (Person 2 can use later)
  const studentEmail = 'student@test.com';
  const studentPassword = await bcrypt.hash('Student123!', 12);
  const student = await prisma.user.upsert({
    where: { email: studentEmail },
    update: {},
    create: {
      email: studentEmail,
      passwordHash: studentPassword,
      fullName: 'Test Student',
      role: UserRole.STUDENT,
    },
  });

  const year1Plan = await prisma.subscriptionPlan.findUnique({
    where: { planType: PlanType.YEAR_1 },
  });
  if (year1Plan) {
    const endDate = new Date();
    endDate.setFullYear(endDate.getFullYear() + 1);
    const existingSub = await prisma.subscription.findFirst({
      where: { userId: student.id, planId: year1Plan.id, status: 'ACTIVE' },
    });
    if (!existingSub) {
      await prisma.subscription.create({
        data: {
          userId: student.id,
          planId: year1Plan.id,
          status: 'ACTIVE',
          startDate: new Date(),
          endDate,
        },
      });
    }
  }

  console.log('Seed complete.');
  console.log('Admin login:', adminEmail, '/ Admin123!');
  console.log('Test student:', studentEmail, '/ Student123! (Year 1 subscription)');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
