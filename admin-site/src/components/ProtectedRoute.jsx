// 📁 src/components/ProtectedRoute.jsx

import { Navigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";

export default function ProtectedRoute({ children }) {
  const { user, userRole, loading } = useAuth();

  // Show loading spinner while checking auth
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-500"></div>
      </div>
    );
  }

  // If no user, redirect to RoleSelection
  if (!user) {
    console.log("🔴 No user, redirecting to /");
    return <Navigate to="/" replace />;
  }

  // ✅ If user exists but role is not admin or ngo, redirect to RoleSelection
  if (userRole !== "admin" && userRole !== "ngo") {
    console.log("🔴 Invalid role:", userRole, "redirecting to /");
    return <Navigate to="/" replace />;
  }

  console.log("✅ ProtectedRoute: User authorized, rendering children");
  return children;
}