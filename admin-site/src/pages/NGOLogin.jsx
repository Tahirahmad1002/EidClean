// 📁 src/pages/NGOLogin.jsx

import { useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "../firebase";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function NGOLogin() {
  const [email, setEmail] = useState("memona@edngo.org.pk");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [isRegister, setIsRegister] = useState(false);
  const navigate = useNavigate();
  const { userRole } = useAuth();

  async function handleLogin(e) {
    e.preventDefault();
    setLoading(true);
    setError("");
  try {
      // ✅ DUMMY LOGIN - No Firebase auth
      // Just check if email and password are not empty
      if (email.trim() && password.trim()) {
        console.log("✅ Dummy NGO login successful");
        
        // ✅ Store dummy user info in localStorage (optional)
        localStorage.setItem("ngoUser", JSON.stringify({
          email: email,
          role: "ngo",
          name: "NGO Admin"
        }));
        
        // ✅ Navigate to NGO Dashboard
        navigate("/ngo-dashboard");
      } else {
        setError("Please enter email and password");
      }

    } catch (err) {
      setError("Invalid credentials. Please try again.");
    }
    setLoading(false);
  }
  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-blue-700">
      <div className="w-full max-w-5xl grid md:grid-cols-2 gap-0 bg-white rounded-3xl shadow-2xl overflow-hidden">
        
        {/* Left Side - Branding (Blue Background) */}
        <div className="bg-blue-700 p-8 md:p-12 flex flex-col justify-between min-h-[450px]">
          <div>
            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 bg-white/20 rounded-xl flex items-center justify-center">
                <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" className="w-5 h-5 text-white">
                  <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
                </svg>
              </div>
              <span className="text-white font-bold text-lg">EidClean NGO</span>
            </div>
            
            <h2 className="text-white text-2xl font-bold mb-2">
              Donation Portal
            </h2>
            <h3 className="text-white/90 text-lg font-semibold mb-3">
              Abbottabad
            </h3>
            <p className="text-blue-200 text-sm font-medium mb-2">
              Meat Donation Network
            </p>
            <p className="text-white/70 text-sm leading-relaxed">
              Coordinate Qurbani meat donations, manage pickups, and ensure every family in need is served.
            </p>
          </div>

          <div className="space-y-2 mt-6">
            <div className="flex items-center gap-2 text-white/80 text-sm">
              <span className="text-blue-300">✓</span> Accept & manage donation requests
            </div>
            <div className="flex items-center gap-2 text-white/80 text-sm">
              <span className="text-blue-300">✓</span> Real-time pickup tracking
            </div>
            <div className="flex items-center gap-2 text-white/80 text-sm">
              <span className="text-blue-300">✓</span> Family distribution management
            </div>
            <div className="flex items-center gap-2 text-white/80 text-sm">
              <span className="text-blue-300">✓</span> Impact reports & analytics
            </div>
          </div>

          <div className="mt-6">
            <p className="text-white/40 text-xs">
              Eid-ul-Adha Donation Management
              <br />
              Abbottabad, KPK
            </p>
          </div>
        </div>

        {/* Right Side - Login/Register Form (White Background) */}
        <div className="p-8 md:p-12 flex flex-col justify-center bg-white">
          <div className="mb-6">
            <div className="flex items-center gap-2 mb-2">
              <button
                onClick={() => setIsRegister(false)}
                className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  !isRegister ? "bg-blue-600 text-white" : "text-gray-500 hover:text-gray-700"
                }`}
              >
                Sign In
              </button>
              <button
                onClick={() => setIsRegister(true)}
                className={`px-4 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  isRegister ? "bg-blue-600 text-white" : "text-gray-500 hover:text-gray-700"
                }`}
              >
                Register NGO
              </button>
            </div>
            <h2 className="text-2xl font-bold text-gray-800">
              {isRegister ? "Register NGO" : "Welcome back"}
            </h2>
            <p className="text-gray-500 text-sm">
              {isRegister ? "Create your organization account" : "Sign in to your NGO account"}
            </p>
          </div>

          <form onSubmit={handleLogin} className="space-y-4">
            {isRegister && (
              <div>
                <label className="block text-sm font-medium text-gray-600 mb-1">
                  Your Name
                </label>
                <input
                  type="text"
                  placeholder="Memona Akhtar"
                  className="w-full px-4 py-2.5 rounded-xl bg-gray-50 border border-gray-300 text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                />
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1">
                {isRegister ? "Organization Name" : "Email Address"}
              </label>
              <input
                type={isRegister ? "text" : "email"}
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder={isRegister ? "Edhi Foundation" : "memona@edngo.org.pk"}
                required
                className="w-full px-4 py-2.5 rounded-xl bg-gray-50 border border-gray-300 text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
              />
            </div>

            {isRegister && (
              <div>
                <label className="block text-sm font-medium text-gray-600 mb-1">
                  Phone
                </label>
                <input
                  type="text"
                  placeholder="+92 300 0000000"
                  className="w-full px-4 py-2.5 rounded-xl bg-gray-50 border border-gray-300 text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                />
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-600 mb-1">
                Password
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter password"
                required
                className="w-full px-4 py-2.5 rounded-xl bg-gray-50 border border-gray-300 text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
              />
            </div>

            {isRegister && (
              <div>
                <label className="block text-sm font-medium text-gray-600 mb-1">
                  Confirm Password
                </label>
                <input
                  type="password"
                  placeholder="Confirm password"
                  className="w-full px-4 py-2.5 rounded-xl bg-gray-50 border border-gray-300 text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                />
              </div>
            )}

            {!isRegister && (
              <div className="flex items-center justify-between">
                <a href="#" className="text-sm text-blue-600 hover:text-blue-700 font-medium">
                  Forgot password?
                </a>
              </div>
            )}

            {error && (
              <div className="bg-red-50 text-red-600 px-4 py-3 rounded-xl text-sm border border-red-200">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 rounded-xl transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <span className="inline-block w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                  {isRegister ? "Registering..." : "Signing in..."}
                </>
              ) : (
                isRegister ? "Register NGO →" : "Sign In →"
              )}
            </button>

            {!isRegister && (
              <p className="text-center text-xs text-gray-400 mt-2">
                New NGO? <button type="button" onClick={() => setIsRegister(true)} className="text-blue-600 hover:text-blue-700 font-medium">Register here</button>
              </p>
            )}
          </form>
        </div>
      </div>
    </div>
  );
}