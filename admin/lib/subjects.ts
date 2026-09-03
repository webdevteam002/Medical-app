import { getAdminToken } from "./auth";
import { getApiBaseUrl, slugify } from "./years";

export { slugify };

export interface Subject {
  id: string;
  yearId: string;
  name: string;
  slug: string;
  sortOrder: number;
  year?: {
    name: string;
    slug: string;
  };
}

export interface CreateSubjectPayload {
  yearId: string;
  name: string;
  slug: string;
  sortOrder: number;
}

export interface SubjectValidationResult {
  isValid: boolean;
  errors: Record<string, string>;
}

export function validateSubjectPayload(payload: CreateSubjectPayload): SubjectValidationResult {
  const errors: Record<string, string> = {};

  if (!payload.yearId || payload.yearId.trim().length === 0) {
    errors.yearId = "Parent academic year is required.";
  }

  if (!payload.name || payload.name.trim().length < 2) {
    errors.name = "Subject name must be at least 2 characters.";
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

  return {
    isValid: Object.keys(errors).length === 0,
    errors,
  };
}

export async function fetchAdminSubjects(
  yearId?: string,
  customBaseUrl?: string
): Promise<Subject[]> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const url = new URL(`${baseUrl}/admin/subjects`);
  if (yearId && yearId.trim().length > 0) {
    url.searchParams.set("yearId", yearId.trim());
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
    let errorMessage = `Failed to fetch subjects (HTTP ${response.status})`;
    try {
      const errData = await response.json();
      if (errData.message) {
        errorMessage = Array.isArray(errData.message)
          ? errData.message.join(", ")
          : errData.message;
      }
    } catch {
      // Ignore non-JSON response parse error
    }
    throw new Error(errorMessage);
  }

  const data = await response.json();
  return data as Subject[];
}

export async function createAdminSubject(
  payload: CreateSubjectPayload,
  customBaseUrl?: string
): Promise<Subject> {
  const validation = validateSubjectPayload(payload);
  if (!validation.isValid) {
    const firstError = Object.values(validation.errors)[0];
    throw new Error(firstError || "Subject validation failed.");
  }

  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/subjects`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({
      yearId: payload.yearId.trim(),
      name: payload.name.trim(),
      slug: payload.slug.trim(),
      sortOrder: Number(payload.sortOrder),
    }),
  });

  if (!response.ok) {
    let errorMessage = `Failed to create subject (HTTP ${response.status})`;
    try {
      const errData = await response.json();
      if (errData.message) {
        errorMessage = Array.isArray(errData.message)
          ? errData.message.join(", ")
          : errData.message;
      }
    } catch {
      // Ignore parse errors
    }
    throw new Error(errorMessage);
  }

  const data = await response.json();
  return data as Subject;
}
