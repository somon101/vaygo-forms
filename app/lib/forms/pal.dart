import 'package:flutter/material.dart';

/// Оформление раздела «Анкеты» взято из app-starter: тёмная тема Midnight,
/// светлая тоже, белый акцент, карточки без теней, кнопки-таблетки.
/// Тема следует настройке телефона.
@immutable
class FPal {
  final Color bg, card, card2, ink, mut, line, accent, onAccent;
  final Color ok, bad, run, info, off;
  const FPal({
    required this.bg,
    required this.card,
    required this.card2,
    required this.ink,
    required this.mut,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.ok,
    required this.bad,
    required this.run,
    required this.info,
    required this.off,
  });

  static const dark = FPal(
    bg: Color(0xFF0B0B0D),
    card: Color(0xFF17171A),
    card2: Color(0xFF1D1D21),
    ink: Color(0xFFF4F5F7),
    mut: Color(0xFF8D929C),
    line: Color(0x14FFFFFF),
    accent: Color(0xFFF4F5F7),
    onAccent: Color(0xFF0B0C0E),
    ok: Color(0xFF3DDC7A),
    bad: Color(0xFFFF6B7D),
    run: Color(0xFFFFD25F),
    info: Color(0xFF6FB0FF),
    off: Color(0xFF3A3A40),
  );

  static const light = FPal(
    bg: Color(0xFFECECEF),
    card: Color(0xFFFFFFFF),
    card2: Color(0xFFF4F4F6),
    ink: Color(0xFF0D0F12),
    mut: Color(0xFF6B7280),
    line: Color(0x170D0F12),
    accent: Color(0xFF0D0F12),
    onAccent: Color(0xFFFFFFFF),
    ok: Color(0xFF16A34A),
    bad: Color(0xFFD7334A),
    run: Color(0xFFC88A00),
    info: Color(0xFF2F6BFF),
    off: Color(0xFFC9CBD3),
  );

  static FPal of(BuildContext c) =>
      MediaQuery.platformBrightnessOf(c) == Brightness.light ? light : dark;
}

/// Тема для экранов анкет: фон, поля и всплывающие сообщения в стиле app-starter.
class FormsTheme extends StatelessWidget {
  final Widget child;
  const FormsTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = FPal.of(context);
    final b = p == FPal.light ? Brightness.light : Brightness.dark;
    return Theme(
      data: ThemeData(
        brightness: b,
        useMaterial3: true,
        scaffoldBackgroundColor: p.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: p.info, brightness: b)
            .copyWith(surface: p.card, onSurface: p.ink, primary: p.accent, onPrimary: p.onAccent),
        textSelectionTheme: TextSelectionThemeData(cursorColor: p.ink),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: p.card,
          contentTextStyle: TextStyle(color: p.ink, fontWeight: FontWeight.w600),
          shape: const StadiumBorder(),
        ),
      ),
      child: child,
    );
  }
}

TextStyle fts(FPal p, {double size = 15, FontWeight w = FontWeight.w600, Color? color}) =>
    TextStyle(fontSize: size, fontWeight: w, color: color ?? p.ink);

/// Главная кнопка-таблетка (белая) или тихая.
class FPill extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool quiet, busy, danger;
  const FPill(this.text,
      {super.key, this.icon, this.onTap, this.quiet = false, this.busy = false, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final p = FPal.of(context);
    final off = onTap == null && !busy;
    final bg = off ? p.card2 : danger ? p.bad.withValues(alpha: 0.14) : (quiet ? p.card2 : p.accent);
    final fg = off ? p.mut : danger ? p.bad : (quiet ? p.ink : p.onAccent);
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: busy ? null : onTap,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            if (busy)
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
            else if (icon != null)
              Icon(icon, size: 18, color: fg),
            if (busy || icon != null) const SizedBox(width: 8),
            Flexible(child: Text(text, style: fts(p, size: 15, w: FontWeight.w800, color: fg))),
          ]),
        ),
      ),
    );
  }
}

/// Маленькая белая кнопка «+ слово» вверху справа.
class FAddBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const FAddBtn(this.text, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = FPal.of(context);
    return Material(
      color: p.accent,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.add_rounded, size: 18, color: p.onAccent),
            const SizedBox(width: 4),
            Text(text, style: fts(p, size: 14, w: FontWeight.w800, color: p.onAccent)),
          ]),
        ),
      ),
    );
  }
}

/// Карточка: радиус 20, рамка 1 px, без теней.
class FCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const FCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    final p = FPal.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: child,
    );
  }
}

/// Круглая кнопка в шапке (назад, закрыть).
class FRoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const FRoundBtn(this.icon, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = FPal.of(context);
    return Material(
      color: p.card,
      shape: CircleBorder(side: BorderSide(color: p.line)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 20, color: p.ink)),
      ),
    );
  }
}

/// Метка состояния: цвет по смыслу.
class FChip extends StatelessWidget {
  final String text;
  final Color? color;
  const FChip(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final p = FPal.of(context);
    final c = color ?? p.mut;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color == null ? p.card2 : c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: fts(p, size: 12, w: FontWeight.w700, color: c)),
    );
  }
}

/// Плавающее окно: отступ 16, все углы скруглены 28, крестик справа вверху.
Future<T?> showFloatingWindow<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Закрыть',
    barrierColor: const Color(0x8C000000),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, _, _) => FormsTheme(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
            child: Material(
              color: FPal.of(ctx).card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: FPal.of(ctx).line),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: builder(ctx),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: child,
    ),
  );
}

/// Шапка окна: ручка по центру, крестик справа.
class FWindowHead extends StatelessWidget {
  const FWindowHead({super.key});

  @override
  Widget build(BuildContext context) {
    final p = FPal.of(context);
    return SizedBox(
      height: 40,
      child: Stack(alignment: Alignment.center, children: [
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: p.off, borderRadius: BorderRadius.circular(2))),
        Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: p.card2,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: SizedBox(width: 36, height: 36, child: Icon(Icons.close_rounded, size: 18, color: p.ink)),
            ),
          ),
        ),
      ]),
    );
  }
}
