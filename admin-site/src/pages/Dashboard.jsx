// src/pages/Dashboard.jsx

import { useEffect, useState, useMemo } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";
import { useAuth } from "../context/AuthContext";
import { useNavigate } from "react-router-dom";
import {
  ArrowRight,
  CalendarDays,
  CircleCheck,
  ClipboardList,
  Clock,
  HardHat,
  Lightbulb,
  LoaderCircle,
  Map as MapIcon,
  MapPin,
  Moon,
  Sparkles,
  Trash2,
  TrendingUp,
  Truck,
  UserCheck,
} from "lucide-react";
import {
  Badge,
  Button,
  Card,
  CardBody,
  CardHeader,
  StatCard,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../components/ui";
import { cn } from "../lib/utils";
import { MapContainer, TileLayer, Marker, Popup, CircleMarker } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { LOCALITIES } from "../data/localities";

// Fix Leaflet default marker icons in Vite/React
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
});

// --------------------------------------------------------------------
// ML API config (same as Predictions page)
// --------------------------------------------------------------------
const ML_API_URL = "https://eidclean-production.up.railway.app";

async function callPredictionAPI(payload) {
  const response = await fetch(`${ML_API_URL}/predict`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!response.ok) {
    throw new Error(`API status ${response.status}`);
  }
  return response.json();
}

// Pick the top N localities by population
const TOP_LOCALITIES = [...LOCALITIES]
  .sort((a, b) => b.population - a.population)
  .slice(0, 3);

// --------------------------------------------------------------------
// Area extraction from location string
// --------------------------------------------------------------------
// Location examples:
//   "Combined Military Hospital, Karakoram Highway, Karimpura, Kehal, Abbottabad, ..."
//   "Supply Bazar, Abbottabad, ..."
// We take the LAST meaningful segment before "Abbottabad".
function extractArea(location) {
  if (!location || typeof location !== "string") return "Unknown";
  const parts = location.split(",").map((s) => s.trim()).filter(Boolean);

  // Find index of "Abbottabad" (case insensitive)
  const abbotIndex = parts.findIndex((p) =>
    p.toLowerCase().includes("abbottabad")
  );

  if (abbotIndex > 0) {
    // Take the segment right before "Abbottabad"
    return parts[abbotIndex - 1];
  }

  // Fallback: return the second segment, or the whole thing
  return parts.length > 1 ? parts[1] : parts[0] || "Unknown";
}

// --------------------------------------------------------------------
// Lattice pattern (unchanged)
// --------------------------------------------------------------------
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

const statTones = {
  blue: "border-blue-200/70 from-blue-50 via-white to-white before:bg-blue-300/40 after:via-blue-400/70 hover:shadow-blue-900/10",
  teal: "border-teal-200/70 from-teal-50 via-white to-white before:bg-teal-300/40 after:via-teal-400/70 hover:shadow-teal-900/10",
  yellow: "border-amber-200/70 from-amber-50 via-white to-white before:bg-amber-300/40 after:via-amber-400/70 hover:shadow-amber-900/10",
  green: "border-emerald-200/70 from-emerald-50 via-white to-white before:bg-emerald-300/40 after:via-emerald-400/70 hover:shadow-emerald-900/10",
};

const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cardBodyPad = "px-4 py-4 sm:px-5 sm:py-5 2xl:px-6 2xl:py-6";
const cellPad = "px-4 py-3 sm:px-5 2xl:px-6 2xl:py-4";

// --------------------------------------------------------------------
// Pending Area Row (unchanged design)
// --------------------------------------------------------------------
function PendingAreaRow({ area, requests, status, action }) {
  const statusColors = {
    Pending: "yellow",
    Assigned: "blue",
    Completed: "green",
  };

  return (
    <TableRow className="group hover:bg-slate-50/80">
      <TableCell className={cellPad}>
        <div className="flex items-center gap-3">
          <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-slate-50 to-slate-100 text-slate-500 ring-1 ring-slate-200 transition-colors duration-150 group-hover:from-emerald-50 group-hover:to-emerald-100 group-hover:text-emerald-600 group-hover:ring-emerald-200 2xl:h-9 2xl:w-9">
            <MapPin className="h-4 w-4" aria-hidden="true" />
          </span>
          <span className="font-semibold text-slate-900">{area}</span>
        </div>
      </TableCell>
      <TableCell className={cn(cellPad, "font-semibold tabular-nums text-slate-900")}>
        {requests}
      </TableCell>
      <TableCell className={cellPad}>
        <Badge variant={statusColors[status] || "gray"} dot>
          {status}
        </Badge>
      </TableCell>
      <TableCell align="right" className={cellPad}>
        <Button
          variant={action === "Assign" ? "primary" : "outline"}
          className={cn(
            "group/btn h-8 gap-1.5 px-3 text-xs",
            action === "Assign"
              ? "bg-emerald-600 shadow-sm shadow-emerald-600/20 hover:bg-emerald-700"
              : "hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-700"
          )}
        >
          {action}
          <ArrowRight
            className="h-3.5 w-3.5 transition-transform duration-150 group-hover/btn:translate-x-0.5"
            aria-hidden="true"
          />
        </Button>
      </TableCell>
    </TableRow>
  );
}

// --------------------------------------------------------------------
// Main Dashboard
// --------------------------------------------------------------------
export default function Dashboard() {
  const { user } = useAuth();
  const navigate = useNavigate();

  const [stats, setStats] = useState({
    total: 0,
    pending: 0,
    assigned: 0,
    completed: 0,
    drivers: 0,
    areas: 0,
  });
  const [pickupRequests, setPickupRequests] = useState([]);
  const [loading, setLoading] = useState(true);

  // AI predictions for the top 3 localities
  const [aiPredictions, setAiPredictions] = useState([]);
  const [aiLoading, setAiLoading] = useState(true);

  // ----------------------------------------------------------------
  // Fetch all Firestore data once
  // ----------------------------------------------------------------
  useEffect(() => {
    async function fetchStats() {
      try {
        const requestsSnap = await getDocs(collection(db, "pickupRequests"));
        const driversSnap = await getDocs(collection(db, "drivers"));
        const areasSnap = await getDocs(collection(db, "areas"));

        const requests = requestsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
        setPickupRequests(requests);

        const pending = requests.filter((r) => r.status === "pending").length;
        const assigned = requests.filter((r) => r.status === "assigned").length;
        const completed = requests.filter((r) => r.status === "completed").length;

        setStats({
          total: requests.length,
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

  // ----------------------------------------------------------------
  // Fetch AI predictions for top 3 localities
  // ----------------------------------------------------------------
  useEffect(() => {
    async function fetchAiPredictions() {
      try {
        const results = await Promise.all(
          TOP_LOCALITIES.map(async (loc) => {
            const prediction = await callPredictionAPI({
              population: loc.population,
              housing: loc.housing,
              participation_rate: loc.participationRate,
              area_type: loc.areaType,
              eid_day: 1,
            });
            return {
              area: loc.name,
              trucks: prediction.trucks,
              workers: prediction.workers,
              bins: prediction.bins,
              waste_kg: prediction.waste_kg,
            };
          })
        );
        setAiPredictions(results);
      } catch (error) {
        console.error("Error fetching AI predictions:", error);
      }
      setAiLoading(false);
    }
    fetchAiPredictions();
  }, []);

  // ----------------------------------------------------------------
  // Aggregate pickupRequests by area (real data)
  // ----------------------------------------------------------------
  const pendingAreas = useMemo(() => {
    if (pickupRequests.length === 0) return [];

    const areaMap = new Map();
    for (const req of pickupRequests) {
      const area = extractArea(req.location);
      if (!areaMap.has(area)) {
        areaMap.set(area, { pending: 0, assigned: 0, completed: 0, total: 0 });
      }
      const entry = areaMap.get(area);
      entry.total += 1;
      if (req.status === "pending") entry.pending += 1;
      else if (req.status === "assigned") entry.assigned += 1;
      else if (req.status === "completed") entry.completed += 1;
    }

    // Convert to array, pick dominant status per area, sort by total
    return Array.from(areaMap.entries())
      .map(([area, counts]) => {
        let status = "Completed";
        let action = "View";
        if (counts.pending > 0) {
          status = "Pending";
          action = "Assign";
        } else if (counts.assigned > 0) {
          status = "Assigned";
          action = "Track";
        }
        return { area, requests: counts.total, status, action };
      })
      .sort((a, b) => b.requests - a.requests)
      .slice(0, 8);
  }, [pickupRequests]);

  // ----------------------------------------------------------------
  // Smart Insights (real data)
  // ----------------------------------------------------------------
  const smartInsights = useMemo(() => {
    // Insight 1: top pending area
    const pendingByArea = new Map();
    for (const req of pickupRequests) {
      if (req.status !== "pending") continue;
      const area = extractArea(req.location);
      pendingByArea.set(area, (pendingByArea.get(area) || 0) + 1);
    }
    const topPending = [...pendingByArea.entries()].sort((a, b) => b[1] - a[1])[0];

    // Insight 2: highest predicted waste locality
    const topWaste = aiPredictions
      .slice()
      .sort((a, b) => b.waste_kg - a.waste_kg)[0];

    // Insight 3: active drivers
    const driverCount = stats.drivers;

    return [
      {
        label: "Top Pending Area",
        value: topPending
          ? `${topPending[0]} (${topPending[1]} pending)`
          : "No pending requests",
        icon: Clock,
        bar: "before:bg-blue-500",
        tile: "bg-blue-50 text-blue-600 ring-blue-100",
        text: "text-blue-700",
      },
      {
        label: "Highest Waste Estimate",
        value: topWaste
          ? `${topWaste.area} (~${Math.round(topWaste.waste_kg).toLocaleString()} kg)`
          : "Loading...",
        icon: TrendingUp,
        bar: "before:bg-amber-500",
        tile: "bg-amber-50 text-amber-600 ring-amber-100",
        text: "text-amber-700",
      },
      {
        label: "Active Drivers",
        value: driverCount === 0
          ? "No drivers registered"
          : `${driverCount} registered driver${driverCount === 1 ? "" : "s"}`,
        icon: Lightbulb,
        bar: "before:bg-emerald-500",
        tile: "bg-emerald-50 text-emerald-600 ring-emerald-100",
        text: "text-emerald-700",
      },
    ];
  }, [pickupRequests, aiPredictions, stats.drivers]);

  const heroStats = [
    { label: "Pending", value: stats.pending, icon: Clock },
    { label: "Assigned", value: stats.assigned, icon: UserCheck },
    { label: "Completed", value: stats.completed, icon: CircleCheck },
  ];

  const shell = "ml-64 min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)]";

  // ----------------------------------------------------------------
  // Compute map center from real requests (fallback to Abbottabad)
  // ----------------------------------------------------------------
  const mapCenter = useMemo(() => {
    const valid = pickupRequests.filter(
      (r) => typeof r.latitude === "number" && typeof r.longitude === "number"
    );
    if (valid.length === 0) return [34.1688, 73.2215]; // Abbottabad center
    const avgLat = valid.reduce((s, r) => s + r.latitude, 0) / valid.length;
    const avgLng = valid.reduce((s, r) => s + r.longitude, 0) / valid.length;
    return [avgLat, avgLng];
  }, [pickupRequests]);

  // ----------------------------------------------------------------
  // Loading screen (unchanged)
  // ----------------------------------------------------------------
  if (loading) {
    return (
      <div className="flex">
        <Sidebar />
        <main className={cn(shell, "flex items-center justify-center p-8")}>
          <div className="flex flex-col items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-white shadow-card ring-1 ring-slate-200">
              <LoaderCircle className="h-6 w-6 animate-spin text-emerald-500" aria-hidden="true" />
            </div>
            <p className="text-sm font-medium text-slate-500">Loading dashboard</p>
          </div>
        </main>
      </div>
    );
  }

  return (
    <div className="flex">
      <Sidebar />
      <main className={cn(shell, "px-4 py-5 sm:px-6 sm:py-6 2xl:px-10 2xl:py-8")}>
        <div className="mx-auto max-w-7xl">
          {/* Hero */}
          <div className={cn(
            "relative isolate overflow-hidden rounded-2xl bg-[linear-gradient(115deg,#064e3b_0%,#047857_52%,#0f766e_100%)] p-5 shadow-xl shadow-emerald-950/20 ring-1 ring-emerald-950/30 motion-safe:animate-slide-up sm:p-6 2xl:p-8",
            sectionGap
          )}>
            <Lattice
              id="eidclean-hero-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div className="pointer-events-none absolute -right-10 -top-16 h-56 w-56 rounded-full bg-amber-300/30 blur-3xl 2xl:h-72 2xl:w-72" aria-hidden="true" />
            <div className="pointer-events-none absolute -bottom-32 left-1/4 h-52 w-52 rounded-full bg-teal-300/20 blur-3xl" aria-hidden="true" />
            <Moon
              className="pointer-events-none absolute right-4 top-3 h-14 w-14 rotate-[18deg] fill-amber-200/20 text-amber-200/80 drop-shadow-[0_0_30px_rgba(252,211,77,0.45)] sm:h-16 sm:w-16 lg:h-20 lg:w-20 2xl:right-6 2xl:top-4 2xl:h-28 2xl:w-28"
              strokeWidth={1.25}
              aria-hidden="true"
            />

            <div className="relative flex flex-col gap-4 sm:gap-5 xl:flex-row xl:items-end xl:justify-between 2xl:gap-8">
              <div className="max-w-lg">
                <span className="inline-flex items-center gap-2 rounded-full bg-white/10 px-3 py-1 text-xs font-medium text-emerald-50 ring-1 ring-white/20 backdrop-blur">
                  <CalendarDays className="h-3.5 w-3.5 text-amber-200" aria-hidden="true" />
                  {new Date().toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric", year: "numeric" })}
                </span>
                <h2 className="mt-3 text-2xl font-semibold tracking-tight text-white sm:text-3xl 2xl:mt-4 2xl:text-4xl">
                  Welcome, {user?.displayName || "Admin"}!
                </h2>
                <p className="mt-1 text-sm leading-relaxed text-emerald-50/75 2xl:mt-2 2xl:text-[15px]">
                  Abbottabad Municipal Corporation — Eid ul Adha Operations
                </p>
                <div className="mt-4 flex flex-wrap gap-2.5 2xl:mt-6 2xl:gap-3">
                  <Button
                    onClick={() => navigate("/reports")}
                    className="group h-9 bg-white px-3.5 text-emerald-900 shadow-lg shadow-emerald-950/20 hover:bg-emerald-50 active:bg-emerald-100 2xl:h-10 2xl:px-4"
                  >
                    <ClipboardList className="h-4 w-4" aria-hidden="true" />
                    Review pickups
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => navigate("/predictions")}
                    className="group h-9 border-white/25 bg-white/10 px-3.5 text-white backdrop-blur hover:border-white/40 hover:bg-white/20 hover:text-white active:bg-white/25 2xl:h-10 2xl:px-4"
                  >
                    <Sparkles className="h-4 w-4 text-amber-200" aria-hidden="true" />
                    Plan resources
                  </Button>
                </div>
              </div>

              <div className="grid w-full shrink-0 grid-cols-3 divide-x divide-white/15 overflow-hidden rounded-xl bg-emerald-950/30 ring-1 ring-white/20 backdrop-blur-md xl:w-auto 2xl:rounded-2xl">
                {heroStats.map((s) => (
                  <div key={s.label} className="px-3 py-2.5 sm:px-5 sm:py-3 2xl:px-6 2xl:py-4">
                    <p className="flex items-center gap-1.5 text-[11px] font-medium text-emerald-50/75 sm:text-xs">
                      <s.icon className="h-3.5 w-3.5" aria-hidden="true" />
                      {s.label}
                    </p>
                    <p className="mt-1 text-xl font-semibold tabular-nums tracking-tight text-white sm:text-2xl 2xl:text-3xl">
                      {s.value}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Stats Cards */}
          <div className={cn("grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 xl:grid-cols-4 2xl:gap-6", sectionGap)}>
            {[
              { label: "Total Pickups", value: stats.total, icon: ClipboardList, variant: "blue", description: "All pickup requests" },
              { label: "Active Drivers", value: stats.drivers, icon: Truck, variant: "teal", description: "Registered drivers" },
              { label: "Areas Managed", value: stats.areas, icon: MapIcon, variant: "yellow", description: "Service zones" },
              {
                label: "Completion Rate",
                value: stats.total > 0 ? `${Math.round((stats.completed / stats.total) * 100)}%` : "—",
                icon: CircleCheck,
                variant: "green",
                description: "Pickups completed",
              },
            ].map((card) => (
              <StatCard
                key={card.label}
                {...card}
                className={cn(
                  "relative isolate overflow-hidden bg-gradient-to-br p-4 shadow-card transition-all duration-200 hover:-translate-y-1 hover:shadow-xl sm:p-5",
                  "before:absolute before:-right-10 before:-top-12 before:-z-10 before:h-32 before:w-32 before:rounded-full before:blur-2xl",
                  "after:absolute after:inset-x-6 after:top-0 after:h-px after:bg-gradient-to-r after:from-transparent after:to-transparent",
                  statTones[card.variant]
                )}
              />
            ))}
          </div>

          {/* AI Resource Planning + Smart Insights Row */}
          <div className={cn("grid grid-cols-1 gap-4 sm:gap-5 xl:grid-cols-3 2xl:gap-6", sectionGap)}>
            {/* AI Resource Planning */}
            <Card
              padding="none"
              className="relative isolate overflow-hidden border-emerald-700/40 bg-gradient-to-br from-emerald-900 via-emerald-950 to-slate-950 shadow-xl shadow-emerald-950/20 xl:col-span-2"
            >
              <Lattice
                id="eidclean-ai-lattice"
                className="inset-0 -z-10 h-full w-full text-emerald-200/[0.05] [mask-image:radial-gradient(ellipse_at_top_right,black,transparent_70%)]"
              />
              <div className="pointer-events-none absolute -right-20 -top-24 -z-10 h-72 w-72 rounded-full bg-emerald-400/20 blur-3xl" aria-hidden="true" />
              <div className="pointer-events-none absolute -bottom-24 -left-16 -z-10 h-56 w-56 rounded-full bg-amber-400/10 blur-3xl" aria-hidden="true" />
              <CardHeader className={cn("flex items-center justify-between border-white/10", cardHeaderPad)}>
                <div className="flex items-center gap-3">
                  <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-300/25 to-teal-400/10 text-emerald-200 ring-1 ring-emerald-200/25 2xl:h-10 2xl:w-10">
                    <Sparkles className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                  </div>
                  <div>
                    <h3 className="text-[15px] font-semibold tracking-tight text-white 2xl:text-base">
                      AI Resource Planning
                    </h3>
                    <p className="text-xs text-emerald-200/60">Predicted needs per area</p>
                  </div>
                </div>
                <Badge
                  variant="green"
                  dot
                  className="bg-emerald-400/10 text-emerald-200 ring-emerald-300/30"
                >
                  AI Powered
                </Badge>
              </CardHeader>
              <CardBody className={cardBodyPad}>
                <p className="mb-4 max-w-lg text-sm leading-relaxed text-emerald-100/65 2xl:mb-5">
                  Live predictions from our RandomForest model for the three largest localities in Abbottabad (Eid Day 1).
                </p>
                <div className="space-y-2">
                  {aiLoading ? (
                    <div className="flex items-center justify-center py-8">
                      <LoaderCircle className="h-5 w-5 animate-spin text-emerald-300/60" aria-hidden="true" />
                      <span className="ml-3 text-sm text-emerald-100/60">Loading predictions...</span>
                    </div>
                  ) : aiPredictions.length === 0 ? (
                    <div className="rounded-xl bg-white/[0.04] px-4 py-3 text-center text-sm text-emerald-100/60 ring-1 ring-white/10">
                      Predictions unavailable — check API connection
                    </div>
                  ) : (
                    aiPredictions.map((item) => (
                      <div
                        key={item.area}
                        className="flex flex-col gap-2.5 rounded-xl bg-white/[0.04] px-3.5 py-2.5 ring-1 ring-white/10 transition-all duration-150 hover:bg-white/[0.08] hover:ring-white/20 sm:flex-row sm:items-center sm:justify-between 2xl:px-4 2xl:py-3.5"
                      >
                        <span className="flex items-center gap-2.5 text-sm font-semibold text-white">
                          <MapPin className="h-4 w-4 text-emerald-300/70" aria-hidden="true" />
                          {item.area}
                        </span>
                        <div className="grid grid-cols-3 gap-2 text-sm">
                          {[
                            { icon: Truck, tone: "text-amber-300", n: item.trucks, l: "trucks" },
                            { icon: HardHat, tone: "text-sky-300", n: item.workers, l: "workers" },
                            { icon: Trash2, tone: "text-emerald-300", n: item.bins, l: "bins" },
                          ].map((m) => (
                            <span
                              key={m.l}
                              className="inline-flex items-center gap-1.5 rounded-lg bg-black/20 px-2.5 py-1.5 ring-1 ring-white/10 2xl:gap-2 2xl:px-3"
                            >
                              <m.icon className={cn("h-4 w-4", m.tone)} aria-hidden="true" />
                              <span className="font-semibold tabular-nums text-white">{m.n}</span>
                              <span className="text-xs text-emerald-100/55">{m.l}</span>
                            </span>
                          ))}
                        </div>
                      </div>
                    ))
                  )}
                </div>
                <Button
                  variant="primary"
                  onClick={() => navigate("/predictions")}
                  className="group mt-4 inline-flex h-9 items-center gap-2 bg-gradient-to-br from-amber-300 to-amber-400 text-emerald-950 shadow-lg shadow-amber-500/20 hover:from-amber-200 hover:to-amber-300 2xl:mt-6 2xl:h-10"
                >
                  Plan Resources
                  <ArrowRight
                    className="h-4 w-4 transition-transform duration-150 group-hover:translate-x-0.5"
                    aria-hidden="true"
                  />
                </Button>
              </CardBody>
            </Card>

            {/* Smart Insights */}
            <Card padding="none" className="overflow-hidden">
              <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-amber-50 to-amber-100 text-amber-600 ring-1 ring-amber-200 2xl:h-10 2xl:w-10">
                  <Lightbulb className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">
                    Smart Insights
                  </h3>
                  <p className="text-xs text-slate-500">Live data from Firestore &amp; ML</p>
                </div>
              </CardHeader>
              <CardBody className="space-y-2.5 px-4 py-4 sm:px-5 2xl:space-y-3 2xl:py-5">
                {smartInsights.map((item) => (
                  <div
                    key={item.label}
                    className={cn(
                      "relative flex items-center gap-3 rounded-xl border border-slate-200 bg-white py-2.5 pl-5 pr-4 shadow-sm transition-all duration-150 hover:-translate-y-px hover:shadow-md 2xl:py-3.5",
                      "before:absolute before:inset-y-3 before:left-0 before:w-1 before:rounded-r-full",
                      item.bar
                    )}
                  >
                    <div className={cn("flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ring-1 2xl:h-10 2xl:w-10", item.tile)}>
                      <item.icon className="h-4 w-4" aria-hidden="true" />
                    </div>
                    <div className="min-w-0">
                      <p className={cn("text-xs font-medium", item.text)}>{item.label}</p>
                      <p className="mt-0.5 text-sm font-semibold text-slate-900 break-words">{item.value}</p>
                    </div>
                  </div>
                ))}
              </CardBody>
            </Card>
          </div>

          {/* Live Pickup Map — real data */}
          <Card padding="none" className={cn("overflow-hidden", sectionGap)}>
            <CardHeader className={cn("flex flex-wrap items-center justify-between gap-3", cardHeaderPad)}>
              <div className="flex items-center gap-3">
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 text-emerald-600 ring-1 ring-emerald-200 2xl:h-10 2xl:w-10">
                  <MapPin className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">
                    Live Pickup Map — Abbottabad
                  </h3>
                  <p className="text-xs text-slate-500">
                    {pickupRequests.length} pickup{pickupRequests.length === 1 ? "" : "s"} on the map
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2 text-xs font-medium text-slate-600">
                <span className="inline-flex items-center gap-2 rounded-full bg-white px-3 py-1.5 shadow-sm ring-1 ring-slate-200">
                  <span className="h-2 w-2 rounded-full bg-amber-500"></span> Pending
                </span>
                <span className="inline-flex items-center gap-2 rounded-full bg-white px-3 py-1.5 shadow-sm ring-1 ring-slate-200">
                  <span className="h-2 w-2 rounded-full bg-blue-500"></span> Assigned
                </span>
                <span className="inline-flex items-center gap-2 rounded-full bg-white px-3 py-1.5 shadow-sm ring-1 ring-slate-200">
                  <span className="h-2 w-2 rounded-full bg-emerald-500"></span> Completed
                </span>
              </div>
            </CardHeader>
            <div className="relative h-80 w-full overflow-hidden bg-slate-100 sm:h-96 2xl:h-[28rem]">
              <MapContainer
                center={mapCenter}
                zoom={12}
                scrollWheelZoom={false}
                style={{ height: "100%", width: "100%" }}
              >
                <TileLayer
                  attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                  url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                />
                {pickupRequests
                  .filter((r) => typeof r.latitude === "number" && typeof r.longitude === "number")
                  .map((req) => {
                    const color =
                      req.status === "pending"
                        ? "#f59e0b"
                        : req.status === "assigned"
                        ? "#3b82f6"
                        : "#10b981";
                    return (
                      <CircleMarker
                        key={req.id}
                        center={[req.latitude, req.longitude]}
                        radius={8}
                        pathOptions={{
                          color: "#ffffff",
                          weight: 2,
                          fillColor: color,
                          fillOpacity: 1,
                        }}
                      >
                        <Popup>
                          <div style={{ minWidth: "180px", fontFamily: "system-ui, sans-serif" }}>
                            <div style={{ fontWeight: 700, fontSize: "13px", marginBottom: "4px" }}>
                              {extractArea(req.location)}
                            </div>
                            <div style={{ fontSize: "12px", color: "#475569", marginBottom: "6px" }}>
                              {req.userName || "Unknown user"}
                            </div>
                            <div
                              style={{
                                display: "inline-block",
                                padding: "2px 8px",
                                borderRadius: "999px",
                                background:
                                  req.status === "pending"
                                    ? "#fef3c7"
                                    : req.status === "assigned"
                                    ? "#dbeafe"
                                    : "#d1fae5",
                                color:
                                  req.status === "pending"
                                    ? "#92400e"
                                    : req.status === "assigned"
                                    ? "#1e40af"
                                    : "#065f46",
                                fontSize: "11px",
                                fontWeight: 600,
                                textTransform: "capitalize",
                              }}
                            >
                              {req.status || "unknown"}
                            </div>
                          </div>
                        </Popup>
                      </CircleMarker>
                    );
                  })}
              </MapContainer>
            </div>
          </Card>

          {/* Pending Pickups by Area — real data */}
          <Card padding="none" className="overflow-hidden">
            <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-amber-50 to-amber-100 text-amber-600 ring-1 ring-amber-200 2xl:h-10 2xl:w-10">
                <ClipboardList className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
              </div>
              <div>
                <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">
                  Pending Pickups by Area
                </h3>
                <p className="text-xs text-slate-500">
                  {pendingAreas.length} area{pendingAreas.length === 1 ? "" : "s"} with requests
                </p>
              </div>
            </CardHeader>
            <Table wrapperClassName="rounded-none border-0 border-t shadow-none">
              <TableHeader className="bg-slate-50/80">
                <TableRow>
                  <TableHead className="px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3">Area</TableHead>
                  <TableHead className="px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3">Requests</TableHead>
                  <TableHead className="px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3">Status</TableHead>
                  <TableHead align="right" className="px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3">Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {pendingAreas.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={4} className={cn(cellPad, "text-center text-sm text-slate-500")}>
                      No pickup requests found in Firestore
                    </TableCell>
                  </TableRow>
                ) : (
                  pendingAreas.map((item) => (
                    <PendingAreaRow key={item.area} {...item} />
                  ))
                )}
              </TableBody>
            </Table>
          </Card>
        </div>
      </main>
    </div>
  );
}