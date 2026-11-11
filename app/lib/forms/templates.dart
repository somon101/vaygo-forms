/// Шаблоны анкет. Новый тип анкеты = новый [FormTemplate] в [formTemplates].

enum QType { text, longText, one, many, yesNo, yesNoComment, grid }

class FormQuestion {
  final String key;
  final String label;
  final QType type;
  final String? hint; // подсказка в поле
  final List<String> options; // one, many
  final String? extraLabel; // для one: поле «Условия и стоимость» после выбора
  final List<String> rows; // yesNo, yesNoComment
  final List<String> columns; // grid

  const FormQuestion._(this.key, this.label, this.type,
      {this.hint,
      this.options = const [],
      this.extraLabel,
      this.rows = const [],
      this.columns = const []});

  const FormQuestion.text(String key, String label, {String? hint})
      : this._(key, label, QType.text, hint: hint);
  const FormQuestion.longText(String key, String label, {String? hint})
      : this._(key, label, QType.longText, hint: hint);
  const FormQuestion.one(String key, String label, List<String> options,
      {String? extraLabel})
      : this._(key, label, QType.one, options: options, extraLabel: extraLabel);
  const FormQuestion.many(String key, String label, List<String> options)
      : this._(key, label, QType.many, options: options);
  const FormQuestion.yesNo(String key, String label, List<String> rows)
      : this._(key, label, QType.yesNo, rows: rows);
  const FormQuestion.yesNoComment(String key, String label, List<String> rows)
      : this._(key, label, QType.yesNoComment, rows: rows);
  const FormQuestion.grid(String key, String label, List<String> columns)
      : this._(key, label, QType.grid, columns: columns);
}

class FormSection {
  final String title;
  final String? note;
  final List<FormQuestion> questions;
  const FormSection(this.title, this.questions, {this.note});
}

class FormTemplate {
  final String id;
  final String name; // название типа в списке
  final String subtitle; // подпись в списке типов
  final String docTitle; // заголовок PDF
  final String docSubtitle;
  final String? intro; // пояснение «как заполнить»
  final String? footnote; // примечание в конце
  final List<String> titleKeys; // из каких полей берётся название анкеты
  final Map<String, String> prefill; // ключ поля -> поле партнёра
  final String? resultKey; // поле с итогом для метки в списке
  final bool signatureLine; // в конце PDF строка для подписи от руки
  final List<FormSection> sections;

  const FormTemplate({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.docTitle,
    required this.docSubtitle,
    required this.titleKeys,
    required this.sections,
    this.intro,
    this.footnote,
    this.prefill = const {},
    this.resultKey,
    this.signatureLine = false,
  });

  int get questionCount =>
      sections.fold(0, (n, s) => n + s.questions.length);
}

/// Отвечен ли вопрос (для счётчика «Заполнено N из M»).
bool isAnswered(FormQuestion q, Map<String, dynamic> v) {
  final x = v[q.key];
  switch (q.type) {
    case QType.text:
    case QType.longText:
    case QType.one:
      return x is String && x.trim().isNotEmpty;
    case QType.many:
      return x is List && x.isNotEmpty;
    case QType.yesNo:
    case QType.yesNoComment:
      return x is Map && x.length >= q.rows.length;
    case QType.grid:
      return x is List &&
          x.any((r) => r is Map && r.values.any((e) => '$e'.trim().isNotEmpty));
  }
}

// ------------------------------------------------------------------
// Анкета продуктового магазина
// ------------------------------------------------------------------

const groceryForm = FormTemplate(
  id: 'grocery',
  name: 'Продуктовый магазин',
  subtitle: 'Готовность к подключению',
  docTitle: 'АНКЕТА ПРОДУКТОВОГО МАГАЗИНА',
  docSubtitle: 'Для оценки готовности к подключению к платформе',
  titleKeys: ['name'],
  prefill: {'name': 'name', 'addr': 'address', 'phone': 'phone'},
  resultKey: 'res',
  footnote:
      'Важно: магазин самостоятельно собирает и упаковывает заказы. VAYGO организует доставку готовых заказов.',
  sections: [
    FormSection('Данные магазина', [
      FormQuestion.text('name', 'Название магазина'),
      FormQuestion.text('addr', 'Адрес торговой точки'),
      FormQuestion.text('boss', 'ФИО руководителя'),
      FormQuestion.text('phone', 'Телефон для связи'),
      FormQuestion.text('points', 'Количество торговых точек'),
      FormQuestion.text('hours', 'Режим работы'),
    ]),
    FormSection('Собственная сборка заказов', [
      FormQuestion.one('staff',
          'Есть ли сотрудники, которые смогут собирать заказы VAYGO?',
          ['Да, отдельные сборщики', 'Действующие сотрудники']),
      FormQuestion.one('nostaff', 'Если пока нет сотрудников для сборки',
          ['Готовы назначить', 'Не можем обеспечить']),
      FormQuestion.text('staffn', 'Количество сотрудников для сборки'),
      FormQuestion.one('par', 'Возможность одновременной сборки',
          ['1–3 заказа', '4–7 заказов', 'Более 7']),
      FormQuestion.one('time', 'Среднее время сборки одного заказа',
          ['До 10 мин', '10–20 мин', 'Более 20 мин']),
      FormQuestion.yesNo('funcs',
          'Какие задачи магазин готов выполнять самостоятельно?', [
        'Принимать и подтверждать заказы',
        'Проверять наличие товаров',
        'Взвешивать товары и указывать фактическую стоимость',
        'Согласовывать замены отсутствующих товаров',
        'Комплектовать и упаковывать заказ',
        'Передавать готовый заказ курьеру VAYGO',
      ]),
    ], note: 'Обязательное условие'),
    FormSection('Ассортимент и техническая готовность', [
      FormQuestion.text('sku', 'Примерное количество товарных позиций'),
      FormQuestion.text('sys', 'Учётная система (если используется)'),
      FormQuestion.many('have', 'Что уже имеется?',
          ['Электронный каталог', 'Фото товаров', 'Выгрузка цен и остатков']),
      FormQuestion.one('net', 'Устройство с интернетом для приёма заказов',
          ['Да', 'Нет']),
      FormQuestion.text('upd', 'Как часто обновляются цены и остатки'),
    ]),
    FormSection('Готовность к запуску', [
      FormQuestion.many('ready', 'Что готов сделать магазин', [
        'Назначим ответственного за заказы',
        'Будем обновлять ассортимент и цены',
        'Готовы выполнить тестовый заказ перед запуском',
      ]),
      FormQuestion.text('date', 'Ориентировочная дата готовности'),
      FormQuestion.text(
          'contact', 'Контактное лицо по подключению и телефон'),
    ]),
    FormSection('Заполняет менеджер VAYGO', [
      FormQuestion.one('own', 'Наличие собственной сборки',
          ['Подтверждено', 'Нужно организовать', 'Отсутствует']),
      FormQuestion.one('res', 'Результат оценки',
          ['Готов к подключению', 'Требуется подготовка', 'Не готов']),
      FormQuestion.text('mgr', 'Менеджер / дата'),
    ]),
  ],
);

// ------------------------------------------------------------------
// Анкета отеля
// ------------------------------------------------------------------

const hotelForm = FormTemplate(
  id: 'hotel',
  name: 'Отель',
  subtitle: 'Подключение к VAYGO',
  docTitle: 'Анкета отеля для подключения к VAYGO',
  docSubtitle:
      'Заполняется представителем отеля и передаётся менеджеру VAYGO',
  intro:
      'Как заполнить: укажите актуальные данные по объекту размещения, классификации, номеру в реестре, номерному фонду, используемой PMS или иной системе учёта, условиям бронирования, оплате, отменам и контактам. Если какой-то пункт не относится к вашему объекту, напишите «не применяется». К анкете желательно приложить фото, реквизиты и документы, указанные в последнем разделе.',
  titleKeys: ['short', 'full'],
  signatureLine: true,
  prefill: {'full': 'name', 'short': 'name', 'addr': 'address'},
  sections: [
    FormSection('Данные об объекте размещения', [
      FormQuestion.text('full', 'Полное название объекта'),
      FormQuestion.text('short', 'Короткое название для карточки'),
      FormQuestion.one('format', 'Формат объекта', [
        'отель', 'гостиница', 'апарт-отель', 'гостевой дом', 'база отдыха', 'другое',
      ]),
      FormQuestion.text('addr', 'Адрес'),
      FormQuestion.text('geo', 'Ссылка на геолокацию'),
      FormQuestion.text('rooms', 'Количество номеров'),
      FormQuestion.one('stars', 'Звёздность отеля', [
        'без звёзд', '1 звезда', '2 звезды', '3 звезды', '4 звезды', '5 звёзд',
      ]),
      FormQuestion.text('reg', 'Номер в реестре средств размещения',
          hint: 'Номер записи в реестре, если присвоен'),
      FormQuestion.text('regdate', 'Дата внесения в реестр'),
      FormQuestion.text('classto', 'Срок действия классификации'),
      FormQuestion.one('cat', 'Категория объекта',
          ['эконом', 'средний сегмент', 'бизнес', 'премиум', 'другое']),
      FormQuestion.longText('about', 'Краткое описание',
          hint: '2–4 предложения об объекте, локации и преимуществах'),
      FormQuestion.longText('near', 'Ориентиры рядом',
          hint: 'Аэропорт, центр, мечеть, вокзал, достопримечательности и др.'),
    ]),
    FormSection('Номера и цены', [
      FormQuestion.grid('types', 'Типы номеров', [
        'Тип номера', 'Кол-во', 'Гостей', 'Кровати', 'Что включено', 'Цена за ночь',
      ]),
    ]),
    FormSection('Условия проживания', [
      FormQuestion.text('in', 'Время заезда'),
      FormQuestion.text('out', 'Время выезда'),
      FormQuestion.one('early', 'Ранний заезд', ['есть', 'нет'],
          extraLabel: 'Условия и стоимость'),
      FormQuestion.one('late', 'Поздний выезд', ['есть', 'нет'],
          extraLabel: 'Условия и стоимость'),
      FormQuestion.text('minstay', 'Минимальный срок проживания'),
      FormQuestion.text('kids', 'Размещение с детьми',
          hint: 'Возраст бесплатно, доп. место, детская кровать'),
      FormQuestion.one('pets', 'Домашние животные', ['можно', 'нельзя'],
          extraLabel: 'Условия и стоимость'),
      FormQuestion.one('deposit', 'Залог', ['есть', 'нет'],
          extraLabel: 'Размер и условия возврата'),
      FormQuestion.text('limits', 'Ограничения',
          hint: 'Возраст, документы, тишина, курение, вечеринки, группы'),
    ]),
    FormSection('Бронирование, оплата и отмена', [
      FormQuestion.one('confirm', 'Как подтверждается бронь',
          ['автоматически', 'вручную отелем', 'по запросу']),
      FormQuestion.text('who', 'Кто подтверждает бронь',
          hint: 'ФИО, должность, телефон, график связи'),
      FormQuestion.text('answer', 'Срок ответа на бронь',
          hint: 'Например: до 15 минут, до 1 часа, в рабочее время'),
      FormQuestion.one('pay', 'Оплата через VAYGO', ['принимаем', 'нужно обсудить']),
      FormQuestion.one('prepay', 'Предоплата', ['100 процентов', 'частичная', 'другое']),
      FormQuestion.text('extra', 'Доплаты на месте',
          hint: 'Завтрак, парковка, доп. место, ранний заезд, трансфер, мини-бар'),
      FormQuestion.text('cancel', 'Бесплатная отмена',
          hint: 'До какого срока гость может отменить без штрафа'),
      FormQuestion.text('fine', 'Штраф при поздней отмене',
          hint: 'Размер штрафа или условия удержания'),
      FormQuestion.text('noshow', 'Неявка гостя', hint: 'Условия no-show'),
      FormQuestion.text('hcancel', 'Отмена со стороны отеля',
          hint: 'Причины, порядок уведомления, кто отвечает за гостя'),
    ]),
    FormSection('Система учёта и техническая готовность', [
      FormQuestion.text('pms', 'Используемая PMS',
          hint: 'Название системы. Если PMS нет, напишите «не используется»'),
      FormQuestion.text('cm', 'Channel Manager',
          hint: 'Название системы. Если нет, напишите «не используется»'),
      FormQuestion.text('crm', 'CRM или иной учёт',
          hint: 'Excel, журнал, внутренняя система, другое'),
      FormQuestion.one('integr', 'Интеграция возможна', [
        'да', 'нет', 'нужно уточнить у разработчика или поставщика PMS',
      ]),
      FormQuestion.text('priceby', 'Кто обновляет цены',
          hint: 'ФИО, должность, телефон'),
      FormQuestion.text('availby', 'Кто обновляет наличие номеров',
          hint: 'ФИО, должность, телефон'),
      FormQuestion.one('freq', 'Как часто обновляются остатки',
          ['в реальном времени', 'ежедневно', 'по запросу', 'другое']),
      FormQuestion.text('stop', 'Стоп-продажи',
          hint: 'Кто и как закрывает даты, когда номеров нет'),
      FormQuestion.text('test', 'Тестовое бронирование',
          hint: 'Кто будет участвовать в тесте со стороны отеля'),
    ]),
    FormSection('Услуги и удобства', [
      FormQuestion.yesNoComment('services', 'Услуги', [
        'Завтрак', 'Ресторан или кафе', 'Wi-Fi', 'Парковка', 'Трансфер',
        'Прачечная', 'Конференц-зал', 'Доступная среда', 'Халяль-питание',
      ]),
    ]),
    FormSection('Контакты для работы', [
      FormQuestion.text('c1', 'Основной контакт',
          hint: 'ФИО, должность, телефон, WhatsApp, email'),
      FormQuestion.text('c2', 'Контакт по бронированиям',
          hint: 'ФИО, телефон, график связи'),
      FormQuestion.text('c3', 'Контакт бухгалтерии', hint: 'ФИО, телефон, email'),
      FormQuestion.many('notify', 'Канал уведомлений',
          ['кабинет VAYGO', 'WhatsApp', 'email', 'телефон']),
      FormQuestion.text('c4', 'Контакт по техническим вопросам',
          hint: 'ФИО, телефон, email'),
    ]),
    FormSection('Документы и реквизиты', [
      FormQuestion.text('legal', 'Юридическое лицо или ИП', hint: 'Наименование'),
      FormQuestion.text('inn', 'ИНН'),
      FormQuestion.text('ogrn', 'ОГРН или ОГРНИП'),
      FormQuestion.text('tax', 'Система налогообложения'),
      FormQuestion.text('bank', 'Банковские реквизиты',
          hint: 'Расчётный счёт, банк, БИК, корреспондентский счёт'),
      FormQuestion.text('signer', 'Кто подписывает договор',
          hint: 'ФИО, должность, основание полномочий'),
      FormQuestion.text('right', 'Право на объект',
          hint: 'Собственность, аренда, управление, иное основание'),
      FormQuestion.text('classdoc', 'Документ о классификации',
          hint: 'Номер, дата, категория звёздности, срок действия'),
      FormQuestion.text('permits', 'Иные разрешительные документы',
          hint: 'Пожарная безопасность, санитарные документы, иные документы'),
    ]),
    FormSection('Что нужно приложить к анкете', [
      FormQuestion.yesNoComment('attach', 'Материалы', [
        'Реквизиты организации или ИП', 'Фото фасада и входа',
        'Фото ресепшена и общих зон', 'Фото каждого типа номера',
        'Фото санузлов', 'Фото завтрака, ресторана или кафе',
        'Логотип при наличии', 'Документ о классификации',
        'Подтверждение номера в реестре', 'Документы по объекту',
      ]),
    ]),
    FormSection('Дополнительная информация', [
      FormQuestion.longText('more', 'Дополнительная информация от представителя отеля'),
      FormQuestion.text('repname', 'ФИО представителя'),
      FormQuestion.text('reppos', 'Должность'),
      FormQuestion.text('repdate', 'Дата заполнения'),
    ]),
  ],
);

const formTemplates = <FormTemplate>[groceryForm, hotelForm];

FormTemplate? templateById(String id) {
  for (final t in formTemplates) {
    if (t.id == id) return t;
  }
  return null;
}
