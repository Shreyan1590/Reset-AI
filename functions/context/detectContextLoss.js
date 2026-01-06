/**
 * Context Loss Detection Logic
 * Analyzes user activity patterns to detect potential context loss
 */

/**
 * Detect context loss based on activity data
 * @param {Object} activityData - User activity data
 * @param {Object} settings - User settings including sensitivity
 * @returns {Object} Detection result with probability and recommendations
 */
async function detectContextLoss(activityData, settings = {}) {
    const sensitivity = settings.aiSensitivity || 5;
    const normalizedSensitivity = sensitivity / 10;

    let probability = 0;
    const factors = [];

    // Factor 1: Tab switching frequency
    if (activityData.recentTabSwitches) {
        const switchCount = activityData.recentTabSwitches.length;
        if (switchCount > 5) {
            const impact = Math.min(0.3, (switchCount - 5) * 0.05) * normalizedSensitivity;
            probability += impact;
            factors.push({
                name: 'High tab switching',
                impact,
                description: `${switchCount} tab switches in the last minute`,
            });
        }
    }

    // Factor 2: Idle duration
    if (activityData.idleDuration) {
        const idleMinutes = activityData.idleDuration / 60000;
        if (idleMinutes > 2) {
            const impact = Math.min(0.4, idleMinutes * 0.1) * normalizedSensitivity;
            probability += impact;
            factors.push({
                name: 'Extended idle time',
                impact,
                description: `${Math.round(idleMinutes)} minutes of inactivity`,
            });
        }
    }

    // Factor 3: Domain change
    if (activityData.domainChanged) {
        const impact = 0.2 * normalizedSensitivity;
        probability += impact;
        factors.push({
            name: 'Domain switch',
            impact,
            description: 'Switched to a different website',
        });
    }

    // Factor 4: Re-reading behavior (scroll back up)
    if (activityData.scrollPatterns) {
        const patterns = activityData.scrollPatterns;
        let backScrolls = 0;

        for (let i = 1; i < patterns.length; i++) {
            if (patterns[i].position < patterns[i - 1].position) {
                backScrolls++;
            }
        }

        if (backScrolls > 2) {
            const impact = Math.min(0.25, backScrolls * 0.05) * normalizedSensitivity;
            probability += impact;
            factors.push({
                name: 'Re-reading behavior',
                impact,
                description: 'Scrolling back to re-read content',
            });
        }
    }

    // Factor 5: Time since last interaction
    if (activityData.timeSinceLastInteraction) {
        const seconds = activityData.timeSinceLastInteraction / 1000;
        if (seconds > 30) {
            const impact = Math.min(0.2, (seconds - 30) * 0.005) * normalizedSensitivity;
            probability += impact;
            factors.push({
                name: 'Hesitation detected',
                impact,
                description: `${Math.round(seconds)} seconds without interaction`,
            });
        }
    }

    // Cap probability at 1.0
    probability = Math.min(1.0, probability);

    // Determine if context loss is detected
    const threshold = 0.5;
    const contextLossDetected = probability >= threshold;

    return {
        detected: contextLossDetected,
        probability: Math.round(probability * 100) / 100,
        confidence: probability >= 0.7 ? 'high' : probability >= 0.4 ? 'medium' : 'low',
        factors,
        recommendation: contextLossDetected
            ? 'Consider showing context recovery prompt'
            : 'No action needed',
    };
}

module.exports = {
    detectContextLoss,
};
