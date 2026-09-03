"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import Sidebar from "@/components/Sidebar";
import { DashboardOverview, fetchDashboardOverview } from "@/lib/dashboard";

export default function AdminDashboardPage() {
  const [overview, setOverview] = useState<DashboardOverview | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const loadDashboardData = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const data = await fetchDashboardOverview();
      setOverview(data);
    } catch (err: unknown) {
      setErrorMessage(
        err instanceof Error ? err.message : "Failed to load dashboard overview data."
      );
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    let isMounted = true;
    Promise.resolve().then(() => {
      if (isMounted) {
        loadDashboardData();
      }
    });
    return () => {
      isMounted = false;
    };
  }, [loadDashboardData]);

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 flex flex-col min-w-0">
        {/* Top Header */}
        <header className="bg-white border-b border-slate-200 px-8 py-5 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-bold text-slate-900 tracking-tight">
              MedStudy Administration Overview
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Real-time medical platform metrics, system health, and entity management foundation
            </p>
          </div>

          <button
            onClick={loadDashboardData}
            disabled={isLoading}
            className="px-3.5 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 disabled:opacity-50 rounded-lg transition-colors border border-slate-200 flex items-center gap-1.5 self-start md:self-auto"
            aria-label="Refresh dashboard metrics"
          >
            <svg
              className={`w-3.5 h-3.5 ${isLoading ? "animate-spin" : ""}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
            Refresh Dashboard
          </button>
        </header>

        {/* Content Area */}
        <div className="p-8 max-w-7xl space-y-6">
          {/* Honest Backend Disclaimer */}
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 flex items-start gap-3 text-xs text-amber-900 shadow-sm">
            <span className="text-amber-600 text-base">ℹ️</span>
            <div>
              <p className="font-semibold">Backend Architecture Audit</p>
              <p className="mt-0.5 text-amber-800 leading-relaxed">
                Person 1&apos;s NestJS backend does not expose a single aggregate <code className="bg-amber-100 px-1 py-0.5 rounded font-mono">GET /v1/admin/dashboard</code> endpoint. System & Database Health is verified via <code className="bg-amber-100 px-1 py-0.5 rounded font-mono">GET /v1/health</code>. Total Students count is derived from <code className="bg-amber-100 px-1 py-0.5 rounded font-mono">GET /v1/admin/users</code> pagination metadata (<code className="font-mono">meta.total</code>). Subscriptions, materials, questions, and exams counts are derived from their verified unpaginated admin domain controllers.
              </p>
            </div>
          </div>

          {/* Partial Metric Failure Warning */}
          {overview && overview.failedMetrics.length > 0 && (
            <div className="bg-red-50 border border-red-200 rounded-xl p-4 flex items-start gap-3 text-xs text-red-900 shadow-sm">
              <span className="text-red-600 text-base">⚠️</span>
              <div>
                <p className="font-semibold">Partial Metrics Fetch Failure</p>
                <p className="mt-0.5 text-red-800 leading-relaxed">
                  The following endpoint metric requests failed: <strong className="font-mono">{overview.failedMetrics.join(", ")}</strong>. Failed metrics are displayed as &quot;N/A&quot; to prevent inaccurate zero values.
                </p>
              </div>
            </div>
          )}

          {/* Loading & Error States */}
          {isLoading ? (
            <div className="bg-white rounded-xl border border-slate-200 p-12 text-center shadow-sm">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-slate-200 border-t-teal-600 mb-3"></div>
              <p className="text-sm font-medium text-slate-600">
                Verifying system health and entity metrics...
              </p>
            </div>
          ) : errorMessage ? (
            <div className="bg-white rounded-xl border border-slate-200 p-8 text-center shadow-sm">
              <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-100 text-red-600 text-xl mb-3">
                ⚠️
              </div>
              <h3 className="text-base font-semibold text-slate-900 mb-1">
                Failed to Load Dashboard Data
              </h3>
              <p className="text-xs text-slate-500 max-w-md mx-auto mb-5">
                {errorMessage}
              </p>
              <button
                onClick={loadDashboardData}
                className="px-4 py-2 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 rounded-lg transition-colors inline-flex items-center gap-1.5"
              >
                Retry Request
              </button>
            </div>
          ) : overview && (
            <>
              {/* System & Database Health Card */}
              <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div className="flex items-center gap-3">
                  <div className={`p-3 rounded-xl border ${
                    overview.systemHealth?.status === "ok"
                      ? "bg-emerald-50 border-emerald-200 text-emerald-700"
                      : "bg-red-50 border-red-200 text-red-700"
                  }`}>
                    <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>
                  <div>
                    <h2 className="text-sm font-bold text-slate-900">
                      API & Database Health Status
                    </h2>
                    <p className="text-xs text-slate-500 mt-0.5">
                      Endpoint: <code className="font-mono bg-slate-100 px-1 py-0.5 rounded">GET /v1/health</code> &bull; Verified DB Query <code className="font-mono bg-slate-100 px-1 py-0.5 rounded">SELECT 1</code>
                    </p>
                  </div>
                </div>

                <div className="flex flex-col sm:items-end gap-1">
                  {overview.systemHealth?.status === "ok" ? (
                    <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                      ● ONLINE (status: ok)
                    </span>
                  ) : (
                    <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-bold bg-red-50 text-red-700 border border-red-200">
                      ○ HEALTH CHECK UNCERTAIN / UNREACHABLE
                    </span>
                  )}
                  <span className="text-[10px] text-slate-400 font-mono">
                    Checked at: {new Date(overview.lastUpdated).toLocaleTimeString()}
                  </span>
                </div>
              </div>

              {/* Entity Metrics Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
                {/* Total Students */}
                <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex flex-col justify-between">
                  <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Total Students
                  </span>
                  <div className="mt-3 flex items-baseline justify-between">
                    <span className="text-2xl font-extrabold text-slate-900">
                      {overview.totalUsers !== null ? overview.totalUsers : "N/A"}
                    </span>
                    <span className="text-[10px] font-semibold text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                      meta.total
                    </span>
                  </div>
                </div>

                {/* Subscriptions */}
                <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex flex-col justify-between">
                  <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Subscriptions
                  </span>
                  <div className="mt-3 flex items-baseline justify-between">
                    <span className="text-2xl font-extrabold text-teal-700">
                      {overview.totalSubscriptions !== null ? overview.totalSubscriptions : "N/A"}
                    </span>
                    <span className="text-[10px] font-semibold text-teal-800 bg-teal-50 px-2 py-0.5 rounded border border-teal-200">
                      Total Records
                    </span>
                  </div>
                </div>

                {/* PDF Materials */}
                <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex flex-col justify-between">
                  <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                    PDF Materials
                  </span>
                  <div className="mt-3 flex items-baseline justify-between">
                    <span className="text-2xl font-extrabold text-slate-900">
                      {overview.totalMaterials !== null ? overview.totalMaterials : "N/A"}
                    </span>
                    <span className="text-[10px] font-semibold text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                      Files
                    </span>
                  </div>
                </div>

                {/* Question Bank */}
                <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex flex-col justify-between">
                  <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Question Bank
                  </span>
                  <div className="mt-3 flex items-baseline justify-between">
                    <span className="text-2xl font-extrabold text-slate-900">
                      {overview.totalQuestions !== null ? overview.totalQuestions : "N/A"}
                    </span>
                    <span className="text-[10px] font-semibold text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                      MCQs
                    </span>
                  </div>
                </div>

                {/* Exams */}
                <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex flex-col justify-between">
                  <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Exams
                  </span>
                  <div className="mt-3 flex items-baseline justify-between">
                    <span className="text-2xl font-extrabold text-slate-900">
                      {overview.totalExams !== null ? overview.totalExams : "N/A"}
                    </span>
                    <span className="text-[10px] font-semibold text-slate-500 bg-slate-100 px-2 py-0.5 rounded">
                      Papers
                    </span>
                  </div>
                </div>
              </div>

              {/* Quick Module Navigation Section */}
              <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-sm space-y-4">
                <h2 className="text-sm font-bold text-slate-900 uppercase tracking-wider">
                  Admin Modules Shortcuts
                </h2>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs font-semibold">
                  <Link
                    href="/years"
                    className="p-3 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-slate-800 transition-colors flex items-center justify-between"
                  >
                    <span>📅 Academic Years</span>
                    <span className="text-slate-400">→</span>
                  </Link>

                  <Link
                    href="/subjects"
                    className="p-3 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-slate-800 transition-colors flex items-center justify-between"
                  >
                    <span>📚 Subjects</span>
                    <span className="text-slate-400">→</span>
                  </Link>

                  <Link
                    href="/topics"
                    className="p-3 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-slate-800 transition-colors flex items-center justify-between"
                  >
                    <span>🏷️ Topics</span>
                    <span className="text-slate-400">→</span>
                  </Link>

                  <Link
                    href="/materials"
                    className="p-3 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-slate-800 transition-colors flex items-center justify-between"
                  >
                    <span>📄 Materials & R2</span>
                    <span className="text-slate-400">→</span>
                  </Link>

                  <Link
                    href="/questions"
                    className="p-3 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-slate-800 transition-colors flex items-center justify-between"
                  >
                    <span>❓ Question Bank</span>
                    <span className="text-slate-400">→</span>
                  </Link>

                  <Link
                    href="/exams"
                    className="p-3 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-slate-800 transition-colors flex items-center justify-between"
                  >
                    <span>📝 Exams & Shuffling</span>
                    <span className="text-slate-400">→</span>
                  </Link>

                  <Link
                    href="/users"
                    className="p-3 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-slate-800 transition-colors flex items-center justify-between"
                  >
                    <span>👤 Student Users</span>
                    <span className="text-slate-400">→</span>
                  </Link>

                  <Link
                    href="/subscriptions"
                    className="p-3 bg-slate-50 hover:bg-slate-100 border border-slate-200 rounded-lg text-slate-800 transition-colors flex items-center justify-between"
                  >
                    <span>💳 Subscriptions</span>
                    <span className="text-slate-400">→</span>
                  </Link>
                </div>
              </div>
            </>
          )}
        </div>
      </main>
    </div>
  );
}
