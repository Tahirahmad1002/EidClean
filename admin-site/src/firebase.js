import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyBAMftlZKjXS0vnyG7vWj_SehvDLFaitB8",
  authDomain: "eidclean.firebaseapp.com",
  projectId: "eidclean",
  storageBucket: "eidclean.firebasestorage.app",
  messagingSenderId: "497546432522",
  appId: "1:497546432522:web:0249428eccc46930cf8ff3"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export default app;

// ─── SECONDARY FIREBASE APP ────────────────────────
// Used only for creating driver accounts so that the
// admin's primary session is not affected.
import { getApps } from "firebase/app";
import { getAuth as getSecondaryAuth } from "firebase/auth";

const SECONDARY_APP_NAME = "driverCreator";
export const secondaryApp =
  getApps().find((a) => a.name === SECONDARY_APP_NAME) ||
  initializeApp(firebaseConfig, SECONDARY_APP_NAME);
export const secondaryAuth = getSecondaryAuth(secondaryApp);