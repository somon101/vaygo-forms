import 'dart:convert';

/// Заполненная анкета (по шаблону из lib/forms/templates.dart).
/// Значения хранятся как JSON: ключ поля -> ответ.
class FormRecord {
  final String id;
  String type; // id шаблона
  String title;
  Map<String, dynamic> values;
  bool done; // false — черновик, true — сохранена (есть PDF)
  String? pdfPath;
  DateTime createdAt;
  DateTime updatedAt;

  FormRecord({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.title = '',
    Map<String, dynamic>? values,
    this.done = false,
    this.pdfPath,
  }) : values = values ?? {};

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        'data': jsonEncode(values),
        'status': done ? 'done' : 'draft',
        'pdf_path': pdfPath,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted': 0,
      };

  factory FormRecord.fromMap(Map<String, Object?> m) {
    Map<String, dynamic> data = {};
    try {
      final d = jsonDecode(m['data'] as String? ?? '{}');
      if (d is Map) data = Map<String, dynamic>.from(d);
    } catch (_) {}
    DateTime date(Object? v) =>
        DateTime.fromMillisecondsSinceEpoch((v as int?) ?? 0);
    return FormRecord(
      id: m['id'] as String,
      type: m['type'] as String? ?? '',
      title: m['title'] as String? ?? '',
      values: data,
      done: m['status'] == 'done',
      pdfPath: m['pdf_path'] as String?,
      createdAt: date(m['created_at']),
      updatedAt: date(m['updated_at']),
    );
  }
}
