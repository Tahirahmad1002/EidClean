// src/components/NGOSidebar.jsx

import { useEffect, useState } from "react";
import { NavLink, useNavigate } from "react-router-dom";
import {
  ArrowRight,
  Building2,
  HeartHandshake,
  History,
  LayoutDashboard,
  Leaf,
  LogOut,
  Menu,
  Moon,
  PackageCheck,
  X,
} from "lucide-react";
import { cn } from "../lib/utils";
import { Button } from "./ui";

// Pending count is static for now (Firebase later)
const ngoLinks = [
  { to: "/ngo-dashboard", icon: LayoutDashboard, label: "Dashboard" },
  { to: "/ngo-donations", icon: HeartHandshake, label: "Donation Requests", badge: 4 },
  { to: "/ngo-pickups", icon: PackageCheck, label: "Accepted Pickups" },
  { to: "/ngo-history", icon: History, label: "History" },
  { to: "/ngo-profile", icon: Building2, label: "NGO Profile" },
];

function readNgoUser() {
  try {
    return JSON.parse(localStorage.getItem("ngoUser") || "null");
  } catch {
    return null;
  }
}

export default function NGOSidebar() {
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [ngoUser] = useState(readNgoUser);

  // Dummy NGO session guard (same check the old NGODashboard used)
  useEffect(() => {
    if (!ngoUser) navigate("/ngo-login", { replace: true });
  }, [ngoUser, navigate]);

  // Mobile drawer: close on Escape / when resized to desktop, lock page scroll while open
  useEffect(() => {
    if (!open) return undefined;
    const onKey = (e) => e.key === "Escape" && setOpen(false);
    const onResize = () => window.innerWidth >= 1024 && setOpen(false);
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    document.addEventListener("keydown", onKey);
    window.addEventListener("resize", onResize);
    return () => {
      document.body.style.overflow = previousOverflow;
      document.removeEventListener("keydown", onKey);
      window.removeEventListener("resize", onResize);
    };
  }, [open]);

  function handleLogout() {
    localStorage.removeItem("ngoUser");
    navigate("/");
  }

  const links = ngoLinks;

  return (
    <>
      {/* Mobile top bar */}
      <header className="fixed inset-x-0 top-0 z-30 flex h-14 items-center gap-3 bg-[linear-gradient(90deg,#064e3b_0%,#022c22_100%)] px-4 shadow-lg shadow-emerald-950/20 ring-1 ring-white/5 lg:hidden">
        <button
          type="button"
          onClick={() => setOpen(true)}
          aria-label="Open navigation"
          aria-expanded={open}
          className="flex h-9 w-9 items-center justify-center rounded-lg bg-white/[0.08] text-emerald-50 ring-1 ring-white/10 transition-colors duration-150 hover:bg-white/15 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-300/50"
        >
          <Menu className="h-[18px] w-[18px]" aria-hidden="true" />
        </button>
        <div className="flex items-center gap-2.5">
          <div className="relative flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-emerald-300 via-emerald-500 to-teal-600 ring-1 ring-white/30">
            <Leaf className="h-4 w-4 text-white" aria-hidden="true" />
            <span className="absolute -right-0.5 -top-0.5 h-2 w-2 rounded-full bg-amber-300 ring-2 ring-emerald-950" aria-hidden="true" />
          </div>
          <div className="leading-tight">
            <p className="text-sm font-semibold tracking-tight text-white">EidClean</p>
            <p className="text-[11px] text-emerald-200/60">NGO Portal</p>
          </div>
        </div>
      </header>

      {/* Mobile backdrop */}
      {open && (
        <div
          className="fixed inset-0 z-40 bg-slate-950/60 backdrop-blur-sm motion-safe:animate-fade-in lg:hidden"
          aria-hidden="true"
          onClick={() => setOpen(false)}
        />
      )}

      <aside
        className={cn(
          "fixed left-0 top-0 z-50 h-screen h-dvh w-64 overflow-hidden bg-[linear-gradient(180deg,#064e3b_0%,#022c22_42%,#04201d_100%)] shadow-[inset_-1px_0_0_rgba(255,255,255,0.06),8px_0_32px_-12px_rgba(2,44,34,0.5)] transition-transform duration-200 ease-out lg:z-10 lg:translate-x-0",
          open ? "translate-x-0" : "-translate-x-full"
        )}
      >
        {/* Layered ambient light */}
        <div
          className="pointer-events-none absolute -left-24 -top-28 h-72 w-72 rounded-full bg-emerald-400/20 blur-3xl"
          aria-hidden="true"
        />
        <div
          className="pointer-events-none absolute -bottom-32 -right-24 h-64 w-64 rounded-full bg-amber-400/10 blur-3xl"
          aria-hidden="true"
        />

        {/* Islamic geometric lattice, fades out toward the bottom */}
        <svg
          className="pointer-events-none absolute inset-x-0 top-0 h-64 w-full text-emerald-100/[0.07] [mask-image:linear-gradient(to_bottom,black,transparent)]"
          aria-hidden="true"
        >
          <defs>
            <pattern id="eidclean-ngo-sidebar-lattice" width="48" height="48" patternUnits="userSpaceOnUse">
              <rect x="14" y="14" width="20" height="20" fill="none" stroke="currentColor" />
              <rect x="14" y="14" width="20" height="20" fill="none" stroke="currentColor" transform="rotate(45 24 24)" />
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#eidclean-ngo-sidebar-lattice)" />
        </svg>

        <div className="relative flex h-full flex-col">
          {/* Brand */}
          <div className="flex h-14 shrink-0 items-center gap-3 px-4">
            <div className="relative flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-300 via-emerald-500 to-teal-600 shadow-lg shadow-emerald-500/30 ring-1 ring-white/30">
              <Leaf className="h-[18px] w-[18px] text-white drop-shadow" aria-hidden="true" />
              <span
                className="absolute -right-1 -top-1 h-2.5 w-2.5 rounded-full bg-amber-300 ring-2 ring-emerald-950"
                aria-hidden="true"
              />
            </div>
            <div className="min-w-0 flex-1 leading-tight">
              <h1 className="text-[15px] font-semibold tracking-tight text-white">EidClean</h1>
              <p className="text-xs text-emerald-200/60">NGO Portal</p>
            </div>
            <button
              type="button"
              onClick={() => setOpen(false)}
              aria-label="Close navigation"
              className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-emerald-100/60 transition-colors duration-150 hover:bg-white/10 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-300/50 lg:hidden"
            >
              <X className="h-4 w-4" aria-hidden="true" />
            </button>
          </div>

          {/* Nav Links (scrolls as a safety net on very short screens) */}
          <nav
            aria-label="NGO navigation"
            className="min-h-0 flex-1 overflow-y-auto px-3 pb-2 pt-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden"
          >
            {/* Quick action */}
            <NavLink
              to="/ngo-donations"
              onClick={() => setOpen(false)}
              className="group mb-3 flex items-center justify-between rounded-xl bg-gradient-to-br from-amber-300 to-amber-400 px-3 py-2 text-[13px] font-semibold text-emerald-950 shadow-lg shadow-amber-500/20 ring-1 ring-amber-200/60 transition-all duration-150 hover:-translate-y-px hover:shadow-amber-400/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-200"
            >
              Review requests
              <span className="flex h-5 w-5 items-center justify-center rounded-md bg-emerald-950/10 transition-transform duration-150 group-hover:translate-x-0.5">
                <ArrowRight className="h-3 w-3" aria-hidden="true" />
              </span>
            </NavLink>

            <p className="mb-1.5 px-3 text-xs font-medium text-emerald-200/45">Workspace</p>
            <div className="space-y-0.5">
              {links.map((link, index) => (
                <div key={link.to}>
                  {index === links.length - 1 && (
                    <div className="my-3 flex items-center gap-3 px-3">
                      <span className="text-xs font-medium text-emerald-200/45">Account</span>
                      <span className="h-px flex-1 bg-gradient-to-r from-white/15 to-transparent" aria-hidden="true" />
                    </div>
                  )}
                  <NavLink
                    to={link.to}
                    end
                    onClick={() => setOpen(false)}
                    className={({ isActive }) =>
                      cn(
                        "group relative flex items-center gap-3 rounded-xl py-1 pl-1 pr-3 text-[13px] font-medium transition-all duration-150 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-emerald-300/50",
                        isActive
                          ? "bg-gradient-to-r from-emerald-400/20 via-emerald-400/10 to-transparent text-white ring-1 ring-inset ring-emerald-300/20"
                          : "text-emerald-50/70 hover:bg-white/[0.06] hover:text-white"
                      )
                    }
                  >
                    {({ isActive }) => (
                      <>
                        {isActive && (
                          <span
                            className="absolute -left-3 top-1/2 h-5 w-1 -translate-y-1/2 rounded-r-full bg-emerald-300 shadow-[0_0_14px_rgba(110,231,183,0.9)]"
                            aria-hidden="true"
                          />
                        )}
                        <span
                          className={cn(
                            "flex h-7 w-7 shrink-0 items-center justify-center rounded-lg transition-all duration-150",
                            isActive
                              ? "bg-gradient-to-br from-emerald-400 to-teal-500 text-white shadow-md shadow-emerald-500/30 ring-1 ring-white/20"
                              : "bg-white/[0.06] text-emerald-200/70 ring-1 ring-white/10 group-hover:bg-white/10 group-hover:text-emerald-100"
                          )}
                        >
                          <link.icon className="h-[15px] w-[15px]" aria-hidden="true" />
                        </span>
                        <span className="flex-1 truncate">{link.label}</span>
                        {link.badge ? (
                          <span className="inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-amber-300 px-1.5 text-[11px] font-semibold tabular-nums text-emerald-950 shadow-[0_0_10px_rgba(252,211,77,0.35)]">
                            {link.badge}
                          </span>
                        ) : (
                          isActive && (
                            <span className="h-1.5 w-1.5 rounded-full bg-amber-300 shadow-[0_0_8px_rgba(252,211,77,0.9)]" aria-hidden="true" />
                          )
                        )}
                      </>
                    )}
                  </NavLink>
                </div>
              ))}
            </div>
          </nav>

          {/* Season card (hidden on short screens to keep the nav fully visible) */}
          <div className="relative mx-3 mb-2 shrink-0 overflow-hidden rounded-xl bg-gradient-to-br from-amber-300/20 via-amber-400/10 to-transparent p-2.5 ring-1 ring-amber-200/20 [@media(max-height:700px)]:hidden">
            <Moon
              className="pointer-events-none absolute -right-2 -top-2 h-14 w-14 text-amber-200/10"
              aria-hidden="true"
            />
            <div className="relative flex items-center gap-2.5">
              <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-amber-300/15 ring-1 ring-amber-200/25">
                <Moon className="h-3.5 w-3.5 text-amber-200" aria-hidden="true" />
              </span>
              <div className="leading-tight">
                <p className="text-[13px] font-semibold text-amber-50">Eid ul Adha</p>
                <p className="mt-0.5 flex items-center gap-1.5 text-[11px] text-emerald-100/60">
                  <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-amber-300" aria-hidden="true" />
                  Donation season
                </p>
              </div>
            </div>
          </div>

          {/* User Info + Logout */}
          <div className="shrink-0 px-3 pb-3">
            <div className="flex items-center gap-2.5 rounded-xl bg-white/[0.06] p-2 ring-1 ring-white/10 transition-colors duration-150 hover:bg-white/10">
              <div className="relative shrink-0">
                <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-gradient-to-br from-emerald-300 to-teal-500 text-sm font-semibold text-emerald-950 ring-2 ring-white/20">
                  {ngoUser?.email?.charAt(0).toUpperCase() || "N"}
                </div>
                <span
                  className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full bg-emerald-400 ring-2 ring-emerald-950"
                  aria-hidden="true"
                />
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-[13px] font-semibold text-white">
                  {ngoUser?.name || "NGO Admin"}
                </p>
                <span className="mt-0.5 inline-flex rounded-full bg-amber-300/15 px-2 py-px text-[11px] font-medium text-amber-200 ring-1 ring-amber-200/20">
                  NGO
                </span>
              </div>
              <Button
                variant="ghost"
                onClick={handleLogout}
                aria-label="Logout"
                title="Logout"
                className="group h-8 w-8 shrink-0 rounded-lg p-0 text-emerald-100/60 hover:bg-red-500/15 hover:text-red-300"
              >
                <LogOut className="h-4 w-4" aria-hidden="true" />
              </Button>
            </div>
          </div>
        </div>
      </aside>
    </>
  );
}