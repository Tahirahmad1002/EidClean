// src/pages/Analytics.jsx

import { useEffect, useState } from "react";
import { collection, getDocs } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  Tooltip, ResponsiveContainer, PieChart, Pie, Cell,
  Legend
} from "recharts";
import {
  ChartColumn,
  ChartPie,
  CircleCheck,
  Clock,
  Download,
  Layers,
  LoaderCircle,
  MapPin,
  Trash2,
  TrendingUp,
  Truck,
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

// Shared responsive spacing: compact on laptops, roomy on large screens
const shell = "ml-64 min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)]";
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cardBodyPad = "px-4 py-4 sm:px-5 sm:py-5 2xl:px-6 2xl:py-6";
const cellPad = "px-4 py-3 sm:px-5 2xl:px-6 2xl:py-3.5";
const headPad = "px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3";
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
                    Comprehensive insights and performance metrics
                  </p>
                </div>
              </div>
              <Button className="h-9 shrink-0 bg-white px-3.5 text-emerald-900 shadow-lg shadow-emerald-950/20 hover:bg-emerald-50 active:bg-emerald-100 2xl:h-10 2xl:px-4">
                <Download className="h-4 w-4" aria-hidden="true" />
                Export Report
              </Button>
            </div>
          </div>

          {/* Stats Cards */}
          <div className={cn("grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 xl:grid-cols-4 2xl:gap-6", sectionGap)}>
            {[
              { label: "Total Pickups", value: stats.total, icon: Truck, variant: "green", trend: { direction: "up", value: "+12.5%" }, trendLabel: "from last week" },
              { label: "Completion Rate", value: `${stats.completionRate.toFixed(1)}%`, icon: CircleCheck, variant: "blue", trend: { direction: "up", value: "+2.1%" }, trendLabel: "improvement" },
              { label: "Total Waste (kg)", value: stats.wasteKg.toLocaleString(), icon: Trash2, variant: "teal", description: "Peak season" },
              { label: "Avg. Response Time", value: `${stats.responseTime} min`, icon: Clock, variant: "yellow", description: "-8 min faster" },
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

          {/* Weekly Performance */}
          <Card padding="none" className={cn("overflow-hidden", sectionGap)}>
            <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
              <div className={cn(iconTile, "from-emerald-50 to-emerald-100 text-emerald-600 ring-emerald-200")}>
                <ChartColumn className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
              </div>
              <div>
                <h3 className={cardTitle}>Weekly Performance</h3>
                <p className="text-xs text-slate-500">Completed and cancelled pickups by day</p>
              </div>
            </CardHeader>
            <CardBody className="px-2 pb-3 pt-4 sm:px-4 2xl:px-6 2xl:pb-4 2xl:pt-6">
              <ResponsiveContainer width="100%" height={230}>
                <BarChart data={weeklyData} barGap={4}>
                  <defs>
                    <linearGradient id="eidclean-bar-completed" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#34D399" />
                      <stop offset="100%" stopColor="#059669" />
                    </linearGradient>
                    <linearGradient id="eidclean-bar-cancelled" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#F87171" />
                      <stop offset="100%" stopColor="#DC2626" />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" vertical={false} />
                  <XAxis dataKey="day" tick={{ fontSize: 12, fill: "#64748b" }} axisLine={false} tickLine={false} />
                  <YAxis tick={{ fontSize: 12, fill: "#64748b" }} axisLine={false} tickLine={false} />
                  <Tooltip contentStyle={tooltipStyle} cursor={{ fill: "#f1f5f9" }} />
                  <Legend iconType="circle" wrapperStyle={{ fontSize: 12 }} />
                  <Bar dataKey="completed" fill="url(#eidclean-bar-completed)" name="Completed" radius={[6, 6, 0, 0]} />
                  <Bar dataKey="cancelled" fill="url(#eidclean-bar-cancelled)" name="Cancelled" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </CardBody>
          </Card>

          {/* Two Column: Area Performance + Waste Type */}
          <div className={cn("grid grid-cols-1 gap-4 sm:gap-5 xl:grid-cols-3 2xl:gap-6", sectionGap)}>
            <Card padding="none" className="overflow-hidden xl:col-span-2">
              <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                <div className={cn(iconTile, "from-amber-50 to-amber-100 text-amber-600 ring-amber-200")}>
                  <MapPin className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className={cardTitle}>Area Performance Summary</h3>
                  <p className="text-xs text-slate-500">Completion and response by service zone</p>
                </div>
              </CardHeader>
              <Table wrapperClassName="rounded-none border-0 border-t shadow-none">
                <TableHeader className="bg-slate-50/80">
                  <TableRow>
                    {["Area", "Total", "Completed", "Rate", "Response", "Performance"].map((h) => (
                      <TableHead key={h} className={headPad}>{h}</TableHead>
                    ))}
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {areaPerformance.map((item, index) => (
                    <TableRow key={index} className="hover:bg-slate-50/80">
                      <TableCell className={cn(cellPad, "font-semibold text-slate-900")}>{item.area}</TableCell>
                      <TableCell className={cn(cellPad, "tabular-nums text-slate-600")}>{item.total}</TableCell>
                      <TableCell className={cn(cellPad, "tabular-nums text-slate-600")}>{item.completed}</TableCell>
                      <TableCell className={cn(cellPad, "tabular-nums text-slate-600")}>{item.rate}</TableCell>
                      <TableCell className={cn(cellPad, "tabular-nums text-slate-600")}>{item.responseTime}</TableCell>
                      <TableCell className={cellPad}>
                        <Badge variant={item.performance === "Excellent" ? "green" : "blue"} dot>
                          {item.performance}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </Card>

            <Card padding="none" className="overflow-hidden">
              <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                <div className={cn(iconTile, "from-blue-50 to-blue-100 text-blue-600 ring-blue-200")}>
                  <ChartPie className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className={cardTitle}>Waste Type Distribution</h3>
                  <p className="text-xs text-slate-500">Share of requests by waste</p>
                </div>
              </CardHeader>
              <CardBody className="px-3 py-4 sm:px-4 2xl:py-5">
                <ResponsiveContainer width="100%" height={200}>
                  <PieChart>
                    <Pie
                      data={wasteTypeData}
                      cx="50%"
                      cy="50%"
                      innerRadius={46}
                      outerRadius={74}
                      paddingAngle={2}
                      dataKey="value"
                      label={({ name, value }) => `${name}: ${value}%`}
                      labelLine={false}
                    >
                      {wasteTypeData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} stroke="#fff" strokeWidth={2} />
                      ))}
                    </Pie>
                    <Tooltip contentStyle={tooltipStyle} />
                  </PieChart>
                </ResponsiveContainer>
                <div className="mt-2 flex flex-wrap justify-center gap-1.5 2xl:gap-2">
                  {wasteTypeData.map((entry) => (
                    <span key={entry.name} className="inline-flex items-center gap-1.5 rounded-full bg-slate-50 px-2.5 py-1 text-xs font-medium text-slate-600 ring-1 ring-slate-200">
                      <span className="h-2 w-2 rounded-full" style={{ backgroundColor: entry.color }} />
                      {entry.name}
                    </span>
                  ))}
                </div>
              </CardBody>
            </Card>
          </div>

          {/* Pickups by Area */}
          <Card padding="none" className="overflow-hidden">
            <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
              <div className={cn(iconTile, "from-teal-50 to-teal-100 text-teal-600 ring-teal-200")}>
                <Layers className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
              </div>
              <div>
                <h3 className={cardTitle}>Pickups by Area</h3>
                <p className="text-xs text-slate-500">Where requests are coming from</p>
              </div>
            </CardHeader>
            <CardBody className={cardBodyPad}>
              <div className="mb-4 flex flex-wrap gap-2 2xl:mb-5 2xl:gap-2.5">
                {areaData.map((item) => (
                  <div key={item.name} className="flex items-center gap-2 rounded-full bg-slate-50 py-1 pl-3 pr-3.5 ring-1 ring-slate-200 2xl:py-1.5">
                    <div className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: item.color }} />
                    <span className="text-sm text-slate-600">{item.name}</span>
                    <span className="text-sm font-semibold tabular-nums text-slate-900">{item.value}%</span>
                  </div>
                ))}
              </div>
              <div className="flex h-3 w-full gap-0.5 overflow-hidden rounded-full bg-slate-100 ring-1 ring-inset ring-slate-200 2xl:h-4">
                {areaData.map((item) => (
                  <div
                    key={item.name}
                    className="h-full first:rounded-l-full last:rounded-r-full"
                    style={{ width: `${item.value}%`, backgroundColor: item.color }}
                  />
                ))}
              </div>
            </CardBody>
          </Card>
        </div>
      </main>
    </div>
  );
}