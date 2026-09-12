import assert from "node:assert";
import {
  formatConfidence,
  isVerificationDecided,
  officialVsAiSummary,
  formatEvidencePages,
  hasEvidenceConflict,
  AiVerificationRecord,
} from "./ai-verifications";

export function runAiVerificationDomainTests(): boolean {
  const pending: AiVerificationRecord = {
    id: "v1",
    questionId: "q1",
    status: "PENDING",
    isStale: false,
    officialCorrectOptionId: "b",
    officialAnswer: "b",
    aiAssessment: "POSSIBLE_KEY_ISSUE",
    issueType: "POSSIBLE_KEY_ISSUE",
    confidence: 0.72,
    reasoning: "Evidence favors C",
    recommendation: "Human review",
    optionAnalysis: [],
    qualityFlags: [],
    sourceSupport: {
      supportsOfficialKey: false,
      suggestedOptionId: "c",
      notes: "RAG favors C",
    },
    evidence: [
      {
        materialId: "m1",
        title: "Renal Notes",
        subjectName: "Medicine",
        pageStart: 12,
        pageEnd: 13,
        chunkId: "c1",
        documentId: "d1",
        contentHash: "hash1",
        sourceType: "rag",
      },
    ],
    grounding: "rag",
    provider: "gemini",
    model: "m",
    createdAt: new Date().toISOString(),
    decision: null,
    mutatesQuestion: false,
  };

  assert.strictEqual(formatConfidence(0.72), "72%");
  assert.strictEqual(formatConfidence(null), "—");
  assert.strictEqual(isVerificationDecided(pending), false);
  assert.strictEqual(formatEvidencePages(12, 13), "Pages 12–13");
  assert.strictEqual(formatEvidencePages(null, null), null);
  assert.strictEqual(hasEvidenceConflict(pending.sourceSupport), true);

  const decided = {
    ...pending,
    status: "APPROVED" as const,
    decision: {
      decision: "APPROVED" as const,
      decidedAt: new Date().toISOString(),
      adminNote: "Noted",
      decidedBy: { id: "a1" },
    },
  };
  assert.strictEqual(isVerificationDecided(decided), true);

  const summary = officialVsAiSummary(pending);
  assert.strictEqual(summary.official, "Option B");
  assert.strictEqual(summary.assessment, "POSSIBLE_KEY_ISSUE");

  // Approve/reject must never imply MCQ mutation in client contract
  assert.strictEqual(pending.mutatesQuestion, false);

  return true;
}
