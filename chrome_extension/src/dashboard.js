// RESET AI Chrome Extension - Dashboard
import {
    auth, db,
    onAuthStateChanged, signOut,
    doc, getDoc, updateDoc, setDoc, collection, query, orderBy, limit, getDocs,
    onSnapshot, serverTimestamp, increment
} from './firebase.js';

const WEB_APP_URL = 'https://reset-ai-gdg.web.app';

let currentUser = null;
let unsubscribeProfile = null;
let unsubscribeHistory = null;

const isBrowser = () => typeof window !== "undefined" && typeof document !== "undefined";

// UI Elements
const recentList = document.getElementById('recent-list');
const historyList = document.getElementById('history-list');
const historyCount = document.getElementById('history-count');

// Check auth state
onAuthStateChanged(auth, async (user) => {
    if (user) {
        currentUser = user;

        // Verify user doc and hasPassword
        try {
            const userDoc = await getDoc(doc(db, 'users', user.uid));
            if (userDoc.exists()) {
                const data = userDoc.data();
                if (data.hasPassword === false) {
                    if (isBrowser()) window.location.href = 'popup.html';
                    return;
                }
            }
        } catch (e) {
            console.warn('Profile fetch error:', e);
        }

        await loadDashboard(user);
    } else {
        // Only redirect if we are sure we're not logged in
        if (isBrowser()) {
            try {
                await chrome.storage.local.remove(['userId', 'userEmail', 'userName']);
            } catch (e) { }
            window.location.href = 'popup.html';
        }
    }
});

async function loadDashboard(user) {
    if (!isBrowser()) return;

    // Update last login
    try {
        await updateDoc(doc(db, 'users', user.uid), {
            lastLogin: serverTimestamp()
        });
    } catch (e) {
        console.warn('Update lastLogin error:', e);
    }

    // Refresh credentials in background
    try {
        chrome.runtime.sendMessage({
            type: 'SET_USER',
            userId: user.uid,
            authToken: await user.getIdToken()
        });
    } catch (e) { }

    setupListeners(user.uid);
    loadUserProfile(user);
    loadRecentActivity(user.uid);
    setupEventListeners();
}

function setupEventListeners() {
    // Navigation
    document.querySelectorAll('.nav-item').forEach(item => {
        item.onclick = (e) => {
            e.preventDefault();
            navigateTo(item.dataset.page);
        };
    });

    document.getElementById('capture-btn')?.addEventListener('click', captureNow);
    document.getElementById('sync-btn')?.addEventListener('click', syncData);
    document.getElementById('save-btn')?.addEventListener('click', saveProfile);
    document.getElementById('web-btn')?.addEventListener('click', () => {
        chrome.tabs.create({ url: WEB_APP_URL });
    });
    document.getElementById('web-analytics-btn')?.addEventListener('click', () => {
        chrome.tabs.create({ url: `${WEB_APP_URL}/#/analytics` });
    });
    document.getElementById('logout-btn')?.addEventListener('click', logoutUser);

    // Preferences sync
    document.getElementById('pref-auto')?.addEventListener('change', (e) => savePreference('autoCapture', e.target.checked));
    document.getElementById('pref-notif')?.addEventListener('change', (e) => savePreference('notifications', e.target.checked));
}

async function savePreference(key, value) {
    if (!currentUser) return;
    try {
        await updateDoc(doc(db, 'users', currentUser.uid), {
            [`preferences.${key}`]: value
        });
        showToast('Preference saved', 'success');
        // Let background script know
        chrome.runtime.sendMessage({ type: 'UPDATE_PREFERENCES', preferences: { [key]: value } });
    } catch (e) {
        console.error('Save preference error:', e);
    }
}

async function logoutUser() {
    if (unsubscribeProfile) unsubscribeProfile();
    if (unsubscribeHistory) unsubscribeHistory();

    await signOut(auth);
    await chrome.storage.local.remove(['userId', 'userEmail', 'userName']);
    chrome.runtime.sendMessage({ type: 'USER_LOGOUT' });
    window.location.href = 'popup.html';
}

async function setupListeners(uid) {
    if (!uid) return;

    // Proactive initial fetch for faster UI
    try {
        const historyRef = collection(db, 'userData', uid, 'activity');
        const historyQuery = query(historyRef, orderBy('lastVisited', 'desc'), limit(50));
        const initialSnap = await getDocs(historyQuery);
        const history = [];
        initialSnap.forEach(doc => history.push({ id: doc.id, ...doc.data() }));
        updateHistoryUI(history);
        updateStats(history);
    } catch (e) {
        console.warn('Initial history fetch error:', e);
        updateHistoryUI([]);
    }

    // Cleanup existing listeners
    if (unsubscribeProfile) unsubscribeProfile();
    if (unsubscribeHistory) unsubscribeHistory();

    const userRef = doc(db, 'users', uid);
    unsubscribeProfile = onSnapshot(userRef, (doc) => {
        if (doc.exists()) updateProfileUI(doc.data());
    }, (error) => {
        console.error('Profile listener error:', error);
    });

    const historyRef = collection(db, 'userData', uid, 'activity');
    const historyQuery = query(historyRef, orderBy('lastVisited', 'desc'), limit(50));

    unsubscribeHistory = onSnapshot(historyQuery, (snapshot) => {
        const history = [];
        snapshot.forEach(doc => history.push({ id: doc.id, ...doc.data() }));
        updateHistoryUI(history);
        updateStats(history);
    }, (error) => {
        console.error('History listener error:', error);
        // Ensure UI isn't stuck loading
        updateHistoryUI([]);
    });
}

function loadUserProfile(user) {
    const name = user.displayName || 'User';
    const email = user.email || '';
    const photoURL = user.photoURL || `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=E8F0FE&color=1A73E8&bold=true`;

    setText('user-name', name);
    setText('user-email', email);
    setSrc('user-avatar', photoURL);
    setText('settings-name', name);
    setText('settings-email', email);
    setSrc('settings-avatar', photoURL);
    setValue('edit-name', name);
}

function updateProfileUI(data) {
    const name = data.name || currentUser?.displayName || 'User';
    const photoURL = data.photoURL || currentUser?.photoURL ||
        `https://ui-avatars.com/api/?name=${encodeURIComponent(name)}&background=E8F0FE&color=1A73E8&bold=true`;

    setText('user-name', name);
    setSrc('user-avatar', photoURL);
    if (data.focusScore !== undefined) {
        setText('focus-score', data.focusScore);
    }
    setText('settings-name', name);
    setSrc('settings-avatar', photoURL);
    setValue('edit-name', name);

    // Sync preferences UI
    if (data.preferences) {
        setChecked('pref-auto', data.preferences.autoCapture);
        setChecked('pref-notif', data.preferences.notifications);
    }
}

function setChecked(id, checked) {
    const el = document.getElementById(id);
    if (el && checked !== undefined) el.checked = checked;
}

function updateStats(history) {
    const totalVisits = history.reduce((sum, item) => sum + (item.visitCount || 1), 0);
    setText('stat-visits', totalVisits);
    setText('stat-domains', history.length);

    const today = new Date().toDateString();
    const todayHistory = history.filter(item => {
        const date = item.lastVisited?.toDate?.();
        return date && date.toDateString() === today;
    });

    setText('stat-today', todayHistory.length);

    // Calculate Focus Score and Distractions
    const { score, distractions } = calculateFocusScore(todayHistory, history.length);
    setText('focus-score', Math.round(score));
    setText('stat-distractions', distractions);

    // Also update profile record if needed (throttle this in production)
    if (currentUser && Math.abs((currentUser.focusScore || 0) - score) > 5) {
        updateDoc(doc(db, 'users', currentUser.uid), { focusScore: Math.round(score) }).catch(() => { });
    }

    // Update Top Workspaces for Analytics Page
    updateTopWorkspaces(history);
}

function updateTopWorkspaces(history) {
    const listEl = document.getElementById('top-workspaces-list');
    if (!listEl) return;

    if (!history.length) {
        listEl.innerHTML = '<div class="empty">No data available.</div>';
        return;
    }

    const domains = {};
    history.forEach(item => {
        const d = item.domain || 'unknown';
        domains[d] = (domains[d] || 0) + (item.visitCount || 1);
    });

    const sorted = Object.entries(domains)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 5);

    const max = sorted[0][1];

    listEl.innerHTML = sorted.map(([domain, count]) => `
        <div class="list-item">
            <div class="list-info">
                <div class="list-title">${escapeHtml(domain)}</div>
                <div class="progress-container">
                    <div class="progress-bar" style="width: ${(count / max * 100)}%"></div>
                </div>
            </div>
            <span class="list-badge">${count}</span>
        </div>
    `).join('');
}

function calculateFocusScore(todayHistory, totalUniqueDomains) {
    if (todayHistory.length === 0) return { score: 100, distractions: 0 };

    const switchCount = todayHistory.length;
    const uniqueDomainsToday = new Set(todayHistory.map(h => h.domain)).size;

    // Distraction detection (Sync with Web App)
    const distractionDomains = ['twitter.com', 'facebook.com', 'instagram.com', 'youtube.com', 'netflix.com', 'amazon.com', 'flipkart.com', 'reddit.com'];
    const distractionTypes = ['social', 'video', 'shopping'];

    let internalDistractions = 0;
    todayHistory.forEach(ctx => {
        let isDistraction = false;
        if (distractionTypes.includes(ctx.type)) isDistraction = true;
        if (distractionDomains.some(d => ctx.domain.includes(d))) isDistraction = true;

        if (isDistraction && !ctx.isRecovered) {
            internalDistractions++;
        }
    });

    let score = 100;

    // Penalty for distractions (direct hits)
    score -= internalDistractions * 8;

    // Penalty for excessive context switching
    if (switchCount > 8) {
        score -= (switchCount - 8) * 1.5;
    }

    // Penalty for too many domains
    if (uniqueDomainsToday > 4) {
        score -= (uniqueDomainsToday - 4) * 4;
    }

    const distractions = internalDistractions + (switchCount > 10 ? Math.floor((switchCount - 10) / 2) : 0);

    return {
        score: Math.max(0, Math.min(100, score)),
        distractions
    };
}

function updateHistoryUI(history) {
    if (!historyList) return;

    if (!history.length) {
        historyList.innerHTML = '<div class="empty">📜 No browsing history yet. Start exploring!</div>';
        if (historyCount) historyCount.textContent = '0 domains';
        return;
    }

    const sorted = [...history].sort((a, b) => (b.visitCount || 1) - (a.visitCount || 1));
    if (historyCount) historyCount.textContent = `${sorted.length} domains`;

    historyList.innerHTML = sorted.map(item => `
        <div class="list-item" data-url="${escapeHtml(item.url || '')}">
            <span class="list-icon">${getIcon(item.type)}</span>
            <div class="list-info">
                <div class="list-title">${escapeHtml(item.title || item.domain)}</div>
                <div class="list-meta">${escapeHtml(item.domain)} • ${formatDuration(item.totalTimeSpent || 0)}</div>
            </div>
            <span class="list-badge">×${item.visitCount || 1}</span>
        </div>
    `).join('');

    addClickHandlers(historyList);
}

async function loadRecentActivity(uid) {
    if (!isBrowser()) return;
    try {
        const historyRef = collection(db, 'userData', uid, 'activity');
        const q = query(historyRef, orderBy('lastVisited', 'desc'), limit(5));
        const snapshot = await getDocs(q);

        if (!recentList) return;

        if (snapshot.empty) {
            recentList.innerHTML = '<div class="empty">📭 No recent activity detected.</div>';
            return;
        }

        recentList.innerHTML = snapshot.docs.map(docSnap => {
            const item = docSnap.data();
            return `
                <div class="list-item" data-url="${escapeHtml(item.url || '')}">
                    <span class="list-icon">${getIcon(item.type)}</span>
                    <div class="list-info">
                        <div class="list-title">${escapeHtml(item.title || item.domain)}</div>
                        <div class="list-meta">${escapeHtml(item.domain)}</div>
                    </div>
                    <span class="list-time">${formatTime(item.lastVisited?.toDate?.())}</span>
                </div>
            `;
        }).join('');

        addClickHandlers(recentList);
    } catch (e) {
        console.error('Load recent activity error:', e);
        if (e.code === 'permission-denied') {
            console.error('PERMISSION DENIED: Verify project settings and run "firebase deploy --only firestore:rules"');
        }
    }
}

async function captureNow() {
    const btn = document.getElementById('capture-btn');
    if (btn) { btn.disabled = true; btn.textContent = '📸 Capturing...'; }

    chrome.runtime.sendMessage({ type: 'CAPTURE_NOW' }, (response) => {
        setTimeout(() => {
            if (currentUser) loadRecentActivity(currentUser.uid);
            if (btn) { btn.disabled = false; btn.textContent = '📸 Capture Now'; }
            showToast('Activity captured!', 'success');
        }, 800);
    });
}

async function syncData() {
    const btn = document.getElementById('sync-btn');
    if (btn) { btn.disabled = true; btn.textContent = '🔄 Refreshing...'; }
    try {
        if (currentUser) {
            await loadRecentActivity(currentUser.uid);
            // Firestore snaphots will handle the rest
        }
        showToast('Data synced!', 'success');
    } finally {
        if (btn) { btn.disabled = false; btn.textContent = '🔄 Refresh'; }
    }
}

async function saveProfile() {
    const name = document.getElementById('edit-name')?.value?.trim();
    if (!name || !currentUser) return;

    const btn = document.getElementById('save-btn');
    if (btn) { btn.disabled = true; btn.textContent = 'Saving...'; }

    try {
        await updateDoc(doc(db, 'users', currentUser.uid), {
            name,
            lastLogin: serverTimestamp()
        });
        showToast('Profile updated!', 'success');
    } catch (e) {
        showToast('Failed to save profile.', 'error');
    } finally {
        if (btn) { btn.disabled = false; btn.textContent = 'Save Changes'; }
    }
}

function navigateTo(page) {
    if (!page) return;

    document.querySelectorAll('.nav-item').forEach(item => {
        item.classList.toggle('active', item.dataset.page === page);
    });

    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    const targetPage = document.getElementById(`page-${page}`);
    if (targetPage) {
        targetPage.classList.add('active');
        // Scroll to top
        targetPage.scrollTop = 0;
    }
}

function getIcon(type) {
    const icons = {
        'code': '💻', 'document': '📄', 'video': '🎬',
        'email': '📧', 'social': '💬', 'news': '📰',
        'shopping': '🛒', 'tab': '🌐'
    };
    return icons[type] || '🌐';
}

function formatTime(date) {
    if (!date) return '';
    const diff = Date.now() - date;
    if (diff < 60000) return 'Now';
    if (diff < 3600000) return `${Math.floor(diff / 60000)}m`;
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}h`;
    return date.toLocaleDateString([], { month: 'short', day: 'numeric' });
}

function formatDuration(ms) {
    if (!ms || ms < 1000) return '0s';
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);

    if (hours > 0) return `${hours}h ${minutes % 60}m`;
    if (minutes > 0) return `${minutes}m ${seconds % 60}s`;
    return `${seconds}s`;
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function setText(id, text) { const el = document.getElementById(id); if (el) el.textContent = text; }
function setSrc(id, src) { const el = document.getElementById(id); if (el) el.src = src; }
function setValue(id, value) { const el = document.getElementById(id); if (el) el.value = value; }

function addClickHandlers(container) {
    container.querySelectorAll('.list-item').forEach(item => {
        item.onclick = (e) => {
            const url = item.dataset.url;
            if (url) chrome.tabs.create({ url });
        };
    });
}

function showToast(message, type = 'info') {
    document.querySelectorAll('.toast').forEach(t => t.remove());
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(() => toast.classList.add('show'), 10);
    setTimeout(() => {
        toast.classList.remove('show');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

console.log('RESET AI Dashboard initialized');

