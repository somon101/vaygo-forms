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
      final emails = [
        for (final s in t.sections) for (final q in s.questions) if (q.email) q,
      ];
      expect(emails.length, 1, reason: 'почта должна быть ровно одна в ${t.id}');
    }
  });

  test('в новый шаблон без почты поле добавляется само', () {
    const bare = FormTemplate(
      id: 'x',
      name: 'Тест',
      subtitle: '',
      docTitle: 'Т',
      docSubtitle: '',
      titleKeys: ['a'],
      sections: [
        FormSection('Раздел', [FormQuestion.text('a', 'Название')]),
      ],
    );
    expect(bare.sections.first.questions.any((q) => q.email), isFalse);
    final fixed = bare.withEmailField();
    expect(fixed.sections.first.questions.first.email, isTrue);
    expect(fixed.sections.first.questions.length, 2);
    // повторный вызов ничего не дублирует
    expect(fixed.withEmailField().sections.first.questions.length, 2);
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
