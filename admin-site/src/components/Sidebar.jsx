// 📁 src/components/Sidebar.jsx (Minimal - Guaranteed Working)

import { NavLink } from "react-router-dom";
import { signOut } from "firebase/auth";
import { auth } from "../firebase";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

const adminLinks = [
  { to: "/dashboard", icon: "📊", label: "Dashboard" },
  { to: "/reports", icon: "📋", label: "Pickup Requests" },
  { to: "/drivers", icon: "🚛", label: "Drivers" },
  { to: "/analytics", icon: "📈", label: "Analytics" },
  { to: "/settings", icon: "⚙️", label: "Settings" },
  { to: "/profile", icon: "👤", label: "Profile" },
];

const ngoLinks = [
  { to: "/dashboard", icon: "📊", label: "Dashboard" },
  { to: "/donations", icon: "🤲", label: "Donation Requests" },
  { to: "/areas", icon: "🗺️", label: "Hotspot Areas" },
  { to: "/settings", icon: "⚙️", label: "Settings" },
  { to: "/profile", icon: "👤", label: "Profile" },
];

export default function Sidebar() {
  const navigate = useNavigate();
  const { user, userRole } = useAuth();

  const links = userRole === "ngo" ? ngoLinks : adminLinks;

  async function handleLogout() {
    await signOut(auth);
    navigate("/");
  }

  return (
    <div className="w-64 bg-white h-screen shadow-sm flex flex-col fixed left-0 top-0 z-10">

      {/* Brand */}
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-emerald-500 rounded-xl flex items-center justify-center">
            <span className="text-white text-lg">🌿</span>
          </div>
          <div>
            <h1 className="font-bold text-gray-800">EidClean</h1>
            <p className="text-xs text-gray-400">Municipal Portal</p>
          </div>
        </div>
      </div>

      {/* Nav Links */}
      <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
        {links.map((link) => (
          <NavLink
            key={link.to + link.label}
            to={link.to}
            end={link.to === "/dashboard"}
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium transition-colors ${
                isActive
                  ? "bg-emerald-500 text-white"
                  : "text-gray-600 hover:bg-gray-100"
              }`
            }
          >
            <span className="text-base">{link.icon}</span>
            {link.label}
          </NavLink>
        ))}
      </nav>

      {/* User Info + Logout */}
      <div className="p-4 border-t border-gray-200">
        <div className="flex items-center gap-3 px-3 py-2 mb-3 bg-gray-50 rounded-xl">
          <div className="w-9 h-9 bg-emerald-500 rounded-full flex items-center justify-center text-white font-semibold text-sm">
            {user?.email?.charAt(0).toUpperCase() || "H"}
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-gray-800 truncate">
              {user?.displayName || "Admin"}
            </p>
            <p className="text-xs text-gray-400 capitalize">
              {userRole || "Administrator"}
            </p>
          </div>
        </div>
        <button
          onClick={handleLogout}
          className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-sm font-medium text-red-500 hover:bg-red-50 transition-colors"
        >
          <span>🚪</span>
          Logout
        </button>
      </div>
    </div>
  );
}