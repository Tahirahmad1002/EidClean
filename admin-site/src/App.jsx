// 📁 src/App.jsx

import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import ProtectedRoute from "./components/ProtectedRoute";

// Admin Screens
import RoleSelection from "./pages/RoleSelection";
import AdminSplash from "./pages/AdminSplash";
import AdminLogin from "./pages/AdminLogin";

// NGO Screens
import NGOSplash from "./pages/NGOSplash";
import NGOLogin from "./pages/NGOLogin";
import NGODashboard from "./pages/NGODashboard";
import NGODonations from "./pages/NGODonations";
import NGOAcceptedPickups from "./pages/NGOAcceptedPickups";
import NGOHistory from "./pages/NGOHistory";
import NGOProfile from "./pages/NGOProfile";

// Admin Pages
import Dashboard from "./pages/Dashboard";
import Reports from "./pages/Reports";
import Drivers from "./pages/Drivers";
import Areas from "./pages/Areas";
import Predictions from "./pages/Predictions";
import Settings from "./pages/Settings";
import Analytics from "./pages/Analytics";
import Profile from "./pages/Profile";

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Role Selection */}
          <Route path="/" element={<RoleSelection />} />

          {/* Admin Flow */}
          <Route path="/admin-splash" element={<AdminSplash />} />
          <Route path="/admin-login" element={<AdminLogin />} />

          {/* NGO Flow */}
          <Route path="/ngo-splash" element={<NGOSplash />} />
          <Route path="/ngo-login" element={<NGOLogin />} />
          <Route path="/ngo-dashboard" element={<NGODashboard />} />
          <Route path="/ngo-donations" element={<NGODonations />} />
          <Route path="/ngo-pickups" element={<NGOAcceptedPickups />} />
          <Route path="/ngo-history" element={<NGOHistory />} />
          <Route path="/ngo-profile" element={<NGOProfile />} />

          {/* Admin Protected Routes */}
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/reports"
            element={
              <ProtectedRoute>
                <Reports />
              </ProtectedRoute>
            }
          />
          <Route
            path="/drivers"
            element={
              <ProtectedRoute>
                <Drivers />
              </ProtectedRoute>
            }
          />
          <Route
            path="/analytics"
            element={
              <ProtectedRoute>
                <Analytics />
              </ProtectedRoute>
            }
          />
          <Route
            path="/areas"
            element={
              <ProtectedRoute>
                <Areas />
              </ProtectedRoute>
            }
          />
          <Route
            path="/predictions"
            element={
              <ProtectedRoute>
                <Predictions />
              </ProtectedRoute>
            }
          />
          <Route
            path="/settings"
            element={
              <ProtectedRoute>
                <Settings />
              </ProtectedRoute>
            }
          />
          <Route
            path="/profile"
            element={
              <ProtectedRoute>
                <Profile />
              </ProtectedRoute>
            }
          />

          {/* Fallback */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}