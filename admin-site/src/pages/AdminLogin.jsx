// 📁 src/pages/AdminLogin.jsx

import { useState, useEffect } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "../firebase";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function AdminLogin() {
  const [email, setEmail] = useState("admin@eidclean.com");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [loginSuccess, setLoginSuccess] = useState(false);
  const navigate = useNavigate();
  const { user, userRole, loading: authLoading } = useAuth();

  // ✅ NEW: Watch for role change after login
  useEffect(() => {
    if (loginSuccess && !authLoading) {
      console.log("🔍 Checking role for navigation:", userRole);
      if (userRole === "admin") {
        navigate("/dashboard", { replace: true });
      } else if (userRole === "ngo") {
        navigate("/ngo-dashboard", { replace: true });
      } else if (user) {
        // If user exists but no role, wait a bit more
        console.log("⏳ No role yet, waiting...");
      } else {
        navigate("/", { replace: true });
      }
    }
  }, [loginSuccess, userRole, authLoading, navigate, user]);

  async function handleLogin(e) {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      await signInWithEmailAndPassword(auth, email, password);
      console.log("✅ Sign in successful");
      setLoginSuccess(true); // ✅ Triggers the useEffect above
    } catch (err) {
      console.error("❌ Login error:", err);
      setError("Invalid email or password. Please try again.");
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="w-full max-w-5xl grid md:grid-cols-2 gap-8 bg-white rounded-3xl shadow-lg overflow-hidden">
        
        {/* Left Side - Branding */}
        <div className="bg-emerald-600 p-8 md:p-12 flex flex-col justify-between min-h-[400px]">
          <div>
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
                <span className="text-white text-xl">🌿</span>
              </div>
              <span className="text-white font-bold text-lg">EidClean</span>
            </div>
            <h2 className="text-white text-2xl font-bold mb-2">
              Municipal Portal
            </h2>
            <h3 className="text-white/90 text-lg font-semibold mb-3">
              Abbottabad Waste Management
            </h3>
            <p className="text-white/70 text-sm leading-relaxed">
              Khyber Pakhtunkhwa's smart Qurbani waste management system — keeping Abbottabad clean during Eid ul Adha.
            </p>
          </div>

          <div className="space-y-2 mt-6">
            <div className="flex items-center gap-2 text-white/80 text-sm">
              <span className="text-emerald-300">✓</span> Real-time pickup tracking
            </div>
            <div className="flex items-center gap-2 text-white/80 text-sm">
              <span className="text-emerald-300">✓</span> AI-powered resource planning
            </div>
            <div className="flex items-center gap-2 text-white/80 text-sm">
              <span className="text-emerald-300">✓</span> Driver performance monitoring
            </div>
            <div className="flex items-center gap-2 text-white/80 text-sm">
              <span className="text-emerald-300">✓</span> Area-wise analytics & reports
            </div>
          </div>

          <div className="mt-6">
            <p className="text-white/40 text-xs">
              Eid-ul-Adha Waste Management System
              <br />
              Abbottabad Municipal Corporation
            </p>
          </div>
        </div>

        {/* Right Side - Login Form */}
        <div className="p-8 md:p-12 flex flex-col justify-center">
          <div className="mb-8">
            <h2 className="text-2xl font-bold text-gray-800">Welcome back</h2>
            <p className="text-gray-500 text-sm">Sign in to your admin account</p>
          </div>

          <form onSubmit={handleLogin} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email Address
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@abbottabad.gov.pk"
                required
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-gray-800"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Password
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                required
                className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-transparent text-gray-800"
              />
            </div>

            <div className="flex items-center justify-between">
              <a href="#" className="text-sm text-emerald-600 hover:text-emerald-700 font-medium">
                Forgot password?
              </a>
            </div>

            {error && (
              <div className="bg-red-50 text-red-600 px-4 py-3 rounded-xl text-sm">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-semibold py-3 rounded-xl transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <span className="inline-block w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                  Signing in...
                </>
              ) : (
                "Sign In →"
              )}
            </button>

            <p className="text-center text-xs text-gray-400 mt-4">
              For admin access, contact <span className="text-emerald-600 font-medium">IT Support</span>
            </p>
          </form>
        </div>
      </div>
    </div>
  );
}