import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../client.dart';
import '../../core/payments.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import '../orders/order_screen.dart';

/// Same flow as the website's New Project page: describe the project, pick fixed-price menu items,
/// optionally ask for custom work (scoped and priced by AI after 3-4 quick questions).
class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key, required this.onCreated});
  final VoidCallback onCreated;
  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _brief = TextEditingController();
  final _custom = TextEditingController();
  List<Map<String, dynamic>>? _menu;
  final Set<String> _picked = {};
  bool _wantCustom = false;
  bool _busy = false;
  String? _error;

  // AI questions step
  String? _orderId;
  List<Map<String, dynamic>> _questions = [];
  final Map<int, TextEditingController> _answers = {};

  @override
  void initState() {
    super.initState();
    _brief.addListener(() => setState(() {}));
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    try {
      final d = jsonDecode(await client.shop.menu(token));
      setState(() => _menu = (d['items'] as List).cast<Map<String, dynamic>>());
    } catch (e) {
      setState(() => _error = errorText(e));
    }
  }

  int get _menuTotal => (_menu ?? []).where((m) => _picked.contains(m['id'])).fold(0, (s, m) => s + (m['price_cents'] as int));

  String? get _missing {
    if (_brief.text.trim().length < 15) return 'Describe your project in a sentence or two (step 1)';
    if (!_wantCustom && _picked.isEmpty) return 'Pick at least one menu item, or add custom work';
    if (_wantCustom && _custom.text.trim().length < 8) return 'Describe the custom work you want';
    return null;
  }

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_wantCustom) {
        final d = jsonDecode(await client.shop.orderFromMenu(token, _brief.text.trim(), _picked.toList(), returnUrl: stripeReturnUrl));
        final orderId = d['orderId'] as String;
        if (mounted) await openCheckout(context, orderId, d['checkoutUrl'] as String);
        _reset();
        widget.onCreated();
        if (mounted) await Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderScreen(orderId: orderId)));
      } else {
        final d = jsonDecode(await client.shop.startScoping(token, _brief.text.trim(), _custom.text.trim(), _picked.toList()));
        setState(() {
          _orderId = d['orderId'] as String;
          _questions = (d['questions'] as List).cast<Map<String, dynamic>>();
          _answers.clear();
        });
      }
    } catch (e) {
      setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendAnswers() async {
    final answers = [for (var i = 0; i < _questions.length; i++) _answers[i]?.text.trim() ?? ''];
    if (answers.any((a) => a.isEmpty)) return setState(() => _error = 'Answer every question (tap a suggestion or type)');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await client.shop.answerScoping(token, _orderId!, answers);
      final id = _orderId!;
      _reset();
      widget.onCreated();
      if (mounted) await Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderScreen(orderId: id)));
    } catch (e) {
      setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() => setState(() {
        _orderId = null;
        _questions = [];
        _picked.clear();
        _brief.clear();
        _custom.clear();
        _wantCustom = false;
      });

  @override
  Widget build(BuildContext context) => _orderId != null ? _questionsView() : _cartView();

  Widget _cartView() {
    return Narrow(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
        Text('What are we', style: display(44)),
        Text('cooking?', style: display(44, color: brand, style: FontStyle.italic)),
        const SizedBox(height: 20),
        const Eyebrow('1 · Describe your project'),
        const SizedBox(height: 8),
        TextField(
          controller: _brief,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'e.g. I run a dental clinic with 3 dentists and want patients to book online.'),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(_brief.text.trim().length >= 15 ? 'Looks good' : '${15 - _brief.text.trim().length} more characters',
              style: mono(10, color: _brief.text.trim().length >= 15 ? leaf : faint)),
        ),
        const SizedBox(height: 16),
        const Eyebrow('2 · Pick off the menu (fixed price)'),
        const SizedBox(height: 8),
        if (_menu == null && _error == null) const Padding(padding: EdgeInsets.all(24), child: Loading()),
        for (final m in _menu ?? const <Map<String, dynamic>>[])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _picked.contains(m['id']) ? _picked.remove(m['id']) : _picked.add(m['id'] as String)),
              child: Panel(
                accent: _picked.contains(m['id']) ? brand : null,
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      LeaderRow(left: '${m['name']}', right: money(m['price_cents'] as int)),
                      const SizedBox(height: 4),
                      Text('${m['description']}', style: const TextStyle(color: muted, fontSize: 13, height: 1.35)),
                      const SizedBox(height: 4),
                      Text('${m['eta_days']} days', style: mono(10, color: faint)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Icon(_picked.contains(m['id']) ? Icons.check_circle : Icons.add_circle_outline, color: _picked.contains(m['id']) ? brand : faint),
                ]),
              ),
            ),
          ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _wantCustom,
          onChanged: (v) => setState(() => _wantCustom = v),
          title: const Text('Add custom work (Chef’s special)'),
          subtitle: const Text('AI asks a few questions, then prices it. A developer reviews the quote.', style: TextStyle(color: muted, fontSize: 12)),
        ),
        if (_wantCustom)
          TextField(
            controller: _custom,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'e.g. A chatbot that answers patient FAQs and books appointments.'),
          ),
        const SizedBox(height: 20),
        Panel(
          child: Column(children: [
            LeaderRow(left: 'Menu items', right: money(_menuTotal)),
            if (_wantCustom) ...[const SizedBox(height: 6), const LeaderRow(left: 'Custom work', right: 'AI quote')],
          ]),
        ),
        if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: brand))],
        const SizedBox(height: 14),
        FilledButton(
          onPressed: _busy || _missing != null ? null : _go,
          child: Text(_busy ? (_wantCustom ? 'AI is reading your brief…' : 'Opening Stripe…') : _wantCustom ? 'Get my quote' : 'Pay ${money(_menuTotal)} & start'),
        ),
        const SizedBox(height: 8),
        Text(_missing != null ? '↑ $_missing' : _wantCustom ? 'Nothing is charged yet.' : 'Paid items wait in escrow until the code proves them.',
            textAlign: TextAlign.center, style: TextStyle(color: _missing != null ? amber : muted, fontSize: 12)),
      ]),
    );
  }

  Widget _questionsView() {
    return Narrow(
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
        Row(children: [
          IconButton(onPressed: _busy ? null : _reset, icon: const Icon(Icons.close)),
          const Eyebrow('A few quick questions'),
        ]),
        Text('Help the AI', style: display(40)),
        Text('price it right.', style: display(40, color: brand, style: FontStyle.italic)),
        const SizedBox(height: 16),
        for (var i = 0; i < _questions.length; i++) ...[
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i + 1}. ${_questions[i]['question']}', style: const TextStyle(fontSize: 15, height: 1.4)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in (_questions[i]['suggestions'] as List? ?? const []))
                  ChoiceChip(
                    label: Text('$s'),
                    selected: (_answers[i]?.text ?? '') == '$s',
                    onSelected: (_) => setState(() => (_answers[i] ??= TextEditingController()).text = '$s'),
                  ),
              ]),
              const SizedBox(height: 10),
              TextField(
                controller: _answers[i] ??= TextEditingController(),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Or type your own answer'),
              ),
            ]),
          ),
          const SizedBox(height: 12),
        ],
        if (_error != null) ...[Text(_error!, style: const TextStyle(color: brand)), const SizedBox(height: 10)],
        FilledButton(onPressed: _busy ? null : _sendAnswers, child: Text(_busy ? 'AI is drafting your quote… (up to a minute)' : 'Draft my quote')),
      ]),
    );
  }
}
