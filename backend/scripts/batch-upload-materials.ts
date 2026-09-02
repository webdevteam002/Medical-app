/**
 * Batch upload PDFs from a manifest CSV (Person 3 — Day 65).
 *
 * Usage:
 *   npx ts-node --compiler-options '{"module":"CommonJS"}' scripts/batch-upload-materials.ts manifest.csv
 *
 * Manifest columns (header row required):
 *   file_path, title, year_slug, subject_slug, topic (optional), is_past_paper (optional), past_paper_year (optional)
 *
 * Example row:
 *   ./pdfs/anatomy-notes.pdf, Upper Limb Notes, year-1, anatomy, upper-limb, false,
 */
import { PrismaClient, MaterialType } from '@prisma/client';
import { readFileSync, existsSync, mkdirSync, writeFileSync } from 'fs';
import { join, dirname, extname, basename } from 'path';
import { randomUUID } from 'crypto';

const prisma = new PrismaClient();

type ManifestRow = {
  file_path: string;
  title: string;
  year_slug: string;
  subject_slug: string;
  topic?: string;
  is_past_paper?: string;
  past_paper_year?: string;
  past_paper_session?: string;
};

function parseCsvLine(line: string): string[] {
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
      result.push(current.trim());
      current = '';
    } else {
      current += ch;
    }
  }
  result.push(current.trim());
  return result;
}

function loadManifest(path: string): ManifestRow[] {
  const raw = readFileSync(path, 'utf-8').replace(/^\uFEFF/, '').trim();
  const lines = raw.split(/\r?\n/).filter((l) => l.trim());
  const header = parseCsvLine(lines[0]).map((h) => h.toLowerCase());

  return lines.slice(1).map((line, idx) => {
    const cols = parseCsvLine(line);
    const row: Record<string, string> = {};
    header.forEach((h, i) => {
      row[h] = cols[i] ?? '';
    });

    if (!row.file_path || !row.title || !row.year_slug || !row.subject_slug) {
      throw new Error(`Row ${idx + 2}: file_path, title, year_slug, subject_slug are required`);
    }

    return row as ManifestRow;
  });
}

async function uploadLocal(key: string, buffer: Buffer): Promise<void> {
  const root = join(process.cwd(), 'uploads');
  const filePath = join(root, key);
  const dir = dirname(filePath);
  if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
  writeFileSync(filePath, buffer);
}

async function main() {
  const manifestPath = process.argv[2];
  if (!manifestPath) {
    console.error('Usage: batch-upload-materials.ts <manifest.csv>');
    process.exit(1);
  }

  const rows = loadManifest(manifestPath);
  const results = { uploaded: 0, skipped: 0, errors: [] as string[] };

  for (const row of rows) {
    const filePath = row.file_path.startsWith('.')
      ? join(process.cwd(), row.file_path)
      : row.file_path;

    if (!existsSync(filePath)) {
      results.errors.push(`${row.title}: file not found — ${filePath}`);
      continue;
    }

    try {
      const year = await prisma.year.findUnique({ where: { slug: row.year_slug } });
      if (!year) throw new Error(`Year not found: ${row.year_slug}`);

      const subject = await prisma.subject.findFirst({
        where: { yearId: year.id, slug: row.subject_slug },
      });
      if (!subject) throw new Error(`Subject not found: ${row.subject_slug} in ${row.year_slug}`);

      let topicId: string | undefined;
      if (row.topic?.trim()) {
        const topic = await prisma.topic.findFirst({
          where: { subjectId: subject.id, name: { equals: row.topic, mode: 'insensitive' } },
        });
        topicId = topic?.id;
      }

      const buffer = readFileSync(filePath);
      const ext = extname(filePath).slice(1).toLowerCase() || 'pdf';
      const fileKey = `materials/${year.slug}/${subject.slug}/${randomUUID()}.${ext}`;

      await uploadLocal(fileKey, buffer);

      await prisma.material.create({
        data: {
          subjectId: subject.id,
          topicId,
          title: row.title,
          type: MaterialType.PDF,
          fileKey,
          fileSizeBytes: BigInt(buffer.length),
          isDownloadable: true,
          isPastPaper: row.is_past_paper === 'true',
          pastPaperYear: row.past_paper_year ? parseInt(row.past_paper_year, 10) : undefined,
          pastPaperSession: row.past_paper_session || undefined,
          isPublished: false,
        },
      });

      results.uploaded++;
      console.log(`✓ ${row.title} → ${fileKey}`);
    } catch (err) {
      results.errors.push(`${row.title}: ${err instanceof Error ? err.message : 'Unknown error'}`);
    }
  }

  console.log('\n--- Summary ---');
  console.log(`Uploaded: ${results.uploaded}`);
  console.log(`Errors: ${results.errors.length}`);
  results.errors.forEach((e) => console.error(`  - ${e}`));

  await prisma.$disconnect();
  process.exit(results.errors.length ? 1 : 0);
}

main().catch(async (err) => {
  console.error(err);
  await prisma.$disconnect();
  process.exit(1);
});
