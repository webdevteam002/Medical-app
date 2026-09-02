"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

const navigationItems = [
  { name: "Dashboard", href: "/" },
  { name: "Users", href: "/users" },
  { name: "Content", href: "/content" },
  { name: "Exams", href: "/exams" },
  { name: "Subscriptions", href: "/subscriptions" },
];

export default function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-64 bg-slate-900 text-slate-100 flex flex-col flex-shrink-0 min-h-screen">
      <div className="p-6 border-b border-slate-800 flex items-center gap-3">
        <div className="w-8 h-8 rounded-lg bg-teal-500 flex items-center justify-center font-bold text-slate-950">
          M
        </div>
        <div>
          <h1 className="text-lg font-bold tracking-tight text-white">MedStudy</h1>
          <p className="text-xs text-slate-400">Admin Control Center</p>
        </div>
      </div>
      <nav className="flex-1 p-4 space-y-1" aria-label="Main Navigation">
        {navigationItems.map((item) => {
          const isActive =
            pathname === item.href ||
            (item.href === "/" && pathname === "/dashboard");
          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-colors ${
                isActive
                  ? "bg-teal-600 text-white shadow-sm"
                  : "text-slate-300 hover:bg-slate-800 hover:text-white"
              }`}
              aria-current={isActive ? "page" : undefined}
            >
              {item.name}
            </Link>
          );
        })}
      </nav>
      <div className="p-4 border-t border-slate-800">
        <Link
          href="/login"
          className="flex items-center justify-center w-full px-4 py-2 text-xs font-semibold text-slate-400 bg-slate-800 hover:bg-slate-700 hover:text-slate-200 rounded-md transition-colors"
        >
          Go to Login Screen
        </Link>
      </div>
    </aside>
  );
}
