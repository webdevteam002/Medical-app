"use client";

import { useState } from "react";
import { Subject } from "@/lib/subjects";
import { CsvImportResult, importAdminQuestionsCsv } from "@/lib/questions";

interface CsvImportModalProps {
  subjects: Subject[];
  defaultSubjectId?: string;
  isOpen: boolean;
  onClose: () => void;
  onImportSuccess: (result: CsvImportResult) => void;
}

export default function CsvImportModal({
  subjects,
  defaultSubjectId = "",
  isOpen,
  onClose,
  onImportSuccess,
}: CsvImportModalProps) {
  const [selectedSubjectId, setSelectedSubjectId] = useState<string>(
    defaultSubjectId || (subjects.length > 0 ? subjects[0].id : "")
  );
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [dryRun, setDryRun] = useState<boolean>(false);
  const [isImporting, setIsImporting] = useState<boolean>(false);
  const [modalError, setModalError] = useState<string | null>(null);
  const [importResult, setImportResult] = useState<CsvImportResult | null>(null);

  if (!isOpen) return null;

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0] || null;
    setSelectedFile(file);
    setModalError(null);
  };

  const handleSubmitImport = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!selectedSubjectId) {
      setModalError("Please select a parent subject for imported questions.");
      return;
    }
    if (!selectedFile) {
      setModalError("Please select a CSV file to import.");
      return;
    }

    setIsImporting(true);
    setModalError(null);
    setImportResult(null);

    try {
      const result = await importAdminQuestionsCsv(
        selectedSubjectId,
        selectedFile,
        dryRun
      );
      setImportResult(result);
      onImportSuccess(result);
    } catch (err: unknown) {
      setModalError(
        err instanceof Error ? err.message : "Failed to import CSV file."
      );
    } finally {
      setIsImporting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-xl overflow-hidden border border-slate-100 max-h-[90vh] flex flex-col">
        {/* Modal Header */}
        <div className="px-6 py-5 border-b border-slate-200 flex items-center justify-between bg-slate-50 flex-shrink-0">
          <div>
            <h3 className="text-base font-bold text-slate-900">
              Bulk Import Questions from CSV
            </h3>
            <p className="text-xs text-slate-500 mt-0.5">
              Upload CSV file containing question stems, options, and correct answers
            </p>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 text-lg leading-none p-1 rounded"
          >
            ✕
          </button>
        </div>

        <form onSubmit={handleSubmitImport} noValidate className="p-6 space-y-4 overflow-y-auto flex-1">
          {/* Format Instructions */}
          <div className="p-3.5 bg-slate-50 border border-slate-200 rounded-xl text-xs space-y-2">
            <p className="font-bold text-slate-800 flex items-center gap-1.5">
              <span>📋</span> Backend CSV Format Requirements
            </p>
            <p className="text-slate-600 text-[11px]">
              Required Headers: <code className="bg-slate-200 px-1 py-0.5 rounded font-mono text-slate-900">stem, option_a, option_b, option_c, option_d, correct_option</code>
            </p>
            <p className="text-slate-600 text-[11px]">
              Optional Headers: <code className="bg-slate-200 px-1 py-0.5 rounded font-mono text-slate-900">option_e, explanation, difficulty, tags, image_key</code>
            </p>
            <p className="text-slate-500 text-[10px]">
              Note: <code className="font-mono">correct_option</code> must be one of: <code className="font-mono">a, b, c, d, e</code>. <code className="font-mono">difficulty</code> must be <code className="font-mono">EASY, MEDIUM, HARD</code>.
            </p>
          </div>

          {modalError && (
            <div className="p-3 rounded-lg bg-red-50 border border-red-200 text-xs text-red-800 flex items-start gap-2">
              <span>⚠️</span>
              <p>{modalError}</p>
            </div>
          )}

          {/* Import Result Summary Card */}
          {importResult && (
            <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-xs space-y-2">
              <div className="flex items-center justify-between font-bold text-emerald-900">
                <span>{importResult.dryRun ? "🔍 Dry Run Inspection Complete" : "✅ Import Operation Complete"}</span>
                <span>Imported: {importResult.imported} rows</span>
              </div>
              <p className="text-[11px] text-emerald-800">
                Skipped: {importResult.skipped} empty rows
              </p>

              {importResult.errors.length > 0 && (
                <div className="mt-2 pt-2 border-t border-emerald-200 space-y-1">
                  <p className="font-bold text-red-800">
                    Row Failures ({importResult.errors.length}):
                  </p>
                  <div className="max-h-32 overflow-y-auto space-y-1 font-mono text-[10px] text-red-700 bg-white p-2 rounded border border-red-200">
                    {importResult.errors.map((err, idx) => (
                      <p key={idx}>
                        Row {err.row}: {err.reason}
                      </p>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Parent Subject Select */}
          <div>
            <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
              Target Parent Subject <span className="text-red-500">*</span>
            </label>
            <select
              value={selectedSubjectId}
              onChange={(e) => setSelectedSubjectId(e.target.value)}
              className="w-full px-3.5 py-2.5 text-xs rounded-lg border border-slate-300 text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-teal-500"
            >
              <option value="">Select Parent Subject...</option>
              {subjects.map((subject) => (
                <option key={subject.id} value={subject.id}>
                  {subject.name} ({subject.year?.name || subject.slug})
                </option>
              ))}
            </select>
          </div>

          {/* CSV File Input */}
          <div>
            <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
              CSV File <span className="text-red-500">*</span>
            </label>
            <input
              type="file"
              accept=".csv,text/csv"
              onChange={handleFileChange}
              className="w-full text-xs text-slate-700 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-slate-100 file:text-slate-700 hover:file:bg-slate-200"
            />
          </div>

          {/* Dry Run Checkbox */}
          <div className="pt-2">
            <label className="flex items-center gap-2 cursor-pointer text-xs font-semibold text-slate-800">
              <input
                type="checkbox"
                checked={dryRun}
                onChange={(e) => setDryRun(e.target.checked)}
                className="w-4 h-4 rounded text-teal-600 focus:ring-teal-500 border-slate-300"
              />
              <span>Dry Run (Validate CSV headers & format without creating database records)</span>
            </label>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-200 flex items-center justify-end gap-3 flex-shrink-0">
            <button
              type="button"
              onClick={onClose}
              disabled={isImporting}
              className="px-4 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-100 rounded-lg transition-colors"
            >
              Close
            </button>
            <button
              type="submit"
              disabled={isImporting}
              className="px-4 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-700 disabled:bg-teal-400 rounded-lg transition-colors shadow-sm flex items-center gap-1.5"
            >
              {isImporting ? (
                <>
                  <span className="animate-spin text-sm">🌀</span>
                  <span>Importing CSV...</span>
                </>
              ) : dryRun ? (
                "Validate CSV Dry Run"
              ) : (
                "Import CSV Questions"
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
