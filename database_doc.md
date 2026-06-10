# FraudWatch AI — Database Documentation (v2 — Normalized)

Database type: **Firebase Realtime Database**
Instance URL: `https://muletrace-7993b-default-rtdb.firebaseio.com`

All code paths are managed through **`lib/services/db_service.dart`**.

---

## 1. Root Structure

```
Root/
├── transactions/
├── predictions/
├── alerts/
├── accounts/
├── signalDefinitions/
└── config/
```

---

## 2. `/transactions/{txnId}` — Transaction Record

Stores only the transfer metadata. No AI data or feature vectors.

| Field | Type | Description |
| :--- | :--- | :--- |
| `accountFrom` | String | Sender account ID |
| `accountTo` | String | Receiver account ID |
| `amount` | Number | Transfer amount |
| `status` | String | `pending` → `analyzing` → `analyzed` \| `analysis_failed` |
| `createdAt` | Integer | Unix epoch milliseconds |

```json
{
  "accountFrom": "ACC001",
  "accountTo":   "ACC002",
  "amount":      25000000,
  "status":      "analyzed",
  "createdAt":   1749475272053
}
```

---

## 3. `/predictions/{txnId}` — AI Prediction Result

Written by the background analysis task after the model responds.

| Field | Type | Description |
| :--- | :--- | :--- |
| `probability` | Double | Mule probability 0.0–1.0 |
| `riskScore` | Integer | `probability × 100` (0–100) |
| `riskTier` | String | `LOW`, `MEDIUM`, `HIGH`, `CRITICAL` |
| `signalsTriggered` | Integer | Count of anomaly signals fired |
| `signals` | List\<String\> | Human-readable signal descriptions |
| `analyzedAt` | Integer | Unix epoch milliseconds |
| `modelVersion` | String | e.g. `v1.0` |

```json
{
  "probability":      0.92,
  "riskScore":        92,
  "riskTier":         "CRITICAL",
  "signalsTriggered": 6,
  "signals": [
    "Signal 6b: Student Account High Tx Count",
    "Signal 7: Multiple Linked Accounts"
  ],
  "analyzedAt":    1749475280000,
  "modelVersion":  "v1.0"
}
```

---

## 4. `/alerts/{txnId}` — Mule Alert Audit Log

Only created when `probability >= 0.5` (flagged as mule).
Used by the dashboard "Recent Alerts" panel and mule count metric.

| Field | Type | Description |
| :--- | :--- | :--- |
| `flagged` | Boolean | Always `true` |
| `probability` | Double | Mule probability |
| `riskTier` | String | Risk classification |
| `signals` | List\<String\> | Triggered signals |
| `analyzedAt` | Integer | Unix epoch milliseconds |

```json
{
  "flagged":     true,
  "probability": 0.92,
  "riskTier":    "CRITICAL",
  "signals":     ["Signal 6b: Student Account High Tx Count"],
  "analyzedAt":  1749475280000
}
```

---

## 5. `/accounts/{accountId}/` — Account Directory

### `sent/{txnId}` and `received/{txnId}` — Reference Only

No transaction data is duplicated here. Each key is just `true`.
Full details are fetched from `/transactions/{txnId}` on demand.

```
accounts/
  ACC001/
    sent/
      -OufiADYz2: true
      -OufYSj7jz: true
    received/
      -OufcRpwze: true
    summary/
      totalSent:       50000000
      totalReceived:   25000000
      lastTransaction: 1749475280000
      flaggedCount:    2
```

### `summary/` — Lightweight Account Counters

Updated atomically on every transaction write.

| Field | Type | Description |
| :--- | :--- | :--- |
| `totalSent` | Double | Cumulative outbound amount |
| `totalReceived` | Double | Cumulative inbound amount |
| `lastTransaction` | Integer | Unix ms of most recent transaction |
| `flaggedCount` | Integer | Count of mule-flagged transactions |

---

## 6. `/signalDefinitions/{id}/` — Signal Catalogue

Seeded once on app start via `DbService.seedStatics()`.
Predictions store the human-readable string; this node provides the canonical reference.

```json
{
  "1": { "title": "Student High Tx Count",        "description": "Signal 6b: ..." },
  "2": { "title": "Multiple Linked Accounts",      "description": "Signal 7: ..." },
  "3": { "title": "Linked Device Auth Flag",       "description": "Signal 9: ..." },
  "4": { "title": "Device Fingerprint Batch Open", "description": "Signal 10: ..." },
  "5": { "title": "New Account SIM Age",           "description": "Signal 11: ..." },
  "6": { "title": "Pass-Through Ratio Near 0.5",   "description": "..." }
}
```

---

## 7. `/config/` — App Configuration

```json
{
  "modelVersion": "v1.0",
  "threshold":    0.5
}
```

---

## 8. State Machine

```
Submit Button Clicked
        │
        ▼
transactions/{id}  status: "pending"     ← written immediately
accounts/{from}/sent/{id}  = true
accounts/{to}/received/{id} = true
        │
        ▼ (background, non-blocking)
transactions/{id}  status: "analyzing"
        │
        ▼
AI Model API called
        │
   ┌────┴────┐
success     failure
   │            │
   ▼            ▼
predictions/{id} written     transactions/{id}  status: "analysis_failed"
transactions/{id}  status: "analyzed"
   │
   ├── if probability ≥ 0.5
   │       └── alerts/{id} written
   └── done
```

---

## 9. AI Feature Reference (17 Input Fields)

These are sent to the prediction API and **not stored in Firebase**.

| Key | Label |
| :--- | :--- |
| F3891 | Occupation |
| F3894 | Age |
| F3889 | Account Tenure Code |
| F3895 | Credit Score |
| F3799 | Total Inward Amount |
| F3800 | Total Outward Amount |
| F3796 | Credit Tx Count |
| F3797 | Debit Tx Count |
| F3890 | Location Segment (U/M/R) |
| F3886 | Account Type |
| F3893 | Customer Segment |
| F3919 | Credit Tx Rate |
| F3887 | Avg Debit Tx Amount |
| F3920 | Avg Tx Amount |
| F3905 | Normalised Credit Score |
| F3915 | Net Flow Efficiency |
| F3922 | Account Type Code |

---

## 10. Key Design Decisions

| Decision | Reason |
| :--- | :--- |
| Separate `predictions/` node | Keeps transactions clean; AI data can evolve independently |
| `alerts/` node instead of `transactions/mule-response/` | Dedicated collection for quick count/read on dashboard |
| Account refs are `true` booleans | Eliminates duplication; single source of truth is `transactions/` |
| Unix ms timestamps | Efficient sorting and diff calculation without string parsing |
| `riskScore` alongside `riskTier` | Enables numeric sorting/range queries in future |
| `modelVersion` in predictions | Enables safe model upgrades — old/new results co-exist |
| Features **not** stored in DB | Reduces storage cost; irrelevant after analysis |
