// 📁 src/pages/NGOSplash.jsx

import { useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";

export default function NGOSplash() {
  const navigate = useNavigate();
  const progressRef = useRef(null);

  useEffect(() => {
    // Animate progress bar
    let progress = 0;
    const interval = setInterval(() => {
      progress += 2;
      if (progress >= 100) {
        clearInterval(interval);
      }
      if (progressRef.current) {
        progressRef.current.style.width = Math.min(progress, 100) + "%";
      }
    }, 30);

    // Navigate to login after 3 seconds
    const timer = setTimeout(() => {
      navigate("/ngo-login");
    }, 3000);

    return () => {
      clearInterval(interval);
      clearTimeout(timer);
    };
  }, [navigate]);

  return (
    <div className="min-h-screen flex items-center justify-center relative overflow-hidden"
      style={{
        background: `
          radial-gradient(ellipse 900px 700px at 50% 45%, #1a56db 0%, #1e40af 45%, #1e3a5f 75%, #0f172a 100%)
        `
      }}
    >
      {/* Pattern Overlay */}
      <div className="absolute inset-0 pointer-events-none opacity-10">
        {[...Array(20)].map((_, i) => (
          <div
            key={i}
            className="absolute w-9 h-9"
            style={{
              left: (Math.random() * 90 + 5) + '%',
              top: (Math.random() * 90 + 5) + '%'
            }}
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.5">
              <path d="M12 2L2 7l10 5 10-5-10-5z"/>
              <path d="M2 17l10 5 10-5"/>
              <path d="M2 12l10 5 10-5"/>
            </svg>
          </div>
        ))}
      </div>

      {/* Content */}
      <div className="relative z-10 flex flex-col items-center text-center">
        {/* Logo */}
        <div className="relative mb-7">
          <div className="w-[100px] h-[100px] rounded-2xl bg-gradient-to-br from-[#2563eb] to-[#1d4ed8] flex items-center justify-center shadow-[0_10px_30px_rgba(0,0,0,0.25)]">
            <div className="w-[60px] h-[60px] rounded-xl bg-gradient-to-br from-[#60a5fa] to-[#3b82f6] flex items-center justify-center">
              <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-[30px] h-[30px]">
                <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
              </svg>
            </div>
          </div>
          {/* Badge */}
          <div className="absolute -right-[22px] -bottom-[6px] w-[42px] h-[42px] rounded-xl bg-[#3b82f6] flex items-center justify-center shadow-[0_6px_14px_rgba(0,0,0,0.25)]">
            <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-[22px] h-[22px]">
              <path d="M12 2L2 7l10 5 10-5-10-5z"/>
              <path d="M2 17l10 5 10-5"/>
              <path d="M2 12l10 5 10-5"/>
            </svg>
          </div>
        </div>

        <h1 className="text-4xl font-bold text-white mb-3">EidClean</h1>
        <p className="text-[17px] font-medium text-blue-200 mb-1.5">
          NGO Donation Portal
        </p>
        <p className="text-[13px] text-blue-300 mb-[34px]">
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
        <p className="text-[12.5px] text-blue-200">Loading portal...</p>
      </div>

      {/* Footer */}
      <footer className="absolute bottom-7 left-0 right-0 text-center text-[11.5px] text-white/35">
        Eid-ul-Adha Donation Management
      </footer>
    </div>
  );
}