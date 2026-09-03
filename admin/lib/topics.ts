import { getAdminToken } from "./auth";
import { getApiBaseUrl } from "./years";

export interface Topic {
  id: string;
  subjectId: string;
  name: string;
  sortOrder: number;
  subject?: {
    name: string;
    slug: string;
  };
}

export interface CreateTopicPayload {
  subjectId: string;
  name: string;
  sortOrder: number;
}

export interface TopicValidationResult {
  isValid: boolean;
  errors: Record<string, string>;
}

export function validateTopicPayload(payload: CreateTopicPayload): TopicValidationResult {
  const errors: Record<string, string> = {};

  if (!payload.subjectId || payload.subjectId.trim().length === 0) {
    errors.subjectId = "Parent subject is required.";
  }

  if (!payload.name || payload.name.trim().length < 2) {
    errors.name = "Topic name must be at least 2 characters.";
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

export async function fetchAdminTopics(
  subjectId: string,
  customBaseUrl?: string
): Promise<Topic[]> {
  if (!subjectId || subjectId.trim().length === 0) {
    return [];
  }

  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/subjects/${encodeURIComponent(subjectId)}/topics`, {
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
    let errorMessage = `Failed to fetch topics (HTTP ${response.status})`;
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
  return data as Topic[];
}

export async function createAdminTopic(
  payload: CreateTopicPayload,
  customBaseUrl?: string
): Promise<Topic> {
  const validation = validateTopicPayload(payload);
  if (!validation.isValid) {
    const firstError = Object.values(validation.errors)[0];
    throw new Error(firstError || "Topic validation failed.");
  }

  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/topics`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({
      subjectId: payload.subjectId.trim(),
      name: payload.name.trim(),
      sortOrder: Number(payload.sortOrder),
    }),
  });

  if (!response.ok) {
    let errorMessage = `Failed to create topic (HTTP ${response.status})`;
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
  return data as Topic;
}
