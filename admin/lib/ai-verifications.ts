import { getAdminToken } from "./auth";
import { getApiBaseUrl } from "./years";

export type AiVerificationStatus =
  | "PENDING"
  | "APPROVED"
  | "REJECTED"
  | "FAILED";

export type AiVerificationIssueType =
  | "NONE"
  | "AMBIGUOUS"
  | "POSSIBLE_KEY_ISSUE"
  | "MULTIPLE_PLAUSIBLE_ANSWERS"
  | "INSUFFICIENT_INFORMATION"
  | "EXPLANATION_ISSUE"
  | "OPTION_QUALITY_ISSUE";

export interface AiVerificationEvidence {
  materialId: string;
  title: string;
  subjectName?: string | null;
  topicName?: string | null;
  yearSlug?: string | null;
  pageStart: number | null;
  pageEnd: number | null;
  chunkId: string;
  documentId?: string;
  contentHash?: string | null;
  chunkIndex?: number | null;
  sourceType?: string;
  similarity?: number | null;
}

/** Format page range only when metadata exists. */
export function formatEvidencePages(
  pageStart: number | null | undefined,
  pageEnd: number | null | undefined
): string | null {
  if (pageStart == null) return null;
  if (pageEnd != null && pageEnd !== pageStart) {
    return `Pages ${pageStart}–${pageEnd}`;
  }
  return `Page ${pageStart}`;
}

export function hasEvidenceConflict(
  sourceSupport:
    | {
        supportsOfficialKey: boolean | null;
        suggestedOptionId: string | null;
        notes: string;
      }
    | null
    | undefined
): boolean {
  return sourceSupport?.supportsOfficialKey === false;
}

export interface AiVerificationRecord {
  id: string;
  questionId: string;
  status: AiVerificationStatus;
  isStale: boolean;
  reused?: boolean;
  officialCorrectOptionId: string;
  officialAnswer: string;
  aiAssessment: string | null;
  issueType: AiVerificationIssueType | null;
  confidence: number | null;
  reasoning: string | null;
  recommendation: string | null;
  optionAnalysis: unknown;
  qualityFlags: unknown;
  sourceSupport: {
    supportsOfficialKey: boolean | null;
    suggestedOptionId: string | null;
    notes: string;
  } | null;
  evidence: AiVerificationEvidence[];
  grounding: string | null;
  provider: string | null;
  model: string | null;
  createdAt: string;
  createdBy?: { id: string; email?: string; fullName?: string };
  decision: {
    decision: "APPROVED" | "REJECTED";
    decidedAt: string | null;
    adminNote: string | null;
    decidedBy: { id: string; email?: string; fullName?: string } | null;
  } | null;
  errorCode?: string | null;
  errorMessage?: string | null;
  question?: {
    id: string;
    stem: string;
    correctOptionId: string;
    subject?: {
      id: string;
      name: string;
      year?: { slug: string; name: string };
    } | null;
  } | null;
  mutatesQuestion: boolean;
}

function adminHeaders(): HeadersInit {
  const token = getAdminToken();
  return {
    "Content-Type": "application/json",
    Accept: "application/json",
    "X-Device-Id": "admin-web-dashboard",
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
  };
}

async function readError(response: Response, fallback: string): Promise<string> {
  try {
    const errData = await response.json();
    if (errData.message) {
      return Array.isArray(errData.message)
        ? errData.message.join(", ")
        : String(errData.message);
    }
    if (errData.code) {
      return `${errData.code}: ${fallback}`;
    }
  } catch {
    // ignore
  }
  return `${fallback} (HTTP ${response.status})`;
}

export async function verifyQuestionWithAi(
  questionId: string,
  customBaseUrl?: string
): Promise<AiVerificationRecord> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const response = await fetch(`${baseUrl}/admin/ai/verify-question`, {
    method: "POST",
    headers: adminHeaders(),
    body: JSON.stringify({ questionId }),
  });
  if (!response.ok) {
    throw new Error(await readError(response, "AI verification failed"));
  }
  return (await response.json()) as AiVerificationRecord;
}

export async function fetchAiVerifications(
  filters?: {
    status?: string;
    issueType?: string;
    questionId?: string;
    subjectId?: string;
    yearSlug?: string;
  },
  customBaseUrl?: string
): Promise<AiVerificationRecord[]> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const url = new URL(`${baseUrl}/admin/ai/verifications`);
  if (filters?.status) url.searchParams.set("status", filters.status);
  if (filters?.issueType) url.searchParams.set("issueType", filters.issueType);
  if (filters?.questionId) url.searchParams.set("questionId", filters.questionId);
  if (filters?.subjectId) url.searchParams.set("subjectId", filters.subjectId);
  if (filters?.yearSlug) url.searchParams.set("yearSlug", filters.yearSlug);

  const response = await fetch(url.toString(), {
    method: "GET",
    headers: adminHeaders(),
    cache: "no-store",
  });
  if (!response.ok) {
    throw new Error(await readError(response, "Failed to load verifications"));
  }
  return (await response.json()) as AiVerificationRecord[];
}

export async function fetchAiVerification(
  id: string,
  customBaseUrl?: string
): Promise<AiVerificationRecord> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const response = await fetch(
    `${baseUrl}/admin/ai/verifications/${encodeURIComponent(id)}`,
    {
      method: "GET",
      headers: adminHeaders(),
      cache: "no-store",
    }
  );
  if (!response.ok) {
    throw new Error(await readError(response, "Failed to load verification"));
  }
  return (await response.json()) as AiVerificationRecord;
}

export async function decideAiVerification(
  id: string,
  decision: "APPROVED" | "REJECTED",
  adminNote?: string,
  customBaseUrl?: string
): Promise<AiVerificationRecord> {
  const baseUrl = customBaseUrl || getApiBaseUrl();
  const response = await fetch(
    `${baseUrl}/admin/ai/verifications/${encodeURIComponent(id)}/decide`,
    {
      method: "POST",
      headers: adminHeaders(),
      body: JSON.stringify({
        decision,
        ...(adminNote && adminNote.trim() ? { adminNote: adminNote.trim() } : {}),
      }),
    }
  );
  if (!response.ok) {
    throw new Error(await readError(response, "Failed to save decision"));
  }
  return (await response.json()) as AiVerificationRecord;
}

/** Pure helpers for UI / domain tests — no network. */
export function formatConfidence(value: number | null | undefined): string {
  if (value === null || value === undefined || Number.isNaN(value)) return "—";
  return `${Math.round(value * 100)}%`;
}

export function isVerificationDecided(record: AiVerificationRecord): boolean {
  return record.status === "APPROVED" || record.status === "REJECTED";
}

export function officialVsAiSummary(record: AiVerificationRecord): {
  official: string;
  assessment: string;
} {
  return {
    official: `Option ${record.officialCorrectOptionId.toUpperCase()}`,
    assessment: record.aiAssessment || record.issueType || "Unavailable",
  };
}
