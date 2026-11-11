import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../data/form_record.dart';
import 'form_pdf.dart';
import 'pal.dart';
import 'templates.dart';

Future<Uint8List> formPdfBytes(FormTemplate t, FormRecord r) async {
  final path = r.pdfPath;
  if (path != null) {
    final f = File(path);
    if (await f.exists()) return f.readAsBytes();
  }
  return FormPdf.build(t, r.values);
}

/// Окно с файлом анкеты: отправить (почта, мессенджеры) и распечатать.
Future<void> showFormActionsWindow(BuildContext context, FormTemplate t, FormRecord r,
    {bool justSaved = false}) {
  final fileName = FormPdf.fileName(t, r.title);
  return showFloatingWindow(context, builder: (ctx) {
    final p = FPal.of(ctx);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const FWindowHead(),
        Text(justSaved ? 'Анкета сохранена' : (r.title.isEmpty ? t.name : r.title),
            style: fts(p, size: 20, w: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(justSaved ? (r.title.isEmpty ? t.name : r.title) : t.name,
            style: fts(p, size: 13, w: FontWeight.w500, color: p.mut)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.card2, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.picture_as_pdf_outlined, size: 20, color: p.ink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: fts(p, size: 13, w: FontWeight.w600)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        FPill('Отправить',
            icon: Icons.ios_share_rounded,
            onTap: () async => Printing.sharePdf(
                bytes: await formPdfBytes(t, r), filename: fileName)),
        const SizedBox(height: 8),
        FPill('Печать',
            icon: Icons.print_outlined,
            quiet: true,
            onTap: () async => Printing.layoutPdf(
                onLayout: (_) => formPdfBytes(t, r), name: fileName)),
      ]),
    );
  });
}
