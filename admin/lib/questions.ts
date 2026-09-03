import { getAdminToken } from "./auth";
import { getApiBaseUrl } from "./years";

export enum Difficulty {
  EASY = "EASY",
  MEDIUM = "MEDIUM",
  HARD = "HARD",
}

export interface QuestionOption {
  id: string;
  text: string;
}

export interface Question {
  id: string;
  subjectId: string;
  stem: string;
  options: QuestionOption[];
  correctOptionId: string;
  explanation: string;
  difficulty: Difficulty | string;
  tags?: string[];
  imageKey?: string | null;
  isPublished: boolean;
  createdAt: string;
  subject?: {
    name: string;
    slug: string;
    year?: {
      slug: string;
    };
  };
}

export interface CreateQuestionPayload {
  subjectId: string;
  stem: string;
  options: QuestionOption[];
  correctOptionId: string;
  explanation: string;
  difficulty?: Difficulty | string;
  tags?: string[];
  imageKey?: string;
}

export interface UpdateQuestionPayload {
  stem?: string;
  options?: QuestionOption[];
  correctOptionId?: string;
  explanation?: string;
  difficulty?: Difficulty | string;
  tags?: string[];
  isPublished?: boolean;
}

export interface CsvImportResult {
  dryRun: boolean;
  imported: number;
  skipped: number;
  errors: Array<{
    row: number;
    reason: string;
  }>;
}

export interface QuestionValidationResult {
  isValid: boolean;
  errors: Record<string, string>;
}

export function validateQuestionPayload(
  payload: CreateQuestionPayload
): QuestionValidationResult {
  const errors: Record<string, string> = {};

  if (!payload.subjectId || payload.subjectId.trim().length === 0) {
    errors.subjectId = "Parent subject is required.";
  }

  if (!payload.stem || payload.stem.trim().length < 5) {
    errors.stem = "Question stem must be at least 5 characters.";
  }

  // Backend rule: options.length must be between 4 and 5
  if (!payload.options || !Array.isArray(payload.options) || payload.options.length < 4 || payload.options.length > 5) {
    errors.options = "Questions require between 4 and 5 options (A, B, C, D, and optional E).";
  } else {
    const emptyOptIndex = payload.options.findIndex((o) => !o.text || o.text.trim().length === 0);
    if (emptyOptIndex !== -1) {
      errors.options = `Option ${payload.options[emptyOptIndex].id.toUpperCase()} text cannot be empty.`;
    }
  }

  if (!payload.correctOptionId || payload.correctOptionId.trim().length === 0) {
    errors.correctOptionId = "Correct option must be selected.";
  } else if (
    payload.options &&
    !payload.options.some((o) => o.id.toLowerCase() === payload.correctOptionId.toLowerCase())
  ) {
    errors.correctOptionId = "Selected correct option must match one of the available options.";
  }

  if (!payload.explanation || payload.explanation.trim().length < 10) {
    errors.explanation = "Explanation must be at least 10 characters.";
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors,
  };
}

export async function fetchAdminQuestions(
  subjectId?: string,
  customBaseUrl?: string
): Promise<Question[]> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const url = new URL(`${baseUrl}/admin/questions`);
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
    let errorMessage = `Failed to fetch questions (HTTP ${response.status})`;
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
  return data as Question[];
}

export async function createAdminQuestion(
  payload: CreateQuestionPayload,
  customBaseUrl?: string
): Promise<Question> {
  const validation = validateQuestionPayload(payload);
  if (!validation.isValid) {
    const firstError = Object.values(validation.errors)[0];
    throw new Error(firstError || "Question validation failed.");
  }

  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/questions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify({
      subjectId: payload.subjectId.trim(),
      stem: payload.stem.trim(),
      options: payload.options,
      correctOptionId: payload.correctOptionId.trim(),
      explanation: payload.explanation.trim(),
      difficulty: payload.difficulty || Difficulty.MEDIUM,
      tags: payload.tags || [],
      imageKey: payload.imageKey || undefined,
    }),
  });

  if (!response.ok) {
    let errorMessage = `Failed to create question (HTTP ${response.status})`;
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
  return data as Question;
}

export async function updateAdminQuestion(
  id: string,
  payload: UpdateQuestionPayload,
  customBaseUrl?: string
): Promise<Question> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/questions/${encodeURIComponent(id)}`, {
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
    let errorMessage = `Failed to update question (HTTP ${response.status})`;
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
  return data as Question;
}

export async function deleteAdminQuestion(
  id: string,
  customBaseUrl?: string
): Promise<boolean> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/questions/${encodeURIComponent(id)}`, {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });

  if (!response.ok) {
    let errorMessage = `Failed to delete question (HTTP ${response.status})`;
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

export async function importAdminQuestionsCsv(
  subjectId: string,
  file: File,
  dryRun = false,
  customBaseUrl?: string
): Promise<CsvImportResult> {
  if (!subjectId || subjectId.trim().length === 0) {
    throw new Error("Parent subject is required for CSV import.");
  }
  if (!file) {
    throw new Error("Please select a CSV file to import.");
  }

  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const formData = new FormData();
  formData.append("file", file);
  formData.append("subjectId", subjectId.trim());
  if (dryRun) {
    formData.append("dryRun", "true");
  }

  const response = await fetch(`${baseUrl}/admin/questions/import`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: formData,
  });

  if (!response.ok) {
    let errorMessage = `CSV import failed (HTTP ${response.status})`;
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
  return data as CsvImportResult;
}
