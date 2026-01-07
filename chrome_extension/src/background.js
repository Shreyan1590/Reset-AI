// RESET AI - Background Service Worker
// Activity Tracking with Deduplication
import {
    auth, db, onAuthStateChanged, signOut,
    doc, setDoc, getDoc, updateDoc, serverTimestamp, increment
} from './firebase.js';

// Configuration
const CONFIG = {
    IDLE_THRESHOLD: 60,
    MIN_TIME_ON_PAGE: 3000
};

// State
let activeTabId = null;
let activeTabStart = null;
let lastUrl = null;
let userId = null;
let authToken = null;
let isOffline = typeof navigator !== 'undefined' ? !navigator.onLine : false;
let resolveAuth;
const authReady = new Promise(resolve => { resolveAuth = resolve; });

// Initialize
chrome.runtime.onInstalled.addListener(() => {
    console.log('RESET AI installed');
    initStorage();
});

chrome.runtime.onStartup.addListener(() => {
    loadStoredUser();
});

// Offline detection for service worker
self.addEventListener('online', () => { isOffline = false; syncOfflineData(); });
self.addEventListener('offline', () => { isOffline = true; });

async function initStorage() {
    const defaults = {
        userId: null,
        authToken: null,
        preferences: { autoCapture: true, notifications: true }
    };

    const existing = await chrome.storage.local.get(Object.keys(defaults));
    for (const [key, value] of Object.entries(defaults)) {
        if (existing[key] === undefined) {
            await chrome.storage.local.set({ [key]: value });
        }
    }

    if (existing.userId) {
        userId = existing.userId;
        authToken = existing.authToken;
    }
}

async function loadStoredUser() {
    const stored = await chrome.storage.local.get(['userId', 'authToken', 'preferences']);
    if (stored.userId) {
        userId = stored.userId;
        authToken = stored.authToken;
    }
}

// Sync Firebase Auth state in background
onAuthStateChanged(auth, (user) => {
    if (user) {
        userId = user.uid;
        chrome.storage.local.set({ userId: user.uid });
        console.log('Background auth synced:', user.uid);
    } else {
        userId = null;
        console.log('Background auth: logged out');
    }
    resolveAuth(); // Signal that we've checked auth state

    // Listen to user doc for focus mode changes
    if (user) {
        onSnapshot(doc(db, 'users', user.uid), (doc) => {
            if (doc.exists()) {
                const data = doc.data();
                if (data.focusMode !== undefined) {
                    chrome.storage.local.set({ focusMode: data.focusMode });
                    console.log('Synced focus mode:', data.focusMode);
                }
            }
        });
    }
});

async function ensureAuth() {
    await authReady;
    return auth.currentUser?.uid || userId;
}

// Tab Tracking
chrome.tabs.onActivated.addListener(async (activeInfo) => {
    if (activeTabId && activeTabStart && lastUrl) {
        const duration = Date.now() - activeTabStart;
        if (duration > CONFIG.MIN_TIME_ON_PAGE) {
            await updateTimeSpent(lastUrl, duration);
        }
    }

    activeTabId = activeInfo.tabId;
    activeTabStart = Date.now();

    try {
        const tab = await chrome.tabs.get(activeInfo.tabId);
        if (tab.url && !isIgnored(tab.url)) {
            lastUrl = tab.url;
            await trackVisit(tab.url, tab.title);
        }
    } catch (e) { }
});

chrome.tabs.onUpdated.addListener(async (tabId, changeInfo, tab) => {
    if (changeInfo.status === 'complete' && tabId === activeTabId) {
        if (tab.url && !isIgnored(tab.url) && tab.url !== lastUrl) {
            if (lastUrl && activeTabStart) {
                const duration = Date.now() - activeTabStart;
                if (duration > CONFIG.MIN_TIME_ON_PAGE) {
                    await updateTimeSpent(lastUrl, duration);
                }
            }

            lastUrl = tab.url;
            activeTabStart = Date.now();
            await trackVisit(tab.url, tab.title);
        }
    }
});

async function isAutoCaptureEnabled() {
    const res = await chrome.storage.local.get(['preferences']);
    return res.preferences?.autoCapture !== false; // Default true
}

// Track Visit with DEDUPLICATION
// Aligned with requirements: users/{uid}/history/{domain}
async function trackVisit(url, title, force = false) {
    const uid = await ensureAuth();
    if (!uid || isOffline) return;
    if (!force && !(await isAutoCaptureEnabled())) return;

    try {
        const domain = getDomain(url);
        if (!domain) return;

        // Use domain itself as ID (escaped) or hash if needed. 
        // Requirements say userData/{uid}/activity/{domain}
        const domainId = domain.replace(/\./g, '_');
        const historyRef = doc(db, 'userData', uid, 'activity', domainId);

        const existing = await getDoc(historyRef);

        if (existing.exists()) {
            await updateDoc(historyRef, {
                visitCount: increment(1),
                lastVisited: serverTimestamp(),
                capturedAt: serverTimestamp(), // Sync with web app
                userId: uid, // For web app filtering
                title: title || existing.data().title || domain,
                url: url
            });
        } else {
            await setDoc(historyRef, {
                domain: domain,
                url: url,
                title: title || domain,
                visitCount: 1,
                totalTimeSpent: 0,
                distractionScore: 0,
                type: detectType(domain),
                userId: uid, // Must include for web app filtering
                capturedAt: serverTimestamp(),
                firstVisited: serverTimestamp(),
                lastVisited: serverTimestamp()
            });
        }

        // Update main user record lastActive
        await updateDoc(doc(db, 'users', uid), {
            lastActive: serverTimestamp()
        });

    } catch (e) {
        console.error('Track error:', e);
    }
}

async function updateTimeSpent(url, duration) {
    const uid = await ensureAuth();
    if (!uid || isOffline) return;
    if (!(await isAutoCaptureEnabled())) return;

    try {
        const domain = getDomain(url);
        if (!domain) return;

        const domainId = domain.replace(/\./g, '_');
        const historyRef = doc(db, 'userData', uid, 'activity', domainId);

        const existing = await getDoc(historyRef);
        if (existing.exists()) {
            await updateDoc(historyRef, {
                totalTimeSpent: increment(duration)
            });
        }
    } catch (e) { }
}

function getDomain(url) {
    try {
        return new URL(url).hostname.replace('www.', '');
    } catch {
        return null;
    }
}

function isIgnored(url) {
    const ignored = ['chrome://', 'chrome-extension://', 'about:', 'edge://', 'file://', 'localhost'];
    return ignored.some(prefix => url.startsWith(prefix));
}

function detectType(domain) {
    const types = {
        'github.com': 'code', 'stackoverflow.com': 'code', 'gitlab.com': 'code',
        'docs.google.com': 'document', 'notion.so': 'document',
        'youtube.com': 'video', 'netflix.com': 'video',
        'mail.google.com': 'email', 'outlook.com': 'email',
        'twitter.com': 'social', 'facebook.com': 'social', 'linkedin.com': 'social', 'instagram.com': 'social',
        'amazon.com': 'shopping', 'flipkart.com': 'shopping'
    };

    for (const [d, type] of Object.entries(types)) {
        if (domain.includes(d)) return type;
    }
    return 'tab';
}

async function syncOfflineData() {
    console.log('Online - ready to sync');
    // For a hackathon, we'll keep it simple. Real apps would use IndexedDB fallback.
}

// Message Handlers
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    switch (message.type) {
        case 'SET_USER':
            userId = message.userId;
            authToken = message.authToken;
            chrome.storage.local.set({ userId, authToken });
            // Fetch preferences from Firestore (non-blocking)
            getDoc(doc(db, 'users', userId)).then(snap => {
                if (snap.exists() && snap.data().preferences) {
                    chrome.storage.local.set({ preferences: snap.data().preferences });
                }
            }).catch(err => console.error('Pref fetch error:', err));
            sendResponse({ success: true });
            return false; // Sync response

        case 'UPDATE_PREFERENCES':
            chrome.storage.local.get(['preferences']).then(res => {
                const updated = { ...(res.preferences || {}), ...message.preferences };
                chrome.storage.local.set({ preferences: updated });
            }).catch(err => console.error('Pref update error:', err));
            sendResponse({ success: true });
            return false; // Sync response

        case 'USER_LOGOUT':
            userId = null;
            authToken = null;
            chrome.storage.local.set({ userId: null, authToken: null, preferences: null });
            signOut(auth).catch(() => { });
            sendResponse({ success: true });
            return false; // Sync response

        case 'CAPTURE_NOW':
            // Async flow: return true
            chrome.tabs.query({ active: true, currentWindow: true }).then(async tabs => {
                try {
                    if (tabs[0] && tabs[0].url && !isIgnored(tabs[0].url)) {
                        await trackVisit(tabs[0].url, tabs[0].title, true);
                        sendResponse({ success: true });
                    } else {
                        sendResponse({ success: false, error: 'Invalid tab for capture' });
                    }
                } catch (e) {
                    console.error('CAPTURE_NOW error:', e);
                    sendResponse({ success: false, error: e.message });
                }
            }).catch(err => {
                sendResponse({ success: false, error: err.message });
            });
            return true; // Keep channel open

        default:
            console.warn('Unknown message type:', message.type);
            sendResponse({ success: false, error: 'Unknown message type' });
            return false;
    }
});

// Idle Detection
chrome.idle.onStateChanged.addListener((state) => {
    if (state === 'active') {
        activeTabStart = Date.now();
    } else if (activeTabId && activeTabStart && lastUrl) {
        const duration = Date.now() - activeTabStart;
        if (duration > CONFIG.MIN_TIME_ON_PAGE) {
            updateTimeSpent(lastUrl, duration);
        }
        activeTabStart = null;
    }
});

chrome.idle.setDetectionInterval(CONFIG.IDLE_THRESHOLD);

console.log('RESET AI Background initialized');

