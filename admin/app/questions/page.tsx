"use client";

import { useEffect, useState, useCallback, useMemo } from "react";
import Sidebar from "@/components/Sidebar";
import CsvImportModal from "@/components/CsvImportModal";
import { Subject, fetchAdminSubjects } from "@/lib/subjects";
import {
  Question,
  Difficulty,
  QuestionOption,
  CreateQuestionPayload,
  fetchAdminQuestions,
  createAdminQuestion,
  updateAdminQuestion,
  deleteAdminQuestion,
  validateQuestionPayload,
} from "@/lib/questions";

export default function QuestionsManagementPage() {
  const [questions, setQuestions] = useState<Question[]>([]);
  const [subjects, setSubjects] = useState<Subject[]>([]);
  const [selectedSubjectFilter, setSelectedSubjectFilter] = useState<string>("");
  const [selectedDifficultyFilter, setSelectedDifficultyFilter] = useState<string>("");

  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  const [pendingPublishId, setPendingPublishId] = useState<string | null>(null);
  const [pendingDeleteId, setPendingDeleteId] = useState<string | null>(null);

  // Modal States
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [isCsvModalOpen, setIsCsvModalOpen] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [modalError, setModalError] = useState<string | null>(null);

  // Form Fields
  const [formSubjectId, setFormSubjectId] = useState<string>("");
  const [formStem, setFormStem] = useState<string>("");
  const [formOptionA, setFormOptionA] = useState<string>("");
  const [formOptionB, setFormOptionB] = useState<string>("");
  const [formOptionC, setFormOptionC] = useState<string>("");
  const [formOptionD, setFormOptionD] = useState<string>("");
  const [formOptionE, setFormOptionE] = useState<string>("");
  const [formCorrectOptionId, setFormCorrectOptionId] = useState<string>("a");
  const [formExplanation, setFormExplanation] = useState<string>("");
  const [formDifficulty, setFormDifficulty] = useState<Difficulty>(Difficulty.MEDIUM);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  useEffect(() => {
    let isMounted = true;
    Promise.all([fetchAdminQuestions(), fetchAdminSubjects()])
      .then(([questionsData, subjectsData]) => {
        if (isMounted) {
          setQuestions(questionsData);
          setSubjects(subjectsData);
          setIsLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (isMounted) {
          setErrorMessage(
            err instanceof Error ? err.message : "Failed to load questions or subjects."
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
      const data = await fetchAdminQuestions(selectedSubjectFilter || undefined);
      setQuestions(data);
    } catch (err: unknown) {
      setErrorMessage(
        err instanceof Error ? err.message : "Failed to load questions."
      );
    } finally {
      setIsLoading(false);
    }
  }, [selectedSubjectFilter]);

  const handleSubjectFilterChange = async (subjectIdFilter: string) => {
    setSelectedSubjectFilter(subjectIdFilter);
    setIsLoading(true);
    setErrorMessage(null);
    try {
      const data = await fetchAdminQuestions(subjectIdFilter || undefined);
      setQuestions(data);
    } catch (err: unknown) {
      setErrorMessage(
        err instanceof Error ? err.message : "Failed to filter questions."
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleOpenModal = () => {
    const defaultSubjectId = selectedSubjectFilter || (subjects.length > 0 ? subjects[0].id : "");
    setFormSubjectId(defaultSubjectId);
    setFormStem("");
    setFormOptionA("");
    setFormOptionB("");
    setFormOptionC("");
    setFormOptionD("");
    setFormOptionE("");
    setFormCorrectOptionId("a");
    setFormExplanation("");
    setFormDifficulty(Difficulty.MEDIUM);
    setFieldErrors({});
    setModalError(null);
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const options: QuestionOption[] = [
      { id: "a", text: formOptionA.trim() },
      { id: "b", text: formOptionB.trim() },
      { id: "c", text: formOptionC.trim() },
      { id: "d", text: formOptionD.trim() },
    ];

    if (formOptionE.trim().length > 0) {
      options.push({ id: "e", text: formOptionE.trim() });
    }

    const payload: CreateQuestionPayload = {
      subjectId: formSubjectId,
      stem: formStem.trim(),
      options,
      correctOptionId: formCorrectOptionId,
      explanation: formExplanation.trim(),
      difficulty: formDifficulty,
    };

    const validation = validateQuestionPayload(payload);
    if (!validation.isValid) {
      setFieldErrors(validation.errors);
      return;
    }

    setIsSubmitting(true);
    setModalError(null);

    try {
      await createAdminQuestion(payload);
      const updatedList = await fetchAdminQuestions(selectedSubjectFilter || undefined);
      setQuestions(updatedList);
      setIsModalOpen(false);
      setSuccessMessage(`Question created successfully.`);
      setTimeout(() => setSuccessMessage(null), 4000);
    } catch (err: unknown) {
      setModalError(
        err instanceof Error ? err.message : "Failed to create question."
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleTogglePublish = async (question: Question) => {
    setPendingPublishId(question.id);
    try {
      const updated = await updateAdminQuestion(question.id, {
        isPublished: !question.isPublished,
      });
      setQuestions((prev) =>
        prev.map((q) => (q.id === question.id ? { ...q, isPublished: updated.isPublished } : q))
      );
      setSuccessMessage(
        `Question status updated to ${updated.isPublished ? "PUBLISHED" : "UNPUBLISHED"}.`
      );
      setTimeout(() => setSuccessMessage(null), 4000);
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "Failed to update publish state.");
    } finally {
      setPendingPublishId(null);
    }
  };

  const handleDelete = async (question: Question) => {
    if (!confirm(`Are you sure you want to delete this question?`)) {
      return;
    }

    setPendingDeleteId(question.id);
    try {
      await deleteAdminQuestion(question.id);
      setQuestions((prev) => prev.filter((q) => q.id !== question.id));
      setSuccessMessage(`Question deleted.`);
      setTimeout(() => setSuccessMessage(null), 4000);
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : "Failed to delete question.");
    } finally {
      setPendingDeleteId(null);
    }
  };

  const filteredQuestions = useMemo(() => {
    if (!selectedDifficultyFilter) return questions;
    return questions.filter((q) => q.difficulty === selectedDifficultyFilter);
  }, [questions, selectedDifficultyFilter]);

  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 flex flex-col min-w-0">
        {/* Top Header */}
        <header className="bg-white border-b border-slate-200 px-8 py-5 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-xl font-bold text-slate-900 tracking-tight">
              Question Bank Management
            </h1>
            <p className="text-xs text-slate-500 mt-0.5">
              Create, bulk import, and manage medical MCQs, option choices, explanations, and difficulty
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            {/* Subject Filter Dropdown */}
            <div className="flex items-center gap-2">
              <label htmlFor="subjectFilter" className="text-xs font-semibold text-slate-600">
                Subject:
              </label>
              <select
                id="subjectFilter"
                value={selectedSubjectFilter}
                onChange={(e) => handleSubjectFilterChange(e.target.value)}
                className="px-3 py-1.5 text-xs rounded-lg border border-slate-300 bg-white text-slate-900 focus:outline-none focus:ring-2 focus:ring-teal-500 font-medium"
              >
                <option value="">All Subjects ({subjects.length})</option>
                {subjects.map((subject) => (
                  <option key={subject.id} value={subject.id}>
                    {subject.name} ({subject.year?.name || subject.slug})
                  </option>
                ))}
              </select>
            </div>

            {/* Difficulty Filter Dropdown */}
            <div className="flex items-center gap-2">
              <label htmlFor="difficultyFilter" className="text-xs font-semibold text-slate-600">
                Difficulty:
              </label>
              <select
                id="difficultyFilter"
                value={selectedDifficultyFilter}
                onChange={(e) => setSelectedDifficultyFilter(e.target.value)}
                className="px-3 py-1.5 text-xs rounded-lg border border-slate-300 bg-white text-slate-900 focus:outline-none focus:ring-2 focus:ring-teal-500 font-medium"
              >
                <option value="">All Difficulties</option>
                <option value={Difficulty.EASY}>Easy</option>
                <option value={Difficulty.MEDIUM}>Medium</option>
                <option value={Difficulty.HARD}>Hard</option>
              </select>
            </div>

            <button
              onClick={handleRefresh}
              disabled={isLoading}
              className="px-3.5 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 disabled:opacity-50 rounded-lg transition-colors border border-slate-200 flex items-center gap-1.5"
              aria-label="Refresh questions list"
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
              onClick={() => setIsCsvModalOpen(true)}
              disabled={subjects.length === 0}
              className="px-3.5 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 disabled:opacity-50 rounded-lg transition-colors border border-slate-200 flex items-center gap-1.5"
            >
              <span>📥</span> Import CSV
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
                  d="M12 4v16m8-8H4"
                />
              </svg>
              Add Question
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
                Loading question bank...
              </p>
            </div>
          ) : errorMessage ? (
            <div className="bg-white rounded-xl border border-slate-200 p-8 text-center shadow-sm">
              <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-red-100 text-red-600 text-xl mb-3">
                ⚠️
              </div>
              <h3 className="text-base font-semibold text-slate-900 mb-1">
                Failed to Load Questions
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
          ) : filteredQuestions.length === 0 ? (
            <div className="bg-white rounded-xl border border-slate-200 p-12 text-center shadow-sm">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-slate-100 text-slate-400 text-2xl mb-4">
                ❓
              </div>
              <h3 className="text-base font-semibold text-slate-900 mb-1">
                No Questions Found
              </h3>
              <p className="text-xs text-slate-500 max-w-sm mx-auto mb-6">
                There are currently no MCQs matching your active filters. Click below to add or bulk import questions.
              </p>
              <div className="flex items-center justify-center gap-3">
                <button
                  onClick={() => setIsCsvModalOpen(true)}
                  className="px-4 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors border border-slate-200"
                >
                  Import CSV
                </button>
                <button
                  onClick={handleOpenModal}
                  className="px-4 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-700 rounded-lg transition-colors inline-flex items-center gap-1.5"
                >
                  + Add First Question
                </button>
              </div>
            </div>
          ) : (
            <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
              <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between">
                <h2 className="text-sm font-bold text-slate-900 uppercase tracking-wider">
                  Question Bank ({filteredQuestions.length})
                </h2>
                <span className="text-xs text-slate-500 font-medium">
                  {selectedSubjectFilter
                    ? `Filtered by Subject ID: ${selectedSubjectFilter}`
                    : "Showing All Subjects"}
                </span>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-200 text-[11px] font-bold text-slate-500 uppercase tracking-wider">
                      <th className="py-3.5 px-6">Question Stem</th>
                      <th className="py-3.5 px-6">Difficulty</th>
                      <th className="py-3.5 px-6">Options</th>
                      <th className="py-3.5 px-6">Correct Answer</th>
                      <th className="py-3.5 px-6">Publication Status</th>
                      <th className="py-3.5 px-6 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 text-xs">
                    {filteredQuestions.map((question) => (
                      <tr key={question.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="py-4 px-6 font-medium text-slate-900 max-w-md">
                          <p className="line-clamp-2 leading-relaxed">{question.stem}</p>
                        </td>
                        <td className="py-4 px-6">
                          <span className={`inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold border ${
                            question.difficulty === Difficulty.EASY
                              ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                              : question.difficulty === Difficulty.HARD
                              ? "bg-red-50 text-red-700 border-red-200"
                              : "bg-amber-50 text-amber-800 border-amber-200"
                          }`}>
                            {question.difficulty}
                          </span>
                        </td>
                        <td className="py-4 px-6 font-mono text-slate-600">
                          {Array.isArray(question.options) ? question.options.length : 0} options
                        </td>
                        <td className="py-4 px-6 font-mono font-bold text-teal-700 uppercase">
                          Option {question.correctOptionId}
                        </td>
                        <td className="py-4 px-6">
                          {question.isPublished ? (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                              ● Published
                            </span>
                          ) : (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-amber-50 text-amber-800 border border-amber-200">
                              ○ Draft
                            </span>
                          )}
                        </td>
                        <td className="py-4 px-6 text-right space-x-2">
                          <button
                            onClick={() => handleTogglePublish(question)}
                            disabled={pendingPublishId === question.id}
                            className={`px-2.5 py-1 text-[11px] font-semibold rounded border transition-colors ${
                              question.isPublished
                                ? "bg-amber-50 text-amber-800 border-amber-200 hover:bg-amber-100"
                                : "bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100"
                            }`}
                          >
                            {pendingPublishId === question.id
                              ? "Updating..."
                              : question.isPublished
                              ? "Unpublish"
                              : "Publish"}
                          </button>
                          <button
                            onClick={() => handleDelete(question)}
                            disabled={pendingDeleteId === question.id}
                            className="px-2.5 py-1 text-[11px] font-semibold text-red-600 bg-red-50 hover:bg-red-100 border border-red-200 rounded transition-colors"
                          >
                            {pendingDeleteId === question.id ? "Deleting..." : "Delete"}
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

      {/* CSV Import Modal */}
      <CsvImportModal
        subjects={subjects}
        defaultSubjectId={selectedSubjectFilter}
        isOpen={isCsvModalOpen}
        onClose={() => setIsCsvModalOpen(false)}
        onImportSuccess={() => {
          handleRefresh();
        }}
      />

      {/* Create Question Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-xl overflow-hidden border border-slate-100 max-h-[90vh] flex flex-col">
            <div className="px-6 py-5 border-b border-slate-200 flex items-center justify-between bg-slate-50 flex-shrink-0">
              <div>
                <h3 className="text-base font-bold text-slate-900">
                  Add MCQ Question
                </h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  Configure question stem, 4-5 option choices, correct answer, and explanation
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

            <form onSubmit={handleSubmit} noValidate className="p-6 space-y-4 overflow-y-auto flex-1">
              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                  Parent Subject <span className="text-red-500">*</span>
                </label>
                <select
                  value={formSubjectId}
                  onChange={(e) => setFormSubjectId(e.target.value)}
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
                  Question Stem <span className="text-red-500">*</span>
                </label>
                <textarea
                  rows={3}
                  value={formStem}
                  onChange={(e) => setFormStem(e.target.value)}
                  placeholder="e.g. Which muscle is primarily responsible for initiating abduction of the arm?"
                  className={`w-full px-3.5 py-2.5 text-xs rounded-lg border text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                    fieldErrors.stem ? "border-red-500 ring-1 ring-red-500" : "border-slate-300"
                  }`}
                />
                {fieldErrors.stem && (
                  <p className="mt-1 text-[11px] text-red-600 font-medium">
                    {fieldErrors.stem}
                  </p>
                )}
              </div>

              {/* Options Inputs */}
              <div className="space-y-2 pt-2 border-t border-slate-200">
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Options Choices & Correct Answer (Backend Requires 4 to 5 Options) <span className="text-red-500">*</span>
                </label>

                <div className="space-y-2">
                  {[
                    { id: "a", label: "A", val: formOptionA, setVal: setFormOptionA, req: true },
                    { id: "b", label: "B", val: formOptionB, setVal: setFormOptionB, req: true },
                    { id: "c", label: "C", val: formOptionC, setVal: setFormOptionC, req: true },
                    { id: "d", label: "D", val: formOptionD, setVal: setFormOptionD, req: true },
                    { id: "e", label: "E", val: formOptionE, setVal: setFormOptionE, req: false },
                  ].map((opt) => (
                    <div key={opt.id} className="flex items-center gap-3">
                      <input
                        type="radio"
                        name="correctOption"
                        id={`opt_${opt.id}`}
                        checked={formCorrectOptionId === opt.id}
                        onChange={() => setFormCorrectOptionId(opt.id)}
                        className="w-4 h-4 text-teal-600 focus:ring-teal-500"
                      />
                      <label htmlFor={`opt_${opt.id}`} className="text-xs font-bold text-slate-700 w-4">
                        {opt.label}.
                      </label>
                      <input
                        type="text"
                        value={opt.val}
                        onChange={(e) => opt.setVal(e.target.value)}
                        placeholder={`Option ${opt.label} text ${opt.req ? "(Required)" : "(Optional)"}`}
                        className="flex-1 px-3 py-2 text-xs rounded-lg border border-slate-300 text-slate-900 focus:outline-none focus:ring-2 focus:ring-teal-500"
                      />
                    </div>
                  ))}
                </div>
                {fieldErrors.options && (
                  <p className="mt-1 text-[11px] text-red-600 font-medium">
                    {fieldErrors.options}
                  </p>
                )}
                {fieldErrors.correctOptionId && (
                  <p className="mt-1 text-[11px] text-red-600 font-medium">
                    {fieldErrors.correctOptionId}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                  Explanation <span className="text-red-500">*</span>
                </label>
                <textarea
                  rows={3}
                  value={formExplanation}
                  onChange={(e) => setFormExplanation(e.target.value)}
                  placeholder="e.g. Supraspinatus initiates the first 15 degrees of abduction before Deltoid takes over."
                  className={`w-full px-3.5 py-2.5 text-xs rounded-lg border text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                    fieldErrors.explanation ? "border-red-500 ring-1 ring-red-500" : "border-slate-300"
                  }`}
                />
                {fieldErrors.explanation && (
                  <p className="mt-1 text-[11px] text-red-600 font-medium">
                    {fieldErrors.explanation}
                  </p>
                )}
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
                  Difficulty Level
                </label>
                <select
                  value={formDifficulty}
                  onChange={(e) => setFormDifficulty(e.target.value as Difficulty)}
                  className="w-full px-3.5 py-2.5 text-xs rounded-lg border border-slate-300 text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-teal-500"
                >
                  <option value={Difficulty.EASY}>Easy</option>
                  <option value={Difficulty.MEDIUM}>Medium</option>
                  <option value={Difficulty.HARD}>Hard</option>
                </select>
              </div>

              <div className="mt-6 pt-4 border-t border-slate-200 flex items-center justify-end gap-3 flex-shrink-0">
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
                  {isSubmitting ? "Saving..." : "Create Question"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
