"use client";

import { useEffect, useState, useMemo } from "react";
import { Exam, setAdminExamQuestions } from "@/lib/exams";
import { Question, Difficulty, fetchAdminQuestions } from "@/lib/questions";

interface ExamQuestionPickerModalProps {
  exam: Exam;
  isOpen: boolean;
  onClose: () => void;
  onSaveSuccess: (updatedExam: Exam) => void;
}

export default function ExamQuestionPickerModal({
  exam,
  isOpen,
  onClose,
  onSaveSuccess,
}: ExamQuestionPickerModalProps) {
  const [questions, setQuestions] = useState<Question[]>([]);
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isSaving, setIsSaving] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    let isMounted = true;
    Promise.resolve().then(() => {
      if (isMounted) {
        setIsLoading(true);
        setError(null);
        setSelectedIds(new Set());
      }
    });

    fetchAdminQuestions(exam.subjectId)
      .then((data) => {
        if (isMounted) {
          setQuestions(data);
          setIsLoading(false);
        }
      })
      .catch((err: unknown) => {
        if (isMounted) {
          setError(
            err instanceof Error
              ? err.message
              : "Failed to load candidate questions for this subject."
          );
          setIsLoading(false);
        }
      });

    return () => {
      isMounted = false;
    };
  }, [isOpen, exam.subjectId]);

  const filteredQuestions = useMemo(() => {
    if (!searchQuery.trim()) return questions;
    const query = searchQuery.toLowerCase();
    return questions.filter((q) => q.stem.toLowerCase().includes(query));
  }, [questions, searchQuery]);

  const handleToggleQuestion = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const handleSelectAllFiltered = () => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      filteredQuestions.forEach((q) => next.add(q.id));
      return next;
    });
  };

  const handleDeselectAllFiltered = () => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      filteredQuestions.forEach((q) => next.delete(q.id));
      return next;
    });
  };

  const handleSaveAssignment = async () => {
    setIsSaving(true);
    setError(null);
    try {
      const updatedExam = await setAdminExamQuestions(
        exam.id,
        Array.from(selectedIds)
      );
      onSaveSuccess(updatedExam);
      onClose();
    } catch (err: unknown) {
      setError(
        err instanceof Error
          ? err.message
          : "Failed to save exam question assignment."
      );
    } finally {
      setIsSaving(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-3xl overflow-hidden border border-slate-100 max-h-[90vh] flex flex-col">
        {/* Header */}
        <div className="px-6 py-4 border-b border-slate-200 flex items-center justify-between bg-slate-50 flex-shrink-0">
          <div>
            <h3 className="text-base font-bold text-slate-900">
              Manage Exam Questions — {exam.title}
            </h3>
            <p className="text-xs text-slate-500 mt-0.5">
              Subject: {exam.subject?.name || "Subject"} &bull; Current Exam Question Count: {exam.questionCount || 0}
            </p>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 text-lg leading-none p-1 rounded"
          >
            ✕
          </button>
        </div>

        {/* Contract Notice */}
        <div className="px-6 pt-4 flex-shrink-0">
          <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg text-xs text-amber-900 flex items-start gap-2">
            <span>ℹ️</span>
            <p>
              NestJS backend API endpoint <code className="bg-amber-100 px-1 py-0.5 rounded font-mono">POST /v1/admin/exams/:id/questions</code> sets the active question list and recalculates the exam question count. Select questions below to assign them.
            </p>
          </div>
        </div>

        {/* Filter Controls & Search */}
        <div className="p-6 pb-3 space-y-3 flex-shrink-0">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search candidate question stems..."
              className="px-3.5 py-2 text-xs rounded-lg border border-slate-300 text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 flex-1"
            />
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={handleSelectAllFiltered}
                disabled={filteredQuestions.length === 0}
                className="px-2.5 py-1.5 text-[11px] font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded transition-colors"
              >
                Select Filtered
              </button>
              <button
                type="button"
                onClick={handleDeselectAllFiltered}
                disabled={selectedIds.size === 0}
                className="px-2.5 py-1.5 text-[11px] font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded transition-colors"
              >
                Deselect Filtered
              </button>
            </div>
          </div>

          <div className="flex items-center justify-between text-xs text-slate-600 font-medium">
            <span>
              Showing {filteredQuestions.length} candidate questions
            </span>
            <span className="font-bold text-teal-700 bg-teal-50 px-2.5 py-1 rounded-full border border-teal-200">
              Selected: {selectedIds.size} questions
            </span>
          </div>
        </div>

        {/* Error Notification */}
        {error && (
          <div className="mx-6 p-3 rounded-lg bg-red-50 border border-red-200 text-xs text-red-800 flex-shrink-0">
            ⚠️ {error}
          </div>
        )}

        {/* Candidate Questions List */}
        <div className="p-6 pt-0 overflow-y-auto flex-1 space-y-2">
          {isLoading ? (
            <div className="py-12 text-center">
              <div className="inline-block animate-spin rounded-full h-7 w-7 border-4 border-slate-200 border-t-teal-600 mb-2"></div>
              <p className="text-xs text-slate-500">Loading candidate questions for subject...</p>
            </div>
          ) : filteredQuestions.length === 0 ? (
            <div className="py-12 text-center border border-dashed border-slate-200 rounded-xl">
              <p className="text-xs font-semibold text-slate-600">No questions found</p>
              <p className="text-[11px] text-slate-400 mt-0.5">
                {searchQuery
                  ? "No questions match your search filter."
                  : "No MCQs created for this subject yet."}
              </p>
            </div>
          ) : (
            filteredQuestions.map((question) => {
              const isSelected = selectedIds.has(question.id);
              return (
                <div
                  key={question.id}
                  onClick={() => handleToggleQuestion(question.id)}
                  className={`p-3.5 rounded-xl border transition-all cursor-pointer flex items-start gap-3.5 ${
                    isSelected
                      ? "bg-teal-50/60 border-teal-500 shadow-xs"
                      : "bg-white border-slate-200 hover:border-slate-300"
                  }`}
                >
                  <input
                    type="checkbox"
                    checked={isSelected}
                    onChange={() => {}} // Controlled by outer click
                    className="w-4 h-4 rounded text-teal-600 focus:ring-teal-500 border-slate-300 mt-0.5"
                  />
                  <div className="flex-1 min-w-0">
                    <p className="text-xs font-semibold text-slate-900 leading-relaxed">
                      {question.stem}
                    </p>
                    <div className="flex flex-wrap items-center gap-2 mt-2 text-[10px]">
                      <span className={`px-2 py-0.5 rounded font-bold border ${
                        question.difficulty === Difficulty.EASY
                          ? "bg-emerald-50 text-emerald-700 border-emerald-200"
                          : question.difficulty === Difficulty.HARD
                          ? "bg-red-50 text-red-700 border-red-200"
                          : "bg-amber-50 text-amber-800 border-amber-200"
                      }`}>
                        {question.difficulty}
                      </span>
                      <span className="bg-slate-100 text-slate-600 px-2 py-0.5 rounded border border-slate-200 font-mono">
                        {Array.isArray(question.options) ? question.options.length : 0} options
                      </span>
                      <span className="bg-slate-100 text-slate-600 px-2 py-0.5 rounded border border-slate-200 font-mono font-bold">
                        Ans: {question.correctOptionId.toUpperCase()}
                      </span>
                      {question.isPublished ? (
                        <span className="text-emerald-700 font-semibold">● Published</span>
                      ) : (
                        <span className="text-amber-700 font-semibold">○ Draft</span>
                      )}
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Modal Footer */}
        <div className="px-6 py-4 border-t border-slate-200 bg-slate-50 flex items-center justify-between flex-shrink-0">
          <span className="text-xs text-slate-500 font-medium">
            {selectedIds.size} questions will be assigned to this exam.
          </span>
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={onClose}
              disabled={isSaving}
              className="px-4 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-200 rounded-lg transition-colors"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={handleSaveAssignment}
              disabled={isSaving}
              className="px-4 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-700 disabled:bg-teal-400 rounded-lg transition-colors shadow-sm flex items-center gap-1.5"
            >
              {isSaving ? "Saving Questions..." : "Save Questions Assignment"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
