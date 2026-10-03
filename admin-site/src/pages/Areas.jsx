// src/pages/Areas.jsx

import { useEffect, useState } from "react";
import { collection, getDocs, addDoc, serverTimestamp } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";
import { Flag, Map as MapIcon, MapPin, Plus, Save, TriangleAlert, Users, X } from "lucide-react";
import {
  Badge,
  Button,
  Card,
  CardBody,
  CardHeader,
  EmptyState,
  Input,
  Select,
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
const cellPad = "px-4 py-3 sm:px-5 2xl:px-6 2xl:py-4";
const headPad = "px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3";

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
  red: "border-red-200/70 from-red-50 via-white to-white before:bg-red-300/40 after:via-red-400/70",
};

// Badge variants
const priorityColors = {
  high:   "red",
  medium: "yellow",
  low:    "green",
};

export default function Areas() {
  const [areas, setAreas]       = useState([]);
  const [loading, setLoading]   = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [saving, setSaving]     = useState(false);
  const [form, setForm] = useState({
    areaName: "", district: "", population: "",
    houses: "", density: "", priority: "medium",
  });

  useEffect(() => { fetchAreas(); }, []);

  async function fetchAreas() {
    setLoading(true);
    const snap = await getDocs(collection(db, "areas"));
    setAreas(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    setLoading(false);
  }

  async function handleAddArea(e) {
    e.preventDefault();
    setSaving(true);
    await addDoc(collection(db, "areas"), {
      areaName:   form.areaName,
      district:   form.district,
      population: Number(form.population),
      houses:     Number(form.houses),
      density:    Number(form.density),
      priority:   form.priority,
      createdAt:  serverTimestamp(),
    });
    setForm({ areaName:"", district:"", population:"", houses:"", density:"", priority:"medium" });
    setShowForm(false);
    fetchAreas();
    setSaving(false);
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
              id="eidclean-areas-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div className="pointer-events-none absolute -right-10 -top-16 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl 2xl:h-64 2xl:w-64" aria-hidden="true" />
            <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-amber-200 ring-1 ring-white/20 backdrop-blur sm:h-11 sm:w-11 2xl:h-12 2xl:w-12">
                  <MapIcon className="h-5 w-5 2xl:h-6 2xl:w-6" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold tracking-tight text-white sm:text-2xl">Areas</h2>
                  <p className="mt-0.5 text-sm text-emerald-50/75">
                    Manage municipal zones and priorities
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
                    Add Area
                  </>
                )}
              </Button>
            </div>
          </div>

          {/* Stats */}
          <div className={cn("grid grid-cols-1 gap-4 sm:grid-cols-3 sm:gap-5 2xl:gap-6", sectionGap)}>
            {[
              { label: "Service Zones", value: areas.length, icon: MapPin, variant: "green", description: "Registered areas" },
              { label: "Total Population", value: areas.reduce((sum, a) => sum + (a.population || 0), 0).toLocaleString(), icon: Users, variant: "blue", description: "Across all zones" },
              { label: "High Priority", value: areas.filter(a => a.priority === "high").length, icon: TriangleAlert, variant: "red", description: "Need extra resources" },
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

          {/* Add Area Form */}
          {showForm && (
            <Card padding="none" className={cn("overflow-hidden shadow-lg shadow-slate-900/5 motion-safe:animate-slide-up", sectionGap)}>
              <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 text-emerald-600 ring-1 ring-emerald-200 2xl:h-10 2xl:w-10">
                  <MapPin className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">Add New Area</h3>
                  <p className="text-xs text-slate-500">Define a zone and its priority level</p>
                </div>
              </CardHeader>
              <CardBody className={cardBodyPad}>
                <form onSubmit={handleAddArea} className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 2xl:gap-5">
                  {[
                    { label:"Area Name",  key:"areaName",   placeholder:"Abbottabad City" },
                    { label:"District",   key:"district",   placeholder:"Abbottabad" },
                    { label:"Population", key:"population", placeholder:"50000" },
                    { label:"Houses",     key:"houses",     placeholder:"8000" },
                    { label:"Density",    key:"density",    placeholder:"1200" },
                  ].map(field => (
                    <Input
                      key={field.key}
                      label={field.label}
                      type={field.key === "areaName" || field.key === "district" ? "text" : "number"}
                      required
                      placeholder={field.placeholder}
                      value={form[field.key]}
                      onChange={e => setForm({...form, [field.key]: e.target.value})}
                    />
                  ))}
                  <Select
                    label="Priority"
                    leftIcon={Flag}
                    value={form.priority}
                    onChange={e => setForm({...form, priority: e.target.value})}
                  >
                    <option value="high">High</option>
                    <option value="medium">Medium</option>
                    <option value="low">Low</option>
                  </Select>
                  <div className="flex items-end sm:col-span-2 lg:col-span-3">
                    <Button
                      type="submit"
                      disabled={saving}
                      leftIcon={Save}
                      className="bg-emerald-600 px-6 shadow-sm shadow-emerald-600/20 hover:bg-emerald-700 2xl:px-8"
                    >
                      {saving ? "Saving..." : "Save Area"}
                    </Button>
                  </div>
                </form>
              </CardBody>
            </Card>
          )}

          {/* Areas Table */}
          {loading ? (
            <div className="flex h-40 items-center justify-center">
              <div className="h-10 w-10 animate-spin rounded-full border-b-2 border-emerald-500"></div>
            </div>
          ) : areas.length === 0 ? (
            <EmptyState
              icon={MapIcon}
              variant="green"
              title="No areas added yet"
              description='Click "Add Area" to add your first zone'
              className="bg-white py-12 shadow-sm 2xl:py-16"
            />
          ) : (
            <Card padding="none" className="overflow-hidden">
              <CardHeader className={cn("flex items-center justify-between gap-3", cardHeaderPad)}>
                <div className="flex items-center gap-3">
                  <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-amber-50 to-amber-100 text-amber-600 ring-1 ring-amber-200 2xl:h-10 2xl:w-10">
                    <MapIcon className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                  </div>
                  <div>
                    <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">Service Zones</h3>
                    <p className="text-xs text-slate-500">Population, housing and priority by area</p>
                  </div>
                </div>
                <Badge variant="gray">{areas.length} zones</Badge>
              </CardHeader>
              <Table wrapperClassName="rounded-none border-0 border-t shadow-none">
                <TableHeader className="bg-slate-50/80">
                  <TableRow>
                    {["Area Name","District","Population","Houses","Density","Priority"].map(h => (
                      <TableHead key={h} className={headPad}>
                        {h}
                      </TableHead>
                    ))}
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {areas.map(area => (
                    <TableRow key={area.id} className="group hover:bg-slate-50/80">
                      <TableCell className={cellPad}>
                        <div className="flex items-center gap-3">
                          <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br from-slate-50 to-slate-100 text-slate-500 ring-1 ring-slate-200 transition-colors duration-150 group-hover:from-emerald-50 group-hover:to-emerald-100 group-hover:text-emerald-600 group-hover:ring-emerald-200 2xl:h-9 2xl:w-9">
                            <MapPin className="h-4 w-4" aria-hidden="true" />
                          </span>
                          <span className="font-semibold text-slate-900">{area.areaName}</span>
                        </div>
                      </TableCell>
                      <TableCell className={cn(cellPad, "text-slate-600")}>
                        {area.district}
                      </TableCell>
                      <TableCell className={cn(cellPad, "tabular-nums text-slate-600")}>
                        {area.population?.toLocaleString()}
                      </TableCell>
                      <TableCell className={cn(cellPad, "tabular-nums text-slate-600")}>
                        {area.houses?.toLocaleString()}
                      </TableCell>
                      <TableCell className={cn(cellPad, "tabular-nums text-slate-600")}>
                        {area.density}
                      </TableCell>
                      <TableCell className={cellPad}>
                        <Badge variant={priorityColors[area.priority] || "gray"} dot className="capitalize">
                          {area.priority}
                        </Badge>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </Card>
          )}
        </div>
      </main>
    </div>
  );
}