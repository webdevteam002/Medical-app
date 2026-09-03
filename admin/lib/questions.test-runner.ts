import assert from "node:assert";
import {
  validateQuestionPayload,
  CreateQuestionPayload,
  Difficulty,
} from "./questions";

export function runQuestionsDomainTests(): boolean {
  // Test 1: Valid question payload with 4 options passes validation
  const validPayload: CreateQuestionPayload = {
    subjectId: "550e8400-e29b-41d4-a716-446655440000",
    stem: "Which nerve innervates the biceps brachii muscle?",
    options: [
      { id: "a", text: "Musculocutaneous nerve" },
      { id: "b", text: "Radial nerve" },
      { id: "c", text: "Median nerve" },
      { id: "d", text: "Ulnar nerve" },
    ],
    correctOptionId: "a",
    explanation: "The musculocutaneous nerve (C5-C7) innervates the muscles of the anterior compartment of the arm.",
    difficulty: Difficulty.MEDIUM,
  };

  const validRes = validateQuestionPayload(validPayload);
  assert.strictEqual(validRes.isValid, true);
  assert.strictEqual(Object.keys(validRes.errors).length, 0);

  // Test 2: Valid question payload with 5 options passes validation
  const valid5OptPayload: CreateQuestionPayload = {
    ...validPayload,
    options: [
      ...validPayload.options,
      { id: "e", text: "Axillary nerve" },
    ],
  };
  const valid5Res = validateQuestionPayload(valid5OptPayload);
  assert.strictEqual(valid5Res.isValid, true);

  // Test 3: Less than 4 options (<4) fails backend validation rule
  const shortOptionsRes = validateQuestionPayload({
    ...validPayload,
    options: [
      { id: "a", text: "Option A" },
      { id: "b", text: "Option B font-mono" },
      { id: "c", text: "Option C" },
    ],
  });
  assert.strictEqual(shortOptionsRes.isValid, false);
  assert.strictEqual(
    shortOptionsRes.errors.options,
    "Questions require between 4 and 5 options (A, B, C, D, and optional E)."
  );

  // Test 4: Short stem (<5 chars) fails validation
  const shortStemRes = validateQuestionPayload({
    ...validPayload,
    stem: "What",
  });
  assert.strictEqual(shortStemRes.isValid, false);
  assert.strictEqual(shortStemRes.errors.stem, "Question stem must be at least 5 characters.");

  // Test 5: Correct option ID mismatch fails validation
  const mismatchRes = validateQuestionPayload({
    ...validPayload,
    correctOptionId: "z",
  });
  assert.strictEqual(mismatchRes.isValid, false);
  assert.strictEqual(
    mismatchRes.errors.correctOptionId,
    "Selected correct option must match one of the available options."
  );

  // Test 6: Short explanation (<10 chars) fails validation
  const shortExplRes = validateQuestionPayload({
    ...validPayload,
    explanation: "Too short",
  });
  assert.strictEqual(shortExplRes.isValid, false);
  assert.strictEqual(shortExplRes.errors.explanation, "Explanation must be at least 10 characters.");

  return true;
}
