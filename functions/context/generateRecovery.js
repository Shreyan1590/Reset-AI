/**
 * AI Recovery Prompt Generation with Deep Cognitive Resume
 */

/**
 * Generate recovery prompt for a context
 */
async function generateRecovery(contextData) {
    try {
        const { type, data } = contextData;
        const url = data?.url || '';
        const title = data?.title || 'Untitled';
        const selectedText = data?.selectedText || '';
        const metadata = data?.pageMetadata || {};

        const typeSummaries = {
            'code': generateCodeSummary(title, url, metadata),
            'document': generateDocumentSummary(title, url, metadata),
            'note': generateNoteSummary(title, url, metadata),
            'video': generateVideoSummary(title, url, metadata),
            'email': generateEmailSummary(title, url, metadata),
            'tab': generateTabSummary(title, url, metadata),
        };

        const result = typeSummaries[type] || typeSummaries['tab'];

        if (selectedText) {
            result.keyPoints.push(`Selected text: "${selectedText.substring(0, 100)}..."`);
        }

        return result;
    } catch (error) {
        console.error('Error generating recovery:', error);
        return {
            summary: `You were viewing: ${contextData.data?.title || 'a page'}`,
            keyPoints: ['Continue where you left off'],
            nextSteps: ['Review your previous work'],
        };
    }
}

/**
 * Generate deep cognitive resume for extended absence
 */
async function generateDeepCognitiveResume(contexts, absenceDuration = 0) {
    if (!contexts || contexts.length === 0) {
        return {
            whatYouWereDoing: 'No recent activity found',
            whyYouWereDoingIt: 'Start a new task',
            nextLogicalStep: 'Begin your work session',
            contexts: [],
        };
    }

    const primaryContext = contexts[0];
    const hours = Math.floor(absenceDuration / 3600000);
    const absenceLabel = hours > 0 ? `${hours} hours` : `${Math.floor(absenceDuration / 60000)} minutes`;

    // Analyze the workflow pattern
    const domains = contexts.map(c => {
        try {
            return new URL(c.data?.url || '').hostname.replace('www.', '');
        } catch {
            return 'unknown';
        }
    });
    const uniqueDomains = [...new Set(domains)];

    // Determine purpose based on context types
    let purpose = 'Based on your workflow pattern';
    const contextTypes = contexts.map(c => c.type);

    if (contextTypes.includes('code')) {
        purpose = 'You were likely debugging or implementing a feature';
    } else if (contextTypes.includes('document')) {
        purpose = 'You were working on documentation or writing';
    } else if (contextTypes.filter(t => t === 'tab').length > 3) {
        purpose = 'You were researching across multiple sources';
    }

    return {
        whatYouWereDoing: primaryContext.summary || primaryContext.data?.title || 'Working on multiple tasks',
        whyYouWereDoingIt: purpose,
        nextLogicalStep: primaryContext.nextSteps?.[0] || 'Continue where you left off',
        absenceDuration: absenceLabel,
        workspaces: contexts.slice(0, 5).map(c => ({
            title: c.data?.title,
            type: c.type,
            url: c.data?.url,
            visitCount: c.visitCount || 1,
        })),
        insights: {
            uniqueDomains: uniqueDomains.length,
            totalWorkspaces: contexts.length,
            recoveredCount: contexts.filter(c => c.isRecovered).length,
        },
        confidence: contexts.length > 3 ? 'high' : 'medium',
    };
}

// Type-specific summary generators
function generateCodeSummary(title, url, metadata) {
    const domain = getDomain(url);
    let summary = `Working on code at ${domain}`;
    const keyPoints = [];
    const nextSteps = [];

    if (url.includes('github.com')) {
        const parts = url.split('/');
        const repoIndex = parts.indexOf('github.com') + 1;
        if (parts[repoIndex] && parts[repoIndex + 1]) {
            summary = `Working on ${parts[repoIndex]}/${parts[repoIndex + 1]}`;
            keyPoints.push(`Repository: ${parts[repoIndex + 1]}`);
        }

        if (url.includes('/pull/')) {
            keyPoints.push('Reviewing a pull request');
            nextSteps.push('Complete code review');
        } else if (url.includes('/issues/')) {
            keyPoints.push('Working on an issue');
            nextSteps.push('Continue issue resolution');
        } else if (url.includes('/blob/')) {
            keyPoints.push('Viewing source code');
            nextSteps.push('Continue code review');
        }
    } else if (url.includes('stackoverflow.com')) {
        summary = 'Researching a coding solution';
        keyPoints.push('Looking up Stack Overflow');
        nextSteps.push('Apply the solution to your code');
    }

    if (metadata.headings?.length > 0) {
        keyPoints.push(`Topic: ${metadata.headings[0]}`);
    }

    if (keyPoints.length === 0) keyPoints.push(`Page: ${title}`);
    if (nextSteps.length === 0) nextSteps.push('Continue your coding task');

    return { summary, keyPoints, nextSteps };
}

function generateDocumentSummary(title, url, metadata) {
    let summary = `Editing document: ${title}`;
    const keyPoints = [`Document: ${title}`];
    const nextSteps = ['Continue editing your document'];

    if (url.includes('docs.google.com')) {
        summary = `Working in Google Docs: ${title}`;
        if (url.includes('/spreadsheets/')) {
            keyPoints.push('Google Sheet');
            nextSteps[0] = 'Continue your spreadsheet work';
        } else if (url.includes('/presentation/')) {
            keyPoints.push('Google Slides');
            nextSteps[0] = 'Continue your presentation';
        }
    } else if (url.includes('notion.so')) {
        summary = `Working in Notion: ${title}`;
        keyPoints.push('Notion page');
    }

    return { summary, keyPoints, nextSteps };
}

function generateNoteSummary(title, url, metadata) {
    return {
        summary: `Taking notes: ${title}`,
        keyPoints: [`Note: ${title}`],
        nextSteps: ['Continue adding to your notes'],
    };
}

function generateVideoSummary(title, url, metadata) {
    return {
        summary: `Watching video: ${title}`,
        keyPoints: [`Video: ${title}`],
        nextSteps: ['Continue watching or take notes'],
    };
}

function generateEmailSummary(title, url, metadata) {
    return {
        summary: `Email: ${title}`,
        keyPoints: ['Managing email'],
        nextSteps: ['Respond or follow up on email'],
    };
}

function generateTabSummary(title, url, metadata) {
    const domain = getDomain(url);
    const summary = `Browsing: ${title}`;
    const keyPoints = [`Site: ${domain}`];
    const nextSteps = ['Continue reading'];

    if (metadata.headings?.length > 0) {
        keyPoints.push(`Topic: ${metadata.headings[0]}`);
    }

    return { summary, keyPoints, nextSteps };
}

function getDomain(url) {
    try {
        return new URL(url).hostname.replace('www.', '');
    } catch {
        return 'unknown';
    }
}

module.exports = {
    generateRecovery,
    generateDeepCognitiveResume,
};
