/**
 * Upload every file under uploads/ to Cloudflare R2 using the same relative key.
 * Safe to re-run (skips keys that already exist in R2).
 *
 * Usage (on server, with .env loaded):
 *   node scripts/migrate-uploads-to-r2.js
 */
const {
  existsSync,
  readdirSync,
  readFileSync,
  statSync,
} = require('fs');
const { join, relative, extname } = require('path');
const {
  S3Client,
  PutObjectCommand,
  HeadObjectCommand,
} = require('@aws-sdk/client-s3');

function loadEnv(filePath) {
  if (!existsSync(filePath)) return;
  for (const line of readFileSync(filePath, 'utf8').split(/\r?\n/)) {
    const s = line.trim();
    if (!s || s.startsWith('#') || !s.includes('=')) continue;
    const i = s.indexOf('=');
    const k = s.slice(0, i).trim();
    let v = s.slice(i + 1).trim();
    if (
      (v.startsWith('"') && v.endsWith('"')) ||
      (v.startsWith("'") && v.endsWith("'"))
    ) {
      v = v.slice(1, -1);
    }
    if (!(k in process.env)) process.env[k] = v;
  }
}

function guessContentType(key) {
  switch (extname(key).toLowerCase()) {
    case '.pdf':
      return 'application/pdf';
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.gif':
      return 'image/gif';
    case '.webp':
      return 'image/webp';
    case '.mp4':
      return 'video/mp4';
    default:
      return 'application/octet-stream';
  }
}

function walkFiles(dir, out = []) {
  if (!existsSync(dir)) return out;
  for (const name of readdirSync(dir)) {
    const abs = join(dir, name);
    const st = statSync(abs);
    if (st.isDirectory()) walkFiles(abs, out);
    else out.push(abs);
  }
  return out;
}

async function exists(s3, bucket, key) {
  try {
    await s3.send(new HeadObjectCommand({ Bucket: bucket, Key: key }));
    return true;
  } catch {
    return false;
  }
}

async function main() {
  loadEnv(join(process.cwd(), '.env'));

  const accountId = process.env.R2_ACCOUNT_ID;
  const accessKey = process.env.R2_ACCESS_KEY_ID;
  const secretKey = process.env.R2_SECRET_ACCESS_KEY;
  const bucket = process.env.R2_BUCKET_NAME || 'medstudy-media';

  if (!accountId || !accessKey || !secretKey) {
    throw new Error('R2 credentials missing in .env');
  }

  const s3 = new S3Client({
    region: 'auto',
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: accessKey,
      secretAccessKey: secretKey,
    },
  });

  const uploadsRoot = join(process.cwd(), 'uploads');
  const files = walkFiles(uploadsRoot);
  const result = { scanned: files.length, uploaded: 0, skipped: 0, failed: [] };

  for (const abs of files) {
    const key = relative(uploadsRoot, abs).replace(/\\/g, '/');
    try {
      if (await exists(s3, bucket, key)) {
        result.skipped++;
        continue;
      }
      const body = readFileSync(abs);
      await s3.send(
        new PutObjectCommand({
          Bucket: bucket,
          Key: key,
          Body: body,
          ContentType: guessContentType(key),
        }),
      );
      result.uploaded++;

      // Also mirror nested images to flat images/<basename> for CSV image_key lookup.
      if (key.startsWith('images/') && key.split('/').length > 2) {
        const flat = `images/${key.split('/').pop()}`;
        if (flat !== key && !(await exists(s3, bucket, flat))) {
          await s3.send(
            new PutObjectCommand({
              Bucket: bucket,
              Key: flat,
              Body: body,
              ContentType: guessContentType(flat),
            }),
          );
          result.uploaded++;
        }
      }
    } catch (err) {
      result.failed.push({ key, error: err instanceof Error ? err.message : String(err) });
    }
  }

  console.log(JSON.stringify(result, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
