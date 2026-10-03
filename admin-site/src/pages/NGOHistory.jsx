// src/pages/NGOHistory.jsx

import { useState } from "react";
import NGOSidebar from "../components/NGOSidebar";
import {
  CalendarDays,
  CircleCheck,
  Eye,
  HeartHandshake,
  History,
  MapPin,
  Phone,
  Scale,
  Search,
  StickyNote,
  X,
} from "lucide-react";
import {
  Avatar,
  Badge,
  Button,
  Card,
  CardHeader,
  Input,
  Modal,
  ModalBody,
  ModalFooter,
  StatCard,
  Table,
  TableBody,
  TableCell,
  TableEmpty,
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
  teal: "border-teal-200/70 from-teal-50 via-white to-white before:bg-teal-300/40 after:via-teal-400/70",
  green: "border-emerald-200/70 from-emerald-50 via-white to-white before:bg-emerald-300/40 after:via-emerald-400/70",
};

// Shared responsive spacing: compact on laptops, roomy on large screens
const shell = "min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)] lg:ml-64";
const mainPad = "px-4 pb-5 pt-[4.75rem] sm:px-6 sm:pb-6 sm:pt-20 lg:pt-6 2xl:px-10 2xl:py-8";
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cellPad = "px-4 py-3 sm:px-5 2xl:px-6 2xl:py-4";
const headCell = "px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3";

const statusVariant = { Completed: "green", Declined: "red", Cancelled: "gray" };

// Static dummy data (Firebase later). Dates are ISO yyyy-mm-dd.
const history = [
  { id: "DN-1031", date: "2026-05-29", citizen: "Sana Iqbal", phone: "+92 304 2217765", area: "Jinnahabad", meat: "Goat", kg: 18, status: "Completed", note: "Collected and distributed to 6 families." },
  { id: "DN-1030", date: "2026-05-29", citizen: "Hamza Raza", phone: "+92 315 7743320", area: "Nawanshehr", meat: "Beef", kg: 45, status: "Completed", note: "Collected and distributed to 14 families." },
  { id: "DN-1027", date: "2026-05-28", citizen: "Maryam Noor", phone: "+92 302 1198456", area: "Mirpur", meat: "Mutton", kg: 22, status: "Completed", note: "Collected and distributed to 7 families." },
  { id: "DN-1025", date: "2026-05-28", citizen: "Imran Shah", phone: "+92 336 5502981", area: "Supply Bazar", meat: "Beef", kg: 60, status: "Declined", note: "Declined: storage capacity reached for the day." },
  { id: "DN-1022", date: "2026-05-27", citizen: "Khadija Rauf", phone: "+92 311 6674409", area: "Mandian", meat: "Beef", kg: 38, status: "Completed", note: "Collected and distributed to 11 families." },
  { id: "DN-1019", date: "2026-05-27", citizen: "Tariq Mehmood", phone: "+92 340 8815273", area: "Habibullah Colony", meat: "Goat", kg: 12, status: "Cancelled", note: "Cancelled by the citizen before pickup." },
  { id: "DN-1015", date: "2026-05-26", citizen: "Rabia Aslam", phone: "+92 323 4476018", area: "Kakul Road", meat: "Mutton", kg: 28, status: "Completed", note: "Collected and distributed to 9 families." },
];

function formatDate(iso) {
  return new Date(`${iso}T00:00:00`).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

function DetailRow({ icon: Icon, label, children }) {
  return (
    <div className="flex gap-3">
      <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-slate-50 to-slate-100 text-slate-500 ring-1 ring-slate-200">
        <Icon className="h-4 w-4" aria-hidden="true" />
      </span>
      <div className="min-w-0">
        <p className="text-xs font-medium text-slate-400">{label}</p>
        <div className="font-semibold text-slate-900">{children}</div>
      </div>
    </div>
  );
}

export default function NGOHistory() {
  const [search, setSearch] = useState("");
  const [date, setDate] = useState("");
  const [selected, setSelected] = useState(null);

  const completed = history.filter((h) => h.status === "Completed");
  const totalKg = completed.reduce((sum, h) => sum + h.kg, 0);

  const stats = [
    { label: "Total Handled", value: history.length, icon: HeartHandshake, variant: "blue", description: "All past requests" },
    { label: "Completed", value: completed.length, icon: CircleCheck, variant: "green", description: "Successfully distributed" },
    { label: "Meat Collected", value: `${totalKg} kg`, icon: Scale, variant: "teal", description: "From completed pickups" },
  ];

  const query = search.trim().toLowerCase();
  const filtered = history.filter((h) => {
    const matchesSearch =
      !query ||
      h.citizen.toLowerCase().includes(query) ||
      h.area.toLowerCase().includes(query) ||
      h.id.toLowerCase().includes(query);
    const matchesDate = !date || h.date === date;
    return matchesSearch && matchesDate;
  });

  const hasFilters = Boolean(query || date);

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
              id="eidclean-ngo-history-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div className="pointer-events-none absolute -right-10 -top-16 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl 2xl:h-64 2xl:w-64" aria-hidden="true" />
            <div className="relative flex items-center gap-3 sm:gap-4">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-amber-200 ring-1 ring-white/20 backdrop-blur sm:h-11 sm:w-11 2xl:h-12 2xl:w-12">
                <History className="h-5 w-5 2xl:h-6 2xl:w-6" aria-hidden="true" />
              </div>
              <div>
                <h2 className="text-xl font-semibold tracking-tight text-white sm:text-2xl">Donation History</h2>
                <p className="mt-0.5 text-sm text-emerald-50/75">
                  Review every donation your NGO has handled
                </p>
              </div>
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

          {/* Search + Date filter */}
          <div className={cn("flex flex-wrap items-center gap-3 sm:gap-4", sectionGap)}>
            <div className="min-w-[220px] flex-1">
              <Input
                leftIcon={Search}
                type="text"
                placeholder="Search by citizen, area or ID..."
                aria-label="Search history"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="shadow-card"
              />
            </div>
            <div className="w-full sm:w-56">
              <Input
                leftIcon={CalendarDays}
                type="date"
                aria-label="Filter by date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                className="shadow-card"
              />
            </div>
            {hasFilters && (
              <Button
                variant="ghost"
                onClick={() => {
                  setSearch("");
                  setDate("");
                }}
                className="h-10 gap-1.5 px-3 text-xs"
              >
                <X className="h-3.5 w-3.5" aria-hidden="true" />
                Clear filters
              </Button>
            )}
          </div>

          {/* History Table */}
          <Card padding="none" className="overflow-hidden">
            <CardHeader className={cn("flex items-center justify-start gap-3", cardHeaderPad)}>
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-amber-50 to-amber-100 text-amber-600 ring-1 ring-amber-200 2xl:h-10 2xl:w-10">
                <History className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
              </div>
              <div>
                <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">
                  Past Donations
                </h3>
                <p className="text-xs text-slate-500">
                  Showing <span className="tabular-nums">{filtered.length}</span> of{" "}
                  <span className="tabular-nums">{history.length}</span> records
                </p>
              </div>
            </CardHeader>
            <Table className="min-w-[820px]" wrapperClassName="rounded-none border-0 border-t shadow-none">
              <TableHeader className="bg-slate-50/80">
                <TableRow>
                  <TableHead className={headCell}>Date</TableHead>
                  <TableHead className={headCell}>Citizen</TableHead>
                  <TableHead className={headCell}>Area</TableHead>
                  <TableHead className={headCell}>Meat</TableHead>
                  <TableHead className={headCell}>Status</TableHead>
                  <TableHead align="right" className={headCell}>Details</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.length === 0 ? (
                  <TableEmpty
                    colSpan={6}
                    icon={History}
                    title="No records found"
                    description="Try a different search or date"
                  />
                ) : (
                  filtered.map((h) => (
                    <TableRow key={h.id} className="group hover:bg-slate-50/80">
                      <TableCell className={cellPad}>
                        <span className="whitespace-nowrap font-medium tabular-nums text-slate-900">
                          {formatDate(h.date)}
                        </span>
                      </TableCell>
                      <TableCell className={cellPad}>
                        <div className="flex items-center gap-3">
                          <Avatar name={h.citizen} size="sm" />
                          <span className="whitespace-nowrap font-semibold text-slate-900">{h.citizen}</span>
                        </div>
                      </TableCell>
                      <TableCell className={cellPad}>
                        <span className="inline-flex items-center gap-1.5 whitespace-nowrap">
                          <MapPin className="h-3.5 w-3.5 text-emerald-600" aria-hidden="true" />
                          {h.area}
                        </span>
                      </TableCell>
                      <TableCell className={cellPad}>
                        <p className="whitespace-nowrap font-semibold tabular-nums text-slate-900">{h.kg} kg</p>
                        <p className="text-xs text-slate-500">{h.meat}</p>
                      </TableCell>
                      <TableCell className={cellPad}>
                        <Badge variant={statusVariant[h.status] || "gray"} dot>
                          {h.status}
                        </Badge>
                      </TableCell>
                      <TableCell align="right" className={cellPad}>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => setSelected(h)}
                          aria-label={`View details for ${h.citizen}`}
                          className="gap-1.5 hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-700"
                        >
                          <Eye className="h-3.5 w-3.5" aria-hidden="true" />
                          Details
                        </Button>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </Card>
        </div>
      </main>

      {/* Details Modal */}
      <Modal
        open={Boolean(selected)}
        onClose={() => setSelected(null)}
        title="Donation details"
        description={selected ? `${selected.id} — ${formatDate(selected.date)}` : undefined}
        size="md"
      >
        {selected && (
          <>
            <ModalBody>
              <div className="mb-5 flex items-center gap-3">
                <Avatar name={selected.citizen} size="lg" />
                <div className="min-w-0">
                  <p className="truncate text-base font-semibold text-slate-900">{selected.citizen}</p>
                  <Badge variant={statusVariant[selected.status] || "gray"} dot className="mt-1">
                    {selected.status}
                  </Badge>
                </div>
              </div>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <DetailRow icon={Phone} label="Phone">
                  <span className="tabular-nums">{selected.phone}</span>
                </DetailRow>
                <DetailRow icon={MapPin} label="Area">
                  {selected.area}
                </DetailRow>
                <DetailRow icon={Scale} label="Meat">
                  <span className="tabular-nums">{selected.kg} kg</span> — {selected.meat}
                </DetailRow>
                <DetailRow icon={CalendarDays} label="Date">
                  <span className="tabular-nums">{formatDate(selected.date)}</span>
                </DetailRow>
              </div>
              <div className="mt-5 rounded-xl bg-slate-50 p-3.5 ring-1 ring-slate-200">
                <p className="flex items-center gap-1.5 text-xs font-medium text-slate-400">
                  <StickyNote className="h-3.5 w-3.5" aria-hidden="true" />
                  Note
                </p>
                <p className="mt-1 text-sm leading-relaxed text-slate-700">{selected.note}</p>
              </div>
            </ModalBody>
            <ModalFooter>
              <Button variant="outline" onClick={() => setSelected(null)}>
                Close
              </Button>
            </ModalFooter>
          </>
        )}
      </Modal>
    </div>
  );
}