import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/form_record.dart';
import '../data/store.dart';
import 'form_actions.dart';
import 'form_fill_screen.dart';
import 'logo.dart';
import 'pal.dart';
import 'templates.dart';

/// Раздел «Анкеты»: список сохранённых и выбор типа новой анкеты.
class FormsScreen extends StatefulWidget {
  const FormsScreen({super.key});

  @override
  State<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends State<FormsScreen> {
  final _repo = FormStore.instance;
  List<FormRecord> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _repo.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _repo.forms();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _open(FormTemplate t, [FormRecord? r]) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => FormFillScreen(template: t, record: r)));

  Future<void> _pickType() async {
    await showFloatingWindow(context, builder: (ctx) {
      final p = FPal.of(ctx);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FWindowHead(),
          Text('Какая анкета?', style: fts(p, size: 20, w: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('Выберите тип', style: fts(p, size: 13, w: FontWeight.w500, color: p.mut)),
          const SizedBox(height: 12),
          for (final t in formTemplates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _typeRow(ctx, p, t),
            ),
        ]),
      );
    });
  }

  Widget _typeRow(BuildContext ctx, FPal p, FormTemplate t) {
    return Material(
      color: p.card2,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.pop(ctx);
          _open(t);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            _icon(p, t.id == 'hotel' ? Icons.hotel_outlined : Icons.shopping_cart_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.name, style: fts(p, size: 16, w: FontWeight.w700)),
                Text('${t.sections.length} разделов · ${t.subtitle}',
                    style: fts(p, size: 12.5, w: FontWeight.w500, color: p.mut)),
              ]),
            ),
            Icon(Icons.chevron_right_rounded, color: p.mut),
          ]),
        ),
      ),
    );
  }

  Widget _icon(FPal p, IconData i) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14)),
        child: Icon(i, size: 22, color: p.ink),
      );

  Color _resultColor(FPal p, String v) => switch (v) {
        'Готов к подключению' => p.ok,
        'Требуется подготовка' => p.run,
        'Не готов' => p.bad,
        _ => p.mut,
      };

  Future<void> _delete(FormRecord r) async {
    final ok = await showFloatingWindow<bool>(context, builder: (ctx) {
      final p = FPal.of(ctx);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const FWindowHead(),
          Text('Удалить анкету?', style: fts(p, size: 20, w: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(r.title.isEmpty ? 'Без названия' : r.title,
              style: fts(p, size: 13, w: FontWeight.w500, color: p.mut)),
          const SizedBox(height: 16),
          FPill('Удалить', danger: true, onTap: () => Navigator.pop(ctx, true)),
          const SizedBox(height: 8),
          FPill('Отмена', quiet: true, onTap: () => Navigator.pop(ctx, false)),
        ]),
      );
    });
    if (ok != true) return;
    final path = r.pdfPath;
    await _repo.deleteForm(r.id);
    if (path != null) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
  }

  Widget _row(FPal p, FormRecord r) {
    final t = templateById(r.type);
    final day = DateFormat('d MMM', 'ru').format(r.updatedAt);
    final result = t?.resultKey == null ? '' : '${r.values[t!.resultKey!] ?? ''}';
    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: t == null
            ? null
            : () => r.done ? showFormActionsWindow(context, t, r) : _open(t, r),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), border: Border.all(color: p.line)),
          child: Row(children: [
            _icon(p, r.type == 'hotel' ? Icons.hotel_outlined : Icons.shopping_cart_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.title.isEmpty ? (t?.name ?? 'Анкета') : r.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: fts(p, size: 15.5, w: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${t?.name ?? r.type} · $day',
                    style: fts(p, size: 12.5, w: FontWeight.w500, color: p.mut)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  r.done ? FChip('Сохранена', color: p.ok) : FChip('Черновик', color: p.run),
                  if (result.isNotEmpty) FChip(result, color: _resultColor(p, result)),
                ]),
              ]),
            ),
            _menu(p, r, t),
          ]),
        ),
      ),
    );
  }

  Widget _menu(FPal p, FormRecord r, FormTemplate? t) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: p.mut),
      color: p.card2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22), side: BorderSide(color: p.line)),
      onSelected: (v) {
        if (v == 'edit' && t != null) _open(t, r);
        if (v == 'send' && t != null) showFormActionsWindow(context, t, r);
        if (v == 'delete') _delete(r);
      },
      itemBuilder: (_) => [
        if (r.done)
          PopupMenuItem(
              value: 'send',
              child: _menuItem(p, Icons.ios_share_rounded, 'Отправить или печать')),
        PopupMenuItem(
            value: 'edit', child: _menuItem(p, Icons.edit_outlined, 'Редактировать')),
        PopupMenuItem(
            value: 'delete',
            child: _menuItem(p, Icons.delete_outline_rounded, 'Удалить', color: p.bad)),
      ],
    );
  }

  Widget _menuItem(FPal p, IconData i, String text, {Color? color}) => Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: p.card, shape: BoxShape.circle),
          child: Icon(i, size: 18, color: color ?? p.ink),
        ),
        const SizedBox(width: 10),
        Text(text, style: fts(p, size: 15, color: color)),
      ]);

  @override
  Widget build(BuildContext context) {
    final p = FPal.of(context);
    return FormsTheme(
      child: Scaffold(
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(children: [
                const LogoMark(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Анкеты',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            height: 1.05,
                            color: p.ink)),
                    Text('VAYGO', style: fts(p, size: 12, w: FontWeight.w600, color: p.mut)),
                  ]),
                ),
                FAddBtn('Анкета', _pickType),
              ]),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Text('0',
                                  style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -1.5,
                                      color: p.ink)),
                              const SizedBox(height: 6),
                              Text('Нажмите «+ Анкета», чтобы заполнить первую',
                                  textAlign: TextAlign.center,
                                  style: fts(p, size: 14, w: FontWeight.w500, color: p.mut)),
                            ]),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          itemCount: _items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => _row(p, _items[i]),
                        ),
            ),
          ]),
        ),
      ),
    );
  }
}
