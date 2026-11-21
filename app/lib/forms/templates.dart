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
  final bool email; // поле электронной почты: своя клавиатура и проверка

  const FormQuestion._(this.key, this.label, this.type,
      {this.hint,
      this.options = const [],
      this.extraLabel,
      this.rows = const [],
      this.columns = const [],
      this.email = false});

  const FormQuestion.text(String key, String label, {String? hint})
      : this._(key, label, QType.text, hint: hint);
  /// Электронная почта для уведомлений: нужна при подключении партнёра.
  const FormQuestion.email(String key, String label, {String? hint})
      : this._(key, label, QType.text, hint: hint, email: true);
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

  /// Гарантирует поле электронной почты: если в шаблоне его нет, оно
  /// добавляется первым вопросом первого раздела. Так у любой будущей анкеты
  /// есть почта для уведомлений при подключении партнёра.
  FormTemplate withEmailField() {
    final has = sections.any((s) => s.questions.any((q) => q.email));
    if (has || sections.isEmpty) return this;
    final first = sections.first;
    return FormTemplate(
      id: id,
      name: name,
      subtitle: subtitle,
      docTitle: docTitle,
      docSubtitle: docSubtitle,
      titleKeys: titleKeys,
      intro: intro,
      footnote: footnote,
      prefill: prefill,
      resultKey: resultKey,
      signatureLine: signatureLine,
      sections: [
        FormSection(first.title, [emailQuestion, ...first.questions],
            note: first.note),
        ...sections.skip(1),
      ],
    );
  }
}

/// Стандартное поле электронной почты для уведомлений (есть в каждой анкете).
const emailQuestion = FormQuestion.email(
    'email', 'Электронная почта для уведомлений',
    hint: 'name@example.com');

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
      FormQuestion.email('email', 'Электронная почта для уведомлений',
          hint: 'name@example.com'),
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
      FormQuestion.email('email', 'Электронная почта для уведомлений',
          hint: 'name@example.com'),
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

// ------------------------------------------------------------------
// Анкета аптечного партнёра
// ------------------------------------------------------------------

const pharmacyForm = FormTemplate(
  id: 'pharmacy',
  name: 'Аптека',
  subtitle: 'Подключение аптеки или аптечной сети',
  docTitle: 'АНКЕТА АПТЕЧНОГО ПАРТНЁРА',
  docSubtitle:
      'Для подключения аптеки или аптечной сети к мультисервисной платформе VAYGO',
  intro:
      'Условия VAYGO: комиссия с аптеки — 0%; подключение и ежемесячная плата — 0 ₽. Условия доставки и расчётов закрепляются договором.',
  titleKeys: ['name', 'legal'],
  prefill: {'name': 'name', 'addr': 'address', 'phone': 'phone'},
  sections: [
    FormSection('Сведения об аптеке', [
      FormQuestion.text('name', 'Торговое наименование'),
      FormQuestion.text('legal', 'Полное наименование юрлица / ИП'),
      FormQuestion.text('inn', 'ИНН'),
      FormQuestion.text('kpp', 'КПП (если есть)'),
      FormQuestion.text('ogrn', 'ОГРН / ОГРНИП'),
      FormQuestion.text('phone', 'Телефон аптеки'),
      FormQuestion.text('addr', 'Юридический адрес'),
      FormQuestion.text('site', 'Сайт / социальные сети'),
      FormQuestion.text('contact', 'Контактное лицо, должность'),
      FormQuestion.text('contactphone', 'Телефон контакта'),
      FormQuestion.email('email', 'Электронная почта для уведомлений',
          hint: 'name@example.com'),
      FormQuestion.one('format', 'Формат работы', ['Одна аптека', 'Сеть аптек']),
    ]),
    FormSection('Лицензии и разрешения', [
      FormQuestion.text('lic', 'Фармлицензия: номер, дата'),
      FormQuestion.text('licholder', 'Лицензиат / адрес(а) деятельности'),
      FormQuestion.one('rx', 'Разрешение Росздравнадзора на дистанционную торговлю лекарствами',
          ['Есть', 'Нет', 'В оформлении']),
      FormQuestion.text('rxnum', 'Номер / дата разрешения (если есть)'),
      FormQuestion.many('sell', 'Что планируется размещать в VAYGO', [
        'Безрецептурные лекарства', 'Аптечные товары (не лекарства)',
      ]),
    ], note:
        'Для дистанционной продажи лекарств нужны лицензия и разрешение Росздравнадзора. Рецептурные препараты и запрещённые категории в онлайн-заказ не включаются.'),
    FormSection('Точки выдачи и график', [
      FormQuestion.text('branches', 'Количество филиалов'),
      FormQuestion.longText('points', 'Адрес(а), ориентир, вход',
          hint: 'Для каждого филиала: адрес, ориентир, вход'),
      FormQuestion.text('hours', 'Режим работы / праздничные дни'),
      FormQuestion.text('branchphone', 'Контактный телефон филиала(ов)'),
    ], note:
        'Если филиалов несколько, приложите список адресов, режимов работы, телефонов и лицензированных мест деятельности.'),
    FormSection('Ассортимент и каталог', [
      FormQuestion.many('cats', 'Категории товаров', [
        'Лекарства без рецепта', 'Медицинские изделия', 'БАД', 'Косметика и уход',
      ]),
      FormQuestion.many('cats2', 'Дополнительные категории', [
        'Товары для детей', 'Гигиена', 'Прочее',
      ]),
      FormQuestion.text('catlimits', 'Прочие категории / ограничения'),
      FormQuestion.text('sku', 'Ориентировочное число SKU'),
      FormQuestion.many('catsrc', 'Источник каталога', [
        'Учётная система / API', 'Excel/CSV/XML', 'Ручная загрузка',
      ]),
      FormQuestion.text('priceby', 'Кто обновляет цены и остатки'),
      FormQuestion.one('stockfreq', 'Актуализация остатков',
          ['Автоматически', 'Несколько раз в день', 'Вручную']),
      FormQuestion.one('photo', 'Фото товаров и описания',
          ['Предоставляет аптека', 'Есть у поставщика', 'Нужна загрузка']),
      FormQuestion.one('marking', 'Есть учёт обязательной маркировки и МДЛП',
          ['Да', 'Нет', 'Не применяется']),
    ], note:
        'Заполняется ответственным сотрудником аптеки совместно с менеджером VAYGO.'),
    FormSection('Программы и интеграция', [
      FormQuestion.text('prog', 'Название учётной / аптечной программы'),
      FormQuestion.text('progver', 'Версия программы / разработчик'),
      FormQuestion.one('connect', 'Способ подключения к VAYGO',
          ['API / интеграция', 'Через кабинет VAYGO', 'Пока не определено']),
      FormQuestion.text('techcontact', 'Технический контакт (ФИО, телефон)'),
      FormQuestion.text('techemail', 'Email технического специалиста',
          hint: 'name@example.com'),
      FormQuestion.many('sync', 'Что можно синхронизировать',
          ['Товары и цены', 'Остатки', 'Статусы заказов']),
      FormQuestion.longText('integlimits', 'Особенности интеграции / ограничения'),
    ]),
    FormSection('Приём, сборка и выдача заказов', [
      FormQuestion.text('acceptby', 'Кто принимает онлайн-заказы'),
      FormQuestion.text('confirmtime', 'Время подтверждения'),
      FormQuestion.text('assembletime', 'Время сборки'),
      FormQuestion.one('acceptmode', 'Приём заказов',
          ['В часы работы', 'Круглосуточно с обработкой в рабочее время']),
      FormQuestion.many('handover', 'Передача заказов',
          ['В кабинете VAYGO', 'В аптечной программе', 'Другое']),
      FormQuestion.one('replace', 'Замены отсутствующих товаров',
          ['Только после согласования с покупателем', 'Не допускаются']),
      FormQuestion.text('assemblecontact', 'Контакт ответственного за сборку'),
    ]),
    FormSection('Выдача и доставка', [
      FormQuestion.many('pickup', 'Доступные способы получения',
          ['Самовывоз', 'Доставка курьером (при соблюдении требований)']),
      FormQuestion.text('courieraddr', 'Адрес передачи заказов курьеру'),
      FormQuestion.text('couriertime', 'Время передачи заказов курьеру'),
      FormQuestion.one('temp', 'Нужен ли специальный температурный режим',
          ['Да', 'Нет', 'Для части позиций']),
      FormQuestion.text('tempgroups', 'Какие группы требуют спецусловий'),
      FormQuestion.one('packing',
          'Возможность обеспечить упаковку и условия транспортировки',
          ['Да', 'Нет', 'Нужна отдельная схема']),
      FormQuestion.text('deliverycontact', 'Контакт по вопросам выдачи / доставки'),
    ], note: 'Информация для запуска, договора и последующего сопровождения.'),
    FormSection('Финансовые и договорные сведения', [
      FormQuestion.text('payee', 'Получатель платежей (наименование)'),
      FormQuestion.text('account', 'Расчётный счёт'),
      FormQuestion.text('bank', 'Банк'),
      FormQuestion.text('bik', 'БИК'),
      FormQuestion.text('corr', 'Корреспондентский счёт'),
      FormQuestion.one('payfreq', 'Предпочтительный график перечислений',
          ['Ежедневно', 'Раз в неделю', 'Два раза в месяц', 'Раз в месяц']),
      FormQuestion.text('accountant', 'Контакт бухгалтера / email'),
      FormQuestion.longText('cancelterms', 'Условия отмены / возврата заказа'),
    ], note:
        'Продажу товаров осуществляет аптека. Безналичная оплата, чеки, возвраты и перечисления средств оформляются в договоре и техническом регламенте.'),
    FormSection('Комплект документов и подтверждение', [
      FormQuestion.many('attach', 'Приложения к анкете', [
        'Карточка предприятия', 'Сведения о фармлицензии',
        'Разрешение на дистанционную торговлю (если есть)',
      ]),
      FormQuestion.many('extra', 'Дополнительные материалы', [
        'Список филиалов', 'Выгрузка каталога', 'Контакты IT-специалиста',
      ]),
      FormQuestion.text('respons', 'Ответственный за подключение'),
      FormQuestion.text('filldate', 'Дата заполнения'),
      FormQuestion.text('sign', 'Подпись / ФИО'),
    ]),
    FormSection('Служебная отметка VAYGO', [
      FormQuestion.many('mark', 'Отметка', [
        'Анкета принята', 'Документы проверены',
        'Интеграция согласована', 'Тестовый заказ выполнен',
      ]),
    ], note: 'Заполняет менеджер VAYGO'),
  ],
);

// ------------------------------------------------------------------
// Анкета цветочного магазина
// ------------------------------------------------------------------

const flowerForm = FormTemplate(
  id: 'flower',
  name: 'Цветочный магазин',
  subtitle: 'Подключение цветочного магазина или салона',
  docTitle: 'АНКЕТА ЦВЕТОЧНОГО МАГАЗИНА',
  docSubtitle: 'Для подключения магазина к приложению VAYGO',
  intro:
      'Заполните доступные сведения; отсутствующие данные можно уточнить с менеджером.',
  footnote:
      'Анкета используется для подготовки подключения. Комиссия, сроки выплат, порядок возвратов и иные обязательства определяются отдельным соглашением сторон.',
  titleKeys: ['name', 'legal'],
  prefill: {'name': 'name', 'addr': 'address', 'phone': 'phone'},
  sections: [
    FormSection('Сведения о магазине', [
      FormQuestion.text('name', 'Торговое название магазина'),
      FormQuestion.text('legal', 'Юридическое наименование / Ф. И. О.'),
      FormQuestion.one('form', 'Форма деятельности',
          ['ООО', 'ИП', 'Самозанятый', 'Физическое лицо']),
      FormQuestion.text('inn', 'ИНН'),
      FormQuestion.text('ogrn', 'ОГРН / ОГРНИП (если есть)'),
      FormQuestion.text('addr', 'Фактический адрес магазина'),
      FormQuestion.text('points', 'Количество торговых точек'),
      FormQuestion.text('contact', 'Контактное лицо и должность'),
      FormQuestion.text('phone', 'Контактный телефон / WhatsApp'),
      FormQuestion.email('email', 'Электронная почта для уведомлений',
          hint: 'name@example.com'),
      FormQuestion.text('site', 'Сайт / социальные сети'),
    ]),
    FormSection('График и возможности', [
      FormQuestion.text('hours', 'Режим работы по дням недели'),
      FormQuestion.one('r24', 'Работа круглосуточно', ['Да', 'Нет']),
      FormQuestion.one('preorder', 'Приём заказов на будущую дату / время',
          ['Да', 'Нет']),
      FormQuestion.one('urgent', 'Возможен срочный заказ', ['Да', 'Нет']),
      FormQuestion.text('assemblemin', 'Минимальное время сборки букета',
          hint: 'в минутах'),
      FormQuestion.text('holidays', 'Работа в праздничные дни / особенности'),
    ]),
    FormSection('Ассортимент', [
      FormQuestion.many('cats', 'Категории товаров (отметьте все подходящие)', [
        'Готовые букеты', 'Авторские букеты', 'Цветы поштучно',
        'Композиции в корзинах', 'Цветы в коробках', 'Свадебная флористика',
        'Комнатные растения', 'Искусственные цветы', 'Воздушные шары',
        'Мягкие игрушки', 'Открытки', 'Подарочные наборы',
      ]),
      FormQuestion.text('othercats', 'Другие категории товаров'),
      FormQuestion.text('skus', 'Приблизительное число позиций'),
      FormQuestion.text('minorder', 'Минимальная сумма заказа', hint: '₽'),
      FormQuestion.text('avgcheck', 'Средний чек', hint: '₽'),
      FormQuestion.one('custom', 'Сборка букета по индивидуальному запросу',
          ['Да', 'Нет']),
      FormQuestion.one('colorchoice', 'Выбор клиентом цвета / количества цветов',
          ['Да', 'Нет']),
      FormQuestion.text('extras', 'Дополнительные услуги (упаковка и др.)'),
    ]),
    FormSection('Цены и обработка заказов', [
      FormQuestion.one('seasonal', 'Цены меняются по сезону / к праздникам',
          ['Да', 'Нет']),
      FormQuestion.text('updfreq', 'Как часто обновляется ассортимент'),
      FormQuestion.text('priceresp', 'Ответственный за цены и наличие в VAYGO'),
      FormQuestion.one('replace',
          'Замена цветов при отсутствии согласовывается с клиентом', ['Да', 'Нет']),
      FormQuestion.one('photoprev', 'Фото готового букета клиенту до отправки',
          ['Да', 'Нет']),
      FormQuestion.one('cardtext', 'Принимаете ли заказы с текстом открытки',
          ['Да', 'Нет']),
      FormQuestion.text('confirmmin', 'Максимальное время подтверждения заказа',
          hint: 'в минутах'),
      FormQuestion.text('confirmphone', 'Телефон для оперативного подтверждения заказов'),
    ]),
    FormSection('Получение заказа и доставка', [
      FormQuestion.many('pickup', 'Способы получения заказа', [
        'Самовывоз', 'Собственная доставка', 'Курьер VAYGO (после согласования)',
      ]),
      FormQuestion.text('pickaddr', 'Адрес / точка самовывоза'),
      FormQuestion.text('zone', 'Зона собственной доставки'),
      FormQuestion.text('delcost', 'Стоимость собственной доставки', hint: '₽'),
      FormQuestion.one('freedel', 'Бесплатная доставка от суммы заказа',
          ['Да', 'Нет']),
      FormQuestion.text('freefrom', 'При наличии: от какой суммы', hint: '₽'),
      FormQuestion.text('deltime', 'Обычное время доставки', hint: 'в минутах'),
      FormQuestion.one('timedel', 'Доставка к указанному времени', ['Да', 'Нет']),
      FormQuestion.one('anon', 'Анонимная доставка (без имени отправителя)',
          ['Да', 'Нет']),
      FormQuestion.one('surprise', 'Доставка-сюрприз получателю', ['Да', 'Нет']),
      FormQuestion.longText('limits', 'Ограничения при доставке / особые условия'),
    ]),
    FormSection('Каталог и учёт товаров', [
      FormQuestion.one('catalog', 'Есть действующий электронный каталог',
          ['Да', 'Нет']),
      FormQuestion.many('catformat', 'Формат товарного каталога',
          ['Excel', '1С', 'МойСклад', 'Другое']),
      FormQuestion.text('system', 'Название системы учёта, если используется'),
      FormQuestion.one('photos', 'Есть качественные фотографии товаров',
          ['Да', 'Частично', 'Нет']),
      FormQuestion.text('photoswho', 'Кто предоставит фото, названия и описания'),
      FormQuestion.text('catupd', 'Кто будет обновлять каталог в VAYGO'),
      FormQuestion.one('photouse',
          'Разрешаете использование предоставленных фото и описаний в карточках товаров VAYGO',
          ['Да', 'Требует согласования']),
    ]),
    FormSection('Расчёты и коммерческие условия', [
      FormQuestion.one('payfreq', 'Предпочтительная периодичность выплат', [
        'Ежедневно', 'Раз в неделю', 'Раз в две недели', 'Раз в месяц',
        'По согласованию',
      ]),
      FormQuestion.text('bank', 'Банк и получатель платежей'),
      FormQuestion.text('account', 'Расчётный счёт / реквизиты (можно приложить)'),
      FormQuestion.text('tax', 'Применяемая система налогообложения'),
      FormQuestion.text('vat', 'Ставка НДС / основание без НДС'),
      FormQuestion.text('fee', 'Предполагаемая комиссия VAYGO',
          hint: '% (согласовывается)'),
      FormQuestion.one('refund',
          'Согласование отмены / возврата через ответственного', ['Да', 'Нет']),
      FormQuestion.text('refundresp', 'Ответственный по вопросам возвратов'),
    ]),
    FormSection('Организация подключения', [
      FormQuestion.text('techcontact', 'Контакт для технического подключения'),
      FormQuestion.text('notifyphone', 'Номер для рабочих уведомлений'),
      FormQuestion.one('training', 'Понадобится обучение работе с заказами',
          ['Да', 'Нет']),
      FormQuestion.one('catready', 'Готовность каталога',
          ['Готов', 'Нужна помощь', 'В работе']),
      FormQuestion.text('startdate', 'Желаемая дата начала приёма заказов'),
      FormQuestion.longText('comment', 'Комментарий / особые пожелания'),
      FormQuestion.many('handed', 'Что передано менеджеру VAYGO', [
        'Реквизиты', 'Меню / прайс', 'Фотографии', 'График работы',
        'Контакты ответственного',
      ]),
      FormQuestion.text('filldate', 'Дата заполнения'),
      FormQuestion.text('manager', 'Менеджер VAYGO'),
      FormQuestion.text('sign', 'Подпись представителя магазина'),
    ]),
  ],
);

/// Все типы анкет. Чтобы добавить новый тип: описать шаблон выше и дописать
/// его сюда. Поле электронной почты добавится само, если его нет в шаблоне.
final formTemplates =
    <FormTemplate>[groceryForm, hotelForm, pharmacyForm, flowerForm]
    .map((t) => t.withEmailField())
    .toList();

FormTemplate? templateById(String id) {
  for (final t in formTemplates) {
    if (t.id == id) return t;
  }
  return null;
}
