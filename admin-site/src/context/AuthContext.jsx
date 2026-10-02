// 📁 src/context/AuthContext.jsx

import { createContext, useContext, useEffect, useState } from "react";
import { onAuthStateChanged } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "../firebase";

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [userRole, setUserRole] = useState(null);
  const [loading, setLoading] = useState(true);

  // ✅ Function to refresh user role
  const refreshUserRole = async () => {
    if (!user) return;
    try {
      const docRef = doc(db, "users", user.uid);
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) {
        const role = docSnap.data().role;
        console.log("🔄 Role refreshed:", role);
        setUserRole(role);
        return role;
      }
    } catch (error) {
      console.error("Error refreshing role:", error);
    }
    return null;
  };

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      console.log("🔥 Auth state changed:", firebaseUser?.uid);
      
      if (firebaseUser) {
        setUser(firebaseUser);
        try {
          const docRef = doc(db, "users", firebaseUser.uid);
          const docSnap = await getDoc(docRef);
          if (docSnap.exists()) {
            const role = docSnap.data().role;
            console.log("✅ User role loaded:", role);
            setUserRole(role);
          } else {
            console.log("❌ User document not found");
            setUserRole(null);
          }
        } catch (error) {
          console.error("Error loading user role:", error);
          setUserRole(null);
        }
      } else {
        setUser(null);
        setUserRole(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const value = {
    user,
    userRole,
    loading,
    refreshUserRole, // ✅ Expose refresh function
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}