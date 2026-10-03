// src/pages/Settings.jsx

import { useState } from "react";
import { updatePassword } from "firebase/auth";
import { auth } from "../firebase";
import { useAuth } from "../context/AuthContext";
import Sidebar from "../components/Sidebar";
import {
  Bell,
  CircleAlert,
  CircleCheck,
  HardDrive,
  Lock,
  Save,
  Settings as SettingsIcon,
  Trash2,
  TriangleAlert,
  Truck,
} from "lucide-react";
import { Button, Card, CardBody, CardHeader, Input, Select } from "../components/ui";
import { cn } from "../lib/utils";

// Shared responsive spacing: compact on laptops, roomy on large screens
const shell = "ml-64 min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)]";
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cardBodyPad = "px-4 py-4 sm:px-5 sm:py-5 2xl:px-6 2xl:py-6";
const rowClass = "flex items-center justify-between gap-4 rounded-xl bg-slate-50 px-3.5 py-3 ring-1 ring-slate-200/70 transition-colors duration-150 hover:bg-slate-100/70 2xl:p-4";

function Lattice({ id, className }) {
  return (
    <svg className={cn("pointer-events-none absolute", className)} aria-hidden="true">
      <defs>
        <pattern id={id} width="56" height="56" patternUnits="userSpaceOnUse">
          <rect x="16" y="16" width="24" height="24" fill="none" stroke="currentColor" />
          <rect x="16" y="16" width="24" height="24" fill="none" stroke="currentColor" transform="rotate(45 28 28)" />
        </pattern>
      </defs>
      <rect width="100%" height="100%" fill={`url(#${id})`} />
    </svg>
  );
}

function Toggle({ checked, onClick, label }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={onClick}
      className={cn(
        "relative h-6 w-11 shrink-0 rounded-full transition-colors duration-200 focus-visible:outline-none focus-visible:shadow-focus",
        checked ? "bg-gradient-to-br from-emerald-400 to-emerald-600 shadow-inner" : "bg-slate-300"
      )}
    >
      <span
        className={cn(
          "absolute top-0.5 h-5 w-5 rounded-full bg-white shadow-md ring-1 ring-black/5 transition-all duration-200",
          checked ? "left-[22px]" : "left-0.5"
        )}
      />
    </button>
  );
}

function SectionHeader({ icon: Icon, title, description, tone }) {
  return (
    <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
      <div className={cn("flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br ring-1 2xl:h-10 2xl:w-10", tone)}>
        <Icon className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
      </div>
      <div>
        <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">{title}</h3>
        <p className="text-xs text-slate-500">{description}</p>
      </div>
    </CardHeader>
  );
}

export default function Settings() {
  const { user, userRole } = useAuth();
  const [newPassword, setNewPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [msg, setMsg] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  // Settings state
  const [settings, setSettings] = useState({
    emailNotifications: true,
    smsNotifications: false,
    pushNotifications: true,
    weeklyReports: true,
    autoAssignment: true,
    requireConfirmation: false,
    maxPickups: 8,
    workingHours: "6-18",
    dataRetention: 365,
    sessionTimeout: 60,
    backupFrequency: "Daily",
    twoFactorAuth: false,
  });

  async function handleChangePassword(e) {
    e.preventDefault();
    if (newPassword !== confirm) {
      setError("Passwords do not match");
      return;
    }
    if (newPassword.length < 6) {
      setError("Password must be at least 6 characters");
      return;
    }
    setLoading(true);
    setError("");
    setMsg("");
    try {
      await updatePassword(auth.currentUser, newPassword);
      setMsg("Password updated successfully");
      setNewPassword("");
      setConfirm("");
    } catch (err) {
      setError("Failed to update password. Please log out and log in again first.");
    }
    setLoading(false);
  }

  const toggleSetting = (key) => {
    setSettings(prev => ({ ...prev, [key]: !prev[key] }));
  };

  const notificationItems = [
    { key: "emailNotifications", title: "Email Notifications", desc: "Receive updates via email" },
    { key: "smsNotifications", title: "SMS Notifications", desc: "Receive updates via SMS" },
    { key: "pushNotifications", title: "Push Notifications", desc: "Receive browser notifications" },
    { key: "weeklyReports", title: "Weekly Reports", desc: "Receive weekly summary emails" },
  ];

  const driverToggles = [
    { key: "autoAssignment", title: "Auto Assignment", desc: "Automatically assign pickups to drivers" },
    { key: "requireConfirmation", title: "Require Confirmation", desc: "Drivers must confirm assignments" },
  ];

  return (
    <div className="flex">
      <Sidebar />
      <main className={cn(shell, "px-4 py-5 sm:px-6 sm:py-6 2xl:px-10 2xl:py-8")}>
        <div className="mx-auto max-w-4xl">
          {/* Header */}
          <div className={cn(
            "relative isolate overflow-hidden rounded-2xl bg-[linear-gradient(115deg,#064e3b_0%,#047857_52%,#0f766e_100%)] p-5 shadow-xl shadow-emerald-950/15 ring-1 ring-emerald-950/30 motion-safe:animate-slide-up sm:p-6 2xl:p-8",
            sectionGap
          )}>
            <Lattice
              id="eidclean-settings-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div className="pointer-events-none absolute -right-10 -top-16 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl 2xl:h-64 2xl:w-64" aria-hidden="true" />
            <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-amber-200 ring-1 ring-white/20 backdrop-blur sm:h-11 sm:w-11 2xl:h-12 2xl:w-12">
                  <SettingsIcon className="h-5 w-5 2xl:h-6 2xl:w-6" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold tracking-tight text-white sm:text-2xl">System Settings</h2>
                  <p className="mt-0.5 text-sm text-emerald-50/75">
                    Configure admin panel preferences — Abbottabad Municipal Corporation
                  </p>
                </div>
              </div>
              <Button className="h-9 shrink-0 bg-white px-3.5 text-emerald-900 shadow-lg shadow-emerald-950/20 hover:bg-emerald-50 active:bg-emerald-100 2xl:h-10 2xl:px-4">
                <Save className="h-4 w-4" aria-hidden="true" />
                Save Settings
              </Button>
            </div>
          </div>

          <div className="space-y-4 sm:space-y-5 2xl:space-y-6">

            {/* NOTIFICATIONS */}
            <Card padding="none" className="overflow-hidden">
              <SectionHeader
                icon={Bell}
                title="Notifications"
                description="Choose how you want to be updated"
                tone="from-blue-50 to-blue-100 text-blue-600 ring-blue-200"
              />
              <CardBody className={cn("grid grid-cols-1 gap-2.5 md:grid-cols-2 2xl:gap-3", cardBodyPad)}>
                {notificationItems.map((item) => (
                  <div key={item.key} className={rowClass}>
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-slate-900">{item.title}</p>
                      <p className="text-xs text-slate-500">{item.desc}</p>
                    </div>
                    <Toggle
                      checked={settings[item.key]}
                      label={item.title}
                      onClick={() => toggleSetting(item.key)}
                    />
                  </div>
                ))}
              </CardBody>
            </Card>

            {/* DRIVER MANAGEMENT */}
            <Card padding="none" className="overflow-hidden">
              <SectionHeader
                icon={Truck}
                title="Driver Management"
                description="Assignment rules and working limits"
                tone="from-emerald-50 to-emerald-100 text-emerald-600 ring-emerald-200"
              />
              <CardBody className={cn("space-y-2.5 2xl:space-y-3", cardBodyPad)}>
                {driverToggles.map((item) => (
                  <div key={item.key} className={rowClass}>
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-slate-900">{item.title}</p>
                      <p className="text-xs text-slate-500">{item.desc}</p>
                    </div>
                    <Toggle
                      checked={settings[item.key]}
                      label={item.title}
                      onClick={() => toggleSetting(item.key)}
                    />
                  </div>
                ))}

                <div className="grid grid-cols-1 gap-4 pt-1.5 sm:grid-cols-2 2xl:gap-5 2xl:pt-2">
                  <Input
                    label="Max Pickups Per Driver / Day"
                    type="number"
                    value={settings.maxPickups}
                    onChange={(e) => setSettings({ ...settings, maxPickups: parseInt(e.target.value) })}
                  />
                  <Input
                    label="Working Hours (Abbottabad PKT)"
                    type="text"
                    value={settings.workingHours}
                    onChange={(e) => setSettings({ ...settings, workingHours: e.target.value })}
                    placeholder="6-18 (6 AM to 6 PM)"
                  />
                </div>
              </CardBody>
            </Card>

            {/* SYSTEM & DATA */}
            <Card padding="none" className="overflow-hidden">
              <SectionHeader
                icon={SettingsIcon}
                title="System & Data"
                description="Retention, sessions and security"
                tone="from-amber-50 to-amber-100 text-amber-600 ring-amber-200"
              />
              <CardBody className={cn("grid grid-cols-1 gap-4 md:grid-cols-2 2xl:gap-5", cardBodyPad)}>
                <Input
                  label="Data Retention (days)"
                  hint="How long to keep completed pickup records"
                  type="number"
                  value={settings.dataRetention}
                  onChange={(e) => setSettings({ ...settings, dataRetention: parseInt(e.target.value) })}
                />
                <Input
                  label="Session Timeout (minutes)"
                  type="number"
                  value={settings.sessionTimeout}
                  onChange={(e) => setSettings({ ...settings, sessionTimeout: parseInt(e.target.value) })}
                />
                <Select
                  label="Backup Frequency"
                  value={settings.backupFrequency}
                  onChange={(e) => setSettings({ ...settings, backupFrequency: e.target.value })}
                >
                  <option>Daily</option>
                  <option>Weekly</option>
                  <option>Monthly</option>
                </Select>
                <div className="flex flex-col justify-end">
                  <div className={rowClass}>
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-slate-900">Two-Factor Authentication</p>
                      <p className="text-xs text-slate-500">Extra security for admin login</p>
                    </div>
                    <Toggle
                      checked={settings.twoFactorAuth}
                      label="Two-Factor Authentication"
                      onClick={() => toggleSetting("twoFactorAuth")}
                    />
                  </div>
                </div>
              </CardBody>
            </Card>

            {/* CHANGE PASSWORD */}
            <Card padding="none" className="overflow-hidden">
              <SectionHeader
                icon={Lock}
                title="Change Admin Password"
                description="Use at least 6 characters"
                tone="from-teal-50 to-teal-100 text-teal-600 ring-teal-200"
              />
              <CardBody className={cardBodyPad}>
                <form onSubmit={handleChangePassword} className="space-y-4 2xl:space-y-5">
                  <div className="grid grid-cols-1 gap-4 md:grid-cols-2 2xl:gap-5">
                    <Input
                      label="New Password"
                      leftIcon={Lock}
                      type="password"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      placeholder="minimum 6 characters"
                      required
                    />
                    <Input
                      label="Confirm Password"
                      leftIcon={Lock}
                      type="password"
                      value={confirm}
                      onChange={(e) => setConfirm(e.target.value)}
                      placeholder="repeat new password"
                      required
                    />
                  </div>
                  {error && (
                    <p className="flex items-center gap-2 rounded-xl bg-red-50 px-3.5 py-2.5 text-sm text-red-600 ring-1 ring-red-100">
                      <CircleAlert className="h-4 w-4 shrink-0" aria-hidden="true" />
                      {error}
                    </p>
                  )}
                  {msg && (
                    <p className="flex items-center gap-2 rounded-xl bg-emerald-50 px-3.5 py-2.5 text-sm text-emerald-700 ring-1 ring-emerald-100">
                      <CircleCheck className="h-4 w-4 shrink-0" aria-hidden="true" />
                      {msg}
                    </p>
                  )}
                  <Button
                    type="submit"
                    disabled={loading}
                    leftIcon={Lock}
                    className="bg-emerald-600 px-5 shadow-sm shadow-emerald-600/20 hover:bg-emerald-700 2xl:px-6"
                  >
                    {loading ? "Updating..." : "Update Password"}
                  </Button>
                </form>
              </CardBody>
            </Card>

            {/* DANGER ZONE */}
            <Card padding="none" className="overflow-hidden border-red-200 bg-gradient-to-br from-red-50 via-white to-white">
              <div className="flex items-start gap-3 px-4 pt-4 sm:px-5 sm:pt-5 2xl:px-6 2xl:pt-6">
                <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-red-100 text-red-600 ring-1 ring-red-200 2xl:h-10 2xl:w-10">
                  <TriangleAlert className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className="text-[15px] font-semibold tracking-tight text-red-700 2xl:text-base">Danger Zone</h3>
                  <p className="text-sm text-red-600/90">These actions are irreversible. Please be careful.</p>
                </div>
              </div>
              <div className="flex flex-wrap gap-2.5 px-4 pb-4 pt-4 sm:px-5 sm:pb-5 2xl:gap-3 2xl:px-6 2xl:pb-6 2xl:pt-5">
                <Button variant="danger" leftIcon={Trash2} className="px-5 shadow-sm shadow-red-600/20 2xl:px-6">
                  Clear All Data
                </Button>
                <Button variant="outline" leftIcon={HardDrive} className="px-5 2xl:px-6">
                  Run Manual Backup
                </Button>
              </div>
            </Card>

          </div>
        </div>
      </main>
    </div>
  );
}