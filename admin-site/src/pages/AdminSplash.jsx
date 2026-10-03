// src/pages/AdminSplash.jsx

import { useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { CircleHelp, MapPin, Moon, Recycle } from "lucide-react";

export default function AdminSplash() {
  const navigate = useNavigate();
  const progressRef = useRef(null);

  useEffect(() => {
    // Animate progress bar
    let progress = 0;
    const interval = setInterval(() => {
      progress += 2;
      if (progress >= 62) {
        clearInterval(interval);
      }
      if (progressRef.current) {
        progressRef.current.style.width = Math.min(progress, 62) + "%";
      }
    }, 30);

    // Navigate to login after 3 seconds
    const timer = setTimeout(() => {
      navigate("/admin-login");
    }, 3000);

    return () => {
      clearInterval(interval);
      clearTimeout(timer);
    };
  }, [navigate]);

  // Generate pattern icons
  const icons = [
    '<path d="M7 19H4.815a1.83 1.83 0 0 1-1.57-.881 1.785 1.785 0 0 1-.004-1.784L7.196 9.5"></path><path d="M11 19h8.203a1.83 1.83 0 0 0 1.556-.89 1.784 1.784 0 0 0 0-1.775l-1.226-2.12"></path><path d="m14 16-3 3 3 3"></path><path d="M8.293 13.596 7.196 9.5 3.1 10.598"></path><path d="m9.344 5.811 1.093-1.892A1.83 1.83 0 0 1 12 3a1.784 1.784 0 0 1 1.545.888l3.943 6.843"></path><path d="m13.378 9.633 4.096 1.098 1.097-4.096"></path>'
  ];

  const positions = [
    [8, 22], [16, 60], [30, 10], [42, 48], [58, 7], [68, 28], [80, 14], [92, 52],
    [6, 72], [18, 88], [34, 68], [48, 82], [62, 90], [76, 72], [88, 86], [96, 40],
    [2, 45], [24, 35], [52, 58], [70, 50]
  ];

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-gradient-to-br from-emerald-950 via-emerald-900 to-slate-950 p-4 sm:p-5 lg:p-6">
      {/* Lattice pattern */}
      <div
        className="pointer-events-none absolute inset-0 bg-[linear-gradient(to_right,rgba(255,255,255,0.04)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.04)_1px,transparent_1px)] bg-[size:32px_32px]"
        aria-hidden="true"
      />

      {/* Ambient glow */}
      <div
        className="pointer-events-none absolute left-1/2 top-1/2 h-[520px] w-[520px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-emerald-500/20 blur-3xl"
        aria-hidden="true"
      />
      <div
        className="pointer-events-none absolute -bottom-32 -right-24 h-80 w-80 rounded-full bg-amber-400/10 blur-3xl"
        aria-hidden="true"
      />

      {/* Pattern Overlay */}
      <div className="pointer-events-none absolute inset-0 opacity-[0.07]" aria-hidden="true">
        {positions.map(([x, y], index) => (
          <div
            key={index}
            className="absolute h-9 w-9"
            style={{ left: x + "%", top: y + "%" }}
          >
            <Recycle className="h-full w-full text-white" strokeWidth={1.5} />
          </div>
        ))}
      </div>

      {/* Content */}
      <div className="relative z-10 flex flex-col items-center text-center">
        {/* Logo */}
        <div className="relative mb-7">
          <div className="flex h-24 w-24 items-center justify-center rounded-2xl bg-gradient-to-br from-emerald-400 to-teal-500 shadow-lg shadow-emerald-500/20 ring-1 ring-white/25 sm:h-[100px] sm:w-[100px]">
            <div className="flex h-14 w-14 items-center justify-center rounded-xl bg-emerald-950/30 ring-1 ring-white/20 backdrop-blur sm:h-[60px] sm:w-[60px]">
              <Moon className="h-7 w-7 text-white sm:h-[30px] sm:w-[30px]" aria-hidden="true" />
            </div>
          </div>
          {/* Badge */}
          <div className="absolute -bottom-1.5 -right-5 flex h-10 w-10 items-center justify-center rounded-xl bg-amber-400 shadow-lg shadow-black/25 ring-2 ring-emerald-950 sm:h-[42px] sm:w-[42px]">
            <Recycle className="h-5 w-5 text-emerald-950" aria-hidden="true" />
          </div>
        </div>

        <span className="mb-4 inline-flex items-center gap-1.5 rounded-full bg-white/10 px-3 py-1 text-xs font-medium text-emerald-50 ring-1 ring-white/15 backdrop-blur">
          <MapPin className="h-3.5 w-3.5 text-amber-300" aria-hidden="true" />
          Abbottabad, Khyber Pakhtunkhwa
        </span>

        <h1 className="text-4xl font-semibold tracking-tight text-white">EidClean</h1>
        <p className="mb-8 mt-2 text-base font-medium text-emerald-50/80 sm:text-[17px]">
          Municipal Waste Management Portal
        </p>

        {/* Progress Bar */}
        <div className="mb-3.5 h-1 w-[200px] overflow-hidden rounded-full bg-white/15 ring-1 ring-white/10">
          <div
            ref={progressRef}
            className="h-full rounded-full bg-gradient-to-r from-emerald-300 to-amber-300 transition-all duration-300"
            style={{ width: "0%" }}
          ></div>
        </div>
        <p className="text-xs font-medium text-emerald-100/70">Loading system...</p>
      </div>

      {/* Footer */}
      <footer className="absolute bottom-5 left-0 right-0 px-4 text-center text-xs text-white/35 sm:bottom-7">
        Eid-ul-Adha Waste Management System
      </footer>

      {/* Help Button */}
      <div className="absolute bottom-4 right-4 flex h-8 w-8 items-center justify-center rounded-full bg-white/10 text-white/80 ring-1 ring-white/15 backdrop-blur sm:bottom-5 sm:right-5">
        <CircleHelp className="h-4 w-4" aria-hidden="true" />
      </div>
    </div>
  );
}