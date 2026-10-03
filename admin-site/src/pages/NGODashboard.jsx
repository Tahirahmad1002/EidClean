// src/pages/NGODashboard.jsx

import { useState } from "react";
import { useNavigate } from "react-router-dom";
import NGOSidebar from "../components/NGOSidebar";
import {
  Activity,
  ArrowRight,
  CalendarDays,
  Check,
  CircleCheck,
  CircleX,
  Clock,
  Eye,
  HeartHandshake,
  MapPin,
  Moon,
  PackageCheck,
  Scale,
  Target,
  Truck,
  Users,
  X,
} from "lucide-react";
import {
  Avatar,
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

// Shared responsive spacing: compact on laptops, roomy on large screens
const shell = "min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)] lg:ml-64";
const mainPad = "px-4 pb-5 pt-[4.75rem] sm:px-6 sm:pb-6 sm:pt-20 lg:pt-6 2xl:px-10 2xl:py-8";
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cardBodyPad = "px-4 py-4 sm:px-5 sm:py-5 2xl:px-6 2xl:py-6";
const cellPad = "px-4 py-3 sm:px-5 2xl:px-6 2xl:py-4";
const headCell = "px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3";

const statusVariant = { Pending: "yellow", Accepted: "blue", Declined: "red" };

// Static dummy data (Firebase later)
const initialRequests = [
  { id: "DN-1048", citizen: "Ahmed Khan", phone: "+92 300 1234567", area: "Jinnahabad", meat: "Beef", kg: 50, status: "Pending" },
  { id: "DN-1047", citizen: "Fatima Ali", phone: "+92 321 7654321", area: "Nawanshehr", meat: "Mutton", kg: 30, status: "Pending" },
  { id: "DN-1046", citizen: "Usman Tariq", phone: "+92 333 9081726", area: "Mirpur", meat: "Beef", kg: 20, status: "Accepted" },
  { id: "DN-1045", citizen: "Hassan Malik", phone: "+92 345 5512098", area: "Supply Bazar", meat: "Beef", kg: 40, status: "Pending" },
  { id: "DN-1044", citizen: "Ayesha Siddiqui", phone: "+92 312 4409871", area: "Mandian", meat: "Goat", kg: 15, status: "Declined" },
  { id: "DN-1043", citizen: "Bilal Ahmed", phone: "+92 301 6620345", area: "Habibullah Colony", meat: "Beef", kg: 35, status: "Pending" },
  { id: "DN-1042", citizen: "Zainab Hussain", phone: "+92 322 8830154", area: "Kakul Road", meat: "Mutton", kg: 25, status: "Accepted" },
];

const DAILY_TARGET_KG = 200;

const activity = [
  { icon: HeartHandshake, text: "New request from Bilal Ahmed", meta: "Habibullah Colony", time: "2 min ago", tile: "bg-amber-50 text-amber-600 ring-amber-100" },
  { icon: PackageCheck, text: "Pickup collected from Sana Iqbal", meta: "Jinnahabad", time: "14 min ago", tile: "bg-emerald-50 text-emerald-600 ring-emerald-100" },
  { icon: Truck, text: "Team on the way to Zainab Hussain", meta: "Kakul Road", time: "26 min ago", tile: "bg-blue-50 text-blue-600 ring-blue-100" },
  { icon: CircleX, text: "Request declined for Ayesha Siddiqui", meta: "Mandian", time: "41 min ago", tile: "bg-red-50 text-red-600 ring-red-100" },
  { icon: Check, text: "Donation accepted from Usman Tariq", meta: "Mirpur", time: "1 hr ago", tile: "bg-teal-50 text-teal-600 ring-teal-100" },
];

function RequestRow({ request, onAccept, onDecline, onView }) {
  const isPending = request.status === "Pending";

  return (
    <TableRow className="group hover:bg-slate-50/80">
      <TableCell className={cellPad}>
        <div className="flex items-center gap-3">
          <Avatar name={request.citizen} size="sm" />
          <div className="min-w-0">
            <p className="whitespace-nowrap font-semibold text-slate-900">{request.citizen}</p>
            <p className="whitespace-nowrap text-xs tabular-nums text-slate-500">{request.phone}</p>
          </div>
        </div>
      </TableCell>
      <TableCell className={cellPad}>
        <span className="inline-flex items-center gap-1.5 whitespace-nowrap">
          <MapPin className="h-3.5 w-3.5 text-emerald-600" aria-hidden="true" />
          {request.area}
        </span>
      </TableCell>
      <TableCell className={cellPad}>
        <p className="whitespace-nowrap font-semibold tabular-nums text-slate-900">{request.kg} kg</p>
        <p className="text-xs text-slate-500">{request.meat}</p>
      </TableCell>
      <TableCell className={cellPad}>
        <Badge variant={statusVariant[request.status] || "gray"} dot>
          {request.status}
        </Badge>
      </TableCell>
      <TableCell align="right" className={cellPad}>
        {isPending ? (
          <div className="flex items-center justify-end gap-2">
            <Button
              size="sm"
              onClick={() => onAccept(request.id)}
              className="gap-1.5 bg-emerald-600 shadow-sm shadow-emerald-600/20 hover:bg-emerald-700"
            >
              <Check className="h-3.5 w-3.5" aria-hidden="true" />
              Accept
            </Button>
            <Button
              size="sm"
              variant="outline"
              onClick={() => onDecline(request.id)}
              className="gap-1.5 hover:border-red-300 hover:bg-red-50 hover:text-red-700"
            >
              <X className="h-3.5 w-3.5" aria-hidden="true" />
              Decline
            </Button>
          </div>
        ) : (
          <Button
            size="sm"
            variant="outline"
            onClick={onView}
            className="gap-1.5 hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-700"
          >
            <Eye className="h-3.5 w-3.5" aria-hidden="true" />
            View
          </Button>
        )}
      </TableCell>
    </TableRow>
  );
}

export default function NGODashboard() {
  const navigate = useNavigate();
  const [requests, setRequests] = useState(initialRequests);

  let ngoUser = {};
  try {
    ngoUser = JSON.parse(localStorage.getItem("ngoUser") || "{}") || {};
  } catch {
    ngoUser = {};
  }

  function updateStatus(id, status) {
    setRequests((prev) => prev.map((r) => (r.id === id ? { ...r, status } : r)));
  }

  const pending = requests.filter((r) => r.status === "Pending").length;
  const accepted = requests.filter((r) => r.status === "Accepted");
  const declined = requests.filter((r) => r.status === "Declined").length;
  const securedKg = accepted.reduce((sum, r) => sum + r.kg, 0);
  const targetPct = Math.min(100, Math.round((securedKg / DAILY_TARGET_KG) * 100));

  const heroStats = [
    { label: "Pending", value: pending, icon: Clock },
    { label: "Accepted", value: accepted.length, icon: CircleCheck },
    { label: "Declined", value: declined, icon: CircleX },
  ];

  const summaryRows = [
    { icon: CircleCheck, tone: "text-emerald-300", label: "Accepted", value: accepted.length },
    { icon: CircleX, tone: "text-red-300", label: "Declined", value: declined },
    { icon: Scale, tone: "text-amber-300", label: "Meat secured", value: `${securedKg} kg` },
  ];

  return (
    <div className="flex">
      <NGOSidebar />
      <main className={cn(shell, mainPad)}>
        <div className="mx-auto max-w-7xl">
          {/* Hero */}
          <div className={cn(
            "relative isolate overflow-hidden rounded-2xl bg-[linear-gradient(115deg,#064e3b_0%,#047857_52%,#0f766e_100%)] p-5 shadow-xl shadow-emerald-950/20 ring-1 ring-emerald-950/30 motion-safe:animate-slide-up sm:p-6 2xl:p-8",
            sectionGap
          )}>
            <Lattice
              id="eidclean-ngo-hero-lattice"
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
                  Welcome, {ngoUser?.name || "NGO Admin"}!
                </h2>
                <p className="mt-1 text-sm leading-relaxed text-emerald-50/75 2xl:mt-2 2xl:text-[15px]">
                  Edhi Foundation — Abbottabad Meat Donation Network
                </p>
                <div className="mt-4 flex flex-wrap gap-2.5 2xl:mt-6 2xl:gap-3">
                  <Button
                    onClick={() => navigate("/ngo-donations")}
                    className="group h-9 bg-white px-3.5 text-emerald-900 shadow-lg shadow-emerald-950/20 hover:bg-emerald-50 active:bg-emerald-100 2xl:h-10 2xl:px-4"
                  >
                    <HeartHandshake className="h-4 w-4" aria-hidden="true" />
                    Review requests
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => navigate("/ngo-pickups")}
                    className="group h-9 border-white/25 bg-white/10 px-3.5 text-white backdrop-blur hover:border-white/40 hover:bg-white/20 hover:text-white active:bg-white/25 2xl:h-10 2xl:px-4"
                  >
                    <PackageCheck className="h-4 w-4 text-amber-200" aria-hidden="true" />
                    View pickups
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
              { label: "Total Donations", value: "2,450", icon: HeartHandshake, variant: "blue", trend: { direction: "up", value: "+15%" }, trendLabel: "from last week" },
              { label: "Meat Collected", value: "1,850 kg", icon: Scale, variant: "teal", trend: { direction: "up", value: "+8%" }, trendLabel: "from last week" },
              { label: "Families Served", value: "1,247", icon: Users, variant: "green", trend: { direction: "up", value: "+12%" }, trendLabel: "from last week" },
              { label: "Pending Requests", value: pending, icon: Clock, variant: "yellow", description: "Awaiting your response" },
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

          {/* Requests + Side column */}
          <div className="grid grid-cols-1 gap-4 sm:gap-5 xl:grid-cols-3 2xl:gap-6">
            {/* Recent Donation Requests */}
            <Card padding="none" className="min-w-0 overflow-hidden xl:col-span-2">
              <CardHeader className={cn("flex flex-wrap items-center justify-between gap-3", cardHeaderPad)}>
                <div className="flex items-center gap-3">
                  <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-amber-50 to-amber-100 text-amber-600 ring-1 ring-amber-200 2xl:h-10 2xl:w-10">
                    <HeartHandshake className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                  </div>
                  <div>
                    <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">
                      Recent Donation Requests
                    </h3>
                    <p className="text-xs text-slate-500">Latest offers from citizens</p>
                  </div>
                </div>
                <Button
                  variant="outline"
                  onClick={() => navigate("/ngo-donations")}
                  className="group/btn h-8 gap-1.5 px-3 text-xs hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-700"
                >
                  View all
                  <ArrowRight
                    className="h-3.5 w-3.5 transition-transform duration-150 group-hover/btn:translate-x-0.5"
                    aria-hidden="true"
                  />
                </Button>
              </CardHeader>
              <Table className="min-w-[680px]" wrapperClassName="rounded-none border-0 border-t shadow-none">
                <TableHeader className="bg-slate-50/80">
                  <TableRow>
                    <TableHead className={headCell}>Citizen</TableHead>
                    <TableHead className={headCell}>Area</TableHead>
                    <TableHead className={headCell}>Meat</TableHead>
                    <TableHead className={headCell}>Status</TableHead>
                    <TableHead align="right" className={headCell}>Action</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {requests.slice(0, 6).map((request) => (
                    <RequestRow
                      key={request.id}
                      request={request}
                      onAccept={(id) => updateStatus(id, "Accepted")}
                      onDecline={(id) => updateStatus(id, "Declined")}
                      onView={() => navigate("/ngo-donations")}
                    />
                  ))}
                </TableBody>
              </Table>
            </Card>

            {/* Side column */}
            <div className="flex min-w-0 flex-col gap-4 sm:gap-5 2xl:gap-6">
              {/* Today's Summary */}
              <Card
                padding="none"
                className="relative isolate overflow-hidden border-emerald-700/40 bg-gradient-to-br from-emerald-900 via-emerald-950 to-slate-950 shadow-xl shadow-emerald-950/20"
              >
                <Lattice
                  id="eidclean-ngo-summary-lattice"
                  className="inset-0 -z-10 h-full w-full text-emerald-200/[0.05] [mask-image:radial-gradient(ellipse_at_top_right,black,transparent_70%)]"
                />
                <div className="pointer-events-none absolute -right-20 -top-24 -z-10 h-72 w-72 rounded-full bg-emerald-400/20 blur-3xl" aria-hidden="true" />
                <div className="pointer-events-none absolute -bottom-24 -left-16 -z-10 h-56 w-56 rounded-full bg-amber-400/10 blur-3xl" aria-hidden="true" />
                <CardHeader className={cn("flex items-center justify-start gap-3 border-white/10", cardHeaderPad)}>
                  <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-300/25 to-teal-400/10 text-emerald-200 ring-1 ring-emerald-200/25 2xl:h-10 2xl:w-10">
                    <CalendarDays className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                  </div>
                  <div>
                    <h3 className="text-[15px] font-semibold tracking-tight text-white 2xl:text-base">
                      Today&apos;s Summary
                    </h3>
                    <p className="text-xs text-emerald-200/60">Your response so far</p>
                  </div>
                </CardHeader>
                <CardBody className={cardBodyPad}>
                  <div className="space-y-2">
                    {summaryRows.map((row) => (
                      <div
                        key={row.label}
                        className="flex items-center justify-between gap-3 rounded-xl bg-white/[0.04] px-3.5 py-2.5 ring-1 ring-white/10 transition-all duration-150 hover:bg-white/[0.08] hover:ring-white/20 2xl:px-4 2xl:py-3"
                      >
                        <span className="flex items-center gap-2.5 text-sm font-medium text-emerald-50/85">
                          <row.icon className={cn("h-4 w-4", row.tone)} aria-hidden="true" />
                          {row.label}
                        </span>
                        <span className="text-base font-semibold tabular-nums text-white">{row.value}</span>
                      </div>
                    ))}
                  </div>

                  <div className="mt-4 2xl:mt-5">
                    <div className="mb-2 flex items-center justify-between text-xs">
                      <span className="inline-flex items-center gap-1.5 font-medium text-emerald-100/70">
                        <Target className="h-3.5 w-3.5 text-amber-300" aria-hidden="true" />
                        Daily target ({DAILY_TARGET_KG} kg)
                      </span>
                      <span className="font-semibold tabular-nums text-amber-200">{targetPct}%</span>
                    </div>
                    <div
                      className="h-2 overflow-hidden rounded-full bg-black/25 ring-1 ring-white/10"
                      role="progressbar"
                      aria-valuenow={targetPct}
                      aria-valuemin={0}
                      aria-valuemax={100}
                      aria-label="Daily meat target progress"
                    >
                      <div
                        className="h-full rounded-full bg-gradient-to-r from-amber-300 to-amber-400 transition-all duration-500"
                        style={{ width: `${targetPct}%` }}
                      />
                    </div>
                  </div>
                </CardBody>
              </Card>

              {/* Live Activity */}
              <Card padding="none" className="overflow-hidden">
                <CardHeader className={cn("flex items-center justify-between gap-3", cardHeaderPad)}>
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 text-emerald-600 ring-1 ring-emerald-200 2xl:h-10 2xl:w-10">
                      <Activity className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                    </div>
                    <div>
                      <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">
                        Live Activity
                      </h3>
                      <p className="text-xs text-slate-500">What is happening now</p>
                    </div>
                  </div>
                  <Badge variant="green" dot>
                    Live
                  </Badge>
                </CardHeader>
                <CardBody className={cardBodyPad}>
                  <ul>
                    {activity.map((item) => (
                      <li
                        key={item.text}
                        className="relative flex gap-3 pb-4 last:pb-0 before:absolute before:bottom-0 before:left-[17px] before:top-10 before:w-px before:bg-slate-200 last:before:hidden"
                      >
                        <div className={cn("relative flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ring-1", item.tile)}>
                          <item.icon className="h-4 w-4" aria-hidden="true" />
                        </div>
                        <div className="min-w-0 flex-1">
                          <p className="text-sm font-semibold text-slate-900">{item.text}</p>
                          <p className="mt-0.5 flex flex-wrap items-center gap-x-2 text-xs text-slate-500">
                            <span className="inline-flex items-center gap-1">
                              <MapPin className="h-3 w-3" aria-hidden="true" />
                              {item.meta}
                            </span>
                            <span className="h-1 w-1 rounded-full bg-slate-300" aria-hidden="true" />
                            <span>{item.time}</span>
                          </p>
                        </div>
                      </li>
                    ))}
                  </ul>
                </CardBody>
              </Card>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}