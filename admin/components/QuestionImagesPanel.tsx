"use client";

import { useEffect, useState } from "react";
import { getAdminToken } from "@/lib/auth";
import { getApiBaseUrl } from "@/lib/years";

interface ImageStatus {
  storageMode: string;
  indexedFiles: number;
  indexedAt: string | null;
}

async function fetchStatus(): Promise<ImageStatus> {
  const token = getAdminToken();
  const res = await fetch(`${getApiBaseUrl()}/admin/question-images/status`, {
    headers: {
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    cache: "no-store",
  });
  if (!res.ok) throw new Error("Failed to load image storage status");
  return res.json();
}

async function reindex(): Promise<ImageStatus> {
  const token = getAdminToken();
  const res = await fetch(`${getApiBaseUrl()}/admin/question-images/reindex`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });
  if (!res.ok) throw new Error("Failed to reindex images");
  return res.json();
}

async function uploadFiles(files: FileList, folder: string) {
  const token = getAdminToken();
  const form = new FormData();
  if (folder.trim()) form.append("folder", folder.trim());
  Array.from(files).forEach((f) => form.append("files", f));
  const res = await fetch(`${getApiBaseUrl()}/admin/question-images/upload`, {
    method: "POST",
    headers: {
      Accept: "application/json",
      "X-Device-Id": "admin-web-dashboard",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: form,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || `Upload failed (HTTP ${res.status})`);
  }
  return res.json() as Promise<{ uploaded: number; keys: string[] }>;
}

export default function QuestionImagesPanel() {
  const [status, setStatus] = useState<ImageStatus | null>(null);
  const [folder, setFolder] = useState("uworld");
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchStatus()
      .then(setStatus)
      .catch((e: unknown) =>
        setError(e instanceof Error ? e.message : "Status failed"),
      );
  }, []);

  const onUpload = async (files: FileList | null) => {
    if (!files || files.length === 0) return;
    setBusy(true);
    setError(null);
    setMessage(null);
    try {
      const result = await uploadFiles(files, folder);
      const next = await reindex();
      setStatus(next);
      setMessage(
        `Uploaded ${result.uploaded} image(s). Indexed files: ${next.indexedFiles}.`,
      );
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Upload failed");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="bg-white rounded-xl border border-slate-200 shadow-sm p-5 space-y-3">
      <div>
        <h2 className="text-sm font-bold text-slate-900 uppercase tracking-wider">
          Question Images
        </h2>
        <p className="text-xs text-slate-500 mt-1">
          Bulk-upload image files so CSV <code className="font-mono">image_key</code> values
          (e.g. <code className="font-mono">U44341.jpg</code>) resolve in exams. Filenames must match exactly.
        </p>
      </div>

      {status && (
        <p className="text-xs text-slate-700">
          Storage: <span className="font-semibold">{status.storageMode}</span> · Indexed:{" "}
          <span className="font-semibold">{status.indexedFiles}</span>
          {status.indexedAt ? ` · Updated ${new Date(status.indexedAt).toLocaleString()}` : ""}
        </p>
      )}

      <div className="flex flex-wrap items-end gap-3">
        <div>
          <label className="block text-[11px] font-semibold text-slate-600 mb-1">
            Folder (optional)
          </label>
          <input
            value={folder}
            onChange={(e) => setFolder(e.target.value)}
            placeholder="uworld / amboss / usmle-rx"
            className="px-3 py-2 text-xs rounded-lg border border-slate-300"
          />
        </div>
        <label className="px-4 py-2 text-xs font-semibold text-white bg-teal-600 hover:bg-teal-700 rounded-lg cursor-pointer">
          {busy ? "Uploading…" : "Select images"}
          <input
            type="file"
            accept="image/*"
            multiple
            className="hidden"
            disabled={busy}
            onChange={(e) => onUpload(e.target.files)}
          />
        </label>
        <button
          type="button"
          disabled={busy}
          onClick={async () => {
            setBusy(true);
            try {
              setStatus(await reindex());
              setMessage("Image index rebuilt.");
            } catch (e: unknown) {
              setError(e instanceof Error ? e.message : "Reindex failed");
            } finally {
              setBusy(false);
            }
          }}
          className="px-3 py-2 text-xs font-semibold text-slate-700 bg-slate-100 border border-slate-200 rounded-lg"
        >
          Rebuild index
        </button>
      </div>

      {message && (
        <p className="text-xs text-emerald-700 bg-emerald-50 border border-emerald-200 rounded-lg px-3 py-2">
          {message}
        </p>
      )}
      {error && (
        <p className="text-xs text-red-700 bg-red-50 border border-red-200 rounded-lg px-3 py-2">
          {error}
        </p>
      )}

      <p className="text-[11px] text-slate-500 leading-relaxed">
        For thousands of files, copy them onto the server at{" "}
        <code className="font-mono">backend/uploads/images/</code> then click Rebuild index.
        R2 is optional later — production currently uses local storage.
      </p>
    </div>
  );
}
