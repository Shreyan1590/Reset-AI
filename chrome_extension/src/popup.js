// RESET AI Chrome Extension - Email/Password Auth with In-Extension Password Setup
import {
    auth, db,
    signInWithEmailAndPassword, createUserWithEmailAndPassword, updateProfile, signOut,
    onAuthStateChanged,
    doc, setDoc, getDoc, serverTimestamp
} from './firebase.js';
import { updatePassword } from 'firebase/auth';

const isBrowser = () => typeof window !== "undefined" && typeof document !== "undefined";

// UI Elements
const loadingUI = document.getElementById('loading');
const loginUI = document.getElementById('login-ui');
const signupUI = document.getElementById('signup-ui');
const passwordSetupUI = document.getElementById('password-setup-ui');

// Temporary user storage for password setup flow
let pendingUser = null;

// Show loading initially
if (isBrowser()) {
    loadingUI.style.display = 'flex';
    loginUI.style.display = 'none';
    signupUI.style.display = 'none';
    passwordSetupUI.style.display = 'none';
}

// Check auth state
onAuthStateChanged(auth, async (user) => {
    if (!isBrowser()) return;
    loadingUI.style.display = 'none';

    if (user) {
        try {
            // Fetch user data from Firestore
            const userDoc = await getDoc(doc(db, 'users', user.uid));
            const fetchedUserData = userDoc.data();

            if (fetchedUserData && fetchedUserData.hasPassword === false) {
                // Only show setup if explicitly false (Google users without password)
                pendingUser = user;
                showPasswordSetupUI();
                return;
            }

            // Save session
            await chrome.storage.local.set({
                userId: user.uid,
                userEmail: user.email,
                userName: user.displayName
            });

            // Go to dashboard
            if (isBrowser()) window.location.href = 'dashboard.html';
        } catch (error) {
            console.error('Auth state error:', error);
            showLoginUI();
        }
    } else {
        showLoginUI();
    }
});

function showLoginUI() {
    loginUI.style.display = 'block';
    signupUI.style.display = 'none';
    passwordSetupUI.style.display = 'none';
}

function showSignupUI() {
    loginUI.style.display = 'none';
    signupUI.style.display = 'block';
    passwordSetupUI.style.display = 'none';
}

function showPasswordSetupUI() {
    loginUI.style.display = 'none';
    signupUI.style.display = 'none';
    passwordSetupUI.style.display = 'block';
}

// Event Listeners
document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('login-form').addEventListener('submit', handleLogin);
    document.getElementById('signup-form').addEventListener('submit', handleSignup);
    document.getElementById('password-setup-form')?.addEventListener('submit', handlePasswordSetup);

    document.getElementById('show-signup').addEventListener('click', (e) => {
        e.preventDefault();
        showSignupUI();
    });

    document.getElementById('show-login').addEventListener('click', (e) => {
        e.preventDefault();
        showLoginUI();
    });

    document.getElementById('cancel-setup')?.addEventListener('click', async (e) => {
        e.preventDefault();
        await signOut(auth);
        pendingUser = null;
        showLoginUI();
    });
});

// LOGIN - Email/Password
async function handleLogin(e) {
    e.preventDefault();
    const email = document.getElementById('login-email').value.trim();
    const password = document.getElementById('login-password').value;
    const errorEl = document.getElementById('login-error');
    const btn = document.getElementById('login-btn');

    if (!email || !password) {
        errorEl.textContent = 'Please fill in all fields';
        return;
    }

    try {
        errorEl.textContent = '';
        btn.disabled = true;
        btn.textContent = 'Signing in...';

        const result = await signInWithEmailAndPassword(auth, email, password);

        // Update last login and ensure hasPassword is true for Email/Password users
        await setDoc(doc(db, 'users', result.user.uid), {
            hasPassword: true,
            lastLogin: serverTimestamp()
        }, { merge: true });

        // Auth state listener handles redirect
    } catch (error) {
        errorEl.textContent = getErrorMessage(error.code);
        btn.disabled = false;
        btn.textContent = 'Sign In';
    }
}

// SIGNUP - Email/Password with confirmation
async function handleSignup(e) {
    e.preventDefault();
    const name = document.getElementById('signup-name').value.trim();
    const email = document.getElementById('signup-email').value.trim();
    const password = document.getElementById('signup-password').value;
    const confirm = document.getElementById('signup-confirm').value;
    const errorEl = document.getElementById('signup-error');
    const btn = document.getElementById('signup-btn');

    // Validation
    if (!name || !email || !password || !confirm) {
        errorEl.textContent = 'Please fill in all fields';
        return;
    }

    if (password !== confirm) {
        errorEl.textContent = 'Passwords do not match';
        return;
    }

    if (password.length < 6) {
        errorEl.textContent = 'Password must be at least 6 characters';
        return;
    }

    try {
        errorEl.textContent = '';
        btn.disabled = true;
        btn.textContent = 'Creating account...';

        // Create Firebase Auth account
        const result = await createUserWithEmailAndPassword(auth, email, password);
        await updateProfile(result.user, { displayName: name });

        // Create Firestore user document
        await setDoc(doc(db, 'users', result.user.uid), {
            name: name,
            email: email,
            authProvider: 'password',
            hasPassword: true,
            createdAt: serverTimestamp(),
            lastLogin: serverTimestamp()
        });

        // Auth state listener handles redirect
    } catch (error) {
        errorEl.textContent = getErrorMessage(error.code);
        btn.disabled = false;
        btn.textContent = 'Create Account';
    }
}

// PASSWORD SETUP - For Google users without password
async function handlePasswordSetup(e) {
    e.preventDefault();
    const password = document.getElementById('setup-password').value;
    const confirm = document.getElementById('setup-confirm').value;
    const errorEl = document.getElementById('setup-error');
    const btn = document.getElementById('setup-btn');

    if (!password || !confirm) {
        errorEl.textContent = 'Please fill in all fields';
        return;
    }

    if (password !== confirm) {
        errorEl.textContent = 'Passwords do not match';
        return;
    }

    if (password.length < 6) {
        errorEl.textContent = 'Password must be at least 6 characters';
        return;
    }

    if (!pendingUser) {
        errorEl.textContent = 'Session expired. Please sign in again.';
        return;
    }

    try {
        errorEl.textContent = '';
        btn.disabled = true;
        btn.textContent = 'Setting password...';

        // Update Firebase Auth password
        await updatePassword(pendingUser, password);

        // Update Firestore
        await setDoc(doc(db, 'users', pendingUser.uid), {
            hasPassword: true,
            lastLogin: serverTimestamp()
        }, { merge: true });

        // Save session
        await chrome.storage.local.set({
            userId: pendingUser.uid,
            userEmail: pendingUser.email,
            userName: pendingUser.displayName
        });

        pendingUser = null;

        // Redirect to dashboard
        if (isBrowser()) window.location.href = 'dashboard.html';
    } catch (error) {
        errorEl.textContent = getErrorMessage(error.code);
        btn.disabled = false;
        btn.textContent = 'Set Password';
    }
}

function getErrorMessage(code) {
    const messages = {
        'auth/email-already-in-use': 'Email already registered',
        'auth/invalid-email': 'Invalid email address',
        'auth/user-not-found': 'No account found with this email',
        'auth/wrong-password': 'Incorrect password',
        'auth/weak-password': 'Password too weak (min 6 characters)',
        'auth/too-many-requests': 'Too many attempts. Try again later.',
        'auth/invalid-credential': 'Invalid email or password',
        'auth/requires-recent-login': 'Please sign in again to set password',
        'auth/network-request-failed': 'Network error. Check your connection.',
    };
    return messages[code] || 'Authentication failed. Please try again.';
}

console.log('RESET AI Extension - Email/Password Auth with Password Setup');

