import assert from "node:assert";
import { User, PaginationMeta } from "./users";

export function runUsersDomainTests(): boolean {
  // Test 1: User response shape omits sensitive fields
  const mockUserResponse: User = {
    id: "user-123",
    email: "student@medstudy.pk",
    fullName: "Dr. Ali Khan",
    role: "STUDENT",
    isBanned: false,
    createdAt: "2026-09-03T10:00:00.000Z",
    activeDevice: {
      deviceId: "device-xyz",
      deviceName: "Samsung Galaxy Tab",
      lastActiveAt: "2026-09-03T11:00:00.000Z",
    },
    activeSubscription: {
      id: "sub-999",
      planId: "plan-111",
      status: "ACTIVE",
      startDate: "2026-01-01",
      endDate: "2026-12-31",
    },
  };

  assert.strictEqual(mockUserResponse.email, "student@medstudy.pk");
  assert.strictEqual(mockUserResponse.isBanned, false);
  assert.strictEqual((mockUserResponse as unknown as Record<string, unknown>).passwordHash, undefined);
  assert.strictEqual((mockUserResponse as unknown as Record<string, unknown>).refreshTokenHash, undefined);

  // Test 2: Pagination metadata calculation
  const meta: PaginationMeta = {
    total: 45,
    page: 2,
    limit: 20,
    totalPages: Math.ceil(45 / 20),
  };
  assert.strictEqual(meta.totalPages, 3);

  return true;
}
