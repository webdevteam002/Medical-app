# Oracle VM Production Deploy Guide (Person 1 — Days 51–60)

Deploy MedStudy API on **Oracle Cloud Always Free** VM with **JazzCash manual payments** (no RevenueCat).

---

## 1. Oracle VM setup

1. Create **Ubuntu 22.04 ARM** VM (Always Free)
2. Open ports **80**, **443**, **22** in Security List
3. SSH in: `ssh ubuntu@YOUR_VM_IP`

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose-v2 nginx certbot python3-certbot-nginx git
sudo usermod -aG docker ubuntu
```

---

## 2. Clone and configure

```bash
git clone YOUR_REPO_URL medstudy
cd medstudy/backend
cp .env.example .env.production
nano .env.production
```

### Required `.env.production` values

```env
DATABASE_URL=postgresql://medstudy:STRONG_PASSWORD@postgres:5432/medstudy
JWT_SECRET=generate-64-char-random-string
JWT_REFRESH_SECRET=generate-another-64-char-string
NODE_ENV=production
PORT=3000
API_PREFIX=v1

# Cloudflare R2
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=medstudy-pdfs

# JazzCash / Easypaisa (shown in app paywall)
PAYMENT_JAZZCASH_NUMBER=03XX-XXXXXXX
PAYMENT_EASYPAISA_NUMBER=03XX-XXXXXXX
PAYMENT_BANK_DETAILS=Bank Name, Account Title, IBAN
PAYMENT_WHATSAPP_NUMBER=92XXXXXXXXXX
PAYMENT_INSTRUCTIONS=Send payment then WhatsApp screenshot. Activated within 24 hours.
```

---

## 3. Deploy with Docker

```bash
export POSTGRES_PASSWORD=STRONG_PASSWORD
docker compose -f docker-compose.prod.yml up -d --build
docker compose -f docker-compose.prod.yml exec api npx prisma db seed
```

---

## 4. Nginx + SSL

```bash
sudo cp deploy/nginx.conf /etc/nginx/sites-available/medstudy
sudo sed -i 's/YOUR_DOMAIN/api.yourdomain.com/g' /etc/nginx/sites-available/medstudy
sudo ln -s /etc/nginx/sites-available/medstudy /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d api.yourdomain.com
```

---

## 5. Verify

```bash
curl https://api.yourdomain.com/v1/health
curl https://api.yourdomain.com/v1/payments/plans
curl https://api.yourdomain.com/v1/payments/instructions
```

Share `https://api.yourdomain.com/v1` with Person 2.

---

## 6. Daily backups (cron)

```bash
chmod +x scripts/backup-db.sh
crontab -e
# Add: 0 3 * * * /home/ubuntu/medstudy/backend/scripts/backup-db.sh
```

---

## 7. PM2 alternative (without Docker)

```bash
npm ci
npx prisma migrate deploy
npm run prisma:seed
npm run build
pm2 start deploy/ecosystem.config.js
pm2 save
pm2 startup
```

---

## JazzCash subscription flow (admin)

1. Student pays JazzCash → sends screenshot on WhatsApp
2. Admin opens admin panel → finds user by email
3. `POST /v1/admin/subscriptions/users/:userId/grant` with `{ "planType": "YEAR_3" }`
4. Student gets access immediately

List all subs: `GET /v1/admin/subscriptions`

---

## Monitoring

- Health: `GET /v1/health`
- SSL pins for Flutter: `GET /v1/security/ssl-pins`
- Logs: `docker compose -f docker-compose.prod.yml logs -f api`
- Disk: `df -h` (watch uploads/ and DB volume)

---

## SSL certificate pinning (Person 2 — Day 64)

After Certbot SSL is live, generate the SHA-256 pin:

```bash
openssl s_client -connect api.yourdomain.com:443 -servername api.yourdomain.com </dev/null 2>/dev/null \
  | openssl x509 -pubkey -noout \
  | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -binary \
  | openssl enc -base64
```

Add to `.env.production`:

```env
SSL_PIN_SHA256=YOUR_BASE64_HASH_HERE
API_PUBLIC_DOMAIN=api.yourdomain.com
```

Person 2 fetches pins from `GET /v1/security/ssl-pins` for the Flutter release build.

---

## Batch PDF upload (Person 3 — Day 65)

On the VM (local storage) or dev machine:

```bash
npm run batch:upload -- scripts/batch-upload-example.csv
```

See `scripts/batch-upload-example.csv` for manifest format. Materials are created as **unpublished** — publish via admin panel.
