// Firebase configuration with browserLocalPersistence
import { initializeApp } from "firebase/app";
import {
    getAuth,
    signInWithEmailAndPassword,
    createUserWithEmailAndPassword,
    signOut,
    updateProfile,
    onAuthStateChanged,
    GoogleAuthProvider,
    signInWithCredential,
    indexedDBLocalPersistence,
    setPersistence
} from "firebase/auth";
import {
    getFirestore,
    doc,
    setDoc,
    getDoc,
    updateDoc,
    collection,
    query,
    orderBy,
    limit,
    getDocs,
    onSnapshot,
    serverTimestamp,
    increment
} from "firebase/firestore";
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";

const firebaseConfig = {
    apiKey: "AIzaSyBMpkFOFowWpsacrzZERzrKWUbC-eYMRO8",
    authDomain: "reset-ai-gdg.firebaseapp.com",
    projectId: "reset-ai-gdg",
    storageBucket: "reset-ai-gdg.firebasestorage.app",
    messagingSenderId: "883561761358",
    appId: "1:883561761358:web:9fa35d31d1019dbe48d11f",
    measurementId: "G-JY4LB76FHV"
};

// Initialize Firebase
export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

// Auth exports
export {
    signInWithEmailAndPassword,
    createUserWithEmailAndPassword,
    signOut,
    updateProfile,
    onAuthStateChanged,
    GoogleAuthProvider,
    signInWithCredential,
    indexedDBLocalPersistence,
    setPersistence
};

// Firestore exports
export {
    doc,
    setDoc,
    getDoc,
    updateDoc,
    collection,
    query,
    orderBy,
    limit,
    getDocs,
    onSnapshot,
    serverTimestamp,
    increment
};

// Storage exports
export { ref, uploadBytes, getDownloadURL };

// Set persistence to indexedDB (works in Service Workers)
setPersistence(auth, indexedDBLocalPersistence).catch(err => {
    console.error('Persistence error:', err);
});

console.log('Firebase initialized with IndexedDB persistence');
