"use client";

import { useEffect, useState } from "react";
import Sidebar from "@/components/Sidebar";
import AiVerificationModal from "@/components/AiVerificationModal";
import {
  AiVerificationRecord,
  fetchAiVerification,
  fetchAiVerifications,
  formatConfidence,
} from "@/lib/ai-verifications";

export default function AiVerificationsPage() {
  const [rows, setRows] = useState<AiVerificationRecord[]>([]);
  const [statusFilter, setStatusFilter] = useState<string>("PENDING");
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [reloadToken, setReloadToken] = useState(0);

  const [detailOpen, setDetailOpen] = useState(false);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState<string | null>(null);
  const [detail, setDetail] = useState<AiVerificationRecord | null>(null);

  useEffect(() => {
    let cancelled = false;

    fetchAiVerifications({
      status: statusFilter || undefined,
    })
      .then((data) => {
        if (cancelled) return;
        setRows(data);
        setErrorMessage(null);
        setIsLoading(false);
      })
      .catch((err: unknown) => {
        if (cancelled) return;
        setErrorMessage(
          err instanceof Error ? err.message : "Failed to load verifications."
        );
        setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [statusFilter, reloadToken]);

  const openDetail = async (id: string) => {
    setDetailOpen(true);
    setDetail(null);
    setDetailError(null);
    setDetailLoading(true);
    try {
      const record = await fetchAiVerification(id);
      setDetail(record);
    } catch (err: unknown) {
      setDetailError(
        err instanceof Error ? err.message : "Failed to load verification."
      );
    } finally {
      setDetailLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 overflow-auto">
        <div className="px-8 py-6 border-b border-slate-200 bg-white">
          <h1 className="text-xl font-bold text-slate-900">AI MCQ Reviews</h1>
          <p className="text-xs text-slate-500 mt-1">
            Quality-control verification records. Approving a review does not
            change the official MCQ — use Questions → Edit for that.
          </p>
        </div>

        <div className="p-8 space-y-4">
          <div className="flex items-center gap-3">
            <label className="text-xs font-semibold text-slate-600">
              Status
            </label>
            <select
              value={statusFilter}
              onChange={(e) => {
                setIsLoading(true);
                setStatusFilter(e.target.value);
              }}
              className="px-3 py-2 text-xs rounded-lg border border-slate-300 bg-white"
            >
              <option value="">All</option>
              <option value="PENDING">Pending</option>
              <option value="APPROVED">Approved</option>
              <option value="REJECTED">Rejected</option>
              <option value="FAILED">Failed</option>
            </select>
            <button
              type="button"
              onClick={() => {
                setIsLoading(true);
                setReloadToken((n) => n + 1);
              }}
              className="px-3 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg border border-slate-200"
            >
              Refresh
            </button>
          </div>

          {errorMessage && (
            <div className="p-3 rounded-lg bg-red-50 border border-red-200 text-xs text-red-800">
              {errorMessage}
            </div>
          )}

          {isLoading ? (
            <p className="text-xs text-slate-500">Loading…</p>
          ) : rows.length === 0 ? (
            <p className="text-xs text-slate-500">
              No verification records for this filter. Run “Verify with AI” from
              Questions.
            </p>
          ) : (
            <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                    <th className="py-3 px-4">Question</th>
                    <th className="py-3 px-4">Official</th>
                    <th className="py-3 px-4">AI Assessment</th>
                    <th className="py-3 px-4">Confidence</th>
                    <th className="py-3 px-4">Status</th>
                    <th className="py-3 px-4">Stale</th>
                    <th className="py-3 px-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200">
                  {rows.map((row) => (
                    <tr key={row.id} className="hover:bg-slate-50/80">
                      <td className="py-3 px-4 max-w-xs">
                        <p className="line-clamp-2 font-medium text-slate-900">
                          {row.question?.stem || row.questionId}
                        </p>
                      </td>
                      <td className="py-3 px-4 font-mono font-bold text-teal-700 uppercase">
                        {row.officialCorrectOptionId}
                      </td>
                      <td className="py-3 px-4 font-mono text-slate-700">
                        {row.aiAssessment || row.issueType || "—"}
                      </td>
                      <td className="py-3 px-4">
                        {formatConfidence(row.confidence)}
                      </td>
                      <td className="py-3 px-4">{row.status}</td>
                      <td className="py-3 px-4">
                        {row.isStale ? (
                          <span className="text-amber-700 font-semibold">
                            Yes
                          </span>
                        ) : (
                          "No"
                        )}
                      </td>
                      <td className="py-3 px-4 text-right">
                        <button
                          type="button"
                          onClick={() => void openDetail(row.id)}
                          className="px-2.5 py-1 text-[11px] font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 border border-slate-300 rounded"
                        >
                          Open
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </main>

      {detailOpen && (
        <AiVerificationModal
          record={detail}
          isLoading={detailLoading}
          error={detailError}
          questionStem={detail?.question?.stem}
          onClose={() => {
            setDetailOpen(false);
            setDetail(null);
            setDetailError(null);
            setIsLoading(true);
            setReloadToken((n) => n + 1);
          }}
          onUpdated={(next) => {
            setDetail(next);
            setReloadToken((n) => n + 1);
          }}
        />
      )}
    </div>
  );
}
