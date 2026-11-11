import 'package:flutter_test/flutter_test.dart';
import 'package:vaygo_forms/data/form_record.dart';
import 'package:vaygo_forms/forms/templates.dart';

void main() {
  test('шаблоны анкет заполнены и ключи полей не повторяются', () {
    expect(formTemplates.length, 2);
    for (final t in formTemplates) {
      expect(t.sections, isNotEmpty);
      expect(t.questionCount, greaterThan(10));
      final keys = <String>[
        for (final s in t.sections) for (final q in s.questions) q.key,
      ];
      expect(keys.toSet().length, keys.length, reason: 'повтор ключа в ${t.id}');
      expect(templateById(t.id), isNotNull);
    }
  });

  test('запись анкеты сохраняется и читается без потерь', () {
    final r = FormRecord(
      id: 'a1',
      type: 'grocery',
      createdAt: DateTime(2026, 11, 11),
      updatedAt: DateTime(2026, 11, 11),
      title: 'Магазин',
      values: {'name': 'Магазин', 'funcs': {'0': 'Да'}},
      done: true,
    );
    final back = FormRecord.fromMap(r.toMap());
    expect(back.title, 'Магазин');
    expect(back.done, isTrue);
    expect(back.values['name'], 'Магазин');
    expect((back.values['funcs'] as Map)['0'], 'Да');
  });
}
