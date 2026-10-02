// 📁 src/pages/Dashboard.jsx

import { useEffect, useState } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";
import { useAuth } from "../context/AuthContext";
import { useNavigate } from "react-router-dom";

function StatCard({ title, value, icon, bg }) {
  return (
    <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-500 font-medium">{title}</p>
          <p className="text-3xl font-bold text-gray-800 mt-1">{value}</p>
        </div>
        <div className={`w-14 h-14 rounded-2xl flex items-center justify-center text-2xl ${bg}`}>
          {icon}
        </div>
      </div>
    </div>
  );
}

function PendingAreaRow({ area, requests, status, action }) {
  const statusColors = {
    Pending: "bg-yellow-100 text-yellow-700",
    Assigned: "bg-blue-100 text-blue-700",
    Completed: "bg-green-100 text-green-700",
  };

  return (
    <tr className="hover:bg-gray-50 transition-colors">
      <td className="px-4 py-3 text-sm font-medium text-gray-800">{area}</td>
      <td className="px-4 py-3 text-sm text-gray-600">{requests}</td>
      <td className="px-4 py-3">
        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${statusColors[status] || "bg-gray-100 text-gray-600"}`}>
          {status}
        </span>
      </td>
      <td className="px-4 py-3">
        <button className="text-sm text-emerald-600 hover:text-emerald-800 font-medium">
          {action}
        </button>
      </td>
    </tr>
  );
}

export default function Dashboard() {
  const { user } = useAuth();
  const [stats, setStats] = useState({
    total: 0,
    pending: 0,
    assigned: 0,
    completed: 0,
    drivers: 0,
    areas: 0,
  });
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    async function fetchStats() {
      try {
        const requestsSnap = await getDocs(collection(db, "pickupRequests"));
        const driversSnap = await getDocs(collection(db, "drivers"));
        const areasSnap = await getDocs(collection(db, "areas"));

        const pending = requestsSnap.docs.filter(d => d.data().status === "pending").length;
        const assigned = requestsSnap.docs.filter(d => d.data().status === "assigned").length;
        const completed = requestsSnap.docs.filter(d => d.data().status === "completed").length;

        setStats({
          total: requestsSnap.size,
          pending,
          assigned,
          completed,
          drivers: driversSnap.size,
          areas: areasSnap.size,
        });
      } catch (error) {
        console.error("Error fetching stats:", error);
      }
      setLoading(false);
    }
    fetchStats();
  }, []);

  // Dummy AI predictions data
  const aiPredictions = [
    { area: "Jinnahabad", trucks: 3, workers: 6, bins: 12 },
    { area: "Nawanshehr", trucks: 2, workers: 4, bins: 8 },
    { area: "Mirpur", trucks: 2, workers: 5, bins: 10 },
  ];

  // Pending pickups by area (dummy data for now)
  const pendingAreas = [
    { area: "Jinnahabad", requests: 12, status: "Pending", action: "Assign" },
    { area: "Nawanshehr", requests: 8, status: "Assigned", action: "Track" },
    { area: "Mirpur", requests: 5, status: "Completed", action: "View" },
    { area: "Supply Bazar", requests: 15, status: "Pending", action: "Assign" },
  ];

  if (loading) {
    return (
      <div className="flex">
        <Sidebar />
        <main className="ml-64 flex-1 p-8 min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-500"></div>
        </main>
      </div>
    );
  }

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8 min-h-screen bg-gray-50">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-gray-800">
                Welcome, {user?.displayName || "Admin"}! 🏅
              </h2>
              <p className="text-gray-500 text-sm mt-1">
                Abbottabad Municipal Corporation — Eid ul Adha Operations
              </p>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-sm text-gray-500">
                📅 {new Date().toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric", year: "numeric" })}
              </span>
            </div>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
          <StatCard title="Total Pickups" value={stats.total} icon="📋" bg="bg-blue-50" />
          <StatCard title="Active Drivers" value={stats.drivers} icon="🚛" bg="bg-emerald-50" />
          <StatCard title="Areas Managed" value={stats.areas} icon="🗺️" bg="bg-purple-50" />
          <StatCard title="On-Time Rate" value="89%" icon="✅" bg="bg-green-50" />
        </div>

        {/* AI Resource Planning + Smart Insights Row */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
          {/* AI Resource Planning - Exact Figma Design */}
          <div className="lg:col-span-2 bg-gradient-to-br from-green-700 to-green-800 rounded-2xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between mb-4">
              <h3 className="font-semibold text--800">🤖 AI Resource Planning</h3>
              <span className="text-xs text-emerald-600 bg-emerald-50 px-3 py-1 rounded-full font-medium">AI Powered</span>
            </div>
            <p className="text-green-200 text-sm mb-4">
              AI predicts resource needs per area based on population density & past Eid data.
            </p>
            <div className="space-y-3">
              {aiPredictions.map((item) => (
                <div key={item.area} className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                  <span className="font-medium text-gray-800 w-28">{item.area}</span>
                  <div className="flex items-center gap-6 text-sm">
                    <span className="text-gray-600">🚛 {item.trucks}</span>
                    <span className="text-gray-600">👷 {item.workers}</span>
                    <span className="text-gray-600">🗑️ {item.bins}</span>
                  </div>
                </div>
              ))}
            </div>
            <button
              onClick={() => navigate("/predictions")}
              className="mt-4 bg-emerald-500 hover:bg-emerald-600 text-white px-6 py-2.5 rounded-xl text-sm font-medium transition-colors"
            >
              Plan Resources →
            </button>
          </div>

          {/* Smart Insights */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <h3 className="font-semibold text-gray-800 mb-4">💡 Smart Insights</h3>
            <div className="space-y-4">
              <div className="p-3 bg-blue-50 rounded-xl">
                <p className="text-xs text-blue-600 font-medium">⏰ Peak Hours</p>
                <p className="text-sm text-gray-700">9–11 AM, 4–6 PM</p>
              </div>
              <div className="p-3 bg-yellow-50 rounded-xl">
                <p className="text-xs text-yellow-600 font-medium">📈 High Demand</p>
                <p className="text-sm text-gray-700">Supply Bazar (+35%)</p>
              </div>
              <div className="p-3 bg-emerald-50 rounded-xl">
                <p className="text-xs text-emerald-600 font-medium">💡 Tip</p>
                <p className="text-sm text-gray-700">Add 2 more drivers to Mirpur</p>
              </div>
            </div>
          </div>
        </div>

        {/* Live Map Placeholder */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-gray-800">📍 Live Pickup Map — Abbottabad</h3>
            <div className="flex items-center gap-4 text-sm text-gray-500">
              <span className="flex items-center gap-1">
                <span className="w-3 h-3 bg-emerald-500 rounded-full"></span> Pickup
              </span>
              <span className="flex items-center gap-1">
                <span className="w-3 h-3 bg-blue-500 rounded-full"></span> Vehicle
              </span>
            </div>
          </div>
          <div className="bg-gray-100 rounded-xl h-48 flex items-center justify-center">
            <div className="text-center">
              <span className="text-4xl mb-2 block">🗺️</span>
              <p className="text-gray-500 text-sm">Live map coming soon</p>
              <p className="text-gray-400 text-xs">Real-time pickup tracking will appear here</p>
            </div>
          </div>
        </div>

        {/* Pending Pickups by Area */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <h3 className="font-semibold text-gray-800 mb-4">📋 Pending Pickups by Area</h3>
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-gray-100">
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Area</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Requests</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Status</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase">Action</th>
                </tr>
              </thead>
              <tbody>
                {pendingAreas.map((item) => (
                  <PendingAreaRow key={item.area} {...item} />
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </main>
    </div>
  );
}