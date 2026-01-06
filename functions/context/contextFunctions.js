/**
 * Enhanced Context Management Functions with Deduplication
 */

const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');

/**
 * Normalize URL for deduplication
 */
function normalizeUrl(url) {
    if (!url) return '';
    try {
        const uri = new URL(url);
        let normalized = `${uri.protocol}//${uri.host}${uri.pathname}`;
        if (normalized.endsWith('/')) {
            normalized = normalized.slice(0, -1);
        }
        return normalized.toLowerCase();
    } catch (e) {
        return url.toLowerCase();
    }
}

/**
 * Capture context with deduplication
 */
async function captureContext(db, { userId, sessionId, type, data }) {
    const normalizedUrl = normalizeUrl(data.url);
    let contextId;
    let isUpdate = false;

    // Check for existing context with same URL
    if (normalizedUrl) {
        const existing = await db.collection('contexts')
            .where('userId', '==', userId)
            .where('data.normalizedUrl', '==', normalizedUrl)
            .where('isArchived', '!=', true)
            .limit(1)
            .get();

        if (!existing.empty) {
            // Update existing context
            const existingDoc = existing.docs[0];
            await existingDoc.ref.update({
                lastVisited: admin.firestore.FieldValue.serverTimestamp(),
                visitCount: admin.firestore.FieldValue.increment(1),
                'data.scrollPosition': data.scrollPosition || 0,
                'data.selectedText': data.selectedText || '',
                isRecovered: false,
            });

            return { contextId: existingDoc.id, isUpdate: true };
        }
    }

    // Create new context
    contextId = uuidv4();

    const contextDoc = {
        userId,
        sessionId: sessionId || null,
        capturedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastVisited: admin.firestore.FieldValue.serverTimestamp(),
        type,
        data: {
            url: data.url || '',
            normalizedUrl,
            title: data.title || 'Untitled',
            scrollPosition: data.scrollPosition || 0,
            selectedText: data.selectedText || '',
            pageMetadata: data.pageMetadata || {},
            formData: data.formData || {},
        },
        summary: '',
        keyPoints: [],
        nextSteps: [],
        isRecovered: false,
        isArchived: false,
        visitCount: 1,
        totalDuration: 0,
    };

    await db.collection('contexts').doc(contextId).set(contextDoc);

    return { contextId, isUpdate: false };
}

/**
 * Get unique contexts (deduplicated by URL)
 */
async function getUniqueContexts(db, userId, limit = 20) {
    const snapshot = await db.collection('contexts')
        .where('userId', '==', userId)
        .where('isArchived', '!=', true)
        .orderBy('isArchived')
        .orderBy('lastVisited', 'desc')
        .limit(limit * 3) // Get more to allow for deduplication
        .get();

    const uniqueMap = new Map();

    snapshot.docs.forEach(doc => {
        const data = doc.data();
        const key = data.data?.normalizedUrl || doc.id;

        if (!uniqueMap.has(key)) {
            uniqueMap.set(key, {
                id: doc.id,
                ...data,
                capturedAt: data.capturedAt?.toMillis() || Date.now(),
                lastVisited: data.lastVisited?.toMillis() || Date.now(),
            });
        }
    });

    // Sort by lastVisited and limit
    return Array.from(uniqueMap.values())
        .sort((a, b) => b.lastVisited - a.lastVisited)
        .slice(0, limit);
}

/**
 * Get all contexts (with full history)
 */
async function getContexts(db, userId, limit = 50) {
    const snapshot = await db.collection('contexts')
        .where('userId', '==', userId)
        .orderBy('capturedAt', 'desc')
        .limit(limit)
        .get();

    return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        capturedAt: doc.data().capturedAt?.toMillis() || Date.now(),
        lastVisited: doc.data().lastVisited?.toMillis() || Date.now(),
    }));
}

/**
 * Mark context as recovered
 */
async function markRecovered(db, contextId) {
    await db.collection('contexts').doc(contextId).update({
        isRecovered: true,
        recoveredAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

/**
 * Archive context (hide from main view)
 */
async function archiveContext(db, contextId) {
    await db.collection('contexts').doc(contextId).update({
        isArchived: true,
        archivedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
}

module.exports = {
    captureContext,
    getContexts,
    getUniqueContexts,
    markRecovered,
    archiveContext,
    normalizeUrl,
};
