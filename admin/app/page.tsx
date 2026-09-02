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
            Day 5 Admin Shell
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
              This dashboard shell establishes the responsive visual and navigation foundation for Person 2&apos;s Next.js admin application.
            </p>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-5 rounded-lg bg-slate-50 border border-slate-200">
                <h3 className="text-sm font-semibold text-slate-800 mb-1">
                  Sidebar Navigation
                </h3>
                <p className="text-xs text-slate-500 leading-normal">
                  Navigation sections for Dashboard, Users, Content, Exams, and Subscriptions are active in the UI layout with active route highlighting.
                </p>
              </div>

              <div className="p-5 rounded-lg bg-slate-50 border border-slate-200">
                <h3 className="text-sm font-semibold text-slate-800 mb-1">
                  Scope Notice
                </h3>
                <p className="text-xs text-slate-500 leading-normal">
                  Live backend API integration, user management tables, PDF uploads, and exam builders are scheduled for later days per the roadmap.
                </p>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
