import assert from "node:assert";
import {
  validateTopicPayload,
  CreateTopicPayload,
} from "./topics";

export function runTopicsDomainTests(): boolean {
  // Test 1: Valid topic payload passes validation
  const validPayload: CreateTopicPayload = {
    subjectId: "660e8400-e29b-41d4-a716-446655440000",
    name: "Brachial Plexus",
    sortOrder: 1,
  };
  const validRes = validateTopicPayload(validPayload);
  assert.strictEqual(validRes.isValid, true);
  assert.strictEqual(Object.keys(validRes.errors).length, 0);

  // Test 2: Missing or short topic name fails validation
  const invalidNameRes = validateTopicPayload({
    ...validPayload,
    name: "A",
  });
  assert.strictEqual(invalidNameRes.isValid, false);
  assert.strictEqual(
    invalidNameRes.errors.name,
    "Topic name must be at least 2 characters."
  );

  // Test 3: Negative sort order fails validation
  const invalidOrderRes = validateTopicPayload({
    ...validPayload,
    sortOrder: -3,
  });
  assert.strictEqual(invalidOrderRes.isValid, false);
  assert.strictEqual(
    invalidOrderRes.errors.sortOrder,
    "Sort order must be a non-negative integer."
  );

  // Test 4: Missing parent subjectId fails validation
  const missingSubjectRes = validateTopicPayload({
    ...validPayload,
    subjectId: "",
  });
  assert.strictEqual(missingSubjectRes.isValid, false);
  assert.strictEqual(
    missingSubjectRes.errors.subjectId,
    "Parent subject is required."
  );

  return true;
}
