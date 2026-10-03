// src/pages/Profile.jsx

import { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { doc, getDoc, collection, getCountFromServer } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";
import {
  Building2,
  Calendar,
  ClipboardList,
  Clock,
  FileText,
  LoaderCircle,
  Lock,
  Mail,
  MapPin,
  Moon,
  Pencil,
  Smartphone,
  Trophy,
  Users,
  Zap,
} from "lucide-react";
import {
  Badge,
  Button,
  Card,
  CardBody,
  CardHeader,
  StatCard,
} from "../components/ui";
import { cn } from "../lib/utils";

const tones = {
  blue: {
    wrap: "bg-blue-50/70 ring-blue-100 hover:bg-blue-50",
    tile: "text-blue-600 ring-blue-100",
    label: "text-blue-700",
  },
  teal: {
    wrap: "bg-teal-50/70 ring-teal-100 hover:bg-teal-50",
    tile: "text-teal-600 ring-teal-100",
    label: "text-teal-700",
  },
  amber: {
    wrap: "bg-amber-50/70 ring-amber-100 hover:bg-amber-50",
    tile: "text-amber-600 ring-amber-100",
    label: "text-amber-700",
  },
  emerald: {
    wrap: "bg-emerald-50/70 ring-emerald-100 hover:bg-emerald-50",
    tile: "text-emerald-600 ring-emerald-100",
    label: "text-emerald-700",
  },
  slate: {
    wrap: "bg-slate-50 ring-slate-200 hover:bg-slate-100",
    tile: "text-slate-600 ring-slate-200",
    label: "text-slate-500",
  },
};

const achievements = [
  {
    icon: ClipboardList,
    tone: "emerald",
    title: "First 100 Pickups",
    description: "Managed first 100 waste pickups",
    note: "100% completion rate for 7 days",
  },
  {
    icon: Zap,
    tone: "blue",
    title: "Fast Response",
    description: "Average response time under 30 min",
  },
  {
    icon: Users,
    tone: "teal",
    title: "Team Builder",
    description: "Onboarded 10+ workers",
  },
];

const activities = [
  { text: "Assigned Worker #5 to Gulberg pickup", time: "2026-04-22 14:30" },
  { text: "Generated weekly performance report", time: "2026-04-22 12:15" },
  { text: "Updated system settings", time: "2026-04-22 10:45" },
  { text: "Added new worker: Farhan Yousuf", time: "2026-04-21 16:20" },
  { text: "Approved 12 pickup requests", time: "2026-04-21 14:00" },
];

const securityItems = [
  {
    title: "Change Password",
    description: "Update your account password",
    action: "Update",
  },
  {
    title: "Two-Factor Authentication",
    description: "Add an extra layer of security",
    action: "Enable",
  },
  {
    title: "Login History",
    description: "View recent login activity",
    action: "View",
  },
];

export default function Profile() {
  const { user, userRole } = useAuth();
  const [userData, setUserData] = useState(null);
  const [stats, setStats] = useState({
    pickupsManaged: 0,
    workersSupervised: 0,
    reportsGenerated: 0,
    daysActive: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchProfileData();
  }, [user]);

  async function fetchProfileData() {
    if (!user) return;
    setLoading(true);

    try {
      // Get user data from Firestore
      const userDoc = await getDoc(doc(db, "users", user.uid));
      if (userDoc.exists()) {
        setUserData(userDoc.data());
      }

      // Get stats
      const pickupSnap = await getCountFromServer(collection(db, "pickupRequests"));
      const totalPickups = pickupSnap.data().count;

      const driverSnap = await getCountFromServer(collection(db, "drivers"));
      const totalDrivers = driverSnap.data().count;

      let daysActive = 0;
      if (user.metadata?.creationTime) {
        const created = new Date(user.metadata.creationTime);
        const now = new Date();
        daysActive = Math.floor((now - created) / (1000 * 60 * 60 * 24));
      }

      setStats({
        pickupsManaged: totalPickups,
        workersSupervised: totalDrivers,
        reportsGenerated: Math.floor(totalPickups * 0.15),
        daysActive: daysActive || 98,
      });

    } catch (error) {
      console.error("Error fetching profile data:", error);
    }
    setLoading(false);
  }

  const getInitials = (name) => {
    if (!name) return user?.email?.charAt(0).toUpperCase() || "A";
    return name.split(' ').map(word => word[0]).join('').toUpperCase().slice(0, 2);
  };

  const displayName = userData?.name || user?.displayName || "Admin";
  const userEmail = user?.email || "admin@eidclean.com";
  const userPhone = userData?.phone || "+92 300 1234567";
  const userCity = userData?.city || "Abbottabad, Pakistan";
  const joinedDate = user?.metadata?.creationTime
    ? new Date(user.metadata.creationTime).toLocaleDateString("en-US", {
        year: "numeric",
        month: "long",
        day: "numeric",
      })
    : "January 15, 2024";

  if (loading) {
    return (
      <div className="flex">
        <Sidebar />
        <main className="ml-64 flex min-h-screen flex-1 items-center justify-center bg-gradient-to-b from-emerald-50/60 via-slate-50 to-slate-50 p-4 sm:p-5 lg:p-6">
          <div className="flex flex-col items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-white shadow-sm ring-1 ring-slate-200">
              <LoaderCircle className="h-6 w-6 animate-spin text-emerald-500" aria-hidden="true" />
            </div>
            <p className="text-sm font-medium text-slate-500">Loading profile</p>
          </div>
        </main>
      </div>
    );
  }

  const details = [
    { icon: Mail, tone: "blue", label: "Email", value: userEmail },
    { icon: Smartphone, tone: "teal", label: "Phone", value: userPhone },
    { icon: MapPin, tone: "amber", label: "Location", value: userCity },
    { icon: Calendar, tone: "emerald", label: "Joined", value: joinedDate },
    { icon: Building2, tone: "slate", label: "Department", value: "Operations" },
  ];

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 min-h-screen flex-1 bg-gradient-to-b from-emerald-50/60 via-slate-50 to-slate-50 py-4 sm:py-5 lg:py-6">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-10">
          {/* Hero */}
          <div className="relative mb-5 overflow-hidden rounded-2xl bg-gradient-to-br from-emerald-600 via-emerald-600 to-teal-600 p-4 shadow-lg shadow-emerald-900/10 ring-1 ring-emerald-700/20 sm:mb-6 sm:p-5 lg:mb-8 lg:p-6">
            <div
              className="pointer-events-none absolute inset-0 bg-[linear-gradient(to_right,rgba(255,255,255,0.07)_1px,transparent_1px),linear-gradient(to_bottom,rgba(255,255,255,0.07)_1px,transparent_1px)] bg-[size:28px_28px]"
              aria-hidden="true"
            />
            <div
              className="pointer-events-none absolute -right-16 -top-20 h-64 w-64 rounded-full bg-white/10"
              aria-hidden="true"
            />
            <div
              className="pointer-events-none absolute -bottom-28 right-40 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl"
              aria-hidden="true"
            />
            <Moon
              className="pointer-events-none absolute right-6 top-4 h-24 w-24 text-white/10"
              aria-hidden="true"
            />

            <div className="relative flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="flex items-center gap-4">
                <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl bg-white/15 text-2xl font-semibold tracking-tight text-white ring-1 ring-white/30 backdrop-blur sm:h-20 sm:w-20 sm:text-3xl">
                  {getInitials(displayName)}
                </div>
                <div className="min-w-0">
                  <div className="flex flex-wrap items-center gap-2">
                    <h2 className="truncate text-2xl font-semibold tracking-tight text-white sm:text-3xl">
                      {displayName}
                    </h2>
                    <Badge
                      variant="green"
                      dot
                      className="bg-white/15 capitalize text-emerald-50 ring-white/25"
                    >
                      {userRole || "Administrator"}
                    </Badge>
                  </div>
                  <p className="mt-1 text-sm text-emerald-50/80">
                    Manage your account information and preferences
                  </p>
                </div>
              </div>

              <Button
                variant="outline"
                leftIcon={Pencil}
                className="border-white/25 bg-white/10 text-white backdrop-blur hover:border-white/30 hover:bg-white/20 active:bg-white/25"
              >
                Edit Profile
              </Button>
            </div>
          </div>

          {/* Stats */}
          <div className="mb-5 grid grid-cols-2 gap-3 sm:mb-6 sm:gap-4 lg:mb-8 lg:grid-cols-4 lg:gap-6">
            <StatCard
              label="Pickups Managed"
              value={stats.pickupsManaged}
              icon={ClipboardList}
              variant="blue"
              className="p-4 transition-all duration-200 hover:-translate-y-0.5 sm:p-5"
            />
            <StatCard
              label="Workers Supervised"
              value={stats.workersSupervised}
              icon={Users}
              variant="teal"
              className="p-4 transition-all duration-200 hover:-translate-y-0.5 sm:p-5"
            />
            <StatCard
              label="Reports Generated"
              value={stats.reportsGenerated}
              icon={FileText}
              variant="yellow"
              className="p-4 transition-all duration-200 hover:-translate-y-0.5 sm:p-5"
            />
            <StatCard
              label="Days Active"
              value={stats.daysActive}
              icon={Calendar}
              variant="green"
              className="p-4 transition-all duration-200 hover:-translate-y-0.5 sm:p-5"
            />
          </div>

          <div className="grid grid-cols-1 gap-4 sm:gap-5 lg:grid-cols-3 lg:gap-6">
            {/* Left Column */}
            <div className="space-y-4 sm:space-y-5 lg:col-span-2 lg:space-y-6">
              {/* Contact Details */}
              <Card padding="none" className="overflow-hidden">
                <CardHeader className="flex items-center gap-3 px-4 py-4 sm:px-5 lg:px-6">
                  <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-blue-50 text-blue-600 ring-1 ring-blue-100">
                    <Mail className="h-4 w-4" aria-hidden="true" />
                  </div>
                  <div>
                    <h3 className="text-base font-semibold tracking-tight text-slate-900">
                      Contact Details
                    </h3>
                    <p className="text-xs text-slate-500">How to reach you</p>
                  </div>
                </CardHeader>
                <CardBody className="p-4 sm:p-5 lg:p-6">
                  <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                    {details.map((item, index) => {
                      const t = tones[item.tone];
                      return (
                        <div
                          key={item.label}
                          className={cn(
                            "flex items-center gap-3 rounded-xl p-3.5 ring-1 transition-colors duration-150",
                            t.wrap,
                            index === details.length - 1 && "sm:col-span-2"
                          )}
                        >
                          <div
                            className={cn(
                              "flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-white shadow-sm ring-1",
                              t.tile
                            )}
                          >
                            <item.icon className="h-4 w-4" aria-hidden="true" />
                          </div>
                          <div className="min-w-0">
                            <p className={cn("text-xs font-medium", t.label)}>{item.label}</p>
                            <p className="mt-0.5 truncate text-sm font-semibold text-slate-900">
                              {item.value}
                            </p>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </CardBody>
              </Card>

              {/* Achievements */}
              <Card padding="none" className="overflow-hidden">
                <CardHeader className="flex items-center gap-3 px-4 py-4 sm:px-5 lg:px-6">
                  <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-amber-50 text-amber-600 ring-1 ring-amber-100">
                    <Trophy className="h-4 w-4" aria-hidden="true" />
                  </div>
                  <div>
                    <h3 className="text-base font-semibold tracking-tight text-slate-900">
                      Achievements
                    </h3>
                    <p className="text-xs text-slate-500">Milestones you have reached</p>
                  </div>
                </CardHeader>
                <CardBody className="p-4 sm:p-5 lg:p-6">
                  <div className="space-y-3">
                    {achievements.map((item) => {
                      const t = tones[item.tone];
                      return (
                        <div
                          key={item.title}
                          className={cn(
                            "flex items-start gap-3 rounded-xl p-3.5 ring-1 transition-colors duration-150",
                            t.wrap
                          )}
                        >
                          <div
                            className={cn(
                              "flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-white shadow-sm ring-1",
                              t.tile
                            )}
                          >
                            <item.icon className="h-4 w-4" aria-hidden="true" />
                          </div>
                          <div className="min-w-0">
                            <p className="text-sm font-semibold text-slate-900">{item.title}</p>
                            <p className="mt-0.5 text-sm text-slate-500">{item.description}</p>
                            {item.note && (
                              <p className={cn("mt-1 text-xs font-medium", t.label)}>{item.note}</p>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </CardBody>
              </Card>
            </div>

            {/* Right Column */}
            <div className="space-y-4 sm:space-y-5 lg:space-y-6">
              {/* Recent Activity */}
              <Card padding="none" className="overflow-hidden">
                <CardHeader className="flex items-center gap-3 px-4 py-4 sm:px-5 lg:px-6">
                  <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-teal-50 text-teal-600 ring-1 ring-teal-100">
                    <Clock className="h-4 w-4" aria-hidden="true" />
                  </div>
                  <div>
                    <h3 className="text-base font-semibold tracking-tight text-slate-900">
                      Recent Activity
                    </h3>
                    <p className="text-xs text-slate-500">Your latest actions</p>
                  </div>
                </CardHeader>
                <CardBody className="p-4 sm:p-5 lg:p-6">
                  <div className="space-y-2.5">
                    {activities.map((item) => (
                      <div
                        key={item.text}
                        className="flex items-start gap-3 rounded-xl bg-slate-50 p-3 ring-1 ring-slate-200/70 transition-colors duration-150 hover:bg-slate-100"
                      >
                        <span
                          className="mt-1.5 h-2 w-2 shrink-0 rounded-full bg-emerald-500 ring-4 ring-emerald-100"
                          aria-hidden="true"
                        />
                        <div className="min-w-0">
                          <p className="text-sm font-medium text-slate-800">{item.text}</p>
                          <p className="mt-0.5 text-xs tabular-nums text-slate-400">{item.time}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                </CardBody>
              </Card>

              {/* Security Settings */}
              <Card padding="none" className="overflow-hidden">
                <CardHeader className="flex items-center gap-3 px-4 py-4 sm:px-5 lg:px-6">
                  <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-emerald-50 text-emerald-600 ring-1 ring-emerald-100">
                    <Lock className="h-4 w-4" aria-hidden="true" />
                  </div>
                  <div>
                    <h3 className="text-base font-semibold tracking-tight text-slate-900">
                      Security Settings
                    </h3>
                    <p className="text-xs text-slate-500">Protect your account</p>
                  </div>
                </CardHeader>
                <CardBody className="p-4 sm:p-5 lg:p-6">
                  <div className="space-y-2.5">
                    {securityItems.map((item) => (
                      <div
                        key={item.title}
                        className="flex items-center justify-between gap-3 rounded-xl bg-slate-50 p-3 ring-1 ring-slate-200/70 transition-colors duration-150 hover:bg-slate-100"
                      >
                        <div className="min-w-0">
                          <p className="text-sm font-semibold text-slate-900">{item.title}</p>
                          <p className="mt-0.5 text-xs text-slate-500">{item.description}</p>
                        </div>
                        <Button variant="outline" size="sm" className="shrink-0">
                          {item.action}
                        </Button>
                      </div>
                    ))}
                  </div>
                </CardBody>
              </Card>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}