// src/pages/RoleSelection.jsx

import { useNavigate } from "react-router-dom";
import { ArrowRight, Building2, HeartHandshake, Moon } from "lucide-react";

export default function RoleSelection() {
  const navigate = useNavigate();

  const handleMunicipalClick = () => {
    navigate("/admin-splash");
  };

  const handleNgoClick = () => {
    navigate("/ngo-splash");
  };

  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center overflow-hidden bg-gradient-to-br from-emerald-950 via-emerald-950 to-slate-950 p-4 sm:p-5 lg:p-6">
      {/* Lattice pattern */}
      <div
        className="pointer-events-none absolute inset-0 bg-[linear-gradient(to_right,rgba(255,255,255,0.04)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.04)_1px,transparent_1px)] bg-[size:32px_32px]"
        aria-hidden="true"
      />

      {/* Ambient glow */}
      <div
        className="pointer-events-none absolute -left-24 -top-32 h-96 w-96 rounded-full bg-emerald-500/20 blur-3xl"
        aria-hidden="true"
      />
      <div
        className="pointer-events-none absolute -bottom-32 -right-24 h-80 w-80 rounded-full bg-amber-400/10 blur-3xl"
        aria-hidden="true"
      />
      <Moon
        className="pointer-events-none absolute right-8 top-8 h-32 w-32 text-white/5 sm:h-44 sm:w-44"
        aria-hidden="true"
      />

      <div className="relative flex w-full max-w-3xl flex-col items-center">
        {/* Logo */}
        <div className="relative mb-5 flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-emerald-400 to-teal-500 shadow-lg shadow-emerald-500/20 ring-1 ring-white/20">
          <Moon className="h-6 w-6 text-white" aria-hidden="true" />
          <span
            className="absolute -right-0.5 -top-0.5 h-2.5 w-2.5 rounded-full bg-amber-400 ring-2 ring-emerald-950"
            aria-hidden="true"
          />
        </div>

        <h1 className="text-center text-3xl font-semibold tracking-tight text-white">
          EidClean
        </h1>
        <p className="mb-8 mt-2 text-center text-sm text-emerald-100/60 sm:mb-10 lg:mb-12">
          Abbottabad · Eid-ul-Adha Waste Management System
        </p>

        {/* Cards */}
        <div className="grid w-full grid-cols-1 gap-4 sm:gap-5 md:grid-cols-2 lg:gap-6">
          {/* Municipal Admin Card */}
          <div
            onClick={handleMunicipalClick}
            className="group relative cursor-pointer overflow-hidden rounded-2xl bg-white/5 p-5 ring-1 ring-white/10 backdrop-blur transition-all duration-200 hover:-translate-y-0.5 hover:bg-emerald-400/10 hover:ring-emerald-300/30 sm:p-6"
          >
            <div
              className="pointer-events-none absolute -right-16 -top-20 h-48 w-48 rounded-full bg-emerald-400/10 blur-3xl transition-opacity duration-200 group-hover:bg-emerald-400/20"
              aria-hidden="true"
            />
            <div className="relative">
              <div className="mb-5 flex h-11 w-11 items-center justify-center rounded-xl bg-emerald-400/15 text-emerald-300 ring-1 ring-emerald-300/20">
                <Building2 className="h-5 w-5" aria-hidden="true" />
              </div>
              <h2 className="mb-2 text-lg font-semibold tracking-tight text-white">
                Municipal Admin
              </h2>
              <p className="mb-4 text-sm leading-relaxed text-emerald-50/60">
                Manage waste pickups, track drivers, and plan resources for Abbottabad.
              </p>
              <div className="mb-5 inline-flex items-center gap-1.5 text-sm font-semibold text-emerald-300">
                Continue as Municipal Admin
                <ArrowRight
                  className="h-4 w-4 transition-transform duration-150 group-hover:translate-x-0.5"
                  aria-hidden="true"
                />
              </div>
              <div className="flex gap-7 border-t border-white/10 pt-4">
                <div>
                  <div className="text-lg font-semibold tabular-nums tracking-tight text-emerald-300">145</div>
                  <div className="text-xs text-emerald-100/50">Pickups</div>
                </div>
                <div>
                  <div className="text-lg font-semibold tabular-nums tracking-tight text-emerald-300">23</div>
                  <div className="text-xs text-emerald-100/50">Drivers</div>
                </div>
                <div>
                  <div className="text-lg font-semibold tabular-nums tracking-tight text-emerald-300">89%</div>
                  <div className="text-xs text-emerald-100/50">On-Time</div>
                </div>
              </div>
            </div>
          </div>

          {/* NGO Admin Card */}
          <div
            onClick={handleNgoClick}
            className="group relative cursor-pointer overflow-hidden rounded-2xl bg-white/5 p-5 ring-1 ring-white/10 backdrop-blur transition-all duration-200 hover:-translate-y-0.5 hover:bg-amber-400/10 hover:ring-amber-300/30 sm:p-6"
          >
            <div
              className="pointer-events-none absolute -right-16 -top-20 h-48 w-48 rounded-full bg-amber-400/10 blur-3xl transition-opacity duration-200 group-hover:bg-amber-400/20"
              aria-hidden="true"
            />
            <div className="relative">
              <div className="mb-5 flex h-11 w-11 items-center justify-center rounded-xl bg-amber-400/15 text-amber-300 ring-1 ring-amber-300/20">
                <HeartHandshake className="h-5 w-5" aria-hidden="true" />
              </div>
              <h2 className="mb-2 text-lg font-semibold tracking-tight text-white">
                NGO Admin
              </h2>
              <p className="mb-4 text-sm leading-relaxed text-emerald-50/60">
                Manage meat donations, coordinate pickups, and distribute to families in need.
              </p>
              <div className="mb-5 inline-flex items-center gap-1.5 text-sm font-semibold text-amber-300">
                Continue as NGO Admin
                <ArrowRight
                  className="h-4 w-4 transition-transform duration-150 group-hover:translate-x-0.5"
                  aria-hidden="true"
                />
              </div>
              <div className="flex gap-7 border-t border-white/10 pt-4">
                <div>
                  <div className="text-lg font-semibold tabular-nums tracking-tight text-amber-300">2.5K</div>
                  <div className="text-xs text-emerald-100/50">Meat kg</div>
                </div>
                <div>
                  <div className="text-lg font-semibold tabular-nums tracking-tight text-amber-300">180</div>
                  <div className="text-xs text-emerald-100/50">Donations</div>
                </div>
                <div>
                  <div className="text-lg font-semibold tabular-nums tracking-tight text-amber-300">450</div>
                  <div className="text-xs text-emerald-100/50">Families</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <footer className="mt-8 text-center text-xs text-emerald-100/40 sm:mt-10 lg:mt-12">
          © 2026 EidClean · Abbottabad Municipal Corporation
        </footer>
      </div>
    </div>
  );
}