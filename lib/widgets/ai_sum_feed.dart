import 'package:flutter/material.dart';

class AiSumCard extends StatefulWidget {
  const AiSumCard({
    super.key,
    required this.box_color,
    required this.ctgy,
    required this.Score,
    required this.acc_no,
    required this.duration,
    required this.location,
    required this.summary,
    this.txnId,
    this.accountTo,
    this.onReview,
    this.onFreeze,
    this.onEscalate,
    this.onDismiss,
  });

  final Color box_color;
  final String ctgy;
  final String Score;
  final String acc_no;
  final String duration;
  final String location;
  final String summary;

  // Action callbacks for the 4 buttons
  final String? txnId;
  final String? accountTo;
  final Future<void> Function()? onReview;
  final Future<void> Function()? onFreeze;
  final Future<void> Function()? onEscalate;
  final Future<void> Function()? onDismiss;

  @override
  State<AiSumCard> createState() => _AiSumCardState();
}

class _AiSumCardState extends State<AiSumCard> {
  bool _expanded = false;
  bool _freezing = false;
  bool _escalating = false;
  bool _dismissing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Accent Color Line
            Container(height: 4, width: double.infinity, color: widget.box_color),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badges Row + Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Risk Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.box_color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          widget.ctgy.toUpperCase(),
                          style: TextStyle(
                            color: widget.box_color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      // Score Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.box_color,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${widget.Score} SCORE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Account Number
                  Row(
                    children: [
                      const Text('ACC: ', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 13)),
                      Expanded(
                        child: Text(
                          widget.acc_no,
                          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Duration & Location
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${widget.duration}  •  ${widget.location}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // AI Explanation Summary box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 13, color: widget.box_color),
                            const SizedBox(width: 5),
                            const Text(
                              'AI EXPLANATION SUMMARY',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          firstChild: Text(
                            widget.summary,
                            style: const TextStyle(color: Color(0xFF334155), fontSize: 12, height: 1.4),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(
                            widget.summary,
                            style: const TextStyle(color: Color(0xFF334155), fontSize: 12, height: 1.4),
                          ),
                        ),
                        if (widget.summary.length > 100)
                          GestureDetector(
                            onTap: () => setState(() => _expanded = !_expanded),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _expanded ? 'Show less' : 'Show more',
                                style: TextStyle(color: widget.box_color, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 4 Action Buttons ──────────────────────────────────
                  Row(
                    children: [
                      // Review
                      Expanded(
                        child: _ActionButton(
                          label: 'Review',
                          icon: Icons.remove_red_eye_outlined,
                          color: const Color(0xFF1D4ED8),
                          filled: false,
                          onPressed: widget.onReview,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Freeze
                      Expanded(
                        child: _ActionButton(
                          label: _freezing ? '…' : 'Freeze',
                          icon: Icons.lock_outline,
                          color: const Color(0xFFDC2626),
                          filled: true,
                          onPressed: widget.onFreeze == null
                              ? null
                              : () async {
                                  setState(() => _freezing = true);
                                  await widget.onFreeze!();
                                  if (mounted) setState(() => _freezing = false);
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Escalate
                      Expanded(
                        child: _ActionButton(
                          label: _escalating ? '…' : 'Escalate',
                          icon: Icons.crisis_alert,
                          color: const Color(0xFF0F172A),
                          filled: false,
                          onPressed: widget.onEscalate == null
                              ? null
                              : () async {
                                  setState(() => _escalating = true);
                                  await widget.onEscalate!();
                                  if (mounted) setState(() => _escalating = false);
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dismiss
                      Expanded(
                        child: _ActionButton(
                          label: _dismissing ? '…' : 'Dismiss',
                          icon: Icons.close,
                          color: const Color(0xFF64748B),
                          filled: false,
                          onPressed: widget.onDismiss == null
                              ? null
                              : () async {
                                  setState(() => _dismissing = true);
                                  await widget.onDismiss!();
                                  if (mounted) setState(() => _dismissing = false);
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small action button used inside AiSumCard
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.filled,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return SizedBox(
        height: 36,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 14),
          label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      );
    }
    return SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
