// src/pages/NGOProfile.jsx

import { useState } from "react";
import NGOSidebar from "../components/NGOSidebar";
import {
  BadgeCheck,
  Building2,
  CalendarDays,
  ChartColumn,
  Clock,
  Globe,
  HeartHandshake,
  Landmark,
  Mail,
  MapPin,
  Pencil,
  Percent,
  Phone,
  Plus,
  Scale,
  Users,
  X,
} from "lucide-react";
import {
  Badge,
  Button,
  Card,
  CardBody,
  CardHeader,
  EmptyState,
  Input,
  Modal,
  ModalBody,
  ModalFooter,
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
const cardBodyPad = "px-4 py-4 sm:px-5 sm:py-5 2xl:px-6 2xl:py-6";

// Static dummy data (Firebase later)
const initialContact = {
  phone: "+92 992 380 123",
  email: "abbottabad@edhi.org.pk",
  address: "Mansehra Road, Abbottabad, Khyber Pakhtunkhwa",
  website: "edhi.org",
};

const initialAreas = [
  "Jinnahabad",
  "Nawanshehr",
  "Mirpur",
  "Supply Bazar",
  "Mandian",
  "Habibullah Colony",
  "Kakul Road",
];

const orgStats = [
  { label: "Total Donations", value: "2,450", icon: HeartHandshake, tile: "bg-blue-50 text-blue-600 ring-blue-100" },
  { label: "Meat Collected", value: "1,850 kg", icon: Scale, tile: "bg-teal-50 text-teal-600 ring-teal-100" },
  { label: "Families Served", value: "1,247", icon: Users, tile: "bg-emerald-50 text-emerald-600 ring-emerald-100" },
  { label: "Active Volunteers", value: "38", icon: Users, tile: "bg-amber-50 text-amber-600 ring-amber-100" },
  { label: "Avg. Response Time", value: "12 min", icon: Clock, tile: "bg-slate-100 text-slate-600 ring-slate-200" },
];

const ACCEPTANCE_RATE = 94;

function InfoTile({ icon: Icon, label, children, tone = "slate" }) {
  const tones = {
    slate: "from-slate-50 to-slate-100 text-slate-500 ring-slate-200",
    green: "from-emerald-50 to-emerald-100 text-emerald-600 ring-emerald-200",
    amber: "from-amber-50 to-amber-100 text-amber-600 ring-amber-200",
  };
  return (
    <div className="flex gap-3">
      <span className={cn("flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-gradient-to-br ring-1 2xl:h-9 2xl:w-9", tones[tone])}>
        <Icon className="h-4 w-4" aria-hidden="true" />
      </span>
      <div className="min-w-0">
        <p className="text-xs font-medium text-slate-400">{label}</p>
        <p className="break-words font-semibold text-slate-900">{children}</p>
      </div>
    </div>
  );
}

export default function NGOProfile() {
  const [contact, setContact] = useState(initialContact);
  const [areas, setAreas] = useState(initialAreas);
  const [newArea, setNewArea] = useState("");
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState(initialContact);

  function openEdit() {
    setDraft(contact);
    setEditing(true);
  }

  function saveEdit(e) {
    e.preventDefault();
    setContact(draft);
    setEditing(false);
  }

  function addArea(e) {
    e.preventDefault();
    const name = newArea.trim();
    if (!name) return;
    if (!areas.some((a) => a.toLowerCase() === name.toLowerCase())) {
      setAreas((prev) => [...prev, name]);
    }
    setNewArea("");
  }

  function removeArea(name) {
    setAreas((prev) => prev.filter((a) => a !== name));
  }

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
              id="eidclean-ngo-profile-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div className="pointer-events-none absolute -right-10 -top-16 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl 2xl:h-64 2xl:w-64" aria-hidden="true" />
            <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-3 sm:gap-4">
                <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-amber-200 ring-1 ring-white/20 backdrop-blur sm:h-11 sm:w-11 2xl:h-12 2xl:w-12">
                  <Building2 className="h-5 w-5 2xl:h-6 2xl:w-6" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="text-xl font-semibold tracking-tight text-white sm:text-2xl">NGO Profile</h2>
                  <p className="mt-0.5 text-sm text-emerald-50/75">
                    Manage your organization details and service coverage
                  </p>
                </div>
              </div>
              <Button
                onClick={openEdit}
                className="h-9 shrink-0 self-start bg-white px-3.5 text-emerald-900 shadow-lg shadow-emerald-950/20 hover:bg-emerald-50 active:bg-emerald-100 sm:self-auto 2xl:h-10 2xl:px-4"
              >
                <Pencil className="h-4 w-4" aria-hidden="true" />
                Edit profile
              </Button>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-4 sm:gap-5 xl:grid-cols-3 2xl:gap-6">
            {/* Main column */}
            <div className="flex min-w-0 flex-col gap-4 sm:gap-5 xl:col-span-2 2xl:gap-6">
              {/* Organization Card */}
              <Card padding="none" className="overflow-hidden">
                <div className="relative isolate h-20 overflow-hidden bg-[linear-gradient(115deg,#064e3b_0%,#047857_52%,#0f766e_100%)] sm:h-24">
                  <Lattice
                    id="eidclean-ngo-org-lattice"
                    className="inset-0 h-full w-full text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_90%)]"
                  />
                  <div className="pointer-events-none absolute -right-8 -top-12 h-40 w-40 rounded-full bg-amber-300/30 blur-3xl" aria-hidden="true" />
                </div>
                <div className="px-4 pb-5 sm:px-6 sm:pb-6 2xl:px-8 2xl:pb-8">
                  <div className="-mt-10 flex flex-col gap-4 sm:-mt-12 sm:flex-row sm:items-end sm:justify-between">
                    <div className="relative z-10 flex h-20 w-20 shrink-0 items-center justify-center rounded-2xl bg-white shadow-xl shadow-emerald-950/10 ring-4 ring-white sm:h-24 sm:w-24">
                      <span className="flex h-full w-full items-center justify-center rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 text-emerald-600 ring-1 ring-emerald-200">
                        <Building2 className="h-9 w-9 sm:h-10 sm:w-10" aria-hidden="true" />
                      </span>
                    </div>
                    <Badge variant="green" size="lg" className="self-start sm:self-auto">
                      <BadgeCheck className="h-4 w-4" aria-hidden="true" />
                      Verified NGO
                    </Badge>
                  </div>

                  <div className="mt-4">
                    <h3 className="text-xl font-semibold tracking-tight text-slate-900 sm:text-2xl">
                      Edhi Foundation
                    </h3>
                    <p className="mt-0.5 text-sm text-slate-500">Abbottabad Chapter — Meat Donation Network</p>
                    <p className="mt-3 max-w-2xl text-sm leading-relaxed text-slate-600">
                      A registered welfare organization collecting Qurbani meat during Eid ul Adha and distributing it to families in need across Abbottabad.
                    </p>
                  </div>

                  <div className="mt-5 grid grid-cols-1 gap-4 border-t border-slate-100 pt-5 sm:grid-cols-2 2xl:gap-5">
                    <InfoTile icon={Phone} label="Phone" tone="green">
                      <span className="tabular-nums">{contact.phone}</span>
                    </InfoTile>
                    <InfoTile icon={Mail} label="Email" tone="green">
                      {contact.email}
                    </InfoTile>
                    <InfoTile icon={MapPin} label="Address" tone="amber">
                      {contact.address}
                    </InfoTile>
                    <InfoTile icon={Globe} label="Website" tone="amber">
                      {contact.website}
                    </InfoTile>
                    <InfoTile icon={Landmark} label="Registration No.">
                      <span className="tabular-nums">NGO-ABT-0142</span>
                    </InfoTile>
                    <InfoTile icon={CalendarDays} label="Verified on">
                      <span className="tabular-nums">Apr 12, 2026</span>
                    </InfoTile>
                  </div>
                </div>
              </Card>

              {/* Service Areas */}
              <Card padding="none" className="overflow-hidden">
                <CardHeader className={cn("flex flex-wrap items-center justify-between gap-3", cardHeaderPad)}>
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 text-emerald-600 ring-1 ring-emerald-200 2xl:h-10 2xl:w-10">
                      <MapPin className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                    </div>
                    <div>
                      <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">
                        Service Areas
                      </h3>
                      <p className="text-xs text-slate-500">
                        <span className="tabular-nums">{areas.length}</span> areas where you accept donations
                      </p>
                    </div>
                  </div>
                </CardHeader>
                <CardBody className={cardBodyPad}>
                  {areas.length === 0 ? (
                    <EmptyState
                      icon={MapPin}
                      variant="green"
                      size="sm"
                      title="No service areas yet"
                      description="Add an area below to start receiving requests from it"
                    />
                  ) : (
                    <ul className="flex flex-wrap gap-2">
                      {areas.map((area) => (
                        <li
                          key={area}
                          className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 py-1 pl-2.5 pr-1 text-xs font-medium text-emerald-700 ring-1 ring-inset ring-emerald-600/20 transition-colors duration-150 hover:bg-emerald-100/70 sm:text-sm"
                        >
                          <MapPin className="h-3.5 w-3.5 text-emerald-600" aria-hidden="true" />
                          {area}
                          <button
                            type="button"
                            onClick={() => removeArea(area)}
                            aria-label={`Remove ${area}`}
                            className="flex h-5 w-5 items-center justify-center rounded-full text-emerald-600/70 transition-colors duration-150 hover:bg-emerald-200/70 hover:text-emerald-900 focus-visible:outline-none focus-visible:shadow-focus"
                          >
                            <X className="h-3 w-3" aria-hidden="true" />
                          </button>
                        </li>
                      ))}
                    </ul>
                  )}

                  <form onSubmit={addArea} className="mt-5 flex flex-col gap-2.5 border-t border-slate-100 pt-5 sm:flex-row">
                    <Input
                      leftIcon={Plus}
                      type="text"
                      placeholder="Add a service area..."
                      aria-label="New service area"
                      value={newArea}
                      onChange={(e) => setNewArea(e.target.value)}
                      wrapperClassName="sm:max-w-xs"
                    />
                    <Button
                      type="submit"
                      disabled={!newArea.trim()}
                      className="gap-1.5 bg-emerald-600 shadow-sm shadow-emerald-600/20 hover:bg-emerald-700"
                    >
                      <Plus className="h-4 w-4" aria-hidden="true" />
                      Add area
                    </Button>
                  </form>
                </CardBody>
              </Card>
            </div>

            {/* Organization Stats */}
            <Card padding="none" className="h-fit min-w-0 overflow-hidden">
              <CardHeader className={cn("flex items-center justify-start gap-3", cardHeaderPad)}>
                <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-gradient-to-br from-amber-50 to-amber-100 text-amber-600 ring-1 ring-amber-200 2xl:h-10 2xl:w-10">
                  <ChartColumn className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                </div>
                <div>
                  <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">
                    Organization Stats
                  </h3>
                  <p className="text-xs text-slate-500">Impact this season</p>
                </div>
              </CardHeader>
              <CardBody className="space-y-2.5 px-4 py-4 sm:px-5 2xl:space-y-3 2xl:py-5">
                {orgStats.map((s) => (
                  <div
                    key={s.label}
                    className="flex items-center gap-3 rounded-xl border border-slate-200 bg-white px-3.5 py-2.5 shadow-sm transition-all duration-150 hover:-translate-y-px hover:shadow-md 2xl:py-3.5"
                  >
                    <div className={cn("flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ring-1 2xl:h-10 2xl:w-10", s.tile)}>
                      <s.icon className="h-4 w-4" aria-hidden="true" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-xs font-medium text-slate-500">{s.label}</p>
                      <p className="mt-0.5 text-base font-semibold tabular-nums tracking-tight text-slate-900">
                        {s.value}
                      </p>
                    </div>
                  </div>
                ))}

                <div className="rounded-xl border border-emerald-200/70 bg-gradient-to-br from-emerald-50 via-white to-white px-3.5 py-3 shadow-sm">
                  <div className="flex items-center justify-between gap-3">
                    <p className="flex items-center gap-2 text-xs font-medium text-emerald-700">
                      <Percent className="h-3.5 w-3.5" aria-hidden="true" />
                      Acceptance rate
                    </p>
                    <p className="text-sm font-semibold tabular-nums text-slate-900">{ACCEPTANCE_RATE}%</p>
                  </div>
                  <div
                    className="mt-2 h-2 overflow-hidden rounded-full bg-emerald-100"
                    role="progressbar"
                    aria-valuenow={ACCEPTANCE_RATE}
                    aria-valuemin={0}
                    aria-valuemax={100}
                    aria-label="Acceptance rate"
                  >
                    <div
                      className="h-full rounded-full bg-gradient-to-r from-emerald-400 to-emerald-600"
                      style={{ width: `${ACCEPTANCE_RATE}%` }}
                    />
                  </div>
                </div>
              </CardBody>
            </Card>
          </div>
        </div>
      </main>

      {/* Edit Contact Modal */}
      <Modal
        open={editing}
        onClose={() => setEditing(false)}
        title="Edit profile"
        description="Update the contact details citizens and the municipality see"
        size="md"
      >
        <form onSubmit={saveEdit} className="flex min-h-0 flex-col">
          <ModalBody className="space-y-4">
            <Input
              label="Phone"
              leftIcon={Phone}
              type="tel"
              value={draft.phone}
              onChange={(e) => setDraft((d) => ({ ...d, phone: e.target.value }))}
              required
            />
            <Input
              label="Email"
              leftIcon={Mail}
              type="email"
              value={draft.email}
              onChange={(e) => setDraft((d) => ({ ...d, email: e.target.value }))}
              required
            />
            <Input
              label="Address"
              leftIcon={MapPin}
              type="text"
              value={draft.address}
              onChange={(e) => setDraft((d) => ({ ...d, address: e.target.value }))}
              required
            />
            <Input
              label="Website"
              leftIcon={Globe}
              type="text"
              value={draft.website}
              onChange={(e) => setDraft((d) => ({ ...d, website: e.target.value }))}
            />
          </ModalBody>
          <ModalFooter>
            <Button type="button" variant="outline" onClick={() => setEditing(false)}>
              Cancel
            </Button>
            <Button type="submit" className="bg-emerald-600 shadow-sm shadow-emerald-600/20 hover:bg-emerald-700">
              Save changes
            </Button>
          </ModalFooter>
        </form>
      </Modal>
    </div>
  );
}