"use client";

import { useState } from "react";
import {
  AiVerificationRecord,
  decideAiVerification,
  formatConfidence,
  formatEvidencePages,
  hasEvidenceConflict,
  isVerificationDecided,
  officialVsAiSummary,
} from "@/lib/ai-verifications";

type Props = {
  record: AiVerificationRecord | null;
  isLoading: boolean;
  error: string | null;
  questionStem?: string;
  onClose: () => void;
  onUpdated: (next: AiVerificationRecord) => void;
};

export default function AiVerificationModal({
  record,
  isLoading,
  error,
  questionStem,
  onClose,
  onUpdated,
}: Props) {
  const [adminNote, setAdminNote] = useState("");
  const [deciding, setDeciding] = useState<"APPROVED" | "REJECTED" | null>(null);
  const [decideError, setDecideError] = useState<string | null>(null);

  const handleDecide = async (decision: "APPROVED" | "REJECTED") => {
    if (!record || isVerificationDecided(record)) return;
    setDeciding(decision);
    setDecideError(null);
    try {
      const updated = await decideAiVerification(
        record.id,
        decision,
        adminNote.trim() || undefined
      );
      onUpdated(updated);
    } catch (err: unknown) {
      setDecideError(
        err instanceof Error ? err.message : "Failed to save decision."
      );
    } finally {
      setDeciding(null);
    }
  };

  const summary = record ? officialVsAiSummary(record) : null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-2xl overflow-hidden border border-slate-100 max-h-[90vh] flex flex-col">
        <div className="px-6 py-5 border-b border-slate-200 flex items-center justify-between bg-slate-50 flex-shrink-0">
          <div>
            <h3 className="text-base font-bold text-slate-900">
              AI MCQ Verification
            </h3>
            <p className="text-xs text-slate-500 mt-0.5">
              Advisory quality review — does not change the official answer
            </p>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 text-lg leading-none p-1 rounded"
            type="button"
          >
            ✕
          </button>
        </div>

        <div className="p-6 overflow-y-auto flex-1 space-y-4 text-xs">
          {isLoading && (
            <div className="p-4 rounded-lg bg-slate-50 border border-slate-200 text-slate-600">
              Running AI verification…
            </div>
          )}

          {error && (
            <div className="p-3 rounded-lg bg-red-50 border border-red-200 text-red-800">
              {error}
            </div>
          )}

          {record && (
            <>
              {record.isStale && (
                <div className="p-3 rounded-lg bg-amber-50 border border-amber-200 text-amber-900">
                  This verification is <strong>stale</strong> — the question was
                  edited after this review. It is not the current verification.
                  Use Edit to change the MCQ manually if needed.
                </div>
              )}

              {record.reused && (
                <div className="p-3 rounded-lg bg-sky-50 border border-sky-200 text-sky-900">
                  Reused existing verification for this question version (no new
                  AI call).
                </div>
              )}

              {questionStem && (
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                    Question
                  </p>
                  <p className="text-slate-800 leading-relaxed line-clamp-4">
                    {questionStem}
                  </p>
                </div>
              )}

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="rounded-lg border-2 border-teal-600 bg-teal-50/60 p-3">
                  <p className="text-[10px] font-bold uppercase tracking-wider text-teal-800 mb-1">
                    Official Answer (MedStudy)
                  </p>
                  <p className="text-sm font-bold text-teal-900">
                    {summary?.official}
                  </p>
                  <p className="text-[11px] text-teal-800/80 mt-1">
                    Authoritative until manually edited
                  </p>
                </div>
                <div className="rounded-lg border border-slate-300 bg-slate-50 p-3">
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                    AI Assessment
                  </p>
                  <p className="text-sm font-bold text-slate-900">
                    {summary?.assessment}
                  </p>
                  <p className="text-[11px] text-slate-500 mt-1">
                    Advisory only — not an automatic key change
                  </p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                    Issue
                  </p>
                  <p className="font-mono text-slate-800">
                    {record.issueType || "—"}
                  </p>
                </div>
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                    Confidence
                  </p>
                  <p className="font-mono text-slate-800">
                    {formatConfidence(record.confidence)}
                  </p>
                </div>
              </div>

              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                  Reasoning
                </p>
                <p className="text-slate-800 leading-relaxed whitespace-pre-wrap">
                  {record.reasoning || "—"}
                </p>
              </div>

              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                  Recommendation
                </p>
                <p className="text-slate-800 leading-relaxed whitespace-pre-wrap">
                  {record.recommendation || "—"}
                </p>
              </div>

              <div>
                <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                  Evidence (authorized MedStudy RAG)
                </p>
                {record.sourceSupport &&
                  hasEvidenceConflict(record.sourceSupport) && (
                    <div className="mb-2 p-2.5 rounded-lg bg-amber-50 border border-amber-200 text-amber-950">
                      <p className="font-semibold">
                        Possible conflict with official answer
                      </p>
                      <p className="mt-0.5">
                        Official key remains{" "}
                        <span className="font-mono font-bold">
                          {record.officialCorrectOptionId.toUpperCase()}
                        </span>
                        {record.sourceSupport.suggestedOptionId
                          ? `; evidence may favor ${record.sourceSupport.suggestedOptionId.toUpperCase()}`
                          : ""}
                        . AI review is advisory — use Edit to change the MCQ.
                      </p>
                    </div>
                  )}
                {record.evidence && record.evidence.length > 0 ? (
                  <ul className="space-y-1.5">
                    {record.evidence.map((e) => {
                      const pages = formatEvidencePages(
                        e.pageStart,
                        e.pageEnd
                      );
                      const meta = [
                        e.subjectName,
                        e.topicName,
                        e.yearSlug,
                      ]
                        .filter(Boolean)
                        .join(" · ");
                      return (
                        <li
                          key={e.chunkId}
                          className="rounded border border-slate-200 bg-white px-3 py-2 text-slate-700"
                        >
                          <span className="font-semibold">{e.title}</span>
                          {meta ? (
                            <span className="block text-slate-500 mt-0.5">
                              {meta}
                            </span>
                          ) : null}
                          {pages ? (
                            <span className="block text-slate-500">{pages}</span>
                          ) : (
                            <span className="block text-slate-400 text-[11px]">
                              Page metadata unavailable
                            </span>
                          )}
                          {e.contentHash ? (
                            <span className="block text-[10px] text-slate-400 font-mono mt-0.5">
                              Source version: {e.contentHash.slice(0, 12)}…
                            </span>
                          ) : null}
                        </li>
                      );
                    })}
                  </ul>
                ) : (
                  <p className="text-slate-500">
                    No authorized RAG evidence retrieved for this review.
                  </p>
                )}
                <p className="text-[11px] text-slate-400 mt-1">
                  Grounding: {record.grounding || "—"} (server-derived
                  evidence only)
                </p>
              </div>

              {record.sourceSupport && (
                <div className="rounded-lg border border-slate-200 bg-slate-50 p-3">
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">
                    Source support (AI interpretation)
                  </p>
                  <p className="text-slate-700">
                    Supports official key:{" "}
                    {record.sourceSupport.supportsOfficialKey === null
                      ? "uncertain"
                      : record.sourceSupport.supportsOfficialKey
                        ? "yes"
                        : "no"}
                    {record.sourceSupport.suggestedOptionId
                      ? ` · Suggested option: ${record.sourceSupport.suggestedOptionId.toUpperCase()}`
                      : ""}
                  </p>
                  <p className="text-slate-600 mt-1">
                    {record.sourceSupport.notes}
                  </p>
                </div>
              )}

              {isVerificationDecided(record) ? (
                <div className="rounded-lg border border-emerald-200 bg-emerald-50 p-3 text-emerald-900">
                  <p className="font-bold">
                    Decision: {record.decision?.decision}
                  </p>
                  {record.decision?.decidedBy?.fullName && (
                    <p className="mt-1">
                      By {record.decision.decidedBy.fullName}
                      {record.decision.decidedAt
                        ? ` · ${new Date(record.decision.decidedAt).toLocaleString()}`
                        : ""}
                    </p>
                  )}
                  {record.decision?.adminNote && (
                    <p className="mt-1">Note: {record.decision.adminNote}</p>
                  )}
                  <p className="mt-2 text-[11px] text-emerald-800/80">
                    This decides the AI review only. To change the MCQ, use Edit.
                  </p>
                </div>
              ) : record.status === "PENDING" ? (
                <div className="space-y-3 border-t border-slate-200 pt-4">
                  <p className="text-[10px] font-bold uppercase tracking-wider text-slate-500">
                    Human decision on AI review
                  </p>
                  <textarea
                    rows={2}
                    value={adminNote}
                    onChange={(e) => setAdminNote(e.target.value)}
                    placeholder="Optional admin note…"
                    className="w-full px-3 py-2 text-xs rounded-lg border border-slate-300 text-slate-900 focus:outline-none focus:ring-2 focus:ring-teal-500"
                  />
                  {decideError && (
                    <p className="text-red-700 bg-red-50 border border-red-200 rounded px-3 py-2">
                      {decideError}
                    </p>
                  )}
                  <div className="flex flex-wrap gap-2">
                    <button
                      type="button"
                      disabled={deciding !== null}
                      onClick={() => handleDecide("APPROVED")}
                      className="px-3 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-700 disabled:bg-teal-400 rounded-lg"
                    >
                      {deciding === "APPROVED"
                        ? "Saving…"
                        : "Approve AI Review"}
                    </button>
                    <button
                      type="button"
                      disabled={deciding !== null}
                      onClick={() => handleDecide("REJECTED")}
                      className="px-3 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 border border-slate-300 disabled:opacity-50 rounded-lg"
                    >
                      {deciding === "REJECTED"
                        ? "Saving…"
                        : "Reject AI Review"}
                    </button>
                  </div>
                  <p className="text-[11px] text-slate-500">
                    Approve/Reject applies to this AI review — not the MCQ
                    itself.
                  </p>
                </div>
              ) : null}

              {record.status === "FAILED" && (
                <div className="p-3 rounded-lg bg-red-50 border border-red-200 text-red-800">
                  Verification failed
                  {record.errorCode ? ` (${record.errorCode})` : ""}. Try again
                  later.
                </div>
              )}
            </>
          )}
        </div>

        <div className="px-6 py-4 border-t border-slate-200 flex justify-end bg-slate-50 flex-shrink-0">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-100 rounded-lg"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
}
