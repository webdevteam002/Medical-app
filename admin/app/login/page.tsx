"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { setAdminSession } from "@/lib/auth";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);

  const [emailError, setEmailError] = useState("");
  const [passwordError, setPasswordError] = useState("");
  const [apiError, setApiError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const validateForm = (): boolean => {
    let isValid = true;
    setEmailError("");
    setPasswordError("");
    setApiError("");

    if (!email.trim()) {
      setEmailError("Email address is required.");
      isValid = false;
    } else {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email.trim())) {
        setEmailError("Please enter a valid email address.");
        isValid = false;
      }
    }

    if (!password) {
      setPasswordError("Password is required.");
      isValid = false;
    } else if (password.length < 6) {
      setPasswordError("Password must be at least 6 characters.");
      isValid = false;
    }

    return isValid;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validateForm()) return;

    setIsSubmitting(true);
    setApiError("");

    try {
      const baseUrl =
        process.env.NEXT_PUBLIC_API_BASE_URL || "http://localhost:3000/api";

      const res = await fetch(`${baseUrl}/auth/login`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
        },
        body: JSON.stringify({
          email: email.trim(),
          password,
          deviceId: "admin-web-dashboard",
          deviceName: "MedStudy Admin Web",
        }),
      });

      const data = await res.json();

      if (res.ok && data.accessToken) {
        const role = data.user?.role?.toUpperCase();
        if (role === "ADMIN" || role === "SUPER_ADMIN") {
          setAdminSession(data.accessToken, data.user);
          router.push("/");
          return;
        } else {
          setApiError("Access denied. Admin credentials required.");
          setIsSubmitting(false);
          return;
        }
      }

      if (res.status === 401 || res.status === 403) {
        setApiError(data.message || "Invalid admin email or password.");
      } else {
        setApiError(
          data.message || "Authentication failed. Please check credentials."
        );
      }
    } catch (err: unknown) {
      setApiError(
        err instanceof Error
          ? err.message
          : "Unable to connect to authentication server."
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-900 p-4">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-xl p-8 border border-slate-100">
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-teal-600 text-white text-xl font-bold mb-3 shadow-sm">
            M
          </div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">
            MedStudy Admin
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Sign in to access the administration portal
          </p>
        </div>

        {apiError && (
          <div className="mb-6 p-4 rounded-lg bg-red-50 border border-red-200 flex items-start gap-3">
            <span className="text-red-500 text-lg">⚠️</span>
            <p className="text-xs font-medium text-red-800 leading-snug">
              {apiError}
            </p>
          </div>
        )}

        <form onSubmit={handleSubmit} noValidate className="space-y-5">
          <div>
            <label
              htmlFor="email"
              className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-2"
            >
              Email Address
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@medstudy.org"
              aria-invalid={!!emailError}
              aria-describedby={emailError ? "email-error" : undefined}
              className={`w-full px-4 py-3 rounded-lg border text-slate-900 text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 transition-all ${
                emailError ? "border-red-500 ring-1 ring-red-500" : "border-slate-300"
              }`}
            />
            {emailError && (
              <p id="email-error" className="mt-1.5 text-xs text-red-600 font-medium">
                {emailError}
              </p>
            )}
          </div>

          <div>
            <label
              htmlFor="password"
              className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-2"
            >
              Password
            </label>
            <div className="relative">
              <input
                id="password"
                type={showPassword ? "text" : "password"}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                aria-invalid={!!passwordError}
                aria-describedby={passwordError ? "password-error" : undefined}
                className={`w-full px-4 py-3 pr-12 rounded-lg border text-slate-900 text-sm placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-teal-500 transition-all ${
                  passwordError ? "border-red-500 ring-1 ring-red-500" : "border-slate-300"
                }`}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-medium text-slate-500 hover:text-slate-800 px-2 py-1 rounded focus:outline-none focus:ring-1 focus:ring-teal-500"
                aria-label={showPassword ? "Hide password" : "Show password"}
              >
                {showPassword ? "Hide" : "Show"}
              </button>
            </div>
            {passwordError && (
              <p id="password-error" className="mt-1.5 text-xs text-red-600 font-medium">
                {passwordError}
              </p>
            )}
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full bg-slate-900 hover:bg-slate-800 disabled:bg-slate-700 text-white font-medium py-3 px-4 rounded-lg text-sm transition-colors shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-900 flex items-center justify-center"
          >
            {isSubmitting ? "Signing in..." : "Sign In to Dashboard"}
          </button>
        </form>

        <div className="mt-8 pt-6 border-t border-slate-100 text-center">
          <p className="text-xs text-slate-400">
            Day 8 Admin Auth Guard Active &bull; Protected Route Enforcement
          </p>
        </div>
      </div>
    </div>
  );
}
