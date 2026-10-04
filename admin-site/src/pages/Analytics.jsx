// src/pages/Analytics.jsx

import { useEffect, useState, useMemo } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, PieChart, Pie, Cell,
  Legend, LineChart, Line,
} from "recharts";
import {
  ChartColumn,
  ChartPie,
  CircleCheck,
  Clock,
  Download,
  HardHat,
  Layers,
  LoaderCircle,
  MapPin,
  Sparkles,
  Trash2,
  TrendingUp,
  Truck,
  Users,
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
import { LOCALITIES } from "../data/localities";

// --------------------------------------------------------------------
// ML API
// --------------------------------------------------------------------
const ML_API_URL = "https://eidclean-production.up.railway.app";

async function callPredictionAPI(payload) {
  const response = await fetch(`${ML_API_URL}/predict`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!response.ok) throw new Error(`API status ${response.status}`);
  return response.json();
}

// --------------------------------------------------------------------
// Layout constants
// --------------------------------------------------------------------
const shell = "ml-64 min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)]";
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cardBodyPad = "px-4 py-4 sm:px-5 sm:py-5 2xl:px-6 2xl:py-6";
const cellPad = "px-4 py-3 sm:px-5 2xl:px-6 2xl:py-3.5";
const headPad = "px-4 py-2.5 text-xs font-semibold uppercase tracking-wider text-slate-500 sm:px-5 2xl:px-6 2xl:py-3";
const iconTile = "flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br ring-1 2xl:h-10 2xl:w-10";
const cardTitle = "text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base";

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
  green: "border-emerald-200/70 from-emerald-50 via-white to-white before:bg-emerald-300/40 after:via-emerald-400/70",
  blue: "border-blue-200/70 from-blue-50 via-white to-white before:bg-blue-300/40 after:via-blue-400/70",
  teal: "border-teal-200/70 from-teal-50 via-white to-white before:bg-teal-300/40 after:via-teal-400/70",
  yellow: "border-amber-200/70 from-amber-50 via-white to-white before:bg-amber-300/40 after:via-amber-400/70",
};

const tooltipStyle = {
  borderRadius: 12,
  border: "1px solid #e2e8f0",
  boxShadow: "0 8px 24px -8px rgba(15,23,42,0.18)",
  fontSize: 12,
};

// --------------------------------------------------------------------
// Utility: area extraction from location string
// --------------------------------------------------------------------
function extractArea(location) {
  if (!location || typeof location !== "string") return "Unknown";
  const parts = location.split(",").map((s) => s.trim()).filter(Boolean);
  const abbotIndex = parts.findIndex((p) => p.toLowerCase().includes("abbottabad"));
  if (abbotIndex > 0) return parts[abbotIndex - 1];
  return parts.length > 1 ? parts[1] : parts[0] || "Unknown";
}

// --------------------------------------------------------------------
// Utility: safe date conversion
// --------------------------------------------------------------------
function toDate(ts) {
  if (!ts) return null;
  if (typeof ts.toDate === "function") return ts.toDate();
  if (ts instanceof Date) return ts;
  if (typeof ts === "number") return new Date(ts);
  if (ts.seconds) return new Date(ts.seconds * 1000);
  return null;
}

// --------------------------------------------------------------------
// Utility: minutes between two Firestore timestamps
// --------------------------------------------------------------------
function minutesBetween(startTs, endTs) {
  const a = toDate(startTs);
  const b = toDate(endTs);
  if (!a || !b) return null;
  const diff = (b.getTime() - a.getTime()) / 60000;
  return diff >= 0 ? diff : null;
}

// --------------------------------------------------------------------
// Main Component
// --------------------------------------------------------------------
export default function Analytics() {
  const [loading, setLoading] = useState(true);
  const [requests, setRequests] = useState([]);
  const [mlPrediction, setMlPrediction] = useState(null);
  const [mlLoading, setMlLoading] = useState(true);

  // ----------------------------------------------------------------
  // Load Firestore requests
  // ----------------------------------------------------------------
  useEffect(() => {
    async function load() {
      setLoading(true);
      try {
        const snap = await getDocs(collection(db, "pickupRequests"));
        setRequests(snap.docs.map((d) => ({ id: d.id, ...d.data() })));
      } catch (err) {
        console.error("Analytics load error:", err);
      }
      setLoading(false);
    }
    load();
  }, []);

  // ----------------------------------------------------------------
  // Load ML district-wide prediction (sum across all localities)
  // ----------------------------------------------------------------
  useEffect(() => {
    async function loadML() {
      setMlLoading(true);
      try {
        // Predict for top 20 by population as a proxy for district total
        const top = [...LOCALITIES].sort((a, b) => b.population - a.population).slice(0, 20);
        const results = await Promise.all(
          top.map((loc) =>
            callPredictionAPI({
              population: loc.population,
              housing: loc.housing,
              participation_rate: loc.participationRate,
              area_type: loc.areaType,
              eid_day: 1,
            }).then((p) => ({ ...p, name: loc.name }))
          )
        );
        const totals = results.reduce(
          (acc, r) => ({
            waste: acc.waste + r.waste_kg,
            trucks: acc.trucks + r.trucks,
            workers: acc.workers + r.workers,
            bins: acc.bins + r.bins,
          }),
          { waste: 0, trucks: 0, workers: 0, bins: 0 }
        );
        setMlPrediction({ ...totals, topLocalities: results.slice(0, 5) });
      } catch (err) {
        console.error("ML prediction error:", err);
      }
      setMlLoading(false);
    }
    loadML();
  }, []);

  // ----------------------------------------------------------------
  // Derived analytics (all real)
  // ----------------------------------------------------------------

  // --- Status counts ---
  const statusCounts = useMemo(() => {
    const counts = { pending: 0, assigned: 0, completed: 0, cancelled: 0 };
    for (const r of requests) {
      if (counts[r.status] !== undefined) counts[r.status] += 1;
    }
    return counts;
  }, [requests]);

  // --- KPIs ---
  const kpis = useMemo(() => {
    const total = requests.length;
    const completed = statusCounts.completed;
    const pending = statusCounts.pending;

    // Response time (createdAt → assignedAt)
    const responseTimes = requests
      .map((r) => minutesBetween(r.createdAt, r.assignedAt))
      .filter((v) => v !== null);
    const avgResponse =
      responseTimes.length > 0
        ? responseTimes.reduce((s, v) => s + v, 0) / responseTimes.length
        : null;

    // Service time (assignedAt → completedAt)
    const serviceTimes = requests
      .map((r) => minutesBetween(r.assignedAt, r.completedAt))
      .filter((v) => v !== null);
    const avgService =
      serviceTimes.length > 0
        ? serviceTimes.reduce((s, v) => s + v, 0) / serviceTimes.length
        : null;

    // Total animals
    const totalAnimals = requests.reduce((s, r) => s + (r.animals || 0), 0);

    return {
      total,
      completed,
      pending,
      completionRate: total > 0 ? (completed / total) * 100 : 0,
      avgResponse,
      avgService,
      totalAnimals,
    };
  }, [requests, statusCounts]);

  // --- Requests per day (last 7 days, real) ---
  const dailyData = useMemo(() => {
    const days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    const buckets = days.map((d) => ({ day: d, requests: 0, completed: 0 }));

    const now = new Date();
    const sevenDaysAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);

    for (const r of requests) {
      const d = toDate(r.createdAt);
      if (!d || d < sevenDaysAgo) continue;
      const dayIdx = d.getDay();
      buckets[dayIdx].requests += 1;
      if (r.status === "completed") buckets[dayIdx].completed += 1;
    }

    // Reorder to start from Monday
    return [1, 2, 3, 4, 5, 6, 0].map((i) => buckets[i]);
  }, [requests]);

  // --- Time slot distribution ---
  const timeSlotData = useMemo(() => {
    const slots = {};
    for (const r of requests) {
      const slot = r.timeSlot || "Unknown";
      slots[slot] = (slots[slot] || 0) + 1;
    }
    const colors = ["#10B981", "#3B82F6", "#F59E0B", "#8B5CF6", "#EF4444", "#EC4899"];
    return Object.entries(slots).map(([name, count], idx) => ({
      name,
      value: count,
      color: colors[idx % colors.length],
    }));
  }, [requests]);

  // --- Area aggregation with real completion rate + response times ---
  const areaPerformance = useMemo(() => {
    const map = new Map();
    for (const r of requests) {
      const area = extractArea(r.location);
      if (!map.has(area)) {
        map.set(area, {
          area,
          total: 0,
          completed: 0,
          pending: 0,
          assigned: 0,
          responseTimes: [],
        });
      }
      const entry = map.get(area);
      entry.total += 1;
      if (r.status === "completed") entry.completed += 1;
      else if (r.status === "pending") entry.pending += 1;
      else if (r.status === "assigned") entry.assigned += 1;

      const rt = minutesBetween(r.createdAt, r.assignedAt);
      if (rt !== null) entry.responseTimes.push(rt);
    }

    return Array.from(map.values())
      .map((e) => {
        const rate = e.total > 0 ? (e.completed / e.total) * 100 : 0;
        const avgResp =
          e.responseTimes.length > 0
            ? e.responseTimes.reduce((s, v) => s + v, 0) / e.responseTimes.length
            : null;
        let performance = "Poor";
        if (rate >= 90) performance = "Excellent";
        else if (rate >= 60) performance = "Good";
        else if (rate >= 30) performance = "Fair";

        return {
          area: e.area,
          total: e.total,
          completed: e.completed,
          pending: e.pending,
          rate,
          avgResponse: avgResp,
          performance,
        };
      })
      .sort((a, b) => b.total - a.total);
  }, [requests]);

  // --- Driver workload ---
  const driverWorkload = useMemo(() => {
    const map = new Map();
    for (const r of requests) {
      if (!r.driverName && !r.driverId) continue;
      const key = r.driverName || r.driverId;
      if (!map.has(key)) {
        map.set(key, { name: key, assigned: 0, completed: 0, serviceTimes: [] });
      }
      const entry = map.get(key);
      entry.assigned += 1;
      if (r.status === "completed") entry.completed += 1;
      const st = minutesBetween(r.assignedAt, r.completedAt);
      if (st !== null) entry.serviceTimes.push(st);
    }
    return Array.from(map.values())
      .map((e) => ({
        name: e.name,
        assigned: e.assigned,
        completed: e.completed,
        avgService:
          e.serviceTimes.length > 0
            ? e.serviceTimes.reduce((s, v) => s + v, 0) / e.serviceTimes.length
            : null,
      }))
      .sort((a, b) => b.assigned - a.assigned);
  }, [requests]);

  // --- Recent activity ---
  const recentActivity = useMemo(() => {
    return [...requests]
      .sort((a, b) => {
        const ta = toDate(a.createdAt)?.getTime() || 0;
        const tb = toDate(b.createdAt)?.getTime() || 0;
        return tb - ta;
      })
      .slice(0, 8);
  }, [requests]);

  if (loading) {
    return (
      <div className="flex">
        <Sidebar />
        <main className={cn(shell, "flex items-center justify-center p-8")}>
          <div className="flex flex-col items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-white shadow-card ring-1 ring-slate-200">
              <LoaderCircle className="h-6 w-6 animate-spin text-emerald-500" aria-hidden="true" />
            </div>
            <p className="text-sm font-medium text-slate-500">Loading analytics</p>
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
          {/* Header */}
          <div className={cn(
            "relative isolate overflow-hidden rounded-2xl bg-[linear-gradient(115deg,#064e3b_0%,#047857_52%,#0f766e_100%)] p-5 shadow-xl shadow-emerald-950/15 ring-1 ring-emerald-950/30 motion-safe:animate-slide-up sm:p-6 2xl:p-8",
            sectionGap
          )}>
            <Lattice
              id="eidclean-analytics-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div className="pointer-events-none absolute -right-10 -top-16 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl 2xl:h-64 2xl:w-64" aria-hidden="true" />
            <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-amber-200 ring-1 ring-white/20 backdrop-blur sm:h-11 sm:w-11 2xl:h-12 2xl:w-12">
                  <TrendingUp className="h-5 w-5 2xl:h-6 2xl:w-6" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold tracking-tight text-white sm:text-2xl">Reports & Analytics</h2>
                  <p className="mt-0.5 text-sm text-emerald-50/75">
                    Live operational insights — every metric computed from Firestore
                  </p>
                </div>
              </div>
              <Button className="h-9 shrink-0 bg-white px-3.5 text-emerald-900 shadow-lg shadow-emerald-950/20 hover:bg-emerald-50 active:bg-emerald-100 2xl:h-10 2xl:px-4">
                <Download className="h-4 w-4" aria-hidden="true" />
                Export Report
              </Button>
            </div>
          </div>

          {/* KPI Cards — all real */}
          <div className={cn("grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 xl:grid-cols-4 2xl:gap-6", sectionGap)}>
            {[
              {
                label: "Total Pickups",
                value: kpis.total,
                icon: Truck,
                variant: "green",
                description: `${kpis.completed} completed · ${kpis.pending} pending`,
              },
              {
                label: "Completion Rate",
                value: `${kpis.completionRate.toFixed(1)}%`,
                icon: CircleCheck,
                variant: "blue",
                description: kpis.total > 0 ? `${kpis.completed} of ${kpis.total} requests` : "No data yet",
              },
              {
                label: "Avg. Response Time",
                value: kpis.avgResponse != null ? `${kpis.avgResponse.toFixed(1)} min` : "—",
                icon: Clock,
                variant: "teal",
                description: "Request → Assigned",
              },
              {
                label: "Avg. Service Time",
                value: kpis.avgService != null ? `${kpis.avgService.toFixed(1)} min` : "—",
                icon: HardHat,
                variant: "yellow",
                description: "Assigned → Completed",
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

          {/* Daily Performance — real data */}
          <Card padding="none" className={cn("overflow-hidden", sectionGap)}>
            <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
              <div className={cn(iconTile, "from-emerald-50 to-emerald-100 text-emerald-600 ring-emerald-200")}>
                <ChartColumn className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
              </div>
              <div>
                <h3 className={cardTitle}>Requests by Day (Last 7 Days)</h3>
                <p className="text-xs text-slate-500">Total requests received vs completed</p>
              </div>
            </CardHeader>
            <CardBody className="px-2 pb-3 pt-4 sm:px-4 2xl:px-6 2xl:pb-4 2xl:pt-6">
              <ResponsiveContainer width="100%" height={230}>
                <BarChart data={dailyData} barGap={4}>
                  <defs>
                    <linearGradient id="eidclean-bar-req" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#34D399" />
                      <stop offset="100%" stopColor="#059669" />
                    </linearGradient>
                    <linearGradient id="eidclean-bar-comp" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#60A5FA" />
                      <stop offset="100%" stopColor="#2563EB" />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                  <XAxis dataKey="day" tick={{ fontSize: 12, fill: "#64748b" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 12, fill: "#64748b" }} axisLine={false} tickLine={false} allowDecimals={false} />
                  <Tooltip contentStyle={tooltipStyle} cursor={{ fill: "#f1f5f9" }} />
                  <Legend iconType="circle" wrapperStyle={{ fontSize: 12 }} />
                  <Bar dataKey="requests" fill="url(#eidclean-bar-req)" name="Received" radius={[6, 6, 0, 0]} />
                  <Bar dataKey="completed" fill="url(#eidclean-bar-comp)" name="Completed" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>

          {/* Time Slot + Status Distribution */}
          <div className={cn("grid grid-cols-1 gap-4 sm:gap-5 xl:grid-cols-3 2xl:gap-6", sectionGap)}>
            <Card padding="none" className="overflow-hidden xl:col-span-2">
              <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                <div className={cn(iconTile, "from-blue-50 to-blue-100 text-blue-600 ring-blue-200")}>
                  <ChartPie className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className={cardTitle}>Requests by Time Slot</h3>
                  <p className="text-xs text-slate-500">When users are requesting pickups</p>
                </div>
              </CardHeader>
              <CardBody className="px-3 py-4 sm:px-4 2xl:py-5">
                <ResponsiveContainer width="100%" height={220}>
                  <PieChart>
                    <Pie
                      data={timeSlotData}
                      cx="50%"
                      cy="50%"
                      innerRadius={50}
                      outerRadius={80}
                      paddingAngle={2}
                      dataKey="value"
                      label={({ name, value }) => `${value}`}
                      labelLine={false}
                    >
                      {timeSlotData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} stroke="#fff" strokeWidth={2} />
                      ))}
                    </Pie>
                    <Tooltip contentStyle={tooltipStyle} />
                  </PieChart>
                </ResponsiveContainer>
                <div className="mt-2 flex flex-wrap justify-center gap-1.5 2xl:gap-2">
                  {timeSlotData.map((entry) => (
                    <span key={entry.name} className="inline-flex items-center gap-1.5 rounded-full bg-slate-50 px-2.5 py-1 text-xs font-medium text-slate-600 ring-1 ring-slate-200">
                      <span className="h-2 w-2 rounded-full" style={{ backgroundColor: entry.color }} />
                      {entry.name} ({entry.value})
                    </span>
                  ))}
                </div>
              </CardBody>
            </Card>

            {/* Status breakdown */}
            <Card padding="none" className="overflow-hidden">
              <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                <div className={cn(iconTile, "from-amber-50 to-amber-100 text-amber-600 ring-amber-200")}>
                  <Layers className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className={cardTitle}>Request Status</h3>
                  <p className="text-xs text-slate-500">Live breakdown</p>
                </div>
              </CardHeader>
              <CardBody className="space-y-3 px-4 py-4 sm:px-5 2xl:py-5">
                {[
                  { label: "Pending", value: statusCounts.pending, color: "bg-amber-500" },
                  { label: "Assigned", value: statusCounts.assigned, color: "bg-blue-500" },
                  { label: "Completed", value: statusCounts.completed, color: "bg-emerald-500" },
                  { label: "Cancelled", value: statusCounts.cancelled, color: "bg-rose-500" },
                ].map((row) => {
                  const pct = kpis.total > 0 ? (row.value / kpis.total) * 100 : 0;
                  return (
                    <div key={row.label}>
                      <div className="mb-1 flex items-center justify-between text-sm">
                        <span className="flex items-center gap-2 text-slate-600">
                          <span className={cn("h-2.5 w-2.5 rounded-full", row.color)} />
                          {row.label}
                        </span>
                        <span className="font-semibold tabular-nums text-slate-900">
                          {row.value} <span className="text-xs text-slate-400">({pct.toFixed(0)}%)</span>
                        </span>
                      </div>
                      <div className="h-1.5 overflow-hidden rounded-full bg-slate-100">
                        <div className={cn("h-full rounded-full transition-all duration-500", row.color)} style={{ width: `${pct}%` }} />
                      </div>
                    </div>
                  );
                })}
              </CardBody>
            </Card>
          </div>

          {/* Area Performance + Driver Workload */}
          <div className={cn("grid grid-cols-1 gap-4 sm:gap-5 xl:grid-cols-3 2xl:gap-6", sectionGap)}>
            <Card padding="none" className="overflow-hidden xl:col-span-2">
              <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                <div className={cn(iconTile, "from-amber-50 to-amber-100 text-amber-600 ring-amber-200")}>
                  <MapPin className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className={cardTitle}>Area Performance</h3>
                  <p className="text-xs text-slate-500">Real completion & response metrics</p>
                </div>
              </CardHeader>
              <Table wrapperClassName="rounded-none border-0 border-t shadow-none">
                <TableHeader className="bg-slate-50/80">
                  <TableRow>
                    {["Area", "Total", "Completed", "Rate", "Avg Response", "Status"].map((h) => (
                      <TableHead key={h} className={headPad}>{h}</TableHead>
                    ))}
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {areaPerformance.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={6} className={cn(cellPad, "text-center text-sm text-slate-500")}>
                        No pickup requests yet
                      </TableCell>
                    </TableRow>
                  ) : (
                    areaPerformance.slice(0, 10).map((item) => (
                      <TableRow key={item.area} className="hover:bg-slate-50/80">
                        <TableCell className={cn(cellPad, "font-semibold text-slate-900")}>{item.area}</TableCell>
                        <TableCell className={cn(cellPad, "tabular-nums text-slate-600")}>{item.total}</TableCell>
                        <TableCell className={cn(cellPad, "tabular-nums text-slate-600")}>{item.completed}</TableCell>
                        <TableCell className={cn(cellPad, "tabular-nums text-slate-600")}>{item.rate.toFixed(0)}%</TableCell>
                        <TableCell className={cn(cellPad, "tabular-nums text-slate-600")}>
                          {item.avgResponse != null ? `${item.avgResponse.toFixed(1)} min` : "—"}
                        </TableCell>
                        <TableCell className={cellPad}>
                          <Badge
                            variant={
                              item.performance === "Excellent"
                                ? "green"
                                : item.performance === "Good"
                                ? "blue"
                                : item.performance === "Fair"
                                ? "yellow"
                                : "red"
                            }
                            dot
                          >
                            {item.performance}
                          </Badge>
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </Card>

            {/* Driver Workload */}
            <Card padding="none" className="overflow-hidden">
              <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                <div className={cn(iconTile, "from-sky-50 to-sky-100 text-sky-600 ring-sky-200")}>
                  <Users className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className={cardTitle}>Driver Workload</h3>
                  <p className="text-xs text-slate-500">Assignments per driver</p>
                </div>
              </CardHeader>
              <CardBody className="space-y-3 px-4 py-4 sm:px-5 2xl:py-5">
                {driverWorkload.length === 0 ? (
                  <p className="text-center text-sm text-slate-500 py-4">No assigned requests yet</p>
                ) : (
                  driverWorkload.map((driver) => (
                    <div key={driver.name} className="rounded-xl border border-slate-200 bg-white p-3">
                      <div className="flex items-center justify-between">
                        <span className="text-sm font-semibold text-slate-900">{driver.name}</span>
                        <span className="rounded-md bg-emerald-50 px-2 py-0.5 text-[11px] font-semibold text-emerald-700 ring-1 ring-emerald-100">
                          {driver.completed}/{driver.assigned}
                        </span>
                      </div>
                      <div className="mt-1.5 flex items-center justify-between text-xs text-slate-500">
                        <span>Assigned: {driver.assigned}</span>
                        <span>
                          {driver.avgService != null ? `~${driver.avgService.toFixed(1)} min avg` : "—"}
                        </span>
                      </div>
                    </div>
                  ))
                )}
              </CardBody>
            </Card>
          </div>

          {/* ML Prediction Overlay */}
          <Card padding="none" className={cn("relative isolate overflow-hidden border-emerald-700/40 bg-gradient-to-br from-emerald-900 via-emerald-950 to-slate-950 shadow-xl shadow-emerald-950/20", sectionGap)}>
            <Lattice
              id="eidclean-ml-overlay-lattice"
              className="inset-0 -z-10 h-full w-full text-emerald-200/[0.05] [mask-image:radial-gradient(ellipse_at_top_right,black,transparent_70%)]"
            />
            <div className="pointer-events-none absolute -right-20 -top-24 -z-10 h-72 w-72 rounded-full bg-emerald-400/20 blur-3xl" aria-hidden="true" />
            <CardHeader className={cn("flex items-center justify-between border-white/10", cardHeaderPad)}>
              <div className="flex items-center gap-3">
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-300/25 to-teal-400/10 text-emerald-200 ring-1 ring-emerald-200/25 2xl:h-10 2xl:w-10">
                  <Sparkles className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className="text-[15px] font-semibold tracking-tight text-white 2xl:text-base">
                    Eid Day 1 — District Forecast
                  </h3>
                  <p className="text-xs text-emerald-200/60">Aggregated from RandomForest model across top 20 localities</p>
                </div>
              </div>
              <Badge variant="green" dot className="bg-emerald-400/10 text-emerald-200 ring-emerald-300/30">
                ML Powered
              </Badge>
            </CardHeader>
            <CardBody className={cardBodyPad}>
              {mlLoading ? (
                <div className="flex items-center justify-center py-8">
                  <LoaderCircle className="h-5 w-5 animate-spin text-emerald-300/60" aria-hidden="true" />
                  <span className="ml-3 text-sm text-emerald-100/60">Computing district forecast...</span>
                </div>
              ) : mlPrediction ? (
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-4 sm:gap-4">
                  <div className="rounded-xl bg-white/[0.04] p-3.5 ring-1 ring-white/10 2xl:p-4">
                    <p className="text-[10px] font-semibold uppercase tracking-wider text-emerald-200/60">Total Waste</p>
                    <p className="mt-1 text-2xl font-semibold text-white 2xl:text-3xl">
                      {(mlPrediction.waste / 1000).toFixed(1)} t
                    </p>
                    <p className="text-xs text-emerald-100/50">{Math.round(mlPrediction.waste).toLocaleString()} kg</p>
                  </div>
                  <div className="rounded-xl bg-white/[0.04] p-3.5 ring-1 ring-white/10 2xl:p-4">
                    <p className="text-[10px] font-semibold uppercase tracking-wider text-emerald-200/60">Trucks</p>
                    <p className="mt-1 text-2xl font-semibold text-white 2xl:text-3xl">{mlPrediction.trucks}</p>
                    <p className="text-xs text-emerald-100/50">required</p>
                  </div>
                  <div className="rounded-xl bg-white/[0.04] p-3.5 ring-1 ring-white/10 2xl:p-4">
                    <p className="text-[10px] font-semibold uppercase tracking-wider text-emerald-200/60">Workers</p>
                    <p className="mt-1 text-2xl font-semibold text-white 2xl:text-3xl">{mlPrediction.workers}</p>
                    <p className="text-xs text-emerald-100/50">required</p>
                  </div>
                  <div className="rounded-xl bg-white/[0.04] p-3.5 ring-1 ring-white/10 2xl:p-4">
                    <p className="text-[10px] font-semibold uppercase tracking-wider text-emerald-200/60">Bins</p>
                    <p className="mt-1 text-2xl font-semibold text-white 2xl:text-3xl">{mlPrediction.bins}</p>
                    <p className="text-xs text-emerald-100/50">required</p>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-emerald-100/60">Forecast unavailable — check ML API</p>
              )}
            </CardBody>
          </Card>

          {/* Recent Activity Feed */}
          <Card padding="none" className="overflow-hidden">
            <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
              <div className={cn(iconTile, "from-teal-50 to-teal-100 text-teal-600 ring-teal-200")}>
                <Clock className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
              </div>
              <div>
                <h3 className={cardTitle}>Recent Activity</h3>
                <p className="text-xs text-slate-500">Latest pickup requests</p>
              </div>
            </CardHeader>
            <CardBody className="space-y-2 px-4 py-4 sm:px-5 2xl:py-5">
              {recentActivity.length === 0 ? (
                <p className="text-center text-sm text-slate-500 py-4">No activity yet</p>
              ) : (
                recentActivity.map((r) => {
                  const d = toDate(r.createdAt);
                  const timeLabel = d
                    ? d.toLocaleString("en-US", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })
                    : "—";
                  const dotColor =
                    r.status === "pending"
                      ? "bg-amber-500"
                      : r.status === "assigned"
                      ? "bg-blue-500"
                      : r.status === "completed"
                      ? "bg-emerald-500"
                      : "bg-rose-500";
                  return (
                    <div
                      key={r.id}
                      className="flex items-center gap-3 rounded-xl border border-slate-200 bg-white px-3.5 py-2.5 transition-colors hover:bg-slate-50/80"
                    >
                      <span className={cn("h-2 w-2 shrink-0 rounded-full", dotColor)} />
                      <div className="min-w-0 flex-1">
                        <div className="flex items-center gap-2">
                          <span className="truncate text-sm font-medium text-slate-900">
                            {extractArea(r.location)}
                          </span>
                          <span className="text-xs text-slate-400">·</span>
                          <span className="truncate text-xs text-slate-500">
                            {r.userName || "Unknown"}
                          </span>
                        </div>
                        <p className="mt-0.5 text-xs text-slate-400">
                          {timeLabel} · {r.animals || 0} animal{r.animals === 1 ? "" : "s"}
                        </p>
                      </div>
                      <Badge
                        variant={
                          r.status === "completed"
                            ? "green"
                            : r.status === "assigned"
                            ? "blue"
                            : r.status === "pending"
                            ? "yellow"
                            : "red"
                        }
                        dot
                      >
                        {r.status || "unknown"}
                      </Badge>
                    </div>
                  );
                })
              )}
            </CardBody>
          </Card>
        </div>
      </main>
    </div>
  );
}