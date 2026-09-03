import { getAdminToken } from "./auth";
import { getApiBaseUrl } from "./years";

export enum MaterialType {
  PDF = "PDF",
  VIDEO = "VIDEO",
  NOTES = "NOTES",
}

export interface Material {
  id: string;
  subjectId: string;
  topicId?: string | null;
  title: string;
  type: MaterialType | string;
  fileKey: string;
  fileSizeBytes: string;
  isPublished: boolean;
  isDownloadable: boolean;
  isPastPaper: boolean;
  pastPaperYear?: number | null;
  pastPaperSession?: string | null;
  createdAt: string;
  subject?: {
    name: string;
    slug: string;
    year?: {
      slug: string;
    };
  };
}

export interface UploadMaterialPayload {
  file: File;
  subjectId: string;
  topicId?: string;
  title: string;
  type?: MaterialType | string;
  isDownloadable?: boolean;
  isPastPaper?: boolean;
  pastPaperYear?: number;
  pastPaperSession?: string;
}

export interface UpdateMaterialPayload {
  title?: string;
  topicId?: string;
  isDownloadable?: boolean;
  isPublished?: boolean;
  isPastPaper?: boolean;
  pastPaperYear?: number;
  pastPaperSession?: string;
}

export interface MaterialValidationResult {
  isValid: boolean;
  errors: Record<string, string>;
}

export function formatFileSize(bytesStr: string | number): string {
  const bytes = typeof bytesStr === "number" ? bytesStr : parseInt(bytesStr, 10);
  if (isNaN(bytes) || bytes <= 0) return "0 B";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export function validateUploadMaterialPayload(
  payload: UploadMaterialPayload
): MaterialValidationResult {
  const errors: Record<string, string> = {};

  if (!payload.file) {
    errors.file = "Please select a file to upload.";
  } else {
    const maxSizeBytes = 50 * 1024 * 1024; // 50MB limit from NestJS Multer
    if (payload.file.size > maxSizeBytes) {
      errors.file = "File size exceeds maximum allowed limit of 50MB.";
    }
  }

  if (!payload.subjectId || payload.subjectId.trim().length === 0) {
    errors.subjectId = "Parent subject is required.";
  }

  if (!payload.title || payload.title.trim().length < 2) {
    errors.title = "Material title must be at least 2 characters.";
  } else if (payload.title.trim().length > 500) {
    errors.title = "Material title must not exceed 500 characters.";
  }

  if (payload.isPastPaper) {
    if (payload.pastPaperYear && (payload.pastPaperYear < 1990 || payload.pastPaperYear > 2100)) {
      errors.pastPaperYear = "Past paper year must be between 1990 and 2100.";
    }
  }

  return {
    isValid: Object.keys(errors).length === 0,
    errors,
  };
}

export async function fetchAdminMaterials(
  subjectId?: string,
  customBaseUrl?: string
): Promise<Material[]> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const url = new URL(`${baseUrl}/admin/materials`);
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
    let errorMessage = `Failed to fetch materials (HTTP ${response.status})`;
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
  return data as Material[];
}

export async function uploadAdminMaterial(
  payload: UploadMaterialPayload,
  customBaseUrl?: string
): Promise<Material> {
  const validation = validateUploadMaterialPayload(payload);
  if (!validation.isValid) {
    const firstError = Object.values(validation.errors)[0];
    throw new Error(firstError || "Upload material validation failed.");
  }

  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const formData = new FormData();
  formData.append("file", payload.file);
  formData.append("subjectId", payload.subjectId.trim());
  formData.append("title", payload.title.trim());

  if (payload.topicId && payload.topicId.trim().length > 0) {
    formData.append("topicId", payload.topicId.trim());
  }
  if (payload.type) {
    formData.append("type", payload.type);
  }
  if (payload.isDownloadable !== undefined) {
    formData.append("isDownloadable", String(payload.isDownloadable));
  }
  if (payload.isPastPaper !== undefined) {
    formData.append("isPastPaper", String(payload.isPastPaper));
  }
  if (payload.pastPaperYear !== undefined && payload.pastPaperYear !== null) {
    formData.append("pastPaperYear", String(payload.pastPaperYear));
  }
  if (payload.pastPaperSession && payload.pastPaperSession.trim().length > 0) {
    formData.append("pastPaperSession", payload.pastPaperSession.trim());
  }

  // Note: Do not set Content-Type header when sending FormData so browser sets multipart boundary!
  const response = await fetch(`${baseUrl}/admin/materials/upload`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: formData,
  });

  if (!response.ok) {
    let errorMessage = `Failed to upload material (HTTP ${response.status})`;
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
  return data as Material;
}

export async function updateAdminMaterial(
  id: string,
  payload: UpdateMaterialPayload,
  customBaseUrl?: string
): Promise<Material> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/materials/${encodeURIComponent(id)}`, {
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
    let errorMessage = `Failed to update material (HTTP ${response.status})`;
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
  return data as Material;
}

export async function deleteAdminMaterial(
  id: string,
  customBaseUrl?: string
): Promise<boolean> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const token = getAdminToken();

  const response = await fetch(`${baseUrl}/admin/materials/${encodeURIComponent(id)}`, {
    method: "DELETE",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });

  if (!response.ok) {
    let errorMessage = `Failed to delete material (HTTP ${response.status})`;
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
