import assert from "node:assert";
import {
  PlanType,
  slugify,
  validateYearPayload,
  CreateYearPayload,
} from "./years";

export function runYearsDomainTests(): boolean {
  // Test 1: slugify conversion
  assert.strictEqual(slugify("1st Year MBBS"), "1st-year-mbbs");
  assert.strictEqual(slugify("FCPS Part 1"), "fcps-part-1");
  assert.strictEqual(slugify("  Anatomy & Physiology  "), "anatomy-physiology");

  // Test 2: Valid payload passes validation
  const validPayload: CreateYearPayload = {
    name: "1st Year MBBS",
    slug: "year-1",
    sortOrder: 1,
    planType: PlanType.YEAR_1,
  };
  const validRes = validateYearPayload(validPayload);
  assert.strictEqual(validRes.isValid, true);
  assert.strictEqual(Object.keys(validRes.errors).length, 0);

  // Test 3: Short name fails validation
  const invalidNameRes = validateYearPayload({
    ...validPayload,
    name: "A",
  });
  assert.strictEqual(invalidNameRes.isValid, false);
  assert.strictEqual(invalidNameRes.errors.name, "Name must be at least 2 characters.");

  // Test 4: Uppercase or special char slug fails validation
  const invalidSlugRes = validateYearPayload({
    ...validPayload,
    slug: "Year_1!",
  });
  assert.strictEqual(invalidSlugRes.isValid, false);
  assert.strictEqual(
    invalidSlugRes.errors.slug,
    "Slug must contain only lowercase letters, numbers, and hyphens."
  );

  // Test 5: Negative sort order fails validation
  const invalidOrderRes = validateYearPayload({
    ...validPayload,
    sortOrder: -1,
  });
  assert.strictEqual(invalidOrderRes.isValid, false);
  assert.strictEqual(
    invalidOrderRes.errors.sortOrder,
    "Sort order must be a non-negative integer."
  );

  // Test 6: Invalid plan type fails validation
  const invalidPlanRes = validateYearPayload({
    ...validPayload,
    planType: "INVALID_PLAN" as PlanType,
  });
  assert.strictEqual(invalidPlanRes.isValid, false);
  assert.strictEqual(
    invalidPlanRes.errors.planType,
    "Please select a valid subscription plan type."
  );

  return true;
}
