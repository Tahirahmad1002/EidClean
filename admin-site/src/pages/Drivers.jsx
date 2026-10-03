// src/pages/Drivers.jsx

import { useEffect, useState } from "react";
import { collection, getDocs, addDoc, setDoc, updateDoc, doc, serverTimestamp } from "firebase/firestore";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { auth, db } from "../firebase";
import Sidebar from "../components/Sidebar";
import {
  CircleCheck,
  ClipboardList,
  Eye,
  Lock,
  Mail,
  MapPin,
  Phone,
  Plus,
  Power,
  Star,
  Truck,
  User,
  UserCheck,
  UserPlus,
  X,
} from "lucide-react";
import { Badge, Button, Card, CardBody, CardHeader, EmptyState, Input, StatCard } from "../components/ui";
import { cn } from "../lib/utils";

// Shared responsive spacing: compact on laptops, roomy on large screens
const shell = "ml-64 min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)]";
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cardBodyPad = "px-4 py-4 sm:px-5 sm:py-5 2xl:px-6 2xl:py-6";

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

export default function Drivers() {
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [formLoading, setFormLoading] = useState(false);
  const [error, setError] = useState("");
  const [form, setForm] = useState({
    name: "", email: "", password: "", phone: "", vehicleNumber: "",
  });

  useEffect(() => { fetchDrivers(); }, []);

  async function fetchDrivers() {
    setLoading(true);
    const snap = await getDocs(collection(db, "drivers"));
    setDrivers(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    setLoading(false);
  }

  async function handleAddDriver(e) {
    e.preventDefault();
    setFormLoading(true);
    setError("");
    try {
      const cred = await createUserWithEmailAndPassword(
        auth, form.email, form.password
      );

      // Use UID as document ID for both drivers and users
      // This matches Firebase Auth UID — enables direct doc lookups later
      await setDoc(doc(db, "drivers", cred.user.uid), {
        uid: cred.user.uid,
        name: form.name,
        phone: form.phone,
        vehicleNumber: form.vehicleNumber,
        status: "available",
        createdAt: serverTimestamp(),
      });

      await setDoc(doc(db, "users", cred.user.uid), {
        uid: cred.user.uid,
        name: form.name,
        email: form.email,
        phone: form.phone,
        role: "driver",
        createdAt: serverTimestamp(),
      });

      setForm({ name:"", email:"", password:"", phone:"", vehicleNumber:"" });
      setShowForm(false);
      fetchDrivers();
    } catch (err) {
      setError(err.message);
    }
    setFormLoading(false);
  }

  async function toggleStatus(driver) {
    const newStatus = driver.status === "available" ? "busy" : "available";
    await updateDoc(doc(db, "drivers", driver.id), { status: newStatus });
    fetchDrivers();
  }

  const getInitials = (name) => {
    if (!name) return "??";
    return name.split(' ').map(word => word[0]).join('').toUpperCase().slice(0, 2);
  };

  // Returns a Badge variant
  const getStatusColor = (status) => {
    if (status === "available" || status === "Active") return "green";
    if (status === "busy") return "red";
    if (status === "Break") return "yellow";
    return "gray";
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
              id="eidclean-drivers-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div className="pointer-events-none absolute -right-10 -top-16 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl 2xl:h-64 2xl:w-64" aria-hidden="true" />
            <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-amber-200 ring-1 ring-white/20 backdrop-blur sm:h-11 sm:w-11 2xl:h-12 2xl:w-12">
                  <Truck className="h-5 w-5 2xl:h-6 2xl:w-6" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold tracking-tight text-white sm:text-2xl">Driver Management</h2>
                  <p className="mt-0.5 max-w-xl text-sm text-emerald-50/75">
                    Monitor drivers — view completed pickups, uploaded photos & user feedback
                  </p>
                </div>
              </div>
              <Button
                onClick={() => setShowForm(!showForm)}
                className="h-9 shrink-0 bg-white px-3.5 text-emerald-900 shadow-lg shadow-emerald-950/20 hover:bg-emerald-50 active:bg-emerald-100 2xl:h-10 2xl:px-4"
              >
                {showForm ? (
                  <>
                    <X className="h-4 w-4" aria-hidden="true" />
                    Cancel
                  </>
                ) : (
                  <>
                    <Plus className="h-4 w-4" aria-hidden="true" />
                    Add Driver
                  </>
                )}
              </Button>
            </div>
          </div>

          {/* Stats Cards */}
          <div className={cn("grid grid-cols-1 gap-4 sm:grid-cols-2 sm:gap-5 xl:grid-cols-4 2xl:gap-6", sectionGap)}>
            {[
              { label: "Active Drivers", value: drivers.filter(d => d.status === "available" || d.status === "Active").length, icon: Truck, variant: "green", description: "Available right now" },
              { label: "Assigned", value: 19, icon: UserCheck, variant: "blue", description: "Currently on a pickup" },
              { label: "Completed Today", value: 51, icon: CircleCheck, variant: "teal", description: "Finished pickups" },
              { label: "Avg. Rating", value: 4.7, icon: Star, variant: "yellow", description: "across all drivers" },
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

          {/* Add Driver Form */}
          {showForm && (
            <Card padding="none" className={cn("overflow-hidden shadow-lg shadow-slate-900/5 motion-safe:animate-slide-up", sectionGap)}>
              <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 text-emerald-600 ring-1 ring-emerald-200 2xl:h-10 2xl:w-10">
                  <UserPlus className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">Add New Driver</h3>
                  <p className="text-xs text-slate-500">Creates a login and a driver profile</p>
                </div>
              </CardHeader>
              <CardBody className={cardBodyPad}>
                <form onSubmit={handleAddDriver} className="grid grid-cols-1 gap-4 md:grid-cols-2 2xl:gap-5">
                  <Input
                    label="Full Name"
                    leftIcon={User}
                    type="text"
                    required
                    placeholder="Ahmad Ali"
                    value={form.name}
                    onChange={e => setForm({...form, name: e.target.value})}
                  />
                  <Input
                    label="Email"
                    leftIcon={Mail}
                    type="email"
                    required
                    placeholder="driver@eidclean.com"
                    value={form.email}
                    onChange={e => setForm({...form, email: e.target.value})}
                  />
                  <Input
                    label="Password"
                    leftIcon={Lock}
                    type="password"
                    required
                    placeholder="minimum 6 characters"
                    value={form.password}
                    onChange={e => setForm({...form, password: e.target.value})}
                  />
                  <Input
                    label="Phone"
                    leftIcon={Phone}
                    type="text"
                    required
                    placeholder="03001234567"
                    value={form.phone}
                    onChange={e => setForm({...form, phone: e.target.value})}
                  />
                  <Input
                    label="Vehicle Number"
                    leftIcon={Truck}
                    type="text"
                    required
                    placeholder="ABC-123"
                    value={form.vehicleNumber}
                    onChange={e => setForm({...form, vehicleNumber: e.target.value})}
                  />
                  <div className="flex flex-col justify-end gap-2">
                    {error && <p className="text-xs text-red-500">{error}</p>}
                    <Button
                      type="submit"
                      disabled={formLoading}
                      leftIcon={UserPlus}
                      className="w-full bg-emerald-600 shadow-sm shadow-emerald-600/20 hover:bg-emerald-700"
                    >
                      {formLoading ? "Adding..." : "Add Driver"}
                    </Button>
                  </div>
                </form>
              </CardBody>
            </Card>
          )}

          {/* Drivers List */}
          {loading ? (
            <div className="flex h-40 items-center justify-center">
              <div className="h-10 w-10 animate-spin rounded-full border-b-2 border-emerald-500"></div>
            </div>
          ) : drivers.length === 0 ? (
            <EmptyState
              icon={Truck}
              variant="green"
              title="No drivers added yet"
              description="Add your first driver to start assigning pickups"
              className="bg-white py-12 shadow-sm 2xl:py-16"
            />
          ) : (
            <div className="grid grid-cols-1 gap-4 sm:gap-5 xl:grid-cols-2 2xl:gap-6">
              {drivers.map((driver) => (
                <Card
                  key={driver.id}
                  padding="none"
                  hoverable
                  className="overflow-hidden transition-all duration-200 hover:-translate-y-0.5 hover:shadow-xl hover:shadow-slate-900/5"
                >
                  <div className="p-4 sm:p-5">
                    <div className="mb-3 flex items-start justify-between gap-3 2xl:mb-4">
                      <div className="flex min-w-0 items-center gap-3">
                        <div className="relative shrink-0">
                          <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-400 to-teal-500 text-sm font-semibold text-white shadow-md shadow-emerald-500/20 ring-1 ring-white/30 2xl:h-12 2xl:w-12 2xl:text-base">
                            {getInitials(driver.name)}
                          </div>
                          <span
                            className={cn(
                              "absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full ring-2 ring-white",
                              driver.status === "busy" ? "bg-red-500" : "bg-emerald-500"
                            )}
                            aria-hidden="true"
                          />
                        </div>
                        <div className="min-w-0">
                          <p className="truncate font-semibold text-slate-900">{driver.name || "Unknown"}</p>
                          <p className="text-xs font-medium tabular-nums text-slate-400">
                            WK-{driver.id?.slice(0, 4).toUpperCase() || "001"}
                          </p>
                          <p className="mt-0.5 flex items-center gap-1.5 text-sm text-slate-500">
                            <Phone className="h-3.5 w-3.5 text-slate-400" aria-hidden="true" />
                            {driver.phone || "+92 300 1234567"}
                          </p>
                        </div>
                      </div>
                      <Badge variant={getStatusColor(driver.status)} dot className="shrink-0 capitalize">
                        {driver.status === "available" ? "Active" : driver.status || "Active"}
                      </Badge>
                    </div>

                    <div className="grid grid-cols-3 divide-x divide-slate-200 rounded-xl bg-slate-50 py-2.5 ring-1 ring-slate-200/70">
                      <div className="px-3 sm:px-4">
                        <p className="text-xs text-slate-500">Area</p>
                        <p className="mt-0.5 truncate text-sm font-semibold text-slate-900">Jinnahabad</p>
                      </div>
                      <div className="px-3 sm:px-4">
                        <p className="text-xs text-slate-500">Pickups</p>
                        <p className="mt-0.5 text-sm font-semibold tabular-nums text-slate-900">5</p>
                      </div>
                      <div className="px-3 sm:px-4">
                        <p className="text-xs text-slate-500">Status</p>
                        <p className="mt-0.5 text-sm font-semibold text-emerald-600">Assigned</p>
                      </div>
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center gap-2 border-t border-slate-100 bg-slate-50/60 px-4 py-2.5 sm:px-5">
                    <Button variant="outline" className="h-8 gap-1.5 px-3 text-xs hover:border-blue-300 hover:bg-blue-50 hover:text-blue-700">
                      <MapPin className="h-3.5 w-3.5" aria-hidden="true" />
                      Track
                    </Button>
                    <Button className="h-8 gap-1.5 bg-emerald-600 px-3 text-xs shadow-sm shadow-emerald-600/20 hover:bg-emerald-700">
                      <ClipboardList className="h-3.5 w-3.5" aria-hidden="true" />
                      Assign
                    </Button>
                    <Button variant="ghost" className="h-8 gap-1.5 px-3 text-xs">
                      <Eye className="h-3.5 w-3.5" aria-hidden="true" />
                      View Work
                    </Button>
                    <Button
                      variant="outline"
                      onClick={() => toggleStatus(driver)}
                      className={cn(
                        "ml-auto h-8 gap-1.5 px-3 text-xs",
                        driver.status === "available"
                          ? "hover:border-red-200 hover:bg-red-50 hover:text-red-700"
                          : "border-emerald-200 bg-emerald-50 text-emerald-700 hover:border-emerald-300 hover:bg-emerald-100"
                      )}
                    >
                      <Power className="h-3.5 w-3.5" aria-hidden="true" />
                      {driver.status === "available" ? "Set Busy" : "Set Active"}
                    </Button>
                  </div>
                </Card>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
}