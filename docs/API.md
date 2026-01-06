# RESET AI - API Documentation

## Base URL
```
https://us-central1-reset-ai-prototype.cloudfunctions.net
```

## Authentication
All endpoints require Firebase Authentication token in the Authorization header:
```
Authorization: Bearer <firebase_id_token>
```

---

## Context Endpoints

### Capture Context
Save a new context snapshot.

**POST** `/api/context/capture`

**Request Body:**
```json
{
  "userId": "string",
  "sessionId": "string (optional)",
  "type": "tab | document | code | note",
  "data": {
    "url": "string",
    "title": "string",
    "scrollPosition": "number",
    "selectedText": "string",
    "pageMetadata": "object"
  }
}
```

**Response:**
```json
{
  "success": true,
  "contextId": "ctx_abc123"
}
```

---

### List Contexts
Get user's captured contexts.

**GET** `/api/context/list?userId={userId}&limit={limit}`

**Query Parameters:**
| Param | Type | Required | Default |
|-------|------|----------|---------|
| userId | string | Yes | - |
| limit | number | No | 20 |

**Response:**
```json
{
  "contexts": [
    {
      "id": "ctx_abc123",
      "userId": "user123",
      "capturedAt": 1703673600000,
      "type": "code",
      "data": { ... },
      "summary": "Working on authentication",
      "keyPoints": ["JWT validation", "Token refresh"],
      "nextSteps": ["Complete validation"],
      "isRecovered": false
    }
  ]
}
```

---

### Detect Context Loss
Analyze activity for context loss.

**POST** `/api/context/detect-loss`

**Request Body:**
```json
{
  "userId": "string",
  "activityData": {
    "recentTabSwitches": [],
    "idleDuration": 120000,
    "domainChanged": true,
    "scrollPatterns": [],
    "timeSinceLastInteraction": 45000
  },
  "settings": {
    "aiSensitivity": 5
  }
}
```

**Response:**
```json
{
  "detected": true,
  "probability": 0.72,
  "confidence": "high",
  "factors": [
    {
      "name": "Extended idle time",
      "impact": 0.3,
      "description": "2 minutes of inactivity"
    }
  ],
  "recommendation": "Consider showing context recovery prompt"
}
```

---

### Generate Recovery
Generate AI recovery prompt.

**POST** `/api/context/generate-recovery`

**Request Body:**
```json
{
  "contextData": {
    "type": "code",
    "data": {
      "url": "https://github.com/...",
      "title": "auth.js",
      "selectedText": "..."
    }
  }
}
```

**Response:**
```json
{
  "summary": "Working on authentication implementation",
  "keyPoints": [
    "JWT token validation",
    "Error handling"
  ],
  "nextSteps": [
    "Complete validateToken function",
    "Add unit tests"
  ]
}
```

---

### Mark Recovered
Mark context as recovered.

**POST** `/api/context/mark-recovered`

**Request Body:**
```json
{
  "contextId": "ctx_abc123"
}
```

**Response:**
```json
{
  "success": true
}
```

---

## Session Endpoints

### Start Session
Start a new productivity session.

**POST** `/api/sessions/start`

**Request Body:**
```json
{
  "userId": "user123"
}
```

**Response:**
```json
{
  "success": true,
  "sessionId": "session_xyz789"
}
```

---

### End Session
End current session.

**POST** `/api/sessions/end`

**Request Body:**
```json
{
  "sessionId": "session_xyz789"
}
```

---

### Get Stats
Get productivity statistics.

**GET** `/api/sessions/stats?userId={userId}`

**Response:**
```json
{
  "totalSessions": 15,
  "totalInterruptions": 42,
  "totalTimeRecovered": 1800,
  "totalContextLossEvents": 23,
  "averageSessionDuration": 45,
  "sessions": [ ... ]
}
```

---

## Settings Endpoints

### Get Settings
**GET** `/api/user/settings?userId={userId}`

### Update Settings
**PUT** `/api/user/settings`

**Request Body:**
```json
{
  "userId": "user123",
  "settings": {
    "aiSensitivity": 7,
    "privacyLevel": "balanced",
    "backupEnabled": true
  }
}
```

---

## Error Responses

All endpoints return errors in this format:
```json
{
  "error": "Error message description"
}
```

| Status | Description |
|--------|-------------|
| 400 | Bad Request - Missing parameters |
| 401 | Unauthorized - Invalid token |
| 404 | Not Found - Resource doesn't exist |
| 405 | Method Not Allowed |
| 500 | Internal Server Error |
