import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'templates.dart';

/// PDF анкеты по шаблону: шапка VAYGO, разделы, ответы, галочки ☒/☐, таблицы.
class FormPdf {
  static const _navy = PdfColor.fromInt(0xFF0B1B4D);
  static const _grey = PdfColor.fromInt(0xFF6B7280);
  static const _line = PdfColor.fromInt(0xFF9CA3AF);
  static const _band = PdfColor.fromInt(0xFFE8ECF7);
  static const _headCell = PdfColor.fromInt(0xFFF3F4F6);

  static String _s(Map<String, dynamic> v, String k) {
    final x = v[k];
    return x is String ? x.trim() : '';
  }

  static pw.Widget _t(String s,
          {double size = 9.5, bool bold = false, bool italic = false, PdfColor? color}) =>
      pw.Text(s,
          style: pw.TextStyle(
              fontSize: size,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
              color: color));

  static pw.Widget _cell(pw.Widget child, {bool head = false, pw.Alignment? align}) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        color: head ? _headCell : null,
        alignment: align,
        child: child,
      );

  static String _box(bool on) => on ? '☒' : '☐';

  static List<pw.Widget> _question(FormQuestion q, Map<String, dynamic> v) {
    final out = <pw.Widget>[];
    switch (q.type) {
      case QType.text:
        final x = _s(v, q.key);
        out.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.RichText(
            text: pw.TextSpan(style: const pw.TextStyle(fontSize: 9.5), children: [
              pw.TextSpan(text: '${q.label}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: x.isEmpty ? '______________________________' : x),
            ]),
          ),
        ));
      case QType.longText:
        final x = _s(v, q.key);
        out.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4, bottom: 3),
          child: _t(q.label, bold: true),
        ));
        out.add(pw.Container(
          width: double.infinity,
          constraints: const pw.BoxConstraints(minHeight: 36),
          padding: const pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _line, width: 0.5)),
          child: _t(x.isEmpty ? '' : x),
        ));
      case QType.one:
      case QType.many:
        final sel = q.type == QType.one
            ? [if (_s(v, q.key).isNotEmpty) _s(v, q.key)]
            : [for (final e in (v[q.key] as List? ?? const [])) '$e'];
        out.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4, bottom: 3),
          child: _t(q.label, bold: true),
        ));
        out.add(pw.Wrap(spacing: 14, runSpacing: 3, children: [
          for (final o in q.options) _t('${_box(sel.contains(o))} $o'),
        ]));
        if (q.extraLabel != null) {
          final x = _s(v, '${q.key}_x');
          out.add(pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.RichText(
              text: pw.TextSpan(style: const pw.TextStyle(fontSize: 9.5), children: [
                pw.TextSpan(text: '${q.extraLabel}: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.TextSpan(text: x.isEmpty ? '____________________' : x),
              ]),
            ),
          ));
        }
      case QType.yesNo:
      case QType.yesNoComment:
        final withComment = q.type == QType.yesNoComment;
        final data = v[q.key] is Map ? Map<String, dynamic>.from(v[q.key] as Map) : <String, dynamic>{};
        out.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4, bottom: 3),
          child: _t(q.label, bold: true),
        ));
        String answer(int i) {
          final d = data['$i'];
          if (d is Map) return '${d['a'] ?? ''}';
          return d is String ? d : '';
        }
        String comment(int i) {
          final d = data['$i'];
          return d is Map ? '${d['c'] ?? ''}' : '';
        }
        out.add(pw.Table(
          border: pw.TableBorder.all(color: _line, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FixedColumnWidth(34),
            2: const pw.FixedColumnWidth(34),
            if (withComment) 3: const pw.FlexColumnWidth(3),
          },
          children: [
            pw.TableRow(children: [
              _cell(_t(withComment ? 'Позиция' : 'Функция', bold: true), head: true),
              _cell(_t('Да', bold: true), head: true, align: pw.Alignment.center),
              _cell(_t('Нет', bold: true), head: true, align: pw.Alignment.center),
              if (withComment) _cell(_t('Комментарий', bold: true), head: true),
            ]),
            for (var i = 0; i < q.rows.length; i++)
              pw.TableRow(children: [
                _cell(_t(q.rows[i])),
                _cell(_t(_box(answer(i) == 'Да')), align: pw.Alignment.center),
                _cell(_t(_box(answer(i) == 'Нет')), align: pw.Alignment.center),
                if (withComment) _cell(_t(comment(i))),
              ]),
          ],
        ));
      case QType.grid:
        final rows = <Map<String, dynamic>>[
          for (final r in (v[q.key] as List? ?? const []))
            if (r is Map && r.values.any((e) => '$e'.trim().isNotEmpty))
              Map<String, dynamic>.from(r),
        ];
        final shown = rows.isEmpty ? [<String, dynamic>{}, <String, dynamic>{}, <String, dynamic>{}] : rows;
        final n = q.columns.length;
        out.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4, bottom: 3),
          child: _t(q.label, bold: true),
        ));
        out.add(pw.Table(
          border: pw.TableBorder.all(color: _line, width: 0.5),
          columnWidths: {
            for (var i = 0; i < n; i++)
              i: pw.FlexColumnWidth(i == 0 || i == n - 2 ? 2 : 1.2),
          },
          children: [
            pw.TableRow(children: [
              for (final c in q.columns) _cell(_t(c, bold: true, size: 8.5), head: true),
            ]),
            for (final r in shown)
              pw.TableRow(children: [
                for (var i = 0; i < n; i++) _cell(_t('${r['$i'] ?? ''}', size: 9)),
              ]),
          ],
        ));
    }
    return out;
  }

  static Future<Uint8List> build(FormTemplate t, Map<String, dynamic> v) async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'));
    final doc = pw.Document(
      title: t.docTitle,
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );
    final date = DateFormat('d MMMM yyyy', 'ru').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 36),
        footer: (ctx) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _t('VAYGO · $date', size: 8, color: _grey),
            _t('Стр. ${ctx.pageNumber} из ${ctx.pagesCount}', size: 8, color: _grey),
          ],
        ),
        build: (ctx) => [
          pw.Text('VAYGO',
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold, color: _navy, letterSpacing: 2)),
          pw.SizedBox(height: 6),
          _t(t.docTitle, size: 15, bold: true),
          pw.SizedBox(height: 2),
          _t(t.docSubtitle, size: 9.5, color: _grey),
          if (t.intro != null) ...[
            pw.SizedBox(height: 8),
            _t(t.intro!, size: 8.5, italic: true, color: _grey),
          ],
          pw.SizedBox(height: 8),
          for (var i = 0; i < t.sections.length; i++) ...[
            pw.Container(
              width: double.infinity,
              margin: const pw.EdgeInsets.only(top: 10, bottom: 4),
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              color: _band,
              child: _t(
                '${i + 1}. ${t.sections[i].title.toUpperCase()}'
                '${t.sections[i].note == null ? '' : ' — ${t.sections[i].note!.toUpperCase()}'}',
                size: 9.5,
                bold: true,
              ),
            ),
            for (final q in t.sections[i].questions) ..._question(q, v),
          ],
          if (t.footnote != null) ...[
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 6),
              decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: _line, width: 0.5))),
              child: _t(t.footnote!, size: 9, italic: true),
            ),
          ],
          if (t.signatureLine) ...[
            pw.SizedBox(height: 22),
            _t('Подпись: ______________________________', size: 10),
          ],
        ],
      ),
    );
    return doc.save();
  }

  /// Сохраняет PDF в папку приложения и возвращает путь.
  static Future<String> saveFile(String id, Uint8List bytes) async {
    final dir = Directory(p.join((await getApplicationDocumentsDirectory()).path, 'forms'));
    await dir.create(recursive: true);
    final path = p.join(dir.path, '$id.pdf');
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  /// Имя файла для отправки: VAYGO_Тип_Название_2026-11-11.pdf
  static String fileName(FormTemplate t, String title) {
    String slug(String s) => s
        .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final day = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final name = slug(title);
    return 'VAYGO_${slug(t.name)}${name.isEmpty ? '' : '_$name'}_$day.pdf';
  }
}
