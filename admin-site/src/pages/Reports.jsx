// src/pages/Reports.jsx

import { useEffect, useState } from "react";
import { collection, getDocs, doc, updateDoc, serverTimestamp } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";
import {
  ArrowRight,
  CalendarDays,
  Camera,
  CircleCheck,
  ClipboardList,
  Clock,
  Inbox,
  MapPin,
  Phone,
  RefreshCw,
  Search,
  Trash2,
  Truck,
  User,
  UserCheck,
  X,
} from "lucide-react";
import { Badge, Button, Card, EmptyState, Input, Select, StatCard } from "../components/ui";
import { cn } from "../lib/utils";

// Shared responsive spacing: compact on laptops, roomy on large screens
const shell = "ml-64 min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)]";
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";

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
  gray: "border-slate-200 from-slate-100/80 via-white to-white before:bg-slate-300/40 after:via-slate-400/70",
  yellow: "border-amber-200/70 from-amber-50 via-white to-white before:bg-amber-300/40 after:via-amber-400/70",
  blue: "border-blue-200/70 from-blue-50 via-white to-white before:bg-blue-300/40 after:via-blue-400/70",
  green: "border-emerald-200/70 from-emerald-50 via-white to-white before:bg-emerald-300/40 after:via-emerald-400/70",
};

// Badge variants
const statusColors = {
  pending: "yellow",
  assigned: "blue",
  completed: "green",
};

const statusIcons = {
  pending: Clock,
  assigned: Truck,
  completed: CircleCheck,
};

export default function Reports() {
  const [requests, setRequests] = useState([]);
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("all");
  const [search, setSearch] = useState("");

  // Photo modal state
  const [selectedPhoto, setSelectedPhoto] = useState(null);

  useEffect(() => {
    fetchRequests();
    fetchDrivers();
  }, []);

  async function fetchRequests() {
    setLoading(true);
    const snap = await getDocs(collection(db, "pickupRequests"));
    setRequests(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    setLoading(false);
  }

  async function fetchDrivers() {
    const snap = await getDocs(collection(db, "drivers"));
    setDrivers(snap.docs.map(d => ({ id: d.id, ...d.data() })));
  }

  async function updateStatus(id, newStatus) {
    await updateDoc(doc(db, "pickupRequests", id), { status: newStatus });
    fetchRequests();
  }

  async function assignDriver(requestId, driverId, driverName) {
    await updateDoc(doc(db, "pickupRequests", requestId), {
      status: "assigned",
      driverId: driverId,
      driverName: driverName,
      assignedAt: serverTimestamp(),
    });
    fetchRequests();
  }

  const filtered = requests.filter(r => {
    const matchesFilter = filter === "all" || r.status === filter;
    const matchesSearch = r.id?.toLowerCase().includes(search.toLowerCase()) ||
                          r.location?.toLowerCase().includes(search.toLowerCase()) ||
                          r.userName?.toLowerCase().includes(search.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  const getStatusCount = (status) => {
    return requests.filter(r => r.status === status).length;
  };

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
              id="eidclean-reports-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div className="pointer-events-none absolute -right-10 -top-16 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl 2xl:h-64 2xl:w-64" aria-hidden="true" />
            <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-amber-200 ring-1 ring-white/20 backdrop-blur sm:h-11 sm:w-11 2xl:h-12 2xl:w-12">
                  <ClipboardList className="h-5 w-5 2xl:h-6 2xl:w-6" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold tracking-tight text-white sm:text-2xl">Pickup Management</h2>
                  <p className="mt-0.5 text-sm text-emerald-50/75">
                    Manage all waste pickup requests and assignments
                  </p>
                </div>
              </div>
              <Button
                onClick={fetchRequests}
                className="h-9 shrink-0 bg-white px-3.5 text-emerald-900 shadow-lg shadow-emerald-950/20 hover:bg-emerald-50 active:bg-emerald-100 2xl:h-10 2xl:px-4"
              >
                <RefreshCw className="h-4 w-4" aria-hidden="true" />
                Refresh
              </Button>
            </div>
          </div>

          {/* Stats */}
          <div className={cn("grid grid-cols-2 gap-3 sm:gap-5 xl:grid-cols-4 2xl:gap-6", sectionGap)}>
            {[
              { label: "Total", value: requests.length, icon: ClipboardList, variant: "gray", description: "All requests" },
              { label: "Pending", value: getStatusCount("pending"), icon: Clock, variant: "yellow", description: "Waiting for a driver" },
              { label: "Assigned", value: getStatusCount("assigned"), icon: Truck, variant: "blue", description: "On the way" },
              { label: "Completed", value: getStatusCount("completed"), icon: CircleCheck, variant: "green", description: "Collected" },
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

          {/* Search + Filters */}
          <div className={cn("flex flex-wrap items-center gap-3 sm:gap-4", sectionGap)}>
            <div className="min-w-[220px] flex-1">
              <Input
                leftIcon={Search}
                type="text"
                placeholder="Search requests..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="shadow-card"
              />
            </div>
            <div className="flex max-w-full items-center gap-1 overflow-x-auto rounded-xl bg-white p-1 shadow-card ring-1 ring-slate-200">
              {["all", "pending", "assigned", "completed"].map((f) => (
                <button
                  key={f}
                  onClick={() => setFilter(f)}
                  className={cn(
                    "whitespace-nowrap rounded-lg px-3 py-1.5 text-xs font-medium capitalize transition-all duration-150 focus-visible:outline-none focus-visible:shadow-focus 2xl:px-3.5",
                    filter === f
                      ? "bg-gradient-to-br from-emerald-500 to-emerald-600 text-white shadow-sm shadow-emerald-600/30"
                      : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
                  )}
                >
                  {f === "all" ? "All Status" : f}
                </button>
              ))}
            </div>
          </div>

          {/* Requests List */}
          {loading ? (
            <div className="flex h-40 items-center justify-center">
              <div className="h-10 w-10 animate-spin rounded-full border-b-2 border-emerald-500"></div>
            </div>
          ) : filtered.length === 0 ? (
            <EmptyState
              icon={Inbox}
              variant="green"
              title="No requests found"
              description="Try a different search or status filter"
              className="bg-white py-12 shadow-sm 2xl:py-16"
            />
          ) : (
            <div className="space-y-3 sm:space-y-4">
              {filtered.map((req) => {
                const StatusIcon = statusIcons[req.status];
                return (
                  <Card
                    key={req.id}
                    padding="none"
                    hoverable
                    className="overflow-hidden transition-all duration-200 hover:shadow-xl hover:shadow-slate-900/5"
                  >
                    <div className="p-4 sm:p-5 2xl:p-6">
                      <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
                        <div className="flex items-center gap-3">
                          <span className="rounded-lg bg-slate-100 px-2.5 py-1 font-mono text-xs font-medium text-slate-600 ring-1 ring-slate-200 sm:text-sm">
                            PK-{req.id.slice(0, 6).toUpperCase()}
                          </span>
                          <Badge variant={statusColors[req.status] || "gray"} className="capitalize">
                            {StatusIcon && <StatusIcon className="h-3.5 w-3.5" aria-hidden="true" />}
                            {req.status || "Pending"}
                          </Badge>
                        </div>
                        {req.status === "assigned" && req.driverName && (
                          <span className="inline-flex items-center gap-2 rounded-full bg-blue-50 py-1 pl-1 pr-3 text-xs font-medium text-blue-700 ring-1 ring-blue-100">
                            <span className="flex h-6 w-6 items-center justify-center rounded-full bg-white text-blue-600 ring-1 ring-blue-100">
                              <User className="h-3.5 w-3.5" aria-hidden="true" />
                            </span>
                            {req.driverName}
                          </span>
                        )}
                      </div>

                      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 sm:gap-4 lg:grid-cols-3">
                        {/* Customer */}
                        <div className="flex gap-3">
                          <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-slate-50 to-slate-100 text-slate-500 ring-1 ring-slate-200 2xl:h-9 2xl:w-9">
                            <User className="h-4 w-4" aria-hidden="true" />
                          </span>
                          <div className="min-w-0">
                            <p className="text-xs font-medium text-slate-400">Customer</p>
                            <p className="font-semibold text-slate-900">{req.userName || "Unknown"}</p>
                            <p className="text-sm text-slate-500">{req.userPhone || "No phone"}</p>
                            <p className="text-sm text-slate-500">Animals: {req.animals || 1}</p>
                          </div>
                        </div>

                        {/* Location */}
                        <div className="flex gap-3">
                          <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-emerald-50 to-emerald-100 text-emerald-600 ring-1 ring-emerald-200 2xl:h-9 2xl:w-9">
                            <MapPin className="h-4 w-4" aria-hidden="true" />
                          </span>
                          <div className="min-w-0">
                            <p className="text-xs font-medium text-slate-400">Location</p>
                            <p className="font-semibold text-slate-900">{req.area || "Jinnahabad"}</p>
                            <p className="text-sm text-slate-500">{req.location || "No address"}</p>
                            <p className="flex items-center gap-1.5 text-sm text-slate-500">
                              <Trash2 className="h-3.5 w-3.5 text-slate-400" aria-hidden="true" />
                              Waste: {req.wasteType || "Mixed"}
                            </p>
                          </div>
                        </div>

                        {/* Schedule */}
                        <div className="flex gap-3">
                          <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-amber-50 to-amber-100 text-amber-600 ring-1 ring-amber-200 2xl:h-9 2xl:w-9">
                            <CalendarDays className="h-4 w-4" aria-hidden="true" />
                          </span>
                          <div className="min-w-0">
                            <p className="text-xs font-medium text-slate-400">Schedule</p>
                            <p className="font-semibold tabular-nums text-slate-900">
                              {req.createdAt?.toDate?.().toLocaleDateString() || "2026-04-22"}
                            </p>
                            <p className="text-sm text-slate-500">{req.timeSlot || "9-12 AM"}</p>
                          </div>
                        </div>
                      </div>

                      {/* Photo Display */}
                      {req.photoBase64 && (
                        <div className="mt-4 border-t border-slate-100 pt-4">
                          <p className="mb-2.5 flex items-center gap-2 text-sm font-semibold text-slate-900">
                            <Camera className="h-4 w-4 text-emerald-600" aria-hidden="true" />
                            Pickup Photo Evidence
                          </p>
                          <div className="flex items-center gap-3 sm:gap-4">
                            <img
                              src={req.photoBase64}
                              alt="Pickup evidence"
                              className="h-16 w-16 cursor-pointer rounded-xl border-2 border-emerald-500 object-cover shadow-md shadow-emerald-900/10 transition-all duration-150 hover:scale-105 hover:opacity-90 sm:h-20 sm:w-20"
                              onClick={() => setSelectedPhoto(req.photoBase64)}
                            />
                            <div className="text-xs text-slate-500">
                              <p className="flex items-center gap-1.5 font-medium text-emerald-700">
                                <CircleCheck className="h-3.5 w-3.5" aria-hidden="true" />
                                Photo captured by driver
                              </p>
                              <p className="mt-0.5 tabular-nums">
                                Size: {req.photoSize ? `${(req.photoSize / 1024).toFixed(1)} KB` : 'N/A'}
                              </p>
                              <button
                                onClick={() => setSelectedPhoto(req.photoBase64)}
                                className="group mt-1 inline-flex items-center gap-1 font-semibold text-emerald-600 transition-colors hover:text-emerald-800"
                              >
                                View Full Size
                                <ArrowRight className="h-3.5 w-3.5 transition-transform duration-150 group-hover:translate-x-0.5" aria-hidden="true" />
                              </button>
                            </div>
                          </div>
                        </div>
                      )}
                    </div>

                    {/* Actions */}
                    {req.status !== undefined && (
                      <div className="flex flex-wrap items-center gap-2 border-t border-slate-100 bg-slate-50/60 px-4 py-2.5 sm:px-5 2xl:px-6 2xl:py-3">
                        {req.status === "pending" && (
                          <Select
                            wrapperClassName="w-full sm:w-56"
                            leftIcon={UserCheck}
                            className="py-2"
                            placeholder="Assign Driver"
                            defaultValue=""
                            onChange={(e) => {
                              const [id, name] = e.target.value.split("|");
                              if (id) assignDriver(req.id, id, name);
                            }}
                          >
                            {drivers.map(d => (
                              <option key={d.id} value={`${d.uid}|${d.name}`}>
                                {d.name}
                              </option>
                            ))}
                          </Select>
                        )}

                        {req.status === "assigned" && (
                          <>
                            <Button variant="outline" className="h-8 gap-1.5 px-3 text-xs hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-700">
                              <MapPin className="h-3.5 w-3.5" aria-hidden="true" />
                              Track
                            </Button>
                            <Button variant="outline" className="h-8 gap-1.5 px-3 text-xs hover:border-blue-300 hover:bg-blue-50 hover:text-blue-700">
                              <RefreshCw className="h-3.5 w-3.5" aria-hidden="true" />
                              Reassign
                            </Button>
                            <Button variant="ghost" className="h-8 gap-1.5 px-3 text-xs">
                              <Phone className="h-3.5 w-3.5" aria-hidden="true" />
                              Contact
                            </Button>
                          </>
                        )}

                        {req.status === "assigned" && (
                          <Button
                            onClick={() => updateStatus(req.id, "completed")}
                            className="ml-auto h-8 gap-1.5 bg-emerald-600 px-3.5 text-xs shadow-sm shadow-emerald-600/20 hover:bg-emerald-700"
                          >
                            <CircleCheck className="h-3.5 w-3.5" aria-hidden="true" />
                            Complete
                          </Button>
                        )}

                        {req.status === "completed" && (
                          <span className="inline-flex items-center gap-1.5 text-sm font-medium text-emerald-600">
                            <CircleCheck className="h-4 w-4" aria-hidden="true" />
                            Done
                          </span>
                        )}
                      </div>
                    )}
                  </Card>
                );
              })}
            </div>
          )}

          {/* Full-Size Photo Modal */}
          {selectedPhoto && (
            <div
              className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/80 p-4 backdrop-blur-sm motion-safe:animate-fade-in"
              onClick={() => setSelectedPhoto(null)}
            >
              <div className="relative max-h-full max-w-4xl">
                <button
                  onClick={() => setSelectedPhoto(null)}
                  className="absolute -top-12 right-0 inline-flex items-center gap-1.5 rounded-lg bg-white/10 px-3 py-1.5 text-sm font-medium text-white ring-1 ring-white/20 transition-colors hover:bg-white/20"
                >
                  <X className="h-4 w-4" aria-hidden="true" />
                  Close
                </button>
                <img
                  src={selectedPhoto}
                  alt="Full size pickup"
                  className="max-h-[75vh] max-w-full rounded-2xl shadow-2xl ring-1 ring-white/20"
                  onClick={(e) => e.stopPropagation()}
                />
                <p className="mt-4 flex items-center justify-center gap-2 text-center text-sm text-white/70">
                  <Camera className="h-4 w-4" aria-hidden="true" />
                  Driver Photo Evidence — Click outside to close
                </p>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}