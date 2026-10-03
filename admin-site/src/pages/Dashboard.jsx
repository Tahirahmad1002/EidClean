// src/pages/Dashboard.jsx

import { useEffect, useState } from "react";
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
  EmptyState,
  StatCard,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../components/ui";
import { cn } from "../lib/utils";

// Eight-pointed star lattice used as brand texture
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

const insights = [
  { label: "Peak Hours", value: "9–11 AM, 4–6 PM", icon: Clock, bar: "before:bg-blue-500", tile: "bg-blue-50 text-blue-600 ring-blue-100", text: "text-blue-700" },
  { label: "High Demand", value: "Supply Bazar (+35%)", icon: TrendingUp, bar: "before:bg-amber-500", tile: "bg-amber-50 text-amber-600 ring-amber-100", text: "text-amber-700" },
  { label: "Tip", value: "Add 2 more drivers to Mirpur", icon: Lightbulb, bar: "before:bg-emerald-500", tile: "bg-emerald-50 text-emerald-600 ring-emerald-100", text: "text-emerald-700" },
];

// Shared responsive spacing: compact on laptops, roomy on large screens
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cardBodyPad = "px-4 py-4 sm:px-5 sm:py-5 2xl:px-6 2xl:py-6";
const cellPad = "px-4 py-3 sm:px-5 2xl:px-6 2xl:py-4";

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

export default function Dashboard() {
  const { user } = useAuth();
  const [stats, setStats] = useState({
    total: 0,
    pending: 0,
    assigned: 0,
    completed: 0,
    drivers: 0,
    areas: 0,
  });
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    async function fetchStats() {
      try {
        const requestsSnap = await getDocs(collection(db, "pickupRequests"));
        const driversSnap = await getDocs(collection(db, "drivers"));
        const areasSnap = await getDocs(collection(db, "areas"));

        const pending = requestsSnap.docs.filter(d => d.data().status === "pending").length;
        const assigned = requestsSnap.docs.filter(d => d.data().status === "assigned").length;
        const completed = requestsSnap.docs.filter(d => d.data().status === "completed").length;

        setStats({
          total: requestsSnap.size,
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

  // Dummy AI predictions data
  const aiPredictions = [
    { area: "Jinnahabad", trucks: 3, workers: 6, bins: 12 },
    { area: "Nawanshehr", trucks: 2, workers: 4, bins: 8 },
    { area: "Mirpur", trucks: 2, workers: 5, bins: 10 },
  ];

  // Pending pickups by area (dummy data for now)
  const pendingAreas = [
    { area: "Jinnahabad", requests: 12, status: "Pending", action: "Assign" },
    { area: "Nawanshehr", requests: 8, status: "Assigned", action: "Track" },
    { area: "Mirpur", requests: 5, status: "Completed", action: "View" },
    { area: "Supply Bazar", requests: 15, status: "Pending", action: "Assign" },
  ];

  const heroStats = [
    { label: "Pending", value: stats.pending, icon: Clock },
    { label: "Assigned", value: stats.assigned, icon: UserCheck },
    { label: "Completed", value: stats.completed, icon: CircleCheck },
  ];

  const shell = "ml-64 min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)]";

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
              { label: "On-Time Rate", value: "89%", icon: CircleCheck, variant: "green", description: "Pickups on schedule" },
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
                  AI predicts resource needs per area based on population density & past Eid data.
                </p>
                <div className="space-y-2">
                  {aiPredictions.map((item) => (
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
                  ))}
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
                  <p className="text-xs text-slate-500">What needs attention</p>
                </div>
              </CardHeader>
              <CardBody className="space-y-2.5 px-4 py-4 sm:px-5 2xl:space-y-3 2xl:py-5">
                {insights.map((item) => (
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
                      <p className="mt-0.5 text-sm font-semibold text-slate-900">{item.value}</p>
                    </div>
                  </div>
                ))}
              </CardBody>
            </Card>
          </div>

          {/* Live Map Placeholder */}
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
                  <p className="text-xs text-slate-500">Pickups and vehicles in real time</p>
                </div>
              </div>
              <div className="flex items-center gap-2 text-xs font-medium text-slate-600">
                <span className="inline-flex items-center gap-2 rounded-full bg-white px-3 py-1.5 shadow-sm ring-1 ring-slate-200">
                  <span className="h-2 w-2 rounded-full bg-emerald-500"></span> Pickup
                </span>
                <span className="inline-flex items-center gap-2 rounded-full bg-white px-3 py-1.5 shadow-sm ring-1 ring-slate-200">
                  <span className="h-2 w-2 rounded-full bg-blue-500"></span> Vehicle
                </span>
              </div>
            </CardHeader>
            <div className="relative flex h-52 items-center justify-center overflow-hidden bg-slate-50 bg-[linear-gradient(to_right,#e2e8f0_1px,transparent_1px),linear-gradient(to_bottom,#e2e8f0_1px,transparent_1px)] bg-[size:32px_32px] sm:h-60 2xl:h-80">
              <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_center,transparent_30%,rgba(248,250,252,0.9)_100%)]" aria-hidden="true" />
              {/* Decorative pins */}
              <span className="absolute left-[18%] top-[28%] flex h-3 w-3" aria-hidden="true">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-60"></span>
                <span className="relative inline-flex h-3 w-3 rounded-full bg-emerald-500 ring-2 ring-white"></span>
              </span>
              <span className="absolute left-[72%] top-[24%] flex h-3 w-3" aria-hidden="true">
                <span className="relative inline-flex h-3 w-3 rounded-full bg-blue-500 ring-2 ring-white"></span>
              </span>
              <span className="absolute left-[30%] top-[70%] flex h-3 w-3" aria-hidden="true">
                <span className="relative inline-flex h-3 w-3 rounded-full bg-blue-500 ring-2 ring-white"></span>
              </span>
              <span className="absolute left-[80%] top-[68%] flex h-3 w-3" aria-hidden="true">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-60"></span>
                <span className="relative inline-flex h-3 w-3 rounded-full bg-emerald-500 ring-2 ring-white"></span>
              </span>

              <EmptyState
                icon={MapIcon}
                variant="green"
                title="Live map coming soon"
                description="Real-time pickup tracking will appear here"
                bordered={false}
                className="relative z-10 mx-auto max-w-sm rounded-2xl bg-white/90 px-5 py-5 shadow-xl shadow-slate-900/5 ring-1 ring-slate-200 backdrop-blur 2xl:py-8"
              />
            </div>
          </Card>

          {/* Pending Pickups by Area */}
          <Card padding="none" className="overflow-hidden">
            <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-amber-50 to-amber-100 text-amber-600 ring-1 ring-amber-200 2xl:h-10 2xl:w-10">
                <ClipboardList className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
              </div>
              <div>
                <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">
                  Pending Pickups by Area
                </h3>
                <p className="text-xs text-slate-500">Requests grouped by service zone</p>
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
                {pendingAreas.map((item) => (
                  <PendingAreaRow key={item.area} {...item} />
                ))}
              </TableBody>
            </Table>
          </Card>
        </div>
      </main>
    </div>
  );
}