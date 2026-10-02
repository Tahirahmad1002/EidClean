// 📁 src/pages/AdminSplash.jsx

import { useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";

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
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden"
      style={{
        background: `
          radial-gradient(ellipse 900px 700px at 50% 45%, #16a34a 0%, #0f7a38 45%, #0a5c2b 75%, #063f1e 100%)
        `
      }}
    >
      {/* Pattern Overlay */}
      <div className="absolute inset-0 pointer-events-none opacity-10">
        {positions.map(([x, y], index) => (
          <div
            key={index}
            className="absolute w-9 h-9"
            style={{ left: x + '%', top: y + '%' }}
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.5">
              <path d="M7 19H4.815a1.83 1.83 0 0 1-1.57-.881 1.785 1.785 0 0 1-.004-1.784L7.196 9.5"></path>
              <path d="M11 19h8.203a1.83 1.83 0 0 0 1.556-.89 1.784 1.784 0 0 0 0-1.775l-1.226-2.12"></path>
              <path d="m14 16-3 3 3 3"></path>
              <path d="M8.293 13.596 7.196 9.5 3.1 10.598"></path>
              <path d="m9.344 5.811 1.093-1.892A1.83 1.83 0 0 1 12 3a1.784 1.784 0 0 1 1.545.888l3.943 6.843"></path>
              <path d="m13.378 9.633 4.096 1.098 1.097-4.096"></path>
            </svg>
          </div>
        ))}
      </div>

      {/* Content */}
      <div className="relative z-10 flex flex-col items-center text-center">
        {/* Logo */}
        <div className="relative mb-7">
          <div className="w-[100px] h-[100px] rounded-2xl bg-gradient-to-br from-[#34a853] to-[#1a7a3e] flex items-center justify-center shadow-[0_10px_30px_rgba(0,0,0,0.25)]">
            <div className="w-[60px] h-[60px] rounded-xl bg-gradient-to-br from-[#9d5ce8] to-[#5b21b6] flex items-center justify-center">
              <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-[30px] h-[30px]">
                <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
              </svg>
            </div>
          </div>
          {/* Badge */}
          <div className="absolute -right-[22px] -bottom-[6px] w-[42px] h-[42px] rounded-xl bg-[#22c55e] flex items-center justify-center shadow-[0_6px_14px_rgba(0,0,0,0.25)]">
            <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-[22px] h-[22px]">
              <path d="M7 19H4.815a1.83 1.83 0 0 1-1.57-.881 1.785 1.785 0 0 1-.004-1.784L7.196 9.5"></path>
              <path d="M11 19h8.203a1.83 1.83 0 0 0 1.556-.89 1.784 1.784 0 0 0 0-1.775l-1.226-2.12"></path>
              <path d="m14 16-3 3 3 3"></path>
              <path d="M8.293 13.596 7.196 9.5 3.1 10.598"></path>
              <path d="m9.344 5.811 1.093-1.892A1.83 1.83 0 0 1 12 3a1.784 1.784 0 0 1 1.545.888l3.943 6.843"></path>
              <path d="m13.378 9.633 4.096 1.098 1.097-4.096"></path>
            </svg>
          </div>
        </div>

        <h1 className="text-4xl font-bold text-white mb-3">EidClean</h1>
        <p className="text-[17px] font-medium text-[#e8f5ec] mb-1.5">
          Municipal Waste Management Portal
        </p>
        <p className="text-[13px] text-[#bfe8cd] mb-[34px]">
          Abbottabad, Khyber Pakhtunkhwa
        </p>

        {/* Progress Bar */}
        <div className="w-[200px] h-1 rounded-full bg-white/25 overflow-hidden mb-[14px]">
          <div
            ref={progressRef}
            className="h-full bg-white rounded-full transition-all duration-300"
            style={{ width: '0%' }}
          ></div>
        </div>
        <p className="text-[12.5px] text-[#cfeed9]">Loading system...</p>
      </div>

      {/* Footer */}
      <footer className="absolute bottom-7 left-0 right-0 text-center text-[11.5px] text-white/35">
        Eid-ul-Adha Waste Management System
      </footer>

      {/* Help Button */}
      <div className="absolute right-5 bottom-5 w-8 h-8 rounded-full bg-black/45 flex items-center justify-center text-white font-semibold text-sm">
        ?
      </div>
    </div>
  );
}