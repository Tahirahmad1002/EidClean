// src/pages/Predictions.jsx

import { useState, useEffect, useMemo } from "react";
import { collection, addDoc, serverTimestamp } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";
import {
  AlertCircle,
  Bot,
  Building2,
  CheckCircle2,
  Download,
  Eye,
  EyeOff,
  Filter,
  Gauge,
  HardHat,
  Info,
  Lightbulb,
  Loader2,
  MapPin,
  Moon,
  Search,
  Sparkles,
  Trash2,
  Truck,
  Users,
  X,
} from "lucide-react";
import {
  Badge,
  Button,
  Card,
  CardBody,
  CardHeader,
  Input,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../components/ui";
import { cn } from "../lib/utils";
import { LOCALITIES } from "../data/localities";

// --------------------------------------------------------------------
// Layout constants
// --------------------------------------------------------------------
const shell = "ml-64 min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)]";
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cardBodyPad = "px-4 py-4 sm:px-5 sm:py-5 2xl:px-6 2xl:py-6";
const cellPad = "px-4 py-3 sm:px-5 2xl:px-6 2xl:py-4";
const headPad = "px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3";
const iconTile = "flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br ring-1 2xl:h-10 2xl:w-10";
const iconSize = "h-4 w-4 2xl:h-[18px] 2xl:w-[18px]";
const cardTitle = "text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base";
const cardSub = "text-xs text-slate-500";

const statTones = {
  slate: "border-slate-200/70 from-slate-50 via-white to-white before:bg-slate-300/40 after:via-slate-400/70 hover:shadow-slate-900/10",
  amber: "border-amber-200/70 from-amber-50 via-white to-white before:bg-amber-300/40 after:via-amber-400/70 hover:shadow-amber-900/10",
  sky: "border-sky-200/70 from-sky-50 via-white to-white before:bg-sky-300/40 after:via-sky-400/70 hover:shadow-sky-900/10",
  emerald: "border-emerald-200/70 from-emerald-50 via-white to-white before:bg-emerald-300/40 after:via-emerald-400/70 hover:shadow-emerald-900/10",
};

// --------------------------------------------------------------------
// ML API configuration
// --------------------------------------------------------------------
const ML_API_URL = "https://eidclean-production.up.railway.app";
const API_CHUNK_SIZE = 20;

async function callPredictionAPI(payload) {
  const response = await fetch(`${ML_API_URL}/predict`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    let errorDetail = `API returned status ${response.status}`;
    try {
      const errorBody = await response.json();
      if (errorBody.detail) errorDetail = String(errorBody.detail);
    } catch {
      // Non-JSON response
    }
    throw new Error(errorDetail);
  }
  return response.json();
}

async function predictOne(loc, eidDay) {
  try {
    const prediction = await callPredictionAPI({
      population: loc.population,
      housing: loc.housing,
      participation_rate: loc.participationRate,
      area_type: loc.areaType,
      eid_day: eidDay,
    });
    return { locality: loc, prediction, error: null };
  } catch (err) {
    return { locality: loc, prediction: null, error: err.message };
  }
}

async function predictInChunks(localities, eidDay, onProgress) {
  const results = [];
  for (let i = 0; i < localities.length; i += API_CHUNK_SIZE) {
    const chunk = localities.slice(i, i + API_CHUNK_SIZE);
    const chunkResults = await Promise.all(chunk.map((loc) => predictOne(loc, eidDay)));
    results.push(...chunkResults);
    if (onProgress) onProgress(results.length, localities.length);
  }
  return results;
}

// --------------------------------------------------------------------
// Display helpers
// --------------------------------------------------------------------
function formatWaste(kg) {
  if (kg == null) return "—";
  if (kg < 1000) return `${Math.round(kg)} kg`;
  const tons = kg / 1000;
  if (kg < 100000) return `${Math.round(kg).toLocaleString()} kg (${tons.toFixed(1)} t)`;
  return `${tons.toFixed(1)} t (${Math.round(kg).toLocaleString()} kg)`;
}

function derivePriority(wasteKg) {
  if (wasteKg > 10000) return "High";
  if (wasteKg > 2000) return "Medium";
  return "Low";
}

const priorityVariant = { High: "red", Medium: "yellow", Low: "green" };

// --------------------------------------------------------------------
// Filter helpers
// --------------------------------------------------------------------
const POPULATION_FILTERS = {
  Any: () => true,
  Small: (pop) => pop < 5000,
  Medium: (pop) => pop >= 5000 && pop <= 20000,
  Large: (pop) => pop > 20000,
};

function localityMatchesFilters(loc, areaFilter, populationFilter, searchQuery, showAll) {
  if (!showAll && !loc.featured) return false;
  if (areaFilter !== "All" && loc.areaType !== areaFilter) return false;
  const popTest = POPULATION_FILTERS[populationFilter] || POPULATION_FILTERS.Any;
  if (!popTest(loc.population)) return false;
  if (searchQuery.trim()) {
    const q = searchQuery.trim().toLowerCase();
    if (!loc.name.toLowerCase().includes(q)) return false;
  }
  return true;
}

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

// --------------------------------------------------------------------
// Reusable Segmented Control
// --------------------------------------------------------------------
function Segmented({ options, value, onChange, size = "md" }) {
  const sizeCls = size === "sm" ? "px-2.5 py-1 text-[11px]" : "px-3 py-1.5 text-xs";
  return (
    <div className="inline-flex items-center gap-0.5 rounded-lg bg-slate-100 p-0.5 ring-1 ring-inset ring-slate-200/70">
      {options.map((opt) => (
        <button
          key={opt.value}
          type="button"
          onClick={() => onChange(opt.value)}
          className={cn(
            "rounded-md font-medium transition-all duration-150",
            sizeCls,
            value === opt.value
              ? "bg-white text-emerald-700 shadow-sm ring-1 ring-emerald-200/80"
              : "text-slate-500 hover:text-slate-900"
          )}
        >
          {opt.label}
        </button>
      ))}
    </div>
  );
}

// --------------------------------------------------------------------
// KPI Card
// --------------------------------------------------------------------
function KpiCard({ icon: Icon, label, value, sub, tone }) {
  const tiles = {
    slate: "from-slate-50 to-slate-100 text-slate-600 ring-slate-200",
    amber: "from-amber-50 to-amber-100 text-amber-600 ring-amber-200",
    sky: "from-sky-50 to-sky-100 text-sky-600 ring-sky-200",
    emerald: "from-emerald-50 to-emerald-100 text-emerald-600 ring-emerald-200",
  };
  const key = statTones[tone] ? tone : "slate";
  return (
    <div
      className={cn(
        "group relative isolate overflow-hidden rounded-2xl border bg-gradient-to-br p-4 shadow-card transition-all duration-200 hover:-translate-y-1 hover:shadow-xl sm:p-5",
        "before:absolute before:-right-10 before:-top-12 before:-z-10 before:h-32 before:w-32 before:rounded-full before:blur-2xl",
        "after:absolute after:inset-x-6 after:top-0 after:h-px after:bg-gradient-to-r after:from-transparent after:to-transparent",
        statTones[key]
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-xs font-medium text-slate-500">{label}</p>
          <p className="mt-2 text-2xl font-semibold tabular-nums tracking-tight text-slate-900 2xl:text-[28px]">
            {value}
          </p>
          {sub && <p className="mt-0.5 text-xs text-slate-400">{sub}</p>}
        </div>
        <span className={cn(iconTile, tiles[key])}>
          <Icon className={iconSize} aria-hidden="true" />
        </span>
      </div>
    </div>
  );
}

// --------------------------------------------------------------------
// Main Component
// --------------------------------------------------------------------
export default function Predictions() {
  const [batchEidDay, setBatchEidDay] = useState(1);
  const [areaFilter, setAreaFilter] = useState("All");
  const [populationFilter, setPopulationFilter] = useState("Any");
  const [showAll, setShowAll] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedIds, setSelectedIds] = useState(new Set());
  const [batchResults, setBatchResults] = useState([]);
  const [batchLoading, setBatchLoading] = useState(false);
  const [batchProgress, setBatchProgress] = useState({ done: 0, total: 0 });
  const [batchError, setBatchError] = useState("");
  const [hasRunBatch, setHasRunBatch] = useState(false);

  const [form, setForm] = useState({
    population: "",
    housing: "",
    participation_rate: "",
    area_type: "Rural",
    eid_day: 1,
  });
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const filteredLocalities = useMemo(
    () =>
      LOCALITIES.filter((l) =>
        localityMatchesFilters(l, areaFilter, populationFilter, searchQuery, showAll)
      ),
    [areaFilter, populationFilter, searchQuery, showAll]
  );

  useEffect(() => {
    setSelectedIds(new Set(filteredLocalities.map((l) => l.id)));
  }, [filteredLocalities]);

  const selectedLocalities = useMemo(
    () => filteredLocalities.filter((l) => selectedIds.has(l.id)),
    [filteredLocalities, selectedIds]
  );

  const selectedCount = selectedLocalities.length;
  const totalFilteredCount = filteredLocalities.length;

  function toggleLocality(id) {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function handleSelectAll() {
    setSelectedIds(new Set(filteredLocalities.map((l) => l.id)));
  }

  function handleClearAll() {
    setSelectedIds(new Set());
  }

  function handleResetFilters() {
    setAreaFilter("All");
    setPopulationFilter("Any");
    setSearchQuery("");
  }

  async function handleRunBatch() {
    if (selectedCount === 0) return;

    setBatchLoading(true);
    setBatchError("");
    setBatchResults([]);
    setHasRunBatch(true);
    setBatchProgress({ done: 0, total: selectedCount });

    try {
      const results = await predictInChunks(selectedLocalities, batchEidDay, (done, total) =>
        setBatchProgress({ done, total })
      );
      setBatchResults(results);

      const succeeded = results.filter((r) => !r.error).length;
      try {
        await addDoc(collection(db, "predictions"), {
          type: "batch",
          eid_day: batchEidDay,
          area_filter: areaFilter,
          population_filter: populationFilter,
          search_query: searchQuery,
          showed_all: showAll,
          localities_count: selectedCount,
          succeeded_count: succeeded,
          createdAt: serverTimestamp(),
        });
      } catch (logError) {
        console.warn("Could not log batch run:", logError);
      }
    } catch (err) {
      setBatchError(err.message || "Batch prediction failed.");
    } finally {
      setBatchLoading(false);
      setBatchProgress({ done: 0, total: 0 });
    }
  }

  async function handleManualPredict(e) {
    e.preventDefault();
    setLoading(true);
    setError("");
    setResult(null);

    try {
      const prediction = await callPredictionAPI({
        population: Number(form.population),
        housing: Number(form.housing),
        participation_rate: Number(form.participation_rate),
        area_type: form.area_type,
        eid_day: Number(form.eid_day),
      });
      setResult({ ...prediction, priority: derivePriority(prediction.waste_kg) });

      try {
        await addDoc(collection(db, "predictions"), {
          type: "single",
          input: form,
          output: prediction,
          createdAt: serverTimestamp(),
        });
      } catch (logError) {
        console.warn("Could not log prediction:", logError);
      }
    } catch (err) {
      setError(err.message || "Prediction failed. Please check the API.");
    } finally {
      setLoading(false);
    }
  }

  function handleExportCSV() {
    if (batchResults.length === 0) return;

    const header = [
      "Locality_ID", "Locality_Name", "Population_2023", "Housing_Units",
      "Area_Type", "Participation_Rate", "Eid_Day",
      "Predicted_Waste_KG", "Predicted_Waste_Tons", "Trucks", "Workers", "Bins", "Priority",
    ];

    const rows = batchResults.map((r) => {
      const l = r.locality;
      const p = r.prediction;
      if (r.error || !p) {
        return [l.id, l.name, l.population, l.housing, l.areaType,
                l.participationRate, batchEidDay, "ERROR", "", "", "", "", r.error];
      }
      return [
        l.id, l.name, l.population, l.housing, l.areaType, l.participationRate, batchEidDay,
        p.waste_kg, (p.waste_kg / 1000).toFixed(2),
        p.trucks, p.workers, p.bins, derivePriority(p.waste_kg),
      ];
    });

    const csv = [header, ...rows]
      .map((row) => row.map((cell) => `"${cell}"`).join(","))
      .join("\n");

    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `eidclean_predictions_eid_day_${batchEidDay}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  }

  const batchSucceeded = batchResults.filter((r) => !r.error && r.prediction);
  const totalWaste = batchSucceeded.reduce((s, r) => s + r.prediction.waste_kg, 0);
  const totalTrucks = batchSucceeded.reduce((s, r) => s + r.prediction.trucks, 0);
  const totalWorkers = batchSucceeded.reduce((s, r) => s + r.prediction.workers, 0);
  const totalBins = batchSucceeded.reduce((s, r) => s + r.prediction.bins, 0);

  const priorityColor = {
    High: "from-red-50 to-white text-red-700 ring-red-200",
    Medium: "from-amber-50 to-white text-amber-700 ring-amber-200",
    Low: "from-emerald-50 to-white text-emerald-700 ring-emerald-200",
  };

  const hasActiveFilters =
    areaFilter !== "All" || populationFilter !== "Any" || searchQuery.trim() !== "";

  const featuredCount = LOCALITIES.filter((l) => l.featured).length;

  return (
    <div className="flex">
      <Sidebar />
      <main className={cn(shell, "px-4 py-5 sm:px-6 sm:py-6 2xl:px-10 2xl:py-8")}>
        <div className="mx-auto max-w-7xl">
          {/* ─── HERO ─────────────────────────── */}
          <div
            className={cn(
              "relative isolate overflow-hidden rounded-2xl bg-[linear-gradient(115deg,#064e3b_0%,#047857_52%,#0f766e_100%)] p-5 shadow-xl shadow-emerald-950/20 ring-1 ring-emerald-950/30 motion-safe:animate-slide-up sm:p-6 2xl:p-8",
              sectionGap
            )}
          >
            <Lattice
              id="eidclean-predictions-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div
              className="pointer-events-none absolute -right-10 -top-16 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl 2xl:h-64 2xl:w-64"
              aria-hidden="true"
            />
            <div
              className="pointer-events-none absolute -bottom-32 left-1/4 h-52 w-52 rounded-full bg-teal-300/20 blur-3xl"
              aria-hidden="true"
            />
            <Moon
              className="pointer-events-none absolute right-4 top-3 h-12 w-12 rotate-[18deg] fill-amber-200/20 text-amber-200/80 drop-shadow-[0_0_30px_rgba(252,211,77,0.45)] sm:h-14 sm:w-14 lg:h-16 lg:w-16 2xl:right-6 2xl:top-4 2xl:h-24 2xl:w-24"
              strokeWidth={1.25}
              aria-hidden="true"
            />
            <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between sm:gap-5 2xl:gap-8">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-amber-200 ring-1 ring-white/20 backdrop-blur sm:h-11 sm:w-11 2xl:h-12 2xl:w-12">
                  <Sparkles className="h-5 w-5 2xl:h-6 2xl:w-6" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold tracking-tight text-white sm:text-2xl">
                    AI Resource Planning
                  </h2>
                  <p className="mt-0.5 text-sm leading-relaxed text-emerald-50/75">
                    Predict Eid-ul-Adha waste and required resources for Abbottabad
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2 sm:pr-16 lg:pr-20 2xl:pr-28">
                <span className="inline-flex items-center gap-1.5 rounded-full bg-white/10 px-3 py-1 text-xs font-medium text-emerald-50 ring-1 ring-white/20 backdrop-blur">
                  <Bot className="h-3.5 w-3.5 text-amber-200" aria-hidden="true" />
                  RandomForestRegressor
                </span>
              </div>
            </div>
          </div>

          {/* ─── INFO BOX ─────────────────────── */}
          <div
            className={cn(
              "flex items-start gap-3 rounded-2xl bg-gradient-to-br from-blue-50 via-white to-white p-4 shadow-sm ring-1 ring-blue-200/70 sm:gap-4 sm:p-5 2xl:p-6",
              sectionGap
            )}
          >
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-white text-blue-600 shadow-sm ring-1 ring-blue-100 2xl:h-10 2xl:w-10">
              <Lightbulb className={iconSize} aria-hidden="true" />
            </div>
            <p className="text-sm leading-relaxed text-blue-900/80">
              <span className="font-semibold text-blue-900">How it works:</span> The RandomForest
              model predicts Eid-ul-Adha waste from population, housing, Qurbani participation,
              area type and Eid day. The backend then converts predicted waste into required trucks,
              workers and bins using configurable capacity rules. Choose a set of localities and run
              the model in one click.
            </p>
          </div>

          {/* ─── BATCH PLANNING ───────────────── */}
          <Card padding="none" className={cn("overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm", sectionGap)}>
            {/* Header row */}
            <div className="flex flex-wrap items-center justify-between gap-4 border-b border-slate-100 px-6 py-5">
              <div className="flex items-center gap-3.5">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 text-emerald-600 ring-1 ring-emerald-200">
                  <Bot className="h-5 w-5" aria-hidden="true" />
                </div>
                <div>
                  <h3 className="text-base font-semibold tracking-tight text-slate-900">
                    Batch Planning
                  </h3>
                  <p className="mt-0.5 text-sm text-slate-500">
                    {showAll
                      ? `Showing all ${LOCALITIES.length} localities from PBS Census 2023`
                      : `Quick view: ${featuredCount} key localities`}
                  </p>
                </div>
              </div>

              <div className="flex flex-wrap items-center gap-3">
                <button
                  type="button"
                  onClick={() => {
                    setShowAll((v) => !v);
                    setSearchQuery("");
                  }}
                  className={cn(
                    "inline-flex h-10 items-center gap-2 rounded-xl border px-4 text-sm font-semibold shadow-sm transition-all",
                    showAll
                      ? "border-emerald-300 bg-emerald-50 text-emerald-700 hover:bg-emerald-100"
                      : "border-slate-200 bg-white text-slate-700 hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-700"
                  )}
                >
                  {showAll ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  {showAll ? "Show featured 20" : `Show all ${LOCALITIES.length}`}
                </button>

                <div className="inline-flex h-10 items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 shadow-sm">
                  <span className="text-xs font-bold uppercase tracking-wider text-slate-500">
                    Eid Day
                  </span>
                  <div className="flex items-center gap-1">
                    {[1, 2, 3].map((d) => (
                      <button
                        key={d}
                        type="button"
                        onClick={() => setBatchEidDay(d)}
                        className={cn(
                          "flex h-7 w-9 items-center justify-center rounded-lg text-sm font-bold transition-all",
                          batchEidDay === d
                            ? "bg-emerald-600 text-white shadow-sm shadow-emerald-600/25"
                            : "text-slate-500 hover:bg-slate-100 hover:text-slate-900"
                        )}
                      >
                        {d}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>

            {/* Search bar */}
            {showAll && (
              <div className="border-b border-slate-100 bg-white px-6 py-4">
                <div className="relative">
                  <Search
                    className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400"
                    aria-hidden="true"
                  />
                  <input
                    type="text"
                    placeholder={`Search ${LOCALITIES.length} localities by name...`}
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="h-11 w-full rounded-xl border border-slate-200 bg-slate-50/60 pl-11 pr-11 text-sm text-slate-900 outline-none transition-all placeholder:text-slate-400 hover:bg-white focus:border-emerald-400 focus:bg-white focus:ring-4 focus:ring-emerald-500/10"
                  />
                  {searchQuery && (
                    <button
                      type="button"
                      onClick={() => setSearchQuery("")}
                      className="absolute right-3 top-1/2 -translate-y-1/2 rounded-md p-1.5 text-slate-400 transition-colors hover:bg-slate-100 hover:text-slate-600"
                    >
                      <X className="h-4 w-4" />
                    </button>
                  )}
                </div>
              </div>
            )}

            {/* Filters row */}
            <div className="border-b border-slate-100 bg-slate-50/70 px-6 py-4">
              <div className="flex flex-wrap items-center gap-x-8 gap-y-4">
                <div className="flex items-center gap-3">
                  <span className="text-xs font-bold uppercase tracking-wider text-slate-500">
                    Area Type
                  </span>
                  <div className="inline-flex items-center gap-1 rounded-xl bg-white p-1 shadow-sm ring-1 ring-slate-200">
                    {[
                      { v: "All", l: "All" },
                      { v: "Rural", l: "Rural" },
                      { v: "Urban", l: "Urban" },
                    ].map((o) => (
                      <button
                        key={o.v}
                        type="button"
                        onClick={() => setAreaFilter(o.v)}
                        className={cn(
                          "rounded-lg px-3.5 py-1.5 text-sm font-semibold transition-all",
                          areaFilter === o.v
                            ? "bg-emerald-600 text-white shadow-sm shadow-emerald-600/25"
                            : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                        )}
                      >
                        {o.l}
                      </button>
                    ))}
                  </div>
                </div>

                <div className="flex items-center gap-3">
                  <span className="text-xs font-bold uppercase tracking-wider text-slate-500">
                    Population
                  </span>
                  <div className="inline-flex items-center gap-1 rounded-xl bg-white p-1 shadow-sm ring-1 ring-slate-200">
                    {[
                      { v: "Any", l: "Any" },
                      { v: "Small", l: "Under 5k" },
                      { v: "Medium", l: "5k–20k" },
                      { v: "Large", l: "Over 20k" },
                    ].map((o) => (
                      <button
                        key={o.v}
                        type="button"
                        onClick={() => setPopulationFilter(o.v)}
                        className={cn(
                          "rounded-lg px-3.5 py-1.5 text-sm font-semibold transition-all",
                          populationFilter === o.v
                            ? "bg-emerald-600 text-white shadow-sm shadow-emerald-600/25"
                            : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                        )}
                      >
                        {o.l}
                      </button>
                    ))}
                  </div>
                </div>

                {hasActiveFilters && (
                  <button
                    type="button"
                    onClick={handleResetFilters}
                    className="ml-auto inline-flex h-9 items-center gap-1.5 rounded-lg px-3 text-sm font-medium text-slate-500 transition-colors hover:bg-white hover:text-slate-900"
                  >
                    <X className="h-4 w-4" aria-hidden="true" />
                    Clear filters
                  </button>
                )}
              </div>
            </div>

            {/* Selection + Run row */}
            <div className="flex flex-wrap items-center justify-between gap-4 px-6 py-5">
              <div className="flex items-center gap-3">
                <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-slate-50 to-slate-100 text-slate-500 ring-1 ring-slate-200">
                  <Filter className="h-4 w-4" aria-hidden="true" />
                </span>
                <div>
                  <div className="flex items-baseline gap-1.5">
                    <span className="text-lg font-bold tabular-nums text-slate-900">
                      {selectedCount}
                    </span>
                    <span className="text-sm text-slate-400">of</span>
                    <span className="text-sm font-semibold tabular-nums text-slate-500">
                      {totalFilteredCount}
                    </span>
                    <span className="text-sm text-slate-500">
                      {showAll ? "matching" : "featured"} selected
                    </span>
                  </div>
                  <div className="mt-0.5 flex items-center gap-2 text-xs">
                    <button
                      type="button"
                      onClick={handleSelectAll}
                      disabled={selectedCount === totalFilteredCount}
                      className={cn(
                        "font-semibold transition-colors",
                        selectedCount === totalFilteredCount
                          ? "cursor-not-allowed text-slate-300"
                          : "text-emerald-700 hover:text-emerald-800 hover:underline"
                      )}
                    >
                      Select all
                    </button>
                    <span className="text-slate-300">·</span>
                    <button
                      type="button"
                      onClick={handleClearAll}
                      disabled={selectedCount === 0}
                      className={cn(
                        "font-semibold transition-colors",
                        selectedCount === 0
                          ? "cursor-not-allowed text-slate-300"
                          : "text-slate-600 hover:text-slate-800 hover:underline"
                      )}
                    >
                      Clear all
                    </button>
                  </div>
                </div>
              </div>

              <Button
                onClick={handleRunBatch}
                disabled={batchLoading || selectedCount === 0}
                className="h-11 gap-2 rounded-xl bg-emerald-600 px-6 text-sm font-bold text-white shadow-lg shadow-emerald-600/25 transition-all hover:bg-emerald-700 hover:shadow-xl hover:shadow-emerald-600/30 disabled:cursor-not-allowed disabled:bg-slate-300 disabled:shadow-none"
              >
                {batchLoading ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />
                    {batchProgress.total > 0
                      ? `Predicting ${batchProgress.done} of ${batchProgress.total}...`
                      : `Predicting ${selectedCount}...`}
                  </>
                ) : (
                  <>
                    <Sparkles className="h-4 w-4" aria-hidden="true" />
                    Run Predictions
                    <span className="rounded-md bg-white/25 px-2 py-0.5 text-xs font-bold tabular-nums">
                      {selectedCount}
                    </span>
                  </>
                )}
              </Button>
            </div>
          </Card>

          {/* ─── BATCH ERROR ─────────────────── */}
          {batchError && (
            <div
              className={cn(
                "flex items-start gap-2.5 rounded-2xl bg-red-50 px-4 py-3 text-sm text-red-700 ring-1 ring-red-200/70",
                sectionGap
              )}
            >
              <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden="true" />
              <span>{batchError}</span>
            </div>
          )}

          {/* ─── KPI CARDS ───────────────────── */}
          {hasRunBatch && !batchError && batchSucceeded.length > 0 && (
            <div
              className={cn(
                "grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 xl:grid-cols-4 2xl:gap-6",
                sectionGap
              )}
            >
              <KpiCard
                icon={Gauge}
                label="Total Waste"
                value={`${(totalWaste / 1000).toFixed(1)} t`}
                sub={`${totalWaste.toLocaleString(undefined, { maximumFractionDigits: 0 })} kg`}
                tone="slate"
              />
              <KpiCard
                icon={Truck}
                label="Trucks"
                value={totalTrucks}
                sub="Required total"
                tone="amber"
              />
              <KpiCard
                icon={HardHat}
                label="Workers"
                value={totalWorkers}
                sub="Required total"
                tone="sky"
              />
              <KpiCard
                icon={Trash2}
                label="Bins"
                value={totalBins}
                sub="Required total"
                tone="emerald"
              />
            </div>
          )}

          {/* ─── RESULTS TABLE ───────────────── */}
          {hasRunBatch && !batchError && (
            <Card padding="none" className={cn("overflow-hidden", sectionGap)}>
              <CardHeader
                className={cn("flex flex-wrap items-center justify-between gap-3", cardHeaderPad)}
              >
                <div className="flex items-center gap-3">
                  <div className={cn(iconTile, "from-amber-50 to-amber-100 text-amber-600 ring-amber-200")}>
                    <MapPin className={iconSize} aria-hidden="true" />
                  </div>
                  <div>
                    <h3 className={cardTitle}>Predicted needs per locality</h3>
                    <p className={cardSub}>
                      {batchSucceeded.length} of {batchResults.length} predictions succeeded · Eid Day {batchEidDay}
                    </p>
                  </div>
                </div>

                <button
                  type="button"
                  onClick={handleExportCSV}
                  disabled={batchResults.length === 0}
                  className="inline-flex h-8 items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 text-xs font-medium text-slate-700 shadow-sm transition-all hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-700 disabled:cursor-not-allowed disabled:opacity-50 2xl:h-9 2xl:px-3.5"
                >
                  <Download className="h-3.5 w-3.5" aria-hidden="true" />
                  Export CSV
                </button>
              </CardHeader>

              <div className="max-h-[600px] overflow-y-auto">
                <Table wrapperClassName="rounded-none border-0 border-t shadow-none">
                  <TableHeader className="sticky top-0 z-10 bg-slate-50/95 backdrop-blur">
                    <TableRow>
                      <TableHead className={headPad}>Locality</TableHead>
                      <TableHead className={cn(headPad, "text-right")}>Population</TableHead>
                      <TableHead className={cn(headPad, "text-right")}>Predicted Waste</TableHead>
                      <TableHead className={headPad}>Priority</TableHead>
                      <TableHead className={cn(headPad, "text-right")}>Trucks</TableHead>
                      <TableHead className={cn(headPad, "text-right")}>Workers</TableHead>
                      <TableHead className={cn(headPad, "text-right")}>Bins</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {batchResults.map((r) => {
                      const l = r.locality;
                      const nameCell = (
                        <div className="flex items-center gap-3">
                          <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-slate-50 to-slate-100 text-slate-500 ring-1 ring-slate-200 transition-colors duration-150 group-hover:from-emerald-50 group-hover:to-emerald-100 group-hover:text-emerald-600 group-hover:ring-emerald-200 2xl:h-9 2xl:w-9">
                            <MapPin className="h-4 w-4" aria-hidden="true" />
                          </span>
                          <span className="font-semibold text-slate-900">{l.name}</span>
                        </div>
                      );
                      if (r.error || !r.prediction) {
                        return (
                          <TableRow
                            key={l.id}
                            className="group border-b border-slate-100 bg-red-50/30 transition-colors hover:bg-red-50/60"
                          >
                            <TableCell className={cellPad}>{nameCell}</TableCell>
                            <TableCell className={cn(cellPad, "text-right tabular-nums text-slate-500")}>
                              {l.population.toLocaleString()}
                            </TableCell>
                            <TableCell className={cellPad} colSpan={5}>
                              <span className="text-xs font-medium text-red-600">Failed: {r.error}</span>
                            </TableCell>
                          </TableRow>
                        );
                      }
                      const p = r.prediction;
                      const priority = derivePriority(p.waste_kg);
                      return (
                        <TableRow
                          key={l.id}
                          className="group border-b border-slate-100 transition-colors hover:bg-emerald-50/30"
                        >
                          <TableCell className={cellPad}>{nameCell}</TableCell>
                          <TableCell className={cn(cellPad, "text-right tabular-nums text-slate-600")}>
                            {l.population.toLocaleString()}
                          </TableCell>
                          <TableCell className={cn(cellPad, "text-right font-medium tabular-nums text-slate-900")}>
                            {formatWaste(p.waste_kg)}
                          </TableCell>
                          <TableCell className={cellPad}>
                            <Badge variant={priorityVariant[priority]} dot>
                              {priority}
                            </Badge>
                          </TableCell>
                          <TableCell className={cn(cellPad, "text-right tabular-nums text-slate-700")}>
                            <span className="inline-flex items-center gap-1.5">
                              <Truck className="h-3.5 w-3.5 text-amber-500" aria-hidden="true" />
                              {p.trucks}
                            </span>
                          </TableCell>
                          <TableCell className={cn(cellPad, "text-right tabular-nums text-slate-700")}>
                            <span className="inline-flex items-center gap-1.5">
                              <HardHat className="h-3.5 w-3.5 text-sky-500" aria-hidden="true" />
                              {p.workers}
                            </span>
                          </TableCell>
                          <TableCell className={cn(cellPad, "text-right tabular-nums text-slate-700")}>
                            <span className="inline-flex items-center gap-1.5">
                              <Trash2 className="h-3.5 w-3.5 text-emerald-500" aria-hidden="true" />
                              {p.bins}
                            </span>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </div>
            </Card>
          )}

          {/* ─── LOCALITY PICKER ─────────────── */}
          {totalFilteredCount > 0 && (showAll || hasActiveFilters) && (
            <Card padding="none" className={cn("overflow-hidden", sectionGap)}>
              <CardHeader
                className={cn("flex flex-wrap items-center justify-between gap-3", cardHeaderPad)}
              >
                <div className="flex items-center gap-3">
                  <div className={cn(iconTile, "from-slate-50 to-slate-100 text-slate-600 ring-slate-200")}>
                    <Filter className={iconSize} aria-hidden="true" />
                  </div>
                  <div>
                    <h3 className={cardTitle}>
                      Matching localities
                      <span className="ml-2 rounded-md bg-slate-100 px-1.5 py-0.5 text-[11px] font-semibold tabular-nums text-slate-600 ring-1 ring-slate-200/70">
                        {totalFilteredCount}
                      </span>
                    </h3>
                    <p className={cardSub}>Uncheck any locality you do not want to include</p>
                  </div>
                </div>
              </CardHeader>
              <div className="grid max-h-[420px] grid-cols-1 gap-x-4 gap-y-1.5 overflow-y-auto px-4 py-4 sm:grid-cols-2 sm:px-5 lg:grid-cols-3 2xl:px-6 2xl:py-5">
                {filteredLocalities.map((l) => {
                  const checked = selectedIds.has(l.id);
                  return (
                    <label
                      key={l.id}
                      className={cn(
                        "flex cursor-pointer items-center gap-2.5 rounded-xl border px-3 py-2 transition-all duration-150",
                        checked
                          ? "border-emerald-200/70 bg-emerald-50/50 hover:bg-emerald-50"
                          : "border-transparent hover:border-slate-200 hover:bg-slate-50"
                      )}
                    >
                      <input
                        type="checkbox"
                        checked={checked}
                        onChange={() => toggleLocality(l.id)}
                        className="h-4 w-4 cursor-pointer rounded accent-emerald-600"
                      />
                      <span className="flex-1 truncate text-sm font-medium text-slate-700">
                        {l.name}
                      </span>
                      <span className="shrink-0 text-[11px] font-medium tabular-nums text-slate-400">
                        {l.population.toLocaleString()}
                      </span>
                    </label>
                  );
                })}
              </div>
            </Card>
          )}

          {/* ─── SINGLE AREA PREDICTION ──────── */}
          <div className="grid grid-cols-1 gap-4 sm:gap-5 xl:grid-cols-2 2xl:gap-6">
            <Card padding="none" className="overflow-hidden">
              <CardHeader className={cn("flex items-center justify-between gap-3", cardHeaderPad)}>
                <div className="flex items-center gap-3">
                  <div className={cn(iconTile, "from-slate-50 to-slate-100 text-slate-600 ring-slate-200")}>
                    <Users className={iconSize} aria-hidden="true" />
                  </div>
                  <div>
                    <h3 className={cardTitle}>Single Area Prediction</h3>
                    <p className={cardSub}>Run the model for one custom locality</p>
                  </div>
                </div>
                <Badge variant="gray">Advanced</Badge>
              </CardHeader>
              <CardBody className={cardBodyPad}>
                <form onSubmit={handleManualPredict} className="space-y-4 2xl:space-y-5">
                  <Input
                    label="Population"
                    leftIcon={Users}
                    type="number"
                    required
                    placeholder="e.g. 5000"
                    value={form.population}
                    onChange={(e) => setForm({ ...form, population: e.target.value })}
                  />
                  <Input
                    label="Housing Units"
                    leftIcon={Building2}
                    type="number"
                    required
                    placeholder="e.g. 900"
                    value={form.housing}
                    onChange={(e) => setForm({ ...form, housing: e.target.value })}
                  />
                  <Input
                    label="Participation Rate (0 to 1)"
                    leftIcon={Gauge}
                    type="number"
                    step="0.01"
                    min="0"
                    max="1"
                    required
                    placeholder="e.g. 0.28"
                    value={form.participation_rate}
                    onChange={(e) => setForm({ ...form, participation_rate: e.target.value })}
                  />

                  <div>
                    <label className="mb-2 block text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                      Area Type
                    </label>
                    <Segmented
                      options={[
                        { value: "Rural", label: "Rural" },
                        { value: "Urban", label: "Urban" },
                      ]}
                      value={form.area_type}
                      onChange={(v) => setForm({ ...form, area_type: v })}
                    />
                  </div>

                  <div>
                    <label className="mb-2 block text-[11px] font-semibold uppercase tracking-wider text-slate-500">
                      Eid Day
                    </label>
                    <Segmented
                      options={[
                        { value: 1, label: "Day 1" },
                        { value: 2, label: "Day 2" },
                        { value: 3, label: "Day 3" },
                      ]}
                      value={form.eid_day}
                      onChange={(v) => setForm({ ...form, eid_day: v })}
                    />
                  </div>

                  {error && (
                    <div className="flex items-start gap-2.5 rounded-xl bg-red-50 px-3.5 py-2.5 text-sm text-red-700 ring-1 ring-red-200/70">
                      <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden="true" />
                      <span>{error}</span>
                    </div>
                  )}

                  <button
                    type="submit"
                    disabled={loading}
                    className="inline-flex h-10 w-full items-center justify-center gap-2 rounded-xl bg-emerald-600 text-sm font-semibold text-white shadow-md shadow-emerald-600/20 transition-all hover:bg-emerald-700 hover:shadow-lg hover:shadow-emerald-600/25 disabled:cursor-not-allowed disabled:bg-slate-300 disabled:shadow-none 2xl:h-11"
                  >
                    {loading ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />
                        Predicting...
                      </>
                    ) : (
                      <>
                        <Bot className="h-4 w-4" aria-hidden="true" />
                        Test Prediction
                      </>
                    )}
                  </button>
                </form>
              </CardBody>
            </Card>

            {result ? (
              <Card padding="none" className="overflow-hidden motion-safe:animate-slide-up">
                <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                  <div className={cn(iconTile, "from-emerald-50 to-emerald-100 text-emerald-600 ring-emerald-200")}>
                    <CheckCircle2 className={iconSize} aria-hidden="true" />
                  </div>
                  <div>
                    <h4 className={cardTitle}>Prediction Result</h4>
                    <p className={cardSub}>Model output for the custom locality</p>
                  </div>
                </CardHeader>
                <CardBody className={cardBodyPad}>
                  <div
                    className={cn(
                      "rounded-2xl bg-gradient-to-br p-4 text-center ring-1 2xl:p-5",
                      priorityColor[result.priority]
                    )}
                  >
                    <p className="text-[11px] font-semibold uppercase tracking-wider opacity-80">
                      Priority Level
                    </p>
                    <p className="mt-1 text-3xl font-semibold tracking-tight 2xl:text-4xl">
                      {result.priority}
                    </p>
                  </div>

                  <div className="mt-4 space-y-2 2xl:space-y-2.5">
                    {[
                      {
                        icon: Gauge,
                        tone: "text-slate-500",
                        label: "Predicted Waste",
                        value: formatWaste(result.waste_kg),
                      },
                      { icon: HardHat, tone: "text-sky-500", label: "Workers Needed", value: result.workers },
                      { icon: Trash2, tone: "text-emerald-500", label: "Bins Needed", value: result.bins },
                      { icon: Truck, tone: "text-amber-500", label: "Trucks Needed", value: result.trucks },
                    ].map((row) => (
                      <div
                        key={row.label}
                        className="flex items-center justify-between rounded-xl bg-slate-50 px-3.5 py-2.5 ring-1 ring-slate-200/60 transition-all duration-150 hover:-translate-y-px hover:bg-white hover:shadow-md 2xl:px-4 2xl:py-3"
                      >
                        <span className="flex items-center gap-2.5 text-sm text-slate-600">
                          <row.icon className={cn("h-4 w-4", row.tone)} aria-hidden="true" />
                          {row.label}
                        </span>
                        <span className="font-semibold tabular-nums text-slate-900">{row.value}</span>
                      </div>
                    ))}
                  </div>
                </CardBody>
              </Card>
            ) : (
              <Card padding="none" className="overflow-hidden">
                <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                  <div className={cn(iconTile, "from-slate-50 to-slate-100 text-slate-600 ring-slate-200")}>
                    <Info className={iconSize} aria-hidden="true" />
                  </div>
                  <div>
                    <h4 className={cardTitle}>Prediction Result</h4>
                    <p className={cardSub}>Waiting for input</p>
                  </div>
                </CardHeader>
                <CardBody className={cn(cardBodyPad, "flex items-center justify-center py-10 2xl:py-14")}>
                  <div className="text-center">
                    <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-xl bg-gradient-to-br from-slate-50 to-slate-100 text-slate-400 ring-1 ring-slate-200">
                      <Info className="h-6 w-6" aria-hidden="true" />
                    </div>
                    <p className="mt-3 text-sm font-medium text-slate-600">No prediction yet</p>
                    <p className="mt-1 text-xs text-slate-400">
                      Fill the form and click Test Prediction
                    </p>
                  </div>
                </CardBody>
              </Card>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}