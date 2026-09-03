import assert from "node:assert";
import {
  validateGrantSubscriptionPayload,
  GrantSubscriptionPayload,
  PlanType,
} from "./subscriptions";

export function runSubscriptionsDomainTests(): boolean {
  // Test 1: Valid grant payload passes validation
  const validPayload: GrantSubscriptionPayload = {
    planType: PlanType.YEAR_1,
    durationDays: 365,
  };
  const validRes = validateGrantSubscriptionPayload(validPayload);
  assert.strictEqual(validRes.isValid, true);
  assert.strictEqual(Object.keys(validRes.errors).length, 0);

  // Test 2: Missing planType fails validation
  const missingPlanRes = validateGrantSubscriptionPayload({
    ...validPayload,
    planType: "" as PlanType,
  });
  assert.strictEqual(missingPlanRes.isValid, false);
  assert.strictEqual(missingPlanRes.errors.planType, "Subscription plan type is required.");

  // Test 3: Invalid durationDays (<1) fails validation
  const invalidDurationRes = validateGrantSubscriptionPayload({
    ...validPayload,
    durationDays: 0,
  });
  assert.strictEqual(invalidDurationRes.isValid, false);
  assert.strictEqual(
    invalidDurationRes.errors.durationDays,
    "Subscription duration must be at least 1 day."
  );

  return true;
}
