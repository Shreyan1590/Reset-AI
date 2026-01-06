/**
 * Neuro-Flow Score & Distraction Prediction
 */

const admin = require('firebase-admin');

/**
 * Calculate Neuro-Flow Score for a user
 */
async function calculateNeuroFlowScore(db, userId) {
    const now = new Date();
    const todayStart = new Date(now.setHours(0, 0, 0, 0));

    // Get today's contexts
    const contextSnapshot = await db.collection('contexts')
        .where('userId', '==', userId)
        .where('capturedAt', '>=', todayStart)
        .get();

    const contexts = contextSnapshot.docs.map(d => d.data());

    if (contexts.length === 0) {
        return {
            score: 75,
            level: 'Good Flow',
            distractions: 0,
            focusStreak: 0,
            suggestions: ['Start working to see your focus metrics'],
        };
    }

    // Calculate metrics
    const uniqueUrls = new Set(contexts.map(c => c.data?.normalizedUrl || c.data?.url)).size;
    const switchCount = contexts.length;
    const recoveredCount = contexts.filter(c => c.isRecovered).length;

    // Base score calculation
    let score = 100;

    // Penalty for excessive switching
    if (switchCount > 20) {
        score -= (switchCount - 20) * 1.5;
    }

    // Penalty for too many unique domains
    if (uniqueUrls > 10) {
        score -= (uniqueUrls - 10) * 2;
    }

    // Bonus for recoveries
    score += recoveredCount * 3;

    // Clamp score
    score = Math.min(100, Math.max(0, score));

    // Determine level
    let level;
    if (score >= 85) level = 'Deep Focus';
    else if (score >= 70) level = 'Good Flow';
    else if (score >= 50) level = 'Moderate';
    else if (score >= 30) level = 'Scattered';
    else level = 'Distracted';

    // Calculate distractions
    const distractions = Math.max(0, switchCount - 10);

    // Generate suggestions
    const suggestions = [];
    if (distractions > 5) {
        suggestions.push('Try closing unnecessary tabs to reduce distractions');
    }
    if (score < 50) {
        suggestions.push('Consider using focus mode for deep work sessions');
    }
    if (uniqueUrls > 8) {
        suggestions.push('You have many active contexts. Consider archiving some.');
    }
    if (suggestions.length === 0) {
        suggestions.push('Great focus today! Keep up the momentum.');
    }

    // Calculate focus streak (days with score >= 70)
    const focusStreak = await calculateFocusStreak(db, userId);

    return {
        score: Math.round(score),
        level,
        distractions,
        focusStreak,
        suggestions,
        uniqueWorkspaces: uniqueUrls,
        totalSwitches: switchCount,
        recoveries: recoveredCount,
    };
}

/**
 * Calculate consecutive days with good focus
 */
async function calculateFocusStreak(db, userId) {
    // Simplified - check last 7 days
    const now = new Date();
    let streak = 0;

    for (let i = 0; i < 7; i++) {
        const dayStart = new Date(now);
        dayStart.setDate(dayStart.getDate() - i);
        dayStart.setHours(0, 0, 0, 0);

        const dayEnd = new Date(dayStart);
        dayEnd.setHours(23, 59, 59, 999);

        const snapshot = await db.collection('contexts')
            .where('userId', '==', userId)
            .where('capturedAt', '>=', dayStart)
            .where('capturedAt', '<=', dayEnd)
            .get();

        if (snapshot.empty) break;

        const contexts = snapshot.docs.map(d => d.data());
        const switchCount = contexts.length;
        const uniqueUrls = new Set(contexts.map(c => c.data?.normalizedUrl)).size;

        // Simple focus check: not too many switches
        if (switchCount <= 30 && uniqueUrls <= 15) {
            streak++;
        } else {
            break;
        }
    }

    return streak;
}

/**
 * Predict distraction based on activity patterns
 */
async function predictDistraction(activityData, settings = {}) {
    const sensitivity = settings.aiSensitivity || 5;
    const normalizedSensitivity = sensitivity / 10;

    let probability = 0;
    const triggers = [];

    // Factor 1: Tab switching frequency
    if (activityData.recentTabSwitches) {
        const switchCount = activityData.recentTabSwitches.length;
        if (switchCount > 5) {
            const impact = Math.min(0.3, (switchCount - 5) * 0.05) * normalizedSensitivity;
            probability += impact;
            triggers.push('Rapid tab switching');
        }
    }

    // Factor 2: Idle duration
    if (activityData.idleDuration) {
        const idleMinutes = activityData.idleDuration / 60000;
        if (idleMinutes > 2) {
            const impact = Math.min(0.3, idleMinutes * 0.08) * normalizedSensitivity;
            probability += impact;
            triggers.push('Extended idle time');
        }
    }

    // Factor 3: Unique domains visited
    if (activityData.uniqueDomains > 5) {
        const impact = Math.min(0.2, (activityData.uniqueDomains - 5) * 0.04) * normalizedSensitivity;
        probability += impact;
        triggers.push('Many different sites');
    }

    // Factor 4: Time of day (afternoon slump)
    const hour = new Date().getHours();
    if (hour >= 14 && hour <= 16) {
        probability += 0.1 * normalizedSensitivity;
        triggers.push('Afternoon productivity dip');
    }

    // Factor 5: Long session without break
    if (activityData.sessionDuration && activityData.sessionDuration > 7200000) {
        probability += 0.15 * normalizedSensitivity;
        triggers.push('Long session without break');
    }

    // Factor 6: Re-reading behavior
    if (activityData.rereadCount && activityData.rereadCount > 3) {
        probability += 0.1 * normalizedSensitivity;
        triggers.push('Confusion detected');
    }

    // Clamp probability
    probability = Math.min(1.0, probability);

    // Generate recommendation
    let recommendation;
    if (probability > 0.7) {
        recommendation = 'High distraction risk. Consider taking a short break or entering focus mode.';
    } else if (probability > 0.4) {
        recommendation = 'Moderate distraction risk. Stay aware of your focus.';
    } else {
        recommendation = 'Focus looks good. Keep up the momentum!';
    }

    return {
        probability: Math.round(probability * 100) / 100,
        riskLevel: probability > 0.7 ? 'High' : probability > 0.4 ? 'Medium' : 'Low',
        triggers,
        recommendation,
        timestamp: Date.now(),
    };
}

module.exports = {
    calculateNeuroFlowScore,
    predictDistraction,
};
