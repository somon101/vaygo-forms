import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/store.dart';
import 'forms/forms_screen.dart';
import 'forms/pal.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru');
  await FormStore.instance.open();
  runApp(const FormsApp());
}

class FormsApp extends StatelessWidget {
  const FormsApp({super.key});

  ThemeData _theme(FPal p, Brightness b) => ThemeData(
        brightness: b,
        useMaterial3: true,
        scaffoldBackgroundColor: p.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: p.info, brightness: b)
            .copyWith(surface: p.card, onSurface: p.ink, primary: p.accent, onPrimary: p.onAccent),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Анкеты VAYGO',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: _theme(FPal.light, Brightness.light),
      darkTheme: _theme(FPal.dark, Brightness.dark),
      themeMode: ThemeMode.system,
      home: const FormsScreen(),
    );
  }
}
