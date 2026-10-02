// 📁 src/pages/Analytics.jsx

import { useEffect, useState } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, PieChart, Pie, Cell,
  Legend
} from "recharts";

export default function Analytics() {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    total: 0,
    completed: 0,
    cancelled: 0,
    wasteKg: 0,
    responseTime: 0,
    completionRate: 0,
  });
  const [weeklyData, setWeeklyData] = useState([]);
  const [areaData, setAreaData] = useState([]);
  const [wasteTypeData, setWasteTypeData] = useState([]);
  const [areaPerformance, setAreaPerformance] = useState([]);

  useEffect(() => {
    fetchAnalytics();
  }, []);

  async function fetchAnalytics() {
    setLoading(true);
    try {
      const requestsSnap = await getDocs(collection(db, "pickupRequests"));
      const requests = requestsSnap.docs.map(d => ({ id: d.id, ...d.data() }));

      // Stats
      const total = requests.length;
      const completed = requests.filter(r => r.status === "completed").length;
      const cancelled = requests.filter(r => r.status === "cancelled").length;
      const completionRate = total > 0 ? ((completed / total) * 100) : 0;
      const totalAnimals = requests.reduce((sum, r) => sum + (r.animals || 0), 0);
      const wasteKg = totalAnimals * 45;

      setStats({
        total,
        completed,
        cancelled,
        wasteKg,
        responseTime: 42,
        completionRate,
      });

      // Weekly Performance (dummy for now - will be dynamic later)
      const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      const weekly = days.map(day => ({
        day,
        completed: Math.floor(Math.random() * 30) + 20,
        cancelled: Math.floor(Math.random() * 6) + 1,
      }));
      setWeeklyData(weekly);

      // Waste Type Distribution
      const wasteTypes = {};
      requests.forEach(r => {
        const type = r.wasteType || "mixed";
        wasteTypes[type] = (wasteTypes[type] || 0) + 1;
      });

      const wasteColors = {
        skin: "#F59E0B",
        bones: "#3B82F6",
        offal: "#EF4444",
        mixed: "#8B5CF6",
        other: "#6B7280",
      };

      const wasteData = Object.entries(wasteTypes).map(([name, count]) => ({
        name: name.charAt(0).toUpperCase() + name.slice(1),
        value: Math.round((count / total) * 100),
        color: wasteColors[name.toLowerCase()] || "#6B7280",
      }));
      setWasteTypeData(wasteData);

      // Area Data
      const areas = {};
      requests.forEach(r => {
        const area = r.area || r.location?.split(",")[0]?.trim() || "Unknown";
        areas[area] = (areas[area] || 0) + 1;
      });

      const areaColors = ["#10B981", "#3B82F6", "#F59E0B", "#8B5CF6", "#EF4444", "#EC4899"];
      const areaList = Object.entries(areas).map(([name, count], index) => ({
        name,
        value: Math.round((count / total) * 100),
        color: areaColors[index % areaColors.length],
        total: count,
      }));
      setAreaData(areaList);

      // Area Performance
      const performanceList = areaList.map(area => ({
        area: area.name,
        total: area.total,
        completed: Math.round(area.total * 0.94),
        rate: "94%",
        responseTime: `${Math.floor(Math.random() * 30) + 30} min`,
        performance: area.value > 15 ? "Excellent" : "Good",
      }));
      setAreaPerformance(performanceList);

    } catch (error) {
      console.error("Error fetching analytics:", error);
    }
    setLoading(false);
  }

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
              <h2 className="text-2xl font-bold text-gray-800">Reports & Analytics</h2>
              <p className="text-gray-500 text-sm mt-1">
                Comprehensive insights and performance metrics
              </p>
            </div>
            <button className="bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-xl text-sm font-medium transition-colors">
              📊 Export Report
            </button>
          </div>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <div className="bg-white rounded-xl p-5 shadow-sm border border-gray-100">
            <p className="text-xs text-gray-400 font-medium uppercase">Total Pickups</p>
            <p className="text-2xl font-bold text-gray-800">{stats.total}</p>
            <p className="text-xs text-emerald-600">+12.5% from last week</p>
          </div>
          <div className="bg-blue-50 rounded-xl p-5 shadow-sm border border-blue-100">
            <p className="text-xs text-blue-500 font-medium uppercase">Completion Rate</p>
            <p className="text-2xl font-bold text-blue-600">{stats.completionRate.toFixed(1)}%</p>
            <p className="text-xs text-blue-600">+2.1% improvement</p>
          </div>
          <div className="bg-emerald-50 rounded-xl p-5 shadow-sm border border-emerald-100">
            <p className="text-xs text-emerald-500 font-medium uppercase">Total Waste (kg)</p>
            <p className="text-2xl font-bold text-emerald-600">{stats.wasteKg.toLocaleString()}</p>
            <p className="text-xs text-emerald-600">Peak season</p>
          </div>
          <div className="bg-yellow-50 rounded-xl p-5 shadow-sm border border-yellow-100">
            <p className="text-xs text-yellow-500 font-medium uppercase">Avg. Response Time</p>
            <p className="text-2xl font-bold text-yellow-600">{stats.responseTime} min</p>
            <p className="text-xs text-yellow-600">-8 min faster</p>
          </div>
        </div>

        {/* Weekly Performance */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 mb-6">
          <h3 className="font-semibold text-gray-800 mb-4">Weekly Performance</h3>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={weeklyData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="day" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Legend />
              <Bar dataKey="completed" fill="#10B981" name="Completed" radius={[4, 4, 0, 0]} />
              <Bar dataKey="cancelled" fill="#EF4444" name="Cancelled" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Two Column: Area Performance + Waste Type */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
          <div className="lg:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <h3 className="font-semibold text-gray-800 mb-4">Area Performance Summary</h3>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100">
                    <th className="text-left px-3 py-2 text-xs font-semibold text-gray-500 uppercase">Area</th>
                    <th className="text-left px-3 py-2 text-xs font-semibold text-gray-500 uppercase">Total</th>
                    <th className="text-left px-3 py-2 text-xs font-semibold text-gray-500 uppercase">Completed</th>
                    <th className="text-left px-3 py-2 text-xs font-semibold text-gray-500 uppercase">Rate</th>
                    <th className="text-left px-3 py-2 text-xs font-semibold text-gray-500 uppercase">Response</th>
                    <th className="text-left px-3 py-2 text-xs font-semibold text-gray-500 uppercase">Performance</th>
                  </tr>
                </thead>
                <tbody>
                  {areaPerformance.map((item, index) => (
                    <tr key={index} className="border-b border-gray-50 hover:bg-gray-50">
                      <td className="px-3 py-2.5 font-medium text-gray-800">{item.area}</td>
                      <td className="px-3 py-2.5 text-gray-600">{item.total}</td>
                      <td className="px-3 py-2.5 text-gray-600">{item.completed}</td>
                      <td className="px-3 py-2.5 text-gray-600">{item.rate}</td>
                      <td className="px-3 py-2.5 text-gray-600">{item.responseTime}</td>
                      <td className="px-3 py-2.5">
                        <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                          item.performance === "Excellent" ? "bg-emerald-100 text-emerald-700" : "bg-blue-100 text-blue-700"
                        }`}>
                          {item.performance}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <h3 className="font-semibold text-gray-800 mb-4">Waste Type Distribution</h3>
            <ResponsiveContainer width="100%" height={220}>
              <PieChart>
                <Pie
                  data={wasteTypeData}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={80}
                  dataKey="value"
                  label={({ name, value }) => `${name}: ${value}%`}
                  labelLine={false}
                >
                  {wasteTypeData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
            <div className="flex justify-center gap-4 mt-2 flex-wrap">
              {wasteTypeData.map((entry) => (
                <div key={entry.name} className="flex items-center gap-1.5">
                  <div className="w-3 h-3 rounded-full" style={{ backgroundColor: entry.color }} />
                  <span className="text-xs text-gray-500">{entry.name}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Pickups by Area */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
          <h3 className="font-semibold text-gray-800 mb-4">Pickups by Area</h3>
          <div className="flex flex-wrap gap-4 mb-4">
            {areaData.map((item) => (
              <div key={item.name} className="flex items-center gap-2">
                <div className="w-3 h-3 rounded-full" style={{ backgroundColor: item.color }} />
                <span className="text-sm text-gray-600">{item.name}:</span>
                <span className="text-sm font-semibold text-gray-800">{item.value}%</span>
              </div>
            ))}
          </div>
          <div className="h-4 w-full bg-gray-200 rounded-full overflow-hidden flex">
            {areaData.map((item) => (
              <div
                key={item.name}
                className="h-full"
                style={{ width: `${item.value}%`, backgroundColor: item.color }}
              />
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}