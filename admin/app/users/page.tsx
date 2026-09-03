"use client";

import { useEffect, useState, useCallback } from "react";
import Sidebar from "@/components/Sidebar";
import GrantSubscriptionModal from "@/components/GrantSubscriptionModal";
import {
  User,
  PaginationMeta,
  fetchAdminUsers,
  setAdminUserBanned,
  resetAdminUserDevice,
} from "@/lib/users";

export default function UsersManagementPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [pagination, setPagination] = useState<PaginationMeta>({
    total: 0,
    page: 1,
    limit: 20,
    totalPages: 1,
  });
  const [searchQuery, setSearchQuery] = useState<string>("");

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const [pendingBanId, setPendingBanId] = useState<string | null>(null);
  const [pendingResetId, setPendingResetId] = useState<string | null>(null);

  // Grant Subscription Modal State
  const [grantUser, setGrantUser] = useState<User | null>(null);

  const loadUsersData = useCallback(async (page: number, search: string) => {
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const res = await fetchAdminUsers(page, 20, search);
      setUsers(res.data);
      setPagination(res.meta);
    } catch (err: unknown) {
      setErrorMessage(
        err instanceof Error ? err.message : "Failed to load users."
      );
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    let isMounted = true;
    Promise.resolve().then(() => {
      if (isMounted) {
        loadUsersData(1, "");
      }
    });
    return () => {
      isMounted = false;
    };
  }, [loadUsersData]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    loadUsersData(1, searchQuery);
  };

  const handlePageChange = (newPage: number) => {
    if (newPage < 1 || newPage > pagination.totalPages) return;
    loadUsersData(newPage, searchQuery);
  };

  const handleToggleBan = async (user: User) => {
    const actionText = user.isBanned ? "unban" : "ban";
    if (!confirm(`Are you sure you want to ${actionText} user "${user.email}"?`)) {
      return;
    }

    setPendingBanId(user.id);
    try {
      const updated = await setAdminUserBanned(user.id, !user.isBanned);
      setUsers((prev) =>
        prev.map((u) => (u.id === user.id ? { ...u, isBanned: updated.isBanned } : u))
      );
      setSuccessMessage(
        `User "${user.email}" is now ${updated.isBanned ? "BANNED" : "ACTIVE"}.`
      );
      setTimeout(() => setSuccessMessage(null), 4000);
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "Failed to update ban status.");
    } finally {
      setPendingBanId(null);
    }
  };

  const handleResetDevice = async (user: User) => {
    if (
      !confirm(
        `Reset device binding for "${user.email}"? This will sign out their current active device.`
      )
    ) {
      return;
    }

    setPendingResetId(user.id);
    try {
      const res = await resetAdminUserDevice(user.id);
      setUsers((prev) =>
        prev.map((u) => (u.id === user.id ? { ...u, activeDevice: null } : u))
      );
      setSuccessMessage(res.message);
      setTimeout(() => setSuccessMessage(null), 4000);
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "Failed to reset device binding.");
    } finally {
      setPendingResetId(null);
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
              Student Users Management
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Manage registered student accounts, active device bindings, and manual subscription grants
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <form onSubmit={handleSearchSubmit} className="flex items-center gap-2">
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search name or email..."
                className="px-3.5 py-2 text-xs rounded-lg border border-slate-300 bg-white text-slate-900 focus:outline-none focus:ring-2 focus:ring-teal-500 font-medium"
              />
              <button
                type="submit"
                className="px-3.5 py-2 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 rounded-lg transition-colors"
              >
                Search
              </button>
            </form>

            <button
              onClick={() => loadUsersData(pagination.page, searchQuery)}
              disabled={isLoading}
              className="px-3.5 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 disabled:opacity-50 rounded-lg transition-colors border border-slate-200 flex items-center gap-1.5"
              aria-label="Refresh users list"
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
          {/* Privacy & Security Notice */}
          <div className="bg-slate-100 border border-slate-200 rounded-xl p-4 flex items-start gap-3 text-xs text-slate-800 shadow-sm">
            <span className="text-slate-500 text-base">🛡️</span>
            <div>
              <p className="font-semibold">Privacy & Credentials Audit Compliance</p>
              <p className="mt-0.5 text-slate-600 leading-relaxed">
                Password hashes, refresh token hashes, and internal security secrets are strictly omitted from frontend data layers and display tables.
              </p>
            </div>
          </div>

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
                Loading student accounts...
              </p>
            </div>
          ) : errorMessage ? (
            <div className="bg-white rounded-xl border border-slate-200 p-8 text-center shadow-sm">
              <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-100 text-red-600 text-xl mb-3">
                ⚠️
              </div>
              <h3 className="text-base font-semibold text-slate-900 mb-1">
                Failed to Load Users
              </h3>
              <p className="text-xs text-slate-500 max-w-md mx-auto mb-5">
                {errorMessage}
              </p>
              <button
                onClick={() => loadUsersData(1, searchQuery)}
                className="px-4 py-2 text-xs font-semibold text-white bg-slate-900 hover:bg-slate-800 rounded-lg transition-colors inline-flex items-center gap-1.5"
              >
                Retry Request
              </button>
            </div>
          ) : users.length === 0 ? (
            <div className="bg-white rounded-xl border border-slate-200 p-12 text-center shadow-sm">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-slate-100 text-slate-400 text-2xl mb-4">
                👤
              </div>
              <h3 className="text-base font-semibold text-slate-900 mb-1">
                No Student Accounts Found
              </h3>
              <p className="text-xs text-slate-500 max-w-sm mx-auto">
                {searchQuery
                  ? `No user accounts match "${searchQuery}".`
                  : "There are currently no registered student accounts in the system."}
              </p>
            </div>
          ) : (
            <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden flex flex-col">
              <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-sm font-bold text-slate-900 uppercase tracking-wider">
                  Registered Accounts ({pagination.total})
                </h2>
                <span className="text-xs text-slate-500 font-medium">
                  Page {pagination.page} of {pagination.totalPages}
                </span>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                      <th className="py-3.5 px-6">Student Name & Email</th>
                      <th className="py-3.5 px-6">Role</th>
                      <th className="py-3.5 px-6">Status</th>
                      <th className="py-3.5 px-6">Active Device Binding</th>
                      <th className="py-3.5 px-6">Active Subscription</th>
                      <th className="py-3.5 px-6 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 text-xs">
                    {users.map((user) => (
                      <tr key={user.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="py-4 px-6 font-semibold text-slate-900">
                          <div className="flex flex-col">
                            <span>{user.fullName}</span>
                            <span className="text-[11px] text-slate-500 font-mono font-normal">
                              {user.email}
                            </span>
                          </div>
                        </td>
                        <td className="py-4 px-6 font-mono font-bold text-slate-700">
                          {user.role}
                        </td>
                        <td className="py-4 px-6">
                          {user.isBanned ? (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-red-50 text-red-700 border border-red-200">
                              ● Banned
                            </span>
                          ) : (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                              ● Active Student
                            </span>
                          )}
                        </td>
                        <td className="py-4 px-6">
                          {user.activeDevice ? (
                            <div className="flex flex-col text-[11px]">
                              <span className="font-semibold text-slate-800">
                                📱 {user.activeDevice.deviceName}
                              </span>
                              <span className="text-slate-400 font-mono text-[10px]">
                                ID: {user.activeDevice.deviceId.substring(0, 12)}...
                              </span>
                            </div>
                          ) : (
                            <span className="text-slate-400">No active device</span>
                          )}
                        </td>
                        <td className="py-4 px-6">
                          {user.activeSubscription ? (
                            <div className="flex flex-col text-[11px]">
                              <span className="font-bold text-teal-800">
                                {user.activeSubscription.plan?.name || user.activeSubscription.planId}
                              </span>
                              <span className="text-[10px] text-emerald-700 font-semibold">
                                Status: {user.activeSubscription.status}
                              </span>
                            </div>
                          ) : (
                            <span className="text-slate-400">No active plan</span>
                          )}
                        </td>
                        <td className="py-4 px-6 text-right space-x-2">
                          <button
                            onClick={() => setGrantUser(user)}
                            className="px-2.5 py-1 text-[11px] font-semibold text-teal-700 bg-teal-50 hover:bg-teal-100 border border-teal-200 rounded transition-colors"
                          >
                            Grant Plan
                          </button>
                          {user.activeDevice && (
                            <button
                              onClick={() => handleResetDevice(user)}
                              disabled={pendingResetId === user.id}
                              className="px-2.5 py-1 text-[11px] font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 border border-slate-200 rounded transition-colors"
                            >
                              {pendingResetId === user.id ? "Resetting..." : "Reset Device"}
                            </button>
                          )}
                          <button
                            onClick={() => handleToggleBan(user)}
                            disabled={pendingBanId === user.id}
                            className={`px-2.5 py-1 text-[11px] font-semibold rounded border transition-colors ${
                              user.isBanned
                                ? "bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100"
                                : "bg-red-50 text-red-700 border-red-200 hover:bg-red-100"
                            }`}
                          >
                            {pendingBanId === user.id
                              ? "Updating..."
                              : user.isBanned
                              ? "Unban User"
                              : "Ban User"}
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Pagination Bar */}
              <div className="px-6 py-4 border-t border-slate-200 bg-slate-50 flex items-center justify-between text-xs text-slate-600">
                <span>
                  Showing page {pagination.page} of {pagination.totalPages} ({pagination.total} total students)
                </span>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => handlePageChange(pagination.page - 1)}
                    disabled={pagination.page <= 1}
                    className="px-3 py-1.5 font-semibold text-slate-700 bg-white border border-slate-300 rounded hover:bg-slate-100 disabled:opacity-50"
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => handlePageChange(pagination.page + 1)}
                    disabled={pagination.page >= pagination.totalPages}
                    className="px-3 py-1.5 font-semibold text-slate-700 bg-white border border-slate-300 rounded hover:bg-slate-100 disabled:opacity-50"
                  >
                    Next
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Grant Subscription Modal */}
      {grantUser && (
        <GrantSubscriptionModal
          userId={grantUser.id}
          userEmail={grantUser.email}
          userName={grantUser.fullName}
          isOpen={Boolean(grantUser)}
          onClose={() => setGrantUser(null)}
          onGrantSuccess={() => {
            loadUsersData(pagination.page, searchQuery);
            setSuccessMessage(`Subscription granted to ${grantUser.fullName}.`);
            setTimeout(() => setSuccessMessage(null), 4000);
          }}
        />
      )}
    </div>
  );
}
