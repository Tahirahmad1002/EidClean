// 📁 src/pages/Reports.jsx

import { useEffect, useState } from "react";
import { collection, getDocs, doc, updateDoc, serverTimestamp } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";

const statusColors = {
  pending: "bg-yellow-100 text-yellow-700",
  assigned: "bg-blue-100 text-blue-700",
  completed: "bg-green-100 text-green-700",
};

const statusIcons = {
  pending: "⏳",
  assigned: "🚛",
  completed: "✅",
};

export default function Reports() {
  const [requests, setRequests] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("all");
  const [search, setSearch] = useState("");
  
  // ✅ NEW: Photo modal state
  const [selectedPhoto, setSelectedPhoto] = useState(null);

  useEffect(() => {
    fetchRequests();
    fetchDrivers();
  }, []);

  async function fetchRequests() {
    setLoading(true);
    const snap = await getDocs(collection(db, "pickupRequests"));
    setRequests(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    setLoading(false);
  }

  async function fetchDrivers() {
    const snap = await getDocs(collection(db, "drivers"));
    setDrivers(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  }

  async function updateStatus(id, newStatus) {
    await updateDoc(doc(db, "pickupRequests", id), { status: newStatus });
    fetchRequests();
  }

  async function assignDriver(requestId, driverId, driverName) {
    await updateDoc(doc(db, "pickupRequests", requestId), {
      status: "assigned",
      driverId: driverId,
      driverName: driverName,
      assignedAt: serverTimestamp(),
    });
    fetchRequests();
  }

  const filtered = requests.filter(r => {
    const matchesFilter = filter === "all" || r.status === filter;
    const matchesSearch = r.id?.toLowerCase().includes(search.toLowerCase()) ||
                          r.location?.toLowerCase().includes(search.toLowerCase()) ||
                          r.userName?.toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const getStatusCount = (status) => {
    return requests.filter(r => r.status === status).length;
  };

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8 min-h-screen bg-gray-50">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-gray-800">Pickup Management</h2>
              <p className="text-gray-500 text-sm mt-1">
                Manage all waste pickup requests and assignments
              </p>
            </div>
            <button
              onClick={fetchRequests}
              className="bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-xl text-sm font-medium transition-colors"
            >
              🔄 Refresh
            </button>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-4 gap-4 mb-6">
          <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 text-center">
            <p className="text-2xl font-bold text-gray-800">{requests.length}</p>
            <p className="text-xs text-gray-500">Total</p>
          </div>
          <div className="bg-yellow-50 rounded-xl p-4 shadow-sm border border-yellow-100 text-center">
            <p className="text-2xl font-bold text-yellow-600">{getStatusCount("pending")}</p>
            <p className="text-xs text-yellow-600">Pending</p>
          </div>
          <div className="bg-blue-50 rounded-xl p-4 shadow-sm border border-blue-100 text-center">
            <p className="text-2xl font-bold text-blue-600">{getStatusCount("assigned")}</p>
            <p className="text-xs text-blue-600">Assigned</p>
          </div>
          <div className="bg-green-50 rounded-xl p-4 shadow-sm border border-green-100 text-center">
            <p className="text-2xl font-bold text-green-600">{getStatusCount("completed")}</p>
            <p className="text-xs text-green-600">Completed</p>
          </div>
        </div>

        {/* Search + Filters */}
        <div className="flex flex-wrap items-center gap-4 mb-6">
          <div className="flex-1 min-w-[200px]">
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">🔍</span>
              <input
                type="text"
                placeholder="Search requests..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
              />
            </div>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-500">Status Filter:</span>
            {["all", "pending", "assigned", "completed"].map((f) => (
              <button
                key={f}
                onClick={() => setFilter(f)}
                className={`px-4 py-1.5 rounded-full text-xs font-medium capitalize transition-colors ${
                  filter === f
                    ? "bg-emerald-500 text-white"
                    : "bg-white text-gray-600 hover:bg-gray-100 border border-gray-200"
                }`}
              >
                {f === "all" ? "All Status" : f}
              </button>
            ))}
          </div>
        </div>

        {/* Requests List */}
        {loading ? (
          <div className="flex items-center justify-center h-40">
            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-emerald-500"></div>
          </div>
        ) : filtered.length === 0 ? (
          <div className="bg-white rounded-2xl p-12 text-center shadow-sm border border-gray-100">
            <p className="text-4xl mb-3">📭</p>
            <p className="text-gray-500">No requests found</p>
          </div>
        ) : (
          <div className="space-y-4">
            {filtered.map((req) => (
              <div key={req.id} className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-4">
                    <span className="text-sm font-mono text-gray-400 bg-gray-50 px-3 py-1 rounded-lg">
                      PK-{req.id.slice(0, 6).toUpperCase()}
                    </span>
                    <span className={`px-3 py-1 rounded-full text-xs font-semibold capitalize flex items-center gap-1 ${statusColors[req.status] || "bg-gray-100 text-gray-600"}`}>
                      {statusIcons[req.status]} {req.status || "Pending"}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    {req.status === "assigned" && req.driverName && (
                      <span className="text-xs text-gray-500">👤 {req.driverName}</span>
                    )}
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {/* Customer */}
                  <div>
                    <p className="text-xs text-gray-400 font-medium uppercase tracking-wider">Customer</p>
                    <p className="font-medium text-gray-800">{req.userName || "Unknown"}</p>
                    <p className="text-sm text-gray-500">{req.userPhone || "No phone"}</p>
                    <p className="text-sm text-gray-500">Animals: {req.animals || 1}</p>
                  </div>

                  {/* Location */}
                  <div>
                    <p className="text-xs text-gray-400 font-medium uppercase tracking-wider">Location</p>
                    <p className="font-medium text-gray-800">{req.area || "Jinnahabad"}</p>
                    <p className="text-sm text-gray-500">{req.location || "No address"}</p>
                    <p className="text-sm text-gray-500">Waste: {req.wasteType || "Mixed"}</p>
                  </div>

                  {/* Schedule */}
                  <div>
                    <p className="text-xs text-gray-400 font-medium uppercase tracking-wider">Schedule</p>
                    <p className="font-medium text-gray-800">
                      {req.createdAt?.toDate?.().toLocaleDateString() || "2026-04-22"}
                    </p>
                    <p className="text-sm text-gray-500">{req.timeSlot || "9-12 AM"}</p>
                  </div>
                </div>

                {/* ✅ NEW: Photo Display */}
                {req.photoBase64 && (
                  <div className="mt-4 pt-4 border-t border-gray-100">
                    <p className="text-xs text-gray-400 font-medium uppercase tracking-wider mb-2">
                      📸 Pickup Photo Evidence
                    </p>
                    <div className="flex items-center gap-3">
                      <img
                        src={req.photoBase64}
                        alt="Pickup evidence"
                        className="w-20 h-20 object-cover rounded-lg border-2 border-emerald-500 cursor-pointer hover:opacity-80 transition-opacity"
                        onClick={() => setSelectedPhoto(req.photoBase64)}
                      />
                      <div className="text-xs text-gray-500">
                        <p>✅ Photo captured by driver</p>
                        <p>
                          Size: {req.photoSize ? `${(req.photoSize / 1024).toFixed(1)} KB` : 'N/A'}
                        </p>
                        <button
                          onClick={() => setSelectedPhoto(req.photoBase64)}
                          className="text-emerald-600 hover:text-emerald-800 font-medium mt-1"
                        >
                          View Full Size →
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {/* Actions */}
                <div className="flex items-center gap-3 mt-4 pt-4 border-t border-gray-100">
                  {req.status === "pending" && (
                    <select
                      onChange={(e) => {
                        const [id, name] = e.target.value.split("|");
                        if (id) assignDriver(req.id, id, name);
                      }}
                      className="text-sm border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-emerald-500"
                      defaultValue=""
                    >
                      <option value="" disabled>Assign Driver</option>
                      {drivers.map(d => (
                        <option key={d.id} value={`${d.uid}|${d.name}`}>
                          {d.name}
                        </option>
                      ))}
                    </select>
                  )}

                  {req.status === "assigned" && (
                    <>
                      <button className="text-emerald-600 hover:text-emerald-800 text-sm font-medium">
                        📍 Track
                      </button>
                      <button className="text-blue-600 hover:text-blue-800 text-sm font-medium">
                        🔄 Reassign
                      </button>
                      <button className="text-gray-600 hover:text-gray-800 text-sm font-medium">
                        📞 Contact
                      </button>
                    </>
                  )}

                  {req.status === "assigned" && (
                    <button
                      onClick={() => updateStatus(req.id, "completed")}
                      className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                    >
                      ✅ Complete
                    </button>
                  )}

                  {req.status === "completed" && (
                    <span className="text-green-600 text-sm font-medium">✅ Done</span>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* ✅ NEW: Full-Size Photo Modal */}
        {selectedPhoto && (
          <div
            className="fixed inset-0 bg-black bg-opacity-80 z-50 flex items-center justify-center p-4"
            onClick={() => setSelectedPhoto(null)}
          >
            <div className="relative max-w-4xl max-h-full">
              <button
                onClick={() => setSelectedPhoto(null)}
                className="absolute -top-10 right-0 text-white text-2xl hover:text-gray-300"
              >
                ✕ Close
              </button>
              <img
                src={selectedPhoto}
                alt="Full size pickup"
                className="max-w-full max-h-[80vh] rounded-lg"
                onClick={(e) => e.stopPropagation()}
              />
              <p className="text-white text-center mt-4 text-sm">
                Driver Photo Evidence — Click outside to close
              </p>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}