import 'package:flutter/material.dart';

import '../data/form_record.dart';
import '../data/store.dart';
import 'form_actions.dart';
import 'form_pdf.dart';
import 'pal.dart';
import 'templates.dart';

/// Заполнение анкеты по шагам: один раздел на экран, «Назад» и «Далее».
/// На последнем шаге «Сохранить анкету» создаёт PDF. Черновик сохраняется сам при выходе.
class FormFillScreen extends StatefulWidget {
  final FormTemplate template;
  final FormRecord? record; // null — новая анкета
  const FormFillScreen({super.key, required this.template, this.record});

  @override
  State<FormFillScreen> createState() => _FormFillScreenState();
}

class _FormFillScreenState extends State<FormFillScreen> {
  final _repo = FormStore.instance;
  late final FormRecord _rec;
  final Map<String, TextEditingController> _ctl = {};
  final _scroll = ScrollController();
  int _step = 0;
  bool _busy = false;
  bool _closing = false;

  FormTemplate get _t => widget.template;
  Map<String, dynamic> get _v => _rec.values;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _rec = widget.record ??
        FormRecord(id: newId(), type: _t.id, createdAt: now, updatedAt: now);
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in _ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _c(String id, String initial) =>
      _ctl.putIfAbsent(id, () => TextEditingController(text: initial));

  String _s(String key) {
    final x = _v[key];
    return x is String ? x : '';
  }

  String get _title {
    for (final k in _t.titleKeys) {
      final x = _s(k).trim();
      if (x.isNotEmpty) return x;
    }
    return '';
  }

  int get _answered {
    var n = 0;
    for (final s in _t.sections) {
      for (final q in s.questions) {
        if (isAnswered(q, _v)) n++;
      }
    }
    return n;
  }

  bool get _hasData => _answered > 0;

  // ---------- Сохранение ----------

  Future<void> _persist({required bool pdf}) async {
    _rec.title = _title;
    if (pdf) {
      final bytes = await FormPdf.build(_t, _v);
      _rec.pdfPath = await FormPdf.saveFile(_rec.id, bytes);
    }
    await _repo.saveForm(_rec);
  }

  /// Адрес электронной почты, если указан, должен быть похож на адрес.
  bool get _emailsOk {
    final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
    for (final s in _t.sections) {
      for (final q in s.questions) {
        if (!q.email) continue;
        final x = _s(q.key).trim();
        if (x.isNotEmpty && !re.hasMatch(x)) return false;
      }
    }
    return true;
  }

  Future<void> _save() async {
    if (_title.isEmpty || _busy) return;
    if (!_emailsOk) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Проверьте электронную почту: адрес указан неверно')));
      return;
    }
    setState(() => _busy = true);
    try {
      _rec.done = true;
      await _persist(pdf: true);
      if (!mounted) return;
      _closing = true;
      await showFormActionsWindow(context, _t, _rec, justSaved: true);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _closing = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось сохранить анкету')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Уход с экрана: черновик (или правки сохранённой анкеты) записывается сам.
  Future<void> _onLeave() async {
    if (_closing || !_hasData) return;
    try {
      await _persist(pdf: _rec.done);
    } catch (_) {}
  }

  // ---------- Поля ----------

  Widget _field(FPal p,
      {String? hint,
      TextEditingController? controller,
      ValueChanged<String>? onChanged,
      int minLines = 1,
      int maxLines = 3,
      bool email = false}) {
    final border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.line));
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      textCapitalization:
          email ? TextCapitalization.none : TextCapitalization.sentences,
      keyboardType: email ? TextInputType.emailAddress : null,
      autocorrect: !email,
      style: fts(p, size: 15, w: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: fts(p, size: 14, w: FontWeight.w400, color: p.mut),
        filled: true,
        fillColor: p.card2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: p.ink)),
      ),
    );
  }

  Widget _label(FPal p, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: fts(p, size: 13, w: FontWeight.w500, color: p.mut)),
      );

  Widget _choice(FPal p, String text, bool on, VoidCallback onTap, {bool small = false}) {
    return Material(
      color: on ? p.accent : p.card2,
      shape: StadiumBorder(side: BorderSide(color: on ? p.accent : p.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: small ? 34 : 38),
          padding: EdgeInsets.symmetric(horizontal: small ? 12 : 14, vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (on) ...[Icon(Icons.check_rounded, size: 16, color: p.onAccent), const SizedBox(width: 6)],
            Flexible(
              child: Text(text,
                  style: fts(p, size: 14, color: on ? p.onAccent : p.ink)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _question(FPal p, FormQuestion q) {
    switch (q.type) {
      case QType.text:
      case QType.longText:
        final long = q.type == QType.longText;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(p, q.label),
          _field(p,
              hint: q.hint,
              controller: _c(q.key, _s(q.key)),
              minLines: long ? 3 : 1,
              maxLines: long ? 8 : 3,
              email: q.email,
              onChanged: (s) => setState(() => _v[q.key] = s)),
        ]);
      case QType.one:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(p, q.label),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final o in q.options)
              _choice(p, o, _s(q.key) == o,
                  () => setState(() => _v[q.key] = _s(q.key) == o ? '' : o)),
          ]),
          if (q.extraLabel != null && _s(q.key).isNotEmpty) ...[
            const SizedBox(height: 8),
            _field(p,
                hint: q.extraLabel,
                controller: _c('${q.key}_x', _s('${q.key}_x')),
                onChanged: (s) => setState(() => _v['${q.key}_x'] = s)),
          ],
        ]);
      case QType.many:
        final sel = [for (final e in (_v[q.key] as List? ?? const [])) '$e'];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(p, '${q.label} (можно несколько)'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final o in q.options)
              _choice(p, o, sel.contains(o), () {
                setState(() {
                  final next = [...sel];
                  next.contains(o) ? next.remove(o) : next.add(o);
                  _v[q.key] = next;
                });
              }),
          ]),
        ]);
      case QType.yesNo:
      case QType.yesNoComment:
        return _yesNo(p, q);
      case QType.grid:
        return _grid(p, q);
    }
  }

  Widget _yesNo(FPal p, FormQuestion q) {
    final withComment = q.type == QType.yesNoComment;
    final data = _v[q.key] is Map
        ? Map<String, dynamic>.from(_v[q.key] as Map)
        : <String, dynamic>{};
    String answer(int i) {
      final d = data['$i'];
      return d is Map ? '${d['a'] ?? ''}' : (d is String ? d : '');
    }

    void setAnswer(int i, String a) {
      final cur = answer(i);
      final d = data['$i'];
      final comment = d is Map ? '${d['c'] ?? ''}' : '';
      setState(() {
        if (cur == a) {
          data.remove('$i');
        } else {
          data['$i'] = {'a': a, 'c': comment};
        }
        _v[q.key] = data;
      });
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(p, q.label),
      for (var i = 0; i < q.rows.length; i++) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(q.rows[i], style: fts(p, size: 14.5, w: FontWeight.w500))),
              const SizedBox(width: 8),
              _choice(p, 'Да', answer(i) == 'Да', () => setAnswer(i, 'Да'), small: true),
              const SizedBox(width: 6),
              _choice(p, 'Нет', answer(i) == 'Нет', () => setAnswer(i, 'Нет'), small: true),
            ]),
            if (withComment && answer(i).isNotEmpty) ...[
              const SizedBox(height: 6),
              _field(p,
                  hint: 'Комментарий',
                  controller: _c('${q.key}|c|$i', () {
                    final d = data['$i'];
                    return d is Map ? '${d['c'] ?? ''}' : '';
                  }()),
                  onChanged: (s) => setState(() {
                        final d = data['$i'];
                        data['$i'] = {'a': d is Map ? d['a'] : answer(i), 'c': s};
                        _v[q.key] = data;
                      })),
            ],
          ]),
        ),
      ],
    ]);
  }

  List<Map<String, dynamic>> _gridRows(FormQuestion q) {
    final raw = _v[q.key];
    final rows = raw is List
        ? [for (final r in raw) r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{}]
        : <Map<String, dynamic>>[];
    if (rows.isEmpty) rows.add({});
    return rows;
  }

  void _clearGridControllers(String key) {
    final ids = _ctl.keys.where((k) => k.startsWith('$key|g|')).toList();
    for (final id in ids) {
      _ctl.remove(id); // не dispose: поля ещё на экране до перестройки
    }
  }

  Widget _grid(FPal p, FormQuestion q) {
    final rows = _gridRows(q);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(q.label, style: fts(p, size: 13, w: FontWeight.w500, color: p.mut))),
        Material(
          color: p.card2,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => setState(() {
              _v[q.key] = [...rows, <String, dynamic>{}];
            }),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, size: 16, color: p.ink),
                const SizedBox(width: 4),
                Text('Строка', style: fts(p, size: 13, w: FontWeight.w700)),
              ]),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      for (var r = 0; r < rows.length; r++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('Номер ${r + 1}', style: fts(p, size: 13, w: FontWeight.w700))),
                if (rows.length > 1)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() {
                      final next = [...rows]..removeAt(r);
                      _clearGridControllers(q.key);
                      _v[q.key] = next;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, size: 18, color: p.mut),
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              LayoutBuilder(builder: (ctx, c) {
                final w = (c.maxWidth - 8) / 2;
                return Wrap(spacing: 8, runSpacing: 8, children: [
                  for (var i = 0; i < q.columns.length; i++)
                    SizedBox(
                      width: i == 0 || i == q.columns.length - 2 ? c.maxWidth : w,
                      child: _field(p,
                          hint: q.columns[i],
                          controller: _c('${q.key}|g|$r|$i', '${rows[r]['$i'] ?? ''}'),
                          onChanged: (s) => setState(() {
                                final next = _gridRows(q);
                                next[r]['$i'] = s;
                                _v[q.key] = next;
                              })),
                    ),
                ]);
              }),
            ]),
          ),
        ),
    ]);
  }

  // ---------- Шаги ----------

  void _goStep(int i) {
    final last = _t.sections.length - 1;
    FocusScope.of(context).unfocus();
    setState(() => _step = i.clamp(0, last).toInt());
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  // ---------- Экран ----------

  @override
  Widget build(BuildContext context) {
    final p = FPal.of(context);
    final n = _answered;
    final total = _t.questionCount;
    final last = _step == _t.sections.length - 1;
    final sec = _t.sections[_step];
    final canSave = _title.isNotEmpty;
    return FormsTheme(
      child: PopScope(
        // Кнопка «назад» на втором и следующих шагах возвращает на шаг назад.
        canPop: _step == 0 || _closing,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            _onLeave();
          } else {
            _goStep(_step - 1);
          }
        },
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: Row(children: [
                  FRoundBtn(Icons.arrow_back_rounded, () => Navigator.maybePop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Шаг ${_step + 1} из ${_t.sections.length} · ${_t.name}',
                          style: fts(p, size: 13, w: FontWeight.w500, color: p.mut)),
                      Text(sec.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.5,
                              color: p.ink)),
                      if (sec.note != null)
                        Text(sec.note!,
                            style: fts(p, size: 12.5, w: FontWeight.w500, color: p.run)),
                    ]),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(children: [
                  for (var i = 0; i < _t.sections.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _goStep(i),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= _step ? p.accent : p.off,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Заполнено $n из $total',
                      style: fts(p, size: 12.5, w: FontWeight.w500, color: p.mut)),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    if (_step == 0 && _t.intro != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                        child: Text(_t.intro!,
                            style: fts(p, size: 13, w: FontWeight.w500, color: p.mut)),
                      ),
                    ],
                    FCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        for (var j = 0; j < sec.questions.length; j++)
                          Padding(
                            padding: EdgeInsets.only(bottom: j == sec.questions.length - 1 ? 0 : 16),
                            child: _question(p, sec.questions[j]),
                          ),
                      ]),
                    ),
                    if (last && _t.footnote != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
                        child: Text(_t.footnote!,
                            style: fts(p, size: 12.5, w: FontWeight.w500, color: p.mut)),
                      ),
                    if (last && !canSave)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 14, 4, 0),
                        child: Text('Укажите название на первом шаге, чтобы сохранить анкету.',
                            style: fts(p, size: 12.5, w: FontWeight.w500, color: p.bad)),
                      ),
                  ],
                ),
              ),
            ]),
          ),
          bottomNavigationBar: Container(
            color: p.bg,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: Row(children: [
                if (_step > 0) ...[
                  Expanded(
                    flex: 2,
                    child: FPill('Назад', quiet: true, onTap: () => _goStep(_step - 1)),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 3,
                  child: last
                      ? FPill('Сохранить анкету', busy: _busy, onTap: canSave ? _save : null)
                      : FPill('Далее', onTap: () => _goStep(_step + 1)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
