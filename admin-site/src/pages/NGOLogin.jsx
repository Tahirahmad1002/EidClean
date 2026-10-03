// src/pages/NGOLogin.jsx

import { useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "../firebase";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import {
  ArrowRight,
  Building2,
  Check,
  HeartHandshake,
  Lock,
  Mail,
  Moon,
  Smartphone,
  User,
  XCircle,
} from "lucide-react";
import { Button, Input } from "../components/ui";
import { cn } from "../lib/utils";

const features = [
  "Accept & manage donation requests",
  "Real-time pickup tracking",
  "Family distribution management",
  "Impact reports & analytics",
];

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
      // DUMMY LOGIN - No Firebase auth
      // Just check if email and password are not empty
      if (email.trim() && password.trim()) {
        console.log("Dummy NGO login successful");
        
        // Store dummy user info in localStorage (optional)
        localStorage.setItem("ngoUser", JSON.stringify({
          email: email,
          role: "ngo",
          name: "NGO Admin"
        }));
        
        // Navigate to NGO Dashboard
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
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-gradient-to-br from-emerald-950 via-emerald-950 to-slate-950 p-4 sm:p-5 lg:p-6">
      {/* Ambient glow */}
      <div
        className="pointer-events-none absolute -left-24 -top-32 h-96 w-96 rounded-full bg-emerald-500/20 blur-3xl"
        aria-hidden="true"
      />
      <div
        className="pointer-events-none absolute -bottom-32 -right-24 h-80 w-80 rounded-full bg-amber-400/10 blur-3xl"
        aria-hidden="true"
      />

      <div className="relative grid w-full max-w-5xl overflow-hidden rounded-2xl bg-white shadow-pop ring-1 ring-white/10 md:grid-cols-2">
        {/* Left Side - Branding */}
        <div className="relative flex flex-col justify-between overflow-hidden bg-gradient-to-br from-emerald-700 via-emerald-700 to-teal-700 p-5 sm:p-6 lg:p-10 md:min-h-[560px]">
          <div
            className="pointer-events-none absolute inset-0 bg-[linear-gradient(to_right,rgba(255,255,255,0.07)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.07)_1px,transparent_1px)] bg-[size:28px_28px]"
            aria-hidden="true"
          />
          <div
            className="pointer-events-none absolute -right-16 -top-20 h-64 w-64 rounded-full bg-white/10"
            aria-hidden="true"
          />
          <div
            className="pointer-events-none absolute -bottom-24 left-10 h-56 w-56 rounded-full bg-amber-300/30 blur-3xl"
            aria-hidden="true"
          />
          <Moon
            className="pointer-events-none absolute right-6 top-6 h-24 w-24 text-white/10 sm:h-28 sm:w-28"
            aria-hidden="true"
          />

          <div className="relative">
            <div className="mb-5 flex items-center gap-3 sm:mb-6">
              <div className="relative flex h-10 w-10 items-center justify-center rounded-xl bg-white/15 ring-1 ring-white/25 backdrop-blur">
                <HeartHandshake className="h-5 w-5 text-white" aria-hidden="true" />
                <span
                  className="absolute -right-0.5 -top-0.5 h-2 w-2 rounded-full bg-amber-400 ring-2 ring-emerald-700"
                  aria-hidden="true"
                />
              </div>
              <span className="text-base font-semibold tracking-tight text-white">EidClean NGO</span>
            </div>

            <h2 className="text-2xl font-semibold tracking-tight text-white sm:text-3xl">
              Donation Portal
            </h2>
            <h3 className="mt-1.5 text-base font-medium text-emerald-50/90 sm:text-lg">
              Abbottabad
            </h3>
            <p className="mt-3 text-sm font-medium text-amber-200">
              Meat Donation Network
            </p>
            <p className="mt-2 text-sm leading-relaxed text-emerald-50/75">
              Coordinate Qurbani meat donations, manage pickups, and ensure every family in need is served.
            </p>
          </div>

          <div className="relative mt-6 hidden space-y-2.5 md:block">
            {features.map((feature) => (
              <div key={feature} className="flex items-center gap-3 text-sm text-emerald-50/90">
                <span className="flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-white/15 ring-1 ring-white/25">
                  <Check className="h-3 w-3 text-emerald-100" aria-hidden="true" />
                </span>
                {feature}
              </div>
            ))}
          </div>

          <div className="relative mt-6 hidden md:block">
            <p className="text-xs text-emerald-50/50">
              Eid-ul-Adha Donation Management
              <br />
              Abbottabad, KPK
            </p>
          </div>
        </div>

        {/* Right Side - Login/Register Form */}
        <div className="flex flex-col justify-center bg-white p-5 sm:p-8 lg:p-12">
          <div className="mb-5 sm:mb-6">
            <div className="mb-4 inline-flex items-center gap-1 rounded-lg bg-slate-100 p-1 ring-1 ring-slate-200">
              <button
                type="button"
                onClick={() => setIsRegister(false)}
                className={cn(
                  "rounded-md px-4 py-1.5 text-sm font-medium transition-all duration-150",
                  !isRegister
                    ? "bg-white text-emerald-700 shadow-sm ring-1 ring-slate-200"
                    : "text-slate-500 hover:text-slate-700"
                )}
              >
                Sign In
              </button>
              <button
                type="button"
                onClick={() => setIsRegister(true)}
                className={cn(
                  "rounded-md px-4 py-1.5 text-sm font-medium transition-all duration-150",
                  isRegister
                    ? "bg-white text-emerald-700 shadow-sm ring-1 ring-slate-200"
                    : "text-slate-500 hover:text-slate-700"
                )}
              >
                Register NGO
              </button>
            </div>
            <h2 className="text-2xl font-semibold tracking-tight text-slate-900">
              {isRegister ? "Register NGO" : "Welcome back"}
            </h2>
            <p className="mt-1 text-sm text-slate-500">
              {isRegister ? "Create your organization account" : "Sign in to your NGO account"}
            </p>
          </div>

          <form onSubmit={handleLogin} className="space-y-4">
            {isRegister && (
              <Input
                label="Your Name"
                type="text"
                leftIcon={User}
                placeholder="Memona Akhtar"
              />
            )}

            <Input
              label={isRegister ? "Organization Name" : "Email Address"}
              type={isRegister ? "text" : "email"}
              leftIcon={isRegister ? Building2 : Mail}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder={isRegister ? "Edhi Foundation" : "memona@edngo.org.pk"}
              required
            />

            {isRegister && (
              <Input
                label="Phone"
                type="text"
                leftIcon={Smartphone}
                placeholder="+92 300 0000000"
              />
            )}

            <Input
              label="Password"
              type="password"
              leftIcon={Lock}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter password"
              required
            />

            {isRegister && (
              <Input
                label="Confirm Password"
                type="password"
                leftIcon={Lock}
                placeholder="Confirm password"
              />
            )}

            {!isRegister && (
              <div className="flex items-center justify-between">
                <a
                  href="#"
                  className="text-sm font-medium text-emerald-600 transition-colors duration-150 hover:text-emerald-700"
                >
                  Forgot password?
                </a>
              </div>
            )}

            {error && (
              <div className="flex items-start gap-2.5 rounded-xl bg-red-50 px-4 py-3 text-sm text-red-700 ring-1 ring-red-100">
                <XCircle className="mt-0.5 h-4 w-4 shrink-0 text-red-500" aria-hidden="true" />
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
              {loading
                ? isRegister
                  ? "Registering..."
                  : "Signing in..."
                : isRegister
                ? "Register NGO"
                : "Sign In"}
            </Button>

            {!isRegister && (
              <p className="pt-1 text-center text-xs text-slate-400">
                New NGO?{" "}
                <button
                  type="button"
                  onClick={() => setIsRegister(true)}
                  className="font-medium text-emerald-600 transition-colors duration-150 hover:text-emerald-700"
                >
                  Register here
                </button>
              </p>
            )}
          </form>
        </div>
      </div>
    </div>
  );
}