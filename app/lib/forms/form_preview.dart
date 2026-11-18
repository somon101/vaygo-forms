import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'pal.dart';

/// Предварительный просмотр анкеты перед отправкой: страницы PDF,
/// внизу «Отправить» и «Печать».
Future<void> showFormPreview(
  BuildContext context, {
  required String title,
  required Uint8List bytes,
  required String fileName,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FormsTheme(
        child: FormPreviewScreen(title: title, bytes: bytes, fileName: fileName),
      ),
    ),
  );
}

class FormPreviewScreen extends StatelessWidget {
  final String title;
  final Uint8List bytes;
  final String fileName;
  const FormPreviewScreen({
    super.key,
    required this.title,
    required this.bytes,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    final p = FPal.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Row(children: [
              FRoundBtn(Icons.arrow_back_rounded, () => Navigator.maybePop(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Предварительный просмотр',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.4,
                          color: p.ink)),
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fts(p, size: 13, w: FontWeight.w500, color: p.mut)),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: PdfPreview(
              build: (_) async => bytes,
              useActions: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName: fileName,
              scrollViewDecoration: BoxDecoration(color: p.card2),
            ),
          ),
          Container(
            color: p.bg,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                FPill('Отправить',
                    icon: Icons.ios_share_rounded,
                    onTap: () => Printing.sharePdf(bytes: bytes, filename: fileName)),
                const SizedBox(height: 8),
                FPill('Печать',
                    icon: Icons.print_outlined,
                    quiet: true,
                    onTap: () => Printing.layoutPdf(
                        onLayout: (_) async => bytes, name: fileName)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
