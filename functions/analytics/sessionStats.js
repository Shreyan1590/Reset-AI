/**
 * Session Statistics Functions
 */

const { v4: uuidv4 } = require('uuid');
const admin = require('firebase-admin');

/**
 * Start a new session
 */
async function startSession(db, userId) {
    const sessionId = uuidv4();

    await db.collection('sessions').doc(sessionId).set({
        userId,
        startTime: admin.firestore.FieldValue.serverTimestamp(),
        status: 'active',
        interruptions: 0,
        contextLossEvents: 0,
        timeRecovered: 0,
    });

    return sessionId;
}

/**
 * End a session
 */
async function endSession(db, sessionId) {
    await db.collection('sessions').doc(sessionId).update({
        endTime: admin.firestore.FieldValue.serverTimestamp(),
        status: 'completed',
    });
}

/**
 * Get session statistics for a user
 */
async function getSessionStats(db, userId) {
    const snapshot = await db.collection('sessions')
        .where('userId', '==', userId)
        .orderBy('startTime', 'desc')
        .limit(30)
        .get();

    if (snapshot.empty) {
        return {
            totalSessions: 0,
            totalInterruptions: 0,
            totalTimeRecovered: 0,
            totalContextLossEvents: 0,
            averageSessionDuration: 0,
            sessions: [],
        };
    }

    let totalInterruptions = 0;
    let totalTimeRecovered = 0;
    let totalContextLossEvents = 0;
    let totalDuration = 0;
    let completedSessions = 0;

    const sessions = snapshot.docs.map(doc => {
        const data = doc.data();

        totalInterruptions += data.interruptions || 0;
        totalTimeRecovered += data.timeRecovered || 0;
        totalContextLossEvents += data.contextLossEvents || 0;

        if (data.startTime && data.endTime) {
            const duration = data.endTime.toMillis() - data.startTime.toMillis();
            totalDuration += duration;
            completedSessions++;
        }

        return {
            id: doc.id,
            ...data,
            startTime: data.startTime?.toMillis() || Date.now(),
            endTime: data.endTime?.toMillis() || null,
        };
    });

    return {
        totalSessions: snapshot.size,
        totalInterruptions,
        totalTimeRecovered,
        totalContextLossEvents,
        averageSessionDuration: completedSessions > 0
            ? Math.round(totalDuration / completedSessions / 60000)
            : 0,
        sessions,
    };
}

/**
 * Update session with interruption
 */
async function recordInterruption(db, sessionId) {
    await db.collection('sessions').doc(sessionId).update({
        interruptions: admin.firestore.FieldValue.increment(1),
    });
}

/**
 * Update session with context loss event
 */
async function recordContextLoss(db, sessionId) {
    await db.collection('sessions').doc(sessionId).update({
        contextLossEvents: admin.firestore.FieldValue.increment(1),
    });
}

/**
 * Update session with recovered time
 */
async function recordTimeRecovered(db, sessionId, seconds) {
    await db.collection('sessions').doc(sessionId).update({
        timeRecovered: admin.firestore.FieldValue.increment(seconds),
    });
}

module.exports = {
    startSession,
    endSession,
    getSessionStats,
    recordInterruption,
    recordContextLoss,
    recordTimeRecovered,
};
