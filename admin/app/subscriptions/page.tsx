"use client";

import { useEffect, useState, useCallback } from "react";
import Sidebar from "@/components/Sidebar";
import {
  Subscription,
  SubscriptionStatus,
  fetchAdminSubscriptions,
  revokeAdminSubscription,
} from "@/lib/subscriptions";

export default function SubscriptionsManagementPage() {
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [selectedStatusFilter, setSelectedStatusFilter] = useState<string>("");

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const [pendingRevokeId, setPendingRevokeId] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;
    fetchAdminSubscriptions()
      .then((data) => {
        if (isMounted) {
          setSubscriptions(data);
          setIsLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (isMounted) {
          setErrorMessage(
            err instanceof Error ? err.message : "Failed to load subscriptions."
          );
          setIsLoading(false);
        }
      });
    return () => {
      isMounted = false;
    };
  }, []);

  const handleRefresh = useCallback(async () => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const data = await fetchAdminSubscriptions(selectedStatusFilter || undefined);
      setSubscriptions(data);
    } catch (err: unknown) {
      setErrorMessage(
        err instanceof Error ? err.message : "Failed to load subscriptions."
      );
    } finally {
      setIsLoading(false);
    }
  }, [selectedStatusFilter]);

  const handleStatusFilterChange = async (statusFilter: string) => {
    setSelectedStatusFilter(statusFilter);
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const data = await fetchAdminSubscriptions(statusFilter || undefined);
      setSubscriptions(data);
    } catch (err: unknown) {
      setErrorMessage(
        err instanceof Error ? err.message : "Failed to filter subscriptions."
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleRevoke = async (sub: Subscription) => {
    if (
      !confirm(
        `Are you sure you want to revoke the active subscription for "${sub.user?.fullName || sub.user?.email || "this user"}"? Access will end immediately.`
      )
    ) {
      return;
    }

    setPendingRevokeId(sub.id);
    try {
      const updated = await revokeAdminSubscription(sub.id);
      setSubscriptions((prev) =>
        prev.map((s) => (s.id === sub.id ? { ...s, status: updated.status, endDate: updated.endDate } : s))
      );
      setSuccessMessage(`Subscription for "${sub.user?.email}" revoked.`);
      setTimeout(() => setSuccessMessage(null), 4000);
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "Failed to revoke subscription.");
    } finally {
      setPendingRevokeId(null);
    }
  };

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 flex flex-col min-w-0">
        {/* Top Header */}
        <header className="bg-white border-b border-slate-200 px-8 py-5 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-bold text-slate-900 tracking-tight">
              Subscriptions Management
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Track student subscription records, status transitions, and administrative revocations
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* Status Filter Select */}
            <div className="flex items-center gap-2">
              <label htmlFor="statusFilter" className="text-xs font-semibold text-slate-600">
                Status:
              </label>
              <select
                id="statusFilter"
                value={selectedStatusFilter}
                onChange={(e) => handleStatusFilterChange(e.target.value)}
                className="px-3 py-1.5 text-xs rounded-lg border border-slate-300 bg-white text-slate-900 focus:outline-none focus:ring-2 focus:ring-teal-500 font-medium"
              >
                <option value="">All Statuses</option>
                <option value={SubscriptionStatus.ACTIVE}>Active</option>
                <option value={SubscriptionStatus.CANCELLED}>Cancelled</option>
                <option value={SubscriptionStatus.EXPIRED}>Expired</option>
                <option value={SubscriptionStatus.PENDING}>Pending</option>
              </select>
            </div>

            <button
              onClick={handleRefresh}
              disabled={isLoading}
              className="px-3.5 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 disabled:opacity-50 rounded-lg transition-colors border border-slate-200 flex items-center gap-1.5"
              aria-label="Refresh subscriptions list"
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
              Refresh
            </button>
          </div>
        </header>

        {/* Content Area */}
        <div className="p-8 max-w-7xl space-y-6">
          {/* Success Banner */}
          {successMessage && (
            <div className="bg-emerald-50 border border-emerald-200 rounded-xl p-4 flex items-center gap-3 text-xs text-emerald-900 shadow-sm">
              <span className="text-emerald-600 text-base">✅</span>
              <p className="font-medium">{successMessage}</p>
            </div>
          )}

          {/* Main Table / State Render */}
          {isLoading ? (
            <div className="bg-white rounded-xl border border-slate-200 p-12 text-center shadow-sm">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-slate-200 border-t-teal-600 mb-3"></div>
              <p className="text-sm font-medium text-slate-600">
                Loading subscriptions history...
              </p>
            </div>
          ) : errorMessage ? (
            <div className="bg-white rounded-xl border border-slate-200 p-8 text-center shadow-sm">
              <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-100 text-red-600 text-xl mb-3">
                ⚠️
              </div>
              <h3 className="text-base font-semibold text-slate-900 mb-1">
                Failed to Load Subscriptions
              </h3>
              <p className="text-xs text-slate-500 max-w-md mx-auto mb-5">
                {errorMessage}
              </p>
              <button
                onClick={handleRefresh}
                className="px-4 py-2 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 rounded-lg transition-colors inline-flex items-center gap-1.5"
              >
                Retry Request
              </button>
            </div>
          ) : subscriptions.length === 0 ? (
            <div className="bg-white rounded-xl border border-slate-200 p-12 text-center shadow-sm">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-slate-100 text-slate-400 text-2xl mb-4">
                💳
              </div>
              <h3 className="text-base font-semibold text-slate-900 mb-1">
                No Subscriptions Found
              </h3>
              <p className="text-xs text-slate-500 max-w-sm mx-auto">
                There are currently no subscription records matching the active filters.
              </p>
            </div>
          ) : (
            <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
              <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-sm font-bold text-slate-900 uppercase tracking-wider">
                  Subscriptions ({subscriptions.length})
                </h2>
                <span className="text-xs text-slate-500 font-medium">
                  {selectedStatusFilter
                    ? `Filtered by Status: ${selectedStatusFilter}`
                    : "Showing All Subscriptions"}
                </span>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                      <th className="py-3.5 px-6">Student User</th>
                      <th className="py-3.5 px-6">Subscription Plan</th>
                      <th className="py-3.5 px-6">Status</th>
                      <th className="py-3.5 px-6">Start Date</th>
                      <th className="py-3.5 px-6">End / Expiry Date</th>
                      <th className="py-3.5 px-6 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 text-xs">
                    {subscriptions.map((sub) => (
                      <tr key={sub.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="py-4 px-6 font-semibold text-slate-900">
                          <div className="flex flex-col">
                            <span>{sub.user?.fullName || "Student User"}</span>
                            <span className="text-[11px] text-slate-500 font-mono font-normal">
                              {sub.user?.email || sub.userId}
                            </span>
                          </div>
                        </td>
                        <td className="py-4 px-6">
                          <div className="flex flex-col">
                            <span className="font-bold text-slate-900">
                              {sub.plan?.name || sub.planId}
                            </span>
                            {sub.plan?.planType && (
                              <span className="text-[10px] text-slate-500 font-mono">
                                ({sub.plan.planType})
                              </span>
                            )}
                          </div>
                        </td>
                        <td className="py-4 px-6">
                          {sub.status === SubscriptionStatus.ACTIVE ? (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                              ● ACTIVE
                            </span>
                          ) : sub.status === SubscriptionStatus.CANCELLED ? (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-red-50 text-red-700 border border-red-200">
                              ○ CANCELLED
                            </span>
                          ) : sub.status === SubscriptionStatus.EXPIRED ? (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-slate-100 text-slate-600 border border-slate-200">
                              ○ EXPIRED
                            </span>
                          ) : (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-800 border border-amber-200">
                              ⌛ PENDING
                            </span>
                          )}
                        </td>
                        <td className="py-4 px-6 font-mono text-slate-600">
                          {sub.startDate
                            ? new Date(sub.startDate).toLocaleDateString()
                            : "N/A"}
                        </td>
                        <td className="py-4 px-6 font-mono text-slate-600">
                          {sub.endDate
                            ? new Date(sub.endDate).toLocaleDateString()
                            : "N/A"}
                        </td>
                        <td className="py-4 px-6 text-right">
                          {sub.status === SubscriptionStatus.ACTIVE && (
                            <button
                              onClick={() => handleRevoke(sub)}
                              disabled={pendingRevokeId === sub.id}
                              className="px-2.5 py-1 text-[11px] font-semibold text-red-600 bg-red-50 hover:bg-red-100 border border-red-200 rounded transition-colors"
                            >
                              {pendingRevokeId === sub.id ? "Revoking..." : "Revoke Access"}
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}
