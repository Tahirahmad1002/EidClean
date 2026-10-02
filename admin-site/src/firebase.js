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