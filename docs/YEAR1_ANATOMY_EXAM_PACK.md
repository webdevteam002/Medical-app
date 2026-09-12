# Year 1 Anatomy Exam Pack — Admin upload + student test

Use this pack to create a **1st Year Anatomy** mock exam, then take it in the student app (with Gemini live grading if enabled).

## Files

| File | Use |
|------|-----|
| [`year1-anatomy-exam-questions.csv`](./year1-anatomy-exam-questions.csv) | Import into Admin → Questions |

**Contents:** 10 Anatomy MCQs (4 options each) for MBBS Year 1.

---

## A) Admin — import & publish exam

### 1. Open admin
- URL: http://localhost:3001/login  
- Login: `admin@medstudy.local` / `Admin123!`

### 2. Import questions
1. Go to **Questions**
2. Click **Import CSV**
3. Choose subject: **Year 1 → Anatomy**
4. Select `docs/year1-anatomy-exam-questions.csv`
5. Import

### 3. Publish every imported question
On the Questions list (filter Anatomy):
- Click **Publish** on each of the 10 questions  
  (Students only see published questions in exams.)

### 4. Create the exam
1. Go to **Exams**
2. Create exam:
   - Title: `Year 1 Anatomy — Sample Mock`
   - Subject: **Anatomy** (Year 1)
   - Duration: `20` minutes
3. Open **Manage Questions** / question picker
4. Select all 10 imported Anatomy questions → Save
5. **Publish** the exam

### 5. Make sure the student can access Year 1
1. Go to **Users**
2. Find `student@test.com`
3. **Grant Plan** → `YEAR_1` (if not already active)

---

## B) Student — take the exam

```powershell
cd "c:\Users\Administrator\Desktop\Medical app\mobile"
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3000/v1
```

1. Login: `student@test.com` / `Student123!`
2. Open **Exams**
3. Start **Year 1 Anatomy — Sample Mock**
4. Answer → **Submit**
5. Wait for AI grading (snackbar), then open **Review** for correct option + explanation

---

## CSV columns (for your own future packs)

Required:

`stem,option_a,option_b,option_c,option_d,correct_option`

Optional:

`explanation,difficulty,tags,option_e,image_key`

`correct_option` must be `a`, `b`, `c`, `d`, or `e`.

> With **live Gemini grading**, explanations should be multi-sentence teaching text (why correct + why wrong options). Stored CSV explanations are the reliable fallback when AI is unavailable.
