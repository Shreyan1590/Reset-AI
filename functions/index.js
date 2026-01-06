/**
 * RESET AI v2 - Firebase Cloud Functions
 * Project: reset-ai-gdg
 * Full backend with Firestore, Auth, and AI integration
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const cors = require('cors')({ origin: true });
const { v4: uuidv4 } = require('uuid');

// Initialize Firebase Admin
admin.initializeApp();
const db = admin.firestore();

// Import function modules
const { captureContext, getContexts, getUniqueContexts, markRecovered, archiveContext } = require('./context/contextFunctions');
const { detectContextLoss } = require('./context/detectContextLoss');
const { generateRecovery, generateDeepCognitiveResume } = require('./context/generateRecovery');
const { getSessionStats, startSession, endSession } = require('./analytics/sessionStats');
const { calculateNeuroFlowScore, predictDistraction } = require('./analytics/neuroFlow');

// ============================================
// AUTHENTICATION MIDDLEWARE
// ============================================
async function verifyAuth(req) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return null;
    }

    try {
        const token = authHeader.split('Bearer ')[1];
        const decoded = await admin.auth().verifyIdToken(token);
        return decoded.uid;
    } catch (e) {
        return null;
    }
}

// ============================================
// CONTEXT MANAGEMENT ENDPOINTS
// ============================================

/**
 * Capture context with deduplication - NO DUPLICATE URLs
 * POST /captureContext
 */
exports.captureContext = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).json({ error: 'Method not allowed' });
        }

        try {
            const userId = await verifyAuth(req) || req.body.userId;
            const { sessionId, type, data, url, normalizedUrl, title, timestampStart, timestampEnd } = req.body;

            if (!userId || !data) {
                return res.status(400).json({ error: 'Missing required fields' });
            }

            // Check for existing context with same URL - UPDATE instead of CREATE
            const urlToCheck = normalizedUrl || data.normalizedUrl;
            let isUpdate = false;
            let contextId;

            if (urlToCheck) {
                const existing = await db.collection('contexts')
                    .where('userId', '==', userId)
                    .where('data.normalizedUrl', '==', urlToCheck)
                    .where('isArchived', '!=', true)
                    .limit(1)
                    .get();

                if (!existing.empty) {
                    // UPDATE existing session - NO DUPLICATE
                    const existingDoc = existing.docs[0];
                    await existingDoc.ref.update({
                        lastVisited: admin.firestore.FieldValue.serverTimestamp(),
                        timestampEnd: admin.firestore.FieldValue.serverTimestamp(),
                        visitCount: admin.firestore.FieldValue.increment(1),
                        'data.scrollPosition': data.scrollPosition || 0,
                        'data.selectedText': data.selectedText || '',
                        isRecovered: false,
                    });

                    return res.json({ contextId: existingDoc.id, isUpdate: true });
                }
            }

            // Create new context only if no existing
            contextId = uuidv4();

            await db.collection('contexts').doc(contextId).set({
                userId,
                sessionId: sessionId || null,
                capturedAt: admin.firestore.FieldValue.serverTimestamp(),
                lastVisited: admin.firestore.FieldValue.serverTimestamp(),
                timestampStart: timestampStart || admin.firestore.FieldValue.serverTimestamp(),
                timestampEnd: timestampEnd || admin.firestore.FieldValue.serverTimestamp(),
                type: type || 'tab',
                data: {
                    url: url || data.url || '',
                    normalizedUrl: urlToCheck || '',
                    title: title || data.title || 'Untitled',
                    scrollPosition: data.scrollPosition || 0,
                    selectedText: data.selectedText || '',
                    pageMetadata: data.pageMetadata || {},
                },
                summary: '',
                keyPoints: [],
                nextSteps: [],
                isRecovered: false,
                isArchived: false,
                visitCount: 1,
                status: 'active',
            });

            res.status(201).json({ contextId, isUpdate: false });
        } catch (error) {
            console.error('Error capturing context:', error);
            res.status(500).json({ error: 'Failed to capture context' });
        }
    });
});

/**
 * Update existing session
 * POST /updateSession
 */
exports.updateSession = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).json({ error: 'Method not allowed' });
        }

        try {
            const userId = await verifyAuth(req) || req.body.userId;
            const { sessionId, normalizedUrl, data, timestampEnd } = req.body;

            if (!userId) {
                return res.status(400).json({ error: 'userId required' });
            }

            // Find by normalized URL
            const existing = await db.collection('contexts')
                .where('userId', '==', userId)
                .where('data.normalizedUrl', '==', normalizedUrl)
                .limit(1)
                .get();

            if (!existing.empty) {
                await existing.docs[0].ref.update({
                    lastVisited: admin.firestore.FieldValue.serverTimestamp(),
                    timestampEnd: timestampEnd || admin.firestore.FieldValue.serverTimestamp(),
                    visitCount: admin.firestore.FieldValue.increment(1),
                    'data.scrollPosition': data?.scrollPosition || 0,
                });

                return res.json({ success: true, contextId: existing.docs[0].id });
            }

            res.status(404).json({ error: 'Session not found' });
        } catch (error) {
            console.error('Error updating session:', error);
            res.status(500).json({ error: 'Failed to update session' });
        }
    });
});

/**
 * Get unique contexts (deduplicated) - ONLY UNIQUE ACTIVE
 * GET /getUniqueContexts
 */
exports.getUniqueContexts = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        if (req.method !== 'GET') {
            return res.status(405).json({ error: 'Method not allowed' });
        }

        try {
            const userId = req.query.userId;
            const limit = parseInt(req.query.limit) || 20;

            if (!userId) {
                return res.status(400).json({ error: 'userId is required' });
            }

            const snapshot = await db.collection('contexts')
                .where('userId', '==', userId)
                .where('isArchived', '!=', true)
                .orderBy('isArchived')
                .orderBy('lastVisited', 'desc')
                .limit(limit)
                .get();

            const contexts = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data(),
                capturedAt: doc.data().capturedAt?.toMillis(),
                lastVisited: doc.data().lastVisited?.toMillis(),
            }));

            res.json({ contexts, count: contexts.length });
        } catch (error) {
            console.error('Error getting contexts:', error);
            res.status(500).json({ error: 'Failed to get contexts' });
        }
    });
});

/**
 * Mark context as recovered
 * POST /markRecovered
 */
exports.markRecovered = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).json({ error: 'Method not allowed' });
        }

        try {
            const { contextId, userId } = req.body;

            if (!contextId) {
                return res.status(400).json({ error: 'contextId is required' });
            }

            await db.collection('contexts').doc(contextId).update({
                isRecovered: true,
                recoveredAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'recovered',
            });

            // Update user stats
            if (userId) {
                await db.collection('users').doc(userId).update({
                    'stats.totalRecoveries': admin.firestore.FieldValue.increment(1),
                });
            }

            res.json({ success: true });
        } catch (error) {
            console.error('Error marking recovered:', error);
            res.status(500).json({ error: 'Failed to mark as recovered' });
        }
    });
});

/**
 * Archive context
 * POST /archiveContext
 */
exports.archiveContext = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).json({ error: 'Method not allowed' });
        }

        try {
            const { contextId } = req.body;

            if (!contextId) {
                return res.status(400).json({ error: 'contextId is required' });
            }

            await db.collection('contexts').doc(contextId).update({
                isArchived: true,
                archivedAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'archived',
            });

            res.json({ success: true });
        } catch (error) {
            console.error('Error archiving:', error);
            res.status(500).json({ error: 'Failed to archive' });
        }
    });
});

// ============================================
// SESSION MANAGEMENT
// ============================================

/**
 * Start new session
 * POST /startSession
 */
exports.startSession = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).json({ error: 'Method not allowed' });
        }

        try {
            const userId = await verifyAuth(req) || req.body.userId;
            if (!userId) return res.status(400).json({ error: 'userId required' });

            const sessionId = uuidv4();

            await db.collection('sessions').doc(sessionId).set({
                userId,
                timestampStart: admin.firestore.FieldValue.serverTimestamp(),
                status: 'active',
                interruptions: 0,
                contextLossEvents: 0,
                timeRecovered: 0,
            });

            res.status(201).json({ sessionId });
        } catch (error) {
            console.error('Error starting session:', error);
            res.status(500).json({ error: 'Failed to start session' });
        }
    });
});

/**
 * End session
 * POST /endSession
 */
exports.endSession = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).json({ error: 'Method not allowed' });
        }

        try {
            const { sessionId } = req.body;
            if (!sessionId) return res.status(400).json({ error: 'sessionId required' });

            await db.collection('sessions').doc(sessionId).update({
                timestampEnd: admin.firestore.FieldValue.serverTimestamp(),
                status: 'completed',
            });

            res.json({ success: true });
        } catch (error) {
            console.error('Error ending session:', error);
            res.status(500).json({ error: 'Failed to end session' });
        }
    });
});

// ============================================
// NEURO-FLOW & ANALYTICS
// ============================================

/**
 * Get Neuro-Flow Score
 * GET /getNeuroFlowScore
 */
exports.getNeuroFlowScore = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        if (req.method !== 'GET') {
            return res.status(405).json({ error: 'Method not allowed' });
        }

        try {
            const userId = req.query.userId;
            if (!userId) return res.status(400).json({ error: 'userId required' });

            const score = await calculateNeuroFlowScore(db, userId);
            res.json(score);
        } catch (error) {
            console.error('Error calculating score:', error);
            res.status(500).json({ error: 'Failed to calculate' });
        }
    });
});

/**
 * Deep cognitive resume
 * POST /deepCognitiveResume
 */
exports.deepCognitiveResume = functions.https.onRequest((req, res) => {
    cors(req, res, async () => {
        if (req.method !== 'POST') {
            return res.status(405).json({ error: 'Method not allowed' });
        }

        try {
            const { userId, absenceDuration } = req.body;
            if (!userId) return res.status(400).json({ error: 'userId required' });

            const snapshot = await db.collection('contexts')
                .where('userId', '==', userId)
                .where('isArchived', '!=', true)
                .orderBy('isArchived')
                .orderBy('lastVisited', 'desc')
                .limit(5)
                .get();

            const contexts = snapshot.docs.map(d => d.data());
            const resume = await generateDeepCognitiveResume(contexts, absenceDuration);

            res.json(resume);
        } catch (error) {
            console.error('Error generating resume:', error);
            res.status(500).json({ error: 'Failed to generate resume' });
        }
    });
});

// ============================================
// FIRESTORE TRIGGERS
// ============================================

/**
 * On new context - generate summary
 */
exports.onContextCreated = functions.firestore
    .document('contexts/{contextId}')
    .onCreate(async (snap, context) => {
        const data = snap.data();

        try {
            const recovery = await generateRecovery(data);
            await snap.ref.update({
                summary: recovery.summary,
                keyPoints: recovery.keyPoints,
                nextSteps: recovery.nextSteps,
            });
        } catch (error) {
            console.error('Error in onContextCreated:', error);
        }
    });

/**
 * On context recovered - update stats
 */
exports.onContextRecovered = functions.firestore
    .document('contexts/{contextId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (!before.isRecovered && after.isRecovered) {
            const userId = after.userId;

            await db.collection('users').doc(userId).update({
                'stats.totalRecoveries': admin.firestore.FieldValue.increment(1),
                'stats.lastRecovery': admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    });

/**
 * On session close - archive to history
 */
exports.onSessionClosed = functions.firestore
    .document('sessions/{sessionId}')
    .onUpdate(async (change, context) => {
        const before = change.before.data();
        const after = change.after.data();

        if (before.status === 'active' && after.status === 'completed') {
            const userId = after.userId;

            // Add to user's history (deduplicated)
            await db.collection('users').doc(userId).collection('history').add({
                sessionId: context.params.sessionId,
                ...after,
                archivedAt: admin.firestore.FieldValue.serverTimestamp(),
            });
        }
    });

console.log('RESET AI Cloud Functions loaded - Project: reset-ai-gdg');
