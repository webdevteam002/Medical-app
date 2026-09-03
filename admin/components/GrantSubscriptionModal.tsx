"use client";

import { useState } from "react";
import {
  PlanType,
  GrantSubscriptionPayload,
  grantAdminSubscription,
  validateGrantSubscriptionPayload,
} from "@/lib/subscriptions";

interface GrantSubscriptionModalProps {
  userId: string;
  userEmail: string;
  userName: string;
  isOpen: boolean;
  onClose: () => void;
  onGrantSuccess: () => void;
}

export default function GrantSubscriptionModal({
  userId,
  userEmail,
  userName,
  isOpen,
  onClose,
  onGrantSuccess,
}: GrantSubscriptionModalProps) {
  const [planType, setPlanType] = useState<PlanType>(PlanType.YEAR_1);
  const [durationDays, setDurationDays] = useState<number>(365);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const payload: GrantSubscriptionPayload = {
      planType,
      durationDays: Number(durationDays),
    };

    const validation = validateGrantSubscriptionPayload(payload);
    if (!validation.isValid) {
      setFieldErrors(validation.errors);
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      await grantAdminSubscription(userId, payload);
      onGrantSuccess();
      onClose();
    } catch (err: unknown) {
      setError(
        err instanceof Error
          ? err.message
          : "Failed to grant subscription."
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4">
      <div className="bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden border border-slate-100">
        <div className="px-6 py-5 border-b border-slate-200 flex items-center justify-between bg-slate-50">
          <div>
            <h3 className="text-base font-bold text-slate-900">
              Grant Manual Subscription
            </h3>
            <p className="text-xs text-slate-500 mt-0.5">
              Student: {userName} ({userEmail})
            </p>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-slate-600 text-lg leading-none p-1 rounded"
          >
            ✕
          </button>
        </div>

        {error && (
          <div className="mx-6 mt-5 p-3 rounded-lg bg-red-50 border border-red-200 text-xs text-red-800 flex items-start gap-2">
            <span>⚠️</span>
            <p>{error}</p>
          </div>
        )}

        <form onSubmit={handleSubmit} noValidate className="p-6 space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
              Subscription Plan <span className="text-red-500">*</span>
            </label>
            <select
              value={planType}
              onChange={(e) => setPlanType(e.target.value as PlanType)}
              className="w-full px-3.5 py-2.5 text-xs rounded-lg border border-slate-300 text-slate-900 bg-white focus:outline-none focus:ring-2 focus:ring-teal-500 font-medium"
            >
              <option value={PlanType.YEAR_1}>1st Year MBBS</option>
              <option value={PlanType.YEAR_2}>2nd Year MBBS</option>
              <option value={PlanType.YEAR_3}>3rd Year MBBS</option>
              <option value={PlanType.YEAR_4}>4th Year MBBS</option>
              <option value={PlanType.YEAR_5}>5th Year MBBS</option>
              <option value={PlanType.FCPS_PART_1}>FCPS Part 1</option>
              <option value={PlanType.FCPS_PART_2}>FCPS Part 2</option>
              <option value={PlanType.ALL_MBBS}>All MBBS (5 Years Bundle)</option>
              <option value={PlanType.ULTIMATE_BUNDLE}>Ultimate Access Bundle</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
              Duration (Days) <span className="text-red-500">*</span>
            </label>
            <input
              type="number"
              min="1"
              value={durationDays}
              onChange={(e) => setDurationDays(parseInt(e.target.value) || 1)}
              className={`w-full px-3.5 py-2.5 text-xs rounded-lg border text-slate-900 focus:outline-none focus:ring-2 focus:ring-teal-500 ${
                fieldErrors.durationDays ? "border-red-500 ring-1 ring-red-500" : "border-slate-300"
              }`}
            />
            {fieldErrors.durationDays && (
              <p className="mt-1 text-[11px] text-red-600 font-medium">
                {fieldErrors.durationDays}
              </p>
            )}
          </div>

          <div className="mt-6 pt-4 border-t border-slate-200 flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
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
              {isSubmitting ? "Granting..." : "Grant Subscription Access"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
