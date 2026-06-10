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

  // ─── Transaction writes ────────────────────────────────────────────────────
  /// Creates a clean 5-field transaction node. Returns the new push key.
  static Future<String> writeTxn({
    required String accountFrom,
    required String accountTo,
    required dynamic amount,
    Map<String, dynamic>? location,
  }) async {
    final ref = transactions.push();
    await ref.set({
      'accountFrom': accountFrom,
      'accountTo':   accountTo,
      'amount':      amount,
      'status':      'pending',
      'createdAt':   nowMs(),
      'location':    location ?? {'status': 'unknown'},
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
  }) async {
    // Reference-only entries — no transaction data duplicated
    await accounts.child('$from/sent/$txnId').set(true);
    await accounts.child('$to/received/$txnId').set(true);

    final amt = (amount as num).toDouble();
    await _updateSummary(from, sentDelta: amt,     isMule: isMule);
    await _updateSummary(to,   receivedDelta: amt, isMule: false);
  }

  static Future<void> _updateSummary(
    String accountId, {
    double sentDelta     = 0,
    double receivedDelta = 0,
    required bool isMule,
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
      });

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

      // 3. Clean the transaction node down to 5 fields
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
        'accountFrom': txn['accountFrom'] ?? '',
        'accountTo':   txn['accountTo']   ?? '',
        'amount':      txn['amount']       ?? 0,
        'status':      txn['status']       ?? 'analyzed',
        'createdAt':   createdMs,
      });
    }
  }
}
