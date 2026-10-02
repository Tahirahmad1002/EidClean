// 📁 src/pages/Settings.jsx

import { useState } from "react";
import { updatePassword } from "firebase/auth";
import { auth } from "../firebase";
import { useAuth } from "../context/AuthContext";
import Sidebar from "../components/Sidebar";

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

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8 min-h-screen bg-gray-50">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-gray-800">System Settings</h2>
              <p className="text-gray-500 text-sm mt-1">
                Configure admin panel preferences — Abbottabad Municipal Corporation
              </p>
            </div>
            <button className="bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-xl text-sm font-medium transition-colors">
              💾 Save Settings
            </button>
          </div>
        </div>

        <div className="max-w-4xl space-y-6">

          {/* ─── NOTIFICATIONS ────────────────── */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <h3 className="font-semibold text-gray-800 mb-4">🔔 Notifications</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                <div>
                  <p className="font-medium text-gray-800">Email Notifications</p>
                  <p className="text-xs text-gray-400">Receive updates via email</p>
                </div>
                <button
                  onClick={() => toggleSetting("emailNotifications")}
                  className={`w-12 h-6 rounded-full transition-colors relative ${
                    settings.emailNotifications ? "bg-emerald-500" : "bg-gray-300"
                  }`}
                >
                  <div className={`w-5 h-5 rounded-full bg-white absolute top-0.5 transition-all ${
                    settings.emailNotifications ? "left-6" : "left-0.5"
                  }`} />
                </button>
              </div>

              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                <div>
                  <p className="font-medium text-gray-800">SMS Notifications</p>
                  <p className="text-xs text-gray-400">Receive updates via SMS</p>
                </div>
                <button
                  onClick={() => toggleSetting("smsNotifications")}
                  className={`w-12 h-6 rounded-full transition-colors relative ${
                    settings.smsNotifications ? "bg-emerald-500" : "bg-gray-300"
                  }`}
                >
                  <div className={`w-5 h-5 rounded-full bg-white absolute top-0.5 transition-all ${
                    settings.smsNotifications ? "left-6" : "left-0.5"
                  }`} />
                </button>
              </div>

              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                <div>
                  <p className="font-medium text-gray-800">Push Notifications</p>
                  <p className="text-xs text-gray-400">Receive browser notifications</p>
                </div>
                <button
                  onClick={() => toggleSetting("pushNotifications")}
                  className={`w-12 h-6 rounded-full transition-colors relative ${
                    settings.pushNotifications ? "bg-emerald-500" : "bg-gray-300"
                  }`}
                >
                  <div className={`w-5 h-5 rounded-full bg-white absolute top-0.5 transition-all ${
                    settings.pushNotifications ? "left-6" : "left-0.5"
                  }`} />
                </button>
              </div>

              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                <div>
                  <p className="font-medium text-gray-800">Weekly Reports</p>
                  <p className="text-xs text-gray-400">Receive weekly summary emails</p>
                </div>
                <button
                  onClick={() => toggleSetting("weeklyReports")}
                  className={`w-12 h-6 rounded-full transition-colors relative ${
                    settings.weeklyReports ? "bg-emerald-500" : "bg-gray-300"
                  }`}
                >
                  <div className={`w-5 h-5 rounded-full bg-white absolute top-0.5 transition-all ${
                    settings.weeklyReports ? "left-6" : "left-0.5"
                  }`} />
                </button>
              </div>
            </div>
          </div>

          {/* ─── DRIVER MANAGEMENT ────────────── */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <h3 className="font-semibold text-gray-800 mb-4">🚛 Driver Management</h3>
            <div className="space-y-4">
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                <div>
                  <p className="font-medium text-gray-800">Auto Assignment</p>
                  <p className="text-xs text-gray-400">Automatically assign pickups to drivers</p>
                </div>
                <button
                  onClick={() => toggleSetting("autoAssignment")}
                  className={`w-12 h-6 rounded-full transition-colors relative ${
                    settings.autoAssignment ? "bg-emerald-500" : "bg-gray-300"
                  }`}
                >
                  <div className={`w-5 h-5 rounded-full bg-white absolute top-0.5 transition-all ${
                    settings.autoAssignment ? "left-6" : "left-0.5"
                  }`} />
                </button>
              </div>

              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                <div>
                  <p className="font-medium text-gray-800">Require Confirmation</p>
                  <p className="text-xs text-gray-400">Drivers must confirm assignments</p>
                </div>
                <button
                  onClick={() => toggleSetting("requireConfirmation")}
                  className={`w-12 h-6 rounded-full transition-colors relative ${
                    settings.requireConfirmation ? "bg-emerald-500" : "bg-gray-300"
                  }`}
                >
                  <div className={`w-5 h-5 rounded-full bg-white absolute top-0.5 transition-all ${
                    settings.requireConfirmation ? "left-6" : "left-0.5"
                  }`} />
                </button>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div className="p-3 bg-gray-50 rounded-xl">
                  <p className="text-xs text-gray-400">Max Pickups Per Driver / Day</p>
                  <input
                    type="number"
                    value={settings.maxPickups}
                    onChange={(e) => setSettings({ ...settings, maxPickups: parseInt(e.target.value) })}
                    className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                  />
                </div>
                <div className="p-3 bg-gray-50 rounded-xl">
                  <p className="text-xs text-gray-400">Working Hours (Abbottabad PKT)</p>
                  <input
                    type="text"
                    value={settings.workingHours}
                    onChange={(e) => setSettings({ ...settings, workingHours: e.target.value })}
                    className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                    placeholder="6-18 (6 AM to 6 PM)"
                  />
                </div>
              </div>
            </div>
          </div>

          {/* ─── SYSTEM & DATA ────────────────── */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <h3 className="font-semibold text-gray-800 mb-4">⚙️ System & Data</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="p-3 bg-gray-50 rounded-xl">
                <p className="text-xs text-gray-400">Data Retention (days)</p>
                <p className="text-sm text-gray-500">How long to keep completed pickup records</p>
                <input
                  type="number"
                  value={settings.dataRetention}
                  onChange={(e) => setSettings({ ...settings, dataRetention: parseInt(e.target.value) })}
                  className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                />
              </div>
              <div className="p-3 bg-gray-50 rounded-xl">
                <p className="text-xs text-gray-400">Session Timeout (minutes)</p>
                <input
                  type="number"
                  value={settings.sessionTimeout}
                  onChange={(e) => setSettings({ ...settings, sessionTimeout: parseInt(e.target.value) })}
                  className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                />
              </div>
              <div className="p-3 bg-gray-50 rounded-xl">
                <p className="text-xs text-gray-400">Backup Frequency</p>
                <select
                  value={settings.backupFrequency}
                  onChange={(e) => setSettings({ ...settings, backupFrequency: e.target.value })}
                  className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                >
                  <option>Daily</option>
                  <option>Weekly</option>
                  <option>Monthly</option>
                </select>
              </div>
              <div className="p-3 bg-gray-50 rounded-xl">
                <p className="text-xs text-gray-400">Two-Factor Authentication</p>
                <p className="text-sm text-gray-500">Extra security for admin login</p>
                <button
                  onClick={() => toggleSetting("twoFactorAuth")}
                  className={`mt-2 w-12 h-6 rounded-full transition-colors relative ${
                    settings.twoFactorAuth ? "bg-emerald-500" : "bg-gray-300"
                  }`}
                >
                  <div className={`w-5 h-5 rounded-full bg-white absolute top-0.5 transition-all ${
                    settings.twoFactorAuth ? "left-6" : "left-0.5"
                  }`} />
                </button>
              </div>
            </div>
          </div>

          {/* ─── CHANGE PASSWORD ────────────────── */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <h3 className="font-semibold text-gray-800 mb-4">🔑 Change Admin Password</h3>
            <form onSubmit={handleChangePassword} className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">New Password</label>
                  <input
                    type="password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    placeholder="minimum 6 characters"
                    required
                    className="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Confirm Password</label>
                  <input
                    type="password"
                    value={confirm}
                    onChange={(e) => setConfirm(e.target.value)}
                    placeholder="repeat new password"
                    required
                    className="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                  />
                </div>
              </div>
              {error && <p className="text-red-500 text-sm">{error}</p>}
              {msg && <p className="text-emerald-600 text-sm">{msg}</p>}
              <button
                type="submit"
                disabled={loading}
                className="bg-emerald-500 hover:bg-emerald-600 text-white px-6 py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50"
              >
                {loading ? "Updating..." : "Update Password"}
              </button>
            </form>
          </div>

          {/* ─── DANGER ZONE ──────────────────── */}
          <div className="bg-red-50 rounded-2xl p-6 border border-red-200">
            <h3 className="font-semibold text-red-700 mb-2">⚠️ Danger Zone</h3>
            <p className="text-sm text-red-600 mb-4">These actions are irreversible. Please be careful.</p>
            <div className="flex gap-4">
              <button className="bg-red-500 hover:bg-red-600 text-white px-6 py-2.5 rounded-xl text-sm font-medium transition-colors">
                🗑️ Clear All Data
              </button>
              <button className="bg-gray-200 hover:bg-gray-300 text-gray-700 px-6 py-2.5 rounded-xl text-sm font-medium transition-colors">
                💾 Run Manual Backup
              </button>
            </div>
          </div>

        </div>
      </main>
    </div>
  );
}