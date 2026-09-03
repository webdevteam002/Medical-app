import assert from "node:assert";
import {
  validateExamPayload,
  CreateExamPayload,
} from "./exams";

export function runExamsDomainTests(): boolean {
  // Test 1: Valid exam payload passes validation
  const validPayload: CreateExamPayload = {
    title: "Gross Anatomy Midterm Examination 2024",
    subjectId: "550e8400-e29b-41d4-a716-446655440000",
    durationMinutes: 60,
    shuffleQuestions: true,
    shuffleOptions: false,
  };

  const validRes = validateExamPayload(validPayload);
  assert.strictEqual(validRes.isValid, true);
  assert.strictEqual(Object.keys(validRes.errors).length, 0);

  // Test 2: Short title (<3 chars) fails validation
  const shortTitleRes = validateExamPayload({
    ...validPayload,
    title: "Ex",
  });
  assert.strictEqual(shortTitleRes.isValid, false);
  assert.strictEqual(shortTitleRes.errors.title, "Exam title must be at least 3 characters.");

  // Test 3: Missing parent subjectId fails validation
  const missingSubjectRes = validateExamPayload({
    ...validPayload,
    subjectId: "",
  });
  assert.strictEqual(missingSubjectRes.isValid, false);
  assert.strictEqual(missingSubjectRes.errors.subjectId, "Parent subject is required.");

  // Test 4: Invalid durationMinutes (<1) fails validation
  const invalidDurationRes = validateExamPayload({
    ...validPayload,
    durationMinutes: 0,
  });
  assert.strictEqual(invalidDurationRes.isValid, false);
  assert.strictEqual(
    invalidDurationRes.errors.durationMinutes,
    "Exam duration must be at least 1 minute."
  );

  return true;
}
