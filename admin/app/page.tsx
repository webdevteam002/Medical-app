import Sidebar from "@/components/Sidebar";

const statCards = [
  { name: "Total Students", value: "--", note: "Provisional placeholder" },
  { name: "Active Subscriptions", value: "--", note: "Provisional placeholder" },
  { name: "Study Materials", value: "--", note: "Provisional placeholder" },
  { name: "QBank Exams", value: "--", note: "Provisional placeholder" },
];

export default function DashboardPage() {
  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 flex flex-col min-w-0">
        <header className="bg-white border-b border-slate-200 px-6 sm:px-8 py-5 flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-slate-900">Dashboard</h1>
            <p className="text-xs text-slate-500 mt-0.5">Overview of platform metrics and administration</p>
          </div>
          <span className="text-xs font-medium bg-teal-50 text-teal-700 px-3 py-1 rounded-full border border-teal-200">
            Day 8 Auth Guard Active
          </span>
        </header>

        <div className="p-6 sm:p-8 max-w-6xl space-y-6">
          {/* Stat Cards Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {statCards.map((stat) => (
              <div
                key={stat.name}
                className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm flex flex-col justify-between"
              >
                <div>
                  <p className="text-xs font-semibold uppercase tracking-wider text-slate-500">
                    {stat.name}
                  </p>
                  <p className="text-2xl font-bold text-slate-900 mt-2">{stat.value}</p>
                </div>
                <p className="text-xs text-slate-400 mt-3 pt-2 border-t border-slate-100">
                  {stat.note}
                </p>
              </div>
            ))}
          </div>

          {/* Core Shell Information Panel */}
          <div className="bg-white rounded-xl border border-slate-200 p-6 sm:p-8 shadow-sm">
            <h2 className="text-lg font-semibold text-slate-900 mb-2">
              MedStudy Control Center Shell
            </h2>
            <p className="text-sm text-slate-600 mb-6 leading-relaxed">
              Protected administration panel. Route access is enforced by Day 8 authentication middleware.
            </p>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-5 rounded-lg bg-slate-50 border border-slate-200">
                <h3 className="text-sm font-semibold text-slate-800 mb-1">
                  Protected Navigation
                </h3>
                <p className="text-xs text-slate-500 leading-normal">
                  Unauthenticated requests to protected routes (/dashboard, /users, /content, /exams, /subscriptions) are automatically redirected to /login.
                </p>
              </div>

              <div className="p-5 rounded-lg bg-slate-50 border border-slate-200">
                <h3 className="text-sm font-semibold text-slate-800 mb-1">
                  Security Architecture
                </h3>
                <p className="text-xs text-slate-500 leading-normal">
                  Authentication tokens are maintained in SameSite cookies. Clear session or tap Sign Out to test route protection.
                </p>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
