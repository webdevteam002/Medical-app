import Sidebar from "@/components/Sidebar";

export default function UsersPlaceholderPage() {
  return (
    <div className="flex min-h-screen bg-slate-50">
      <Sidebar />
      <main className="flex-1 flex flex-col min-w-0">
        <header className="bg-white border-b border-slate-200 px-8 py-5 flex items-center justify-between">
          <h1 className="text-xl font-bold text-slate-900">User Management</h1>
          <span className="text-xs font-medium bg-slate-100 text-slate-600 px-3 py-1 rounded-full border border-slate-200">
            Placeholder
          </span>
        </header>
        <div className="p-8 max-w-5xl">
          <div className="bg-white rounded-xl border border-slate-200 p-8 shadow-sm text-center">
            <h2 className="text-lg font-semibold text-slate-900 mb-2">User Management</h2>
            <p className="text-sm text-slate-500">
              User listing, device reset, and user moderation features will be wired in later days per the roadmap.
            </p>
          </div>
        </div>
      </main>
    </div>
  );
}
