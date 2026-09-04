# Person 3 — Content + Design Polish

**Role:** Content lead + UX/design polish (no coding required)  
**You own:** All study content · QBank quality · Post-build design · Store assets  
**Works with:** Person 1 (staging API) · Person 2 (admin panel + app builds)

> **Daily schedule (Day 1–80):** [PERSON_3_DAILY.md](./PERSON_3_DAILY.md) — every working day, Mon–Fri, 16 weeks

---

## Your job in one sentence

Prepare **all medical content** (MCQs, PDFs, past papers, images) to a high standard, upload it through the admin panel, then **polish the app’s look and feel** after Person 2 builds the first working version.

---

## Two parts to your work

| Part | When | Effort |
|------|------|--------|
| **A — Content** | **Week 1 → forever** | **Largest part of your job** |
| **B — Design polish** | **Week 10+** (after app skeleton) | After content MVP batch is rolling |

---

## What you own

| Area | Your responsibility |
|------|---------------------|
| QBank (MCQs) | Write, review, format, explanations |
| PDFs | Notes, chapters, compress, organize |
| Past papers | Collect, tag year/session |
| Images | Diagrams for image-based MCQs |
| content-map.csv | Master index of all files |
| Content upload | Via admin (Person 2 builds) |
| Beta testing | Students test app with real content |
| Design polish | Figma v2, UX fixes list, store screenshots |
| App store copy | Descriptions, feature bullets (support Person 2) |

---

## What you do NOT own

- Writing API or app code → Person 1 & 2
- Server / database → Person 1
- Building screens from scratch → Person 2 (you **refine** them)
- Initial wireframes (optional — you can own if no designer)

---

## Folder ownership

```text
content/
├── qbanks/              ← YOU
├── materials/           ← YOU
├── images/              ← YOU
└── content-map.csv      ← YOU

docs/templates/          ← use these, don’t change without team OK
```

Templates:
- [qbank-template.csv](./templates/qbank-template.csv)
- [content-map-template.csv](./templates/content-map-template.csv)

Full standards: [CONTENT_GUIDE.md](./CONTENT_GUIDE.md)

---

## Part A — Content (start Week 1)

### QBank — every question must have

| Field | Required? |
|-------|-----------|
| Question stem | Yes |
| 4–5 options | Yes |
| One correct answer | Yes |
| **Explanation** (why correct + why wrong) | **Yes — non-negotiable** |
| subject + topic | Yes |
| tags (year-2, fcps-part-1, etc.) | Yes |
| difficulty (EASY/MEDIUM/HARD) | Yes |
| image (if diagram question) | When needed |

### Review pipeline

```text
DRAFT → REVIEW (expert) → READY → upload → PUBLISHED
```

Never skip REVIEW for medical accuracy.

---

### PDFs — standards

| Rule | Target |
|------|--------|
| Format | PDF |
| Size | 2–15 MB (compress scans to 150 DPI) |
| Path | `materials/year-X/subject/filename.pdf` |
| Past papers | Tag: `past-paper;2024` |

### Images — standards

| Rule | Target |
|------|--------|
| Format | WebP or PNG |
| Max width | 1600 px |
| Size | 100–400 KB |
| Path | `images/questions/subject/q0001-main.webp` |
| CSV link | `image_key` column matches path |

---

### Content targets

| Milestone | What to have ready |
|-----------|-------------------|
| **Gate 2** (Week 6) | 1 subject fully polished: PDFs + 50 MCQs |
| **Gate 3** (Week 9) | Same subject: 100+ MCQs with explanations |
| **Gate 5 — Beta** (Week 13) | **Year 1–2 complete**: 500+ MCQs/subject, core PDFs, past papers |
| **Gate 7 — Launch** | All MVP content PUBLISHED in app |
| **Post-launch** | Year 3–5 + FCPS Part 1 → Part 2 |

---

### Week-by-week summary (content)

> Full day-by-day tasks: **[PERSON_3_DAILY.md](./PERSON_3_DAILY.md)**

### Week-by-week checklist (content)

#### Weeks 1–4
- [ ] Copy `content-map-template.csv` → `content/content-map.csv`
- [ ] Set up folder structure under `content/`
- [ ] List all subjects for Year 1 and Year 2
- [ ] Start QBank spreadsheets per subject
- [ ] Collect existing PDFs; note what’s missing
- [ ] Define who does medical review (subject expert)

#### Weeks 5–6
- [ ] First subject: 50+ MCQs in CSV format
- [ ] Compress first batch of PDFs
- [ ] Mark rows `READY` in content-map
- [ ] **Wait for Person 2 admin** → upload first PDF + import CSV
- [ ] Spot-check in Flutter app

#### Weeks 7–10
- [ ] Scale to 500+ MCQs per Year 1–2 subject
- [ ] All core notes PDFs compressed and named
- [ ] Past papers: min 2 per subject per year
- [ ] Image MCQs: at least 20% of bank where relevant (anatomy, pathology, ECG)
- [ ] FCPS folder structure prepared (content can come later)

#### Weeks 11–13 — Beta content
- [ ] All MVP content uploaded and `PUBLISHED`
- [ ] Recruit 10–20 students for beta
- [ ] Log content errors (typos, wrong answers, broken images)
- [ ] Fix and re-upload

#### Weeks 14+ — Expand
- [ ] Year 3–5 content batches
- [ ] FCPS Part 1 full library
- [ ] FCPS Part 2 (v1.1)

---

### Upload workflow (when admin is ready)

1. Set status `READY` in content-map.csv  
2. Log in to admin panel (Person 2 gives you credentials)  
3. Upload PDFs under correct year/subject  
4. Import QBank CSV  
5. Open Flutter app → read 1 PDF + take 1 exam  
6. Fix issues → set `PUBLISHED`  

Ask Person 1 for batch upload script if you have hundreds of files.

---

## Part B — Design polish (start Week 10+)

**Only after Person 2 gives you a test build (APK / TestFlight).**

### Your design tasks

| Task | Output |
|------|--------|
| Walk every screen | Written UX audit (Google Doc or Issues) |
| Visual consistency | Figma v2: colors, fonts, spacing, icons |
| **Cross-platform polish** | Onboarding, responsive empty states, loading, errors, keyboard navigation |
| Exam UX | Timer, palette, results, review screens (mobile and multi-column desktop) |
| PDF viewer | Watermark position, readability on large monitors, dark mode |
| Admin panel | Cleaner forms, upload feedback |
| Accessibility | Font size, contrast, button size |
| Store assets | Screenshots, feature graphic, icon refinements |
| Beta feedback | Prioritized list for Person 2 |

### Design deliverables

- [ ] **UX audit doc** — screen name + problem + suggested fix  
- [ ] **Figma v2** — polished designs Person 2 implements  
- [ ] **Change checklist** — checkbox list Person 2 can tick off  
- [ ] **Screenshot pack** — 6–8 store screenshots with real content  
- [ ] **Beta report** — summary of 10–20 student sessions  

### Week-by-week (design phase)

#### Weeks 10–11
- [ ] Install beta APK / TestFlight / Desktop builds (Win/macOS)
- [ ] Complete UX audit (all student screens on mobile + desktop)
- [ ] Share audit with Person 2

#### Weeks 12–13
- [ ] Run beta with students; collect feedback
- [ ] Start Figma v2 for highest-impact screens (home, PDF, exam, results)

#### Weeks 14–15
- [ ] Finalize Figma v2 + change checklist
- [ ] Create Play Store + App Store screenshots
- [ ] Write app description draft

#### Week 16
- [ ] Verify Person 2 implemented polish items
- [ ] Sign off on visual quality before launch

---

## Integration gates (your part)

| Gate | You must deliver |
|------|------------------|
| **Gate 2 — Content** | 1 subject fully READY + uploaded |
| **Gate 3 — Exams** | 100+ MCQs imported for test subject |
| **Gate 5 — Beta** | Year 1–2 MVP content complete |
| **Gate 6 — Polish** | Figma v2 + change list + screenshots |
| **Gate 7 — Launch** | All launch content PUBLISHED |

---

## What you need from others

| From Person 1 | When |
|---------------|------|
| Staging API (optional) | Week 11 |
| Batch upload help if needed | Week 10 |

| From Person 2 | When |
|---------------|------|
| Admin panel access | Week 6 |
| APK / TestFlight build | Week 10 |
| List of all screen names/routes | Week 10 |
| Implement your design fixes | Week 14–15 |

---

## Content quality checklist (before READY)

**Every MCQ:**
- [ ] Medically accurate (expert reviewed)
- [ ] One clear correct answer
- [ ] Explanation teaches the concept
- [ ] Tags include year or FCPS
- [ ] Image linked if diagram question

**Every PDF:**
- [ ] Compressed
- [ ] Correct year/subject in content-map
- [ ] No password on file
- [ ] Copyright OK

---

## Skills that help you

- Medical / MBBS / FCPS knowledge  
- Attention to detail (explanations, typos)  
- Excel / Google Sheets  
- Basic Figma  
- User testing with students  
- **No coding required**

---

## Weekly sync — your agenda items

1. How many MCQs/PDFs reached READY this week?
2. Which subject/year on track for next gate?
3. Beta feedback highlights?
4. Design polish blockers?

---

## Related docs

- [CONTENT_GUIDE.md](./CONTENT_GUIDE.md) — full content standards
- [PERSON_1_PLATFORM.md](./PERSON_1_PLATFORM.md) — API owner
- [PERSON_2_APPS.md](./PERSON_2_APPS.md) — app/admin owner
- [PRICING.md](./PRICING.md) — plan names for tagging content
- [TEAM_SPLIT.md](./TEAM_SPLIT.md) — overview of all 3 roles

---

**You are critical to launch.** An app without polished QBank and PDFs has no value. Plan content work as **40–50% of the whole project effort.**
