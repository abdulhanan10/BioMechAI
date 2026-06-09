import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyBlhY78jXwjcdT-IvPmLqo684dXgiIeXjE",
  appId: "1:549717601795:web:c06be789c2f57541fc6836",
  messagingSenderId: "549717601795",
  projectId: "biomechai",
  authDomain: "biomechai.firebaseapp.com",
  storageBucket: "biomechai.firebasestorage.app",
  measurementId: "G-C1WY3E6C0Y"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
