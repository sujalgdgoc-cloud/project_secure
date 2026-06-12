import 'package:firebase_database/firebase_database.dart';

/// Centralised Firebase Realtime Database service.
/// All path constants, write helpers, and migration logic live here.
class DbService {
  static const String modelVersion     = 'v1.0';
  static const double defaultThreshold = 0.5;

  static final _db = FirebaseDatabase.instance;

  // ─── Node references ───────────────────────────────────────────────────────
  static DatabaseReference get transactions => _db.ref('transactions');
  static DatabaseReference get predictions  => _db.ref('predictions');
  static DatabaseReference get alerts       => _db.ref('alerts');
  static DatabaseReference get accounts     => _db.ref('accounts');
  static DatabaseReference get signalDefs   => _db.ref('signalDefinitions');
  static DatabaseReference get config       => _db.ref('config');
  static DatabaseReference get auditLogs    => _db.ref('auditLogs');
  static DatabaseReference get muleAccounts => _db.ref('mule_accounts');

  // ─── Timestamp helpers ─────────────────────────────────────────────────────
  /// Current Unix epoch milliseconds.
  static int nowMs() => DateTime.now().millisecondsSinceEpoch;

  /// Parses Unix-ms int OR ISO string into a DateTime.
  static DateTime parseTs(dynamic ts) {
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    if (ts is String) {
      try { return DateTime.parse(ts); } catch (_) {}
    }
    return DateTime.now();
  }

  // ─── Static data seeding ───────────────────────────────────────────────────
  /// Seeds /config and /signalDefinitions once. Safe to call repeatedly.
  static Future<void> seedStatics() async {
    final snap = await config.child('modelVersion').get();
    if (snap.exists) return; // already seeded

    await config.set({
      'modelVersion': modelVersion,
      'threshold':    defaultThreshold,
    });

    await signalDefs.set({
      '1': {'title': 'Student High Tx Count',        'description': 'Signal 6b: Student account with unusually high transaction count.'},
      '2': {'title': 'Multiple Linked Accounts',      'description': 'Signal 7: Account linked to multiple devices or identifiers.'},
      '3': {'title': 'Linked Device Auth Flag',       'description': 'Signal 9: Device fingerprint matches a known flagged device.'},
      '4': {'title': 'Device Fingerprint Batch Open', 'description': 'Signal 10: Batch account opening from the same device.'},
      '5': {'title': 'New Account SIM Age',           'description': 'Signal 11: Account opened with a newly registered SIM/telecom.'},
      '6': {'title': 'Pass-Through Ratio Near 0.5',   'description': 'Funds pass through with minimal balance retention — indicative of layering.'},
    });
  }

  // ─── Mule Account registry ────────────────────────────────────────────────
  /// Inserts or updates a mule account entry in mule_accounts/{accountId}.
  static Future<void> writeMuleAccount({
    required String accountId,
    required String accountName,
    required String riskLevel,
    required double incoming,
    required double outgoing,
    required String status,
    required String txnId,
    double riskScore = 0.0,
    int linkedCases = 1,
    String aiExplanation = '',
  }) async {
    final ts = nowMs();
    final ref = muleAccounts.child(accountId);
    final snap = await ref.get();
    final existing = snap.exists && snap.value is Map
        ? Map<String, dynamic>.from((snap.value as Map).map((k, v) => MapEntry(k.toString(), v)))
        : <String, dynamic>{};

    await ref.set({
      'accountId':     accountId,
      'accountName':   accountName,
      'accountNumber': 'BOI-$accountId',
      'riskLevel':     riskLevel,
      'riskScore':     riskScore,
      'linkedCases':   (existing['linkedCases'] as int? ?? 0) + linkedCases,
      'incoming':      ((existing['incoming'] as num?) ?? 0) + incoming,
      'outgoing':      ((existing['outgoing'] as num?) ?? 0) + outgoing,
      'status':        status,
      'frozen':        false,
      'aiExplanation': aiExplanation,
      'lastTxnId':     txnId,
      'lastActivity':  ts,
      'createdAt':     existing['createdAt'] ?? ts,
      'updatedAt':     ts,
    });
  }

  // ─── Transaction writes ────────────────────────────────────────────────────
  /// Creates a clean transaction node. Returns the new push key.
  static Future<String> writeTxn({
    required String accountFrom,
    required String accountTo,
    required dynamic amount,
    String? senderName,
    String? receiverName,
    Map<String, dynamic>? location,
  }) async {
    final ref = transactions.push();
    await ref.set({
      'accountFrom':  accountFrom,
      'accountTo':    accountTo,
      'amount':       amount,
      'status':       'pending',
      'createdAt':    nowMs(),
      'location':     location ?? {'status': 'unknown'},
      if (senderName != null && senderName.isNotEmpty)   'senderName':   senderName,
      if (receiverName != null && receiverName.isNotEmpty) 'receiverName': receiverName,
    });
    return ref.key!;
  }

  /// Updates only the `status` field on a transaction node.
  static Future<void> markTxnStatus(String txnId, String status) =>
      transactions.child(txnId).update({'status': status});

  // ─── Account reference writes ──────────────────────────────────────────────
  /// Writes boolean references into sent/received folders and updates summary.
  static Future<void> writeAccRefs({
    required String from,
    required String to,
    required String txnId,
    required dynamic amount,
    required bool isMule,
    String? senderName,
    String? receiverName,
  }) async {
    // Reference-only entries — no transaction data duplicated
    await accounts.child('$from/sent/$txnId').set(true);
    await accounts.child('$to/received/$txnId').set(true);

    final amt = (amount as num).toDouble();
    await _updateSummary(from, sentDelta: amt,     isMule: isMule, ownerName: senderName);
    await _updateSummary(to,   receivedDelta: amt, isMule: false,  ownerName: receiverName);
  }

  static Future<void> _updateSummary(
    String accountId, {
    double sentDelta     = 0,
    double receivedDelta = 0,
    required bool isMule,
    String? ownerName,
  }) async {
    final sumRef = accounts.child('$accountId/summary');
    final snap   = await sumRef.get();
    Map<String, dynamic> old = {};
    if (snap.exists && snap.value is Map) {
      old = Map<String, dynamic>.from((snap.value as Map).map(
            (k, v) => MapEntry(k.toString(), v)));
    }
    await sumRef.set({
      'totalSent':       ((old['totalSent']     as num?) ?? 0) + sentDelta,
      'totalReceived':   ((old['totalReceived'] as num?) ?? 0) + receivedDelta,
      'lastTransaction': nowMs(),
      'flaggedCount':    ((old['flaggedCount']  as num?) ?? 0) + (isMule ? 1 : 0),
      'status':          old['status'] ?? 'active',
      if (ownerName != null && ownerName.isNotEmpty) 'ownerName': ownerName,
    });
  }

  // ─── Prediction writes ─────────────────────────────────────────────────────
  /// Stores AI output under predictions/{txnId}.
  static Future<void> writePrediction({
    required String txnId,
    required double probability,
    required String riskTier,
    required int signalsTriggered,
    required List<dynamic> signals,
  }) =>
      predictions.child(txnId).set({
        'probability':      probability,
        'riskScore':        (probability * 100).round(),
        'riskTier':         riskTier,
        'signalsTriggered': signalsTriggered,
        'signals':          signals,
        'analyzedAt':       nowMs(),
        'modelVersion':     modelVersion,
      });

  // ─── Alert writes ──────────────────────────────────────────────────────────
  /// Stores a mule alert under alerts/{txnId}. Only called when flagged.
  static Future<void> writeAlert({
    required String txnId,
    required double probability,
    required String riskTier,
    required List<dynamic> signals,
  }) =>
      alerts.child(txnId).set({
        'flagged':     true,
        'probability': probability,
        'riskTier':    riskTier,
        'signals':     signals,
        'analyzedAt':  nowMs(),
        'status':      'active',
      });

  // ─── Audit log ─────────────────────────────────────────────────────────────
  /// Appends a single audit log entry under auditLogs/{txnId}/{pushKey}.
  static Future<void> writeAuditLog({
    required String txnId,
    required String action,
    required String performedBy,
    String? accountId,
    String? note,
  }) =>
      auditLogs.child(txnId).push().set({
        'action':      action,
        'performedBy': performedBy,
        'timestamp':   nowMs(),
        if (accountId != null) 'accountId': accountId,
        if (note != null)      'note':      note,
      });

  // ─── Freeze Account ────────────────────────────────────────────────────────
  /// Fully freezes an account: sets status, timestamps, metadata, audit log.
  static Future<void> freezeAccount({
    required String accountId,
    required String alertId,
    required String performedBy,
    String reason = 'High-probability mule transaction flagged by AI model',
  }) async {
    final ts = nowMs();

    // 1. Update account summary
    await accounts.child('$accountId/summary').update({
      'status':        'frozen',
      'frozenAt':      ts,
      'frozenBy':      performedBy,
      'freezeAlertId': alertId,
      'freezeReason':  reason,
      'flaggedCount':  ServerValue.increment(1),
    });

    // 2. Update mule_accounts node if it exists
    final muleSnap = await muleAccounts.child(accountId).get();
    if (muleSnap.exists) {
      await muleAccounts.child(accountId).update({
        'frozen':     true,
        'status':     'Frozen',
        'frozenAt':   ts,
        'frozenBy':   performedBy,
        'updatedAt':  ts,
      });
    }

    // 3. Write audit log
    await writeAuditLog(
      txnId:       alertId,
      action:      'FREEZE_ACCOUNT',
      performedBy: performedBy,
      accountId:   accountId,
      note:        reason,
    );
  }

  // ─── Escalate Alert ────────────────────────────────────────────────────────
  /// Fully escalates an alert: updates transaction, alert node, history, and audit log.
  static Future<void> escalateAlert({
    required String txnId,
    required String escalatedBy,
    String reason = 'Escalated to senior investigator queue',
  }) async {
    final ts = nowMs();

    // 1. Update transaction node
    await transactions.child(txnId).update({
      'status':       'escalated',
      'priority':     'HIGH',
      'escalatedAt':  ts,
      'escalatedBy':  escalatedBy,
    });

    // 2. Update alert node
    await alerts.child(txnId).update({
      'status':      'escalated',
      'escalatedAt': ts,
    });

    // 3. Append to escalation history
    await alerts.child(txnId).child('escalationHistory').push().set({
      'by':     escalatedBy,
      'at':     ts,
      'reason': reason,
    });

    // 4. Write audit log
    await writeAuditLog(
      txnId:       txnId,
      action:      'ESCALATE',
      performedBy: escalatedBy,
      note:        reason,
    );
  }

  // ─── Mark Safe ─────────────────────────────────────────────────────────────
  /// Marks a transaction safe: updates status, removes alert, writes audit log.
  static Future<void> markSafe({
    required String txnId,
    required String reviewedBy,
    String note = 'Investigation completed — transaction deemed safe',
  }) async {
    final ts = nowMs();

    // 1. Update transaction node
    await transactions.child(txnId).update({
      'status':        'safe',
      'markedSafeAt':  ts,
      'markedSafeBy':  reviewedBy,
    });

    // 2. Remove alert (resolved)
    await alerts.child(txnId).remove();

    // 3. Write audit log
    await writeAuditLog(
      txnId:       txnId,
      action:      'MARK_SAFE',
      performedBy: reviewedBy,
      note:        note,
    );
  }

  // ─── One-shot migration ────────────────────────────────────────────────────
  /// Moves old denormalized records into the new normalized nodes.
  /// Idempotent — safe to call on every app start.
  static Future<void> migrateOldRecords() async {
    final snap = await transactions.get();
    if (!snap.exists || snap.value == null) return;
    final raw = snap.value;
    if (raw is! Map) return;

    for (final entry in raw.entries) {
      final txnId = entry.key.toString();
      if (txnId == 'mule-response') continue; // skip old sub-collection

      final data = entry.value;
      if (data is! Map) continue;
      final txn = Map<String, dynamic>.from(
          data.map((k, v) => MapEntry(k.toString(), v)));

      // Skip already-migrated records
      if (!txn.containsKey('features') && !txn.containsKey('mule_probability')) {
        continue;
      }

      // 1. Write prediction node (if missing)
      final predSnap = await predictions.child(txnId).get();
      if (!predSnap.exists && txn.containsKey('mule_probability')) {
        final prob  = (txn['mule_probability'] as num?)?.toDouble() ?? 0.0;
        final tier  = txn['risk_tier']?.toString() ?? 'UNKNOWN';
        final sigs  = txn['signals'] is List ? (txn['signals'] as List) : <dynamic>[];
        final sigCt = (txn['signals_triggered'] as num?)?.toInt() ?? 0;

        await writePrediction(
          txnId: txnId, probability: prob,
          riskTier: tier, signalsTriggered: sigCt, signals: sigs,
        );

        // 2. Write alert node if it was a mule
        if (txn['mule'] == true) {
          final alertSnap = await alerts.child(txnId).get();
          if (!alertSnap.exists) {
            await writeAlert(txnId: txnId, probability: prob,
                riskTier: tier, signals: sigs);
          }
        }
      }

      // 3. Clean the transaction node down to core fields
      final ts = txn['timestamp'] ?? txn['createdAt'];
      int createdMs;
      if (ts is int) {
        createdMs = ts;
      } else if (ts is String) {
        try { createdMs = DateTime.parse(ts).millisecondsSinceEpoch; }
        catch (_) { createdMs = nowMs(); }
      } else {
        createdMs = nowMs();
      }

      await transactions.child(txnId).set({
        'accountFrom':  txn['accountFrom'] ?? '',
        'accountTo':    txn['accountTo']   ?? '',
        'amount':       txn['amount']       ?? 0,
        'status':       txn['status']       ?? 'analyzed',
        'createdAt':    createdMs,
        if (txn['senderName'] != null)   'senderName':   txn['senderName'],
        if (txn['receiverName'] != null) 'receiverName': txn['receiverName'],
      });
    }
  }
}
