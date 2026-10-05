// src/pages/AdminLogin.jsx

import { useState, useEffect } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "../firebase";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import {
  ArrowRight,
  Check,
  Eye,
  EyeOff,
  Leaf,
  Lock,
  Mail,
  Moon,
  XCircle,
} from "lucide-react";
import { Button, Input } from "../components/ui";

const features = [
  "Real-time pickup tracking",
  "AI-powered resource planning",
  "Driver performance monitoring",
  "Area-wise analytics & reports",
];

export default function AdminLogin() {
  const [email, setEmail] = useState("admin@eidclean.com");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [loginSuccess, setLoginSuccess] = useState(false);
  const [showPassword, setShowPassword] = useState(false); // ← added

  const navigate = useNavigate();
  const { user, userRole, loading: authLoading } = useAuth();

  // Watch for role change after login
  useEffect(() => {
    if (loginSuccess && !authLoading) {
      console.log("Checking role for navigation:", userRole);
      if (userRole === "admin") {
        navigate("/dashboard", { replace: true });
      } else if (userRole === "ngo") {
        navigate("/ngo-dashboard", { replace: true });
      } else if (user) {
        console.log("No role yet, waiting...");
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
      console.log("Sign in successful");
      setLoginSuccess(true);
    } catch (err) {
      console.error("Login error:", err);
      setError("Invalid email or password. Please try again.");
      setLoading(false);
    }
  }

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-gradient-to-br from-emerald-950 via-emerald-950 to-slate-950 p-4 sm:p-5 lg:p-6">
      {/* Ambient glow */}
      <div
        className="pointer-events-none absolute -left-24 -top-32 h-96 w-96 rounded-full bg-emerald-500/20 blur-3xl"
        aria-hidden="true"
      />
      <div
        className="pointer-events-none absolute -bottom-32 -right-24 h-80 w-80 rounded-full bg-teal-500/15 blur-3xl"
        aria-hidden="true"
      />

      <div className="relative grid w-full max-w-5xl overflow-hidden rounded-2xl bg-white shadow-pop ring-1 ring-white/10 md:grid-cols-2">
        {/* Left Side — Branding */}
        <div className="relative flex flex-col justify-between overflow-hidden bg-gradient-to-br from-emerald-600 via-emerald-600 to-teal-600 p-5 sm:p-6 lg:p-10 md:min-h-[520px]">
          <div
            className="pointer-events-none absolute inset-0 bg-[linear-gradient(to_right,rgba(255,255,255,0.07)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.07)_1px,transparent_1px)] bg-[size:28px_28px]"
            aria-hidden="true"
          />
          <div
            className="pointer-events-none absolute -right-16 -top-20 h-64 w-64 rounded-full bg-white/10"
            aria-hidden="true"
          />
          <div
            className="pointer-events-none absolute -bottom-24 left-10 h-56 w-56 rounded-full bg-amber-300/25 blur-3xl"
            aria-hidden="true"
          />
          <Moon
            className="pointer-events-none absolute right-6 top-6 h-24 w-24 text-white/10 sm:h-28 sm:w-28"
            aria-hidden="true"
          />

          <div className="relative">
            <div className="mb-5 flex items-center gap-3 sm:mb-6">
              <div className="relative flex h-10 w-10 items-center justify-center rounded-xl bg-white/15 ring-1 ring-white/25 backdrop-blur">
                <Leaf className="h-5 w-5 text-white" aria-hidden="true" />
                <span
                  className="absolute -right-0.5 -top-0.5 h-2 w-2 rounded-full bg-amber-400 ring-2 ring-emerald-600"
                  aria-hidden="true"
                />
              </div>
              <span className="text-base font-semibold tracking-tight text-white">
                EidClean
              </span>
            </div>
            <h2 className="text-2xl font-semibold tracking-tight text-white sm:text-3xl">
              Municipal Portal
            </h2>
            <h3 className="mt-1.5 text-base font-medium text-emerald-50/90 sm:text-lg">
              Abbottabad Waste Management
            </h3>
            <p className="mt-3 text-sm leading-relaxed text-emerald-50/75">
              Khyber Pakhtunkhwa's smart Qurbani waste management system — keeping
              Abbottabad clean during Eid ul Adha.
            </p>
          </div>

          <div className="relative mt-6 hidden space-y-2.5 md:block">
            {features.map((feature) => (
              <div
                key={feature}
                className="flex items-center gap-3 text-sm text-emerald-50/90"
              >
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-white/15 ring-1 ring-white/25">
                  <Check className="h-3 w-3 text-emerald-100" aria-hidden="true" />
                </span>
                {feature}
              </div>
            ))}
          </div>

          <div className="relative mt-6 hidden md:block">
            <p className="text-xs text-emerald-50/50">
              Eid-ul-Adha Waste Management System
              <br />
              Abbottabad Municipal Corporation
            </p>
          </div>
        </div>

        {/* Right Side — Login Form */}
        <div className="flex flex-col justify-center p-5 sm:p-8 lg:p-12">
          <div className="mb-6 sm:mb-8">
            <h2 className="text-2xl font-semibold tracking-tight text-slate-900">
              Welcome back
            </h2>
            <p className="mt-1 text-sm text-slate-500">
              Sign in to your admin account
            </p>
          </div>

          <form onSubmit={handleLogin} className="space-y-4 sm:space-y-5">
            <Input
              label="Email Address"
              type="email"
              leftIcon={Mail}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@abbottabad.gov.pk"
              required
            />

            <div className="relative">
              <Input
                label="Password"
                type={showPassword ? "text" : "password"}
                leftIcon={Lock}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                placeholder="••••••••"
              />
              <button
                type="button"
                onClick={() => setShowPassword((v) => !v)}
                className="absolute right-3 top-[38px] rounded-md p-1.5 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-700"
                aria-label={showPassword ? "Hide password" : "Show password"}
              >
                {showPassword ? (
                  <EyeOff className="h-4 w-4" aria-hidden="true" />
                ) : (
                  <Eye className="h-4 w-4" aria-hidden="true" />
                )}
              </button>
            </div>

            <div className="flex items-center justify-between">
              <a
                href="#"
                className="text-sm font-medium text-emerald-600 transition-colors duration-150 hover:text-emerald-700"
              >
                Forgot password?
              </a>
            </div>

            {error && (
              <div className="flex items-start gap-2.5 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700 ring-1 ring-red-100">
                <XCircle
                  className="mt-0.5 h-4 w-4 shrink-0 text-red-500"
                  aria-hidden="true"
                />
                <span>{error}</span>
              </div>
            )}

            <Button
              type="submit"
              size="lg"
              fullWidth
              loading={loading}
              rightIcon={ArrowRight}
              className="shadow-lg shadow-emerald-500/20"
            >
              {loading ? "Signing in..." : "Sign In"}
            </Button>

            <p className="pt-1 text-center text-xs text-slate-400">
              For admin access, contact{" "}
              <span className="font-medium text-emerald-600">IT Support</span>
            </p>
          </form>
        </div>
      </div>
    </div>
  );
}