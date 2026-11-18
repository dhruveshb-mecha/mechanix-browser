// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UrlsTable extends Urls with TableInfo<$UrlsTable, HistoryUrl> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UrlsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _visitCountMeta = const VerificationMeta(
    'visitCount',
  );
  @override
  late final GeneratedColumn<int> visitCount = GeneratedColumn<int>(
    'visit_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _typedCountMeta = const VerificationMeta(
    'typedCount',
  );
  @override
  late final GeneratedColumn<int> typedCount = GeneratedColumn<int>(
    'typed_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastVisitTimeMeta = const VerificationMeta(
    'lastVisitTime',
  );
  @override
  late final GeneratedColumn<int> lastVisitTime = GeneratedColumn<int>(
    'last_visit_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    url,
    title,
    visitCount,
    typedCount,
    lastVisitTime,
    hidden,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'urls';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryUrl> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('visit_count')) {
      context.handle(
        _visitCountMeta,
        visitCount.isAcceptableOrUnknown(data['visit_count']!, _visitCountMeta),
      );
    }
    if (data.containsKey('typed_count')) {
      context.handle(
        _typedCountMeta,
        typedCount.isAcceptableOrUnknown(data['typed_count']!, _typedCountMeta),
      );
    }
    if (data.containsKey('last_visit_time')) {
      context.handle(
        _lastVisitTimeMeta,
        lastVisitTime.isAcceptableOrUnknown(
          data['last_visit_time']!,
          _lastVisitTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastVisitTimeMeta);
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryUrl map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryUrl(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      visitCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}visit_count'],
      )!,
      typedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}typed_count'],
      )!,
      lastVisitTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_visit_time'],
      )!,
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
    );
  }

  @override
  $UrlsTable createAlias(String alias) {
    return $UrlsTable(attachedDatabase, alias);
  }
}

class HistoryUrl extends DataClass implements Insertable<HistoryUrl> {
  final int id;
  final String url;
  final String title;

  /// Number of visits to this URL.
  final int visitCount;

  /// Number of those visits where the URL was typed in the address bar.
  final int typedCount;
  final int lastVisitTime;

  /// Hidden URLs are kept for counting but not shown in history or
  /// suggestions. Reserved, as in Chromium (e.g. for subframe-only URLs);
  /// nothing sets it yet. Redirect hops are left out per visit instead.
  final bool hidden;
  const HistoryUrl({
    required this.id,
    required this.url,
    required this.title,
    required this.visitCount,
    required this.typedCount,
    required this.lastVisitTime,
    required this.hidden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['url'] = Variable<String>(url);
    map['title'] = Variable<String>(title);
    map['visit_count'] = Variable<int>(visitCount);
    map['typed_count'] = Variable<int>(typedCount);
    map['last_visit_time'] = Variable<int>(lastVisitTime);
    map['hidden'] = Variable<bool>(hidden);
    return map;
  }

  UrlsCompanion toCompanion(bool nullToAbsent) {
    return UrlsCompanion(
      id: Value(id),
      url: Value(url),
      title: Value(title),
      visitCount: Value(visitCount),
      typedCount: Value(typedCount),
      lastVisitTime: Value(lastVisitTime),
      hidden: Value(hidden),
    );
  }

  factory HistoryUrl.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryUrl(
      id: serializer.fromJson<int>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      title: serializer.fromJson<String>(json['title']),
      visitCount: serializer.fromJson<int>(json['visitCount']),
      typedCount: serializer.fromJson<int>(json['typedCount']),
      lastVisitTime: serializer.fromJson<int>(json['lastVisitTime']),
      hidden: serializer.fromJson<bool>(json['hidden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'url': serializer.toJson<String>(url),
      'title': serializer.toJson<String>(title),
      'visitCount': serializer.toJson<int>(visitCount),
      'typedCount': serializer.toJson<int>(typedCount),
      'lastVisitTime': serializer.toJson<int>(lastVisitTime),
      'hidden': serializer.toJson<bool>(hidden),
    };
  }

  HistoryUrl copyWith({
    int? id,
    String? url,
    String? title,
    int? visitCount,
    int? typedCount,
    int? lastVisitTime,
    bool? hidden,
  }) => HistoryUrl(
    id: id ?? this.id,
    url: url ?? this.url,
    title: title ?? this.title,
    visitCount: visitCount ?? this.visitCount,
    typedCount: typedCount ?? this.typedCount,
    lastVisitTime: lastVisitTime ?? this.lastVisitTime,
    hidden: hidden ?? this.hidden,
  );
  HistoryUrl copyWithCompanion(UrlsCompanion data) {
    return HistoryUrl(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      visitCount: data.visitCount.present
          ? data.visitCount.value
          : this.visitCount,
      typedCount: data.typedCount.present
          ? data.typedCount.value
          : this.typedCount,
      lastVisitTime: data.lastVisitTime.present
          ? data.lastVisitTime.value
          : this.lastVisitTime,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryUrl(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('visitCount: $visitCount, ')
          ..write('typedCount: $typedCount, ')
          ..write('lastVisitTime: $lastVisitTime, ')
          ..write('hidden: $hidden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    url,
    title,
    visitCount,
    typedCount,
    lastVisitTime,
    hidden,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryUrl &&
          other.id == this.id &&
          other.url == this.url &&
          other.title == this.title &&
          other.visitCount == this.visitCount &&
          other.typedCount == this.typedCount &&
          other.lastVisitTime == this.lastVisitTime &&
          other.hidden == this.hidden);
}

class UrlsCompanion extends UpdateCompanion<HistoryUrl> {
  final Value<int> id;
  final Value<String> url;
  final Value<String> title;
  final Value<int> visitCount;
  final Value<int> typedCount;
  final Value<int> lastVisitTime;
  final Value<bool> hidden;
  const UrlsCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.visitCount = const Value.absent(),
    this.typedCount = const Value.absent(),
    this.lastVisitTime = const Value.absent(),
    this.hidden = const Value.absent(),
  });
  UrlsCompanion.insert({
    this.id = const Value.absent(),
    required String url,
    this.title = const Value.absent(),
    this.visitCount = const Value.absent(),
    this.typedCount = const Value.absent(),
    required int lastVisitTime,
    this.hidden = const Value.absent(),
  }) : url = Value(url),
       lastVisitTime = Value(lastVisitTime);
  static Insertable<HistoryUrl> custom({
    Expression<int>? id,
    Expression<String>? url,
    Expression<String>? title,
    Expression<int>? visitCount,
    Expression<int>? typedCount,
    Expression<int>? lastVisitTime,
    Expression<bool>? hidden,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (visitCount != null) 'visit_count': visitCount,
      if (typedCount != null) 'typed_count': typedCount,
      if (lastVisitTime != null) 'last_visit_time': lastVisitTime,
      if (hidden != null) 'hidden': hidden,
    });
  }

  UrlsCompanion copyWith({
    Value<int>? id,
    Value<String>? url,
    Value<String>? title,
    Value<int>? visitCount,
    Value<int>? typedCount,
    Value<int>? lastVisitTime,
    Value<bool>? hidden,
  }) {
    return UrlsCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      visitCount: visitCount ?? this.visitCount,
      typedCount: typedCount ?? this.typedCount,
      lastVisitTime: lastVisitTime ?? this.lastVisitTime,
      hidden: hidden ?? this.hidden,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (visitCount.present) {
      map['visit_count'] = Variable<int>(visitCount.value);
    }
    if (typedCount.present) {
      map['typed_count'] = Variable<int>(typedCount.value);
    }
    if (lastVisitTime.present) {
      map['last_visit_time'] = Variable<int>(lastVisitTime.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UrlsCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('visitCount: $visitCount, ')
          ..write('typedCount: $typedCount, ')
          ..write('lastVisitTime: $lastVisitTime, ')
          ..write('hidden: $hidden')
          ..write(')'))
        .toString();
  }
}

class $VisitsTable extends Visits with TableInfo<$VisitsTable, HistoryVisit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _urlIdMeta = const VerificationMeta('urlId');
  @override
  late final GeneratedColumn<int> urlId = GeneratedColumn<int>(
    'url_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES urls (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _visitTimeMeta = const VerificationMeta(
    'visitTime',
  );
  @override
  late final GeneratedColumn<int> visitTime = GeneratedColumn<int>(
    'visit_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PageTransition, String>
  transition = GeneratedColumn<String>(
    'transition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<PageTransition>($VisitsTable.$convertertransition);
  static const VerificationMeta _fromVisitMeta = const VerificationMeta(
    'fromVisit',
  );
  @override
  late final GeneratedColumn<int> fromVisit = GeneratedColumn<int>(
    'from_visit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES visits (id) ON DELETE SET NULL',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    urlId,
    visitTime,
    transition,
    fromVisit,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visits';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryVisit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('url_id')) {
      context.handle(
        _urlIdMeta,
        urlId.isAcceptableOrUnknown(data['url_id']!, _urlIdMeta),
      );
    } else if (isInserting) {
      context.missing(_urlIdMeta);
    }
    if (data.containsKey('visit_time')) {
      context.handle(
        _visitTimeMeta,
        visitTime.isAcceptableOrUnknown(data['visit_time']!, _visitTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_visitTimeMeta);
    }
    if (data.containsKey('from_visit')) {
      context.handle(
        _fromVisitMeta,
        fromVisit.isAcceptableOrUnknown(data['from_visit']!, _fromVisitMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryVisit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryVisit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      urlId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}url_id'],
      )!,
      visitTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}visit_time'],
      )!,
      transition: $VisitsTable.$convertertransition.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}transition'],
        )!,
      ),
      fromVisit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_visit'],
      ),
    );
  }

  @override
  $VisitsTable createAlias(String alias) {
    return $VisitsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PageTransition, String, String>
  $convertertransition = const EnumNameConverter<PageTransition>(
    PageTransition.values,
  );
}

class HistoryVisit extends DataClass implements Insertable<HistoryVisit> {
  final int id;
  final int urlId;
  final int visitTime;
  final PageTransition transition;

  /// The visit this one came from, for redirect chains.
  final int? fromVisit;
  const HistoryVisit({
    required this.id,
    required this.urlId,
    required this.visitTime,
    required this.transition,
    this.fromVisit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['url_id'] = Variable<int>(urlId);
    map['visit_time'] = Variable<int>(visitTime);
    {
      map['transition'] = Variable<String>(
        $VisitsTable.$convertertransition.toSql(transition),
      );
    }
    if (!nullToAbsent || fromVisit != null) {
      map['from_visit'] = Variable<int>(fromVisit);
    }
    return map;
  }

  VisitsCompanion toCompanion(bool nullToAbsent) {
    return VisitsCompanion(
      id: Value(id),
      urlId: Value(urlId),
      visitTime: Value(visitTime),
      transition: Value(transition),
      fromVisit: fromVisit == null && nullToAbsent
          ? const Value.absent()
          : Value(fromVisit),
    );
  }

  factory HistoryVisit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryVisit(
      id: serializer.fromJson<int>(json['id']),
      urlId: serializer.fromJson<int>(json['urlId']),
      visitTime: serializer.fromJson<int>(json['visitTime']),
      transition: $VisitsTable.$convertertransition.fromJson(
        serializer.fromJson<String>(json['transition']),
      ),
      fromVisit: serializer.fromJson<int?>(json['fromVisit']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'urlId': serializer.toJson<int>(urlId),
      'visitTime': serializer.toJson<int>(visitTime),
      'transition': serializer.toJson<String>(
        $VisitsTable.$convertertransition.toJson(transition),
      ),
      'fromVisit': serializer.toJson<int?>(fromVisit),
    };
  }

  HistoryVisit copyWith({
    int? id,
    int? urlId,
    int? visitTime,
    PageTransition? transition,
    Value<int?> fromVisit = const Value.absent(),
  }) => HistoryVisit(
    id: id ?? this.id,
    urlId: urlId ?? this.urlId,
    visitTime: visitTime ?? this.visitTime,
    transition: transition ?? this.transition,
    fromVisit: fromVisit.present ? fromVisit.value : this.fromVisit,
  );
  HistoryVisit copyWithCompanion(VisitsCompanion data) {
    return HistoryVisit(
      id: data.id.present ? data.id.value : this.id,
      urlId: data.urlId.present ? data.urlId.value : this.urlId,
      visitTime: data.visitTime.present ? data.visitTime.value : this.visitTime,
      transition: data.transition.present
          ? data.transition.value
          : this.transition,
      fromVisit: data.fromVisit.present ? data.fromVisit.value : this.fromVisit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryVisit(')
          ..write('id: $id, ')
          ..write('urlId: $urlId, ')
          ..write('visitTime: $visitTime, ')
          ..write('transition: $transition, ')
          ..write('fromVisit: $fromVisit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, urlId, visitTime, transition, fromVisit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryVisit &&
          other.id == this.id &&
          other.urlId == this.urlId &&
          other.visitTime == this.visitTime &&
          other.transition == this.transition &&
          other.fromVisit == this.fromVisit);
}

class VisitsCompanion extends UpdateCompanion<HistoryVisit> {
  final Value<int> id;
  final Value<int> urlId;
  final Value<int> visitTime;
  final Value<PageTransition> transition;
  final Value<int?> fromVisit;
  const VisitsCompanion({
    this.id = const Value.absent(),
    this.urlId = const Value.absent(),
    this.visitTime = const Value.absent(),
    this.transition = const Value.absent(),
    this.fromVisit = const Value.absent(),
  });
  VisitsCompanion.insert({
    this.id = const Value.absent(),
    required int urlId,
    required int visitTime,
    required PageTransition transition,
    this.fromVisit = const Value.absent(),
  }) : urlId = Value(urlId),
       visitTime = Value(visitTime),
       transition = Value(transition);
  static Insertable<HistoryVisit> custom({
    Expression<int>? id,
    Expression<int>? urlId,
    Expression<int>? visitTime,
    Expression<String>? transition,
    Expression<int>? fromVisit,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (urlId != null) 'url_id': urlId,
      if (visitTime != null) 'visit_time': visitTime,
      if (transition != null) 'transition': transition,
      if (fromVisit != null) 'from_visit': fromVisit,
    });
  }

  VisitsCompanion copyWith({
    Value<int>? id,
    Value<int>? urlId,
    Value<int>? visitTime,
    Value<PageTransition>? transition,
    Value<int?>? fromVisit,
  }) {
    return VisitsCompanion(
      id: id ?? this.id,
      urlId: urlId ?? this.urlId,
      visitTime: visitTime ?? this.visitTime,
      transition: transition ?? this.transition,
      fromVisit: fromVisit ?? this.fromVisit,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (urlId.present) {
      map['url_id'] = Variable<int>(urlId.value);
    }
    if (visitTime.present) {
      map['visit_time'] = Variable<int>(visitTime.value);
    }
    if (transition.present) {
      map['transition'] = Variable<String>(
        $VisitsTable.$convertertransition.toSql(transition.value),
      );
    }
    if (fromVisit.present) {
      map['from_visit'] = Variable<int>(fromVisit.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitsCompanion(')
          ..write('id: $id, ')
          ..write('urlId: $urlId, ')
          ..write('visitTime: $visitTime, ')
          ..write('transition: $transition, ')
          ..write('fromVisit: $fromVisit')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, DownloadEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cefDownloadIdMeta = const VerificationMeta(
    'cefDownloadId',
  );
  @override
  late final GeneratedColumn<int> cefDownloadId = GeneratedColumn<int>(
    'cef_download_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _downloadedBytesMeta = const VerificationMeta(
    'downloadedBytes',
  );
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
    'downloaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusIndexMeta = const VerificationMeta(
    'statusIndex',
  );
  @override
  late final GeneratedColumn<int> statusIndex = GeneratedColumn<int>(
    'status_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cefDownloadId,
    url,
    fileName,
    filePath,
    totalBytes,
    downloadedBytes,
    statusIndex,
    createdAt,
    completedAt,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cef_download_id')) {
      context.handle(
        _cefDownloadIdMeta,
        cefDownloadId.isAcceptableOrUnknown(
          data['cef_download_id']!,
          _cefDownloadIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cefDownloadIdMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
        _downloadedBytesMeta,
        downloadedBytes.isAcceptableOrUnknown(
          data['downloaded_bytes']!,
          _downloadedBytesMeta,
        ),
      );
    }
    if (data.containsKey('status_index')) {
      context.handle(
        _statusIndexMeta,
        statusIndex.isAcceptableOrUnknown(
          data['status_index']!,
          _statusIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_statusIndexMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cefDownloadId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cef_download_id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      )!,
      downloadedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded_bytes'],
      )!,
      statusIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class DownloadsCompanion extends UpdateCompanion<DownloadEntity> {
  final Value<int> id;
  final Value<int> cefDownloadId;
  final Value<String> url;
  final Value<String> fileName;
  final Value<String> filePath;
  final Value<int> totalBytes;
  final Value<int> downloadedBytes;
  final Value<int> statusIndex;
  final Value<int> createdAt;
  final Value<int?> completedAt;
  final Value<String?> errorMessage;
  const DownloadsCompanion({
    this.id = const Value.absent(),
    this.cefDownloadId = const Value.absent(),
    this.url = const Value.absent(),
    this.fileName = const Value.absent(),
    this.filePath = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.statusIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
  });
  DownloadsCompanion.insert({
    this.id = const Value.absent(),
    required int cefDownloadId,
    required String url,
    required String fileName,
    required String filePath,
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    required int statusIndex,
    required int createdAt,
    this.completedAt = const Value.absent(),
    this.errorMessage = const Value.absent(),
  }) : cefDownloadId = Value(cefDownloadId),
       url = Value(url),
       fileName = Value(fileName),
       filePath = Value(filePath),
       statusIndex = Value(statusIndex),
       createdAt = Value(createdAt);
  static Insertable<DownloadEntity> custom({
    Expression<int>? id,
    Expression<int>? cefDownloadId,
    Expression<String>? url,
    Expression<String>? fileName,
    Expression<String>? filePath,
    Expression<int>? totalBytes,
    Expression<int>? downloadedBytes,
    Expression<int>? statusIndex,
    Expression<int>? createdAt,
    Expression<int>? completedAt,
    Expression<String>? errorMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cefDownloadId != null) 'cef_download_id': cefDownloadId,
      if (url != null) 'url': url,
      if (fileName != null) 'file_name': fileName,
      if (filePath != null) 'file_path': filePath,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (statusIndex != null) 'status_index': statusIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (errorMessage != null) 'error_message': errorMessage,
    });
  }

  DownloadsCompanion copyWith({
    Value<int>? id,
    Value<int>? cefDownloadId,
    Value<String>? url,
    Value<String>? fileName,
    Value<String>? filePath,
    Value<int>? totalBytes,
    Value<int>? downloadedBytes,
    Value<int>? statusIndex,
    Value<int>? createdAt,
    Value<int?>? completedAt,
    Value<String?>? errorMessage,
  }) {
    return DownloadsCompanion(
      id: id ?? this.id,
      cefDownloadId: cefDownloadId ?? this.cefDownloadId,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      statusIndex: statusIndex ?? this.statusIndex,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cefDownloadId.present) {
      map['cef_download_id'] = Variable<int>(cefDownloadId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (statusIndex.present) {
      map['status_index'] = Variable<int>(statusIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('id: $id, ')
          ..write('cefDownloadId: $cefDownloadId, ')
          ..write('url: $url, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('statusIndex: $statusIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }
}

class $TabsTable extends Tabs with TableInfo<$TabsTable, TabEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TabsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tabIdMeta = const VerificationMeta('tabId');
  @override
  late final GeneratedColumn<String> tabId = GeneratedColumn<String>(
    'tab_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tabIndexMeta = const VerificationMeta(
    'tabIndex',
  );
  @override
  late final GeneratedColumn<int> tabIndex = GeneratedColumn<int>(
    'tab_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _screenshotMeta = const VerificationMeta(
    'screenshot',
  );
  @override
  late final GeneratedColumn<Uint8List> screenshot = GeneratedColumn<Uint8List>(
    'screenshot',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tabId,
    tabIndex,
    url,
    title,
    isActive,
    screenshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tabs';
  @override
  VerificationContext validateIntegrity(
    Insertable<TabEntity> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tab_id')) {
      context.handle(
        _tabIdMeta,
        tabId.isAcceptableOrUnknown(data['tab_id']!, _tabIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tabIdMeta);
    }
    if (data.containsKey('tab_index')) {
      context.handle(
        _tabIndexMeta,
        tabIndex.isAcceptableOrUnknown(data['tab_index']!, _tabIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_tabIndexMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('screenshot')) {
      context.handle(
        _screenshotMeta,
        screenshot.isAcceptableOrUnknown(data['screenshot']!, _screenshotMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TabEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TabEntity(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tabId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tab_id'],
      )!,
      tabIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tab_index'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      screenshot: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}screenshot'],
      ),
    );
  }

  @override
  $TabsTable createAlias(String alias) {
    return $TabsTable(attachedDatabase, alias);
  }
}

class TabsCompanion extends UpdateCompanion<TabEntity> {
  final Value<int> id;
  final Value<String> tabId;
  final Value<int> tabIndex;
  final Value<String> url;
  final Value<String> title;
  final Value<bool> isActive;
  final Value<Uint8List?> screenshot;
  const TabsCompanion({
    this.id = const Value.absent(),
    this.tabId = const Value.absent(),
    this.tabIndex = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.isActive = const Value.absent(),
    this.screenshot = const Value.absent(),
  });
  TabsCompanion.insert({
    this.id = const Value.absent(),
    required String tabId,
    required int tabIndex,
    required String url,
    required String title,
    required bool isActive,
    this.screenshot = const Value.absent(),
  }) : tabId = Value(tabId),
       tabIndex = Value(tabIndex),
       url = Value(url),
       title = Value(title),
       isActive = Value(isActive);
  static Insertable<TabEntity> custom({
    Expression<int>? id,
    Expression<String>? tabId,
    Expression<int>? tabIndex,
    Expression<String>? url,
    Expression<String>? title,
    Expression<bool>? isActive,
    Expression<Uint8List>? screenshot,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tabId != null) 'tab_id': tabId,
      if (tabIndex != null) 'tab_index': tabIndex,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (isActive != null) 'is_active': isActive,
      if (screenshot != null) 'screenshot': screenshot,
    });
  }

  TabsCompanion copyWith({
    Value<int>? id,
    Value<String>? tabId,
    Value<int>? tabIndex,
    Value<String>? url,
    Value<String>? title,
    Value<bool>? isActive,
    Value<Uint8List?>? screenshot,
  }) {
    return TabsCompanion(
      id: id ?? this.id,
      tabId: tabId ?? this.tabId,
      tabIndex: tabIndex ?? this.tabIndex,
      url: url ?? this.url,
      title: title ?? this.title,
      isActive: isActive ?? this.isActive,
      screenshot: screenshot ?? this.screenshot,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tabId.present) {
      map['tab_id'] = Variable<String>(tabId.value);
    }
    if (tabIndex.present) {
      map['tab_index'] = Variable<int>(tabIndex.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (screenshot.present) {
      map['screenshot'] = Variable<Uint8List>(screenshot.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TabsCompanion(')
          ..write('id: $id, ')
          ..write('tabId: $tabId, ')
          ..write('tabIndex: $tabIndex, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('isActive: $isActive, ')
          ..write('screenshot: $screenshot')
          ..write(')'))
        .toString();
  }
}

class $HistoryEntriesView extends ViewInfo<$HistoryEntriesView, BrowserHistory>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$AppDatabase attachedDatabase;
  $HistoryEntriesView(this.attachedDatabase, [this._alias]);
  $VisitsTable get visits => attachedDatabase.visits.createAlias('t0');
  $UrlsTable get urls => attachedDatabase.urls.createAlias('t1');
  @override
  List<GeneratedColumn> get $columns => [id, url, title, timestamp];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'history_entries';
  @override
  Map<SqlDialect, String>? get createViewStatements => null;
  @override
  $HistoryEntriesView get asDslTable => this;
  @override
  BrowserHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BrowserHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    generatedAs: GeneratedAs(visits.id, false),
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    generatedAs: GeneratedAs(urls.url, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    generatedAs: GeneratedAs(urls.title, false),
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    generatedAs: GeneratedAs(visits.visitTime, false),
    type: DriftSqlType.int,
  );
  @override
  $HistoryEntriesView createAlias(String alias) {
    return $HistoryEntriesView(attachedDatabase, alias);
  }

  @override
  Query? get query =>
      (attachedDatabase.selectOnly(visits)..addColumns($columns)).join([
        innerJoin(urls, urls.id.equalsExp(visits.urlId)),
      ])..where(
        BooleanExpressionOperators(urls.hidden).not() &
            _IsRedirectChainEnd(visits.id),
      );
  @override
  Set<String> get readTables => const {'visits', 'urls'};
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UrlsTable urls = $UrlsTable(this);
  late final $VisitsTable visits = $VisitsTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $TabsTable tabs = $TabsTable(this);
  late final $HistoryEntriesView historyEntries = $HistoryEntriesView(this);
  late final Index visitsUrlId = Index(
    'visits_url_id',
    'CREATE INDEX visits_url_id ON visits (url_id)',
  );
  late final Index visitsVisitTime = Index(
    'visits_visit_time',
    'CREATE INDEX visits_visit_time ON visits (visit_time)',
  );
  late final Index visitsFromVisit = Index(
    'visits_from_visit',
    'CREATE INDEX visits_from_visit ON visits (from_visit)',
  );
  late final Index downloadsCefDownloadId = Index(
    'downloads_cef_download_id',
    'CREATE INDEX downloads_cef_download_id ON downloads (cef_download_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    urls,
    visits,
    downloads,
    tabs,
    historyEntries,
    visitsUrlId,
    visitsVisitTime,
    visitsFromVisit,
    downloadsCefDownloadId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'urls',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visits', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'visits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('visits', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$UrlsTableCreateCompanionBuilder =
    UrlsCompanion Function({
      Value<int> id,
      required String url,
      Value<String> title,
      Value<int> visitCount,
      Value<int> typedCount,
      required int lastVisitTime,
      Value<bool> hidden,
    });
typedef $$UrlsTableUpdateCompanionBuilder =
    UrlsCompanion Function({
      Value<int> id,
      Value<String> url,
      Value<String> title,
      Value<int> visitCount,
      Value<int> typedCount,
      Value<int> lastVisitTime,
      Value<bool> hidden,
    });

final class $$UrlsTableReferences
    extends BaseReferences<_$AppDatabase, $UrlsTable, HistoryUrl> {
  $$UrlsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VisitsTable, List<HistoryVisit>> _visitsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.visits,
    aliasName: 'urls__id__visits__url_id',
  );

  $$VisitsTableProcessedTableManager get visitsRefs {
    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.urlId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UrlsTableFilterComposer extends Composer<_$AppDatabase, $UrlsTable> {
  $$UrlsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get typedCount => $composableBuilder(
    column: $table.typedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastVisitTime => $composableBuilder(
    column: $table.lastVisitTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> visitsRefs(
    Expression<bool> Function($$VisitsTableFilterComposer f) f,
  ) {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.urlId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UrlsTableOrderingComposer extends Composer<_$AppDatabase, $UrlsTable> {
  $$UrlsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get typedCount => $composableBuilder(
    column: $table.typedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastVisitTime => $composableBuilder(
    column: $table.lastVisitTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UrlsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UrlsTable> {
  $$UrlsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get visitCount => $composableBuilder(
    column: $table.visitCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get typedCount => $composableBuilder(
    column: $table.typedCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastVisitTime => $composableBuilder(
    column: $table.lastVisitTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  Expression<T> visitsRefs<T extends Object>(
    Expression<T> Function($$VisitsTableAnnotationComposer a) f,
  ) {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.urlId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UrlsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UrlsTable,
          HistoryUrl,
          $$UrlsTableFilterComposer,
          $$UrlsTableOrderingComposer,
          $$UrlsTableAnnotationComposer,
          $$UrlsTableCreateCompanionBuilder,
          $$UrlsTableUpdateCompanionBuilder,
          (HistoryUrl, $$UrlsTableReferences),
          HistoryUrl,
          PrefetchHooks Function({bool visitsRefs})
        > {
  $$UrlsTableTableManager(_$AppDatabase db, $UrlsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UrlsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UrlsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UrlsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> visitCount = const Value.absent(),
                Value<int> typedCount = const Value.absent(),
                Value<int> lastVisitTime = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
              }) => UrlsCompanion(
                id: id,
                url: url,
                title: title,
                visitCount: visitCount,
                typedCount: typedCount,
                lastVisitTime: lastVisitTime,
                hidden: hidden,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String url,
                Value<String> title = const Value.absent(),
                Value<int> visitCount = const Value.absent(),
                Value<int> typedCount = const Value.absent(),
                required int lastVisitTime,
                Value<bool> hidden = const Value.absent(),
              }) => UrlsCompanion.insert(
                id: id,
                url: url,
                title: title,
                visitCount: visitCount,
                typedCount: typedCount,
                lastVisitTime: lastVisitTime,
                hidden: hidden,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UrlsTable, HistoryUrl>(table),
                  $$UrlsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({visitsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (visitsRefs) db.visits],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (visitsRefs)
                    await $_getPrefetchedDataByColumns<
                      HistoryUrl,
                      $UrlsTable,
                      HistoryVisit,
                      $VisitsTable
                    >(
                      currentTable: table,
                      referencedTable: $$UrlsTableReferences._visitsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$UrlsTableReferences(db, table, p0).visitsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'url_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UrlsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UrlsTable,
      HistoryUrl,
      $$UrlsTableFilterComposer,
      $$UrlsTableOrderingComposer,
      $$UrlsTableAnnotationComposer,
      $$UrlsTableCreateCompanionBuilder,
      $$UrlsTableUpdateCompanionBuilder,
      (HistoryUrl, $$UrlsTableReferences),
      HistoryUrl,
      PrefetchHooks Function({bool visitsRefs})
    >;
typedef $$VisitsTableCreateCompanionBuilder =
    VisitsCompanion Function({
      Value<int> id,
      required int urlId,
      required int visitTime,
      required PageTransition transition,
      Value<int?> fromVisit,
    });
typedef $$VisitsTableUpdateCompanionBuilder =
    VisitsCompanion Function({
      Value<int> id,
      Value<int> urlId,
      Value<int> visitTime,
      Value<PageTransition> transition,
      Value<int?> fromVisit,
    });

final class $$VisitsTableReferences
    extends BaseReferences<_$AppDatabase, $VisitsTable, HistoryVisit> {
  $$VisitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UrlsTable _urlIdTable(_$AppDatabase db) =>
      db.urls.createAlias('visits__url_id__urls__id');

  $$UrlsTableProcessedTableManager get urlId {
    final $_column = $_itemColumn<int>('url_id')!;

    final manager = $$UrlsTableTableManager(
      $_db,
      $_db.urls,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_urlIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VisitsTable _fromVisitTable(_$AppDatabase db) =>
      db.visits.createAlias('visits__from_visit__visits__id');

  $$VisitsTableProcessedTableManager? get fromVisit {
    final $_column = $_itemColumn<int>('from_visit');
    if ($_column == null) return null;
    final manager = $$VisitsTableTableManager(
      $_db,
      $_db.visits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromVisitTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VisitsTableFilterComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get visitTime => $composableBuilder(
    column: $table.visitTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PageTransition, PageTransition, String>
  get transition => $composableBuilder(
    column: $table.transition,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  $$UrlsTableFilterComposer get urlId {
    final $$UrlsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.urlId,
      referencedTable: $db.urls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UrlsTableFilterComposer(
            $db: $db,
            $table: $db.urls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitsTableFilterComposer get fromVisit {
    final $$VisitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromVisit,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableFilterComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitsTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visitTime => $composableBuilder(
    column: $table.visitTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transition => $composableBuilder(
    column: $table.transition,
    builder: (column) => ColumnOrderings(column),
  );

  $$UrlsTableOrderingComposer get urlId {
    final $$UrlsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.urlId,
      referencedTable: $db.urls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UrlsTableOrderingComposer(
            $db: $db,
            $table: $db.urls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitsTableOrderingComposer get fromVisit {
    final $$VisitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromVisit,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableOrderingComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitsTable> {
  $$VisitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get visitTime =>
      $composableBuilder(column: $table.visitTime, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PageTransition, String> get transition =>
      $composableBuilder(
        column: $table.transition,
        builder: (column) => column,
      );

  $$UrlsTableAnnotationComposer get urlId {
    final $$UrlsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.urlId,
      referencedTable: $db.urls,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UrlsTableAnnotationComposer(
            $db: $db,
            $table: $db.urls,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VisitsTableAnnotationComposer get fromVisit {
    final $$VisitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromVisit,
      referencedTable: $db.visits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitsTableAnnotationComposer(
            $db: $db,
            $table: $db.visits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitsTable,
          HistoryVisit,
          $$VisitsTableFilterComposer,
          $$VisitsTableOrderingComposer,
          $$VisitsTableAnnotationComposer,
          $$VisitsTableCreateCompanionBuilder,
          $$VisitsTableUpdateCompanionBuilder,
          (HistoryVisit, $$VisitsTableReferences),
          HistoryVisit,
          PrefetchHooks Function({bool urlId, bool fromVisit})
        > {
  $$VisitsTableTableManager(_$AppDatabase db, $VisitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> urlId = const Value.absent(),
                Value<int> visitTime = const Value.absent(),
                Value<PageTransition> transition = const Value.absent(),
                Value<int?> fromVisit = const Value.absent(),
              }) => VisitsCompanion(
                id: id,
                urlId: urlId,
                visitTime: visitTime,
                transition: transition,
                fromVisit: fromVisit,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int urlId,
                required int visitTime,
                required PageTransition transition,
                Value<int?> fromVisit = const Value.absent(),
              }) => VisitsCompanion.insert(
                id: id,
                urlId: urlId,
                visitTime: visitTime,
                transition: transition,
                fromVisit: fromVisit,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VisitsTable, HistoryVisit>(table),
                  $$VisitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({urlId = false, fromVisit = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (urlId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.urlId,
                                referencedTable: $$VisitsTableReferences
                                    ._urlIdTable(db),
                                referencedColumn: $$VisitsTableReferences
                                    ._urlIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (fromVisit) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.fromVisit,
                                referencedTable: $$VisitsTableReferences
                                    ._fromVisitTable(db),
                                referencedColumn: $$VisitsTableReferences
                                    ._fromVisitTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VisitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitsTable,
      HistoryVisit,
      $$VisitsTableFilterComposer,
      $$VisitsTableOrderingComposer,
      $$VisitsTableAnnotationComposer,
      $$VisitsTableCreateCompanionBuilder,
      $$VisitsTableUpdateCompanionBuilder,
      (HistoryVisit, $$VisitsTableReferences),
      HistoryVisit,
      PrefetchHooks Function({bool urlId, bool fromVisit})
    >;
typedef $$DownloadsTableCreateCompanionBuilder =
    DownloadsCompanion Function({
      Value<int> id,
      required int cefDownloadId,
      required String url,
      required String fileName,
      required String filePath,
      Value<int> totalBytes,
      Value<int> downloadedBytes,
      required int statusIndex,
      required int createdAt,
      Value<int?> completedAt,
      Value<String?> errorMessage,
    });
typedef $$DownloadsTableUpdateCompanionBuilder =
    DownloadsCompanion Function({
      Value<int> id,
      Value<int> cefDownloadId,
      Value<String> url,
      Value<String> fileName,
      Value<String> filePath,
      Value<int> totalBytes,
      Value<int> downloadedBytes,
      Value<int> statusIndex,
      Value<int> createdAt,
      Value<int?> completedAt,
      Value<String?> errorMessage,
    });

class $$DownloadsTableFilterComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cefDownloadId => $composableBuilder(
    column: $table.cefDownloadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statusIndex => $composableBuilder(
    column: $table.statusIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cefDownloadId => $composableBuilder(
    column: $table.cefDownloadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statusIndex => $composableBuilder(
    column: $table.statusIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get cefDownloadId => $composableBuilder(
    column: $table.cefDownloadId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get statusIndex => $composableBuilder(
    column: $table.statusIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$DownloadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DownloadsTable,
          DownloadEntity,
          $$DownloadsTableFilterComposer,
          $$DownloadsTableOrderingComposer,
          $$DownloadsTableAnnotationComposer,
          $$DownloadsTableCreateCompanionBuilder,
          $$DownloadsTableUpdateCompanionBuilder,
          (
            DownloadEntity,
            BaseReferences<_$AppDatabase, $DownloadsTable, DownloadEntity>,
          ),
          DownloadEntity,
          PrefetchHooks Function()
        > {
  $$DownloadsTableTableManager(_$AppDatabase db, $DownloadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> cefDownloadId = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<int> statusIndex = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => DownloadsCompanion(
                id: id,
                cefDownloadId: cefDownloadId,
                url: url,
                fileName: fileName,
                filePath: filePath,
                totalBytes: totalBytes,
                downloadedBytes: downloadedBytes,
                statusIndex: statusIndex,
                createdAt: createdAt,
                completedAt: completedAt,
                errorMessage: errorMessage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int cefDownloadId,
                required String url,
                required String fileName,
                required String filePath,
                Value<int> totalBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                required int statusIndex,
                required int createdAt,
                Value<int?> completedAt = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => DownloadsCompanion.insert(
                id: id,
                cefDownloadId: cefDownloadId,
                url: url,
                fileName: fileName,
                filePath: filePath,
                totalBytes: totalBytes,
                downloadedBytes: downloadedBytes,
                statusIndex: statusIndex,
                createdAt: createdAt,
                completedAt: completedAt,
                errorMessage: errorMessage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadsTable, DownloadEntity>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DownloadsTable,
                    DownloadEntity
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DownloadsTable,
      DownloadEntity,
      $$DownloadsTableFilterComposer,
      $$DownloadsTableOrderingComposer,
      $$DownloadsTableAnnotationComposer,
      $$DownloadsTableCreateCompanionBuilder,
      $$DownloadsTableUpdateCompanionBuilder,
      (
        DownloadEntity,
        BaseReferences<_$AppDatabase, $DownloadsTable, DownloadEntity>,
      ),
      DownloadEntity,
      PrefetchHooks Function()
    >;
typedef $$TabsTableCreateCompanionBuilder =
    TabsCompanion Function({
      Value<int> id,
      required String tabId,
      required int tabIndex,
      required String url,
      required String title,
      required bool isActive,
      Value<Uint8List?> screenshot,
    });
typedef $$TabsTableUpdateCompanionBuilder =
    TabsCompanion Function({
      Value<int> id,
      Value<String> tabId,
      Value<int> tabIndex,
      Value<String> url,
      Value<String> title,
      Value<bool> isActive,
      Value<Uint8List?> screenshot,
    });

class $$TabsTableFilterComposer extends Composer<_$AppDatabase, $TabsTable> {
  $$TabsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tabId => $composableBuilder(
    column: $table.tabId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tabIndex => $composableBuilder(
    column: $table.tabIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get screenshot => $composableBuilder(
    column: $table.screenshot,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TabsTableOrderingComposer extends Composer<_$AppDatabase, $TabsTable> {
  $$TabsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tabId => $composableBuilder(
    column: $table.tabId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tabIndex => $composableBuilder(
    column: $table.tabIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get screenshot => $composableBuilder(
    column: $table.screenshot,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TabsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TabsTable> {
  $$TabsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tabId =>
      $composableBuilder(column: $table.tabId, builder: (column) => column);

  GeneratedColumn<int> get tabIndex =>
      $composableBuilder(column: $table.tabIndex, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<Uint8List> get screenshot => $composableBuilder(
    column: $table.screenshot,
    builder: (column) => column,
  );
}

class $$TabsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TabsTable,
          TabEntity,
          $$TabsTableFilterComposer,
          $$TabsTableOrderingComposer,
          $$TabsTableAnnotationComposer,
          $$TabsTableCreateCompanionBuilder,
          $$TabsTableUpdateCompanionBuilder,
          (TabEntity, BaseReferences<_$AppDatabase, $TabsTable, TabEntity>),
          TabEntity,
          PrefetchHooks Function()
        > {
  $$TabsTableTableManager(_$AppDatabase db, $TabsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TabsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TabsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TabsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tabId = const Value.absent(),
                Value<int> tabIndex = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<Uint8List?> screenshot = const Value.absent(),
              }) => TabsCompanion(
                id: id,
                tabId: tabId,
                tabIndex: tabIndex,
                url: url,
                title: title,
                isActive: isActive,
                screenshot: screenshot,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tabId,
                required int tabIndex,
                required String url,
                required String title,
                required bool isActive,
                Value<Uint8List?> screenshot = const Value.absent(),
              }) => TabsCompanion.insert(
                id: id,
                tabId: tabId,
                tabIndex: tabIndex,
                url: url,
                title: title,
                isActive: isActive,
                screenshot: screenshot,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TabsTable, TabEntity>(table),
                  BaseReferences<_$AppDatabase, $TabsTable, TabEntity>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TabsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TabsTable,
      TabEntity,
      $$TabsTableFilterComposer,
      $$TabsTableOrderingComposer,
      $$TabsTableAnnotationComposer,
      $$TabsTableCreateCompanionBuilder,
      $$TabsTableUpdateCompanionBuilder,
      (TabEntity, BaseReferences<_$AppDatabase, $TabsTable, TabEntity>),
      TabEntity,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UrlsTableTableManager get urls => $$UrlsTableTableManager(_db, _db.urls);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db, _db.visits);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
  $$TabsTableTableManager get tabs => $$TabsTableTableManager(_db, _db.tabs);
}
