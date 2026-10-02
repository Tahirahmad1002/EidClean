// 📁 src/pages/NGODashboard.jsx

import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import Sidebar from "../components/Sidebar";

export default function NGODashboard() {
  const navigate = useNavigate();

  // ✅ Check if NGO is logged in (dummy check)
  useEffect(() => {
    const ngoUser = localStorage.getItem("ngoUser");
    if (!ngoUser) {
      navigate("/ngo-login");
    }
  }, [navigate]);

  // Get user info from localStorage
  const ngoUser = JSON.parse(localStorage.getItem("ngoUser") || "{}");

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8 min-h-screen bg-gray-50">
        {/* Header */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gray-800">
            Welcome, {ngoUser?.name || "NGO Admin"}! 🤲
          </h2>
          <p className="text-gray-500 text-sm mt-1">
            Abbottabad Meat Donation Network — Eid ul Adha Operations
          </p>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <p className="text-sm text-gray-500 font-medium">Total Donations</p>
            <p className="text-3xl font-bold text-gray-800">2,450</p>
            <p className="text-xs text-emerald-600">+15% from last week</p>
          </div>
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <p className="text-sm text-gray-500 font-medium">Meat Distributed</p>
            <p className="text-3xl font-bold text-blue-600">1,850 kg</p>
            <p className="text-xs text-blue-600">+8% from last week</p>
          </div>
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <p className="text-sm text-gray-500 font-medium">Families Served</p>
            <p className="text-3xl font-bold text-emerald-600">1,247</p>
            <p className="text-xs text-emerald-600">+12% from last week</p>
          </div>
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <p className="text-sm text-gray-500 font-medium">Active Donations</p>
            <p className="text-3xl font-bold text-yellow-600">45</p>
            <p className="text-xs text-yellow-600">Pending processing</p>
          </div>
        </div>

        {/* Two Column Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Donation Requests */}
          <div className="lg:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <h3 className="font-semibold text-gray-800 mb-4">Recent Donation Requests</h3>
            <div className="space-y-3">
              {[
                { name: "Ahmed Khan", amount: "50 kg", status: "Pending", location: "Jinnahabad" },
                { name: "Fatima Ali", amount: "30 kg", status: "In Progress", location: "Nawanshehr" },
                { name: "Usman Tariq", amount: "20 kg", status: "Completed", location: "Mirpur" },
                { name: "Hassan Malik", amount: "40 kg", status: "Pending", location: "Supply Bazar" },
              ].map((item, i) => (
                <div key={i} className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                  <div>
                    <p className="font-medium text-gray-800">{item.name}</p>
                    <p className="text-sm text-gray-500">{item.location}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-gray-800">{item.amount}</p>
                    <span className={`text-xs px-2 py-1 rounded-full ${
                      item.status === "Pending" ? "bg-yellow-100 text-yellow-700" :
                      item.status === "In Progress" ? "bg-blue-100 text-blue-700" :
                      "bg-green-100 text-green-700"
                    }`}>
                      {item.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Quick Stats */}
          <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
            <h3 className="font-semibold text-gray-800 mb-4">Quick Stats</h3>
            <div className="space-y-4">
              <div className="p-3 bg-blue-50 rounded-xl">
                <p className="text-xs text-blue-600 font-medium">Total NGOs Registered</p>
                <p className="text-2xl font-bold text-blue-700">12</p>
              </div>
              <div className="p-3 bg-emerald-50 rounded-xl">
                <p className="text-xs text-emerald-600 font-medium">Meat Donated</p>
                <p className="text-2xl font-bold text-emerald-700">2,450 kg</p>
              </div>
              <div className="p-3 bg-yellow-50 rounded-xl">
                <p className="text-xs text-yellow-600 font-medium">Families Reached</p>
                <p className="text-2xl font-bold text-yellow-700">1,247</p>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}