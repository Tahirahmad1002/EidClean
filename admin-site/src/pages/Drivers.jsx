// 📁 src/pages/Drivers.jsx

import { useEffect, useState } from "react";
import { collection, getDocs, addDoc, setDoc, updateDoc, doc, serverTimestamp } from "firebase/firestore";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { auth, db } from "../firebase";
import Sidebar from "../components/Sidebar";


export default function Drivers() {
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [formLoading, setFormLoading] = useState(false);
  const [error, setError] = useState("");
  const [form, setForm] = useState({
    name: "", email: "", password: "", phone: "", vehicleNumber: "",
  });

  useEffect(() => { fetchDrivers(); }, []);

  async function fetchDrivers() {
    setLoading(true);
    const snap = await getDocs(collection(db, "drivers"));
    setDrivers(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    setLoading(false);
  }

  async function handleAddDriver(e) {
    e.preventDefault();
    setFormLoading(true);
    setError("");
    try {
      const cred = await createUserWithEmailAndPassword(
        auth, form.email, form.password
      );

      await addDoc(collection(db, "users"), {
        uid: cred.user.uid,
        name: form.name,
        email: form.email,
        phone: form.phone,
        role: "driver",
        createdAt: serverTimestamp(),
      });

      await setDoc(doc(db, "drivers", cred.user.uid), {
        uid: cred.user.uid,
        name: form.name,
        phone: form.phone,
        vehicleNumber: form.vehicleNumber,
        status: "available",
        createdAt: serverTimestamp(),
      });
      await setDoc(doc(db, "users", cred.user.uid), {
        uid: cred.user.uid,
        name: form.name,
        email: form.email,           // ← make sure form has email
        phone: form.phone,
        role: "driver",              // ← set role to driver
        createdAt: serverTimestamp(),
     });

      setForm({ name:"", email:"", password:"", phone:"", vehicleNumber:"" });
      setShowForm(false);
      fetchDrivers();
    } catch (err) {
      setError(err.message);
    }
    setFormLoading(false);
  }

  async function toggleStatus(driver) {
    const newStatus = driver.status === "available" ? "busy" : "available";
    await updateDoc(doc(db, "drivers", driver.id), { status: newStatus });
    fetchDrivers();
  }

  const getInitials = (name) => {
    if (!name) return "??";
    return name.split(' ').map(word => word[0]).join('').toUpperCase().slice(0, 2);
  };

  const getStatusColor = (status) => {
    if (status === "available" || status === "Active") return "bg-green-100 text-green-700";
    if (status === "busy") return "bg-red-100 text-red-700";
    if (status === "Break") return "bg-yellow-100 text-yellow-700";
    return "bg-gray-100 text-gray-600";
  };

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8 min-h-screen bg-gray-50">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h2 className="text-2xl font-bold text-gray-800">Driver Management</h2>
            <p className="text-gray-500 text-sm mt-1">
              Monitor drivers — view completed pickups, uploaded photos & user feedback
            </p>
          </div>
          <button
            onClick={() => setShowForm(!showForm)}
            className="bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-xl text-sm font-medium transition-colors"
          >
            {showForm ? "✕ Cancel" : "+ Add Driver"}
          </button>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
          <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
            <p className="text-xs text-gray-400 font-medium uppercase tracking-wider">Active Drivers</p>
            <p className="text-2xl font-bold text-gray-800">{drivers.filter(d => d.status === "available" || d.status === "Active").length}</p>
          </div>
          <div className="bg-blue-50 rounded-xl p-4 shadow-sm border border-blue-100">
            <p className="text-xs text-blue-500 font-medium uppercase tracking-wider">Assigned</p>
            <p className="text-2xl font-bold text-blue-600">19</p>
          </div>
          <div className="bg-emerald-50 rounded-xl p-4 shadow-sm border border-emerald-100">
            <p className="text-xs text-emerald-500 font-medium uppercase tracking-wider">Completed Today</p>
            <p className="text-2xl font-bold text-emerald-600">51</p>
          </div>
          <div className="bg-yellow-50 rounded-xl p-4 shadow-sm border border-yellow-100">
            <p className="text-xs text-yellow-500 font-medium uppercase tracking-wider">Avg. Rating</p>
            <p className="text-2xl font-bold text-yellow-600">4.7</p>
            <p className="text-xs text-gray-400">across all drivers</p>
          </div>
        </div>

        {/* Add Driver Form */}
        {showForm && (
          <div className="bg-white rounded-2xl shadow-sm p-6 mb-6 border border-gray-100">
            <h3 className="font-semibold text-gray-800 mb-4">Add New Driver</h3>
            <form onSubmit={handleAddDriver} className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Full Name</label>
                <input
                  type="text"
                  required
                  placeholder="Ahmad Ali"
                  value={form.name}
                  onChange={e => setForm({...form, name: e.target.value})}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                <input
                  type="email"
                  required
                  placeholder="driver@eidclean.com"
                  value={form.email}
                  onChange={e => setForm({...form, email: e.target.value})}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
                <input
                  type="password"
                  required
                  placeholder="minimum 6 characters"
                  value={form.password}
                  onChange={e => setForm({...form, password: e.target.value})}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Phone</label>
                <input
                  type="text"
                  required
                  placeholder="03001234567"
                  value={form.phone}
                  onChange={e => setForm({...form, phone: e.target.value})}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Vehicle Number</label>
                <input
                  type="text"
                  required
                  placeholder="ABC-123"
                  value={form.vehicleNumber}
                  onChange={e => setForm({...form, vehicleNumber: e.target.value})}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                />
              </div>
              <div className="flex items-end">
                {error && <p className="text-red-500 text-xs mb-1">{error}</p>}
                <button
                  type="submit"
                  disabled={formLoading}
                  className="w-full bg-emerald-500 hover:bg-emerald-600 text-white py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50"
                >
                  {formLoading ? "Adding..." : "Add Driver"}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Drivers List */}
        {loading ? (
          <div className="flex items-center justify-center h-40">
            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-emerald-500"></div>
          </div>
        ) : drivers.length === 0 ? (
          <div className="bg-white rounded-2xl p-12 text-center shadow-sm border border-gray-100">
            <p className="text-4xl mb-3">🚛</p>
            <p className="text-gray-500">No drivers added yet</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {drivers.map((driver) => (
              <div key={driver.id} className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100 hover:shadow-md transition-shadow">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div className="w-12 h-12 rounded-xl bg-emerald-100 flex items-center justify-center text-emerald-700 font-bold text-lg">
                      {getInitials(driver.name)}
                    </div>
                    <div>
                      <p className="font-semibold text-gray-800">{driver.name || "Unknown"}</p>
                      <p className="text-sm text-gray-500">WK-{driver.id?.slice(0, 4).toUpperCase() || "001"}</p>
                      <p className="text-sm text-gray-500">{driver.phone || "+92 300 1234567"}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className={`px-3 py-1 rounded-full text-xs font-semibold capitalize ${getStatusColor(driver.status)}`}>
                      {driver.status === "available" ? "Active" : driver.status || "Active"}
                    </span>
                    <button
                      onClick={() => toggleStatus(driver)}
                      className={`text-xs px-3 py-1 rounded-lg transition-colors ${
                        driver.status === "available"
                          ? "bg-gray-200 hover:bg-gray-300 text-gray-700"
                          : "bg-emerald-100 hover:bg-emerald-200 text-emerald-700"
                      }`}
                    >
                      {driver.status === "available" ? "Set Busy" : "Set Active"}
                    </button>
                  </div>
                </div>

                <div className="grid grid-cols-3 gap-2 mb-3 text-sm">
                  <div>
                    <p className="text-xs text-gray-400">Area</p>
                    <p className="font-medium text-gray-700">Jinnahabad</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-400">Pickups</p>
                    <p className="font-medium text-gray-700">5</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-400">Status</p>
                    <p className="font-medium text-emerald-600">Assigned</p>
                  </div>
                </div>

                <div className="flex items-center gap-2 pt-3 border-t border-gray-100">
                  <button className="bg-blue-500 hover:bg-blue-600 text-white text-xs px-3 py-1.5 rounded-lg transition-colors">
                    📍 Track
                  </button>
                  <button className="bg-emerald-500 hover:bg-emerald-600 text-white text-xs px-3 py-1.5 rounded-lg transition-colors">
                    📋 Assign
                  </button>
                  <button className="bg-gray-200 hover:bg-gray-300 text-gray-700 text-xs px-3 py-1.5 rounded-lg transition-colors">
                    👁️ View Work
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
