import 'package:flutter/material.dart';

import 'pal.dart';

/// Знак VAYGO: тёмная плитка Midnight и белые стрелки вперёд.
/// Картинка: assets/icon/logo_mark.png (прозрачный фон).
class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final p = FPal.of(context);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0D),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: p.line),
      ),
      child: Image.asset('assets/icon/logo_mark.png', filterQuality: FilterQuality.medium),
    );
  }
}
