import assert from "node:assert";
import {
  slugify,
  validateSubjectPayload,
  CreateSubjectPayload,
} from "./subjects";

export function runSubjectsDomainTests(): boolean {
  // Test 1: slugify conversion reuse for subject names
  assert.strictEqual(slugify("Gross Anatomy"), "gross-anatomy");
  assert.strictEqual(slugify("Biochemistry & Genetics"), "biochemistry-genetics");

  // Test 2: Valid subject payload passes validation
  const validPayload: CreateSubjectPayload = {
    yearId: "550e8400-e29b-41d4-a716-446655440000",
    name: "Gross Anatomy",
    slug: "gross-anatomy",
    sortOrder: 1,
  };
  const validRes = validateSubjectPayload(validPayload);
  assert.strictEqual(validRes.isValid, true);
  assert.strictEqual(Object.keys(validRes.errors).length, 0);

  // Test 3: Missing or short subject name fails validation
  const invalidNameRes = validateSubjectPayload({
    ...validPayload,
    name: "A",
  });
  assert.strictEqual(invalidNameRes.isValid, false);
  assert.strictEqual(
    invalidNameRes.errors.name,
    "Subject name must be at least 2 characters."
  );

  // Test 4: Uppercase or special char slug fails validation
  const invalidSlugRes = validateSubjectPayload({
    ...validPayload,
    slug: "Gross_Anatomy!",
  });
  assert.strictEqual(invalidSlugRes.isValid, false);
  assert.strictEqual(
    invalidSlugRes.errors.slug,
    "Slug must contain only lowercase letters, numbers, and hyphens."
  );

  // Test 5: Negative sort order fails validation
  const invalidOrderRes = validateSubjectPayload({
    ...validPayload,
    sortOrder: -2,
  });
  assert.strictEqual(invalidOrderRes.isValid, false);
  assert.strictEqual(
    invalidOrderRes.errors.sortOrder,
    "Sort order must be a non-negative integer."
  );

  // Test 6: Missing parent yearId fails validation
  const missingYearRes = validateSubjectPayload({
    ...validPayload,
    yearId: "",
  });
  assert.strictEqual(missingYearRes.isValid, false);
  assert.strictEqual(
    missingYearRes.errors.yearId,
    "Parent academic year is required."
  );

  return true;
}
