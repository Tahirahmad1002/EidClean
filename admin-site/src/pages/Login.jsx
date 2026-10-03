import { useState } from "react";
import { signInWithEmailAndPassword } from "firebase/auth";
import { auth } from "../firebase";
import { useNavigate } from "react-router-dom";
import { ArrowRight, Leaf, Lock, Mail, XCircle } from "lucide-react";
import { Button, Input } from "../components/ui";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  async function handleLogin(e) {
    e.preventDefault();
    setLoading(true);
    setError("");
    try {
      await signInWithEmailAndPassword(auth, email, password);
      navigate("/");
    } catch (err) {
      setError("Invalid email or password. Please try again.");
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
        className="pointer-events-none absolute -bottom-32 -right-24 h-80 w-80 rounded-full bg-teal-500/15 blur-3xl"
        aria-hidden="true"
      />

      <div className="relative w-full max-w-md overflow-hidden rounded-2xl bg-white shadow-pop ring-1 ring-white/10">
        {/* Hero band */}
        <div className="relative overflow-hidden bg-gradient-to-br from-emerald-600 via-emerald-600 to-teal-600 p-5 text-center sm:p-6">
          <div
            className="pointer-events-none absolute inset-0 bg-[linear-gradient(to_right,rgba(255,255,255,0.07)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.07)_1px,transparent_1px)] bg-[size:28px_28px]"
            aria-hidden="true"
          />
          <div
            className="pointer-events-none absolute -right-12 -top-16 h-48 w-48 rounded-full bg-white/10"
            aria-hidden="true"
          />
          <div
            className="pointer-events-none absolute -bottom-20 left-6 h-40 w-40 rounded-full bg-amber-300/25 blur-3xl"
            aria-hidden="true"
          />

          <div className="relative">
            {/* Logo */}
            <div className="relative mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-white/15 ring-1 ring-white/25 backdrop-blur">
              <Leaf className="h-7 w-7 text-white" aria-hidden="true" />
              <span
                className="absolute -right-0.5 -top-0.5 h-2.5 w-2.5 rounded-full bg-amber-400 ring-2 ring-emerald-600"
                aria-hidden="true"
              />
            </div>
            <h1 className="text-2xl font-semibold tracking-tight text-white">EidClean</h1>
            <p className="mt-1 text-sm text-emerald-50/80">
              Municipal Admin Dashboard
            </p>
          </div>
        </div>

        <div className="p-5 sm:p-6 lg:p-8">
          {/* Form */}
          <form onSubmit={handleLogin} className="space-y-4">
            <Input
              label="Email Address"
              type="email"
              leftIcon={Mail}
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@eidclean.com"
              required
            />

            <Input
              label="Password"
              type="password"
              leftIcon={Lock}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
            />

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
              {loading ? "Signing in..." : "Sign In"}
            </Button>
          </form>

          <p className="mt-6 text-center text-xs text-slate-400">
            EidClean © 2025 — Eid-ul-Adha Waste Management System
          </p>
        </div>
      </div>
    </div>
  );
}