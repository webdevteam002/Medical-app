# MedStudy — Content Guide (Team 3)

Standards for preparing QBank, PDFs, images, and past papers before import.

---

## 1. QBank rules

### Required per question

- Clear **stem** (question text)
- **4 or 5** options (A–E)
- Exactly **one** correct answer
- **Explanation** — why correct + why common wrong answers fail
- **subject_slug** matching system (e.g. `anatomy`, `pathology`)
- **tags** — include year (`year-2`) or `fcps-part-1`
- **difficulty** — EASY | MEDIUM | HARD

### Quality bar

| Pass | Fail |
|------|------|
| Medically accurate, reviewed by subject expert | Unreviewed draft |
| Explanation teaches the concept | "Answer is A" only |
| Image sharp and labeled if needed | Blurry phone photo |
| No duplicate stems | Same question twice with different wording |

### Import file

Use [templates/qbank-template.csv](./templates/qbank-template.csv)

---

## 2. PDF rules

| Rule | Target |
|------|--------|
| Format | PDF (text-based preferred over scan) |
| Scan DPI | 150 DPI max for compression |
| File size | 2–15 MB typical; max 50 MB |
| Naming | `materials/{year-slug}/{subject-slug}/{descriptive-name}.pdf` |
| Past papers | Set tags: `past-paper;{year}` e.g. `past-paper;2024` |

### Before upload checklist

- [ ] Compressed
- [ ] Correct year/subject in content-map
- [ ] No password protection on PDF
- [ ] Copyright cleared

---

## 3. Image rules (question diagrams)

| Rule | Target |
|------|--------|
| Format | WebP (preferred) or PNG for line art |
| Max width | 1600 px |
| File size | 100–400 KB |
| Naming | `images/questions/{subject}/q{id}-{role}.webp` |
| CSV link | `image_key` column matches R2 path after upload |

---

## 4. content-map.csv

Copy [templates/content-map-template.csv](./templates/content-map-template.csv)

**Status values:**

| Status | Meaning |
|--------|---------|
| DRAFT | Work in progress |
| REVIEW | Expert reviewing |
| READY | OK to upload |
| PUBLISHED | Live in app |
| REJECTED | Needs rewrite |

---

## 5. MVP content targets

| Scope | Minimum |
|-------|---------|
| Years | 1–2 complete first |
| Per subject | 500+ MCQs, core notes PDFs, 2+ past papers |
| Explanations | 100% of published questions |
| Image MCQs | At least 20% of bank (higher for anatomy/pathology) |

---

## 6. FCPS content

- Separate tags: `fcps-part-1` or `fcps-part-2`
- Separate folders: `content/qbanks/fcps-part-1/`
- Do not mix MBBS year tags with FCPS in same file without clear tags

---

## 7. Design polish (Team 3 — after app built)

Not content — but same owner:

1. Audit all screens in TestFlight/APK
2. File UX issues in GitHub Issues / shared doc
3. Provide Figma v2 for Team 2 to implement
4. Prepare Play Store + App Store screenshots with real content

---

See [TEAM_SPLIT.md](./TEAM_SPLIT.md) for full Team 3 responsibilities.
