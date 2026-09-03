import { getApiBaseUrl } from "./years";
import { fetchAdminUsers } from "./users";
import { fetchAdminSubscriptions } from "./subscriptions";
import { fetchAdminMaterials } from "./materials";
import { fetchAdminQuestions } from "./questions";
import { fetchAdminExams } from "./exams";

export interface SystemHealthResponse {
  status: string;
  timestamp: string;
}

export interface DashboardOverview {
  systemHealth: SystemHealthResponse | null;
  totalUsers: number | null;
  totalSubscriptions: number | null;
  totalMaterials: number | null;
  totalQuestions: number | null;
  totalExams: number | null;
  lastUpdated: string;
  hasDedicatedEndpoint: boolean;
  failedMetrics: string[];
}

export async function fetchSystemHealth(customBaseUrl?: string): Promise<SystemHealthResponse> {
  const baseUrl = customBaseUrl || getApiBaseUrl();

  const response = await fetch(`${baseUrl}/health`, {
    method: "GET",
    headers: {
      Accept: "application/json",
    },
    cache: "no-store",
  });

  if (!response.ok) {
    throw new Error(`Health check failed (HTTP ${response.status})`);
  }

  const data = await response.json();
  return data as SystemHealthResponse;
}

export async function fetchDashboardOverview(customBaseUrl?: string): Promise<DashboardOverview> {
  let health: SystemHealthResponse | null = null;
  let userCount: number | null = null;
  let subCount: number | null = null;
  let materialCount: number | null = null;
  let questionCount: number | null = null;
  let examCount: number | null = null;
  const failedMetrics: string[] = [];

  const results = await Promise.allSettled([
    fetchSystemHealth(customBaseUrl),
    fetchAdminUsers(1, 1, undefined, customBaseUrl),
    fetchAdminSubscriptions(undefined, undefined, customBaseUrl),
    fetchAdminMaterials(undefined, customBaseUrl),
    fetchAdminQuestions(undefined, customBaseUrl),
    fetchAdminExams(undefined, customBaseUrl),
  ]);

  // Index 0: Health
  if (results[0].status === "fulfilled") {
    health = results[0].value;
  } else {
    failedMetrics.push("System Health");
  }

  // Index 1: Users (Paginated, uses meta.total)
  if (results[1].status === "fulfilled") {
    userCount = results[1].value.meta.total;
  } else {
    failedMetrics.push("Total Students");
  }

  // Index 2: Subscriptions (Unpaginated, uses array length)
  if (results[2].status === "fulfilled") {
    subCount = results[2].value.length;
  } else {
    failedMetrics.push("Subscriptions");
  }

  // Index 3: Materials (Unpaginated, uses array length)
  if (results[3].status === "fulfilled") {
    materialCount = results[3].value.length;
  } else {
    failedMetrics.push("PDF Materials");
  }

  // Index 4: Questions (Unpaginated, uses array length)
  if (results[4].status === "fulfilled") {
    questionCount = results[4].value.length;
  } else {
    failedMetrics.push("Question Bank");
  }

  // Index 5: Exams (Unpaginated, uses array length)
  if (results[5].status === "fulfilled") {
    examCount = results[5].value.length;
  } else {
    failedMetrics.push("Exams");
  }

  return {
    systemHealth: health,
    totalUsers: userCount,
    totalSubscriptions: subCount,
    totalMaterials: materialCount,
    totalQuestions: questionCount,
    totalExams: examCount,
    lastUpdated: new Date().toISOString(),
    hasDedicatedEndpoint: false, // Honest flag: Backend does not expose GET /v1/admin/dashboard
    failedMetrics,
  };
}
