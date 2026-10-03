// src/pages/NGODonations.jsx

import { useState } from "react";
import NGOSidebar from "../components/NGOSidebar";
import {
  Check,
  Clock,
  Eye,
  HeartHandshake,
  Inbox,
  MapPin,
  Phone,
  Scale,
  Search,
  User,
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

// Shared responsive spacing: compact on laptops, roomy on large screens
const shell = "min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)] lg:ml-64";
const mainPad = "px-4 pb-5 pt-[4.75rem] sm:px-6 sm:pb-6 sm:pt-20 lg:pt-6 2xl:px-10 2xl:py-8";
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cellPad = "px-4 py-3 sm:px-5 2xl:px-6 2xl:py-4";
const headCell = "px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3";

const statusVariant = { Pending: "yellow", Accepted: "blue", Declined: "red" };
const filters = ["All", "Pending", "Accepted", "Declined"];

// Static dummy data (Firebase later)
const initialRequests = [
  { id: "DN-1048", citizen: "Ahmed Khan", phone: "+92 300 1234567", area: "Jinnahabad", meat: "Beef", kg: 50, time: "10:30 AM", status: "Pending" },
  { id: "DN-1047", citizen: "Fatima Ali", phone: "+92 321 7654321", area: "Nawanshehr", meat: "Mutton", kg: 30, time: "10:05 AM", status: "Pending" },
  { id: "DN-1046", citizen: "Usman Tariq", phone: "+92 333 9081726", area: "Mirpur", meat: "Beef", kg: 20, time: "09:40 AM", status: "Accepted" },
  { id: "DN-1045", citizen: "Hassan Malik", phone: "+92 345 5512098", area: "Supply Bazar", meat: "Beef", kg: 40, time: "09:15 AM", status: "Pending" },
  { id: "DN-1044", citizen: "Ayesha Siddiqui", phone: "+92 312 4409871", area: "Mandian", meat: "Goat", kg: 15, time: "08:50 AM", status: "Declined" },
  { id: "DN-1043", citizen: "Bilal Ahmed", phone: "+92 301 6620345", area: "Habibullah Colony", meat: "Beef", kg: 35, time: "08:20 AM", status: "Pending" },
  { id: "DN-1042", citizen: "Zainab Hussain", phone: "+92 322 8830154", area: "Kakul Road", meat: "Mutton", kg: 25, time: "07:55 AM", status: "Accepted" },
];

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

export default function NGODonations() {
  const [requests, setRequests] = useState(initialRequests);
  const [filter, setFilter] = useState("All");
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState(null);

  function updateStatus(id, status) {
    setRequests((prev) => prev.map((r) => (r.id === id ? { ...r, status } : r)));
  }

  const query = search.trim().toLowerCase();
  const filtered = requests.filter((r) => {
    const matchesFilter = filter === "All" || r.status === filter;
    const matchesSearch =
      !query ||
      r.citizen.toLowerCase().includes(query) ||
      r.area.toLowerCase().includes(query) ||
      r.id.toLowerCase().includes(query);
    return matchesFilter && matchesSearch;
  });

  const countFor = (f) => (f === "All" ? requests.length : requests.filter((r) => r.status === f).length);
  const pending = countFor("Pending");

  // Keep the modal in sync with live status changes
  const live = selected ? requests.find((r) => r.id === selected.id) : null;

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
              id="eidclean-ngo-donations-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div className="pointer-events-none absolute -right-10 -top-16 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl 2xl:h-64 2xl:w-64" aria-hidden="true" />
            <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-amber-200 ring-1 ring-white/20 backdrop-blur sm:h-11 sm:w-11 2xl:h-12 2xl:w-12">
                  <HeartHandshake className="h-5 w-5 2xl:h-6 2xl:w-6" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold tracking-tight text-white sm:text-2xl">Donation Requests</h2>
                  <p className="mt-0.5 text-sm text-emerald-50/75">
                    Review and respond to meat donation offers from citizens
                  </p>
                </div>
              </div>
              <span className="inline-flex shrink-0 items-center gap-2 self-start rounded-full bg-white/10 px-3 py-1.5 text-xs font-medium text-emerald-50 ring-1 ring-white/20 backdrop-blur sm:self-auto">
                <Clock className="h-3.5 w-3.5 text-amber-200" aria-hidden="true" />
                <span className="tabular-nums">{pending}</span> awaiting response
              </span>
            </div>
          </div>

          {/* Search + Filters */}
          <div className={cn("flex flex-wrap items-center gap-3 sm:gap-4", sectionGap)}>
            <div className="min-w-[220px] flex-1">
              <Input
                leftIcon={Search}
                type="text"
                placeholder="Search by citizen, area or ID..."
                aria-label="Search donation requests"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="shadow-card"
              />
            </div>
            <div className="flex max-w-full items-center gap-1 overflow-x-auto rounded-xl bg-white p-1 shadow-card ring-1 ring-slate-200">
              {filters.map((f) => (
                <button
                  key={f}
                  type="button"
                  onClick={() => setFilter(f)}
                  className={cn(
                    "inline-flex items-center gap-1.5 whitespace-nowrap rounded-lg px-3 py-1.5 text-xs font-medium transition-all duration-150 focus-visible:outline-none focus-visible:shadow-focus 2xl:px-3.5",
                    filter === f
                      ? "bg-gradient-to-br from-emerald-500 to-emerald-600 text-white shadow-sm shadow-emerald-600/30"
                      : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                  )}
                >
                  {f === "All" ? "All Status" : f}
                  <span className={cn("tabular-nums", filter === f ? "text-white/80" : "text-slate-400")}>
                    {countFor(f)}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Requests Table */}
          <Card padding="none" className="overflow-hidden">
            <CardHeader className={cn("flex items-center justify-between gap-3", cardHeaderPad)}>
              <div className="flex items-center gap-3">
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-amber-50 to-amber-100 text-amber-600 ring-1 ring-amber-200 2xl:h-10 2xl:w-10">
                  <Inbox className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">
                    All Donation Requests
                  </h3>
                  <p className="text-xs text-slate-500">
                    Showing <span className="tabular-nums">{filtered.length}</span> of{" "}
                    <span className="tabular-nums">{requests.length}</span> requests
                  </p>
                </div>
              </div>
            </CardHeader>
            <Table className="min-w-[860px]" wrapperClassName="rounded-none border-0 border-t shadow-none">
              <TableHeader className="bg-slate-50/80">
                <TableRow>
                  <TableHead className={headCell}>Citizen</TableHead>
                  <TableHead className={headCell}>Area</TableHead>
                  <TableHead className={headCell}>Meat</TableHead>
                  <TableHead className={headCell}>Time</TableHead>
                  <TableHead className={headCell}>Status</TableHead>
                  <TableHead align="right" className={headCell}>Action</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filtered.length === 0 ? (
                  <TableEmpty
                    colSpan={6}
                    icon={Inbox}
                    title="No requests found"
                    description="Try a different search or status filter"
                  />
                ) : (
                  filtered.map((r) => (
                    <TableRow key={r.id} className="group hover:bg-slate-50/80">
                      <TableCell className={cellPad}>
                        <div className="flex items-center gap-3">
                          <Avatar name={r.citizen} size="sm" />
                          <div className="min-w-0">
                            <p className="whitespace-nowrap font-semibold text-slate-900">{r.citizen}</p>
                            <p className="whitespace-nowrap text-xs tabular-nums text-slate-500">{r.phone}</p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell className={cellPad}>
                        <span className="inline-flex items-center gap-1.5 whitespace-nowrap">
                          <MapPin className="h-3.5 w-3.5 text-emerald-600" aria-hidden="true" />
                          {r.area}
                        </span>
                      </TableCell>
                      <TableCell className={cellPad}>
                        <p className="whitespace-nowrap font-semibold tabular-nums text-slate-900">{r.kg} kg</p>
                        <p className="text-xs text-slate-500">{r.meat}</p>
                      </TableCell>
                      <TableCell className={cellPad}>
                        <p className="whitespace-nowrap font-medium tabular-nums text-slate-900">{r.time}</p>
                        <p className="text-xs text-slate-500">Today</p>
                      </TableCell>
                      <TableCell className={cellPad}>
                        <Badge variant={statusVariant[r.status] || "gray"} dot>
                          {r.status}
                        </Badge>
                      </TableCell>
                      <TableCell align="right" className={cellPad}>
                        <div className="flex items-center justify-end gap-2">
                          {r.status === "Pending" && (
                            <>
                              <Button
                                size="sm"
                                onClick={() => updateStatus(r.id, "Accepted")}
                                className="gap-1.5 bg-emerald-600 shadow-sm shadow-emerald-600/20 hover:bg-emerald-700"
                              >
                                <Check className="h-3.5 w-3.5" aria-hidden="true" />
                                Accept
                              </Button>
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => updateStatus(r.id, "Declined")}
                                className="gap-1.5 hover:border-red-300 hover:bg-red-50 hover:text-red-700"
                              >
                                <X className="h-3.5 w-3.5" aria-hidden="true" />
                                Decline
                              </Button>
                            </>
                          )}
                          <Button
                            size="sm"
                            variant={r.status === "Pending" ? "ghost" : "outline"}
                            onClick={() => setSelected(r)}
                            aria-label={`View request from ${r.citizen}`}
                            className={cn(
                              "gap-1.5",
                              r.status !== "Pending" && "hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-700"
                            )}
                          >
                            <Eye className="h-3.5 w-3.5" aria-hidden="true" />
                            View
                          </Button>
                        </div>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </Card>
        </div>
      </main>

      {/* View Details Modal */}
      <Modal
        open={Boolean(live)}
        onClose={() => setSelected(null)}
        title="Donation request"
        description={live ? `${live.id} — received today at ${live.time}` : undefined}
        size="md"
      >
        {live && (
          <>
            <ModalBody>
              <div className="mb-5 flex items-center gap-3">
                <Avatar name={live.citizen} size="lg" />
                <div className="min-w-0">
                  <p className="truncate text-base font-semibold text-slate-900">{live.citizen}</p>
                  <Badge variant={statusVariant[live.status] || "gray"} dot className="mt-1">
                    {live.status}
                  </Badge>
                </div>
              </div>
              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <DetailRow icon={Phone} label="Phone">
                  <span className="tabular-nums">{live.phone}</span>
                </DetailRow>
                <DetailRow icon={MapPin} label="Area">
                  {live.area}
                </DetailRow>
                <DetailRow icon={Scale} label="Meat">
                  <span className="tabular-nums">{live.kg} kg</span> — {live.meat}
                </DetailRow>
                <DetailRow icon={User} label="Request ID">
                  <span className="font-mono text-sm">{live.id}</span>
                </DetailRow>
              </div>
            </ModalBody>
            <ModalFooter>
              <Button variant="outline" onClick={() => setSelected(null)}>
                Close
              </Button>
              {live.status === "Pending" && (
                <>
                  <Button
                    variant="outline"
                    onClick={() => updateStatus(live.id, "Declined")}
                    className="gap-1.5 hover:border-red-300 hover:bg-red-50 hover:text-red-700"
                  >
                    <X className="h-4 w-4" aria-hidden="true" />
                    Decline
                  </Button>
                  <Button
                    onClick={() => updateStatus(live.id, "Accepted")}
                    className="gap-1.5 bg-emerald-600 shadow-sm shadow-emerald-600/20 hover:bg-emerald-700"
                  >
                    <Check className="h-4 w-4" aria-hidden="true" />
                    Accept
                  </Button>
                </>
              )}
            </ModalFooter>
          </>
        )}
      </Modal>
    </div>
  );
}