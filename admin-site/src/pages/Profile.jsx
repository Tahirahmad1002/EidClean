// 📁 src/pages/Profile.jsx

import { useState, useEffect } from "react";
import { useAuth } from "../context/AuthContext";
import { doc, getDoc, collection, getCountFromServer } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";

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
        <main className="ml-64 flex-1 p-8 min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-500"></div>
        </main>
      </div>
    );
  }

  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8 min-h-screen bg-gray-50">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-gray-800">My Profile</h2>
              <p className="text-gray-500 text-sm mt-1">
                Manage your account information and preferences
              </p>
            </div>
            <button className="bg-emerald-500 hover:bg-emerald-600 text-white px-4 py-2 rounded-xl text-sm font-medium transition-colors">
              ✏️ Edit Profile
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Column - Profile Info */}
          <div className="lg:col-span-2 space-y-6">
            {/* Profile Card */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <div className="flex items-start gap-6">
                <div className="w-20 h-20 rounded-2xl bg-emerald-500 flex items-center justify-center text-white text-3xl font-bold">
                  {getInitials(displayName)}
                </div>
                <div className="flex-1">
                  <h3 className="text-xl font-bold text-gray-800">{displayName}</h3>
                  <p className="text-sm text-gray-500 capitalize">{userRole || "Administrator"}</p>
                  <div className="mt-3 space-y-1 text-sm">
                    <p className="text-gray-600">📧 {userEmail}</p>
                    <p className="text-gray-600">📱 {userPhone}</p>
                    <p className="text-gray-600">📍 {userCity}</p>
                    <p className="text-gray-600">📅 Joined {joinedDate}</p>
                    <p className="text-gray-600">🏢 Operations</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 text-center">
                <p className="text-2xl font-bold text-gray-800">{stats.pickupsManaged}</p>
                <p className="text-xs text-gray-500">Pickups Managed</p>
              </div>
              <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 text-center">
                <p className="text-2xl font-bold text-gray-800">{stats.workersSupervised}</p>
                <p className="text-xs text-gray-500">Workers Supervised</p>
              </div>
              <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 text-center">
                <p className="text-2xl font-bold text-gray-800">{stats.reportsGenerated}</p>
                <p className="text-xs text-gray-500">Reports Generated</p>
              </div>
              <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 text-center">
                <p className="text-2xl font-bold text-gray-800">{stats.daysActive}</p>
                <p className="text-xs text-gray-500">Days Active</p>
              </div>
            </div>

            {/* Achievements */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h3 className="font-semibold text-gray-800 mb-4">🏆 Achievements</h3>
              <div className="space-y-4">
                <div className="flex items-start gap-4 p-3 bg-gray-50 rounded-xl">
                  <div className="w-10 h-10 rounded-full bg-emerald-100 flex items-center justify-center text-lg">📋</div>
                  <div>
                    <p className="font-medium text-gray-800">First 100 Pickups</p>
                    <p className="text-sm text-gray-500">Managed first 100 waste pickups</p>
                    <p className="text-xs text-emerald-600">100% completion rate for 7 days</p>
                  </div>
                </div>
                <div className="flex items-start gap-4 p-3 bg-gray-50 rounded-xl">
                  <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center text-lg">⚡</div>
                  <div>
                    <p className="font-medium text-gray-800">Fast Response</p>
                    <p className="text-sm text-gray-500">Average response time under 30 min</p>
                  </div>
                </div>
                <div className="flex items-start gap-4 p-3 bg-gray-50 rounded-xl">
                  <div className="w-10 h-10 rounded-full bg-purple-100 flex items-center justify-center text-lg">👥</div>
                  <div>
                    <p className="font-medium text-gray-800">Team Builder</p>
                    <p className="text-sm text-gray-500">Onboarded 10+ workers</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column - Activity & Security */}
          <div className="space-y-6">
            {/* Recent Activity */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h3 className="font-semibold text-gray-800 mb-4">🕐 Recent Activity</h3>
              <div className="space-y-3">
                <div className="p-3 bg-gray-50 rounded-xl">
                  <p className="text-sm text-gray-700">Assigned Worker #5 to Gulberg pickup</p>
                  <p className="text-xs text-gray-400">2026-04-22 14:30</p>
                </div>
                <div className="p-3 bg-gray-50 rounded-xl">
                  <p className="text-sm text-gray-700">Generated weekly performance report</p>
                  <p className="text-xs text-gray-400">2026-04-22 12:15</p>
                </div>
                <div className="p-3 bg-gray-50 rounded-xl">
                  <p className="text-sm text-gray-700">Updated system settings</p>
                  <p className="text-xs text-gray-400">2026-04-22 10:45</p>
                </div>
                <div className="p-3 bg-gray-50 rounded-xl">
                  <p className="text-sm text-gray-700">Added new worker: Farhan Yousuf</p>
                  <p className="text-xs text-gray-400">2026-04-21 16:20</p>
                </div>
                <div className="p-3 bg-gray-50 rounded-xl">
                  <p className="text-sm text-gray-700">Approved 12 pickup requests</p>
                  <p className="text-xs text-gray-400">2026-04-21 14:00</p>
                </div>
              </div>
            </div>

            {/* Security Settings */}
            <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100">
              <h3 className="font-semibold text-gray-800 mb-4">🔒 Security Settings</h3>
              <div className="space-y-3">
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                  <div>
                    <p className="font-medium text-gray-800">Change Password</p>
                    <p className="text-xs text-gray-400">Update your account password</p>
                  </div>
                  <button className="text-emerald-600 text-sm font-medium">Update</button>
                </div>
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                  <div>
                    <p className="font-medium text-gray-800">Two-Factor Authentication</p>
                    <p className="text-xs text-gray-400">Add an extra layer of security</p>
                  </div>
                  <button className="text-emerald-600 text-sm font-medium">Enable</button>
                </div>
                <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
                  <div>
                    <p className="font-medium text-gray-800">Login History</p>
                    <p className="text-xs text-gray-400">View recent login activity</p>
                  </div>
                  <button className="text-emerald-600 text-sm font-medium">View</button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}