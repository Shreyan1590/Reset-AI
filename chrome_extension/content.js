// RESET AI v2 - Enhanced Content Script
// Page context capture with focus bubble overlay

let scrollPosition = 0;
let selectedText = '';
let lastInteraction = Date.now();
let formData = {};

// Track scroll position
document.addEventListener('scroll', () => {
    scrollPosition = window.scrollY;
    lastInteraction = Date.now();
});

// Track text selection
document.addEventListener('selectionchange', () => {
    const selection = window.getSelection();
    if (selection && selection.toString().trim()) {
        selectedText = selection.toString().trim().substring(0, 500);
    }
    lastInteraction = Date.now();
});

// Track clicks
document.addEventListener('click', () => {
    lastInteraction = Date.now();
});

// Track keyboard input
document.addEventListener('keydown', () => {
    lastInteraction = Date.now();
});

// Track form data for state snapshotting
document.addEventListener('input', (e) => {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
        formData[e.target.name || e.target.id || 'unnamed'] = e.target.value;
    }
    lastInteraction = Date.now();
});

// Extract page metadata
function getPageMetadata() {
    const metadata = {
        title: document.title,
        description: '',
        keywords: [],
        headings: [],
        focusedElement: null,
    };

    const descMeta = document.querySelector('meta[name="description"]');
    if (descMeta) {
        metadata.description = descMeta.getAttribute('content') || '';
    }

    const keywordsMeta = document.querySelector('meta[name="keywords"]');
    if (keywordsMeta) {
        metadata.keywords = (keywordsMeta.getAttribute('content') || '').split(',').map(k => k.trim());
    }

    const headings = document.querySelectorAll('h1, h2');
    metadata.headings = Array.from(headings).slice(0, 5).map(h => h.textContent?.trim() || '');

    const focused = document.activeElement;
    if (focused && focused !== document.body) {
        metadata.focusedElement = {
            tag: focused.tagName,
            id: focused.id,
            class: focused.className,
            type: focused.type,
        };
    }

    return metadata;
}

// Get visible content
function getVisibleContent() {
    const mainContent = document.querySelector('main, article, [role="main"], .content, #content');
    const element = mainContent || document.body;
    let text = element.innerText || '';
    text = text.replace(/\s+/g, ' ').trim();
    return text.substring(0, 1000);
}

// Listen for messages from background script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
    if (message.type === 'GET_PAGE_CONTEXT') {
        const context = {
            scrollPosition,
            selectedText,
            lastInteraction,
            formData,
            metadata: getPageMetadata(),
            visibleContent: getVisibleContent(),
            url: window.location.href,
            title: document.title,
        };
        sendResponse(context);
    } else if (message.type === 'SHOW_RECOVERY') {
        showRecoveryPopup(message.context);
        sendResponse({ success: true });
    } else if (message.type === 'SHOW_FOCUS_BUBBLE') {
        showFocusBubble(message.prediction);
        sendResponse({ success: true });
    }
    // Only return true (to keep channel open) if we actually send a response asynchronously.
    // In manifest v3, we can just return nothing if we respond immediately.
});

// Reading pattern detection
let readingPatterns = [];

function trackReadingPattern() {
    const pattern = {
        timestamp: Date.now(),
        scrollPosition: window.scrollY,
        viewportHeight: window.innerHeight,
    };

    readingPatterns.push(pattern);
    if (readingPatterns.length > 20) readingPatterns.shift();

    // Detect re-reading (confusion)
    if (readingPatterns.length >= 3) {
        const recent = readingPatterns.slice(-3);
        if (recent[0].scrollPosition > recent[1].scrollPosition &&
            recent[1].scrollPosition > recent[2].scrollPosition) {
            chrome.runtime.sendMessage({ type: 'CONFUSION_DETECTED' });
        }
    }
}

setInterval(trackReadingPattern, 2000);

// Show recovery popup
function showRecoveryPopup(context) {
    removeExisting('reset-ai-recovery');

    const popup = document.createElement('div');
    popup.id = 'reset-ai-recovery';
    popup.innerHTML = `
    <div class="reset-ai-popup">
      <div class="reset-ai-header">
        <span class="reset-ai-icon">🧠</span>
        <span class="reset-ai-title">Context Recovery</span>
        <button class="reset-ai-close">&times;</button>
      </div>
      <div class="reset-ai-body">
        <p class="reset-ai-message">You were working on:</p>
        <p class="reset-ai-context">${escapeHtml(context.title || 'Previous task')}</p>
        ${context.summary ? `<p class="reset-ai-summary">${escapeHtml(context.summary)}</p>` : ''}
      </div>
      <div class="reset-ai-actions">
        <button class="reset-ai-resume">Resume</button>
        <button class="reset-ai-skip">Skip</button>
      </div>
    </div>
  `;

    document.body.appendChild(popup);
    setupPopupHandlers(popup, context);
    autoHide(popup, 10000);
}

// Show AI Focus Bubble
function showFocusBubble(prediction) {
    removeExisting('reset-ai-focus-bubble');

    const bubble = document.createElement('div');
    bubble.id = 'reset-ai-focus-bubble';
    bubble.innerHTML = `
    <div class="focus-bubble">
      <div class="focus-header">
        <span class="focus-icon">🎯</span>
        <span class="focus-title">Focus Check</span>
        <button class="focus-close">&times;</button>
      </div>
      <div class="focus-body">
        <div class="focus-alert ${prediction.probability > 0.7 ? 'high' : prediction.probability > 0.4 ? 'medium' : 'low'}">
          <span class="alert-icon">${prediction.probability > 0.5 ? '⚠️' : '✅'}</span>
          <span class="alert-text">${prediction.probability > 0.5 ? 'Distraction risk detected' : 'Focus looks good'}</span>
        </div>
        <p class="focus-message">${escapeHtml(prediction.recommendation)}</p>
        ${prediction.triggers?.length ? `
          <div class="focus-triggers">
            ${prediction.triggers.slice(0, 2).map(t => `<span class="trigger-tag">${escapeHtml(t)}</span>`).join('')}
          </div>
        ` : ''}
      </div>
      <div class="focus-actions">
        <button class="focus-mode-btn">Enter Focus Mode</button>
        <button class="focus-dismiss">Got it</button>
      </div>
    </div>
  `;

    document.body.appendChild(bubble);

    bubble.querySelector('.focus-close').addEventListener('click', () => bubble.remove());
    bubble.querySelector('.focus-dismiss').addEventListener('click', () => bubble.remove());
    bubble.querySelector('.focus-mode-btn').addEventListener('click', () => {
        // Placeholder for focus mode
        bubble.remove();
    });

    autoHide(bubble, 8000);
}

// Helper functions
function removeExisting(id) {
    const existing = document.getElementById(id);
    if (existing) existing.remove();
}

function setupPopupHandlers(popup, context) {
    popup.querySelector('.reset-ai-close').addEventListener('click', () => popup.remove());
    popup.querySelector('.reset-ai-skip').addEventListener('click', () => popup.remove());
    popup.querySelector('.reset-ai-resume').addEventListener('click', () => {
        chrome.runtime.sendMessage({ type: 'MARK_RECOVERED', contextId: context.id });
        if (context.url) window.location.href = context.url;
        popup.remove();
    });
}

function autoHide(element, delay) {
    setTimeout(() => {
        if (element.parentNode) {
            element.classList.add('reset-ai-fade-out');
            setTimeout(() => element.remove(), 300);
        }
    }, delay);
}

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

console.log('RESET AI v2 content script loaded');
