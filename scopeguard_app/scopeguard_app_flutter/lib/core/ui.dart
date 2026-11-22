import 'package:flutter/material.dart';
import 'package:scopeguard_app_client/scopeguard_app_client.dart';

import '../app/theme.dart';

/// A readable message for any error from the app's backend.
String errorText(Object e) {
  if (e is SgException) return e.message;
  final s = '$e';
  if (s.contains('SocketException') || s.contains('XMLHttpRequest') || s.contains('ClientException')) {
    return 'Can’t reach the ScopeGuard server. Is start-all.ps1 running?';
  }
  return 'Something went wrong. Try again.';
}

void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(text)));

/// Runs an action, shows a friendly error if it fails. Returns true on success.
Future<bool> attempt(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (e) {
    if (context.mounted) toast(context, errorText(e));
    return false;
  }
}

const stages = [
  ('paid', 'Paid & queued'),
  ('accepted', 'Order accepted'),
  ('cooking', 'Cooking'),
  ('quality_check', 'Quality check'),
  ('out_for_delivery', 'Out for delivery'),
  ('taste_test', 'Taste test'),
  ('delivered', 'Delivered'),
  ('completed', 'Completed'),
];

/// Plain-language status, same wording as the website.
(String, Color) statusOf(Map o) {
  if (o['paid'] == true) {
    final stage = (o['stage'] as num?)?.toInt() ?? 0;
    final label = stages[stage.clamp(0, stages.length - 1)].$2;
    return (o['ciFailed'] == true ? '$label · tests failing' : label, stage >= 7 ? leaf : cyan);
  }
  return switch (o['status']) {
    'scoping' => ('Unfinished', faint),
    'ai_draft' => ('Being reviewed', amber),
    'negotiating' => ('Quote ready', brand),
    'awaiting_payment' => ('Awaiting payment', brand),
    _ => ('${o['status']}', muted),
  };
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.accent});
  final Widget child;
  final EdgeInsets padding;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent?.withValues(alpha: 0.35) ?? line),
        ),
        child: child,
      );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = faint});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: mono(10.5, color: color, spacing: 2));
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, this.color, {super.key});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

/// Name ........ $price, like a restaurant menu (same as the website's bill).
class LeaderRow extends StatelessWidget {
  const LeaderRow({super.key, required this.left, required this.right, this.strike = false, this.tag});
  final String left;
  final String right;
  final bool strike;
  final String? tag;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        ConstrainedBox(
          // The name takes what it needs (up to 65%); the dotted leader fills the rest up to the price.
          constraints: BoxConstraints(maxWidth: c.maxWidth * 0.65),
          child: Text(left,
              style: TextStyle(fontSize: 15, color: strike ? faint : ink, decoration: strike ? TextDecoration.lineThrough : null),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
        if (tag != null) ...[const SizedBox(width: 6), Text(tag!.toUpperCase(), style: mono(9, color: brand))],
        const SizedBox(width: 8),
        const Expanded(child: _Dots()),
        const SizedBox(width: 8),
        Text(right, style: mono(14, color: strike ? faint : ink, spacing: 0)),
      ]),
      );
}

class _Dots extends StatelessWidget {
  const _Dots();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('·' * (c.maxWidth / 5).floor().clamp(1, 400), maxLines: 1, overflow: TextOverflow.clip, style: const TextStyle(color: faint, height: 1)),
        ),
      );
}

class Loading extends StatelessWidget {
  const Loading({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: brand, strokeWidth: 2));
}

class EmptyNote extends StatelessWidget {
  const EmptyNote({super.key, required this.title, required this.body});
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(children: [
          Text(title, style: display(32), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(color: muted), textAlign: TextAlign.center),
        ]),
      );
}

/// Centers content and limits width so the app also looks right in a desktop browser.
class Narrow extends StatelessWidget {
  const Narrow({super.key, required this.child, this.max = 720});
  final Widget child;
  final double max;
  @override
  Widget build(BuildContext context) =>
      Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: max), child: child));
}
