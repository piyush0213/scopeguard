import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:scopeguard_app_client/scopeguard_app_client.dart';

import '../../app/theme.dart';
import '../../core/server_clock.dart';

/// "Scope locked" celebration. Every phone computes the same timeline from the server's start time
/// (corrected for clock skew) and flashes when the wave reaches its seat, so the light travels
/// around the meeting table, phone to phone.
class LockMomentView extends StatefulWidget {
  const LockMomentView({super.key, required this.moment, required this.me, required this.members, required this.totalCents, required this.onClose});
  final LockMoment moment;
  final int me;
  final List<RoomMember> members;
  final int totalCents;
  final VoidCallback onClose;
  @override
  State<LockMomentView> createState() => _LockMomentViewState();
}

class _LockMomentViewState extends State<LockMomentView> with SingleTickerProviderStateMixin {
  static const _laps = 3;
  static const _gapMs = 700;
  late final Ticker _ticker;
  int _lastLap = -1;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => setState(() {}))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.moment;
    final seat = max(0, m.order.indexOf(widget.me));
    final n = max(1, m.order.length);
    final lapMs = n * m.stepMs + _gapMs;
    final t = serverClock.now().difference(m.startAt.toUtc()).inMilliseconds;
    final myColor = seatColor(widget.members.where((x) => x.id == widget.me).firstOrNull?.color ?? 0);

    var glow = 0.0;
    var finished = false;
    var countdown = 0;
    if (t < 0) {
      countdown = (-t / 1000).ceil();
    } else if (t >= _laps * lapMs) {
      finished = true;
    } else {
      final lap = t ~/ lapMs;
      final phase = (t % lapMs) - seat * m.stepMs;
      glow = exp(-pow(phase / 140.0, 2)).toDouble();
      if (phase >= 0 && lap != _lastLap) {
        _lastLap = lap;
        HapticFeedback.heavyImpact();
      }
    }
    final bg = finished ? myColor : Color.lerp(canvas, myColor, glow)!;
    final fg = finished || glow > 0.5 ? canvas : ink;

    return Material(
      color: bg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t < 0 ? 'SCOPE LOCKING · $countdown' : 'SCOPE AGREED IN PERSON',
                style: TextStyle(color: fg.withValues(alpha: 0.75), letterSpacing: 4, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(money(widget.totalCents), style: display(min(110, MediaQuery.of(context).size.width / 3.6), color: fg)),
            const SizedBox(height: 12),
            Text(
              t < 0
                  ? 'Hold your phones up — locking in $countdown…'
                  : finished
                      ? 'Everyone in the room agreed. No surprises later.'
                      : 'Seat ${seat + 1} of $n',
              style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 16),
            ),
            const Spacer(),
            if (finished)
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: canvas, side: const BorderSide(color: canvas)),
                onPressed: widget.onClose,
                child: const Text('Back to the room'),
              ),
          ]),
        ),
      ),
    );
  }
}
