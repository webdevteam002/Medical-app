export const ADMIN_TOKEN_COOKIE = "admin_access_token";
export const ADMIN_USER_COOKIE = "admin_user";

export interface AdminUser {
  id: string;
  email: string;
  fullName: string;
  role: string;
}

export function getCookie(name: string): string | null {
  if (typeof document === "undefined") return null;
  const value = `; ${document.cookie}`;
  const parts = value.split(`; ${name}=`);
  if (parts.length === 2) return parts.pop()?.split(";").shift() || null;
  return null;
}

export function setCookie(name: string, value: string, days = 7) {
  if (typeof document === "undefined") return;
  const date = new Date();
  date.setTime(date.getTime() + days * 24 * 60 * 60 * 1000);
  const expires = `; expires=${date.toUTCString()}`;
  const isSecure =
    typeof window !== "undefined" && window.location.protocol === "https:";
  const secureFlag = isSecure ? "; Secure" : "";
  document.cookie = `${name}=${encodeURIComponent(value)}${expires}; path=/; SameSite=Lax${secureFlag}`;
}

export function deleteCookie(name: string) {
  if (typeof document === "undefined") return;
  const isSecure =
    typeof window !== "undefined" && window.location.protocol === "https:";
  const secureFlag = isSecure ? "; Secure" : "";
  document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; SameSite=Lax${secureFlag}`;
}

export function setAdminSession(token: string, user?: AdminUser) {
  setCookie(ADMIN_TOKEN_COOKIE, token);
  if (user) {
    setCookie(ADMIN_USER_COOKIE, JSON.stringify(user));
  }
}

export function clearAdminSession() {
  deleteCookie(ADMIN_TOKEN_COOKIE);
  deleteCookie(ADMIN_USER_COOKIE);
}

export function getAdminToken(): string | null {
  return getCookie(ADMIN_TOKEN_COOKIE);
}

export function getAdminUser(): AdminUser | null {
  const raw = getCookie(ADMIN_USER_COOKIE);
  if (!raw) return null;
  try {
    return JSON.parse(decodeURIComponent(raw)) as AdminUser;
  } catch {
    return null;
  }
}

export function isAdminAuthenticated(): boolean {
  const token = getAdminToken();
  return !!token && token.trim().length > 0;
}
