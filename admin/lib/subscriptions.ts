import { getAdminToken } from "./auth";
import { getApiBaseUrl } from "./years";

export enum SubscriptionStatus {
  ACTIVE = "ACTIVE",
  CANCELLED = "CANCELLED",
  EXPIRED = "EXPIRED",
  PENDING = "PENDING",
}

export enum PlanType {
  YEAR_1 = "YEAR_1",
  YEAR_2 = "YEAR_2",
  YEAR_3 = "YEAR_3",
  YEAR_4 = "YEAR_4",
  YEAR_5 = "YEAR_5",
  FCPS_PART_1 = "FCPS_PART_1",
  FCPS_PART_2 = "FCPS_PART_2",
  ALL_MBBS = "ALL_MBBS",
  ULTIMATE_BUNDLE = "ULTIMATE_BUNDLE",
}

export interface SubscriptionPlan {
  id: string;
  name: string;
  planType: PlanType | string;
  pricePkr: number;
  durationDays: number;
}

export interface Subscription {
  id: string;
  userId: string;
  planId: string;
  status: SubscriptionStatus | string;
  startDate: string | null;
  endDate: string | null;
  revenuecatSubscriberId?: string | null;
  createdAt: string;
  plan?: SubscriptionPlan;
  user?: {
    id: string;
    email: string;
    fullName: string;
  };
}

export interface GrantSubscriptionPayload {
  planType: PlanType | string;
  durationDays?: number;
}

export interface GrantSubscriptionValidationResult {
  isValid: boolean;
  errors: Record<string, string>;
}

export function validateGrantSubscriptionPayload(
  payload: GrantSubscriptionPayload
): GrantSubscriptionValidationResult {
  const errors: Record<string, string> = {};

  if (!payload.planType) {
    errors.planType = "Subscription plan type is required.";
  }

  if (
    payload.durationDays !== undefined &&
    payload.durationDays !== null &&
    (isNaN(payload.durationDays) || payload.durationDays < 1)
  ) {
    errors.durationDays = "Subscription duration must be at least 1 day.";
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors,
  };
}

export async function fetchAdminSubscriptions(
  status?: string,
  userId?: string,
  customBaseUrl?: string
): Promise<Subscription[]> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const url = new URL(`${baseUrl}/admin/subscriptions`);
  if (status && status.trim().length > 0) {
    url.searchParams.set("status", status.trim());
  }
  if (userId && userId.trim().length > 0) {
    url.searchParams.set("userId", userId.trim());
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
    let errorMessage = `Failed to fetch subscriptions (HTTP ${response.status})`;
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
  return data as Subscription[];
}

export async function grantAdminSubscription(
  userId: string,
  payload: GrantSubscriptionPayload,
  customBaseUrl?: string
): Promise<Subscription> {
  const validation = validateGrantSubscriptionPayload(payload);
  if (!validation.isValid) {
    const firstError = Object.values(validation.errors)[0];
    throw new Error(firstError || "Grant subscription validation failed.");
  }

  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/subscriptions/users/${encodeURIComponent(userId)}/grant`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({
      planType: payload.planType,
      durationDays: payload.durationDays ?? 365,
    }),
  });

  if (!response.ok) {
    let errorMessage = `Failed to grant subscription (HTTP ${response.status})`;
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
  return data as Subscription;
}

export async function revokeAdminSubscription(
  subscriptionId: string,
  customBaseUrl?: string
): Promise<Subscription> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/subscriptions/${encodeURIComponent(subscriptionId)}/revoke`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });

  if (!response.ok) {
    let errorMessage = `Failed to revoke subscription (HTTP ${response.status})`;
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
  return data as Subscription;
}
