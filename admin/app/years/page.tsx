"use client";

import { useEffect, useState, useCallback } from "react";
import Sidebar from "@/components/Sidebar";
import {
  Year,
  PlanType,
  CreateYearPayload,
  fetchAdminYears,
  createAdminYear,
  slugify,
  validateYearPayload,
} from "@/lib/years";

export default function YearsManagementPage() {
  const [years, setYears] = useState<Year[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [modalError, setModalError] = useState<string | null>(null);

  // Form Fields
  const [formName, setFormName] = useState<string>("");
  const [formSlug, setFormSlug] = useState<string>("");
  const [isAutoSlug, setIsAutoSlug] = useState<boolean>(true);
  const [formSortOrder, setFormSortOrder] = useState<number>(1);
  const [formPlanType, setFormPlanType] = useState<PlanType>(PlanType.YEAR_1);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    let isMounted = true;
    fetchAdminYears()
      .then((data) => {
        if (isMounted) {
          setYears(data);
          setIsLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (isMounted) {
          setErrorMessage(
            err instanceof Error ? err.message : "Failed to load academic years."
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
      const data = await fetchAdminYears();
      setYears(data);
    } catch (err: unknown) {
      setErrorMessage(
        err instanceof Error ? err.message : "Failed to load academic years."
      );
    } finally {
      setIsLoading(false);
    }
  }, []);

  const handleOpenModal = () => {
    const nextOrder = years.length > 0 ? Math.max(...years.map((y) => y.sortOrder)) + 1 : 1;
    setFormName("");
    setFormSlug("");
    setIsAutoSlug(true);
    setFormSortOrder(nextOrder);
    setFormPlanType(PlanType.YEAR_1);
    setFieldErrors({});
    setModalError(null);
    setIsModalOpen(true);
  };

  const handleNameChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const nameVal = e.target.value;
    setFormName(nameVal);
    if (isAutoSlug) {
      setFormSlug(slugify(nameVal));
    }
    if (fieldErrors.name) {
      setFieldErrors((prev) => ({ ...prev, name: "" }));
    }
  };

  const handleSlugChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormSlug(e.target.value);
    setIsAutoSlug(false);
    if (fieldErrors.slug) {
      setFieldErrors((prev) => ({ ...prev, slug: "" }));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const payload: CreateYearPayload = {
      name: formName.trim(),
      slug: formSlug.trim(),
      sortOrder: Number(formSortOrder),
      planType: formPlanType,
    };

    const validation = validateYearPayload(payload);
    if (!validation.isValid) {
      setFieldErrors(validation.errors);
      return;
    }

    setIsSubmitting(true);
    setModalError(null);

    try {
      const created = await createAdminYear(payload);
      setYears((prev) => [...prev, created].sort((a, b) => a.sortOrder - b.sortOrder));
      setIsModalOpen(false);
      setSuccessMessage(`Academic year "${created.name}" created successfully.`);
      setTimeout(() => setSuccessMessage(null), 4000);
    } catch (err: unknown) {
      setModalError(
        err instanceof Error ? err.message : "Failed to create academic year."
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleActionDeferred = (actionName: string) => {
    alert(
      `${actionName} action is deferred pending Person 1 NestJS backend API implementation (PATCH/DELETE /admin/years/:id).`
    );
  };

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 flex flex-col min-w-0">
        {/* Top Header */}
        <header className="bg-white border-b border-slate-200 px-8 py-5 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-bold text-slate-900 tracking-tight">
              Years Management
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Manage academic years, ordering, and subscription plan mappings
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={handleRefresh}
              disabled={isLoading}
              className="px-3.5 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 disabled:opacity-50 rounded-lg transition-colors border border-slate-200 flex items-center gap-1.5"
              aria-label="Refresh years list"
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

            <button
              onClick={handleOpenModal}
              className="px-4 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-700 rounded-lg transition-colors shadow-sm flex items-center gap-1.5"
            >
              <svg
                className="w-4 h-4"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M12 4v16m8-8H4"
                />
              </svg>
              Add Academic Year
            </button>
          </div>
        </header>

        {/* Content Area */}
        <div className="p-8 max-w-6xl space-y-6">
          {/* Deferred Action Notice */}
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 flex items-start gap-3 text-xs text-amber-900 shadow-sm">
            <span className="text-amber-600 text-base">ℹ️</span>
            <div>
              <p className="font-semibold">Backend API Contract Notice</p>
              <p className="mt-0.5 text-amber-800 leading-relaxed">
                Person 1 NestJS backend provides <code className="bg-amber-100 px-1 py-0.5 rounded text-amber-900 font-mono">GET /v1/admin/years</code> (List) and <code className="bg-amber-100 px-1 py-0.5 rounded text-amber-900 font-mono">POST /v1/admin/years</code> (Create). Edit and Delete endpoints are not available on the backend yet and are deferred.
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
                Loading academic years...
              </p>
            </div>
          ) : errorMessage ? (
            <div className="bg-white rounded-xl border border-slate-200 p-8 text-center shadow-sm">
              <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-100 text-red-600 text-xl mb-3">
                ⚠️
              </div>
              <h3 className="text-base font-semibold text-slate-900 mb-1">
                Failed to Load Years
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
          ) : years.length === 0 ? (
            <div className="bg-white rounded-xl border border-slate-200 p-12 text-center shadow-sm">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-slate-100 text-slate-400 text-2xl mb-4">
                📚
              </div>
              <h3 className="text-base font-semibold text-slate-900 mb-1">
                No Academic Years Found
              </h3>
              <p className="text-xs text-slate-500 max-w-sm mx-auto mb-6">
                There are currently no academic years configured in the system. Click below to add the first year.
              </p>
              <button
                onClick={handleOpenModal}
                className="px-4 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-700 rounded-lg transition-colors inline-flex items-center gap-1.5"
              >
                + Add First Academic Year
              </button>
            </div>
          ) : (
            <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
              <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-sm font-bold text-slate-900 uppercase tracking-wider">
                  Academic Years ({years.length})
                </h2>
                <span className="text-xs text-slate-500 font-medium">
                  Sorted by Sort Order
                </span>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                      <th className="py-3.5 px-6">Order</th>
                      <th className="py-3.5 px-6">Year Name</th>
                      <th className="py-3.5 px-6">Slug</th>
                      <th className="py-3.5 px-6">Subscription Plan Mapping</th>
                      <th className="py-3.5 px-6 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 text-xs">
                    {years.map((year) => (
                      <tr key={year.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="py-4 px-6 font-semibold text-slate-700">
                          <span className="inline-flex items-center justify-center w-6 h-6 rounded-md bg-slate-100 border border-slate-200 text-slate-700 text-xs font-mono">
                            #{year.sortOrder}
                          </span>
                        </td>
                        <td className="py-4 px-6 font-semibold text-slate-900">
                          {year.name}
                        </td>
                        <td className="py-4 px-6 font-mono text-slate-600">
                          <span className="bg-slate-100 px-2 py-1 rounded border border-slate-200 text-slate-800">
                            {year.slug}
                          </span>
                        </td>
                        <td className="py-4 px-6">
                          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[11px] font-semibold bg-teal-50 text-teal-700 border border-teal-200">
                            {year.planType}
                          </span>
                        </td>
                        <td className="py-4 px-6 text-right space-x-2">
                          <button
                            onClick={() => handleActionDeferred("Edit")}
                            className="px-2.5 py-1 text-[11px] font-medium text-slate-400 bg-slate-50 border border-slate-200 rounded hover:text-slate-600 transition-colors cursor-not-allowed"
                            title="Edit action deferred until NestJS backend provides PATCH /admin/years/:id"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => handleActionDeferred("Delete")}
                            className="px-2.5 py-1 text-[11px] font-medium text-slate-400 bg-slate-50 border border-slate-200 rounded hover:text-slate-600 transition-colors cursor-not-allowed"
                            title="Delete action deferred until NestJS backend provides DELETE /admin/years/:id"
                          >
                            Delete
                          </button>
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

      {/* Create Year Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden border border-slate-100">
            <div className="px-6 py-5 border-b border-slate-200 flex items-center justify-between bg-slate-50">
              <div>
                <h3 className="text-base font-bold text-slate-900">
                  Add Academic Year
                </h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  Configure name, URL slug, sequence, and subscription plan
                </p>
              </div>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-slate-400 hover:text-slate-600 text-lg leading-none p-1 rounded"
              >
                ✕
              </button>
            </div>

            {modalError && (
              <div className="mx-6 mt-5 p-3 rounded-lg bg-red-50 border border-red-200 flex items-start gap-2.5 text-xs text-red-800">
                <span>⚠️</span>
                <p>{modalError}</p>
              </div>
            )}

            <form onSubmit={handleSubmit} noValidate className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                  Year Name <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={formName}
                  onChange={handleNameChange}
                  placeholder="e.g. 1st Year MBBS"
                  className={`w-full px-3.5 py-2.5 text-xs rounded-lg border text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                    fieldErrors.name ? "border-red-500 ring-1 ring-red-500" : "border-slate-300"
                  }`}
                />
                {fieldErrors.name && (
                  <p className="mt-1 text-[11px] text-red-600 font-medium">
                    {fieldErrors.name}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                  URL Slug <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={formSlug}
                  onChange={handleSlugChange}
                  placeholder="e.g. year-1"
                  className={`w-full px-3.5 py-2.5 text-xs font-mono rounded-lg border text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                    fieldErrors.slug ? "border-red-500 ring-1 ring-red-500" : "border-slate-300"
                  }`}
                />
                {fieldErrors.slug && (
                  <p className="mt-1 text-[11px] text-red-600 font-medium">
                    {fieldErrors.slug}
                  </p>
                )}
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                    Sort Order <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="number"
                    min="0"
                    value={formSortOrder}
                    onChange={(e) => setFormSortOrder(parseInt(e.target.value) || 0)}
                    className={`w-full px-3.5 py-2.5 text-xs rounded-lg border text-slate-900 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                      fieldErrors.sortOrder ? "border-red-500 ring-1 ring-red-500" : "border-slate-300"
                    }`}
                  />
                  {fieldErrors.sortOrder && (
                    <p className="mt-1 text-[11px] text-red-600 font-medium">
                      {fieldErrors.sortOrder}
                    </p>
                  )}
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                    Plan Type <span className="text-red-500">*</span>
                  </label>
                  <select
                    value={formPlanType}
                    onChange={(e) => setFormPlanType(e.target.value as PlanType)}
                    className="w-full px-3.5 py-2.5 text-xs rounded-lg border border-slate-300 text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-teal-500"
                  >
                    {Object.values(PlanType).map((plan) => (
                      <option key={plan} value={plan}>
                        {plan}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="mt-6 pt-4 border-t border-slate-200 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  disabled={isSubmitting}
                  className="px-4 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-4 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-700 disabled:bg-teal-400 rounded-lg transition-colors shadow-sm flex items-center gap-1.5"
                >
                  {isSubmitting ? "Creating..." : "Create Academic Year"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
