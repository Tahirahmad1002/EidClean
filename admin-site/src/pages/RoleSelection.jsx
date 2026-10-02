// 📁 src/pages/RoleSelection.jsx

import { useNavigate } from "react-router-dom";

export default function RoleSelection() {
  const navigate = useNavigate();

  const handleMunicipalClick = () => {
    navigate("/admin-splash");
  };

  const handleNgoClick = () => {
    navigate("/ngo-splash");
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-6 relative overflow-hidden"
  style={{
    background: `
      radial-gradient(ellipse 600px 500px at 25% 30%, #0d5c3e, transparent 55%),
      radial-gradient(ellipse 600px 500px at 75% 70%, #1a56db, transparent 55%),
      linear-gradient(135deg, #0d5c3e 0%, #0d5c3e 30%, #1a56db 70%, #1a56db 100%)
    `
  }}

    >
      {/* Logo */}
      <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-purple-500 to-purple-900 flex items-center justify-center mb-5">
        <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-7 h-7">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
        </svg>
      </div>

      <h1 className="text-3xl font-bold text-white text-center mb-2">
        EidClean
      </h1>
      <p className="text-gray-400 text-sm text-center mb-12">
        Abbottabad · Eid-ul-Adha Waste Management System
      </p>

      {/* Cards */}
      <div className="flex flex-wrap gap-6 justify-center max-w-2xl">
        
        {/* Municipal Admin Card */}
        <div
          onClick={handleMunicipalClick}
          className="w-80 rounded-2xl p-7 border border-[#23271f] bg-[#12140f] cursor-pointer transition-all duration-300 hover:bg-[rgba(16,74,46,0.35)] hover:border-[rgba(34,197,94,0.35)] group"
        >
          <div className="w-11 h-11 rounded-xl bg-green-600 flex items-center justify-center mb-5">
            <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-5.5 h-5.5">
              <rect x="4" y="2" width="16" height="20" rx="2"></rect>
              <line x1="9" y1="6" x2="9" y2="6"></line>
              <line x1="15" y1="6" x2="15" y2="6"></line>
              <line x1="9" y1="10" x2="9" y2="10"></line>
              <line x1="15" y1="10" x2="15" y2="10"></line>
              <line x1="9" y1="14" x2="9" y2="14"></line>
              <line x1="15" y1="14" x2="15" y2="14"></line>
              <line x1="9" y1="18" x2="15" y2="18"></line>
            </svg>
          </div>
          <h2 className="text-lg font-bold text-white mb-2.5">Municipal Admin</h2>
          <p className="text-[13.5px] leading-relaxed text-[#a3a8b0] mb-4">
            Manage waste pickups, track drivers, and plan resources for Abbottabad.
          </p>
          <div className="text-green-400 font-semibold text-sm inline-flex items-center gap-1.5 mb-5">
            Continue as Municipal Admin →
          </div>
          <div className="border-t border-white/10 pt-4 flex gap-7">
            <div>
              <div className="text-lg font-bold text-green-400">145</div>
              <div className="text-[11.5px] text-[#8b9096]">Pickups</div>
            </div>
            <div>
              <div className="text-lg font-bold text-green-400">23</div>
              <div className="text-[11.5px] text-[#8b9096]">Drivers</div>
            </div>
            <div>
              <div className="text-lg font-bold text-green-400">89%</div>
              <div className="text-[11.5px] text-[#8b9096]">On-Time</div>
            </div>
          </div>
        </div>

        {/* NGO Admin Card */}
        <div
          onClick={handleNgoClick}
          className="w-80 rounded-2xl p-7 border border-[#23271f] bg-[#12140f] cursor-pointer transition-all duration-300 hover:bg-[rgba(30,58,138,0.3)] hover:border-[rgba(96,165,250,0.35)] group"
        >
          <div className="w-11 h-11 rounded-xl bg-blue-800 flex items-center justify-center mb-5">
            <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-5.5 h-5.5">
              <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"></path>
            </svg>
          </div>
          <h2 className="text-lg font-bold text-white mb-2.5">NGO Admin</h2>
          <p className="text-[13.5px] leading-relaxed text-[#a3a8b0] mb-4">
            Manage meat donations, coordinate pickups, and distribute to families in need.
          </p>
          <div className="text-blue-400 font-semibold text-sm inline-flex items-center gap-1.5 mb-5">
            Continue as NGO Admin →
          </div>
          <div className="border-t border-[#2a2d36] pt-4 flex gap-7">
            <div>
              <div className="text-lg font-bold text-blue-400">2.5K</div>
              <div className="text-[11.5px] text-[#8b9096]">Meat kg</div>
            </div>
            <div>
              <div className="text-lg font-bold text-blue-400">180</div>
              <div className="text-[11.5px] text-[#8b9096]">Donations</div>
            </div>
            <div>
              <div className="text-lg font-bold text-blue-400">450</div>
              <div className="text-[11.5px] text-[#8b9096]">Families</div>
            </div>
          </div>
        </div>

      </div>

      {/* Footer */}
      <footer className="mt-12 text-[12.5px] text-[#5c6067] text-center">
        © 2026 EidClean · Abbottabad Municipal Corporation
      </footer>
    </div>
  );
}