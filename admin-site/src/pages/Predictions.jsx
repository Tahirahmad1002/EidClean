// 📁 src/pages/Predictions.jsx

import { useState } from "react";
import { collection, addDoc, serverTimestamp } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";

export default function Predictions() {
  const [form, setForm] = useState({
    population: "",
    houses: "",
    density: "",
  });
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  // Dummy AI predictions data (will be replaced with real ML model)
  const aiPredictions = [
    { area: "Jinnahabad", demand: "High", trucks: 3, workers: 6, bins: 12 },
    { area: "Nawanshehr", demand: "Medium", trucks: 2, workers: 4, bins: 8 },
    { area: "Mirpur", demand: "High", trucks: 2, workers: 5, bins: 10 },
    { area: "Cantt Area", demand: "Low", trucks: 1, workers: 3, bins: 6 },
    { area: "Supply Bazar", demand: "High", trucks: 3, workers: 7, bins: 14 },
    { area: "Havelian Road", demand: "Low", trucks: 1, workers: 2, bins: 5 },
  ];

  // Local prediction logic (placeholder until ML backend is ready)
  function runPrediction() {
    const pop = Number(form.population);
    const houses = Number(form.houses);
    const density = Number(form.density);

    let cluster, cleaners, bins, trucks, priority;

    if (density > 2000 || pop > 80000) {
      cluster = 1;
      priority = "High";
      cleaners = Math.ceil(pop / 3000);
      bins = Math.ceil(houses / 120);
      trucks = Math.ceil(houses / 800);
    } else if (density > 1000 || pop > 30000) {
      cluster = 2;
      priority = "Medium";
      cleaners = Math.ceil(pop / 4000);
      bins = Math.ceil(houses / 160);
      trucks = Math.ceil(houses / 1000);
    } else {
      cluster = 3;
      priority = "Low";
      cleaners = Math.ceil(pop / 5000);
      bins = Math.ceil(houses / 200);
      trucks = Math.ceil(houses / 1200);
    }

    return { cluster, cleaners, bins, trucks, priority };
  }

  async function handlePredict(e) {
    e.preventDefault();
    setLoading(true);
    const prediction = runPrediction();
    setResult(prediction);

    await addDoc(collection(db, "predictions"), {
      ...form,
      ...prediction,
      createdAt: serverTimestamp(),
    });
    setLoading(false);
  }

  const priorityColor = {
    High: "text-red-600 bg-red-50",
    Medium: "text-yellow-600 bg-yellow-50",
    Low: "text-green-600 bg-green-50",
  };

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8 min-h-screen bg-gray-50">
        {/* Header */}
        <div className="mb-8">
          <h2 className="text-2xl font-bold text-gray-800">AI Resource Planning</h2>
          <p className="text-gray-500 text-sm mt-1">
            AI predictions for Abbottabad areas — override as needed
          </p>
        </div>

        {/* Info Box */}
        <div className="bg-blue-50 border border-blue-200 rounded-2xl p-4 mb-6">
          <p className="text-sm text-blue-700">
            💡 How it works: The AI model analyzes population density, historical Eid-ul-Adha data, and area size for Abbottabad to predict optimal resource allocation. You can override any prediction and apply your own plan.
          </p>
        </div>

        {/* AI Predictions Table */}
        <div className="bg-white rounded-2xl shadow-sm overflow-hidden mb-6">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-100">
                <tr>
                  <th className="text-left px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Area</th>
                  <th className="text-left px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Demand</th>
                  <th className="text-left px-6 py-4 text-xs font-semibold text-gray-500 uppercase">AI → Your Plan</th>
                  <th className="text-left px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Trucks</th>
                  <th className="text-left px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Workers</th>
                  <th className="text-left px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Bins</th>
                  <th className="text-left px-6 py-4 text-xs font-semibold text-gray-500 uppercase">Override</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-50">
                {aiPredictions.map((item, index) => (
                  <tr key={index} className="hover:bg-gray-50 transition-colors">
                    <td className="px-6 py-4 text-sm font-medium text-gray-800">{item.area}</td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                        item.demand === "High" ? "bg-red-100 text-red-700" :
                        item.demand === "Medium" ? "bg-yellow-100 text-yellow-700" :
                        "bg-green-100 text-green-700"
                      }`}>
                        {item.demand}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <span className="text-xs bg-emerald-50 text-emerald-700 px-3 py-1 rounded-full font-medium">
                        AI Plan
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">{item.trucks}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{item.workers}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{item.bins}</td>
                    <td className="px-6 py-4">
                      <button className="text-emerald-600 hover:text-emerald-800 font-medium text-sm">
                        ☑ Override
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-4">
          <button className="bg-emerald-500 hover:bg-emerald-600 text-white px-8 py-3 rounded-xl text-sm font-medium transition-colors">
            Apply Full AI Plan
          </button>
          <button className="bg-gray-200 hover:bg-gray-300 text-gray-700 px-8 py-3 rounded-xl text-sm font-medium transition-colors">
            Save & Close
          </button>
        </div>

        {/* Bottom Section: Manual Prediction (for testing) */}
        <div className="mt-8 border-t border-gray-200 pt-6">
          <h3 className="text-sm font-semibold text-gray-600 mb-4">Manual Area Prediction (Testing)</h3>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div className="bg-white rounded-2xl shadow-sm p-6">
              <form onSubmit={handlePredict} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Population</label>
                  <input
                    type="number"
                    required
                    placeholder="e.g. 50000"
                    value={form.population}
                    onChange={(e) => setForm({ ...form, population: e.target.value })}
                    className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Houses</label>
                  <input
                    type="number"
                    required
                    placeholder="e.g. 8000"
                    value={form.houses}
                    onChange={(e) => setForm({ ...form, houses: e.target.value })}
                    className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">Density (per km²)</label>
                  <input
                    type="number"
                    required
                    placeholder="e.g. 1200"
                    value={form.density}
                    onChange={(e) => setForm({ ...form, density: e.target.value })}
                    className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500 text-sm"
                  />
                </div>
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full bg-emerald-500 hover:bg-emerald-600 text-white font-semibold py-3 rounded-xl transition-colors disabled:opacity-50"
                >
                  {loading ? "Predicting..." : "🤖 Test Prediction"}
                </button>
              </form>
            </div>

            {result && (
              <div className="bg-white rounded-2xl shadow-sm p-6">
                <h4 className="font-semibold text-gray-800 mb-4">Prediction Result</h4>
                <div className={`rounded-2xl p-4 text-center ${priorityColor[result.priority]}`}>
                  <p className="text-xs font-medium uppercase tracking-wide mb-1">Priority Level</p>
                  <p className="text-3xl font-bold">{result.priority}</p>
                </div>
                <div className="mt-4 space-y-3">
                  <div className="flex justify-between p-3 bg-gray-50 rounded-xl">
                    <span className="text-sm text-gray-600">Cluster</span>
                    <span className="font-bold text-gray-800">Cluster {result.cluster}</span>
                  </div>
                  <div className="flex justify-between p-3 bg-gray-50 rounded-xl">
                    <span className="text-sm text-gray-600">👷 Cleaners Needed</span>
                    <span className="font-bold text-gray-800">{result.cleaners}</span>
                  </div>
                  <div className="flex justify-between p-3 bg-gray-50 rounded-xl">
                    <span className="text-sm text-gray-600">🗑️ Bins Needed</span>
                    <span className="font-bold text-gray-800">{result.bins}</span>
                  </div>
                  <div className="flex justify-between p-3 bg-gray-50 rounded-xl">
                    <span className="text-sm text-gray-600">🚛 Trucks Needed</span>
                    <span className="font-bold text-gray-800">{result.trucks}</span>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}