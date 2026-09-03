import { getAdminToken } from "./auth";

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

export interface Year {
  id: string;
  name: string;
  slug: string;
  sortOrder: number;
  planType: PlanType;
}

export interface CreateYearPayload {
  name: string;
  slug: string;
  sortOrder: number;
  planType: PlanType;
}

export interface ValidationResult {
  isValid: boolean;
  errors: Record<string, string>;
}

export function slugify(text: string): string {
  return text
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/[\s_]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

export function validateYearPayload(payload: CreateYearPayload): ValidationResult {
  const errors: Record<string, string> = {};

  if (!payload.name || payload.name.trim().length < 2) {
    errors.name = "Name must be at least 2 characters.";
  }

  if (!payload.slug || payload.slug.trim().length < 2) {
    errors.slug = "Slug must be at least 2 characters.";
  } else if (!/^[a-z0-9-]+$/.test(payload.slug.trim())) {
    errors.slug = "Slug must contain only lowercase letters, numbers, and hyphens.";
  }

  if (payload.sortOrder === undefined || payload.sortOrder === null || isNaN(payload.sortOrder)) {
    errors.sortOrder = "Sort order must be a valid number.";
  } else if (payload.sortOrder < 0 || !Number.isInteger(payload.sortOrder)) {
    errors.sortOrder = "Sort order must be a non-negative integer.";
  }

  if (!payload.planType || !Object.values(PlanType).includes(payload.planType)) {
    errors.planType = "Please select a valid subscription plan type.";
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors,
  };
}

export function getApiBaseUrl(): string {
  if (process.env.NEXT_PUBLIC_API_BASE_URL) {
    return process.env.NEXT_PUBLIC_API_BASE_URL;
  }
  return "http://localhost:3000/v1";
}

export async function fetchAdminYears(customBaseUrl?: string): Promise<Year[]> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/years`, {
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
    let errorMessage = `Failed to fetch years (HTTP ${response.status})`;
    try {
      const errData = await response.json();
      if (errData.message) {
        errorMessage = Array.isArray(errData.message)
          ? errData.message.join(", ")
          : errData.message;
      }
    } catch {
      // Ignore JSON parse errors for non-JSON failure responses
    }
    throw new Error(errorMessage);
  }

  const data = await response.json();
  return data as Year[];
}

export async function createAdminYear(
  payload: CreateYearPayload,
  customBaseUrl?: string
): Promise<Year> {
  const validation = validateYearPayload(payload);
  if (!validation.isValid) {
    const firstError = Object.values(validation.errors)[0];
    throw new Error(firstError || "Validation failed.");
  }

  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/years`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({
      name: payload.name.trim(),
      slug: payload.slug.trim(),
      sortOrder: Number(payload.sortOrder),
      planType: payload.planType,
    }),
  });

  if (!response.ok) {
    let errorMessage = `Failed to create year (HTTP ${response.status})`;
    try {
      const errData = await response.json();
      if (errData.message) {
        errorMessage = Array.isArray(errData.message)
          ? errData.message.join(", ")
          : errData.message;
      }
    } catch {
      // Ignore JSON parse errors
    }
    throw new Error(errorMessage);
  }

  const data = await response.json();
  return data as Year;
}
