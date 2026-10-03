// src/pages/NGOAcceptedPickups.jsx

import NGOSidebar from "../components/NGOSidebar";
import {
  CalendarDays,
  CircleCheck,
  Clock,
  Info,
  MapPin,
  PackageCheck,
  Phone,
  Truck,
} from "lucide-react";
import {
  Avatar,
  Badge,
  Button,
  Card,
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
  blue: "border-blue-200/70 from-blue-50 via-white to-white before:bg-blue-300/40 after:via-blue-400/70",
  yellow: "border-amber-200/70 from-amber-50 via-white to-white before:bg-amber-300/40 after:via-amber-400/70",
  green: "border-emerald-200/70 from-emerald-50 via-white to-white before:bg-emerald-300/40 after:via-emerald-400/70",
};

// Shared responsive spacing: compact on laptops, roomy on large screens
const shell = "min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)] lg:ml-64";
const mainPad = "px-4 pb-5 pt-[4.75rem] sm:px-6 sm:pb-6 sm:pt-20 lg:pt-6 2xl:px-10 2xl:py-8";
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cellPad = "px-4 py-3 sm:px-5 2xl:px-6 2xl:py-4";
const headCell = "px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3";

const statusVariant = { Scheduled: "blue", "On the Way": "yellow", Collected: "green" };

// Static dummy data (Firebase later)
const pickups = [
  { id: "PK-2031", citizen: "Usman Tariq", phone: "+92 333 9081726", area: "Mirpur", meat: "Beef", kg: 20, time: "11:30 AM", status: "Scheduled" },
  { id: "PK-2030", citizen: "Zainab Hussain", phone: "+92 322 8830154", area: "Kakul Road", meat: "Mutton", kg: 25, time: "12:15 PM", status: "On the Way" },
  { id: "PK-2029", citizen: "Sana Iqbal", phone: "+92 304 2217765", area: "Jinnahabad", meat: "Goat", kg: 18, time: "09:30 AM", status: "Collected" },
  { id: "PK-2028", citizen: "Hamza Raza", phone: "+92 315 7743320", area: "Nawanshehr", meat: "Beef", kg: 45, time: "02:00 PM", status: "Scheduled" },
];

export default function NGOAcceptedPickups() {
  const total = pickups.length;
  const awaiting = pickups.filter((p) => p.status !== "Collected").length;
  const collected = pickups.filter((p) => p.status === "Collected").length;

  const stats = [
    { label: "Total Accepted", value: total, icon: PackageCheck, variant: "blue", description: "Confirmed donations" },
    { label: "Awaiting Pickup", value: awaiting, icon: Clock, variant: "yellow", description: "Scheduled or on the way" },
    { label: "Collected", value: collected, icon: CircleCheck, variant: "green", description: "Received at your centre" },
  ];

  return (
    <div className="flex">
      <NGOSidebar />
      <main className={cn(shell, mainPad)}>
        <div className="mx-auto max-w-7xl">
          {/* Header */}
          <div className={cn(
            "relative isolate overflow-hidden rounded-2xl bg-[linear-gradient(115deg,#064e3b_0%,#047857_52%,#0f766e_100%)] p-5 shadow-xl shadow-emerald-950/15 ring-1 ring-emerald-950/30 motion-safe:animate-slide-up sm:p-6 2xl:p-8",
            sectionGap
          )}>
            <Lattice
              id="eidclean-ngo-pickups-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div className="pointer-events-none absolute -right-10 -top-16 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl 2xl:h-64 2xl:w-64" aria-hidden="true" />
            <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-amber-200 ring-1 ring-white/20 backdrop-blur sm:h-11 sm:w-11 2xl:h-12 2xl:w-12">
                  <PackageCheck className="h-5 w-5 2xl:h-6 2xl:w-6" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold tracking-tight text-white sm:text-2xl">Accepted Pickups</h2>
                  <p className="mt-0.5 text-sm text-emerald-50/75">
                    Track confirmed donations and coordinate collection
                  </p>
                </div>
              </div>
              <span className="inline-flex shrink-0 items-center gap-2 self-start rounded-full bg-white/10 px-3 py-1.5 text-xs font-medium text-emerald-50 ring-1 ring-white/20 backdrop-blur sm:self-auto">
                <CalendarDays className="h-3.5 w-3.5 text-amber-200" aria-hidden="true" />
                {new Date().toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric", year: "numeric" })}
              </span>
            </div>
          </div>

          {/* Info banner */}
          <div
            className={cn(
              "relative flex items-start gap-3 overflow-hidden rounded-xl border border-amber-200/80 bg-gradient-to-r from-amber-50 via-amber-50/70 to-white p-4 shadow-card sm:items-center sm:p-5",
              sectionGap
            )}
            role="note"
          >
            <span className="absolute inset-y-3 left-0 w-1 rounded-r-full bg-amber-500" aria-hidden="true" />
            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-amber-100 text-amber-600 ring-1 ring-amber-200 2xl:h-10 2xl:w-10">
              <Info className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
            </span>
            <div className="min-w-0">
              <p className="text-sm font-semibold text-amber-900">Confirm the pickup time with each citizen</p>
              <p className="mt-0.5 text-sm leading-relaxed text-amber-800/80">
                Accepted donations are reserved for your NGO. Use the Contact button to agree on an exact time and address before dispatching your team.
              </p>
            </div>
          </div>

          {/* Stats */}
          <div className={cn("grid grid-cols-1 gap-3 sm:grid-cols-3 sm:gap-5 2xl:gap-6", sectionGap)}>
            {stats.map((card) => (
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

          {/* Pickups Table */}
          <Card padding="none" className="overflow-hidden">
            <CardHeader className={cn("flex items-center justify-start gap-3", cardHeaderPad)}>
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 text-emerald-600 ring-1 ring-emerald-200 2xl:h-10 2xl:w-10">
                <Truck className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
              </div>
              <div>
                <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">
                  Pickup Schedule
                </h3>
                <p className="text-xs text-slate-500">Donations you have accepted</p>
              </div>
            </CardHeader>
            <Table className="min-w-[820px]" wrapperClassName="rounded-none border-0 border-t shadow-none">
              <TableHeader className="bg-slate-50/80">
                <TableRow>
                  <TableHead className={headCell}>Citizen</TableHead>
                  <TableHead className={headCell}>Area</TableHead>
                  <TableHead className={headCell}>Meat</TableHead>
                  <TableHead className={headCell}>Pickup Time</TableHead>
                  <TableHead className={headCell}>Status</TableHead>
                  <TableHead align="right" className={headCell}>Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {pickups.map((p) => (
                  <TableRow key={p.id} className="group hover:bg-slate-50/80">
                    <TableCell className={cellPad}>
                      <div className="flex items-center gap-3">
                        <Avatar name={p.citizen} size="sm" />
                        <div className="min-w-0">
                          <p className="whitespace-nowrap font-semibold text-slate-900">{p.citizen}</p>
                          <p className="whitespace-nowrap text-xs tabular-nums text-slate-500">{p.phone}</p>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className={cellPad}>
                      <span className="inline-flex items-center gap-1.5 whitespace-nowrap">
                        <MapPin className="h-3.5 w-3.5 text-emerald-600" aria-hidden="true" />
                        {p.area}
                      </span>
                    </TableCell>
                    <TableCell className={cellPad}>
                      <p className="whitespace-nowrap font-semibold tabular-nums text-slate-900">{p.kg} kg</p>
                      <p className="text-xs text-slate-500">{p.meat}</p>
                    </TableCell>
                    <TableCell className={cellPad}>
                      <p className="whitespace-nowrap font-medium tabular-nums text-slate-900">{p.time}</p>
                      <p className="text-xs text-slate-500">Today</p>
                    </TableCell>
                    <TableCell className={cellPad}>
                      <Badge variant={statusVariant[p.status] || "gray"} dot>
                        {p.status}
                      </Badge>
                    </TableCell>
                    <TableCell align="right" className={cellPad}>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => {
                          window.location.href = `tel:${p.phone.replace(/\s/g, "")}`;
                        }}
                        aria-label={`Contact ${p.citizen}`}
                        className="gap-1.5 hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-700"
                      >
                        <Phone className="h-3.5 w-3.5" aria-hidden="true" />
                        Contact
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </Card>
        </div>
      </main>
    </div>
  );
}