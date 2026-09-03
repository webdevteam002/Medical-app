import { getAdminToken } from "./auth";
import { getApiBaseUrl } from "./years";

export interface Exam {
  id: string;
  title: string;
  subjectId: string;
  durationMinutes: number;
  questionCount: number;
  shuffleQuestions: boolean;
  shuffleOptions: boolean;
  isPublished: boolean;
  createdAt: string;
  subject?: {
    name: string;
    year?: {
      name: string;
    };
  };
  _count?: {
    examQuestions: number;
    attempts: number;
  };
}

export interface CreateExamPayload {
  title: string;
  subjectId: string;
  durationMinutes: number;
  shuffleQuestions?: boolean;
  shuffleOptions?: boolean;
}

export interface UpdateExamPayload {
  title?: string;
  durationMinutes?: number;
  shuffleQuestions?: boolean;
  shuffleOptions?: boolean;
  isPublished?: boolean;
}

export interface ExamValidationResult {
  isValid: boolean;
  errors: Record<string, string>;
}

export function validateExamPayload(
  payload: CreateExamPayload
): ExamValidationResult {
  const errors: Record<string, string> = {};

  if (!payload.title || payload.title.trim().length < 3) {
    errors.title = "Exam title must be at least 3 characters.";
  } else if (payload.title.trim().length > 500) {
    errors.title = "Exam title cannot exceed 500 characters.";
  }

  if (!payload.subjectId || payload.subjectId.trim().length === 0) {
    errors.subjectId = "Parent subject is required.";
  }

  if (
    payload.durationMinutes === undefined ||
    payload.durationMinutes === null ||
    isNaN(payload.durationMinutes) ||
    payload.durationMinutes < 1
  ) {
    errors.durationMinutes = "Exam duration must be at least 1 minute.";
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors,
  };
}

export async function fetchAdminExams(
  subjectId?: string,
  customBaseUrl?: string
): Promise<Exam[]> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const url = new URL(`${baseUrl}/admin/exams`);
  if (subjectId && subjectId.trim().length > 0) {
    url.searchParams.set("subjectId", subjectId.trim());
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
    let errorMessage = `Failed to fetch exams (HTTP ${response.status})`;
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
  return data as Exam[];
}

export async function createAdminExam(
  payload: CreateExamPayload,
  customBaseUrl?: string
): Promise<Exam> {
  const validation = validateExamPayload(payload);
  if (!validation.isValid) {
    const firstError = Object.values(validation.errors)[0];
    throw new Error(firstError || "Exam validation failed.");
  }

  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/exams`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({
      title: payload.title.trim(),
      subjectId: payload.subjectId.trim(),
      durationMinutes: Number(payload.durationMinutes),
      shuffleQuestions: payload.shuffleQuestions ?? true,
      shuffleOptions: payload.shuffleOptions ?? false,
    }),
  });

  if (!response.ok) {
    let errorMessage = `Failed to create exam (HTTP ${response.status})`;
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
  return data as Exam;
}

export async function updateAdminExam(
  id: string,
  payload: UpdateExamPayload,
  customBaseUrl?: string
): Promise<Exam> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/exams/${encodeURIComponent(id)}`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    let errorMessage = `Failed to update exam (HTTP ${response.status})`;
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
  return data as Exam;
}

export async function deleteAdminExam(
  id: string,
  customBaseUrl?: string
): Promise<boolean> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/exams/${encodeURIComponent(id)}`, {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });

  if (!response.ok) {
    let errorMessage = `Failed to delete exam (HTTP ${response.status})`;
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

  return true;
}

export async function setAdminExamQuestions(
  examId: string,
  questionIds: string[],
  customBaseUrl?: string
): Promise<Exam> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/exams/${encodeURIComponent(examId)}/questions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({ questionIds }),
  });

  if (!response.ok) {
    let errorMessage = `Failed to set exam questions (HTTP ${response.status})`;
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
  return data as Exam;
}
