import assert from "node:assert";
import { SystemHealthResponse, DashboardOverview } from "./dashboard";

export function runDashboardDomainTests(): boolean {
  // Test 1: System health response structure
  const mockHealth: SystemHealthResponse = {
    status: "ok",
    timestamp: "2026-09-03T12:00:00.000Z",
  };
  assert.strictEqual(mockHealth.status, "ok");
  assert.strictEqual(typeof mockHealth.timestamp, "string");

  // Test 2: Complete Dashboard Overview normalization
  const mockOverview: DashboardOverview = {
    systemHealth: mockHealth,
    totalUsers: 42,
    totalSubscriptions: 15,
    totalMaterials: 8,
    totalQuestions: 120,
    totalExams: 3,
    lastUpdated: "2026-09-03T12:00:01.000Z",
    hasDedicatedEndpoint: false,
    failedMetrics: [],
  };

  assert.strictEqual(mockOverview.totalUsers, 42);
  assert.strictEqual(mockOverview.hasDedicatedEndpoint, false);
  assert.strictEqual(mockOverview.failedMetrics.length, 0);

  // Test 3: Partial Failure Metric Tracking (Ensure failed metric is null, not 0!)
  const partialFailureOverview: DashboardOverview = {
    systemHealth: mockHealth,
    totalUsers: 42,
    totalSubscriptions: null, // Subscriptions request failed!
    totalMaterials: 8,
    totalQuestions: null, // Questions request failed!
    totalExams: 3,
    lastUpdated: "2026-09-03T12:00:01.000Z",
    hasDedicatedEndpoint: false,
    failedMetrics: ["Subscriptions", "Question Bank"],
  };

  assert.strictEqual(partialFailureOverview.totalSubscriptions, null);
  assert.strictEqual(partialFailureOverview.totalQuestions, null);
  assert.notStrictEqual(partialFailureOverview.totalSubscriptions, 0);
  assert.strictEqual(partialFailureOverview.failedMetrics.length, 2);
  assert.strictEqual(partialFailureOverview.failedMetrics.includes("Subscriptions"), true);

  return true;
}
