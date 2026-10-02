import { useEffect, useState } from "react";
import { collection, getDocs, addDoc, serverTimestamp } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";

const priorityColors = {
  high:   "bg-red-100 text-red-700",
  medium: "bg-yellow-100 text-yellow-700",
  low:    "bg-green-100 text-green-700",
};

export default function Areas() {
  const [areas, setAreas]       = useState([]);
  const [loading, setLoading]   = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving]     = useState(false);
  const [form, setForm] = useState({
    areaName: "", district: "", population: "",
    houses: "", density: "", priority: "medium",
  });

  useEffect(() => { fetchAreas(); }, []);

  async function fetchAreas() {
    setLoading(true);
    const snap = await getDocs(collection(db, "areas"));
    setAreas(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    setLoading(false);
  }

  async function handleAddArea(e) {
    e.preventDefault();
    setSaving(true);
    await addDoc(collection(db, "areas"), {
      areaName:   form.areaName,
      district:   form.district,
      population: Number(form.population),
      houses:     Number(form.houses),
      density:    Number(form.density),
      priority:   form.priority,
      createdAt:  serverTimestamp(),
    });
    setForm({ areaName:"", district:"", population:"", houses:"", density:"", priority:"medium" });
    setShowForm(false);
    fetchAreas();
    setSaving(false);
  }

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8 min-h-screen bg-gray-50">

        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h2 className="text-2xl font-bold text-gray-800">Areas</h2>
            <p className="text-gray-500 text-sm mt-1">
              Manage municipal zones and priorities
            </p>
          </div>
          <button
            onClick={() => setShowForm(!showForm)}
            className="bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-xl text-sm font-medium transition-colors"
          >
            {showForm ? "✕ Cancel" : "+ Add Area"}
          </button>
        </div>

        {/* Add Area Form */}
        {showForm && (
          <div className="bg-white rounded-2xl shadow-sm p-6 mb-6">
            <h3 className="font-semibold text-gray-800 mb-4">Add New Area</h3>
            <form onSubmit={handleAddArea} className="grid grid-cols-3 gap-4">
              {[
                { label:"Area Name",  key:"areaName",   placeholder:"Abbottabad City" },
                { label:"District",   key:"district",   placeholder:"Abbottabad" },
                { label:"Population", key:"population", placeholder:"50000" },
                { label:"Houses",     key:"houses",     placeholder:"8000" },
                { label:"Density",    key:"density",    placeholder:"1200" },
              ].map(field => (
                <div key={field.key}>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    {field.label}
                  </label>
                  <input
                    type={field.key === "areaName" || field.key === "district" ? "text" : "number"}
                    required
                    placeholder={field.placeholder}
                    value={form[field.key]}
                    onChange={e => setForm({...form, [field.key]: e.target.value})}
                    className="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                  />
                </div>
              ))}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Priority
                </label>
                <select
                  value={form.priority}
                  onChange={e => setForm({...form, priority: e.target.value})}
                  className="w-full px-4 py-2.5 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                >
                  <option value="high">High</option>
                  <option value="medium">Medium</option>
                  <option value="low">Low</option>
                </select>
              </div>
              <div className="flex items-end col-span-3">
                <button
                  type="submit"
                  disabled={saving}
                  className="bg-emerald-500 hover:bg-emerald-600 text-white px-8 py-2.5 rounded-xl text-sm font-medium transition-colors disabled:opacity-50"
                >
                  {saving ? "Saving..." : "Save Area"}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Areas Table */}
        {loading ? (
          <div className="flex items-center justify-center h-40">
            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-emerald-500"></div>
          </div>
        ) : areas.length === 0 ? (
          <div className="bg-white rounded-2xl p-12 text-center shadow-sm">
            <p className="text-4xl mb-3">🗺️</p>
            <p className="text-gray-500">No areas added yet</p>
            <p className="text-gray-400 text-sm mt-1">
              Click "Add Area" to add your first zone
            </p>
          </div>
        ) : (
          <div className="bg-white rounded-2xl shadow-sm overflow-hidden">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>
                  {["Area Name","District","Population","Houses","Density","Priority"].map(h => (
                    <th key={h} className="text-left px-6 py-4 text-xs font-semibold text-gray-500 uppercase">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {areas.map(area => (
                  <tr key={area.id} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 text-sm font-medium text-gray-800">
                      {area.areaName}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {area.district}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {area.population?.toLocaleString()}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {area.houses?.toLocaleString()}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {area.density}
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold capitalize ${priorityColors[area.priority] || "bg-gray-100 text-gray-600"}`}>
                        {area.priority}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </main>
    </div>
  );
}