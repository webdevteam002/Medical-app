import { getAdminToken } from "./auth";
import { getApiBaseUrl } from "./years";
import { PlanType, SubscriptionStatus } from "./subscriptions";

export interface ActiveDevice {
  deviceId: string;
  deviceName: string;
  lastActiveAt: string;
}

export interface ActiveSubscription {
  id: string;
  planId: string;
  status: SubscriptionStatus | string;
  startDate: string | null;
  endDate: string | null;
  plan?: {
    name: string;
    planType: PlanType | string;
  };
}

export interface User {
  id: string;
  email: string;
  fullName: string;
  role: string;
  isBanned: boolean;
  createdAt: string;
  activeDevice?: ActiveDevice | null;
  activeSubscription?: ActiveSubscription | null;
}

export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

export interface UserListResponse {
  data: User[];
  meta: PaginationMeta;
}

export async function fetchAdminUsers(
  page = 1,
  limit = 20,
  search?: string,
  customBaseUrl?: string
): Promise<UserListResponse> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const url = new URL(`${baseUrl}/admin/users`);
  url.searchParams.set("page", String(page));
  url.searchParams.set("limit", String(limit));
  if (search && search.trim().length > 0) {
    url.searchParams.set("search", search.trim());
  }

  const response = await fetch(url.toString(), {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    cache: "no-store",
  });

  if (!response.ok) {
    let errorMessage = `Failed to fetch users (HTTP ${response.status})`;
    try {
      const errData = await response.json();
      if (errData.message) {
        errorMessage = Array.isArray(errData.message)
          ? errData.message.join(", ")
          : errData.message;
      }
    } catch {
      // Ignore parse error
    }
    throw new Error(errorMessage);
  }

  const data = await response.json();
  return data as UserListResponse;
}

export async function setAdminUserBanned(
  userId: string,
  isBanned: boolean,
  customBaseUrl?: string
): Promise<{ id: string; email: string; isBanned: boolean }> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/users/${encodeURIComponent(userId)}/ban`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({ isBanned }),
  });

  if (!response.ok) {
    let errorMessage = `Failed to set ban status (HTTP ${response.status})`;
    try {
      const errData = await response.json();
      if (errData.message) {
        errorMessage = Array.isArray(errData.message)
          ? errData.message.join(", ")
          : errData.message;
      }
    } catch {
      // Ignore parse error
    }
    throw new Error(errorMessage);
  }

  const data = await response.json();
  return data;
}

export async function resetAdminUserDevice(
  userId: string,
  customBaseUrl?: string
): Promise<{ success: boolean; message: string }> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/users/${encodeURIComponent(userId)}/reset-device`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });

  if (!response.ok) {
    let errorMessage = `Failed to reset device binding (HTTP ${response.status})`;
    try {
      const errData = await response.json();
      if (errData.message) {
        errorMessage = Array.isArray(errData.message)
          ? errData.message.join(", ")
          : errData.message;
      }
    } catch {
      // Ignore parse error
    }
    throw new Error(errorMessage);
  }

  const data = await response.json();
  return data;
}
