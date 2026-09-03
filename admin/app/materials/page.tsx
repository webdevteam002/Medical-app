"use client";

import { useEffect, useState, useCallback, useMemo } from "react";
import Link from "next/link";
import Sidebar from "@/components/Sidebar";
import { Year, fetchAdminYears } from "@/lib/years";
import { Subject, fetchAdminSubjects } from "@/lib/subjects";
import { Topic, fetchAdminTopics } from "@/lib/topics";
import {
  Material,
  MaterialType,
  UploadMaterialPayload,
  fetchAdminMaterials,
  uploadAdminMaterial,
  updateAdminMaterial,
  deleteAdminMaterial,
  validateUploadMaterialPayload,
  formatFileSize,
} from "@/lib/materials";
import {
  HierarchyFilterState,
  resetDependentFilters,
  filterSubjectsByYear,
  filterMaterialsByHierarchy,
  formatHierarchyBreadcrumb,
} from "@/lib/hierarchy";

export default function MaterialsManagementPage() {
  const [materials, setMaterials] = useState<Material[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [years, setYears] = useState<Year[]>([]);
  const [topics, setTopics] = useState<Topic[]>([]);

  // Multi-tier Hierarchy Filters
  const [filters, setFilters] = useState<HierarchyFilterState>({
    yearId: "",
    subjectId: "",
    topicId: "",
  });

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // Action Pending States
  const [pendingPublishId, setPendingPublishId] = useState<string | null>(null);
  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [isUploading, setIsUploading] = useState<boolean>(false);
  const [modalError, setModalError] = useState<string | null>(null);
  const [modalTopics, setModalTopics] = useState<Topic[]>([]);

  // Form Fields
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [formSubjectId, setFormSubjectId] = useState<string>("");
  const [formTopicId, setFormTopicId] = useState<string>("");
  const [formTitle, setFormTitle] = useState<string>("");
  const [formType, setFormType] = useState<MaterialType>(MaterialType.PDF);
  const [formIsDownloadable, setFormIsDownloadable] = useState<boolean>(true);
  const [formIsPastPaper, setFormIsPastPaper] = useState<boolean>(false);
  const [formPastPaperYear, setFormPastPaperYear] = useState<number>(new Date().getFullYear());
  const [formPastPaperSession, setFormPastPaperSession] = useState<string>("Annual");
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    let isMounted = true;
    Promise.all([fetchAdminMaterials(), fetchAdminSubjects(), fetchAdminYears()])
      .then(([materialsData, subjectsData, yearsData]) => {
        if (isMounted) {
          setMaterials(materialsData);
          setSubjects(subjectsData);
          setYears(yearsData);
          setIsLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (isMounted) {
          setErrorMessage(
            err instanceof Error ? err.message : "Failed to load content hierarchy."
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
      const data = await fetchAdminMaterials(filters.subjectId || undefined);
      setMaterials(data);
    } catch (err: unknown) {
      setErrorMessage(
        err instanceof Error ? err.message : "Failed to load materials."
      );
    } finally {
      setIsLoading(false);
    }
  }, [filters.subjectId]);

  // Handle Progressive Filter Changes
  const handleYearFilterChange = (yearIdVal: string) => {
    setFilters((prev) => resetDependentFilters(prev, "yearId", yearIdVal));
    setTopics([]);
  };

  const handleSubjectFilterChange = async (subjectIdVal: string) => {
    setFilters((prev) => resetDependentFilters(prev, "subjectId", subjectIdVal));
    setTopics([]);
    if (subjectIdVal) {
      try {
        const fetchedTopics = await fetchAdminTopics(subjectIdVal);
        setTopics(fetchedTopics);
      } catch {
        setTopics([]);
      }
    }
  };

  const handleTopicFilterChange = (topicIdVal: string) => {
    setFilters((prev) => resetDependentFilters(prev, "topicId", topicIdVal));
  };

  const handleClearFilters = () => {
    setFilters({ yearId: "", subjectId: "", topicId: "" });
    setTopics([]);
  };

  // Filtered Options & Results
  const filteredSubjectsForDropdown = useMemo(() => {
    return filterSubjectsByYear(subjects, filters.yearId);
  }, [subjects, filters.yearId]);

  const filteredMaterials = useMemo(() => {
    return filterMaterialsByHierarchy(materials, filters, subjects, years);
  }, [materials, filters, subjects, years]);

  const activeYearObj = useMemo(() => years.find((y) => y.id === filters.yearId), [years, filters.yearId]);
  const activeSubjectObj = useMemo(() => subjects.find((s) => s.id === filters.subjectId), [subjects, filters.subjectId]);
  const activeTopicObj = useMemo(() => topics.find((t) => t.id === filters.topicId), [topics, filters.topicId]);

  const activeBreadcrumbText = useMemo(() => {
    return formatHierarchyBreadcrumb(
      activeYearObj?.name,
      activeSubjectObj?.name,
      activeTopicObj?.name
    );
  }, [activeYearObj, activeSubjectObj, activeTopicObj]);

  const hasActiveFilters = Boolean(filters.yearId || filters.subjectId || filters.topicId);

  // Modal Handlers
  const handleOpenModal = () => {
    const defaultSubjectId = filters.subjectId || (subjects.length > 0 ? subjects[0].id : "");
    setSelectedFile(null);
    setFormSubjectId(defaultSubjectId);
    setFormTopicId(filters.topicId || "");
    setFormTitle("");
    setFormType(MaterialType.PDF);
    setFormIsDownloadable(true);
    setFormIsPastPaper(false);
    setFormPastPaperYear(new Date().getFullYear());
    setFormPastPaperSession("Annual");
    setFieldErrors({});
    setModalError(null);
    setIsModalOpen(true);

    if (defaultSubjectId) {
      fetchAdminTopics(defaultSubjectId)
        .then((fetchedTopics) => setModalTopics(fetchedTopics))
        .catch(() => setModalTopics([]));
    } else {
      setModalTopics([]);
    }
  };

  const handleFormSubjectChange = (subjectIdVal: string) => {
    setFormSubjectId(subjectIdVal);
    setFormTopicId("");
    if (fieldErrors.subjectId) {
      setFieldErrors((prev) => ({ ...prev, subjectId: "" }));
    }
    if (subjectIdVal) {
      fetchAdminTopics(subjectIdVal)
        .then((fetchedTopics) => setModalTopics(fetchedTopics))
        .catch(() => setModalTopics([]));
    } else {
      setModalTopics([]);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0] || null;
    setSelectedFile(file);
    if (file) {
      if (!formTitle) {
        const nameWithoutExt = file.name.replace(/\.[^/.]+$/, "");
        setFormTitle(nameWithoutExt);
      }
      if (file.name.toLowerCase().endsWith(".pdf")) {
        setFormType(MaterialType.PDF);
      } else if (file.name.toLowerCase().endsWith(".mp4") || file.name.toLowerCase().endsWith(".mkv")) {
        setFormType(MaterialType.VIDEO);
      }
    }
    if (fieldErrors.file) {
      setFieldErrors((prev) => ({ ...prev, file: "" }));
    }
  };

  const handleSubmitUpload = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!selectedFile) {
      setFieldErrors((prev) => ({ ...prev, file: "Please select a file to upload." }));
      return;
    }

    const payload: UploadMaterialPayload = {
      file: selectedFile,
      subjectId: formSubjectId,
      topicId: formTopicId || undefined,
      title: formTitle.trim(),
      type: formType,
      isDownloadable: formIsDownloadable,
      isPastPaper: formIsPastPaper,
      pastPaperYear: formIsPastPaper ? Number(formPastPaperYear) : undefined,
      pastPaperSession: formIsPastPaper ? formPastPaperSession.trim() : undefined,
    };

    const validation = validateUploadMaterialPayload(payload);
    if (!validation.isValid) {
      setFieldErrors(validation.errors);
      return;
    }

    setIsUploading(true);
    setModalError(null);

    try {
      const created = await uploadAdminMaterial(payload);
      const updatedList = await fetchAdminMaterials();
      setMaterials(updatedList);
      setIsModalOpen(false);
      setSuccessMessage(`Material "${created.title}" uploaded & saved to storage successfully.`);
      setTimeout(() => setSuccessMessage(null), 4000);
    } catch (err: unknown) {
      setModalError(
        err instanceof Error ? err.message : "Failed to upload material file."
      );
    } finally {
      setIsUploading(false);
    }
  };

  const handleTogglePublish = async (material: Material) => {
    setPendingPublishId(material.id);
    try {
      const updated = await updateAdminMaterial(material.id, {
        isPublished: !material.isPublished,
      });
      setMaterials((prev) =>
        prev.map((m) => (m.id === material.id ? { ...m, isPublished: updated.isPublished } : m))
      );
      setSuccessMessage(
        `Material "${material.title}" is now ${updated.isPublished ? "PUBLISHED (Student Visible)" : "UNPUBLISHED (Draft)"}.`
      );
      setTimeout(() => setSuccessMessage(null), 4000);
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "Failed to update publish state.");
    } finally {
      setPendingPublishId(null);
    }
  };

  const handleDelete = async (material: Material) => {
    if (
      !confirm(
        `Are you sure you want to permanently delete "${material.title}" and its storage file?`
      )
    ) {
      return;
    }

    setPendingDeleteId(material.id);
    try {
      await deleteAdminMaterial(material.id);
      setMaterials((prev) => prev.filter((m) => m.id !== material.id));
      setSuccessMessage(`Material "${material.title}" deleted from storage.`);
      setTimeout(() => setSuccessMessage(null), 4000);
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "Failed to delete material.");
    } finally {
      setPendingDeleteId(null);
    }
  };

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 flex flex-col min-w-0">
        {/* Breadcrumbs & Top Header */}
        <header className="bg-white border-b border-slate-200 px-8 py-4 flex flex-col gap-3">
          <nav className="flex items-center text-xs font-semibold text-slate-500 gap-1.5" aria-label="Breadcrumb">
            <Link href="/years" className="hover:text-teal-600 transition-colors">Years</Link>
            <span>&rsaquo;</span>
            <Link href="/subjects" className="hover:text-teal-600 transition-colors">Subjects</Link>
            <span>&rsaquo;</span>
            <Link href="/topics" className="hover:text-teal-600 transition-colors">Topics</Link>
            <span>&rsaquo;</span>
            <span className="text-slate-900 font-bold">Materials & PDF Upload</span>
          </nav>

          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
              <h1 className="text-xl font-bold text-slate-900 tracking-tight">
                Materials & Content Hierarchy
              </h1>
              <p className="text-xs text-slate-500 mt-0.5">
                Consolidated Year &rarr; Subject &rarr; Topic &rarr; Material hierarchy and Cloudflare R2 upload center
              </p>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <button
                onClick={handleRefresh}
                disabled={isLoading}
                className="px-3.5 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 disabled:opacity-50 rounded-lg transition-colors border border-slate-200 flex items-center gap-1.5"
                aria-label="Refresh materials list"
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
                disabled={subjects.length === 0}
                className="px-4 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-700 disabled:bg-teal-400 rounded-lg transition-colors shadow-sm flex items-center gap-1.5"
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
                    d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"
                  />
                </svg>
                Upload Material
              </button>
            </div>
          </div>
        </header>

        {/* Content Area */}
        <div className="p-8 max-w-7xl space-y-6">
          {/* Progressive Multi-Tier Filter Bar */}
          <div className="bg-white border border-slate-200 rounded-xl p-5 shadow-sm space-y-4">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 border-b border-slate-100 pb-3">
              <span className="text-xs font-bold text-slate-800 uppercase tracking-wider flex items-center gap-2">
                <span>🔍</span> Progressive Content Hierarchy Filter
              </span>
              {hasActiveFilters && (
                <button
                  onClick={handleClearFilters}
                  className="text-xs font-semibold text-teal-600 hover:text-teal-800 transition-colors flex items-center gap-1 self-start md:self-auto"
                >
                  <span>✕</span> Clear All Filters
                </button>
              )}
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
              {/* 1. Year Filter */}
              <div>
                <label htmlFor="yearFilter" className="block text-[11px] font-semibold text-slate-600 uppercase tracking-wider mb-1.5">
                  1. Academic Year
                </label>
                <select
                  id="yearFilter"
                  value={filters.yearId}
                  onChange={(e) => handleYearFilterChange(e.target.value)}
                  className="w-full px-3 py-2 text-xs rounded-lg border border-slate-300 bg-white text-slate-900 focus:outline-none focus:ring-2 focus:ring-teal-500 font-medium"
                >
                  <option value="">All Academic Years ({years.length})</option>
                  {years.map((year) => (
                    <option key={year.id} value={year.id}>
                      {year.name} ({year.slug})
                    </option>
                  ))}
                </select>
              </div>

              {/* 2. Subject Filter */}
              <div>
                <label htmlFor="subjectFilter" className="block text-[11px] font-semibold text-slate-600 uppercase tracking-wider mb-1.5">
                  2. Subject
                </label>
                <select
                  id="subjectFilter"
                  value={filters.subjectId}
                  onChange={(e) => handleSubjectFilterChange(e.target.value)}
                  className="w-full px-3 py-2 text-xs rounded-lg border border-slate-300 bg-white text-slate-900 focus:outline-none focus:ring-2 focus:ring-teal-500 font-medium"
                >
                  <option value="">All Subjects ({filteredSubjectsForDropdown.length})</option>
                  {filteredSubjectsForDropdown.map((subject) => (
                    <option key={subject.id} value={subject.id}>
                      {subject.name} ({subject.year?.name || subject.slug})
                    </option>
                  ))}
                </select>
              </div>

              {/* 3. Topic Filter */}
              <div>
                <label htmlFor="topicFilter" className="block text-[11px] font-semibold text-slate-600 uppercase tracking-wider mb-1.5">
                  3. Topic
                </label>
                <select
                  id="topicFilter"
                  value={filters.topicId}
                  onChange={(e) => handleTopicFilterChange(e.target.value)}
                  disabled={!filters.subjectId || topics.length === 0}
                  className="w-full px-3 py-2 text-xs rounded-lg border border-slate-300 bg-white text-slate-900 focus:outline-none focus:ring-2 focus:ring-teal-500 font-medium disabled:bg-slate-100 disabled:text-slate-400"
                >
                  <option value="">
                    {!filters.subjectId
                      ? "Select Subject First"
                      : topics.length === 0
                      ? "No Topics Found"
                      : `All Topics (${topics.length})`}
                  </option>
                  {topics.map((topic) => (
                    <option key={topic.id} value={topic.id}>
                      {topic.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {/* Active Filter Summary Badge */}
            {hasActiveFilters && (
              <div className="pt-2 flex items-center gap-2 text-xs text-slate-600">
                <span className="font-semibold text-slate-800">Active Scope:</span>
                <span className="inline-flex items-center px-3 py-1 rounded-full bg-teal-50 text-teal-800 border border-teal-200 font-medium text-[11px]">
                  {activeBreadcrumbText}
                </span>
              </div>
            )}
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
                Loading study materials...
              </p>
            </div>
          ) : errorMessage ? (
            <div className="bg-white rounded-xl border border-slate-200 p-8 text-center shadow-sm">
              <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-100 text-red-600 text-xl mb-3">
                ⚠️
              </div>
              <h3 className="text-base font-semibold text-slate-900 mb-1">
                Failed to Load Materials
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
          ) : filteredMaterials.length === 0 ? (
            <div className="bg-white rounded-xl border border-slate-200 p-12 text-center shadow-sm">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-slate-100 text-slate-400 text-2xl mb-4">
                📚
              </div>
              <h3 className="text-base font-semibold text-slate-900 mb-1">
                No Materials Found for Selected Scope
              </h3>
              <p className="text-xs text-slate-500 max-w-md mx-auto mb-6">
                {hasActiveFilters
                  ? `No study materials match the filter scope: "${activeBreadcrumbText}". Click below to clear filters or upload a material.`
                  : "There are currently no study materials uploaded in the system. Click below to upload the first material."}
              </p>
              <div className="flex items-center justify-center gap-3">
                {hasActiveFilters && (
                  <button
                    onClick={handleClearFilters}
                    className="px-4 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors border border-slate-200"
                  >
                    Clear Filters
                  </button>
                )}
                <button
                  onClick={handleOpenModal}
                  className="px-4 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-700 rounded-lg transition-colors inline-flex items-center gap-1.5"
                >
                  + Upload Material
                </button>
              </div>
            </div>
          ) : (
            <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
              <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-sm font-bold text-slate-900 uppercase tracking-wider">
                  Materials Library ({filteredMaterials.length} of {materials.length})
                </h2>
                <span className="text-xs text-slate-500 font-medium">
                  {hasActiveFilters ? `Scope: ${activeBreadcrumbText}` : "Showing All Materials"}
                </span>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                      <th className="py-3.5 px-6">Material Title</th>
                      <th className="py-3.5 px-6">Type</th>
                      <th className="py-3.5 px-6">Hierarchy Path (Year &rarr; Subject)</th>
                      <th className="py-3.5 px-6">Size</th>
                      <th className="py-3.5 px-6">Downloadable</th>
                      <th className="py-3.5 px-6">Publication Status</th>
                      <th className="py-3.5 px-6 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 text-xs">
                    {filteredMaterials.map((material) => (
                      <tr key={material.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="py-4 px-6 font-semibold text-slate-900">
                          <div className="flex flex-col">
                            <span>{material.title}</span>
                            {material.isPastPaper && (
                              <span className="text-[10px] text-amber-700 font-medium mt-0.5">
                                📝 Past Paper ({material.pastPaperYear || "N/A"} - {material.pastPaperSession || "Annual"})
                              </span>
                            )}
                          </div>
                        </td>
                        <td className="py-4 px-6">
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold bg-slate-100 text-slate-700 border border-slate-200">
                            {material.type}
                          </span>
                        </td>
                        <td className="py-4 px-6">
                          <div className="flex flex-col">
                            <span className="font-semibold text-slate-800">
                              {material.subject?.year?.slug ? `${material.subject.year.slug.toUpperCase()} / ` : ""}
                              {material.subject?.name || "Subject"}
                            </span>
                            <span className="text-[10px] text-slate-500 font-mono">
                              Topic ID: {material.topicId ? material.topicId.substring(0, 8) + "..." : "General Subject"}
                            </span>
                          </div>
                        </td>
                        <td className="py-4 px-6 font-mono text-slate-600">
                          {formatFileSize(material.fileSizeBytes)}
                        </td>
                        <td className="py-4 px-6">
                          {material.isDownloadable ? (
                            <span className="text-emerald-700 font-medium flex items-center gap-1">
                              <span>✓</span> Downloadable
                            </span>
                          ) : (
                            <span className="text-slate-400 font-medium">View Only</span>
                          )}
                        </td>
                        <td className="py-4 px-6">
                          {material.isPublished ? (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                              ● Published (Student Visible)
                            </span>
                          ) : (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-800 border border-amber-200">
                              ○ Draft (Unpublished)
                            </span>
                          )}
                        </td>
                        <td className="py-4 px-6 text-right space-x-2">
                          <button
                            onClick={() => handleTogglePublish(material)}
                            disabled={pendingPublishId === material.id}
                            className={`px-2.5 py-1 text-[11px] font-semibold rounded border transition-colors ${
                              material.isPublished
                                ? "bg-amber-50 text-amber-800 border-amber-200 hover:bg-amber-100"
                                : "bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100"
                            }`}
                          >
                            {pendingPublishId === material.id
                              ? "Updating..."
                              : material.isPublished
                              ? "Unpublish"
                              : "Publish"}
                          </button>
                          <button
                            onClick={() => handleDelete(material)}
                            disabled={pendingDeleteId === material.id}
                            className="px-2.5 py-1 text-[11px] font-semibold text-red-600 bg-red-50 hover:bg-red-100 border border-red-200 rounded transition-colors"
                          >
                            {pendingDeleteId === material.id ? "Deleting..." : "Delete"}
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

      {/* Upload Material Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden border border-slate-100 max-h-[90vh] flex flex-col">
            <div className="px-6 py-5 border-b border-slate-200 flex items-center justify-between bg-slate-50 flex-shrink-0">
              <div>
                <h3 className="text-base font-bold text-slate-900">
                  Upload Study Material (PDF / Document)
                </h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  Stream material file to storage and set content metadata
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
              <div className="mx-6 mt-5 p-3 rounded-lg bg-red-50 border border-red-200 flex items-start gap-2.5 text-xs text-red-800 flex-shrink-0">
                <span>⚠️</span>
                <p>{modalError}</p>
              </div>
            )}

            <form onSubmit={handleSubmitUpload} noValidate className="p-6 space-y-4 overflow-y-auto flex-1">
              {/* File Dropzone / Input */}
              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                  Material File (Max 50MB) <span className="text-red-500">*</span>
                </label>
                <div className="border-2 border-dashed border-slate-300 hover:border-teal-500 rounded-xl p-4 text-center bg-slate-50/50 transition-colors">
                  <input
                    type="file"
                    accept=".pdf,.notes,.mp4,.mkv"
                    onChange={handleFileSelect}
                    className="hidden"
                    id="fileUploadInput"
                  />
                  <label htmlFor="fileUploadInput" className="cursor-pointer block">
                    {selectedFile ? (
                      <div className="space-y-1">
                        <span className="text-xl">📄</span>
                        <p className="text-xs font-bold text-slate-900 truncate">
                          {selectedFile.name}
                        </p>
                        <p className="text-[11px] text-teal-600 font-semibold">
                          {formatFileSize(selectedFile.size)} &bull; Click to change file
                        </p>
                      </div>
                    ) : (
                      <div className="space-y-1">
                        <span className="text-2xl text-slate-400">📤</span>
                        <p className="text-xs font-semibold text-slate-700">
                          Click to select a PDF or document file
                        </p>
                        <p className="text-[11px] text-slate-400">
                          Supports .pdf, .mp4, .notes up to 50MB
                        </p>
                      </div>
                    )}
                  </label>
                </div>
                {fieldErrors.file && (
                  <p className="mt-1 text-[11px] text-red-600 font-medium">
                    {fieldErrors.file}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                  Parent Subject <span className="text-red-500">*</span>
                </label>
                <select
                  value={formSubjectId}
                  onChange={(e) => handleFormSubjectChange(e.target.value)}
                  className={`w-full px-3.5 py-2.5 text-xs rounded-lg border text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                    fieldErrors.subjectId ? "border-red-500 ring-1 ring-red-500" : "border-slate-300"
                  }`}
                >
                  <option value="">Select Parent Subject...</option>
                  {subjects.map((subject) => (
                    <option key={subject.id} value={subject.id}>
                      {subject.name} ({subject.year?.name || subject.slug})
                    </option>
                  ))}
                </select>
                {fieldErrors.subjectId && (
                  <p className="mt-1 text-[11px] text-red-600 font-medium">
                    {fieldErrors.subjectId}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                  Parent Topic (Optional)
                </label>
                <select
                  value={formTopicId}
                  onChange={(e) => setFormTopicId(e.target.value)}
                  disabled={!formSubjectId || modalTopics.length === 0}
                  className="w-full px-3.5 py-2.5 text-xs rounded-lg border border-slate-300 text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-teal-500 disabled:bg-slate-100"
                >
                  <option value="">No Topic (General Subject Material)</option>
                  {modalTopics.map((topic) => (
                    <option key={topic.id} value={topic.id}>
                      {topic.name}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                  Material Title <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={formTitle}
                  onChange={(e) => setFormTitle(e.target.value)}
                  placeholder="e.g. Brachial Plexus Comprehensive Diagram Notes"
                  className={`w-full px-3.5 py-2.5 text-xs rounded-lg border text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                    fieldErrors.title ? "border-red-500 ring-1 ring-red-500" : "border-slate-300"
                  }`}
                />
                {fieldErrors.title && (
                  <p className="mt-1 text-[11px] text-red-600 font-medium">
                    {fieldErrors.title}
                  </p>
                )}
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                    Material Type <span className="text-red-500">*</span>
                  </label>
                  <select
                    value={formType}
                    onChange={(e) => setFormType(e.target.value as MaterialType)}
                    className="w-full px-3.5 py-2.5 text-xs rounded-lg border border-slate-300 text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-teal-500"
                  >
                    <option value={MaterialType.PDF}>PDF Document</option>
                    <option value={MaterialType.VIDEO}>Video Stream</option>
                    <option value={MaterialType.NOTES}>Study Notes</option>
                  </select>
                </div>

                <div className="flex flex-col justify-end pb-2">
                  <label className="flex items-center gap-2 cursor-pointer text-xs font-semibold text-slate-800">
                    <input
                      type="checkbox"
                      checked={formIsDownloadable}
                      onChange={(e) => setFormIsDownloadable(e.target.checked)}
                      className="w-4 h-4 rounded text-teal-600 focus:ring-teal-500 border-slate-300"
                    />
                    <span>Allow Student Offline Download</span>
                  </label>
                </div>
              </div>

              {/* Past Paper Section */}
              <div className="pt-2 border-t border-slate-200">
                <label className="flex items-center gap-2 cursor-pointer text-xs font-semibold text-slate-800 mb-3">
                  <input
                    type="checkbox"
                    checked={formIsPastPaper}
                    onChange={(e) => setFormIsPastPaper(e.target.checked)}
                    className="w-4 h-4 rounded text-teal-600 focus:ring-teal-500 border-slate-300"
                  />
                  <span>Is Past Paper Document?</span>
                </label>

                {formIsPastPaper && (
                  <div className="grid grid-cols-2 gap-4 bg-slate-50 p-3 rounded-lg border border-slate-200">
                    <div>
                      <label className="block text-[11px] font-semibold text-slate-700 mb-1">
                        Exam Year
                      </label>
                      <input
                        type="number"
                        value={formPastPaperYear}
                        onChange={(e) => setFormPastPaperYear(parseInt(e.target.value) || 2024)}
                        className="w-full px-3 py-1.5 text-xs rounded border border-slate-300 text-slate-900"
                      />
                    </div>
                    <div>
                      <label className="block text-[11px] font-semibold text-slate-700 mb-1">
                        Exam Session
                      </label>
                      <input
                        type="text"
                        value={formPastPaperSession}
                        onChange={(e) => setFormPastPaperSession(e.target.value)}
                        placeholder="e.g. Annual / Supply"
                        className="w-full px-3 py-1.5 text-xs rounded border border-slate-300 text-slate-900"
                      />
                    </div>
                  </div>
                )}
              </div>

              <div className="mt-6 pt-4 border-t border-slate-200 flex items-center justify-end gap-3 flex-shrink-0">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  disabled={isUploading}
                  className="px-4 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isUploading}
                  className="px-4 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-700 disabled:bg-teal-400 rounded-lg transition-colors shadow-sm flex items-center gap-1.5"
                >
                  {isUploading ? (
                    <>
                      <span className="animate-spin text-sm">🌀</span>
                      <span>Uploading File to Storage...</span>
                    </>
                  ) : (
                    "Upload & Save Material"
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
