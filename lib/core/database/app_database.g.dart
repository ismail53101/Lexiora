// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $DocumentsTable extends Documents
    with TableInfo<$DocumentsTable, DocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 512,
    ),
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
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coverPathMeta = const VerificationMeta(
    'coverPath',
  );
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
    'cover_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _managedFileMeta = const VerificationMeta(
    'managedFile',
  );
  @override
  late final GeneratedColumn<bool> managedFile = GeneratedColumn<bool>(
    'managed_file',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("managed_file" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    fileName,
    filePath,
    fileSize,
    pageCount,
    coverPath,
    categoryId,
    isFavorite,
    importedAt,
    lastOpenedAt,
    managedFile,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
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
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    }
    if (data.containsKey('cover_path')) {
      context.handle(
        _coverPathMeta,
        coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('managed_file')) {
      context.handle(
        _managedFileMeta,
        managedFile.isAcceptableOrUnknown(
          data['managed_file']!,
          _managedFileMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      coverPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_path'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
      managedFile: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}managed_file'],
      )!,
    );
  }

  @override
  $DocumentsTable createAlias(String alias) {
    return $DocumentsTable(attachedDatabase, alias);
  }
}

class DocumentRow extends DataClass implements Insertable<DocumentRow> {
  final String id;
  final String title;
  final String fileName;
  final String filePath;
  final int fileSize;
  final int pageCount;
  final String? coverPath;
  final String? categoryId;
  final bool isFavorite;
  final DateTime importedAt;
  final DateTime? lastOpenedAt;

  /// True when the file at [filePath] is a private copy the app made during
  /// manual import (stored under the app's files dir). Such files are deleted
  /// when the document is removed. Auto-discovered documents reference the
  /// user's own file in place ([managedFile] = false) and are never deleted.
  final bool managedFile;
  const DocumentRow({
    required this.id,
    required this.title,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.pageCount,
    this.coverPath,
    this.categoryId,
    required this.isFavorite,
    required this.importedAt,
    this.lastOpenedAt,
    required this.managedFile,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['file_name'] = Variable<String>(fileName);
    map['file_path'] = Variable<String>(filePath);
    map['file_size'] = Variable<int>(fileSize);
    map['page_count'] = Variable<int>(pageCount);
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['imported_at'] = Variable<DateTime>(importedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    map['managed_file'] = Variable<bool>(managedFile);
    return map;
  }

  DocumentsCompanion toCompanion(bool nullToAbsent) {
    return DocumentsCompanion(
      id: Value(id),
      title: Value(title),
      fileName: Value(fileName),
      filePath: Value(filePath),
      fileSize: Value(fileSize),
      pageCount: Value(pageCount),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      isFavorite: Value(isFavorite),
      importedAt: Value(importedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      managedFile: Value(managedFile),
    );
  }

  factory DocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      fileName: serializer.fromJson<String>(json['fileName']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      managedFile: serializer.fromJson<bool>(json['managedFile']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'fileName': serializer.toJson<String>(fileName),
      'filePath': serializer.toJson<String>(filePath),
      'fileSize': serializer.toJson<int>(fileSize),
      'pageCount': serializer.toJson<int>(pageCount),
      'coverPath': serializer.toJson<String?>(coverPath),
      'categoryId': serializer.toJson<String?>(categoryId),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'managedFile': serializer.toJson<bool>(managedFile),
    };
  }

  DocumentRow copyWith({
    String? id,
    String? title,
    String? fileName,
    String? filePath,
    int? fileSize,
    int? pageCount,
    Value<String?> coverPath = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    bool? isFavorite,
    DateTime? importedAt,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
    bool? managedFile,
  }) => DocumentRow(
    id: id ?? this.id,
    title: title ?? this.title,
    fileName: fileName ?? this.fileName,
    filePath: filePath ?? this.filePath,
    fileSize: fileSize ?? this.fileSize,
    pageCount: pageCount ?? this.pageCount,
    coverPath: coverPath.present ? coverPath.value : this.coverPath,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    isFavorite: isFavorite ?? this.isFavorite,
    importedAt: importedAt ?? this.importedAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    managedFile: managedFile ?? this.managedFile,
  );
  DocumentRow copyWithCompanion(DocumentsCompanion data) {
    return DocumentRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      managedFile: data.managedFile.present
          ? data.managedFile.value
          : this.managedFile,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('pageCount: $pageCount, ')
          ..write('coverPath: $coverPath, ')
          ..write('categoryId: $categoryId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('importedAt: $importedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('managedFile: $managedFile')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    fileName,
    filePath,
    fileSize,
    pageCount,
    coverPath,
    categoryId,
    isFavorite,
    importedAt,
    lastOpenedAt,
    managedFile,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.fileName == this.fileName &&
          other.filePath == this.filePath &&
          other.fileSize == this.fileSize &&
          other.pageCount == this.pageCount &&
          other.coverPath == this.coverPath &&
          other.categoryId == this.categoryId &&
          other.isFavorite == this.isFavorite &&
          other.importedAt == this.importedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.managedFile == this.managedFile);
}

class DocumentsCompanion extends UpdateCompanion<DocumentRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> fileName;
  final Value<String> filePath;
  final Value<int> fileSize;
  final Value<int> pageCount;
  final Value<String?> coverPath;
  final Value<String?> categoryId;
  final Value<bool> isFavorite;
  final Value<DateTime> importedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<bool> managedFile;
  final Value<int> rowid;
  const DocumentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.fileName = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.managedFile = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentsCompanion.insert({
    required String id,
    required String title,
    required String fileName,
    required String filePath,
    this.fileSize = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.isFavorite = const Value.absent(),
    required DateTime importedAt,
    this.lastOpenedAt = const Value.absent(),
    this.managedFile = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       fileName = Value(fileName),
       filePath = Value(filePath),
       importedAt = Value(importedAt);
  static Insertable<DocumentRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? fileName,
    Expression<String>? filePath,
    Expression<int>? fileSize,
    Expression<int>? pageCount,
    Expression<String>? coverPath,
    Expression<String>? categoryId,
    Expression<bool>? isFavorite,
    Expression<DateTime>? importedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<bool>? managedFile,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (fileName != null) 'file_name': fileName,
      if (filePath != null) 'file_path': filePath,
      if (fileSize != null) 'file_size': fileSize,
      if (pageCount != null) 'page_count': pageCount,
      if (coverPath != null) 'cover_path': coverPath,
      if (categoryId != null) 'category_id': categoryId,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (importedAt != null) 'imported_at': importedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (managedFile != null) 'managed_file': managedFile,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? fileName,
    Value<String>? filePath,
    Value<int>? fileSize,
    Value<int>? pageCount,
    Value<String?>? coverPath,
    Value<String?>? categoryId,
    Value<bool>? isFavorite,
    Value<DateTime>? importedAt,
    Value<DateTime?>? lastOpenedAt,
    Value<bool>? managedFile,
    Value<int>? rowid,
  }) {
    return DocumentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      coverPath: coverPath ?? this.coverPath,
      categoryId: categoryId ?? this.categoryId,
      isFavorite: isFavorite ?? this.isFavorite,
      importedAt: importedAt ?? this.importedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      managedFile: managedFile ?? this.managedFile,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (managedFile.present) {
      map['managed_file'] = Variable<bool>(managedFile.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('fileName: $fileName, ')
          ..write('filePath: $filePath, ')
          ..write('fileSize: $fileSize, ')
          ..write('pageCount: $pageCount, ')
          ..write('coverPath: $coverPath, ')
          ..write('categoryId: $categoryId, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('importedAt: $importedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('managedFile: $managedFile, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 128,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, colorValue, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String id;
  final String name;
  final int colorValue;
  final DateTime createdAt;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['color_value'] = Variable<int>(colorValue);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      colorValue: Value(colorValue),
      createdAt: Value(createdAt),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'colorValue': serializer.toJson<int>(colorValue),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CategoryRow copyWith({
    String? id,
    String? name,
    int? colorValue,
    DateTime? createdAt,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
    createdAt: createdAt ?? this.createdAt,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, colorValue, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.colorValue == this.colorValue &&
          other.createdAt == this.createdAt);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> colorValue;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required int colorValue,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       colorValue = Value(colorValue),
       createdAt = Value(createdAt);
  static Insertable<CategoryRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? colorValue,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (colorValue != null) 'color_value': colorValue,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? colorValue,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('colorValue: $colorValue, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookmarksTable extends Bookmarks
    with TableInfo<$BookmarksTable, BookmarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    pageNumber,
    label,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookmarkRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookmarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookmarkRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BookmarksTable createAlias(String alias) {
    return $BookmarksTable(attachedDatabase, alias);
  }
}

class BookmarkRow extends DataClass implements Insertable<BookmarkRow> {
  final String id;
  final String documentId;
  final int pageNumber;
  final String? label;
  final DateTime createdAt;
  const BookmarkRow({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    this.label,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['page_number'] = Variable<int>(pageNumber);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BookmarksCompanion toCompanion(bool nullToAbsent) {
    return BookmarksCompanion(
      id: Value(id),
      documentId: Value(documentId),
      pageNumber: Value(pageNumber),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      createdAt: Value(createdAt),
    );
  }

  factory BookmarkRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookmarkRow(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      label: serializer.fromJson<String?>(json['label']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'label': serializer.toJson<String?>(label),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BookmarkRow copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    Value<String?> label = const Value.absent(),
    DateTime? createdAt,
  }) => BookmarkRow(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    pageNumber: pageNumber ?? this.pageNumber,
    label: label.present ? label.value : this.label,
    createdAt: createdAt ?? this.createdAt,
  );
  BookmarkRow copyWithCompanion(BookmarksCompanion data) {
    return BookmarkRow(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookmarkRow(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, documentId, pageNumber, label, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookmarkRow &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.pageNumber == this.pageNumber &&
          other.label == this.label &&
          other.createdAt == this.createdAt);
}

class BookmarksCompanion extends UpdateCompanion<BookmarkRow> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<int> pageNumber;
  final Value<String?> label;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BookmarksCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookmarksCompanion.insert({
    required String id,
    required String documentId,
    required int pageNumber,
    this.label = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       pageNumber = Value(pageNumber),
       createdAt = Value(createdAt);
  static Insertable<BookmarkRow> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<int>? pageNumber,
    Expression<String>? label,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookmarksCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<int>? pageNumber,
    Value<String?>? label,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BookmarksCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookmarksCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HighlightsTable extends Highlights
    with TableInfo<$HighlightsTable, HighlightRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HighlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _colorValueMeta = const VerificationMeta(
    'colorValue',
  );
  @override
  late final GeneratedColumn<int> colorValue = GeneratedColumn<int>(
    'color_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedTextMeta = const VerificationMeta(
    'selectedText',
  );
  @override
  late final GeneratedColumn<String> selectedText = GeneratedColumn<String>(
    'selected_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<NormalizedRect>, String>
  rects = GeneratedColumn<String>(
    'rects',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<NormalizedRect>>($HighlightsTable.$converterrects);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    pageNumber,
    type,
    colorValue,
    selectedText,
    rects,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'highlights';
  @override
  VerificationContext validateIntegrity(
    Insertable<HighlightRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('color_value')) {
      context.handle(
        _colorValueMeta,
        colorValue.isAcceptableOrUnknown(data['color_value']!, _colorValueMeta),
      );
    } else if (isInserting) {
      context.missing(_colorValueMeta);
    }
    if (data.containsKey('selected_text')) {
      context.handle(
        _selectedTextMeta,
        selectedText.isAcceptableOrUnknown(
          data['selected_text']!,
          _selectedTextMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HighlightRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HighlightRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      colorValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_value'],
      )!,
      selectedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_text'],
      )!,
      rects: $HighlightsTable.$converterrects.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}rects'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HighlightsTable createAlias(String alias) {
    return $HighlightsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<NormalizedRect>, String> $converterrects =
      const NormalizedRectListConverter();
}

class HighlightRow extends DataClass implements Insertable<HighlightRow> {
  final String id;
  final String documentId;
  final int pageNumber;

  /// Mirrors `AnnotationType.index`: 0 = highlight, 1 = underline.
  final int type;
  final int colorValue;
  final String selectedText;
  final List<NormalizedRect> rects;
  final DateTime createdAt;
  final DateTime updatedAt;
  const HighlightRow({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.type,
    required this.colorValue,
    required this.selectedText,
    required this.rects,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['page_number'] = Variable<int>(pageNumber);
    map['type'] = Variable<int>(type);
    map['color_value'] = Variable<int>(colorValue);
    map['selected_text'] = Variable<String>(selectedText);
    {
      map['rects'] = Variable<String>(
        $HighlightsTable.$converterrects.toSql(rects),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HighlightsCompanion toCompanion(bool nullToAbsent) {
    return HighlightsCompanion(
      id: Value(id),
      documentId: Value(documentId),
      pageNumber: Value(pageNumber),
      type: Value(type),
      colorValue: Value(colorValue),
      selectedText: Value(selectedText),
      rects: Value(rects),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory HighlightRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HighlightRow(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      type: serializer.fromJson<int>(json['type']),
      colorValue: serializer.fromJson<int>(json['colorValue']),
      selectedText: serializer.fromJson<String>(json['selectedText']),
      rects: serializer.fromJson<List<NormalizedRect>>(json['rects']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'type': serializer.toJson<int>(type),
      'colorValue': serializer.toJson<int>(colorValue),
      'selectedText': serializer.toJson<String>(selectedText),
      'rects': serializer.toJson<List<NormalizedRect>>(rects),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  HighlightRow copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    int? type,
    int? colorValue,
    String? selectedText,
    List<NormalizedRect>? rects,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => HighlightRow(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    pageNumber: pageNumber ?? this.pageNumber,
    type: type ?? this.type,
    colorValue: colorValue ?? this.colorValue,
    selectedText: selectedText ?? this.selectedText,
    rects: rects ?? this.rects,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  HighlightRow copyWithCompanion(HighlightsCompanion data) {
    return HighlightRow(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      type: data.type.present ? data.type.value : this.type,
      colorValue: data.colorValue.present
          ? data.colorValue.value
          : this.colorValue,
      selectedText: data.selectedText.present
          ? data.selectedText.value
          : this.selectedText,
      rects: data.rects.present ? data.rects.value : this.rects,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HighlightRow(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('type: $type, ')
          ..write('colorValue: $colorValue, ')
          ..write('selectedText: $selectedText, ')
          ..write('rects: $rects, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    pageNumber,
    type,
    colorValue,
    selectedText,
    rects,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HighlightRow &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.pageNumber == this.pageNumber &&
          other.type == this.type &&
          other.colorValue == this.colorValue &&
          other.selectedText == this.selectedText &&
          other.rects == this.rects &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HighlightsCompanion extends UpdateCompanion<HighlightRow> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<int> pageNumber;
  final Value<int> type;
  final Value<int> colorValue;
  final Value<String> selectedText;
  final Value<List<NormalizedRect>> rects;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HighlightsCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.type = const Value.absent(),
    this.colorValue = const Value.absent(),
    this.selectedText = const Value.absent(),
    this.rects = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HighlightsCompanion.insert({
    required String id,
    required String documentId,
    required int pageNumber,
    this.type = const Value.absent(),
    required int colorValue,
    this.selectedText = const Value.absent(),
    required List<NormalizedRect> rects,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       pageNumber = Value(pageNumber),
       colorValue = Value(colorValue),
       rects = Value(rects),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HighlightRow> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<int>? pageNumber,
    Expression<int>? type,
    Expression<int>? colorValue,
    Expression<String>? selectedText,
    Expression<String>? rects,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (type != null) 'type': type,
      if (colorValue != null) 'color_value': colorValue,
      if (selectedText != null) 'selected_text': selectedText,
      if (rects != null) 'rects': rects,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HighlightsCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<int>? pageNumber,
    Value<int>? type,
    Value<int>? colorValue,
    Value<String>? selectedText,
    Value<List<NormalizedRect>>? rects,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HighlightsCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      type: type ?? this.type,
      colorValue: colorValue ?? this.colorValue,
      selectedText: selectedText ?? this.selectedText,
      rects: rects ?? this.rects,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (colorValue.present) {
      map['color_value'] = Variable<int>(colorValue.value);
    }
    if (selectedText.present) {
      map['selected_text'] = Variable<String>(selectedText.value);
    }
    if (rects.present) {
      map['rects'] = Variable<String>(
        $HighlightsTable.$converterrects.toSql(rects.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HighlightsCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('type: $type, ')
          ..write('colorValue: $colorValue, ')
          ..write('selectedText: $selectedText, ')
          ..write('rects: $rects, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anchorTypeMeta = const VerificationMeta(
    'anchorType',
  );
  @override
  late final GeneratedColumn<int> anchorType = GeneratedColumn<int>(
    'anchor_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _selectedTextMeta = const VerificationMeta(
    'selectedText',
  );
  @override
  late final GeneratedColumn<String> selectedText = GeneratedColumn<String>(
    'selected_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<List<NormalizedRect>, String>
  rects = GeneratedColumn<String>(
    'rects',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<List<NormalizedRect>>($NotesTable.$converterrects);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    pageNumber,
    content,
    anchorType,
    selectedText,
    rects,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('anchor_type')) {
      context.handle(
        _anchorTypeMeta,
        anchorType.isAcceptableOrUnknown(data['anchor_type']!, _anchorTypeMeta),
      );
    }
    if (data.containsKey('selected_text')) {
      context.handle(
        _selectedTextMeta,
        selectedText.isAcceptableOrUnknown(
          data['selected_text']!,
          _selectedTextMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      anchorType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anchor_type'],
      )!,
      selectedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_text'],
      ),
      rects: $NotesTable.$converterrects.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}rects'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<NormalizedRect>, String> $converterrects =
      const NormalizedRectListConverter();
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final String id;
  final String documentId;
  final int pageNumber;
  final String content;

  /// Mirrors `NoteAnchor.index`: 0 = page, 1 = selection.
  final int anchorType;
  final String? selectedText;

  /// Normalized rects for selection-anchored notes; empty list for page notes.
  final List<NormalizedRect> rects;
  final DateTime createdAt;
  final DateTime updatedAt;
  const NoteRow({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.content,
    required this.anchorType,
    this.selectedText,
    required this.rects,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['page_number'] = Variable<int>(pageNumber);
    map['content'] = Variable<String>(content);
    map['anchor_type'] = Variable<int>(anchorType);
    if (!nullToAbsent || selectedText != null) {
      map['selected_text'] = Variable<String>(selectedText);
    }
    {
      map['rects'] = Variable<String>($NotesTable.$converterrects.toSql(rects));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      documentId: Value(documentId),
      pageNumber: Value(pageNumber),
      content: Value(content),
      anchorType: Value(anchorType),
      selectedText: selectedText == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedText),
      rects: Value(rects),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      content: serializer.fromJson<String>(json['content']),
      anchorType: serializer.fromJson<int>(json['anchorType']),
      selectedText: serializer.fromJson<String?>(json['selectedText']),
      rects: serializer.fromJson<List<NormalizedRect>>(json['rects']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'content': serializer.toJson<String>(content),
      'anchorType': serializer.toJson<int>(anchorType),
      'selectedText': serializer.toJson<String?>(selectedText),
      'rects': serializer.toJson<List<NormalizedRect>>(rects),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NoteRow copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    String? content,
    int? anchorType,
    Value<String?> selectedText = const Value.absent(),
    List<NormalizedRect>? rects,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NoteRow(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    pageNumber: pageNumber ?? this.pageNumber,
    content: content ?? this.content,
    anchorType: anchorType ?? this.anchorType,
    selectedText: selectedText.present ? selectedText.value : this.selectedText,
    rects: rects ?? this.rects,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      content: data.content.present ? data.content.value : this.content,
      anchorType: data.anchorType.present
          ? data.anchorType.value
          : this.anchorType,
      selectedText: data.selectedText.present
          ? data.selectedText.value
          : this.selectedText,
      rects: data.rects.present ? data.rects.value : this.rects,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('content: $content, ')
          ..write('anchorType: $anchorType, ')
          ..write('selectedText: $selectedText, ')
          ..write('rects: $rects, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    pageNumber,
    content,
    anchorType,
    selectedText,
    rects,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.pageNumber == this.pageNumber &&
          other.content == this.content &&
          other.anchorType == this.anchorType &&
          other.selectedText == this.selectedText &&
          other.rects == this.rects &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<int> pageNumber;
  final Value<String> content;
  final Value<int> anchorType;
  final Value<String?> selectedText;
  final Value<List<NormalizedRect>> rects;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.content = const Value.absent(),
    this.anchorType = const Value.absent(),
    this.selectedText = const Value.absent(),
    this.rects = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    required String documentId,
    required int pageNumber,
    required String content,
    this.anchorType = const Value.absent(),
    this.selectedText = const Value.absent(),
    required List<NormalizedRect> rects,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       pageNumber = Value(pageNumber),
       content = Value(content),
       rects = Value(rects),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NoteRow> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<int>? pageNumber,
    Expression<String>? content,
    Expression<int>? anchorType,
    Expression<String>? selectedText,
    Expression<String>? rects,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (content != null) 'content': content,
      if (anchorType != null) 'anchor_type': anchorType,
      if (selectedText != null) 'selected_text': selectedText,
      if (rects != null) 'rects': rects,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<int>? pageNumber,
    Value<String>? content,
    Value<int>? anchorType,
    Value<String?>? selectedText,
    Value<List<NormalizedRect>>? rects,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      content: content ?? this.content,
      anchorType: anchorType ?? this.anchorType,
      selectedText: selectedText ?? this.selectedText,
      rects: rects ?? this.rects,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (anchorType.present) {
      map['anchor_type'] = Variable<int>(anchorType.value);
    }
    if (selectedText.present) {
      map['selected_text'] = Variable<String>(selectedText.value);
    }
    if (rects.present) {
      map['rects'] = Variable<String>(
        $NotesTable.$converterrects.toSql(rects.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('content: $content, ')
          ..write('anchorType: $anchorType, ')
          ..write('selectedText: $selectedText, ')
          ..write('rects: $rects, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingProgressTable extends ReadingProgress
    with TableInfo<$ReadingProgressTable, ReadingProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastPageMeta = const VerificationMeta(
    'lastPage',
  );
  @override
  late final GeneratedColumn<int> lastPage = GeneratedColumn<int>(
    'last_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _totalPagesMeta = const VerificationMeta(
    'totalPages',
  );
  @override
  late final GeneratedColumn<int> totalPages = GeneratedColumn<int>(
    'total_pages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _percentMeta = const VerificationMeta(
    'percent',
  );
  @override
  late final GeneratedColumn<double> percent = GeneratedColumn<double>(
    'percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    lastPage,
    totalPages,
    percent,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('last_page')) {
      context.handle(
        _lastPageMeta,
        lastPage.isAcceptableOrUnknown(data['last_page']!, _lastPageMeta),
      );
    }
    if (data.containsKey('total_pages')) {
      context.handle(
        _totalPagesMeta,
        totalPages.isAcceptableOrUnknown(data['total_pages']!, _totalPagesMeta),
      );
    }
    if (data.containsKey('percent')) {
      context.handle(
        _percentMeta,
        percent.isAcceptableOrUnknown(data['percent']!, _percentMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  ReadingProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingProgressRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      lastPage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_page'],
      )!,
      totalPages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages'],
      )!,
      percent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percent'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReadingProgressTable createAlias(String alias) {
    return $ReadingProgressTable(attachedDatabase, alias);
  }
}

class ReadingProgressRow extends DataClass
    implements Insertable<ReadingProgressRow> {
  final String documentId;
  final int lastPage;
  final int totalPages;
  final double percent;
  final DateTime updatedAt;
  const ReadingProgressRow({
    required this.documentId,
    required this.lastPage,
    required this.totalPages,
    required this.percent,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['last_page'] = Variable<int>(lastPage);
    map['total_pages'] = Variable<int>(totalPages);
    map['percent'] = Variable<double>(percent);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReadingProgressCompanion toCompanion(bool nullToAbsent) {
    return ReadingProgressCompanion(
      documentId: Value(documentId),
      lastPage: Value(lastPage),
      totalPages: Value(totalPages),
      percent: Value(percent),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReadingProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingProgressRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      lastPage: serializer.fromJson<int>(json['lastPage']),
      totalPages: serializer.fromJson<int>(json['totalPages']),
      percent: serializer.fromJson<double>(json['percent']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'lastPage': serializer.toJson<int>(lastPage),
      'totalPages': serializer.toJson<int>(totalPages),
      'percent': serializer.toJson<double>(percent),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReadingProgressRow copyWith({
    String? documentId,
    int? lastPage,
    int? totalPages,
    double? percent,
    DateTime? updatedAt,
  }) => ReadingProgressRow(
    documentId: documentId ?? this.documentId,
    lastPage: lastPage ?? this.lastPage,
    totalPages: totalPages ?? this.totalPages,
    percent: percent ?? this.percent,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReadingProgressRow copyWithCompanion(ReadingProgressCompanion data) {
    return ReadingProgressRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      lastPage: data.lastPage.present ? data.lastPage.value : this.lastPage,
      totalPages: data.totalPages.present
          ? data.totalPages.value
          : this.totalPages,
      percent: data.percent.present ? data.percent.value : this.percent,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressRow(')
          ..write('documentId: $documentId, ')
          ..write('lastPage: $lastPage, ')
          ..write('totalPages: $totalPages, ')
          ..write('percent: $percent, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(documentId, lastPage, totalPages, percent, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgressRow &&
          other.documentId == this.documentId &&
          other.lastPage == this.lastPage &&
          other.totalPages == this.totalPages &&
          other.percent == this.percent &&
          other.updatedAt == this.updatedAt);
}

class ReadingProgressCompanion extends UpdateCompanion<ReadingProgressRow> {
  final Value<String> documentId;
  final Value<int> lastPage;
  final Value<int> totalPages;
  final Value<double> percent;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReadingProgressCompanion({
    this.documentId = const Value.absent(),
    this.lastPage = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.percent = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingProgressCompanion.insert({
    required String documentId,
    this.lastPage = const Value.absent(),
    this.totalPages = const Value.absent(),
    this.percent = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       updatedAt = Value(updatedAt);
  static Insertable<ReadingProgressRow> custom({
    Expression<String>? documentId,
    Expression<int>? lastPage,
    Expression<int>? totalPages,
    Expression<double>? percent,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (lastPage != null) 'last_page': lastPage,
      if (totalPages != null) 'total_pages': totalPages,
      if (percent != null) 'percent': percent,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingProgressCompanion copyWith({
    Value<String>? documentId,
    Value<int>? lastPage,
    Value<int>? totalPages,
    Value<double>? percent,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReadingProgressCompanion(
      documentId: documentId ?? this.documentId,
      lastPage: lastPage ?? this.lastPage,
      totalPages: totalPages ?? this.totalPages,
      percent: percent ?? this.percent,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (lastPage.present) {
      map['last_page'] = Variable<int>(lastPage.value);
    }
    if (totalPages.present) {
      map['total_pages'] = Variable<int>(totalPages.value);
    }
    if (percent.present) {
      map['percent'] = Variable<double>(percent.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressCompanion(')
          ..write('documentId: $documentId, ')
          ..write('lastPage: $lastPage, ')
          ..write('totalPages: $totalPages, ')
          ..write('percent: $percent, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTable extends ReadingSessions
    with TableInfo<$ReadingSessionsTable, ReadingSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, documentId, pageNumber, openedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
    );
  }

  @override
  $ReadingSessionsTable createAlias(String alias) {
    return $ReadingSessionsTable(attachedDatabase, alias);
  }
}

class ReadingSessionRow extends DataClass
    implements Insertable<ReadingSessionRow> {
  final String id;
  final String documentId;
  final int pageNumber;
  final DateTime openedAt;
  const ReadingSessionRow({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.openedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['page_number'] = Variable<int>(pageNumber);
    map['opened_at'] = Variable<DateTime>(openedAt);
    return map;
  }

  ReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsCompanion(
      id: Value(id),
      documentId: Value(documentId),
      pageNumber: Value(pageNumber),
      openedAt: Value(openedAt),
    );
  }

  factory ReadingSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSessionRow(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'openedAt': serializer.toJson<DateTime>(openedAt),
    };
  }

  ReadingSessionRow copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    DateTime? openedAt,
  }) => ReadingSessionRow(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    pageNumber: pageNumber ?? this.pageNumber,
    openedAt: openedAt ?? this.openedAt,
  );
  ReadingSessionRow copyWithCompanion(ReadingSessionsCompanion data) {
    return ReadingSessionRow(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionRow(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('openedAt: $openedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, documentId, pageNumber, openedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSessionRow &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.pageNumber == this.pageNumber &&
          other.openedAt == this.openedAt);
}

class ReadingSessionsCompanion extends UpdateCompanion<ReadingSessionRow> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<int> pageNumber;
  final Value<DateTime> openedAt;
  final Value<int> rowid;
  const ReadingSessionsCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingSessionsCompanion.insert({
    required String id,
    required String documentId,
    required int pageNumber,
    required DateTime openedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       pageNumber = Value(pageNumber),
       openedAt = Value(openedAt);
  static Insertable<ReadingSessionRow> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<int>? pageNumber,
    Expression<DateTime>? openedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (openedAt != null) 'opened_at': openedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<int>? pageNumber,
    Value<DateTime>? openedAt,
    Value<int>? rowid,
  }) {
    return ReadingSessionsCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      openedAt: openedAt ?? this.openedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('openedAt: $openedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DictionaryEntriesTable extends DictionaryEntries
    with TableInfo<$DictionaryEntriesTable, DictionaryEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordLowerMeta = const VerificationMeta(
    'wordLower',
  );
  @override
  late final GeneratedColumn<String> wordLower = GeneratedColumn<String>(
    'word_lower',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipaPronunciationMeta = const VerificationMeta(
    'ipaPronunciation',
  );
  @override
  late final GeneratedColumn<String> ipaPronunciation = GeneratedColumn<String>(
    'ipa_pronunciation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exampleSentenceMeta = const VerificationMeta(
    'exampleSentence',
  );
  @override
  late final GeneratedColumn<String> exampleSentence = GeneratedColumn<String>(
    'example_sentence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    word,
    wordLower,
    partOfSpeech,
    meaning,
    ipaPronunciation,
    exampleSentence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('word_lower')) {
      context.handle(
        _wordLowerMeta,
        wordLower.isAcceptableOrUnknown(data['word_lower']!, _wordLowerMeta),
      );
    } else if (isInserting) {
      context.missing(_wordLowerMeta);
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('ipa_pronunciation')) {
      context.handle(
        _ipaPronunciationMeta,
        ipaPronunciation.isAcceptableOrUnknown(
          data['ipa_pronunciation']!,
          _ipaPronunciationMeta,
        ),
      );
    }
    if (data.containsKey('example_sentence')) {
      context.handle(
        _exampleSentenceMeta,
        exampleSentence.isAcceptableOrUnknown(
          data['example_sentence']!,
          _exampleSentenceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DictionaryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      wordLower: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_lower'],
      )!,
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      ),
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      ipaPronunciation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ipa_pronunciation'],
      ),
      exampleSentence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}example_sentence'],
      ),
    );
  }

  @override
  $DictionaryEntriesTable createAlias(String alias) {
    return $DictionaryEntriesTable(attachedDatabase, alias);
  }
}

class DictionaryEntryRow extends DataClass
    implements Insertable<DictionaryEntryRow> {
  final int id;

  /// Headword as displayed (original casing), e.g. "Apple".
  final String word;

  /// Lowercased headword used for indexed, case-insensitive search.
  final String wordLower;

  /// Grammatical category, e.g. "noun" (nullable — not every source has it).
  final String? partOfSpeech;

  /// The definition text for this sense.
  final String meaning;

  /// IPA pronunciation, when available (the bundled set does not include it).
  final String? ipaPronunciation;

  /// An example sentence for this sense, when available.
  final String? exampleSentence;
  const DictionaryEntryRow({
    required this.id,
    required this.word,
    required this.wordLower,
    this.partOfSpeech,
    required this.meaning,
    this.ipaPronunciation,
    this.exampleSentence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['word'] = Variable<String>(word);
    map['word_lower'] = Variable<String>(wordLower);
    if (!nullToAbsent || partOfSpeech != null) {
      map['part_of_speech'] = Variable<String>(partOfSpeech);
    }
    map['meaning'] = Variable<String>(meaning);
    if (!nullToAbsent || ipaPronunciation != null) {
      map['ipa_pronunciation'] = Variable<String>(ipaPronunciation);
    }
    if (!nullToAbsent || exampleSentence != null) {
      map['example_sentence'] = Variable<String>(exampleSentence);
    }
    return map;
  }

  DictionaryEntriesCompanion toCompanion(bool nullToAbsent) {
    return DictionaryEntriesCompanion(
      id: Value(id),
      word: Value(word),
      wordLower: Value(wordLower),
      partOfSpeech: partOfSpeech == null && nullToAbsent
          ? const Value.absent()
          : Value(partOfSpeech),
      meaning: Value(meaning),
      ipaPronunciation: ipaPronunciation == null && nullToAbsent
          ? const Value.absent()
          : Value(ipaPronunciation),
      exampleSentence: exampleSentence == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleSentence),
    );
  }

  factory DictionaryEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryEntryRow(
      id: serializer.fromJson<int>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      wordLower: serializer.fromJson<String>(json['wordLower']),
      partOfSpeech: serializer.fromJson<String?>(json['partOfSpeech']),
      meaning: serializer.fromJson<String>(json['meaning']),
      ipaPronunciation: serializer.fromJson<String?>(json['ipaPronunciation']),
      exampleSentence: serializer.fromJson<String?>(json['exampleSentence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'word': serializer.toJson<String>(word),
      'wordLower': serializer.toJson<String>(wordLower),
      'partOfSpeech': serializer.toJson<String?>(partOfSpeech),
      'meaning': serializer.toJson<String>(meaning),
      'ipaPronunciation': serializer.toJson<String?>(ipaPronunciation),
      'exampleSentence': serializer.toJson<String?>(exampleSentence),
    };
  }

  DictionaryEntryRow copyWith({
    int? id,
    String? word,
    String? wordLower,
    Value<String?> partOfSpeech = const Value.absent(),
    String? meaning,
    Value<String?> ipaPronunciation = const Value.absent(),
    Value<String?> exampleSentence = const Value.absent(),
  }) => DictionaryEntryRow(
    id: id ?? this.id,
    word: word ?? this.word,
    wordLower: wordLower ?? this.wordLower,
    partOfSpeech: partOfSpeech.present ? partOfSpeech.value : this.partOfSpeech,
    meaning: meaning ?? this.meaning,
    ipaPronunciation: ipaPronunciation.present
        ? ipaPronunciation.value
        : this.ipaPronunciation,
    exampleSentence: exampleSentence.present
        ? exampleSentence.value
        : this.exampleSentence,
  );
  DictionaryEntryRow copyWithCompanion(DictionaryEntriesCompanion data) {
    return DictionaryEntryRow(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      wordLower: data.wordLower.present ? data.wordLower.value : this.wordLower,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      ipaPronunciation: data.ipaPronunciation.present
          ? data.ipaPronunciation.value
          : this.ipaPronunciation,
      exampleSentence: data.exampleSentence.present
          ? data.exampleSentence.value
          : this.exampleSentence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryEntryRow(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('wordLower: $wordLower, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('meaning: $meaning, ')
          ..write('ipaPronunciation: $ipaPronunciation, ')
          ..write('exampleSentence: $exampleSentence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    word,
    wordLower,
    partOfSpeech,
    meaning,
    ipaPronunciation,
    exampleSentence,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryEntryRow &&
          other.id == this.id &&
          other.word == this.word &&
          other.wordLower == this.wordLower &&
          other.partOfSpeech == this.partOfSpeech &&
          other.meaning == this.meaning &&
          other.ipaPronunciation == this.ipaPronunciation &&
          other.exampleSentence == this.exampleSentence);
}

class DictionaryEntriesCompanion extends UpdateCompanion<DictionaryEntryRow> {
  final Value<int> id;
  final Value<String> word;
  final Value<String> wordLower;
  final Value<String?> partOfSpeech;
  final Value<String> meaning;
  final Value<String?> ipaPronunciation;
  final Value<String?> exampleSentence;
  const DictionaryEntriesCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.wordLower = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.meaning = const Value.absent(),
    this.ipaPronunciation = const Value.absent(),
    this.exampleSentence = const Value.absent(),
  });
  DictionaryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String word,
    required String wordLower,
    this.partOfSpeech = const Value.absent(),
    required String meaning,
    this.ipaPronunciation = const Value.absent(),
    this.exampleSentence = const Value.absent(),
  }) : word = Value(word),
       wordLower = Value(wordLower),
       meaning = Value(meaning);
  static Insertable<DictionaryEntryRow> custom({
    Expression<int>? id,
    Expression<String>? word,
    Expression<String>? wordLower,
    Expression<String>? partOfSpeech,
    Expression<String>? meaning,
    Expression<String>? ipaPronunciation,
    Expression<String>? exampleSentence,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (wordLower != null) 'word_lower': wordLower,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (meaning != null) 'meaning': meaning,
      if (ipaPronunciation != null) 'ipa_pronunciation': ipaPronunciation,
      if (exampleSentence != null) 'example_sentence': exampleSentence,
    });
  }

  DictionaryEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? word,
    Value<String>? wordLower,
    Value<String?>? partOfSpeech,
    Value<String>? meaning,
    Value<String?>? ipaPronunciation,
    Value<String?>? exampleSentence,
  }) {
    return DictionaryEntriesCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      wordLower: wordLower ?? this.wordLower,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      meaning: meaning ?? this.meaning,
      ipaPronunciation: ipaPronunciation ?? this.ipaPronunciation,
      exampleSentence: exampleSentence ?? this.exampleSentence,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (wordLower.present) {
      map['word_lower'] = Variable<String>(wordLower.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (ipaPronunciation.present) {
      map['ipa_pronunciation'] = Variable<String>(ipaPronunciation.value);
    }
    if (exampleSentence.present) {
      map['example_sentence'] = Variable<String>(exampleSentence.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('wordLower: $wordLower, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('meaning: $meaning, ')
          ..write('ipaPronunciation: $ipaPronunciation, ')
          ..write('exampleSentence: $exampleSentence')
          ..write(')'))
        .toString();
  }
}

class $DictionaryFavoritesTable extends DictionaryFavorites
    with TableInfo<$DictionaryFavoritesTable, DictionaryFavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordLowerMeta = const VerificationMeta(
    'wordLower',
  );
  @override
  late final GeneratedColumn<String> wordLower = GeneratedColumn<String>(
    'word_lower',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    wordLower,
    word,
    partOfSpeech,
    meaning,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryFavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_lower')) {
      context.handle(
        _wordLowerMeta,
        wordLower.isAcceptableOrUnknown(data['word_lower']!, _wordLowerMeta),
      );
    } else if (isInserting) {
      context.missing(_wordLowerMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordLower};
  @override
  DictionaryFavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryFavoriteRow(
      wordLower: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_lower'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      ),
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DictionaryFavoritesTable createAlias(String alias) {
    return $DictionaryFavoritesTable(attachedDatabase, alias);
  }
}

class DictionaryFavoriteRow extends DataClass
    implements Insertable<DictionaryFavoriteRow> {
  final String wordLower;
  final String word;
  final String? partOfSpeech;
  final String meaning;
  final DateTime createdAt;
  const DictionaryFavoriteRow({
    required this.wordLower,
    required this.word,
    this.partOfSpeech,
    required this.meaning,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_lower'] = Variable<String>(wordLower);
    map['word'] = Variable<String>(word);
    if (!nullToAbsent || partOfSpeech != null) {
      map['part_of_speech'] = Variable<String>(partOfSpeech);
    }
    map['meaning'] = Variable<String>(meaning);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DictionaryFavoritesCompanion toCompanion(bool nullToAbsent) {
    return DictionaryFavoritesCompanion(
      wordLower: Value(wordLower),
      word: Value(word),
      partOfSpeech: partOfSpeech == null && nullToAbsent
          ? const Value.absent()
          : Value(partOfSpeech),
      meaning: Value(meaning),
      createdAt: Value(createdAt),
    );
  }

  factory DictionaryFavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryFavoriteRow(
      wordLower: serializer.fromJson<String>(json['wordLower']),
      word: serializer.fromJson<String>(json['word']),
      partOfSpeech: serializer.fromJson<String?>(json['partOfSpeech']),
      meaning: serializer.fromJson<String>(json['meaning']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordLower': serializer.toJson<String>(wordLower),
      'word': serializer.toJson<String>(word),
      'partOfSpeech': serializer.toJson<String?>(partOfSpeech),
      'meaning': serializer.toJson<String>(meaning),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DictionaryFavoriteRow copyWith({
    String? wordLower,
    String? word,
    Value<String?> partOfSpeech = const Value.absent(),
    String? meaning,
    DateTime? createdAt,
  }) => DictionaryFavoriteRow(
    wordLower: wordLower ?? this.wordLower,
    word: word ?? this.word,
    partOfSpeech: partOfSpeech.present ? partOfSpeech.value : this.partOfSpeech,
    meaning: meaning ?? this.meaning,
    createdAt: createdAt ?? this.createdAt,
  );
  DictionaryFavoriteRow copyWithCompanion(DictionaryFavoritesCompanion data) {
    return DictionaryFavoriteRow(
      wordLower: data.wordLower.present ? data.wordLower.value : this.wordLower,
      word: data.word.present ? data.word.value : this.word,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryFavoriteRow(')
          ..write('wordLower: $wordLower, ')
          ..write('word: $word, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('meaning: $meaning, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(wordLower, word, partOfSpeech, meaning, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryFavoriteRow &&
          other.wordLower == this.wordLower &&
          other.word == this.word &&
          other.partOfSpeech == this.partOfSpeech &&
          other.meaning == this.meaning &&
          other.createdAt == this.createdAt);
}

class DictionaryFavoritesCompanion
    extends UpdateCompanion<DictionaryFavoriteRow> {
  final Value<String> wordLower;
  final Value<String> word;
  final Value<String?> partOfSpeech;
  final Value<String> meaning;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DictionaryFavoritesCompanion({
    this.wordLower = const Value.absent(),
    this.word = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.meaning = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DictionaryFavoritesCompanion.insert({
    required String wordLower,
    required String word,
    this.partOfSpeech = const Value.absent(),
    required String meaning,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : wordLower = Value(wordLower),
       word = Value(word),
       meaning = Value(meaning),
       createdAt = Value(createdAt);
  static Insertable<DictionaryFavoriteRow> custom({
    Expression<String>? wordLower,
    Expression<String>? word,
    Expression<String>? partOfSpeech,
    Expression<String>? meaning,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordLower != null) 'word_lower': wordLower,
      if (word != null) 'word': word,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (meaning != null) 'meaning': meaning,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DictionaryFavoritesCompanion copyWith({
    Value<String>? wordLower,
    Value<String>? word,
    Value<String?>? partOfSpeech,
    Value<String>? meaning,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DictionaryFavoritesCompanion(
      wordLower: wordLower ?? this.wordLower,
      word: word ?? this.word,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      meaning: meaning ?? this.meaning,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordLower.present) {
      map['word_lower'] = Variable<String>(wordLower.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryFavoritesCompanion(')
          ..write('wordLower: $wordLower, ')
          ..write('word: $word, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('meaning: $meaning, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DictionaryExamEntriesTable extends DictionaryExamEntries
    with TableInfo<$DictionaryExamEntriesTable, DictionaryExamEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionaryExamEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordLowerMeta = const VerificationMeta(
    'wordLower',
  );
  @override
  late final GeneratedColumn<String> wordLower = GeneratedColumn<String>(
    'word_lower',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentJsonMeta = const VerificationMeta(
    'contentJson',
  );
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
    'content_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [wordLower, word, contentJson];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_exam_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DictionaryExamEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_lower')) {
      context.handle(
        _wordLowerMeta,
        wordLower.isAcceptableOrUnknown(data['word_lower']!, _wordLowerMeta),
      );
    } else if (isInserting) {
      context.missing(_wordLowerMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('content_json')) {
      context.handle(
        _contentJsonMeta,
        contentJson.isAcceptableOrUnknown(
          data['content_json']!,
          _contentJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordLower};
  @override
  DictionaryExamEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DictionaryExamEntryRow(
      wordLower: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_lower'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      contentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_json'],
      )!,
    );
  }

  @override
  $DictionaryExamEntriesTable createAlias(String alias) {
    return $DictionaryExamEntriesTable(attachedDatabase, alias);
  }
}

class DictionaryExamEntryRow extends DataClass
    implements Insertable<DictionaryExamEntryRow> {
  final String wordLower;
  final String word;
  final String contentJson;
  const DictionaryExamEntryRow({
    required this.wordLower,
    required this.word,
    required this.contentJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_lower'] = Variable<String>(wordLower);
    map['word'] = Variable<String>(word);
    map['content_json'] = Variable<String>(contentJson);
    return map;
  }

  DictionaryExamEntriesCompanion toCompanion(bool nullToAbsent) {
    return DictionaryExamEntriesCompanion(
      wordLower: Value(wordLower),
      word: Value(word),
      contentJson: Value(contentJson),
    );
  }

  factory DictionaryExamEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DictionaryExamEntryRow(
      wordLower: serializer.fromJson<String>(json['wordLower']),
      word: serializer.fromJson<String>(json['word']),
      contentJson: serializer.fromJson<String>(json['contentJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordLower': serializer.toJson<String>(wordLower),
      'word': serializer.toJson<String>(word),
      'contentJson': serializer.toJson<String>(contentJson),
    };
  }

  DictionaryExamEntryRow copyWith({
    String? wordLower,
    String? word,
    String? contentJson,
  }) => DictionaryExamEntryRow(
    wordLower: wordLower ?? this.wordLower,
    word: word ?? this.word,
    contentJson: contentJson ?? this.contentJson,
  );
  DictionaryExamEntryRow copyWithCompanion(
    DictionaryExamEntriesCompanion data,
  ) {
    return DictionaryExamEntryRow(
      wordLower: data.wordLower.present ? data.wordLower.value : this.wordLower,
      word: data.word.present ? data.word.value : this.word,
      contentJson: data.contentJson.present
          ? data.contentJson.value
          : this.contentJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryExamEntryRow(')
          ..write('wordLower: $wordLower, ')
          ..write('word: $word, ')
          ..write('contentJson: $contentJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordLower, word, contentJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DictionaryExamEntryRow &&
          other.wordLower == this.wordLower &&
          other.word == this.word &&
          other.contentJson == this.contentJson);
}

class DictionaryExamEntriesCompanion
    extends UpdateCompanion<DictionaryExamEntryRow> {
  final Value<String> wordLower;
  final Value<String> word;
  final Value<String> contentJson;
  final Value<int> rowid;
  const DictionaryExamEntriesCompanion({
    this.wordLower = const Value.absent(),
    this.word = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DictionaryExamEntriesCompanion.insert({
    required String wordLower,
    required String word,
    required String contentJson,
    this.rowid = const Value.absent(),
  }) : wordLower = Value(wordLower),
       word = Value(word),
       contentJson = Value(contentJson);
  static Insertable<DictionaryExamEntryRow> custom({
    Expression<String>? wordLower,
    Expression<String>? word,
    Expression<String>? contentJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordLower != null) 'word_lower': wordLower,
      if (word != null) 'word': word,
      if (contentJson != null) 'content_json': contentJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DictionaryExamEntriesCompanion copyWith({
    Value<String>? wordLower,
    Value<String>? word,
    Value<String>? contentJson,
    Value<int>? rowid,
  }) {
    return DictionaryExamEntriesCompanion(
      wordLower: wordLower ?? this.wordLower,
      word: word ?? this.word,
      contentJson: contentJson ?? this.contentJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordLower.present) {
      map['word_lower'] = Variable<String>(wordLower.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionaryExamEntriesCompanion(')
          ..write('wordLower: $wordLower, ')
          ..write('word: $word, ')
          ..write('contentJson: $contentJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DictionarySearchHistoryTable extends DictionarySearchHistory
    with TableInfo<$DictionarySearchHistoryTable, SearchHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DictionarySearchHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordLowerMeta = const VerificationMeta(
    'wordLower',
  );
  @override
  late final GeneratedColumn<String> wordLower = GeneratedColumn<String>(
    'word_lower',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchedAtMeta = const VerificationMeta(
    'searchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> searchedAt = GeneratedColumn<DateTime>(
    'searched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [wordLower, word, searchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dictionary_search_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_lower')) {
      context.handle(
        _wordLowerMeta,
        wordLower.isAcceptableOrUnknown(data['word_lower']!, _wordLowerMeta),
      );
    } else if (isInserting) {
      context.missing(_wordLowerMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('searched_at')) {
      context.handle(
        _searchedAtMeta,
        searchedAt.isAcceptableOrUnknown(data['searched_at']!, _searchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_searchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordLower};
  @override
  SearchHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchHistoryRow(
      wordLower: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_lower'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      searchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}searched_at'],
      )!,
    );
  }

  @override
  $DictionarySearchHistoryTable createAlias(String alias) {
    return $DictionarySearchHistoryTable(attachedDatabase, alias);
  }
}

class SearchHistoryRow extends DataClass
    implements Insertable<SearchHistoryRow> {
  final String wordLower;
  final String word;
  final DateTime searchedAt;
  const SearchHistoryRow({
    required this.wordLower,
    required this.word,
    required this.searchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_lower'] = Variable<String>(wordLower);
    map['word'] = Variable<String>(word);
    map['searched_at'] = Variable<DateTime>(searchedAt);
    return map;
  }

  DictionarySearchHistoryCompanion toCompanion(bool nullToAbsent) {
    return DictionarySearchHistoryCompanion(
      wordLower: Value(wordLower),
      word: Value(word),
      searchedAt: Value(searchedAt),
    );
  }

  factory SearchHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchHistoryRow(
      wordLower: serializer.fromJson<String>(json['wordLower']),
      word: serializer.fromJson<String>(json['word']),
      searchedAt: serializer.fromJson<DateTime>(json['searchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordLower': serializer.toJson<String>(wordLower),
      'word': serializer.toJson<String>(word),
      'searchedAt': serializer.toJson<DateTime>(searchedAt),
    };
  }

  SearchHistoryRow copyWith({
    String? wordLower,
    String? word,
    DateTime? searchedAt,
  }) => SearchHistoryRow(
    wordLower: wordLower ?? this.wordLower,
    word: word ?? this.word,
    searchedAt: searchedAt ?? this.searchedAt,
  );
  SearchHistoryRow copyWithCompanion(DictionarySearchHistoryCompanion data) {
    return SearchHistoryRow(
      wordLower: data.wordLower.present ? data.wordLower.value : this.wordLower,
      word: data.word.present ? data.word.value : this.word,
      searchedAt: data.searchedAt.present
          ? data.searchedAt.value
          : this.searchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchHistoryRow(')
          ..write('wordLower: $wordLower, ')
          ..write('word: $word, ')
          ..write('searchedAt: $searchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(wordLower, word, searchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchHistoryRow &&
          other.wordLower == this.wordLower &&
          other.word == this.word &&
          other.searchedAt == this.searchedAt);
}

class DictionarySearchHistoryCompanion
    extends UpdateCompanion<SearchHistoryRow> {
  final Value<String> wordLower;
  final Value<String> word;
  final Value<DateTime> searchedAt;
  final Value<int> rowid;
  const DictionarySearchHistoryCompanion({
    this.wordLower = const Value.absent(),
    this.word = const Value.absent(),
    this.searchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DictionarySearchHistoryCompanion.insert({
    required String wordLower,
    required String word,
    required DateTime searchedAt,
    this.rowid = const Value.absent(),
  }) : wordLower = Value(wordLower),
       word = Value(word),
       searchedAt = Value(searchedAt);
  static Insertable<SearchHistoryRow> custom({
    Expression<String>? wordLower,
    Expression<String>? word,
    Expression<DateTime>? searchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordLower != null) 'word_lower': wordLower,
      if (word != null) 'word': word,
      if (searchedAt != null) 'searched_at': searchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DictionarySearchHistoryCompanion copyWith({
    Value<String>? wordLower,
    Value<String>? word,
    Value<DateTime>? searchedAt,
    Value<int>? rowid,
  }) {
    return DictionarySearchHistoryCompanion(
      wordLower: wordLower ?? this.wordLower,
      word: word ?? this.word,
      searchedAt: searchedAt ?? this.searchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordLower.present) {
      map['word_lower'] = Variable<String>(wordLower.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (searchedAt.present) {
      map['searched_at'] = Variable<DateTime>(searchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DictionarySearchHistoryCompanion(')
          ..write('wordLower: $wordLower, ')
          ..write('word: $word, ')
          ..write('searchedAt: $searchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TranslationEntriesTable extends TranslationEntries
    with TableInfo<$TranslationEntriesTable, TranslationEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslationEntriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _langCodeMeta = const VerificationMeta(
    'langCode',
  );
  @override
  late final GeneratedColumn<String> langCode = GeneratedColumn<String>(
    'lang_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordLowerMeta = const VerificationMeta(
    'wordLower',
  );
  @override
  late final GeneratedColumn<String> wordLower = GeneratedColumn<String>(
    'word_lower',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, langCode, wordLower, translation];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translation_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TranslationEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lang_code')) {
      context.handle(
        _langCodeMeta,
        langCode.isAcceptableOrUnknown(data['lang_code']!, _langCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_langCodeMeta);
    }
    if (data.containsKey('word_lower')) {
      context.handle(
        _wordLowerMeta,
        wordLower.isAcceptableOrUnknown(data['word_lower']!, _wordLowerMeta),
      );
    } else if (isInserting) {
      context.missing(_wordLowerMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TranslationEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranslationEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      langCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang_code'],
      )!,
      wordLower: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_lower'],
      )!,
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      )!,
    );
  }

  @override
  $TranslationEntriesTable createAlias(String alias) {
    return $TranslationEntriesTable(attachedDatabase, alias);
  }
}

class TranslationEntryRow extends DataClass
    implements Insertable<TranslationEntryRow> {
  final int id;

  /// Two-letter target language code, e.g. "fr", "hi".
  final String langCode;

  /// Lowercased English headword being translated.
  final String wordLower;

  /// The translation text (one or more senses, joined).
  final String translation;
  const TranslationEntryRow({
    required this.id,
    required this.langCode,
    required this.wordLower,
    required this.translation,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lang_code'] = Variable<String>(langCode);
    map['word_lower'] = Variable<String>(wordLower);
    map['translation'] = Variable<String>(translation);
    return map;
  }

  TranslationEntriesCompanion toCompanion(bool nullToAbsent) {
    return TranslationEntriesCompanion(
      id: Value(id),
      langCode: Value(langCode),
      wordLower: Value(wordLower),
      translation: Value(translation),
    );
  }

  factory TranslationEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranslationEntryRow(
      id: serializer.fromJson<int>(json['id']),
      langCode: serializer.fromJson<String>(json['langCode']),
      wordLower: serializer.fromJson<String>(json['wordLower']),
      translation: serializer.fromJson<String>(json['translation']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'langCode': serializer.toJson<String>(langCode),
      'wordLower': serializer.toJson<String>(wordLower),
      'translation': serializer.toJson<String>(translation),
    };
  }

  TranslationEntryRow copyWith({
    int? id,
    String? langCode,
    String? wordLower,
    String? translation,
  }) => TranslationEntryRow(
    id: id ?? this.id,
    langCode: langCode ?? this.langCode,
    wordLower: wordLower ?? this.wordLower,
    translation: translation ?? this.translation,
  );
  TranslationEntryRow copyWithCompanion(TranslationEntriesCompanion data) {
    return TranslationEntryRow(
      id: data.id.present ? data.id.value : this.id,
      langCode: data.langCode.present ? data.langCode.value : this.langCode,
      wordLower: data.wordLower.present ? data.wordLower.value : this.wordLower,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranslationEntryRow(')
          ..write('id: $id, ')
          ..write('langCode: $langCode, ')
          ..write('wordLower: $wordLower, ')
          ..write('translation: $translation')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, langCode, wordLower, translation);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranslationEntryRow &&
          other.id == this.id &&
          other.langCode == this.langCode &&
          other.wordLower == this.wordLower &&
          other.translation == this.translation);
}

class TranslationEntriesCompanion extends UpdateCompanion<TranslationEntryRow> {
  final Value<int> id;
  final Value<String> langCode;
  final Value<String> wordLower;
  final Value<String> translation;
  const TranslationEntriesCompanion({
    this.id = const Value.absent(),
    this.langCode = const Value.absent(),
    this.wordLower = const Value.absent(),
    this.translation = const Value.absent(),
  });
  TranslationEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String langCode,
    required String wordLower,
    required String translation,
  }) : langCode = Value(langCode),
       wordLower = Value(wordLower),
       translation = Value(translation);
  static Insertable<TranslationEntryRow> custom({
    Expression<int>? id,
    Expression<String>? langCode,
    Expression<String>? wordLower,
    Expression<String>? translation,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (langCode != null) 'lang_code': langCode,
      if (wordLower != null) 'word_lower': wordLower,
      if (translation != null) 'translation': translation,
    });
  }

  TranslationEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? langCode,
    Value<String>? wordLower,
    Value<String>? translation,
  }) {
    return TranslationEntriesCompanion(
      id: id ?? this.id,
      langCode: langCode ?? this.langCode,
      wordLower: wordLower ?? this.wordLower,
      translation: translation ?? this.translation,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (langCode.present) {
      map['lang_code'] = Variable<String>(langCode.value);
    }
    if (wordLower.present) {
      map['word_lower'] = Variable<String>(wordLower.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslationEntriesCompanion(')
          ..write('id: $id, ')
          ..write('langCode: $langCode, ')
          ..write('wordLower: $wordLower, ')
          ..write('translation: $translation')
          ..write(')'))
        .toString();
  }
}

class $TranslationCacheTable extends TranslationCache
    with TableInfo<$TranslationCacheTable, TranslationCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TranslationCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _langCodeMeta = const VerificationMeta(
    'langCode',
  );
  @override
  late final GeneratedColumn<String> langCode = GeneratedColumn<String>(
    'lang_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordLowerMeta = const VerificationMeta(
    'wordLower',
  );
  @override
  late final GeneratedColumn<String> wordLower = GeneratedColumn<String>(
    'word_lower',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationMeta = const VerificationMeta(
    'translation',
  );
  @override
  late final GeneratedColumn<String> translation = GeneratedColumn<String>(
    'translation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('online'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    langCode,
    wordLower,
    word,
    translation,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'translation_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<TranslationCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lang_code')) {
      context.handle(
        _langCodeMeta,
        langCode.isAcceptableOrUnknown(data['lang_code']!, _langCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_langCodeMeta);
    }
    if (data.containsKey('word_lower')) {
      context.handle(
        _wordLowerMeta,
        wordLower.isAcceptableOrUnknown(data['word_lower']!, _wordLowerMeta),
      );
    } else if (isInserting) {
      context.missing(_wordLowerMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('translation')) {
      context.handle(
        _translationMeta,
        translation.isAcceptableOrUnknown(
          data['translation']!,
          _translationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {langCode, wordLower};
  @override
  TranslationCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TranslationCacheRow(
      langCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lang_code'],
      )!,
      wordLower: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_lower'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      translation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TranslationCacheTable createAlias(String alias) {
    return $TranslationCacheTable(attachedDatabase, alias);
  }
}

class TranslationCacheRow extends DataClass
    implements Insertable<TranslationCacheRow> {
  /// Two-letter target language code, e.g. "ur".
  final String langCode;

  /// Lowercased English headword being translated.
  final String wordLower;

  /// The original (display) casing of the word.
  final String word;

  /// The cached translation text.
  final String translation;

  /// How the entry was obtained (e.g. "online"). Kept so cached rows can be
  /// distinguished/managed later without a schema change.
  final String source;
  final DateTime createdAt;
  const TranslationCacheRow({
    required this.langCode,
    required this.wordLower,
    required this.word,
    required this.translation,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lang_code'] = Variable<String>(langCode);
    map['word_lower'] = Variable<String>(wordLower);
    map['word'] = Variable<String>(word);
    map['translation'] = Variable<String>(translation);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TranslationCacheCompanion toCompanion(bool nullToAbsent) {
    return TranslationCacheCompanion(
      langCode: Value(langCode),
      wordLower: Value(wordLower),
      word: Value(word),
      translation: Value(translation),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory TranslationCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TranslationCacheRow(
      langCode: serializer.fromJson<String>(json['langCode']),
      wordLower: serializer.fromJson<String>(json['wordLower']),
      word: serializer.fromJson<String>(json['word']),
      translation: serializer.fromJson<String>(json['translation']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'langCode': serializer.toJson<String>(langCode),
      'wordLower': serializer.toJson<String>(wordLower),
      'word': serializer.toJson<String>(word),
      'translation': serializer.toJson<String>(translation),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  TranslationCacheRow copyWith({
    String? langCode,
    String? wordLower,
    String? word,
    String? translation,
    String? source,
    DateTime? createdAt,
  }) => TranslationCacheRow(
    langCode: langCode ?? this.langCode,
    wordLower: wordLower ?? this.wordLower,
    word: word ?? this.word,
    translation: translation ?? this.translation,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  TranslationCacheRow copyWithCompanion(TranslationCacheCompanion data) {
    return TranslationCacheRow(
      langCode: data.langCode.present ? data.langCode.value : this.langCode,
      wordLower: data.wordLower.present ? data.wordLower.value : this.wordLower,
      word: data.word.present ? data.word.value : this.word,
      translation: data.translation.present
          ? data.translation.value
          : this.translation,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TranslationCacheRow(')
          ..write('langCode: $langCode, ')
          ..write('wordLower: $wordLower, ')
          ..write('word: $word, ')
          ..write('translation: $translation, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(langCode, wordLower, word, translation, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TranslationCacheRow &&
          other.langCode == this.langCode &&
          other.wordLower == this.wordLower &&
          other.word == this.word &&
          other.translation == this.translation &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class TranslationCacheCompanion extends UpdateCompanion<TranslationCacheRow> {
  final Value<String> langCode;
  final Value<String> wordLower;
  final Value<String> word;
  final Value<String> translation;
  final Value<String> source;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TranslationCacheCompanion({
    this.langCode = const Value.absent(),
    this.wordLower = const Value.absent(),
    this.word = const Value.absent(),
    this.translation = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TranslationCacheCompanion.insert({
    required String langCode,
    required String wordLower,
    required String word,
    required String translation,
    this.source = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : langCode = Value(langCode),
       wordLower = Value(wordLower),
       word = Value(word),
       translation = Value(translation),
       createdAt = Value(createdAt);
  static Insertable<TranslationCacheRow> custom({
    Expression<String>? langCode,
    Expression<String>? wordLower,
    Expression<String>? word,
    Expression<String>? translation,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (langCode != null) 'lang_code': langCode,
      if (wordLower != null) 'word_lower': wordLower,
      if (word != null) 'word': word,
      if (translation != null) 'translation': translation,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TranslationCacheCompanion copyWith({
    Value<String>? langCode,
    Value<String>? wordLower,
    Value<String>? word,
    Value<String>? translation,
    Value<String>? source,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TranslationCacheCompanion(
      langCode: langCode ?? this.langCode,
      wordLower: wordLower ?? this.wordLower,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (langCode.present) {
      map['lang_code'] = Variable<String>(langCode.value);
    }
    if (wordLower.present) {
      map['word_lower'] = Variable<String>(wordLower.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (translation.present) {
      map['translation'] = Variable<String>(translation.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TranslationCacheCompanion(')
          ..write('langCode: $langCode, ')
          ..write('wordLower: $wordLower, ')
          ..write('word: $word, ')
          ..write('translation: $translation, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrammarLessonsTable extends GrammarLessons
    with TableInfo<$GrammarLessonsTable, GrammarLessonRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrammarLessonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
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
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contentJsonMeta = const VerificationMeta(
    'contentJson',
  );
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
    'content_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    title,
    summary,
    searchText,
    orderIndex,
    contentJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grammar_lessons';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrammarLessonRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    } else if (isInserting) {
      context.missing(_searchTextMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('content_json')) {
      context.handle(
        _contentJsonMeta,
        contentJson.isAcceptableOrUnknown(
          data['content_json']!,
          _contentJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrammarLessonRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrammarLessonRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      contentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_json'],
      )!,
    );
  }

  @override
  $GrammarLessonsTable createAlias(String alias) {
    return $GrammarLessonsTable(attachedDatabase, alias);
  }
}

class GrammarLessonRow extends DataClass
    implements Insertable<GrammarLessonRow> {
  /// Stable slug id, e.g. `parts-of-speech`.
  final String id;

  /// Grouping category, e.g. `Foundations`.
  final String category;

  /// Display title, e.g. `Parts of Speech`.
  final String title;

  /// One-line description shown in lists and cards.
  final String summary;

  /// Lowercased haystack (title + summary + keywords + category) used for
  /// case-insensitive substring search.
  final String searchText;

  /// Sort order within the whole module and within a category (lower first).
  final int orderIndex;

  /// The full lesson body encoded as a JSON object (explanation, rules,
  /// examples, notes, tips, commonMistakes, practiceQuestions).
  final String contentJson;
  const GrammarLessonRow({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.searchText,
    required this.orderIndex,
    required this.contentJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['title'] = Variable<String>(title);
    map['summary'] = Variable<String>(summary);
    map['search_text'] = Variable<String>(searchText);
    map['order_index'] = Variable<int>(orderIndex);
    map['content_json'] = Variable<String>(contentJson);
    return map;
  }

  GrammarLessonsCompanion toCompanion(bool nullToAbsent) {
    return GrammarLessonsCompanion(
      id: Value(id),
      category: Value(category),
      title: Value(title),
      summary: Value(summary),
      searchText: Value(searchText),
      orderIndex: Value(orderIndex),
      contentJson: Value(contentJson),
    );
  }

  factory GrammarLessonRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrammarLessonRow(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      title: serializer.fromJson<String>(json['title']),
      summary: serializer.fromJson<String>(json['summary']),
      searchText: serializer.fromJson<String>(json['searchText']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      contentJson: serializer.fromJson<String>(json['contentJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'title': serializer.toJson<String>(title),
      'summary': serializer.toJson<String>(summary),
      'searchText': serializer.toJson<String>(searchText),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'contentJson': serializer.toJson<String>(contentJson),
    };
  }

  GrammarLessonRow copyWith({
    String? id,
    String? category,
    String? title,
    String? summary,
    String? searchText,
    int? orderIndex,
    String? contentJson,
  }) => GrammarLessonRow(
    id: id ?? this.id,
    category: category ?? this.category,
    title: title ?? this.title,
    summary: summary ?? this.summary,
    searchText: searchText ?? this.searchText,
    orderIndex: orderIndex ?? this.orderIndex,
    contentJson: contentJson ?? this.contentJson,
  );
  GrammarLessonRow copyWithCompanion(GrammarLessonsCompanion data) {
    return GrammarLessonRow(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      title: data.title.present ? data.title.value : this.title,
      summary: data.summary.present ? data.summary.value : this.summary,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      contentJson: data.contentJson.present
          ? data.contentJson.value
          : this.contentJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrammarLessonRow(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('searchText: $searchText, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('contentJson: $contentJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    title,
    summary,
    searchText,
    orderIndex,
    contentJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrammarLessonRow &&
          other.id == this.id &&
          other.category == this.category &&
          other.title == this.title &&
          other.summary == this.summary &&
          other.searchText == this.searchText &&
          other.orderIndex == this.orderIndex &&
          other.contentJson == this.contentJson);
}

class GrammarLessonsCompanion extends UpdateCompanion<GrammarLessonRow> {
  final Value<String> id;
  final Value<String> category;
  final Value<String> title;
  final Value<String> summary;
  final Value<String> searchText;
  final Value<int> orderIndex;
  final Value<String> contentJson;
  final Value<int> rowid;
  const GrammarLessonsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.title = const Value.absent(),
    this.summary = const Value.absent(),
    this.searchText = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrammarLessonsCompanion.insert({
    required String id,
    required String category,
    required String title,
    required String summary,
    required String searchText,
    this.orderIndex = const Value.absent(),
    required String contentJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       title = Value(title),
       summary = Value(summary),
       searchText = Value(searchText),
       contentJson = Value(contentJson);
  static Insertable<GrammarLessonRow> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<String>? title,
    Expression<String>? summary,
    Expression<String>? searchText,
    Expression<int>? orderIndex,
    Expression<String>? contentJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (title != null) 'title': title,
      if (summary != null) 'summary': summary,
      if (searchText != null) 'search_text': searchText,
      if (orderIndex != null) 'order_index': orderIndex,
      if (contentJson != null) 'content_json': contentJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrammarLessonsCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<String>? title,
    Value<String>? summary,
    Value<String>? searchText,
    Value<int>? orderIndex,
    Value<String>? contentJson,
    Value<int>? rowid,
  }) {
    return GrammarLessonsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      searchText: searchText ?? this.searchText,
      orderIndex: orderIndex ?? this.orderIndex,
      contentJson: contentJson ?? this.contentJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrammarLessonsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('title: $title, ')
          ..write('summary: $summary, ')
          ..write('searchText: $searchText, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('contentJson: $contentJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrammarProgressTable extends GrammarProgress
    with TableInfo<$GrammarProgressTable, GrammarProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrammarProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _scrollProgressMeta = const VerificationMeta(
    'scrollProgress',
  );
  @override
  late final GeneratedColumn<double> scrollProgress = GeneratedColumn<double>(
    'scroll_progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastViewedAtMeta = const VerificationMeta(
    'lastViewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastViewedAt = GeneratedColumn<DateTime>(
    'last_viewed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    lessonId,
    status,
    scrollProgress,
    lastViewedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grammar_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrammarProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('scroll_progress')) {
      context.handle(
        _scrollProgressMeta,
        scrollProgress.isAcceptableOrUnknown(
          data['scroll_progress']!,
          _scrollProgressMeta,
        ),
      );
    }
    if (data.containsKey('last_viewed_at')) {
      context.handle(
        _lastViewedAtMeta,
        lastViewedAt.isAcceptableOrUnknown(
          data['last_viewed_at']!,
          _lastViewedAtMeta,
        ),
      );
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  GrammarProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrammarProgressRow(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      scrollProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scroll_progress'],
      )!,
      lastViewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_viewed_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $GrammarProgressTable createAlias(String alias) {
    return $GrammarProgressTable(attachedDatabase, alias);
  }
}

class GrammarProgressRow extends DataClass
    implements Insertable<GrammarProgressRow> {
  final String lessonId;
  final int status;
  final double scrollProgress;
  final DateTime? lastViewedAt;
  final DateTime? completedAt;
  const GrammarProgressRow({
    required this.lessonId,
    required this.status,
    required this.scrollProgress,
    this.lastViewedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['status'] = Variable<int>(status);
    map['scroll_progress'] = Variable<double>(scrollProgress);
    if (!nullToAbsent || lastViewedAt != null) {
      map['last_viewed_at'] = Variable<DateTime>(lastViewedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  GrammarProgressCompanion toCompanion(bool nullToAbsent) {
    return GrammarProgressCompanion(
      lessonId: Value(lessonId),
      status: Value(status),
      scrollProgress: Value(scrollProgress),
      lastViewedAt: lastViewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastViewedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory GrammarProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrammarProgressRow(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      status: serializer.fromJson<int>(json['status']),
      scrollProgress: serializer.fromJson<double>(json['scrollProgress']),
      lastViewedAt: serializer.fromJson<DateTime?>(json['lastViewedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'status': serializer.toJson<int>(status),
      'scrollProgress': serializer.toJson<double>(scrollProgress),
      'lastViewedAt': serializer.toJson<DateTime?>(lastViewedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  GrammarProgressRow copyWith({
    String? lessonId,
    int? status,
    double? scrollProgress,
    Value<DateTime?> lastViewedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
  }) => GrammarProgressRow(
    lessonId: lessonId ?? this.lessonId,
    status: status ?? this.status,
    scrollProgress: scrollProgress ?? this.scrollProgress,
    lastViewedAt: lastViewedAt.present ? lastViewedAt.value : this.lastViewedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  GrammarProgressRow copyWithCompanion(GrammarProgressCompanion data) {
    return GrammarProgressRow(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      status: data.status.present ? data.status.value : this.status,
      scrollProgress: data.scrollProgress.present
          ? data.scrollProgress.value
          : this.scrollProgress,
      lastViewedAt: data.lastViewedAt.present
          ? data.lastViewedAt.value
          : this.lastViewedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrammarProgressRow(')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('scrollProgress: $scrollProgress, ')
          ..write('lastViewedAt: $lastViewedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(lessonId, status, scrollProgress, lastViewedAt, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrammarProgressRow &&
          other.lessonId == this.lessonId &&
          other.status == this.status &&
          other.scrollProgress == this.scrollProgress &&
          other.lastViewedAt == this.lastViewedAt &&
          other.completedAt == this.completedAt);
}

class GrammarProgressCompanion extends UpdateCompanion<GrammarProgressRow> {
  final Value<String> lessonId;
  final Value<int> status;
  final Value<double> scrollProgress;
  final Value<DateTime?> lastViewedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const GrammarProgressCompanion({
    this.lessonId = const Value.absent(),
    this.status = const Value.absent(),
    this.scrollProgress = const Value.absent(),
    this.lastViewedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrammarProgressCompanion.insert({
    required String lessonId,
    this.status = const Value.absent(),
    this.scrollProgress = const Value.absent(),
    this.lastViewedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId);
  static Insertable<GrammarProgressRow> custom({
    Expression<String>? lessonId,
    Expression<int>? status,
    Expression<double>? scrollProgress,
    Expression<DateTime>? lastViewedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (status != null) 'status': status,
      if (scrollProgress != null) 'scroll_progress': scrollProgress,
      if (lastViewedAt != null) 'last_viewed_at': lastViewedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrammarProgressCompanion copyWith({
    Value<String>? lessonId,
    Value<int>? status,
    Value<double>? scrollProgress,
    Value<DateTime?>? lastViewedAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return GrammarProgressCompanion(
      lessonId: lessonId ?? this.lessonId,
      status: status ?? this.status,
      scrollProgress: scrollProgress ?? this.scrollProgress,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (scrollProgress.present) {
      map['scroll_progress'] = Variable<double>(scrollProgress.value);
    }
    if (lastViewedAt.present) {
      map['last_viewed_at'] = Variable<DateTime>(lastViewedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrammarProgressCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('scrollProgress: $scrollProgress, ')
          ..write('lastViewedAt: $lastViewedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrammarFavoritesTable extends GrammarFavorites
    with TableInfo<$GrammarFavoritesTable, GrammarFavoriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrammarFavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [lessonId, title, category, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grammar_favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrammarFavoriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {lessonId};
  @override
  GrammarFavoriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrammarFavoriteRow(
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $GrammarFavoritesTable createAlias(String alias) {
    return $GrammarFavoritesTable(attachedDatabase, alias);
  }
}

class GrammarFavoriteRow extends DataClass
    implements Insertable<GrammarFavoriteRow> {
  final String lessonId;
  final String title;
  final String category;
  final DateTime createdAt;
  const GrammarFavoriteRow({
    required this.lessonId,
    required this.title,
    required this.category,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lesson_id'] = Variable<String>(lessonId);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GrammarFavoritesCompanion toCompanion(bool nullToAbsent) {
    return GrammarFavoritesCompanion(
      lessonId: Value(lessonId),
      title: Value(title),
      category: Value(category),
      createdAt: Value(createdAt),
    );
  }

  factory GrammarFavoriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrammarFavoriteRow(
      lessonId: serializer.fromJson<String>(json['lessonId']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'lessonId': serializer.toJson<String>(lessonId),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GrammarFavoriteRow copyWith({
    String? lessonId,
    String? title,
    String? category,
    DateTime? createdAt,
  }) => GrammarFavoriteRow(
    lessonId: lessonId ?? this.lessonId,
    title: title ?? this.title,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
  );
  GrammarFavoriteRow copyWithCompanion(GrammarFavoritesCompanion data) {
    return GrammarFavoriteRow(
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrammarFavoriteRow(')
          ..write('lessonId: $lessonId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(lessonId, title, category, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrammarFavoriteRow &&
          other.lessonId == this.lessonId &&
          other.title == this.title &&
          other.category == this.category &&
          other.createdAt == this.createdAt);
}

class GrammarFavoritesCompanion extends UpdateCompanion<GrammarFavoriteRow> {
  final Value<String> lessonId;
  final Value<String> title;
  final Value<String> category;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const GrammarFavoritesCompanion({
    this.lessonId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrammarFavoritesCompanion.insert({
    required String lessonId,
    required String title,
    required String category,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : lessonId = Value(lessonId),
       title = Value(title),
       category = Value(category),
       createdAt = Value(createdAt);
  static Insertable<GrammarFavoriteRow> custom({
    Expression<String>? lessonId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (lessonId != null) 'lesson_id': lessonId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrammarFavoritesCompanion copyWith({
    Value<String>? lessonId,
    Value<String>? title,
    Value<String>? category,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return GrammarFavoritesCompanion(
      lessonId: lessonId ?? this.lessonId,
      title: title ?? this.title,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrammarFavoritesCompanion(')
          ..write('lessonId: $lessonId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrammarTopicsTable extends GrammarTopics
    with TableInfo<$GrammarTopicsTable, GrammarTopicRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrammarTopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isLeafMeta = const VerificationMeta('isLeaf');
  @override
  late final GeneratedColumn<bool> isLeaf = GeneratedColumn<bool>(
    'is_leaf',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_leaf" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _contentJsonMeta = const VerificationMeta(
    'contentJson',
  );
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
    'content_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    title,
    subtitle,
    orderIndex,
    isLeaf,
    searchText,
    contentJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grammar_topics';
  @override
  VerificationContext validateIntegrity(
    Insertable<GrammarTopicRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('is_leaf')) {
      context.handle(
        _isLeafMeta,
        isLeaf.isAcceptableOrUnknown(data['is_leaf']!, _isLeafMeta),
      );
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    }
    if (data.containsKey('content_json')) {
      context.handle(
        _contentJsonMeta,
        contentJson.isAcceptableOrUnknown(
          data['content_json']!,
          _contentJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrammarTopicRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrammarTopicRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      isLeaf: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_leaf'],
      )!,
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      contentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_json'],
      ),
    );
  }

  @override
  $GrammarTopicsTable createAlias(String alias) {
    return $GrammarTopicsTable(attachedDatabase, alias);
  }
}

class GrammarTopicRow extends DataClass implements Insertable<GrammarTopicRow> {
  final String id;
  final String? parentId;
  final String title;
  final String? subtitle;
  final int orderIndex;
  final bool isLeaf;

  /// Lowercased haystack (leaf title + intro/keywords) for search over lessons.
  final String searchText;

  /// Full lesson body as JSON, for leaves only (null for branches).
  final String? contentJson;
  const GrammarTopicRow({
    required this.id,
    this.parentId,
    required this.title,
    this.subtitle,
    required this.orderIndex,
    required this.isLeaf,
    required this.searchText,
    this.contentJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    map['order_index'] = Variable<int>(orderIndex);
    map['is_leaf'] = Variable<bool>(isLeaf);
    map['search_text'] = Variable<String>(searchText);
    if (!nullToAbsent || contentJson != null) {
      map['content_json'] = Variable<String>(contentJson);
    }
    return map;
  }

  GrammarTopicsCompanion toCompanion(bool nullToAbsent) {
    return GrammarTopicsCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      title: Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      orderIndex: Value(orderIndex),
      isLeaf: Value(isLeaf),
      searchText: Value(searchText),
      contentJson: contentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contentJson),
    );
  }

  factory GrammarTopicRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrammarTopicRow(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      isLeaf: serializer.fromJson<bool>(json['isLeaf']),
      searchText: serializer.fromJson<String>(json['searchText']),
      contentJson: serializer.fromJson<String?>(json['contentJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'isLeaf': serializer.toJson<bool>(isLeaf),
      'searchText': serializer.toJson<String>(searchText),
      'contentJson': serializer.toJson<String?>(contentJson),
    };
  }

  GrammarTopicRow copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? title,
    Value<String?> subtitle = const Value.absent(),
    int? orderIndex,
    bool? isLeaf,
    String? searchText,
    Value<String?> contentJson = const Value.absent(),
  }) => GrammarTopicRow(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    title: title ?? this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    orderIndex: orderIndex ?? this.orderIndex,
    isLeaf: isLeaf ?? this.isLeaf,
    searchText: searchText ?? this.searchText,
    contentJson: contentJson.present ? contentJson.value : this.contentJson,
  );
  GrammarTopicRow copyWithCompanion(GrammarTopicsCompanion data) {
    return GrammarTopicRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      isLeaf: data.isLeaf.present ? data.isLeaf.value : this.isLeaf,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
      contentJson: data.contentJson.present
          ? data.contentJson.value
          : this.contentJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrammarTopicRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isLeaf: $isLeaf, ')
          ..write('searchText: $searchText, ')
          ..write('contentJson: $contentJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    title,
    subtitle,
    orderIndex,
    isLeaf,
    searchText,
    contentJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrammarTopicRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.orderIndex == this.orderIndex &&
          other.isLeaf == this.isLeaf &&
          other.searchText == this.searchText &&
          other.contentJson == this.contentJson);
}

class GrammarTopicsCompanion extends UpdateCompanion<GrammarTopicRow> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<int> orderIndex;
  final Value<bool> isLeaf;
  final Value<String> searchText;
  final Value<String?> contentJson;
  final Value<int> rowid;
  const GrammarTopicsCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.isLeaf = const Value.absent(),
    this.searchText = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrammarTopicsCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String title,
    this.subtitle = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.isLeaf = const Value.absent(),
    this.searchText = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<GrammarTopicRow> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<int>? orderIndex,
    Expression<bool>? isLeaf,
    Expression<String>? searchText,
    Expression<String>? contentJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (orderIndex != null) 'order_index': orderIndex,
      if (isLeaf != null) 'is_leaf': isLeaf,
      if (searchText != null) 'search_text': searchText,
      if (contentJson != null) 'content_json': contentJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrammarTopicsCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? title,
    Value<String?>? subtitle,
    Value<int>? orderIndex,
    Value<bool>? isLeaf,
    Value<String>? searchText,
    Value<String?>? contentJson,
    Value<int>? rowid,
  }) {
    return GrammarTopicsCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      orderIndex: orderIndex ?? this.orderIndex,
      isLeaf: isLeaf ?? this.isLeaf,
      searchText: searchText ?? this.searchText,
      contentJson: contentJson ?? this.contentJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (isLeaf.present) {
      map['is_leaf'] = Variable<bool>(isLeaf.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrammarTopicsCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('isLeaf: $isLeaf, ')
          ..write('searchText: $searchText, ')
          ..write('contentJson: $contentJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VocabularyListsTable extends VocabularyLists
    with TableInfo<$VocabularyListsTable, VocabularyListRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyListsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _subtitleMeta = const VerificationMeta(
    'subtitle',
  );
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
    'subtitle',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wordCountMeta = const VerificationMeta(
    'wordCount',
  );
  @override
  late final GeneratedColumn<int> wordCount = GeneratedColumn<int>(
    'word_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    subtitle,
    orderIndex,
    wordCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabularyListRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(
        _subtitleMeta,
        subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('word_count')) {
      context.handle(
        _wordCountMeta,
        wordCount.isAcceptableOrUnknown(data['word_count']!, _wordCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyListRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyListRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subtitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      wordCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_count'],
      )!,
    );
  }

  @override
  $VocabularyListsTable createAlias(String alias) {
    return $VocabularyListsTable(attachedDatabase, alias);
  }
}

class VocabularyListRow extends DataClass
    implements Insertable<VocabularyListRow> {
  /// Stable slug id, e.g. `general`, `business`.
  final String id;
  final String title;
  final String? subtitle;
  final int orderIndex;
  final int wordCount;
  const VocabularyListRow({
    required this.id,
    required this.title,
    this.subtitle,
    required this.orderIndex,
    required this.wordCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    map['order_index'] = Variable<int>(orderIndex);
    map['word_count'] = Variable<int>(wordCount);
    return map;
  }

  VocabularyListsCompanion toCompanion(bool nullToAbsent) {
    return VocabularyListsCompanion(
      id: Value(id),
      title: Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      orderIndex: Value(orderIndex),
      wordCount: Value(wordCount),
    );
  }

  factory VocabularyListRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyListRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      wordCount: serializer.fromJson<int>(json['wordCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'wordCount': serializer.toJson<int>(wordCount),
    };
  }

  VocabularyListRow copyWith({
    String? id,
    String? title,
    Value<String?> subtitle = const Value.absent(),
    int? orderIndex,
    int? wordCount,
  }) => VocabularyListRow(
    id: id ?? this.id,
    title: title ?? this.title,
    subtitle: subtitle.present ? subtitle.value : this.subtitle,
    orderIndex: orderIndex ?? this.orderIndex,
    wordCount: wordCount ?? this.wordCount,
  );
  VocabularyListRow copyWithCompanion(VocabularyListsCompanion data) {
    return VocabularyListRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      wordCount: data.wordCount.present ? data.wordCount.value : this.wordCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyListRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('wordCount: $wordCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, subtitle, orderIndex, wordCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyListRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.orderIndex == this.orderIndex &&
          other.wordCount == this.wordCount);
}

class VocabularyListsCompanion extends UpdateCompanion<VocabularyListRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<int> orderIndex;
  final Value<int> wordCount;
  final Value<int> rowid;
  const VocabularyListsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularyListsCompanion.insert({
    required String id,
    required String title,
    this.subtitle = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.wordCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<VocabularyListRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<int>? orderIndex,
    Expression<int>? wordCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (orderIndex != null) 'order_index': orderIndex,
      if (wordCount != null) 'word_count': wordCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularyListsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? subtitle,
    Value<int>? orderIndex,
    Value<int>? wordCount,
    Value<int>? rowid,
  }) {
    return VocabularyListsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      orderIndex: orderIndex ?? this.orderIndex,
      wordCount: wordCount ?? this.wordCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (wordCount.present) {
      map['word_count'] = Variable<int>(wordCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyListsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('wordCount: $wordCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VocabularyWordsTable extends VocabularyWords
    with TableInfo<$VocabularyWordsTable, VocabularyWordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordLowerMeta = const VerificationMeta(
    'wordLower',
  );
  @override
  late final GeneratedColumn<String> wordLower = GeneratedColumn<String>(
    'word_lower',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _letterMeta = const VerificationMeta('letter');
  @override
  late final GeneratedColumn<String> letter = GeneratedColumn<String>(
    'letter',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ipaMeta = const VerificationMeta('ipa');
  @override
  late final GeneratedColumn<String> ipa = GeneratedColumn<String>(
    'ipa',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urduMeaningMeta = const VerificationMeta(
    'urduMeaning',
  );
  @override
  late final GeneratedColumn<String> urduMeaning = GeneratedColumn<String>(
    'urdu_meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _englishMeaningMeta = const VerificationMeta(
    'englishMeaning',
  );
  @override
  late final GeneratedColumn<String> englishMeaning = GeneratedColumn<String>(
    'english_meaning',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _partOfSpeechMeta = const VerificationMeta(
    'partOfSpeech',
  );
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
    'part_of_speech',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listId,
    word,
    wordLower,
    letter,
    ipa,
    urduMeaning,
    englishMeaning,
    partOfSpeech,
    orderIndex,
    searchText,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<VocabularyWordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listIdMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('word_lower')) {
      context.handle(
        _wordLowerMeta,
        wordLower.isAcceptableOrUnknown(data['word_lower']!, _wordLowerMeta),
      );
    } else if (isInserting) {
      context.missing(_wordLowerMeta);
    }
    if (data.containsKey('letter')) {
      context.handle(
        _letterMeta,
        letter.isAcceptableOrUnknown(data['letter']!, _letterMeta),
      );
    } else if (isInserting) {
      context.missing(_letterMeta);
    }
    if (data.containsKey('ipa')) {
      context.handle(
        _ipaMeta,
        ipa.isAcceptableOrUnknown(data['ipa']!, _ipaMeta),
      );
    }
    if (data.containsKey('urdu_meaning')) {
      context.handle(
        _urduMeaningMeta,
        urduMeaning.isAcceptableOrUnknown(
          data['urdu_meaning']!,
          _urduMeaningMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_urduMeaningMeta);
    }
    if (data.containsKey('english_meaning')) {
      context.handle(
        _englishMeaningMeta,
        englishMeaning.isAcceptableOrUnknown(
          data['english_meaning']!,
          _englishMeaningMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_englishMeaningMeta);
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
        _partOfSpeechMeta,
        partOfSpeech.isAcceptableOrUnknown(
          data['part_of_speech']!,
          _partOfSpeechMeta,
        ),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyWordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyWordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      )!,
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      wordLower: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word_lower'],
      )!,
      letter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}letter'],
      )!,
      ipa: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ipa'],
      ),
      urduMeaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}urdu_meaning'],
      )!,
      englishMeaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}english_meaning'],
      )!,
      partOfSpeech: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}part_of_speech'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
    );
  }

  @override
  $VocabularyWordsTable createAlias(String alias) {
    return $VocabularyWordsTable(attachedDatabase, alias);
  }
}

class VocabularyWordRow extends DataClass
    implements Insertable<VocabularyWordRow> {
  /// Stable composite id: `<listId>/<wordLower>`.
  final String id;
  final String listId;
  final String word;
  final String wordLower;

  /// Uppercase A–Z bucket (or `#` for non-alphabetic) for grouping/headers.
  final String letter;
  final String? ipa;
  final String urduMeaning;
  final String englishMeaning;
  final String? partOfSpeech;
  final int orderIndex;

  /// Lowercased English word + Urdu meaning, for case-insensitive substring
  /// search across both scripts.
  final String searchText;
  const VocabularyWordRow({
    required this.id,
    required this.listId,
    required this.word,
    required this.wordLower,
    required this.letter,
    this.ipa,
    required this.urduMeaning,
    required this.englishMeaning,
    this.partOfSpeech,
    required this.orderIndex,
    required this.searchText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['list_id'] = Variable<String>(listId);
    map['word'] = Variable<String>(word);
    map['word_lower'] = Variable<String>(wordLower);
    map['letter'] = Variable<String>(letter);
    if (!nullToAbsent || ipa != null) {
      map['ipa'] = Variable<String>(ipa);
    }
    map['urdu_meaning'] = Variable<String>(urduMeaning);
    map['english_meaning'] = Variable<String>(englishMeaning);
    if (!nullToAbsent || partOfSpeech != null) {
      map['part_of_speech'] = Variable<String>(partOfSpeech);
    }
    map['order_index'] = Variable<int>(orderIndex);
    map['search_text'] = Variable<String>(searchText);
    return map;
  }

  VocabularyWordsCompanion toCompanion(bool nullToAbsent) {
    return VocabularyWordsCompanion(
      id: Value(id),
      listId: Value(listId),
      word: Value(word),
      wordLower: Value(wordLower),
      letter: Value(letter),
      ipa: ipa == null && nullToAbsent ? const Value.absent() : Value(ipa),
      urduMeaning: Value(urduMeaning),
      englishMeaning: Value(englishMeaning),
      partOfSpeech: partOfSpeech == null && nullToAbsent
          ? const Value.absent()
          : Value(partOfSpeech),
      orderIndex: Value(orderIndex),
      searchText: Value(searchText),
    );
  }

  factory VocabularyWordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyWordRow(
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String>(json['listId']),
      word: serializer.fromJson<String>(json['word']),
      wordLower: serializer.fromJson<String>(json['wordLower']),
      letter: serializer.fromJson<String>(json['letter']),
      ipa: serializer.fromJson<String?>(json['ipa']),
      urduMeaning: serializer.fromJson<String>(json['urduMeaning']),
      englishMeaning: serializer.fromJson<String>(json['englishMeaning']),
      partOfSpeech: serializer.fromJson<String?>(json['partOfSpeech']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      searchText: serializer.fromJson<String>(json['searchText']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String>(listId),
      'word': serializer.toJson<String>(word),
      'wordLower': serializer.toJson<String>(wordLower),
      'letter': serializer.toJson<String>(letter),
      'ipa': serializer.toJson<String?>(ipa),
      'urduMeaning': serializer.toJson<String>(urduMeaning),
      'englishMeaning': serializer.toJson<String>(englishMeaning),
      'partOfSpeech': serializer.toJson<String?>(partOfSpeech),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'searchText': serializer.toJson<String>(searchText),
    };
  }

  VocabularyWordRow copyWith({
    String? id,
    String? listId,
    String? word,
    String? wordLower,
    String? letter,
    Value<String?> ipa = const Value.absent(),
    String? urduMeaning,
    String? englishMeaning,
    Value<String?> partOfSpeech = const Value.absent(),
    int? orderIndex,
    String? searchText,
  }) => VocabularyWordRow(
    id: id ?? this.id,
    listId: listId ?? this.listId,
    word: word ?? this.word,
    wordLower: wordLower ?? this.wordLower,
    letter: letter ?? this.letter,
    ipa: ipa.present ? ipa.value : this.ipa,
    urduMeaning: urduMeaning ?? this.urduMeaning,
    englishMeaning: englishMeaning ?? this.englishMeaning,
    partOfSpeech: partOfSpeech.present ? partOfSpeech.value : this.partOfSpeech,
    orderIndex: orderIndex ?? this.orderIndex,
    searchText: searchText ?? this.searchText,
  );
  VocabularyWordRow copyWithCompanion(VocabularyWordsCompanion data) {
    return VocabularyWordRow(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      word: data.word.present ? data.word.value : this.word,
      wordLower: data.wordLower.present ? data.wordLower.value : this.wordLower,
      letter: data.letter.present ? data.letter.value : this.letter,
      ipa: data.ipa.present ? data.ipa.value : this.ipa,
      urduMeaning: data.urduMeaning.present
          ? data.urduMeaning.value
          : this.urduMeaning,
      englishMeaning: data.englishMeaning.present
          ? data.englishMeaning.value
          : this.englishMeaning,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyWordRow(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('word: $word, ')
          ..write('wordLower: $wordLower, ')
          ..write('letter: $letter, ')
          ..write('ipa: $ipa, ')
          ..write('urduMeaning: $urduMeaning, ')
          ..write('englishMeaning: $englishMeaning, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('searchText: $searchText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listId,
    word,
    wordLower,
    letter,
    ipa,
    urduMeaning,
    englishMeaning,
    partOfSpeech,
    orderIndex,
    searchText,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyWordRow &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.word == this.word &&
          other.wordLower == this.wordLower &&
          other.letter == this.letter &&
          other.ipa == this.ipa &&
          other.urduMeaning == this.urduMeaning &&
          other.englishMeaning == this.englishMeaning &&
          other.partOfSpeech == this.partOfSpeech &&
          other.orderIndex == this.orderIndex &&
          other.searchText == this.searchText);
}

class VocabularyWordsCompanion extends UpdateCompanion<VocabularyWordRow> {
  final Value<String> id;
  final Value<String> listId;
  final Value<String> word;
  final Value<String> wordLower;
  final Value<String> letter;
  final Value<String?> ipa;
  final Value<String> urduMeaning;
  final Value<String> englishMeaning;
  final Value<String?> partOfSpeech;
  final Value<int> orderIndex;
  final Value<String> searchText;
  final Value<int> rowid;
  const VocabularyWordsCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.word = const Value.absent(),
    this.wordLower = const Value.absent(),
    this.letter = const Value.absent(),
    this.ipa = const Value.absent(),
    this.urduMeaning = const Value.absent(),
    this.englishMeaning = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.searchText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularyWordsCompanion.insert({
    required String id,
    required String listId,
    required String word,
    required String wordLower,
    required String letter,
    this.ipa = const Value.absent(),
    required String urduMeaning,
    required String englishMeaning,
    this.partOfSpeech = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.searchText = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       listId = Value(listId),
       word = Value(word),
       wordLower = Value(wordLower),
       letter = Value(letter),
       urduMeaning = Value(urduMeaning),
       englishMeaning = Value(englishMeaning);
  static Insertable<VocabularyWordRow> custom({
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? word,
    Expression<String>? wordLower,
    Expression<String>? letter,
    Expression<String>? ipa,
    Expression<String>? urduMeaning,
    Expression<String>? englishMeaning,
    Expression<String>? partOfSpeech,
    Expression<int>? orderIndex,
    Expression<String>? searchText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (word != null) 'word': word,
      if (wordLower != null) 'word_lower': wordLower,
      if (letter != null) 'letter': letter,
      if (ipa != null) 'ipa': ipa,
      if (urduMeaning != null) 'urdu_meaning': urduMeaning,
      if (englishMeaning != null) 'english_meaning': englishMeaning,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (orderIndex != null) 'order_index': orderIndex,
      if (searchText != null) 'search_text': searchText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularyWordsCompanion copyWith({
    Value<String>? id,
    Value<String>? listId,
    Value<String>? word,
    Value<String>? wordLower,
    Value<String>? letter,
    Value<String?>? ipa,
    Value<String>? urduMeaning,
    Value<String>? englishMeaning,
    Value<String?>? partOfSpeech,
    Value<int>? orderIndex,
    Value<String>? searchText,
    Value<int>? rowid,
  }) {
    return VocabularyWordsCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      word: word ?? this.word,
      wordLower: wordLower ?? this.wordLower,
      letter: letter ?? this.letter,
      ipa: ipa ?? this.ipa,
      urduMeaning: urduMeaning ?? this.urduMeaning,
      englishMeaning: englishMeaning ?? this.englishMeaning,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      orderIndex: orderIndex ?? this.orderIndex,
      searchText: searchText ?? this.searchText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (wordLower.present) {
      map['word_lower'] = Variable<String>(wordLower.value);
    }
    if (letter.present) {
      map['letter'] = Variable<String>(letter.value);
    }
    if (ipa.present) {
      map['ipa'] = Variable<String>(ipa.value);
    }
    if (urduMeaning.present) {
      map['urdu_meaning'] = Variable<String>(urduMeaning.value);
    }
    if (englishMeaning.present) {
      map['english_meaning'] = Variable<String>(englishMeaning.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyWordsCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('word: $word, ')
          ..write('wordLower: $wordLower, ')
          ..write('letter: $letter, ')
          ..write('ipa: $ipa, ')
          ..write('urduMeaning: $urduMeaning, ')
          ..write('englishMeaning: $englishMeaning, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('searchText: $searchText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudyTasksTable extends StudyTasks
    with TableInfo<$StudyTasksTable, StudyTaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
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
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta(
    'startMinute',
  );
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMinuteMeta = const VerificationMeta(
    'endMinute',
  );
  @override
  late final GeneratedColumn<int> endMinute = GeneratedColumn<int>(
    'end_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('session'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    day,
    title,
    subject,
    startMinute,
    endMinute,
    priority,
    completed,
    orderIndex,
    createdAt,
    updatedAt,
    completedAt,
    topic,
    notes,
    status,
    durationMinutes,
    kind,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyTaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(
          data['start_minute']!,
          _startMinuteMeta,
        ),
      );
    }
    if (data.containsKey('end_minute')) {
      context.handle(
        _endMinuteMeta,
        endMinute.isAcceptableOrUnknown(data['end_minute']!, _endMinuteMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
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
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudyTaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyTaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      ),
      endMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minute'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $StudyTasksTable createAlias(String alias) {
    return $StudyTasksTable(attachedDatabase, alias);
  }
}

class StudyTaskRow extends DataClass implements Insertable<StudyTaskRow> {
  final String id;
  final String day;
  final String title;
  final String? subject;

  /// Start/end time as minutes from midnight (0–1439); null when unscheduled.
  final int? startMinute;
  final int? endMinute;

  /// 0 = low, 1 = medium, 2 = high (mirrors TaskPriority.index).
  final int priority;
  final bool completed;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  /// The topic within the subject (user-defined; null for breaks).
  final String? topic;

  /// Free-form notes/description (user-defined).
  final String? notes;

  /// 0 = pending, 1 = in progress, 2 = completed (mirrors TaskStatus.index).
  /// Kept in sync with [completed] so pre-v0.7.1 queries keep working.
  final int status;

  /// Actual studied minutes recorded for this session (via a timer); optional.
  final int? durationMinutes;

  /// 'session' or 'break' (mirrors SessionKind.key). Existing rows default to
  /// 'session'. Breaks store their name in [title] and never count as sessions.
  final String kind;
  const StudyTaskRow({
    required this.id,
    required this.day,
    required this.title,
    this.subject,
    this.startMinute,
    this.endMinute,
    required this.priority,
    required this.completed,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.topic,
    this.notes,
    required this.status,
    this.durationMinutes,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day'] = Variable<String>(day);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || startMinute != null) {
      map['start_minute'] = Variable<int>(startMinute);
    }
    if (!nullToAbsent || endMinute != null) {
      map['end_minute'] = Variable<int>(endMinute);
    }
    map['priority'] = Variable<int>(priority);
    map['completed'] = Variable<bool>(completed);
    map['order_index'] = Variable<int>(orderIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || topic != null) {
      map['topic'] = Variable<String>(topic);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    map['kind'] = Variable<String>(kind);
    return map;
  }

  StudyTasksCompanion toCompanion(bool nullToAbsent) {
    return StudyTasksCompanion(
      id: Value(id),
      day: Value(day),
      title: Value(title),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      startMinute: startMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(startMinute),
      endMinute: endMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(endMinute),
      priority: Value(priority),
      completed: Value(completed),
      orderIndex: Value(orderIndex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      topic: topic == null && nullToAbsent
          ? const Value.absent()
          : Value(topic),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      kind: Value(kind),
    );
  }

  factory StudyTaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyTaskRow(
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      title: serializer.fromJson<String>(json['title']),
      subject: serializer.fromJson<String?>(json['subject']),
      startMinute: serializer.fromJson<int?>(json['startMinute']),
      endMinute: serializer.fromJson<int?>(json['endMinute']),
      priority: serializer.fromJson<int>(json['priority']),
      completed: serializer.fromJson<bool>(json['completed']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      topic: serializer.fromJson<String?>(json['topic']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<int>(json['status']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<String>(day),
      'title': serializer.toJson<String>(title),
      'subject': serializer.toJson<String?>(subject),
      'startMinute': serializer.toJson<int?>(startMinute),
      'endMinute': serializer.toJson<int?>(endMinute),
      'priority': serializer.toJson<int>(priority),
      'completed': serializer.toJson<bool>(completed),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'topic': serializer.toJson<String?>(topic),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<int>(status),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'kind': serializer.toJson<String>(kind),
    };
  }

  StudyTaskRow copyWith({
    String? id,
    String? day,
    String? title,
    Value<String?> subject = const Value.absent(),
    Value<int?> startMinute = const Value.absent(),
    Value<int?> endMinute = const Value.absent(),
    int? priority,
    bool? completed,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> topic = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? status,
    Value<int?> durationMinutes = const Value.absent(),
    String? kind,
  }) => StudyTaskRow(
    id: id ?? this.id,
    day: day ?? this.day,
    title: title ?? this.title,
    subject: subject.present ? subject.value : this.subject,
    startMinute: startMinute.present ? startMinute.value : this.startMinute,
    endMinute: endMinute.present ? endMinute.value : this.endMinute,
    priority: priority ?? this.priority,
    completed: completed ?? this.completed,
    orderIndex: orderIndex ?? this.orderIndex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    topic: topic.present ? topic.value : this.topic,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    durationMinutes: durationMinutes.present
        ? durationMinutes.value
        : this.durationMinutes,
    kind: kind ?? this.kind,
  );
  StudyTaskRow copyWithCompanion(StudyTasksCompanion data) {
    return StudyTaskRow(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      title: data.title.present ? data.title.value : this.title,
      subject: data.subject.present ? data.subject.value : this.subject,
      startMinute: data.startMinute.present
          ? data.startMinute.value
          : this.startMinute,
      endMinute: data.endMinute.present ? data.endMinute.value : this.endMinute,
      priority: data.priority.present ? data.priority.value : this.priority,
      completed: data.completed.present ? data.completed.value : this.completed,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      topic: data.topic.present ? data.topic.value : this.topic,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyTaskRow(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('priority: $priority, ')
          ..write('completed: $completed, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('topic: $topic, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    day,
    title,
    subject,
    startMinute,
    endMinute,
    priority,
    completed,
    orderIndex,
    createdAt,
    updatedAt,
    completedAt,
    topic,
    notes,
    status,
    durationMinutes,
    kind,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyTaskRow &&
          other.id == this.id &&
          other.day == this.day &&
          other.title == this.title &&
          other.subject == this.subject &&
          other.startMinute == this.startMinute &&
          other.endMinute == this.endMinute &&
          other.priority == this.priority &&
          other.completed == this.completed &&
          other.orderIndex == this.orderIndex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt &&
          other.topic == this.topic &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.durationMinutes == this.durationMinutes &&
          other.kind == this.kind);
}

class StudyTasksCompanion extends UpdateCompanion<StudyTaskRow> {
  final Value<String> id;
  final Value<String> day;
  final Value<String> title;
  final Value<String?> subject;
  final Value<int?> startMinute;
  final Value<int?> endMinute;
  final Value<int> priority;
  final Value<bool> completed;
  final Value<int> orderIndex;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> topic;
  final Value<String?> notes;
  final Value<int> status;
  final Value<int?> durationMinutes;
  final Value<String> kind;
  final Value<int> rowid;
  const StudyTasksCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.title = const Value.absent(),
    this.subject = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.priority = const Value.absent(),
    this.completed = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.topic = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudyTasksCompanion.insert({
    required String id,
    required String day,
    required String title,
    this.subject = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.priority = const Value.absent(),
    this.completed = const Value.absent(),
    this.orderIndex = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.completedAt = const Value.absent(),
    this.topic = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StudyTaskRow> custom({
    Expression<String>? id,
    Expression<String>? day,
    Expression<String>? title,
    Expression<String>? subject,
    Expression<int>? startMinute,
    Expression<int>? endMinute,
    Expression<int>? priority,
    Expression<bool>? completed,
    Expression<int>? orderIndex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? topic,
    Expression<String>? notes,
    Expression<int>? status,
    Expression<int>? durationMinutes,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (title != null) 'title': title,
      if (subject != null) 'subject': subject,
      if (startMinute != null) 'start_minute': startMinute,
      if (endMinute != null) 'end_minute': endMinute,
      if (priority != null) 'priority': priority,
      if (completed != null) 'completed': completed,
      if (orderIndex != null) 'order_index': orderIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (topic != null) 'topic': topic,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudyTasksCompanion copyWith({
    Value<String>? id,
    Value<String>? day,
    Value<String>? title,
    Value<String?>? subject,
    Value<int?>? startMinute,
    Value<int?>? endMinute,
    Value<int>? priority,
    Value<bool>? completed,
    Value<int>? orderIndex,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? completedAt,
    Value<String?>? topic,
    Value<String?>? notes,
    Value<int>? status,
    Value<int?>? durationMinutes,
    Value<String>? kind,
    Value<int>? rowid,
  }) {
    return StudyTasksCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      topic: topic ?? this.topic,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (endMinute.present) {
      map['end_minute'] = Variable<int>(endMinute.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyTasksCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('priority: $priority, ')
          ..write('completed: $completed, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('topic: $topic, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudyGoalsTable extends StudyGoals
    with TableInfo<$StudyGoalsTable, StudyGoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyGoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('custom'),
  );
  static const VerificationMeta _targetCountMeta = const VerificationMeta(
    'targetCount',
  );
  @override
  late final GeneratedColumn<int> targetCount = GeneratedColumn<int>(
    'target_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _currentCountMeta = const VerificationMeta(
    'currentCount',
  );
  @override
  late final GeneratedColumn<int> currentCount = GeneratedColumn<int>(
    'current_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    day,
    title,
    type,
    targetCount,
    currentCount,
    unit,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyGoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('target_count')) {
      context.handle(
        _targetCountMeta,
        targetCount.isAcceptableOrUnknown(
          data['target_count']!,
          _targetCountMeta,
        ),
      );
    }
    if (data.containsKey('current_count')) {
      context.handle(
        _currentCountMeta,
        currentCount.isAcceptableOrUnknown(
          data['current_count']!,
          _currentCountMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudyGoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyGoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      targetCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_count'],
      )!,
      currentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_count'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StudyGoalsTable createAlias(String alias) {
    return $StudyGoalsTable(attachedDatabase, alias);
  }
}

class StudyGoalRow extends DataClass implements Insertable<StudyGoalRow> {
  final String id;
  final String day;
  final String title;

  /// vocabulary / reading / grammar / mcq / custom (mirrors GoalType.key).
  final String type;
  final int targetCount;
  final int currentCount;
  final String? unit;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StudyGoalRow({
    required this.id,
    required this.day,
    required this.title,
    required this.type,
    required this.targetCount,
    required this.currentCount,
    this.unit,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day'] = Variable<String>(day);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['target_count'] = Variable<int>(targetCount);
    map['current_count'] = Variable<int>(currentCount);
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StudyGoalsCompanion toCompanion(bool nullToAbsent) {
    return StudyGoalsCompanion(
      id: Value(id),
      day: Value(day),
      title: Value(title),
      type: Value(type),
      targetCount: Value(targetCount),
      currentCount: Value(currentCount),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StudyGoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyGoalRow(
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      targetCount: serializer.fromJson<int>(json['targetCount']),
      currentCount: serializer.fromJson<int>(json['currentCount']),
      unit: serializer.fromJson<String?>(json['unit']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<String>(day),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'targetCount': serializer.toJson<int>(targetCount),
      'currentCount': serializer.toJson<int>(currentCount),
      'unit': serializer.toJson<String?>(unit),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StudyGoalRow copyWith({
    String? id,
    String? day,
    String? title,
    String? type,
    int? targetCount,
    int? currentCount,
    Value<String?> unit = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StudyGoalRow(
    id: id ?? this.id,
    day: day ?? this.day,
    title: title ?? this.title,
    type: type ?? this.type,
    targetCount: targetCount ?? this.targetCount,
    currentCount: currentCount ?? this.currentCount,
    unit: unit.present ? unit.value : this.unit,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StudyGoalRow copyWithCompanion(StudyGoalsCompanion data) {
    return StudyGoalRow(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      targetCount: data.targetCount.present
          ? data.targetCount.value
          : this.targetCount,
      currentCount: data.currentCount.present
          ? data.currentCount.value
          : this.currentCount,
      unit: data.unit.present ? data.unit.value : this.unit,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyGoalRow(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('targetCount: $targetCount, ')
          ..write('currentCount: $currentCount, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    day,
    title,
    type,
    targetCount,
    currentCount,
    unit,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyGoalRow &&
          other.id == this.id &&
          other.day == this.day &&
          other.title == this.title &&
          other.type == this.type &&
          other.targetCount == this.targetCount &&
          other.currentCount == this.currentCount &&
          other.unit == this.unit &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StudyGoalsCompanion extends UpdateCompanion<StudyGoalRow> {
  final Value<String> id;
  final Value<String> day;
  final Value<String> title;
  final Value<String> type;
  final Value<int> targetCount;
  final Value<int> currentCount;
  final Value<String?> unit;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StudyGoalsCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.targetCount = const Value.absent(),
    this.currentCount = const Value.absent(),
    this.unit = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudyGoalsCompanion.insert({
    required String id,
    required String day,
    required String title,
    this.type = const Value.absent(),
    this.targetCount = const Value.absent(),
    this.currentCount = const Value.absent(),
    this.unit = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StudyGoalRow> custom({
    Expression<String>? id,
    Expression<String>? day,
    Expression<String>? title,
    Expression<String>? type,
    Expression<int>? targetCount,
    Expression<int>? currentCount,
    Expression<String>? unit,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (targetCount != null) 'target_count': targetCount,
      if (currentCount != null) 'current_count': currentCount,
      if (unit != null) 'unit': unit,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudyGoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? day,
    Value<String>? title,
    Value<String>? type,
    Value<int>? targetCount,
    Value<int>? currentCount,
    Value<String?>? unit,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StudyGoalsCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      title: title ?? this.title,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (targetCount.present) {
      map['target_count'] = Variable<int>(targetCount.value);
    }
    if (currentCount.present) {
      map['current_count'] = Variable<int>(currentCount.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyGoalsCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('targetCount: $targetCount, ')
          ..write('currentCount: $currentCount, ')
          ..write('unit: $unit, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudySessionsTable extends StudySessions
    with TableInfo<$StudySessionsTable, StudySessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pomodoro'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    day,
    startedAt,
    durationMinutes,
    kind,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudySessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudySessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudySessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StudySessionsTable createAlias(String alias) {
    return $StudySessionsTable(attachedDatabase, alias);
  }
}

class StudySessionRow extends DataClass implements Insertable<StudySessionRow> {
  final String id;
  final String day;
  final DateTime startedAt;
  final int durationMinutes;

  /// pomodoro / manual.
  final String kind;
  final DateTime createdAt;
  const StudySessionRow({
    required this.id,
    required this.day,
    required this.startedAt,
    required this.durationMinutes,
    required this.kind,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['day'] = Variable<String>(day);
    map['started_at'] = Variable<DateTime>(startedAt);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['kind'] = Variable<String>(kind);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StudySessionsCompanion toCompanion(bool nullToAbsent) {
    return StudySessionsCompanion(
      id: Value(id),
      day: Value(day),
      startedAt: Value(startedAt),
      durationMinutes: Value(durationMinutes),
      kind: Value(kind),
      createdAt: Value(createdAt),
    );
  }

  factory StudySessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudySessionRow(
      id: serializer.fromJson<String>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      kind: serializer.fromJson<String>(json['kind']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'day': serializer.toJson<String>(day),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'kind': serializer.toJson<String>(kind),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StudySessionRow copyWith({
    String? id,
    String? day,
    DateTime? startedAt,
    int? durationMinutes,
    String? kind,
    DateTime? createdAt,
  }) => StudySessionRow(
    id: id ?? this.id,
    day: day ?? this.day,
    startedAt: startedAt ?? this.startedAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    kind: kind ?? this.kind,
    createdAt: createdAt ?? this.createdAt,
  );
  StudySessionRow copyWithCompanion(StudySessionsCompanion data) {
    return StudySessionRow(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      kind: data.kind.present ? data.kind.value : this.kind,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudySessionRow(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, day, startedAt, durationMinutes, kind, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudySessionRow &&
          other.id == this.id &&
          other.day == this.day &&
          other.startedAt == this.startedAt &&
          other.durationMinutes == this.durationMinutes &&
          other.kind == this.kind &&
          other.createdAt == this.createdAt);
}

class StudySessionsCompanion extends UpdateCompanion<StudySessionRow> {
  final Value<String> id;
  final Value<String> day;
  final Value<DateTime> startedAt;
  final Value<int> durationMinutes;
  final Value<String> kind;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StudySessionsCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.kind = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudySessionsCompanion.insert({
    required String id,
    required String day,
    required DateTime startedAt,
    required int durationMinutes,
    this.kind = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       day = Value(day),
       startedAt = Value(startedAt),
       durationMinutes = Value(durationMinutes),
       createdAt = Value(createdAt);
  static Insertable<StudySessionRow> custom({
    Expression<String>? id,
    Expression<String>? day,
    Expression<DateTime>? startedAt,
    Expression<int>? durationMinutes,
    Expression<String>? kind,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (startedAt != null) 'started_at': startedAt,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (kind != null) 'kind': kind,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudySessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? day,
    Value<DateTime>? startedAt,
    Value<int>? durationMinutes,
    Value<String>? kind,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return StudySessionsCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      startedAt: startedAt ?? this.startedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      kind: kind ?? this.kind,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudySessionsCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('startedAt: $startedAt, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('kind: $kind, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudyTemplatesTable extends StudyTemplates
    with TableInfo<$StudyTemplatesTable, StudyTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudyTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StudyTemplatesTable createAlias(String alias) {
    return $StudyTemplatesTable(attachedDatabase, alias);
  }
}

class StudyTemplateRow extends DataClass
    implements Insertable<StudyTemplateRow> {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StudyTemplateRow({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StudyTemplatesCompanion toCompanion(bool nullToAbsent) {
    return StudyTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StudyTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StudyTemplateRow copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StudyTemplateRow(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StudyTemplateRow copyWithCompanion(StudyTemplatesCompanion data) {
    return StudyTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyTemplateRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyTemplateRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StudyTemplatesCompanion extends UpdateCompanion<StudyTemplateRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StudyTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudyTemplatesCompanion.insert({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StudyTemplateRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudyTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StudyTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudyTemplateItemsTable extends StudyTemplateItems
    with TableInfo<$StudyTemplateItemsTable, StudyTemplateItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudyTemplateItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('session'),
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
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startMinuteMeta = const VerificationMeta(
    'startMinute',
  );
  @override
  late final GeneratedColumn<int> startMinute = GeneratedColumn<int>(
    'start_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMinuteMeta = const VerificationMeta(
    'endMinute',
  );
  @override
  late final GeneratedColumn<int> endMinute = GeneratedColumn<int>(
    'end_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    kind,
    title,
    subject,
    topic,
    startMinute,
    endMinute,
    priority,
    notes,
    orderIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_template_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudyTemplateItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('start_minute')) {
      context.handle(
        _startMinuteMeta,
        startMinute.isAcceptableOrUnknown(
          data['start_minute']!,
          _startMinuteMeta,
        ),
      );
    }
    if (data.containsKey('end_minute')) {
      context.handle(
        _endMinuteMeta,
        endMinute.isAcceptableOrUnknown(data['end_minute']!, _endMinuteMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudyTemplateItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudyTemplateItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      ),
      startMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_minute'],
      ),
      endMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_minute'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
    );
  }

  @override
  $StudyTemplateItemsTable createAlias(String alias) {
    return $StudyTemplateItemsTable(attachedDatabase, alias);
  }
}

class StudyTemplateItemRow extends DataClass
    implements Insertable<StudyTemplateItemRow> {
  final String id;
  final String templateId;
  final String kind;
  final String title;
  final String? subject;
  final String? topic;
  final int? startMinute;
  final int? endMinute;
  final int priority;
  final String? notes;
  final int orderIndex;
  const StudyTemplateItemRow({
    required this.id,
    required this.templateId,
    required this.kind,
    required this.title,
    this.subject,
    this.topic,
    this.startMinute,
    this.endMinute,
    required this.priority,
    this.notes,
    required this.orderIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || topic != null) {
      map['topic'] = Variable<String>(topic);
    }
    if (!nullToAbsent || startMinute != null) {
      map['start_minute'] = Variable<int>(startMinute);
    }
    if (!nullToAbsent || endMinute != null) {
      map['end_minute'] = Variable<int>(endMinute);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  StudyTemplateItemsCompanion toCompanion(bool nullToAbsent) {
    return StudyTemplateItemsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      kind: Value(kind),
      title: Value(title),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      topic: topic == null && nullToAbsent
          ? const Value.absent()
          : Value(topic),
      startMinute: startMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(startMinute),
      endMinute: endMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(endMinute),
      priority: Value(priority),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      orderIndex: Value(orderIndex),
    );
  }

  factory StudyTemplateItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudyTemplateItemRow(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      subject: serializer.fromJson<String?>(json['subject']),
      topic: serializer.fromJson<String?>(json['topic']),
      startMinute: serializer.fromJson<int?>(json['startMinute']),
      endMinute: serializer.fromJson<int?>(json['endMinute']),
      priority: serializer.fromJson<int>(json['priority']),
      notes: serializer.fromJson<String?>(json['notes']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'subject': serializer.toJson<String?>(subject),
      'topic': serializer.toJson<String?>(topic),
      'startMinute': serializer.toJson<int?>(startMinute),
      'endMinute': serializer.toJson<int?>(endMinute),
      'priority': serializer.toJson<int>(priority),
      'notes': serializer.toJson<String?>(notes),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  StudyTemplateItemRow copyWith({
    String? id,
    String? templateId,
    String? kind,
    String? title,
    Value<String?> subject = const Value.absent(),
    Value<String?> topic = const Value.absent(),
    Value<int?> startMinute = const Value.absent(),
    Value<int?> endMinute = const Value.absent(),
    int? priority,
    Value<String?> notes = const Value.absent(),
    int? orderIndex,
  }) => StudyTemplateItemRow(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    subject: subject.present ? subject.value : this.subject,
    topic: topic.present ? topic.value : this.topic,
    startMinute: startMinute.present ? startMinute.value : this.startMinute,
    endMinute: endMinute.present ? endMinute.value : this.endMinute,
    priority: priority ?? this.priority,
    notes: notes.present ? notes.value : this.notes,
    orderIndex: orderIndex ?? this.orderIndex,
  );
  StudyTemplateItemRow copyWithCompanion(StudyTemplateItemsCompanion data) {
    return StudyTemplateItemRow(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      subject: data.subject.present ? data.subject.value : this.subject,
      topic: data.topic.present ? data.topic.value : this.topic,
      startMinute: data.startMinute.present
          ? data.startMinute.value
          : this.startMinute,
      endMinute: data.endMinute.present ? data.endMinute.value : this.endMinute,
      priority: data.priority.present ? data.priority.value : this.priority,
      notes: data.notes.present ? data.notes.value : this.notes,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudyTemplateItemRow(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('priority: $priority, ')
          ..write('notes: $notes, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    kind,
    title,
    subject,
    topic,
    startMinute,
    endMinute,
    priority,
    notes,
    orderIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudyTemplateItemRow &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.subject == this.subject &&
          other.topic == this.topic &&
          other.startMinute == this.startMinute &&
          other.endMinute == this.endMinute &&
          other.priority == this.priority &&
          other.notes == this.notes &&
          other.orderIndex == this.orderIndex);
}

class StudyTemplateItemsCompanion
    extends UpdateCompanion<StudyTemplateItemRow> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> kind;
  final Value<String> title;
  final Value<String?> subject;
  final Value<String?> topic;
  final Value<int?> startMinute;
  final Value<int?> endMinute;
  final Value<int> priority;
  final Value<String?> notes;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const StudyTemplateItemsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.priority = const Value.absent(),
    this.notes = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudyTemplateItemsCompanion.insert({
    required String id,
    required String templateId,
    this.kind = const Value.absent(),
    required String title,
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.startMinute = const Value.absent(),
    this.endMinute = const Value.absent(),
    this.priority = const Value.absent(),
    this.notes = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateId = Value(templateId),
       title = Value(title);
  static Insertable<StudyTemplateItemRow> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? subject,
    Expression<String>? topic,
    Expression<int>? startMinute,
    Expression<int>? endMinute,
    Expression<int>? priority,
    Expression<String>? notes,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (subject != null) 'subject': subject,
      if (topic != null) 'topic': topic,
      if (startMinute != null) 'start_minute': startMinute,
      if (endMinute != null) 'end_minute': endMinute,
      if (priority != null) 'priority': priority,
      if (notes != null) 'notes': notes,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudyTemplateItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? templateId,
    Value<String>? kind,
    Value<String>? title,
    Value<String?>? subject,
    Value<String?>? topic,
    Value<int?>? startMinute,
    Value<int?>? endMinute,
    Value<int>? priority,
    Value<String?>? notes,
    Value<int>? orderIndex,
    Value<int>? rowid,
  }) {
    return StudyTemplateItemsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      startMinute: startMinute ?? this.startMinute,
      endMinute: endMinute ?? this.endMinute,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (startMinute.present) {
      map['start_minute'] = Variable<int>(startMinute.value);
    }
    if (endMinute.present) {
      map['end_minute'] = Variable<int>(endMinute.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudyTemplateItemsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('startMinute: $startMinute, ')
          ..write('endMinute: $endMinute, ')
          ..write('priority: $priority, ')
          ..write('notes: $notes, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StudySubjectsTable extends StudySubjects
    with TableInfo<$StudySubjectsTable, StudySubjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StudySubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameLowerMeta = const VerificationMeta(
    'nameLower',
  );
  @override
  late final GeneratedColumn<String> nameLower = GeneratedColumn<String>(
    'name_lower',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    nameLower,
    color,
    archived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'study_subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<StudySubjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_lower')) {
      context.handle(
        _nameLowerMeta,
        nameLower.isAcceptableOrUnknown(data['name_lower']!, _nameLowerMeta),
      );
    } else if (isInserting) {
      context.missing(_nameLowerMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StudySubjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StudySubjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      nameLower: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_lower'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StudySubjectsTable createAlias(String alias) {
    return $StudySubjectsTable(attachedDatabase, alias);
  }
}

class StudySubjectRow extends DataClass implements Insertable<StudySubjectRow> {
  final String id;
  final String name;
  final String nameLower;

  /// ARGB colour value.
  final int color;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StudySubjectRow({
    required this.id,
    required this.name,
    required this.nameLower,
    required this.color,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['name_lower'] = Variable<String>(nameLower);
    map['color'] = Variable<int>(color);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StudySubjectsCompanion toCompanion(bool nullToAbsent) {
    return StudySubjectsCompanion(
      id: Value(id),
      name: Value(name),
      nameLower: Value(nameLower),
      color: Value(color),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StudySubjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StudySubjectRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      nameLower: serializer.fromJson<String>(json['nameLower']),
      color: serializer.fromJson<int>(json['color']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'nameLower': serializer.toJson<String>(nameLower),
      'color': serializer.toJson<int>(color),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StudySubjectRow copyWith({
    String? id,
    String? name,
    String? nameLower,
    int? color,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StudySubjectRow(
    id: id ?? this.id,
    name: name ?? this.name,
    nameLower: nameLower ?? this.nameLower,
    color: color ?? this.color,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StudySubjectRow copyWithCompanion(StudySubjectsCompanion data) {
    return StudySubjectRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      nameLower: data.nameLower.present ? data.nameLower.value : this.nameLower,
      color: data.color.present ? data.color.value : this.color,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StudySubjectRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameLower: $nameLower, ')
          ..write('color: $color, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, nameLower, color, archived, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudySubjectRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.nameLower == this.nameLower &&
          other.color == this.color &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StudySubjectsCompanion extends UpdateCompanion<StudySubjectRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> nameLower;
  final Value<int> color;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StudySubjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.nameLower = const Value.absent(),
    this.color = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StudySubjectsCompanion.insert({
    required String id,
    required String name,
    required String nameLower,
    required int color,
    this.archived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       nameLower = Value(nameLower),
       color = Value(color),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StudySubjectRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? nameLower,
    Expression<int>? color,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (nameLower != null) 'name_lower': nameLower,
      if (color != null) 'color': color,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StudySubjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? nameLower,
    Value<int>? color,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StudySubjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      nameLower: nameLower ?? this.nameLower,
      color: color ?? this.color,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (nameLower.present) {
      map['name_lower'] = Variable<String>(nameLower.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StudySubjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('nameLower: $nameLower, ')
          ..write('color: $color, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DecksTable extends Decks with TableInfo<$DecksTable, DeckRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<int> icon = GeneratedColumn<int>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    subject,
    topic,
    color,
    icon,
    archived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeckRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeckRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeckRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DecksTable createAlias(String alias) {
    return $DecksTable(attachedDatabase, alias);
  }
}

class DeckRow extends DataClass implements Insertable<DeckRow> {
  final String id;
  final String name;
  final String? description;
  final String? subject;
  final String? topic;

  /// Optional deck-specific ARGB colour (else the subject colour is used).
  final int? color;

  /// Material icon code point for the deck.
  final int? icon;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DeckRow({
    required this.id,
    required this.name,
    this.description,
    this.subject,
    this.topic,
    this.color,
    this.icon,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || topic != null) {
      map['topic'] = Variable<String>(topic);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<int>(icon);
    }
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DecksCompanion toCompanion(bool nullToAbsent) {
    return DecksCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      topic: topic == null && nullToAbsent
          ? const Value.absent()
          : Value(topic),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DeckRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeckRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      subject: serializer.fromJson<String?>(json['subject']),
      topic: serializer.fromJson<String?>(json['topic']),
      color: serializer.fromJson<int?>(json['color']),
      icon: serializer.fromJson<int?>(json['icon']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'subject': serializer.toJson<String?>(subject),
      'topic': serializer.toJson<String?>(topic),
      'color': serializer.toJson<int?>(color),
      'icon': serializer.toJson<int?>(icon),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DeckRow copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> subject = const Value.absent(),
    Value<String?> topic = const Value.absent(),
    Value<int?> color = const Value.absent(),
    Value<int?> icon = const Value.absent(),
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DeckRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    subject: subject.present ? subject.value : this.subject,
    topic: topic.present ? topic.value : this.topic,
    color: color.present ? color.value : this.color,
    icon: icon.present ? icon.value : this.icon,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DeckRow copyWithCompanion(DecksCompanion data) {
    return DeckRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      subject: data.subject.present ? data.subject.value : this.subject,
      topic: data.topic.present ? data.topic.value : this.topic,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeckRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    subject,
    topic,
    color,
    icon,
    archived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.subject == this.subject &&
          other.topic == this.topic &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DecksCompanion extends UpdateCompanion<DeckRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> subject;
  final Value<String?> topic;
  final Value<int?> color;
  final Value<int?> icon;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DecksCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DeckRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? subject,
    Expression<String>? topic,
    Expression<int>? color,
    Expression<int>? icon,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (subject != null) 'subject': subject,
      if (topic != null) 'topic': topic,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DecksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? subject,
    Value<String?>? topic,
    Value<int?>? color,
    Value<int?>? icon,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<int>(icon.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FlashcardsTable extends Flashcards
    with TableInfo<$FlashcardsTable, FlashcardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
    'front',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
    'back',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bookmarkedMeta = const VerificationMeta(
    'bookmarked',
  );
  @override
  late final GeneratedColumn<bool> bookmarked = GeneratedColumn<bool>(
    'bookmarked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bookmarked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _favoriteMeta = const VerificationMeta(
    'favorite',
  );
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
    'favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reviewStateMeta = const VerificationMeta(
    'reviewState',
  );
  @override
  late final GeneratedColumn<int> reviewState = GeneratedColumn<int>(
    'review_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<DateTime> dueAt = GeneratedColumn<DateTime>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    front,
    back,
    subject,
    topic,
    tags,
    notes,
    difficulty,
    bookmarked,
    favorite,
    reviewState,
    dueAt,
    intervalDays,
    easeFactor,
    repetitions,
    lapses,
    lastReviewedAt,
    searchText,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcards';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlashcardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('front')) {
      context.handle(
        _frontMeta,
        front.isAcceptableOrUnknown(data['front']!, _frontMeta),
      );
    } else if (isInserting) {
      context.missing(_frontMeta);
    }
    if (data.containsKey('back')) {
      context.handle(
        _backMeta,
        back.isAcceptableOrUnknown(data['back']!, _backMeta),
      );
    } else if (isInserting) {
      context.missing(_backMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('bookmarked')) {
      context.handle(
        _bookmarkedMeta,
        bookmarked.isAcceptableOrUnknown(data['bookmarked']!, _bookmarkedMeta),
      );
    }
    if (data.containsKey('favorite')) {
      context.handle(
        _favoriteMeta,
        favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta),
      );
    }
    if (data.containsKey('review_state')) {
      context.handle(
        _reviewStateMeta,
        reviewState.isAcceptableOrUnknown(
          data['review_state']!,
          _reviewStateMeta,
        ),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FlashcardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlashcardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      front: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front'],
      )!,
      back: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      )!,
      bookmarked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bookmarked'],
      )!,
      favorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}favorite'],
      )!,
      reviewState: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_state'],
      )!,
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at'],
      ),
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $FlashcardsTable createAlias(String alias) {
    return $FlashcardsTable(attachedDatabase, alias);
  }
}

class FlashcardRow extends DataClass implements Insertable<FlashcardRow> {
  final String id;
  final String deckId;
  final String front;
  final String back;
  final String? subject;
  final String? topic;

  /// Comma-separated user tags (free text).
  final String? tags;
  final String? notes;

  /// 0 = none, 1 = easy, 2 = medium, 3 = hard (mirrors CardDifficulty.index).
  final int difficulty;
  final bool bookmarked;
  final bool favorite;

  /// 0 = new, 1 = learning, 2 = review (mirrors ReviewState.index).
  final int reviewState;
  final DateTime? dueAt;
  final int intervalDays;
  final double easeFactor;
  final int repetitions;
  final int lapses;
  final DateTime? lastReviewedAt;
  final String searchText;
  final DateTime createdAt;
  final DateTime updatedAt;
  const FlashcardRow({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.subject,
    this.topic,
    this.tags,
    this.notes,
    required this.difficulty,
    required this.bookmarked,
    required this.favorite,
    required this.reviewState,
    this.dueAt,
    required this.intervalDays,
    required this.easeFactor,
    required this.repetitions,
    required this.lapses,
    this.lastReviewedAt,
    required this.searchText,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || topic != null) {
      map['topic'] = Variable<String>(topic);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['difficulty'] = Variable<int>(difficulty);
    map['bookmarked'] = Variable<bool>(bookmarked);
    map['favorite'] = Variable<bool>(favorite);
    map['review_state'] = Variable<int>(reviewState);
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<DateTime>(dueAt);
    }
    map['interval_days'] = Variable<int>(intervalDays);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['repetitions'] = Variable<int>(repetitions);
    map['lapses'] = Variable<int>(lapses);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    map['search_text'] = Variable<String>(searchText);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FlashcardsCompanion toCompanion(bool nullToAbsent) {
    return FlashcardsCompanion(
      id: Value(id),
      deckId: Value(deckId),
      front: Value(front),
      back: Value(back),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      topic: topic == null && nullToAbsent
          ? const Value.absent()
          : Value(topic),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      difficulty: Value(difficulty),
      bookmarked: Value(bookmarked),
      favorite: Value(favorite),
      reviewState: Value(reviewState),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      intervalDays: Value(intervalDays),
      easeFactor: Value(easeFactor),
      repetitions: Value(repetitions),
      lapses: Value(lapses),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      searchText: Value(searchText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory FlashcardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlashcardRow(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      front: serializer.fromJson<String>(json['front']),
      back: serializer.fromJson<String>(json['back']),
      subject: serializer.fromJson<String?>(json['subject']),
      topic: serializer.fromJson<String?>(json['topic']),
      tags: serializer.fromJson<String?>(json['tags']),
      notes: serializer.fromJson<String?>(json['notes']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      bookmarked: serializer.fromJson<bool>(json['bookmarked']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      reviewState: serializer.fromJson<int>(json['reviewState']),
      dueAt: serializer.fromJson<DateTime?>(json['dueAt']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      lapses: serializer.fromJson<int>(json['lapses']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      searchText: serializer.fromJson<String>(json['searchText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'front': serializer.toJson<String>(front),
      'back': serializer.toJson<String>(back),
      'subject': serializer.toJson<String?>(subject),
      'topic': serializer.toJson<String?>(topic),
      'tags': serializer.toJson<String?>(tags),
      'notes': serializer.toJson<String?>(notes),
      'difficulty': serializer.toJson<int>(difficulty),
      'bookmarked': serializer.toJson<bool>(bookmarked),
      'favorite': serializer.toJson<bool>(favorite),
      'reviewState': serializer.toJson<int>(reviewState),
      'dueAt': serializer.toJson<DateTime?>(dueAt),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'repetitions': serializer.toJson<int>(repetitions),
      'lapses': serializer.toJson<int>(lapses),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'searchText': serializer.toJson<String>(searchText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FlashcardRow copyWith({
    String? id,
    String? deckId,
    String? front,
    String? back,
    Value<String?> subject = const Value.absent(),
    Value<String?> topic = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    int? difficulty,
    bool? bookmarked,
    bool? favorite,
    int? reviewState,
    Value<DateTime?> dueAt = const Value.absent(),
    int? intervalDays,
    double? easeFactor,
    int? repetitions,
    int? lapses,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    String? searchText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => FlashcardRow(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    front: front ?? this.front,
    back: back ?? this.back,
    subject: subject.present ? subject.value : this.subject,
    topic: topic.present ? topic.value : this.topic,
    tags: tags.present ? tags.value : this.tags,
    notes: notes.present ? notes.value : this.notes,
    difficulty: difficulty ?? this.difficulty,
    bookmarked: bookmarked ?? this.bookmarked,
    favorite: favorite ?? this.favorite,
    reviewState: reviewState ?? this.reviewState,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    intervalDays: intervalDays ?? this.intervalDays,
    easeFactor: easeFactor ?? this.easeFactor,
    repetitions: repetitions ?? this.repetitions,
    lapses: lapses ?? this.lapses,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    searchText: searchText ?? this.searchText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  FlashcardRow copyWithCompanion(FlashcardsCompanion data) {
    return FlashcardRow(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      subject: data.subject.present ? data.subject.value : this.subject,
      topic: data.topic.present ? data.topic.value : this.topic,
      tags: data.tags.present ? data.tags.value : this.tags,
      notes: data.notes.present ? data.notes.value : this.notes,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      bookmarked: data.bookmarked.present
          ? data.bookmarked.value
          : this.bookmarked,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      reviewState: data.reviewState.present
          ? data.reviewState.value
          : this.reviewState,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardRow(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('tags: $tags, ')
          ..write('notes: $notes, ')
          ..write('difficulty: $difficulty, ')
          ..write('bookmarked: $bookmarked, ')
          ..write('favorite: $favorite, ')
          ..write('reviewState: $reviewState, ')
          ..write('dueAt: $dueAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('searchText: $searchText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    deckId,
    front,
    back,
    subject,
    topic,
    tags,
    notes,
    difficulty,
    bookmarked,
    favorite,
    reviewState,
    dueAt,
    intervalDays,
    easeFactor,
    repetitions,
    lapses,
    lastReviewedAt,
    searchText,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlashcardRow &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.front == this.front &&
          other.back == this.back &&
          other.subject == this.subject &&
          other.topic == this.topic &&
          other.tags == this.tags &&
          other.notes == this.notes &&
          other.difficulty == this.difficulty &&
          other.bookmarked == this.bookmarked &&
          other.favorite == this.favorite &&
          other.reviewState == this.reviewState &&
          other.dueAt == this.dueAt &&
          other.intervalDays == this.intervalDays &&
          other.easeFactor == this.easeFactor &&
          other.repetitions == this.repetitions &&
          other.lapses == this.lapses &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.searchText == this.searchText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FlashcardsCompanion extends UpdateCompanion<FlashcardRow> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> front;
  final Value<String> back;
  final Value<String?> subject;
  final Value<String?> topic;
  final Value<String?> tags;
  final Value<String?> notes;
  final Value<int> difficulty;
  final Value<bool> bookmarked;
  final Value<bool> favorite;
  final Value<int> reviewState;
  final Value<DateTime?> dueAt;
  final Value<int> intervalDays;
  final Value<double> easeFactor;
  final Value<int> repetitions;
  final Value<int> lapses;
  final Value<DateTime?> lastReviewedAt;
  final Value<String> searchText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FlashcardsCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.tags = const Value.absent(),
    this.notes = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.bookmarked = const Value.absent(),
    this.favorite = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.searchText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlashcardsCompanion.insert({
    required String id,
    required String deckId,
    required String front,
    required String back,
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.tags = const Value.absent(),
    this.notes = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.bookmarked = const Value.absent(),
    this.favorite = const Value.absent(),
    this.reviewState = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.lapses = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.searchText = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       front = Value(front),
       back = Value(back),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<FlashcardRow> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? front,
    Expression<String>? back,
    Expression<String>? subject,
    Expression<String>? topic,
    Expression<String>? tags,
    Expression<String>? notes,
    Expression<int>? difficulty,
    Expression<bool>? bookmarked,
    Expression<bool>? favorite,
    Expression<int>? reviewState,
    Expression<DateTime>? dueAt,
    Expression<int>? intervalDays,
    Expression<double>? easeFactor,
    Expression<int>? repetitions,
    Expression<int>? lapses,
    Expression<DateTime>? lastReviewedAt,
    Expression<String>? searchText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (subject != null) 'subject': subject,
      if (topic != null) 'topic': topic,
      if (tags != null) 'tags': tags,
      if (notes != null) 'notes': notes,
      if (difficulty != null) 'difficulty': difficulty,
      if (bookmarked != null) 'bookmarked': bookmarked,
      if (favorite != null) 'favorite': favorite,
      if (reviewState != null) 'review_state': reviewState,
      if (dueAt != null) 'due_at': dueAt,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (repetitions != null) 'repetitions': repetitions,
      if (lapses != null) 'lapses': lapses,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (searchText != null) 'search_text': searchText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlashcardsCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? front,
    Value<String>? back,
    Value<String?>? subject,
    Value<String?>? topic,
    Value<String?>? tags,
    Value<String?>? notes,
    Value<int>? difficulty,
    Value<bool>? bookmarked,
    Value<bool>? favorite,
    Value<int>? reviewState,
    Value<DateTime?>? dueAt,
    Value<int>? intervalDays,
    Value<double>? easeFactor,
    Value<int>? repetitions,
    Value<int>? lapses,
    Value<DateTime?>? lastReviewedAt,
    Value<String>? searchText,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FlashcardsCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      front: front ?? this.front,
      back: back ?? this.back,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      difficulty: difficulty ?? this.difficulty,
      bookmarked: bookmarked ?? this.bookmarked,
      favorite: favorite ?? this.favorite,
      reviewState: reviewState ?? this.reviewState,
      dueAt: dueAt ?? this.dueAt,
      intervalDays: intervalDays ?? this.intervalDays,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      lapses: lapses ?? this.lapses,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      searchText: searchText ?? this.searchText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (bookmarked.present) {
      map['bookmarked'] = Variable<bool>(bookmarked.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (reviewState.present) {
      map['review_state'] = Variable<int>(reviewState.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<DateTime>(dueAt.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardsCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('tags: $tags, ')
          ..write('notes: $notes, ')
          ..write('difficulty: $difficulty, ')
          ..write('bookmarked: $bookmarked, ')
          ..write('favorite: $favorite, ')
          ..write('reviewState: $reviewState, ')
          ..write('dueAt: $dueAt, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('repetitions: $repetitions, ')
          ..write('lapses: $lapses, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('searchText: $searchText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewLogsTable extends ReviewLogs
    with TableInfo<$ReviewLogsTable, ReviewLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    deckId,
    rating,
    day,
    reviewedAt,
    durationMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
    );
  }

  @override
  $ReviewLogsTable createAlias(String alias) {
    return $ReviewLogsTable(attachedDatabase, alias);
  }
}

class ReviewLogRow extends DataClass implements Insertable<ReviewLogRow> {
  final String id;
  final String cardId;
  final String deckId;

  /// 0 = again, 1 = hard, 2 = good, 3 = easy (mirrors CardRating.index).
  final int rating;
  final String day;
  final DateTime reviewedAt;
  final int durationMs;
  const ReviewLogRow({
    required this.id,
    required this.cardId,
    required this.deckId,
    required this.rating,
    required this.day,
    required this.reviewedAt,
    required this.durationMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['card_id'] = Variable<String>(cardId);
    map['deck_id'] = Variable<String>(deckId);
    map['rating'] = Variable<int>(rating);
    map['day'] = Variable<String>(day);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['duration_ms'] = Variable<int>(durationMs);
    return map;
  }

  ReviewLogsCompanion toCompanion(bool nullToAbsent) {
    return ReviewLogsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      deckId: Value(deckId),
      rating: Value(rating),
      day: Value(day),
      reviewedAt: Value(reviewedAt),
      durationMs: Value(durationMs),
    );
  }

  factory ReviewLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewLogRow(
      id: serializer.fromJson<String>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      deckId: serializer.fromJson<String>(json['deckId']),
      rating: serializer.fromJson<int>(json['rating']),
      day: serializer.fromJson<String>(json['day']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cardId': serializer.toJson<String>(cardId),
      'deckId': serializer.toJson<String>(deckId),
      'rating': serializer.toJson<int>(rating),
      'day': serializer.toJson<String>(day),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'durationMs': serializer.toJson<int>(durationMs),
    };
  }

  ReviewLogRow copyWith({
    String? id,
    String? cardId,
    String? deckId,
    int? rating,
    String? day,
    DateTime? reviewedAt,
    int? durationMs,
  }) => ReviewLogRow(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    deckId: deckId ?? this.deckId,
    rating: rating ?? this.rating,
    day: day ?? this.day,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    durationMs: durationMs ?? this.durationMs,
  );
  ReviewLogRow copyWithCompanion(ReviewLogsCompanion data) {
    return ReviewLogRow(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      rating: data.rating.present ? data.rating.value : this.rating,
      day: data.day.present ? data.day.value : this.day,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogRow(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('deckId: $deckId, ')
          ..write('rating: $rating, ')
          ..write('day: $day, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, cardId, deckId, rating, day, reviewedAt, durationMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewLogRow &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.deckId == this.deckId &&
          other.rating == this.rating &&
          other.day == this.day &&
          other.reviewedAt == this.reviewedAt &&
          other.durationMs == this.durationMs);
}

class ReviewLogsCompanion extends UpdateCompanion<ReviewLogRow> {
  final Value<String> id;
  final Value<String> cardId;
  final Value<String> deckId;
  final Value<int> rating;
  final Value<String> day;
  final Value<DateTime> reviewedAt;
  final Value<int> durationMs;
  final Value<int> rowid;
  const ReviewLogsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.deckId = const Value.absent(),
    this.rating = const Value.absent(),
    this.day = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewLogsCompanion.insert({
    required String id,
    required String cardId,
    required String deckId,
    required int rating,
    required String day,
    required DateTime reviewedAt,
    this.durationMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cardId = Value(cardId),
       deckId = Value(deckId),
       rating = Value(rating),
       day = Value(day),
       reviewedAt = Value(reviewedAt);
  static Insertable<ReviewLogRow> custom({
    Expression<String>? id,
    Expression<String>? cardId,
    Expression<String>? deckId,
    Expression<int>? rating,
    Expression<String>? day,
    Expression<DateTime>? reviewedAt,
    Expression<int>? durationMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (deckId != null) 'deck_id': deckId,
      if (rating != null) 'rating': rating,
      if (day != null) 'day': day,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? cardId,
    Value<String>? deckId,
    Value<int>? rating,
    Value<String>? day,
    Value<DateTime>? reviewedAt,
    Value<int>? durationMs,
    Value<int>? rowid,
  }) {
    return ReviewLogsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      deckId: deckId ?? this.deckId,
      rating: rating ?? this.rating,
      day: day ?? this.day,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      durationMs: durationMs ?? this.durationMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewLogsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('deckId: $deckId, ')
          ..write('rating: $rating, ')
          ..write('day: $day, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuizBanksTable extends QuizBanks
    with TableInfo<$QuizBanksTable, QuizBankRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizBanksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    subject,
    topic,
    description,
    color,
    tags,
    version,
    source,
    externalId,
    subjectId,
    topicId,
    orderIndex,
    archived,
    searchText,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_banks';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizBankRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuizBankRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizBankRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      ),
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuizBanksTable createAlias(String alias) {
    return $QuizBanksTable(attachedDatabase, alias);
  }
}

class QuizBankRow extends DataClass implements Insertable<QuizBankRow> {
  final String id;
  final String name;
  final String? subject;
  final String? topic;
  final String? description;

  /// Optional bank-specific ARGB colour (else the subject colour is used).
  final int? color;

  /// Comma-separated free-text tags.
  final String? tags;

  /// Content version string (e.g. "1.0") carried from the source pack.
  final String? version;

  /// Provenance of the bank: 'manual' | 'local_json' | 'admin' | 'cloud'.
  final String source;

  /// Stable id from the external source, for merge/replace deduplication.
  final String? externalId;

  /// Links into the Subject → Topic hierarchy (v0.9.1). Nullable for banks not
  /// yet filed under a subject/topic. Managed by the Admin CMS / demo seeder.
  final String? subjectId;
  final String? topicId;
  final int orderIndex;
  final bool archived;
  final String searchText;
  final DateTime createdAt;
  final DateTime updatedAt;
  const QuizBankRow({
    required this.id,
    required this.name,
    this.subject,
    this.topic,
    this.description,
    this.color,
    this.tags,
    this.version,
    required this.source,
    this.externalId,
    this.subjectId,
    this.topicId,
    required this.orderIndex,
    required this.archived,
    required this.searchText,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || topic != null) {
      map['topic'] = Variable<String>(topic);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<String>(topicId);
    }
    map['order_index'] = Variable<int>(orderIndex);
    map['archived'] = Variable<bool>(archived);
    map['search_text'] = Variable<String>(searchText);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuizBanksCompanion toCompanion(bool nullToAbsent) {
    return QuizBanksCompanion(
      id: Value(id),
      name: Value(name),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      topic: topic == null && nullToAbsent
          ? const Value.absent()
          : Value(topic),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      source: Value(source),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      orderIndex: Value(orderIndex),
      archived: Value(archived),
      searchText: Value(searchText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuizBankRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizBankRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      subject: serializer.fromJson<String?>(json['subject']),
      topic: serializer.fromJson<String?>(json['topic']),
      description: serializer.fromJson<String?>(json['description']),
      color: serializer.fromJson<int?>(json['color']),
      tags: serializer.fromJson<String?>(json['tags']),
      version: serializer.fromJson<String?>(json['version']),
      source: serializer.fromJson<String>(json['source']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      subjectId: serializer.fromJson<String?>(json['subjectId']),
      topicId: serializer.fromJson<String?>(json['topicId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      archived: serializer.fromJson<bool>(json['archived']),
      searchText: serializer.fromJson<String>(json['searchText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'subject': serializer.toJson<String?>(subject),
      'topic': serializer.toJson<String?>(topic),
      'description': serializer.toJson<String?>(description),
      'color': serializer.toJson<int?>(color),
      'tags': serializer.toJson<String?>(tags),
      'version': serializer.toJson<String?>(version),
      'source': serializer.toJson<String>(source),
      'externalId': serializer.toJson<String?>(externalId),
      'subjectId': serializer.toJson<String?>(subjectId),
      'topicId': serializer.toJson<String?>(topicId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'archived': serializer.toJson<bool>(archived),
      'searchText': serializer.toJson<String>(searchText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QuizBankRow copyWith({
    String? id,
    String? name,
    Value<String?> subject = const Value.absent(),
    Value<String?> topic = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<int?> color = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<String?> version = const Value.absent(),
    String? source,
    Value<String?> externalId = const Value.absent(),
    Value<String?> subjectId = const Value.absent(),
    Value<String?> topicId = const Value.absent(),
    int? orderIndex,
    bool? archived,
    String? searchText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => QuizBankRow(
    id: id ?? this.id,
    name: name ?? this.name,
    subject: subject.present ? subject.value : this.subject,
    topic: topic.present ? topic.value : this.topic,
    description: description.present ? description.value : this.description,
    color: color.present ? color.value : this.color,
    tags: tags.present ? tags.value : this.tags,
    version: version.present ? version.value : this.version,
    source: source ?? this.source,
    externalId: externalId.present ? externalId.value : this.externalId,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    topicId: topicId.present ? topicId.value : this.topicId,
    orderIndex: orderIndex ?? this.orderIndex,
    archived: archived ?? this.archived,
    searchText: searchText ?? this.searchText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QuizBankRow copyWithCompanion(QuizBanksCompanion data) {
    return QuizBankRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      subject: data.subject.present ? data.subject.value : this.subject,
      topic: data.topic.present ? data.topic.value : this.topic,
      description: data.description.present
          ? data.description.value
          : this.description,
      color: data.color.present ? data.color.value : this.color,
      tags: data.tags.present ? data.tags.value : this.tags,
      version: data.version.present ? data.version.value : this.version,
      source: data.source.present ? data.source.value : this.source,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      archived: data.archived.present ? data.archived.value : this.archived,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizBankRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('tags: $tags, ')
          ..write('version: $version, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('subjectId: $subjectId, ')
          ..write('topicId: $topicId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('archived: $archived, ')
          ..write('searchText: $searchText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    subject,
    topic,
    description,
    color,
    tags,
    version,
    source,
    externalId,
    subjectId,
    topicId,
    orderIndex,
    archived,
    searchText,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizBankRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.subject == this.subject &&
          other.topic == this.topic &&
          other.description == this.description &&
          other.color == this.color &&
          other.tags == this.tags &&
          other.version == this.version &&
          other.source == this.source &&
          other.externalId == this.externalId &&
          other.subjectId == this.subjectId &&
          other.topicId == this.topicId &&
          other.orderIndex == this.orderIndex &&
          other.archived == this.archived &&
          other.searchText == this.searchText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QuizBanksCompanion extends UpdateCompanion<QuizBankRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> subject;
  final Value<String?> topic;
  final Value<String?> description;
  final Value<int?> color;
  final Value<String?> tags;
  final Value<String?> version;
  final Value<String> source;
  final Value<String?> externalId;
  final Value<String?> subjectId;
  final Value<String?> topicId;
  final Value<int> orderIndex;
  final Value<bool> archived;
  final Value<String> searchText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QuizBanksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.tags = const Value.absent(),
    this.version = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.archived = const Value.absent(),
    this.searchText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizBanksCompanion.insert({
    required String id,
    required String name,
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.description = const Value.absent(),
    this.color = const Value.absent(),
    this.tags = const Value.absent(),
    this.version = const Value.absent(),
    this.source = const Value.absent(),
    this.externalId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.archived = const Value.absent(),
    this.searchText = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<QuizBankRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? subject,
    Expression<String>? topic,
    Expression<String>? description,
    Expression<int>? color,
    Expression<String>? tags,
    Expression<String>? version,
    Expression<String>? source,
    Expression<String>? externalId,
    Expression<String>? subjectId,
    Expression<String>? topicId,
    Expression<int>? orderIndex,
    Expression<bool>? archived,
    Expression<String>? searchText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (subject != null) 'subject': subject,
      if (topic != null) 'topic': topic,
      if (description != null) 'description': description,
      if (color != null) 'color': color,
      if (tags != null) 'tags': tags,
      if (version != null) 'version': version,
      if (source != null) 'source': source,
      if (externalId != null) 'external_id': externalId,
      if (subjectId != null) 'subject_id': subjectId,
      if (topicId != null) 'topic_id': topicId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (archived != null) 'archived': archived,
      if (searchText != null) 'search_text': searchText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizBanksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? subject,
    Value<String?>? topic,
    Value<String?>? description,
    Value<int?>? color,
    Value<String?>? tags,
    Value<String?>? version,
    Value<String>? source,
    Value<String?>? externalId,
    Value<String?>? subjectId,
    Value<String?>? topicId,
    Value<int>? orderIndex,
    Value<bool>? archived,
    Value<String>? searchText,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return QuizBanksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      description: description ?? this.description,
      color: color ?? this.color,
      tags: tags ?? this.tags,
      version: version ?? this.version,
      source: source ?? this.source,
      externalId: externalId ?? this.externalId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      orderIndex: orderIndex ?? this.orderIndex,
      archived: archived ?? this.archived,
      searchText: searchText ?? this.searchText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizBanksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('description: $description, ')
          ..write('color: $color, ')
          ..write('tags: $tags, ')
          ..write('version: $version, ')
          ..write('source: $source, ')
          ..write('externalId: $externalId, ')
          ..write('subjectId: $subjectId, ')
          ..write('topicId: $topicId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('archived: $archived, ')
          ..write('searchText: $searchText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuizQuestionsTable extends QuizQuestions
    with TableInfo<$QuizQuestionsTable, QuizQuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankIdMeta = const VerificationMeta('bankId');
  @override
  late final GeneratedColumn<String> bankId = GeneratedColumn<String>(
    'bank_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _optionsJsonMeta = const VerificationMeta(
    'optionsJson',
  );
  @override
  late final GeneratedColumn<String> optionsJson = GeneratedColumn<String>(
    'options_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _answerJsonMeta = const VerificationMeta(
    'answerJson',
  );
  @override
  late final GeneratedColumn<String> answerJson = GeneratedColumn<String>(
    'answer_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bookmarkedMeta = const VerificationMeta(
    'bookmarked',
  );
  @override
  late final GeneratedColumn<bool> bookmarked = GeneratedColumn<bool>(
    'bookmarked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bookmarked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bankId,
    type,
    prompt,
    optionsJson,
    answerJson,
    explanation,
    subject,
    topic,
    tags,
    difficulty,
    bookmarked,
    externalId,
    subjectId,
    topicId,
    searchText,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizQuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bank_id')) {
      context.handle(
        _bankIdMeta,
        bankId.isAcceptableOrUnknown(data['bank_id']!, _bankIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bankIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('options_json')) {
      context.handle(
        _optionsJsonMeta,
        optionsJson.isAcceptableOrUnknown(
          data['options_json']!,
          _optionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('answer_json')) {
      context.handle(
        _answerJsonMeta,
        answerJson.isAcceptableOrUnknown(data['answer_json']!, _answerJsonMeta),
      );
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('bookmarked')) {
      context.handle(
        _bookmarkedMeta,
        bookmarked.isAcceptableOrUnknown(data['bookmarked']!, _bookmarkedMeta),
      );
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuizQuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizQuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bankId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      optionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}options_json'],
      ),
      answerJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer_json'],
      ),
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      ),
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      )!,
      bookmarked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bookmarked'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      ),
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      ),
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      ),
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuizQuestionsTable createAlias(String alias) {
    return $QuizQuestionsTable(attachedDatabase, alias);
  }
}

class QuizQuestionRow extends DataClass implements Insertable<QuizQuestionRow> {
  final String id;
  final String bankId;

  /// Mirrors QuestionType.index: 0 mcqSingle, 1 trueFalse, 2 fillBlank,
  /// 3 matching (reserved), 4 multiCorrect (reserved).
  final int type;

  /// The question stem / prompt (free text, markdown-ready).
  final String prompt;

  /// JSON array of option strings (MCQ/matching). Null for True/False & Blank.
  final String? optionsJson;

  /// JSON-encoded correct answer, shape depends on [type]:
  /// mcqSingle → int index; trueFalse → bool; fillBlank → [accepted strings];
  /// multiCorrect → [indices]; matching → {left: right}.
  final String? answerJson;
  final String? explanation;

  /// Denormalised (from the bank/pack) for fast filtering & subject analytics.
  final String? subject;
  final String? topic;
  final String? tags;

  /// 0 = none, 1 = easy, 2 = medium, 3 = hard (mirrors QuizDifficulty.index).
  final int difficulty;
  final bool bookmarked;

  /// Stable id from the external source, for merge/replace deduplication.
  final String? externalId;

  /// Links into the Subject → Topic hierarchy (v0.9.1); denormalised for fast
  /// per-subject/topic filtering and analytics.
  final String? subjectId;
  final String? topicId;
  final String searchText;
  final DateTime createdAt;
  final DateTime updatedAt;
  const QuizQuestionRow({
    required this.id,
    required this.bankId,
    required this.type,
    required this.prompt,
    this.optionsJson,
    this.answerJson,
    this.explanation,
    this.subject,
    this.topic,
    this.tags,
    required this.difficulty,
    required this.bookmarked,
    this.externalId,
    this.subjectId,
    this.topicId,
    required this.searchText,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['bank_id'] = Variable<String>(bankId);
    map['type'] = Variable<int>(type);
    map['prompt'] = Variable<String>(prompt);
    if (!nullToAbsent || optionsJson != null) {
      map['options_json'] = Variable<String>(optionsJson);
    }
    if (!nullToAbsent || answerJson != null) {
      map['answer_json'] = Variable<String>(answerJson);
    }
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || topic != null) {
      map['topic'] = Variable<String>(topic);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['difficulty'] = Variable<int>(difficulty);
    map['bookmarked'] = Variable<bool>(bookmarked);
    if (!nullToAbsent || externalId != null) {
      map['external_id'] = Variable<String>(externalId);
    }
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<String>(subjectId);
    }
    if (!nullToAbsent || topicId != null) {
      map['topic_id'] = Variable<String>(topicId);
    }
    map['search_text'] = Variable<String>(searchText);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuizQuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuizQuestionsCompanion(
      id: Value(id),
      bankId: Value(bankId),
      type: Value(type),
      prompt: Value(prompt),
      optionsJson: optionsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(optionsJson),
      answerJson: answerJson == null && nullToAbsent
          ? const Value.absent()
          : Value(answerJson),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      topic: topic == null && nullToAbsent
          ? const Value.absent()
          : Value(topic),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      difficulty: Value(difficulty),
      bookmarked: Value(bookmarked),
      externalId: externalId == null && nullToAbsent
          ? const Value.absent()
          : Value(externalId),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      topicId: topicId == null && nullToAbsent
          ? const Value.absent()
          : Value(topicId),
      searchText: Value(searchText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuizQuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizQuestionRow(
      id: serializer.fromJson<String>(json['id']),
      bankId: serializer.fromJson<String>(json['bankId']),
      type: serializer.fromJson<int>(json['type']),
      prompt: serializer.fromJson<String>(json['prompt']),
      optionsJson: serializer.fromJson<String?>(json['optionsJson']),
      answerJson: serializer.fromJson<String?>(json['answerJson']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      subject: serializer.fromJson<String?>(json['subject']),
      topic: serializer.fromJson<String?>(json['topic']),
      tags: serializer.fromJson<String?>(json['tags']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      bookmarked: serializer.fromJson<bool>(json['bookmarked']),
      externalId: serializer.fromJson<String?>(json['externalId']),
      subjectId: serializer.fromJson<String?>(json['subjectId']),
      topicId: serializer.fromJson<String?>(json['topicId']),
      searchText: serializer.fromJson<String>(json['searchText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bankId': serializer.toJson<String>(bankId),
      'type': serializer.toJson<int>(type),
      'prompt': serializer.toJson<String>(prompt),
      'optionsJson': serializer.toJson<String?>(optionsJson),
      'answerJson': serializer.toJson<String?>(answerJson),
      'explanation': serializer.toJson<String?>(explanation),
      'subject': serializer.toJson<String?>(subject),
      'topic': serializer.toJson<String?>(topic),
      'tags': serializer.toJson<String?>(tags),
      'difficulty': serializer.toJson<int>(difficulty),
      'bookmarked': serializer.toJson<bool>(bookmarked),
      'externalId': serializer.toJson<String?>(externalId),
      'subjectId': serializer.toJson<String?>(subjectId),
      'topicId': serializer.toJson<String?>(topicId),
      'searchText': serializer.toJson<String>(searchText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QuizQuestionRow copyWith({
    String? id,
    String? bankId,
    int? type,
    String? prompt,
    Value<String?> optionsJson = const Value.absent(),
    Value<String?> answerJson = const Value.absent(),
    Value<String?> explanation = const Value.absent(),
    Value<String?> subject = const Value.absent(),
    Value<String?> topic = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    int? difficulty,
    bool? bookmarked,
    Value<String?> externalId = const Value.absent(),
    Value<String?> subjectId = const Value.absent(),
    Value<String?> topicId = const Value.absent(),
    String? searchText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => QuizQuestionRow(
    id: id ?? this.id,
    bankId: bankId ?? this.bankId,
    type: type ?? this.type,
    prompt: prompt ?? this.prompt,
    optionsJson: optionsJson.present ? optionsJson.value : this.optionsJson,
    answerJson: answerJson.present ? answerJson.value : this.answerJson,
    explanation: explanation.present ? explanation.value : this.explanation,
    subject: subject.present ? subject.value : this.subject,
    topic: topic.present ? topic.value : this.topic,
    tags: tags.present ? tags.value : this.tags,
    difficulty: difficulty ?? this.difficulty,
    bookmarked: bookmarked ?? this.bookmarked,
    externalId: externalId.present ? externalId.value : this.externalId,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    topicId: topicId.present ? topicId.value : this.topicId,
    searchText: searchText ?? this.searchText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QuizQuestionRow copyWithCompanion(QuizQuestionsCompanion data) {
    return QuizQuestionRow(
      id: data.id.present ? data.id.value : this.id,
      bankId: data.bankId.present ? data.bankId.value : this.bankId,
      type: data.type.present ? data.type.value : this.type,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      optionsJson: data.optionsJson.present
          ? data.optionsJson.value
          : this.optionsJson,
      answerJson: data.answerJson.present
          ? data.answerJson.value
          : this.answerJson,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      subject: data.subject.present ? data.subject.value : this.subject,
      topic: data.topic.present ? data.topic.value : this.topic,
      tags: data.tags.present ? data.tags.value : this.tags,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      bookmarked: data.bookmarked.present
          ? data.bookmarked.value
          : this.bookmarked,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizQuestionRow(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('type: $type, ')
          ..write('prompt: $prompt, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('answerJson: $answerJson, ')
          ..write('explanation: $explanation, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('tags: $tags, ')
          ..write('difficulty: $difficulty, ')
          ..write('bookmarked: $bookmarked, ')
          ..write('externalId: $externalId, ')
          ..write('subjectId: $subjectId, ')
          ..write('topicId: $topicId, ')
          ..write('searchText: $searchText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bankId,
    type,
    prompt,
    optionsJson,
    answerJson,
    explanation,
    subject,
    topic,
    tags,
    difficulty,
    bookmarked,
    externalId,
    subjectId,
    topicId,
    searchText,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizQuestionRow &&
          other.id == this.id &&
          other.bankId == this.bankId &&
          other.type == this.type &&
          other.prompt == this.prompt &&
          other.optionsJson == this.optionsJson &&
          other.answerJson == this.answerJson &&
          other.explanation == this.explanation &&
          other.subject == this.subject &&
          other.topic == this.topic &&
          other.tags == this.tags &&
          other.difficulty == this.difficulty &&
          other.bookmarked == this.bookmarked &&
          other.externalId == this.externalId &&
          other.subjectId == this.subjectId &&
          other.topicId == this.topicId &&
          other.searchText == this.searchText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QuizQuestionsCompanion extends UpdateCompanion<QuizQuestionRow> {
  final Value<String> id;
  final Value<String> bankId;
  final Value<int> type;
  final Value<String> prompt;
  final Value<String?> optionsJson;
  final Value<String?> answerJson;
  final Value<String?> explanation;
  final Value<String?> subject;
  final Value<String?> topic;
  final Value<String?> tags;
  final Value<int> difficulty;
  final Value<bool> bookmarked;
  final Value<String?> externalId;
  final Value<String?> subjectId;
  final Value<String?> topicId;
  final Value<String> searchText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QuizQuestionsCompanion({
    this.id = const Value.absent(),
    this.bankId = const Value.absent(),
    this.type = const Value.absent(),
    this.prompt = const Value.absent(),
    this.optionsJson = const Value.absent(),
    this.answerJson = const Value.absent(),
    this.explanation = const Value.absent(),
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.tags = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.bookmarked = const Value.absent(),
    this.externalId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.searchText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizQuestionsCompanion.insert({
    required String id,
    required String bankId,
    this.type = const Value.absent(),
    required String prompt,
    this.optionsJson = const Value.absent(),
    this.answerJson = const Value.absent(),
    this.explanation = const Value.absent(),
    this.subject = const Value.absent(),
    this.topic = const Value.absent(),
    this.tags = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.bookmarked = const Value.absent(),
    this.externalId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.topicId = const Value.absent(),
    this.searchText = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       bankId = Value(bankId),
       prompt = Value(prompt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<QuizQuestionRow> custom({
    Expression<String>? id,
    Expression<String>? bankId,
    Expression<int>? type,
    Expression<String>? prompt,
    Expression<String>? optionsJson,
    Expression<String>? answerJson,
    Expression<String>? explanation,
    Expression<String>? subject,
    Expression<String>? topic,
    Expression<String>? tags,
    Expression<int>? difficulty,
    Expression<bool>? bookmarked,
    Expression<String>? externalId,
    Expression<String>? subjectId,
    Expression<String>? topicId,
    Expression<String>? searchText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bankId != null) 'bank_id': bankId,
      if (type != null) 'type': type,
      if (prompt != null) 'prompt': prompt,
      if (optionsJson != null) 'options_json': optionsJson,
      if (answerJson != null) 'answer_json': answerJson,
      if (explanation != null) 'explanation': explanation,
      if (subject != null) 'subject': subject,
      if (topic != null) 'topic': topic,
      if (tags != null) 'tags': tags,
      if (difficulty != null) 'difficulty': difficulty,
      if (bookmarked != null) 'bookmarked': bookmarked,
      if (externalId != null) 'external_id': externalId,
      if (subjectId != null) 'subject_id': subjectId,
      if (topicId != null) 'topic_id': topicId,
      if (searchText != null) 'search_text': searchText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizQuestionsCompanion copyWith({
    Value<String>? id,
    Value<String>? bankId,
    Value<int>? type,
    Value<String>? prompt,
    Value<String?>? optionsJson,
    Value<String?>? answerJson,
    Value<String?>? explanation,
    Value<String?>? subject,
    Value<String?>? topic,
    Value<String?>? tags,
    Value<int>? difficulty,
    Value<bool>? bookmarked,
    Value<String?>? externalId,
    Value<String?>? subjectId,
    Value<String?>? topicId,
    Value<String>? searchText,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return QuizQuestionsCompanion(
      id: id ?? this.id,
      bankId: bankId ?? this.bankId,
      type: type ?? this.type,
      prompt: prompt ?? this.prompt,
      optionsJson: optionsJson ?? this.optionsJson,
      answerJson: answerJson ?? this.answerJson,
      explanation: explanation ?? this.explanation,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      bookmarked: bookmarked ?? this.bookmarked,
      externalId: externalId ?? this.externalId,
      subjectId: subjectId ?? this.subjectId,
      topicId: topicId ?? this.topicId,
      searchText: searchText ?? this.searchText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bankId.present) {
      map['bank_id'] = Variable<String>(bankId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (optionsJson.present) {
      map['options_json'] = Variable<String>(optionsJson.value);
    }
    if (answerJson.present) {
      map['answer_json'] = Variable<String>(answerJson.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (bookmarked.present) {
      map['bookmarked'] = Variable<bool>(bookmarked.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizQuestionsCompanion(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('type: $type, ')
          ..write('prompt: $prompt, ')
          ..write('optionsJson: $optionsJson, ')
          ..write('answerJson: $answerJson, ')
          ..write('explanation: $explanation, ')
          ..write('subject: $subject, ')
          ..write('topic: $topic, ')
          ..write('tags: $tags, ')
          ..write('difficulty: $difficulty, ')
          ..write('bookmarked: $bookmarked, ')
          ..write('externalId: $externalId, ')
          ..write('subjectId: $subjectId, ')
          ..write('topicId: $topicId, ')
          ..write('searchText: $searchText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuizAttemptsTable extends QuizAttempts
    with TableInfo<$QuizAttemptsTable, QuizAttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizAttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankIdMeta = const VerificationMeta('bankId');
  @override
  late final GeneratedColumn<String> bankId = GeneratedColumn<String>(
    'bank_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<int> mode = GeneratedColumn<int>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalQuestionsMeta = const VerificationMeta(
    'totalQuestions',
  );
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
    'total_questions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<int> correct = GeneratedColumn<int>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wrongMeta = const VerificationMeta('wrong');
  @override
  late final GeneratedColumn<int> wrong = GeneratedColumn<int>(
    'wrong',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<int> skipped = GeneratedColumn<int>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMeta = const VerificationMeta(
    'finishedAt',
  );
  @override
  late final GeneratedColumn<DateTime> finishedAt = GeneratedColumn<DateTime>(
    'finished_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bankId,
    mode,
    title,
    totalQuestions,
    correct,
    wrong,
    skipped,
    startedAt,
    finishedAt,
    durationMs,
    day,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizAttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bank_id')) {
      context.handle(
        _bankIdMeta,
        bankId.isAcceptableOrUnknown(data['bank_id']!, _bankIdMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('total_questions')) {
      context.handle(
        _totalQuestionsMeta,
        totalQuestions.isAcceptableOrUnknown(
          data['total_questions']!,
          _totalQuestionsMeta,
        ),
      );
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    }
    if (data.containsKey('wrong')) {
      context.handle(
        _wrongMeta,
        wrong.isAcceptableOrUnknown(data['wrong']!, _wrongMeta),
      );
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('finished_at')) {
      context.handle(
        _finishedAtMeta,
        finishedAt.isAcceptableOrUnknown(data['finished_at']!, _finishedAtMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuizAttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizAttemptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      bankId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_id'],
      ),
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mode'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      totalQuestions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_questions'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct'],
      )!,
      wrong: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wrong'],
      )!,
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      finishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}finished_at'],
      ),
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QuizAttemptsTable createAlias(String alias) {
    return $QuizAttemptsTable(attachedDatabase, alias);
  }
}

class QuizAttemptRow extends DataClass implements Insertable<QuizAttemptRow> {
  final String id;

  /// Bank studied, or null for a mixed/custom selection.
  final String? bankId;

  /// 0 = practice, 1 = exam (mirrors QuizMode.index).
  final int mode;
  final String? title;
  final int totalQuestions;
  final int correct;
  final int wrong;
  final int skipped;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int durationMs;

  /// 'YYYY-MM-DD' of completion, for daily/weekly/monthly analytics ranges.
  final String day;
  final DateTime createdAt;
  const QuizAttemptRow({
    required this.id,
    this.bankId,
    required this.mode,
    this.title,
    required this.totalQuestions,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.startedAt,
    this.finishedAt,
    required this.durationMs,
    required this.day,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || bankId != null) {
      map['bank_id'] = Variable<String>(bankId);
    }
    map['mode'] = Variable<int>(mode);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['total_questions'] = Variable<int>(totalQuestions);
    map['correct'] = Variable<int>(correct);
    map['wrong'] = Variable<int>(wrong);
    map['skipped'] = Variable<int>(skipped);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || finishedAt != null) {
      map['finished_at'] = Variable<DateTime>(finishedAt);
    }
    map['duration_ms'] = Variable<int>(durationMs);
    map['day'] = Variable<String>(day);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QuizAttemptsCompanion toCompanion(bool nullToAbsent) {
    return QuizAttemptsCompanion(
      id: Value(id),
      bankId: bankId == null && nullToAbsent
          ? const Value.absent()
          : Value(bankId),
      mode: Value(mode),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      totalQuestions: Value(totalQuestions),
      correct: Value(correct),
      wrong: Value(wrong),
      skipped: Value(skipped),
      startedAt: Value(startedAt),
      finishedAt: finishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAt),
      durationMs: Value(durationMs),
      day: Value(day),
      createdAt: Value(createdAt),
    );
  }

  factory QuizAttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizAttemptRow(
      id: serializer.fromJson<String>(json['id']),
      bankId: serializer.fromJson<String?>(json['bankId']),
      mode: serializer.fromJson<int>(json['mode']),
      title: serializer.fromJson<String?>(json['title']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      correct: serializer.fromJson<int>(json['correct']),
      wrong: serializer.fromJson<int>(json['wrong']),
      skipped: serializer.fromJson<int>(json['skipped']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      finishedAt: serializer.fromJson<DateTime?>(json['finishedAt']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      day: serializer.fromJson<String>(json['day']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bankId': serializer.toJson<String?>(bankId),
      'mode': serializer.toJson<int>(mode),
      'title': serializer.toJson<String?>(title),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'correct': serializer.toJson<int>(correct),
      'wrong': serializer.toJson<int>(wrong),
      'skipped': serializer.toJson<int>(skipped),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'finishedAt': serializer.toJson<DateTime?>(finishedAt),
      'durationMs': serializer.toJson<int>(durationMs),
      'day': serializer.toJson<String>(day),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  QuizAttemptRow copyWith({
    String? id,
    Value<String?> bankId = const Value.absent(),
    int? mode,
    Value<String?> title = const Value.absent(),
    int? totalQuestions,
    int? correct,
    int? wrong,
    int? skipped,
    DateTime? startedAt,
    Value<DateTime?> finishedAt = const Value.absent(),
    int? durationMs,
    String? day,
    DateTime? createdAt,
  }) => QuizAttemptRow(
    id: id ?? this.id,
    bankId: bankId.present ? bankId.value : this.bankId,
    mode: mode ?? this.mode,
    title: title.present ? title.value : this.title,
    totalQuestions: totalQuestions ?? this.totalQuestions,
    correct: correct ?? this.correct,
    wrong: wrong ?? this.wrong,
    skipped: skipped ?? this.skipped,
    startedAt: startedAt ?? this.startedAt,
    finishedAt: finishedAt.present ? finishedAt.value : this.finishedAt,
    durationMs: durationMs ?? this.durationMs,
    day: day ?? this.day,
    createdAt: createdAt ?? this.createdAt,
  );
  QuizAttemptRow copyWithCompanion(QuizAttemptsCompanion data) {
    return QuizAttemptRow(
      id: data.id.present ? data.id.value : this.id,
      bankId: data.bankId.present ? data.bankId.value : this.bankId,
      mode: data.mode.present ? data.mode.value : this.mode,
      title: data.title.present ? data.title.value : this.title,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      correct: data.correct.present ? data.correct.value : this.correct,
      wrong: data.wrong.present ? data.wrong.value : this.wrong,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      finishedAt: data.finishedAt.present
          ? data.finishedAt.value
          : this.finishedAt,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      day: data.day.present ? data.day.value : this.day,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizAttemptRow(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('mode: $mode, ')
          ..write('title: $title, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correct: $correct, ')
          ..write('wrong: $wrong, ')
          ..write('skipped: $skipped, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bankId,
    mode,
    title,
    totalQuestions,
    correct,
    wrong,
    skipped,
    startedAt,
    finishedAt,
    durationMs,
    day,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizAttemptRow &&
          other.id == this.id &&
          other.bankId == this.bankId &&
          other.mode == this.mode &&
          other.title == this.title &&
          other.totalQuestions == this.totalQuestions &&
          other.correct == this.correct &&
          other.wrong == this.wrong &&
          other.skipped == this.skipped &&
          other.startedAt == this.startedAt &&
          other.finishedAt == this.finishedAt &&
          other.durationMs == this.durationMs &&
          other.day == this.day &&
          other.createdAt == this.createdAt);
}

class QuizAttemptsCompanion extends UpdateCompanion<QuizAttemptRow> {
  final Value<String> id;
  final Value<String?> bankId;
  final Value<int> mode;
  final Value<String?> title;
  final Value<int> totalQuestions;
  final Value<int> correct;
  final Value<int> wrong;
  final Value<int> skipped;
  final Value<DateTime> startedAt;
  final Value<DateTime?> finishedAt;
  final Value<int> durationMs;
  final Value<String> day;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const QuizAttemptsCompanion({
    this.id = const Value.absent(),
    this.bankId = const Value.absent(),
    this.mode = const Value.absent(),
    this.title = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.correct = const Value.absent(),
    this.wrong = const Value.absent(),
    this.skipped = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.finishedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.day = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizAttemptsCompanion.insert({
    required String id,
    this.bankId = const Value.absent(),
    this.mode = const Value.absent(),
    this.title = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.correct = const Value.absent(),
    this.wrong = const Value.absent(),
    this.skipped = const Value.absent(),
    required DateTime startedAt,
    this.finishedAt = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.day = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       startedAt = Value(startedAt),
       createdAt = Value(createdAt);
  static Insertable<QuizAttemptRow> custom({
    Expression<String>? id,
    Expression<String>? bankId,
    Expression<int>? mode,
    Expression<String>? title,
    Expression<int>? totalQuestions,
    Expression<int>? correct,
    Expression<int>? wrong,
    Expression<int>? skipped,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? finishedAt,
    Expression<int>? durationMs,
    Expression<String>? day,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bankId != null) 'bank_id': bankId,
      if (mode != null) 'mode': mode,
      if (title != null) 'title': title,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (correct != null) 'correct': correct,
      if (wrong != null) 'wrong': wrong,
      if (skipped != null) 'skipped': skipped,
      if (startedAt != null) 'started_at': startedAt,
      if (finishedAt != null) 'finished_at': finishedAt,
      if (durationMs != null) 'duration_ms': durationMs,
      if (day != null) 'day': day,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizAttemptsCompanion copyWith({
    Value<String>? id,
    Value<String?>? bankId,
    Value<int>? mode,
    Value<String?>? title,
    Value<int>? totalQuestions,
    Value<int>? correct,
    Value<int>? wrong,
    Value<int>? skipped,
    Value<DateTime>? startedAt,
    Value<DateTime?>? finishedAt,
    Value<int>? durationMs,
    Value<String>? day,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return QuizAttemptsCompanion(
      id: id ?? this.id,
      bankId: bankId ?? this.bankId,
      mode: mode ?? this.mode,
      title: title ?? this.title,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correct: correct ?? this.correct,
      wrong: wrong ?? this.wrong,
      skipped: skipped ?? this.skipped,
      startedAt: startedAt ?? this.startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      durationMs: durationMs ?? this.durationMs,
      day: day ?? this.day,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bankId.present) {
      map['bank_id'] = Variable<String>(bankId.value);
    }
    if (mode.present) {
      map['mode'] = Variable<int>(mode.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (correct.present) {
      map['correct'] = Variable<int>(correct.value);
    }
    if (wrong.present) {
      map['wrong'] = Variable<int>(wrong.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<int>(skipped.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (finishedAt.present) {
      map['finished_at'] = Variable<DateTime>(finishedAt.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizAttemptsCompanion(')
          ..write('id: $id, ')
          ..write('bankId: $bankId, ')
          ..write('mode: $mode, ')
          ..write('title: $title, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correct: $correct, ')
          ..write('wrong: $wrong, ')
          ..write('skipped: $skipped, ')
          ..write('startedAt: $startedAt, ')
          ..write('finishedAt: $finishedAt, ')
          ..write('durationMs: $durationMs, ')
          ..write('day: $day, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuizAttemptAnswersTable extends QuizAttemptAnswers
    with TableInfo<$QuizAttemptAnswersTable, QuizAnswerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizAttemptAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<String> attemptId = GeneratedColumn<String>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _givenJsonMeta = const VerificationMeta(
    'givenJson',
  );
  @override
  late final GeneratedColumn<String> givenJson = GeneratedColumn<String>(
    'given_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCorrectMeta = const VerificationMeta(
    'isCorrect',
  );
  @override
  late final GeneratedColumn<bool> isCorrect = GeneratedColumn<bool>(
    'is_correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_correct" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<bool> skipped = GeneratedColumn<bool>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("skipped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _timeMsMeta = const VerificationMeta('timeMs');
  @override
  late final GeneratedColumn<int> timeMs = GeneratedColumn<int>(
    'time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    attemptId,
    questionId,
    givenJson,
    isCorrect,
    skipped,
    subject,
    orderIndex,
    timeMs,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_attempt_answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizAnswerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('given_json')) {
      context.handle(
        _givenJsonMeta,
        givenJson.isAcceptableOrUnknown(data['given_json']!, _givenJsonMeta),
      );
    }
    if (data.containsKey('is_correct')) {
      context.handle(
        _isCorrectMeta,
        isCorrect.isAcceptableOrUnknown(data['is_correct']!, _isCorrectMeta),
      );
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('time_ms')) {
      context.handle(
        _timeMsMeta,
        timeMs.isAcceptableOrUnknown(data['time_ms']!, _timeMsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuizAnswerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizAnswerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempt_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      givenJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}given_json'],
      ),
      isCorrect: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_correct'],
      )!,
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}skipped'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      timeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_ms'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QuizAttemptAnswersTable createAlias(String alias) {
    return $QuizAttemptAnswersTable(attachedDatabase, alias);
  }
}

class QuizAnswerRow extends DataClass implements Insertable<QuizAnswerRow> {
  final String id;
  final String attemptId;
  final String questionId;

  /// JSON-encoded answer the user gave (null when skipped).
  final String? givenJson;
  final bool isCorrect;
  final bool skipped;
  final String? subject;
  final int orderIndex;
  final int timeMs;
  final DateTime createdAt;
  const QuizAnswerRow({
    required this.id,
    required this.attemptId,
    required this.questionId,
    this.givenJson,
    required this.isCorrect,
    required this.skipped,
    this.subject,
    required this.orderIndex,
    required this.timeMs,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['attempt_id'] = Variable<String>(attemptId);
    map['question_id'] = Variable<String>(questionId);
    if (!nullToAbsent || givenJson != null) {
      map['given_json'] = Variable<String>(givenJson);
    }
    map['is_correct'] = Variable<bool>(isCorrect);
    map['skipped'] = Variable<bool>(skipped);
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    map['order_index'] = Variable<int>(orderIndex);
    map['time_ms'] = Variable<int>(timeMs);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QuizAttemptAnswersCompanion toCompanion(bool nullToAbsent) {
    return QuizAttemptAnswersCompanion(
      id: Value(id),
      attemptId: Value(attemptId),
      questionId: Value(questionId),
      givenJson: givenJson == null && nullToAbsent
          ? const Value.absent()
          : Value(givenJson),
      isCorrect: Value(isCorrect),
      skipped: Value(skipped),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      orderIndex: Value(orderIndex),
      timeMs: Value(timeMs),
      createdAt: Value(createdAt),
    );
  }

  factory QuizAnswerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizAnswerRow(
      id: serializer.fromJson<String>(json['id']),
      attemptId: serializer.fromJson<String>(json['attemptId']),
      questionId: serializer.fromJson<String>(json['questionId']),
      givenJson: serializer.fromJson<String?>(json['givenJson']),
      isCorrect: serializer.fromJson<bool>(json['isCorrect']),
      skipped: serializer.fromJson<bool>(json['skipped']),
      subject: serializer.fromJson<String?>(json['subject']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      timeMs: serializer.fromJson<int>(json['timeMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'attemptId': serializer.toJson<String>(attemptId),
      'questionId': serializer.toJson<String>(questionId),
      'givenJson': serializer.toJson<String?>(givenJson),
      'isCorrect': serializer.toJson<bool>(isCorrect),
      'skipped': serializer.toJson<bool>(skipped),
      'subject': serializer.toJson<String?>(subject),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'timeMs': serializer.toJson<int>(timeMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  QuizAnswerRow copyWith({
    String? id,
    String? attemptId,
    String? questionId,
    Value<String?> givenJson = const Value.absent(),
    bool? isCorrect,
    bool? skipped,
    Value<String?> subject = const Value.absent(),
    int? orderIndex,
    int? timeMs,
    DateTime? createdAt,
  }) => QuizAnswerRow(
    id: id ?? this.id,
    attemptId: attemptId ?? this.attemptId,
    questionId: questionId ?? this.questionId,
    givenJson: givenJson.present ? givenJson.value : this.givenJson,
    isCorrect: isCorrect ?? this.isCorrect,
    skipped: skipped ?? this.skipped,
    subject: subject.present ? subject.value : this.subject,
    orderIndex: orderIndex ?? this.orderIndex,
    timeMs: timeMs ?? this.timeMs,
    createdAt: createdAt ?? this.createdAt,
  );
  QuizAnswerRow copyWithCompanion(QuizAttemptAnswersCompanion data) {
    return QuizAnswerRow(
      id: data.id.present ? data.id.value : this.id,
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      givenJson: data.givenJson.present ? data.givenJson.value : this.givenJson,
      isCorrect: data.isCorrect.present ? data.isCorrect.value : this.isCorrect,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      subject: data.subject.present ? data.subject.value : this.subject,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      timeMs: data.timeMs.present ? data.timeMs.value : this.timeMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizAnswerRow(')
          ..write('id: $id, ')
          ..write('attemptId: $attemptId, ')
          ..write('questionId: $questionId, ')
          ..write('givenJson: $givenJson, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('skipped: $skipped, ')
          ..write('subject: $subject, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('timeMs: $timeMs, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    attemptId,
    questionId,
    givenJson,
    isCorrect,
    skipped,
    subject,
    orderIndex,
    timeMs,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizAnswerRow &&
          other.id == this.id &&
          other.attemptId == this.attemptId &&
          other.questionId == this.questionId &&
          other.givenJson == this.givenJson &&
          other.isCorrect == this.isCorrect &&
          other.skipped == this.skipped &&
          other.subject == this.subject &&
          other.orderIndex == this.orderIndex &&
          other.timeMs == this.timeMs &&
          other.createdAt == this.createdAt);
}

class QuizAttemptAnswersCompanion extends UpdateCompanion<QuizAnswerRow> {
  final Value<String> id;
  final Value<String> attemptId;
  final Value<String> questionId;
  final Value<String?> givenJson;
  final Value<bool> isCorrect;
  final Value<bool> skipped;
  final Value<String?> subject;
  final Value<int> orderIndex;
  final Value<int> timeMs;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const QuizAttemptAnswersCompanion({
    this.id = const Value.absent(),
    this.attemptId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.givenJson = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.skipped = const Value.absent(),
    this.subject = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.timeMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizAttemptAnswersCompanion.insert({
    required String id,
    required String attemptId,
    required String questionId,
    this.givenJson = const Value.absent(),
    this.isCorrect = const Value.absent(),
    this.skipped = const Value.absent(),
    this.subject = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.timeMs = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       attemptId = Value(attemptId),
       questionId = Value(questionId),
       createdAt = Value(createdAt);
  static Insertable<QuizAnswerRow> custom({
    Expression<String>? id,
    Expression<String>? attemptId,
    Expression<String>? questionId,
    Expression<String>? givenJson,
    Expression<bool>? isCorrect,
    Expression<bool>? skipped,
    Expression<String>? subject,
    Expression<int>? orderIndex,
    Expression<int>? timeMs,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (attemptId != null) 'attempt_id': attemptId,
      if (questionId != null) 'question_id': questionId,
      if (givenJson != null) 'given_json': givenJson,
      if (isCorrect != null) 'is_correct': isCorrect,
      if (skipped != null) 'skipped': skipped,
      if (subject != null) 'subject': subject,
      if (orderIndex != null) 'order_index': orderIndex,
      if (timeMs != null) 'time_ms': timeMs,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizAttemptAnswersCompanion copyWith({
    Value<String>? id,
    Value<String>? attemptId,
    Value<String>? questionId,
    Value<String?>? givenJson,
    Value<bool>? isCorrect,
    Value<bool>? skipped,
    Value<String?>? subject,
    Value<int>? orderIndex,
    Value<int>? timeMs,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return QuizAttemptAnswersCompanion(
      id: id ?? this.id,
      attemptId: attemptId ?? this.attemptId,
      questionId: questionId ?? this.questionId,
      givenJson: givenJson ?? this.givenJson,
      isCorrect: isCorrect ?? this.isCorrect,
      skipped: skipped ?? this.skipped,
      subject: subject ?? this.subject,
      orderIndex: orderIndex ?? this.orderIndex,
      timeMs: timeMs ?? this.timeMs,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (attemptId.present) {
      map['attempt_id'] = Variable<String>(attemptId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (givenJson.present) {
      map['given_json'] = Variable<String>(givenJson.value);
    }
    if (isCorrect.present) {
      map['is_correct'] = Variable<bool>(isCorrect.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<bool>(skipped.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (timeMs.present) {
      map['time_ms'] = Variable<int>(timeMs.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizAttemptAnswersCompanion(')
          ..write('id: $id, ')
          ..write('attemptId: $attemptId, ')
          ..write('questionId: $questionId, ')
          ..write('givenJson: $givenJson, ')
          ..write('isCorrect: $isCorrect, ')
          ..write('skipped: $skipped, ')
          ..write('subject: $subject, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('timeMs: $timeMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuizWrongAnswersTable extends QuizWrongAnswers
    with TableInfo<$QuizWrongAnswersTable, QuizWrongRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizWrongAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankIdMeta = const VerificationMeta('bankId');
  @override
  late final GeneratedColumn<String> bankId = GeneratedColumn<String>(
    'bank_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastGivenJsonMeta = const VerificationMeta(
    'lastGivenJson',
  );
  @override
  late final GeneratedColumn<String> lastGivenJson = GeneratedColumn<String>(
    'last_given_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wrongCountMeta = const VerificationMeta(
    'wrongCount',
  );
  @override
  late final GeneratedColumn<int> wrongCount = GeneratedColumn<int>(
    'wrong_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastWrongAtMeta = const VerificationMeta(
    'lastWrongAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastWrongAt = GeneratedColumn<DateTime>(
    'last_wrong_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    questionId,
    bankId,
    subject,
    lastGivenJson,
    wrongCount,
    lastWrongAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_wrong_answers';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizWrongRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('bank_id')) {
      context.handle(
        _bankIdMeta,
        bankId.isAcceptableOrUnknown(data['bank_id']!, _bankIdMeta),
      );
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('last_given_json')) {
      context.handle(
        _lastGivenJsonMeta,
        lastGivenJson.isAcceptableOrUnknown(
          data['last_given_json']!,
          _lastGivenJsonMeta,
        ),
      );
    }
    if (data.containsKey('wrong_count')) {
      context.handle(
        _wrongCountMeta,
        wrongCount.isAcceptableOrUnknown(data['wrong_count']!, _wrongCountMeta),
      );
    }
    if (data.containsKey('last_wrong_at')) {
      context.handle(
        _lastWrongAtMeta,
        lastWrongAt.isAcceptableOrUnknown(
          data['last_wrong_at']!,
          _lastWrongAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastWrongAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {questionId};
  @override
  QuizWrongRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizWrongRow(
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      bankId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_id'],
      ),
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      ),
      lastGivenJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_given_json'],
      ),
      wrongCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wrong_count'],
      )!,
      lastWrongAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_wrong_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $QuizWrongAnswersTable createAlias(String alias) {
    return $QuizWrongAnswersTable(attachedDatabase, alias);
  }
}

class QuizWrongRow extends DataClass implements Insertable<QuizWrongRow> {
  /// The question id (natural key → one notebook entry per question).
  final String questionId;
  final String? bankId;
  final String? subject;

  /// JSON of the most recent wrong answer given.
  final String? lastGivenJson;
  final int wrongCount;
  final DateTime lastWrongAt;
  final DateTime createdAt;
  const QuizWrongRow({
    required this.questionId,
    this.bankId,
    this.subject,
    this.lastGivenJson,
    required this.wrongCount,
    required this.lastWrongAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['question_id'] = Variable<String>(questionId);
    if (!nullToAbsent || bankId != null) {
      map['bank_id'] = Variable<String>(bankId);
    }
    if (!nullToAbsent || subject != null) {
      map['subject'] = Variable<String>(subject);
    }
    if (!nullToAbsent || lastGivenJson != null) {
      map['last_given_json'] = Variable<String>(lastGivenJson);
    }
    map['wrong_count'] = Variable<int>(wrongCount);
    map['last_wrong_at'] = Variable<DateTime>(lastWrongAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QuizWrongAnswersCompanion toCompanion(bool nullToAbsent) {
    return QuizWrongAnswersCompanion(
      questionId: Value(questionId),
      bankId: bankId == null && nullToAbsent
          ? const Value.absent()
          : Value(bankId),
      subject: subject == null && nullToAbsent
          ? const Value.absent()
          : Value(subject),
      lastGivenJson: lastGivenJson == null && nullToAbsent
          ? const Value.absent()
          : Value(lastGivenJson),
      wrongCount: Value(wrongCount),
      lastWrongAt: Value(lastWrongAt),
      createdAt: Value(createdAt),
    );
  }

  factory QuizWrongRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizWrongRow(
      questionId: serializer.fromJson<String>(json['questionId']),
      bankId: serializer.fromJson<String?>(json['bankId']),
      subject: serializer.fromJson<String?>(json['subject']),
      lastGivenJson: serializer.fromJson<String?>(json['lastGivenJson']),
      wrongCount: serializer.fromJson<int>(json['wrongCount']),
      lastWrongAt: serializer.fromJson<DateTime>(json['lastWrongAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'questionId': serializer.toJson<String>(questionId),
      'bankId': serializer.toJson<String?>(bankId),
      'subject': serializer.toJson<String?>(subject),
      'lastGivenJson': serializer.toJson<String?>(lastGivenJson),
      'wrongCount': serializer.toJson<int>(wrongCount),
      'lastWrongAt': serializer.toJson<DateTime>(lastWrongAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  QuizWrongRow copyWith({
    String? questionId,
    Value<String?> bankId = const Value.absent(),
    Value<String?> subject = const Value.absent(),
    Value<String?> lastGivenJson = const Value.absent(),
    int? wrongCount,
    DateTime? lastWrongAt,
    DateTime? createdAt,
  }) => QuizWrongRow(
    questionId: questionId ?? this.questionId,
    bankId: bankId.present ? bankId.value : this.bankId,
    subject: subject.present ? subject.value : this.subject,
    lastGivenJson: lastGivenJson.present
        ? lastGivenJson.value
        : this.lastGivenJson,
    wrongCount: wrongCount ?? this.wrongCount,
    lastWrongAt: lastWrongAt ?? this.lastWrongAt,
    createdAt: createdAt ?? this.createdAt,
  );
  QuizWrongRow copyWithCompanion(QuizWrongAnswersCompanion data) {
    return QuizWrongRow(
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      bankId: data.bankId.present ? data.bankId.value : this.bankId,
      subject: data.subject.present ? data.subject.value : this.subject,
      lastGivenJson: data.lastGivenJson.present
          ? data.lastGivenJson.value
          : this.lastGivenJson,
      wrongCount: data.wrongCount.present
          ? data.wrongCount.value
          : this.wrongCount,
      lastWrongAt: data.lastWrongAt.present
          ? data.lastWrongAt.value
          : this.lastWrongAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizWrongRow(')
          ..write('questionId: $questionId, ')
          ..write('bankId: $bankId, ')
          ..write('subject: $subject, ')
          ..write('lastGivenJson: $lastGivenJson, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('lastWrongAt: $lastWrongAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    questionId,
    bankId,
    subject,
    lastGivenJson,
    wrongCount,
    lastWrongAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizWrongRow &&
          other.questionId == this.questionId &&
          other.bankId == this.bankId &&
          other.subject == this.subject &&
          other.lastGivenJson == this.lastGivenJson &&
          other.wrongCount == this.wrongCount &&
          other.lastWrongAt == this.lastWrongAt &&
          other.createdAt == this.createdAt);
}

class QuizWrongAnswersCompanion extends UpdateCompanion<QuizWrongRow> {
  final Value<String> questionId;
  final Value<String?> bankId;
  final Value<String?> subject;
  final Value<String?> lastGivenJson;
  final Value<int> wrongCount;
  final Value<DateTime> lastWrongAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const QuizWrongAnswersCompanion({
    this.questionId = const Value.absent(),
    this.bankId = const Value.absent(),
    this.subject = const Value.absent(),
    this.lastGivenJson = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.lastWrongAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizWrongAnswersCompanion.insert({
    required String questionId,
    this.bankId = const Value.absent(),
    this.subject = const Value.absent(),
    this.lastGivenJson = const Value.absent(),
    this.wrongCount = const Value.absent(),
    required DateTime lastWrongAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : questionId = Value(questionId),
       lastWrongAt = Value(lastWrongAt),
       createdAt = Value(createdAt);
  static Insertable<QuizWrongRow> custom({
    Expression<String>? questionId,
    Expression<String>? bankId,
    Expression<String>? subject,
    Expression<String>? lastGivenJson,
    Expression<int>? wrongCount,
    Expression<DateTime>? lastWrongAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (questionId != null) 'question_id': questionId,
      if (bankId != null) 'bank_id': bankId,
      if (subject != null) 'subject': subject,
      if (lastGivenJson != null) 'last_given_json': lastGivenJson,
      if (wrongCount != null) 'wrong_count': wrongCount,
      if (lastWrongAt != null) 'last_wrong_at': lastWrongAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizWrongAnswersCompanion copyWith({
    Value<String>? questionId,
    Value<String?>? bankId,
    Value<String?>? subject,
    Value<String?>? lastGivenJson,
    Value<int>? wrongCount,
    Value<DateTime>? lastWrongAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return QuizWrongAnswersCompanion(
      questionId: questionId ?? this.questionId,
      bankId: bankId ?? this.bankId,
      subject: subject ?? this.subject,
      lastGivenJson: lastGivenJson ?? this.lastGivenJson,
      wrongCount: wrongCount ?? this.wrongCount,
      lastWrongAt: lastWrongAt ?? this.lastWrongAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (bankId.present) {
      map['bank_id'] = Variable<String>(bankId.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (lastGivenJson.present) {
      map['last_given_json'] = Variable<String>(lastGivenJson.value);
    }
    if (wrongCount.present) {
      map['wrong_count'] = Variable<int>(wrongCount.value);
    }
    if (lastWrongAt.present) {
      map['last_wrong_at'] = Variable<DateTime>(lastWrongAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizWrongAnswersCompanion(')
          ..write('questionId: $questionId, ')
          ..write('bankId: $bankId, ')
          ..write('subject: $subject, ')
          ..write('lastGivenJson: $lastGivenJson, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('lastWrongAt: $lastWrongAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuizSettingsRowsTable extends QuizSettingsRows
    with TableInfo<$QuizSettingsRowsTable, QuizSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizSettingsRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_settings_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  QuizSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $QuizSettingsRowsTable createAlias(String alias) {
    return $QuizSettingsRowsTable(attachedDatabase, alias);
  }
}

class QuizSettingRow extends DataClass implements Insertable<QuizSettingRow> {
  final String key;
  final String value;
  const QuizSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  QuizSettingsRowsCompanion toCompanion(bool nullToAbsent) {
    return QuizSettingsRowsCompanion(key: Value(key), value: Value(value));
  }

  factory QuizSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  QuizSettingRow copyWith({String? key, String? value}) =>
      QuizSettingRow(key: key ?? this.key, value: value ?? this.value);
  QuizSettingRow copyWithCompanion(QuizSettingsRowsCompanion data) {
    return QuizSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class QuizSettingsRowsCompanion extends UpdateCompanion<QuizSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const QuizSettingsRowsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizSettingsRowsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<QuizSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizSettingsRowsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return QuizSettingsRowsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizSettingsRowsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuizSubjectsTable extends QuizSubjects
    with TableInfo<$QuizSubjectsTable, QuizSubjectRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizSubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<int> icon = GeneratedColumn<int>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    icon,
    color,
    orderIndex,
    archived,
    searchText,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizSubjectRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuizSubjectRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizSubjectRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuizSubjectsTable createAlias(String alias) {
    return $QuizSubjectsTable(attachedDatabase, alias);
  }
}

class QuizSubjectRow extends DataClass implements Insertable<QuizSubjectRow> {
  final String id;
  final String name;
  final String? description;

  /// Material icon code point (optional).
  final int? icon;

  /// ARGB colour (optional; else a subject colour / theme default is used).
  final int? color;
  final int orderIndex;
  final bool archived;
  final String searchText;
  final DateTime createdAt;
  final DateTime updatedAt;
  const QuizSubjectRow({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.orderIndex,
    required this.archived,
    required this.searchText,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<int>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['order_index'] = Variable<int>(orderIndex);
    map['archived'] = Variable<bool>(archived);
    map['search_text'] = Variable<String>(searchText);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuizSubjectsCompanion toCompanion(bool nullToAbsent) {
    return QuizSubjectsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      orderIndex: Value(orderIndex),
      archived: Value(archived),
      searchText: Value(searchText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuizSubjectRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizSubjectRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      icon: serializer.fromJson<int?>(json['icon']),
      color: serializer.fromJson<int?>(json['color']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      archived: serializer.fromJson<bool>(json['archived']),
      searchText: serializer.fromJson<String>(json['searchText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'icon': serializer.toJson<int?>(icon),
      'color': serializer.toJson<int?>(color),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'archived': serializer.toJson<bool>(archived),
      'searchText': serializer.toJson<String>(searchText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QuizSubjectRow copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<int?> icon = const Value.absent(),
    Value<int?> color = const Value.absent(),
    int? orderIndex,
    bool? archived,
    String? searchText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => QuizSubjectRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    orderIndex: orderIndex ?? this.orderIndex,
    archived: archived ?? this.archived,
    searchText: searchText ?? this.searchText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QuizSubjectRow copyWithCompanion(QuizSubjectsCompanion data) {
    return QuizSubjectRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      archived: data.archived.present ? data.archived.value : this.archived,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizSubjectRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('archived: $archived, ')
          ..write('searchText: $searchText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    icon,
    color,
    orderIndex,
    archived,
    searchText,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizSubjectRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.orderIndex == this.orderIndex &&
          other.archived == this.archived &&
          other.searchText == this.searchText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QuizSubjectsCompanion extends UpdateCompanion<QuizSubjectRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int?> icon;
  final Value<int?> color;
  final Value<int> orderIndex;
  final Value<bool> archived;
  final Value<String> searchText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QuizSubjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.archived = const Value.absent(),
    this.searchText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizSubjectsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.archived = const Value.absent(),
    this.searchText = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<QuizSubjectRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? icon,
    Expression<int>? color,
    Expression<int>? orderIndex,
    Expression<bool>? archived,
    Expression<String>? searchText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (orderIndex != null) 'order_index': orderIndex,
      if (archived != null) 'archived': archived,
      if (searchText != null) 'search_text': searchText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizSubjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int?>? icon,
    Value<int?>? color,
    Value<int>? orderIndex,
    Value<bool>? archived,
    Value<String>? searchText,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return QuizSubjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      orderIndex: orderIndex ?? this.orderIndex,
      archived: archived ?? this.archived,
      searchText: searchText ?? this.searchText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<int>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizSubjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('archived: $archived, ')
          ..write('searchText: $searchText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $QuizTopicsTable extends QuizTopics
    with TableInfo<$QuizTopicsTable, QuizTopicRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizTopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<String> subjectId = GeneratedColumn<String>(
    'subject_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<int> icon = GeneratedColumn<int>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subjectId,
    name,
    description,
    icon,
    color,
    orderIndex,
    archived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_topics';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuizTopicRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_subjectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuizTopicRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizTopicRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $QuizTopicsTable createAlias(String alias) {
    return $QuizTopicsTable(attachedDatabase, alias);
  }
}

class QuizTopicRow extends DataClass implements Insertable<QuizTopicRow> {
  final String id;
  final String subjectId;
  final String name;
  final String? description;
  final int? icon;
  final int? color;
  final int orderIndex;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  const QuizTopicRow({
    required this.id,
    required this.subjectId,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.orderIndex,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['subject_id'] = Variable<String>(subjectId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<int>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['order_index'] = Variable<int>(orderIndex);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  QuizTopicsCompanion toCompanion(bool nullToAbsent) {
    return QuizTopicsCompanion(
      id: Value(id),
      subjectId: Value(subjectId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      orderIndex: Value(orderIndex),
      archived: Value(archived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory QuizTopicRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizTopicRow(
      id: serializer.fromJson<String>(json['id']),
      subjectId: serializer.fromJson<String>(json['subjectId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      icon: serializer.fromJson<int?>(json['icon']),
      color: serializer.fromJson<int?>(json['color']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subjectId': serializer.toJson<String>(subjectId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'icon': serializer.toJson<int?>(icon),
      'color': serializer.toJson<int?>(color),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  QuizTopicRow copyWith({
    String? id,
    String? subjectId,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<int?> icon = const Value.absent(),
    Value<int?> color = const Value.absent(),
    int? orderIndex,
    bool? archived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => QuizTopicRow(
    id: id ?? this.id,
    subjectId: subjectId ?? this.subjectId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    orderIndex: orderIndex ?? this.orderIndex,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  QuizTopicRow copyWithCompanion(QuizTopicsCompanion data) {
    return QuizTopicRow(
      id: data.id.present ? data.id.value : this.id,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizTopicRow(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subjectId,
    name,
    description,
    icon,
    color,
    orderIndex,
    archived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizTopicRow &&
          other.id == this.id &&
          other.subjectId == this.subjectId &&
          other.name == this.name &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.orderIndex == this.orderIndex &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class QuizTopicsCompanion extends UpdateCompanion<QuizTopicRow> {
  final Value<String> id;
  final Value<String> subjectId;
  final Value<String> name;
  final Value<String?> description;
  final Value<int?> icon;
  final Value<int?> color;
  final Value<int> orderIndex;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const QuizTopicsCompanion({
    this.id = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizTopicsCompanion.insert({
    required String id,
    required String subjectId,
    required String name,
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.archived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       subjectId = Value(subjectId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<QuizTopicRow> custom({
    Expression<String>? id,
    Expression<String>? subjectId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? icon,
    Expression<int>? color,
    Expression<int>? orderIndex,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subjectId != null) 'subject_id': subjectId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (orderIndex != null) 'order_index': orderIndex,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizTopicsCompanion copyWith({
    Value<String>? id,
    Value<String>? subjectId,
    Value<String>? name,
    Value<String?>? description,
    Value<int?>? icon,
    Value<int?>? color,
    Value<int>? orderIndex,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return QuizTopicsCompanion(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      orderIndex: orderIndex ?? this.orderIndex,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<String>(subjectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<int>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizTopicsCompanion(')
          ..write('id: $id, ')
          ..write('subjectId: $subjectId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiConversationsTable extends AiConversations
    with TableInfo<$AiConversationsTable, AiConversationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _searchTextMeta = const VerificationMeta(
    'searchText',
  );
  @override
  late final GeneratedColumn<String> searchText = GeneratedColumn<String>(
    'search_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    model,
    pinned,
    searchText,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiConversationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    if (data.containsKey('search_text')) {
      context.handle(
        _searchTextMeta,
        searchText.isAcceptableOrUnknown(data['search_text']!, _searchTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiConversationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiConversationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      searchText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AiConversationsTable createAlias(String alias) {
    return $AiConversationsTable(attachedDatabase, alias);
  }
}

class AiConversationRow extends DataClass
    implements Insertable<AiConversationRow> {
  final String id;
  final String title;

  /// The model used for this conversation (e.g. 'auto').
  final String? model;
  final bool pinned;

  /// Lowercased title (+ optional content) for fast conversation search.
  final String searchText;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AiConversationRow({
    required this.id,
    required this.title,
    this.model,
    required this.pinned,
    required this.searchText,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    map['pinned'] = Variable<bool>(pinned);
    map['search_text'] = Variable<String>(searchText);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AiConversationsCompanion toCompanion(bool nullToAbsent) {
    return AiConversationsCompanion(
      id: Value(id),
      title: Value(title),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      pinned: Value(pinned),
      searchText: Value(searchText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AiConversationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiConversationRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      model: serializer.fromJson<String?>(json['model']),
      pinned: serializer.fromJson<bool>(json['pinned']),
      searchText: serializer.fromJson<String>(json['searchText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'model': serializer.toJson<String?>(model),
      'pinned': serializer.toJson<bool>(pinned),
      'searchText': serializer.toJson<String>(searchText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AiConversationRow copyWith({
    String? id,
    String? title,
    Value<String?> model = const Value.absent(),
    bool? pinned,
    String? searchText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AiConversationRow(
    id: id ?? this.id,
    title: title ?? this.title,
    model: model.present ? model.value : this.model,
    pinned: pinned ?? this.pinned,
    searchText: searchText ?? this.searchText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AiConversationRow copyWithCompanion(AiConversationsCompanion data) {
    return AiConversationRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      model: data.model.present ? data.model.value : this.model,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      searchText: data.searchText.present
          ? data.searchText.value
          : this.searchText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiConversationRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('model: $model, ')
          ..write('pinned: $pinned, ')
          ..write('searchText: $searchText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, model, pinned, searchText, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiConversationRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.model == this.model &&
          other.pinned == this.pinned &&
          other.searchText == this.searchText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AiConversationsCompanion extends UpdateCompanion<AiConversationRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> model;
  final Value<bool> pinned;
  final Value<String> searchText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AiConversationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.model = const Value.absent(),
    this.pinned = const Value.absent(),
    this.searchText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiConversationsCompanion.insert({
    required String id,
    required String title,
    this.model = const Value.absent(),
    this.pinned = const Value.absent(),
    this.searchText = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AiConversationRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? model,
    Expression<bool>? pinned,
    Expression<String>? searchText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (model != null) 'model': model,
      if (pinned != null) 'pinned': pinned,
      if (searchText != null) 'search_text': searchText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? model,
    Value<bool>? pinned,
    Value<String>? searchText,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AiConversationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      model: model ?? this.model,
      pinned: pinned ?? this.pinned,
      searchText: searchText ?? this.searchText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (searchText.present) {
      map['search_text'] = Variable<String>(searchText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiConversationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('model: $model, ')
          ..write('pinned: $pinned, ')
          ..write('searchText: $searchText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiMessagesTable extends AiMessages
    with TableInfo<$AiMessagesTable, AiMessageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<int> role = GeneratedColumn<int>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMeta = const VerificationMeta('error');
  @override
  late final GeneratedColumn<String> error = GeneratedColumn<String>(
    'error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderIndexMeta = const VerificationMeta(
    'orderIndex',
  );
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
    'order_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    role,
    content,
    status,
    error,
    orderIndex,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiMessageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('error')) {
      context.handle(
        _errorMeta,
        error.isAcceptableOrUnknown(data['error']!, _errorMeta),
      );
    }
    if (data.containsKey('order_index')) {
      context.handle(
        _orderIndexMeta,
        orderIndex.isAcceptableOrUnknown(data['order_index']!, _orderIndexMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiMessageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiMessageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}role'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      error: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error'],
      ),
      orderIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AiMessagesTable createAlias(String alias) {
    return $AiMessagesTable(attachedDatabase, alias);
  }
}

class AiMessageRow extends DataClass implements Insertable<AiMessageRow> {
  final String id;
  final String conversationId;

  /// 0 = system, 1 = user, 2 = assistant (mirrors AiRole.index).
  final int role;
  final String content;

  /// 0 = done, 1 = error (mirrors AiMessageStatus persisted subset).
  final int status;
  final String? error;
  final int orderIndex;
  final DateTime createdAt;
  const AiMessageRow({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.status,
    this.error,
    required this.orderIndex,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['role'] = Variable<int>(role);
    map['content'] = Variable<String>(content);
    map['status'] = Variable<int>(status);
    if (!nullToAbsent || error != null) {
      map['error'] = Variable<String>(error);
    }
    map['order_index'] = Variable<int>(orderIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AiMessagesCompanion toCompanion(bool nullToAbsent) {
    return AiMessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      role: Value(role),
      content: Value(content),
      status: Value(status),
      error: error == null && nullToAbsent
          ? const Value.absent()
          : Value(error),
      orderIndex: Value(orderIndex),
      createdAt: Value(createdAt),
    );
  }

  factory AiMessageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiMessageRow(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      role: serializer.fromJson<int>(json['role']),
      content: serializer.fromJson<String>(json['content']),
      status: serializer.fromJson<int>(json['status']),
      error: serializer.fromJson<String?>(json['error']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'role': serializer.toJson<int>(role),
      'content': serializer.toJson<String>(content),
      'status': serializer.toJson<int>(status),
      'error': serializer.toJson<String?>(error),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AiMessageRow copyWith({
    String? id,
    String? conversationId,
    int? role,
    String? content,
    int? status,
    Value<String?> error = const Value.absent(),
    int? orderIndex,
    DateTime? createdAt,
  }) => AiMessageRow(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    role: role ?? this.role,
    content: content ?? this.content,
    status: status ?? this.status,
    error: error.present ? error.value : this.error,
    orderIndex: orderIndex ?? this.orderIndex,
    createdAt: createdAt ?? this.createdAt,
  );
  AiMessageRow copyWithCompanion(AiMessagesCompanion data) {
    return AiMessageRow(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      role: data.role.present ? data.role.value : this.role,
      content: data.content.present ? data.content.value : this.content,
      status: data.status.present ? data.status.value : this.status,
      error: data.error.present ? data.error.value : this.error,
      orderIndex: data.orderIndex.present
          ? data.orderIndex.value
          : this.orderIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiMessageRow(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('error: $error, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    role,
    content,
    status,
    error,
    orderIndex,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiMessageRow &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.role == this.role &&
          other.content == this.content &&
          other.status == this.status &&
          other.error == this.error &&
          other.orderIndex == this.orderIndex &&
          other.createdAt == this.createdAt);
}

class AiMessagesCompanion extends UpdateCompanion<AiMessageRow> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<int> role;
  final Value<String> content;
  final Value<int> status;
  final Value<String?> error;
  final Value<int> orderIndex;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AiMessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.role = const Value.absent(),
    this.content = const Value.absent(),
    this.status = const Value.absent(),
    this.error = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiMessagesCompanion.insert({
    required String id,
    required String conversationId,
    required int role,
    required String content,
    this.status = const Value.absent(),
    this.error = const Value.absent(),
    this.orderIndex = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       role = Value(role),
       content = Value(content),
       createdAt = Value(createdAt);
  static Insertable<AiMessageRow> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<int>? role,
    Expression<String>? content,
    Expression<int>? status,
    Expression<String>? error,
    Expression<int>? orderIndex,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (role != null) 'role': role,
      if (content != null) 'content': content,
      if (status != null) 'status': status,
      if (error != null) 'error': error,
      if (orderIndex != null) 'order_index': orderIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<int>? role,
    Value<String>? content,
    Value<int>? status,
    Value<String?>? error,
    Value<int>? orderIndex,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AiMessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      status: status ?? this.status,
      error: error ?? this.error,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (role.present) {
      map['role'] = Variable<int>(role.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (error.present) {
      map['error'] = Variable<String>(error.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiMessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('role: $role, ')
          ..write('content: $content, ')
          ..write('status: $status, ')
          ..write('error: $error, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DocumentsTable documents = $DocumentsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $BookmarksTable bookmarks = $BookmarksTable(this);
  late final $HighlightsTable highlights = $HighlightsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $ReadingProgressTable readingProgress = $ReadingProgressTable(
    this,
  );
  late final $ReadingSessionsTable readingSessions = $ReadingSessionsTable(
    this,
  );
  late final $SettingsTable settings = $SettingsTable(this);
  late final $DictionaryEntriesTable dictionaryEntries =
      $DictionaryEntriesTable(this);
  late final $DictionaryFavoritesTable dictionaryFavorites =
      $DictionaryFavoritesTable(this);
  late final $DictionaryExamEntriesTable dictionaryExamEntries =
      $DictionaryExamEntriesTable(this);
  late final $DictionarySearchHistoryTable dictionarySearchHistory =
      $DictionarySearchHistoryTable(this);
  late final $TranslationEntriesTable translationEntries =
      $TranslationEntriesTable(this);
  late final $TranslationCacheTable translationCache = $TranslationCacheTable(
    this,
  );
  late final $GrammarLessonsTable grammarLessons = $GrammarLessonsTable(this);
  late final $GrammarProgressTable grammarProgress = $GrammarProgressTable(
    this,
  );
  late final $GrammarFavoritesTable grammarFavorites = $GrammarFavoritesTable(
    this,
  );
  late final $GrammarTopicsTable grammarTopics = $GrammarTopicsTable(this);
  late final $VocabularyListsTable vocabularyLists = $VocabularyListsTable(
    this,
  );
  late final $VocabularyWordsTable vocabularyWords = $VocabularyWordsTable(
    this,
  );
  late final $StudyTasksTable studyTasks = $StudyTasksTable(this);
  late final $StudyGoalsTable studyGoals = $StudyGoalsTable(this);
  late final $StudySessionsTable studySessions = $StudySessionsTable(this);
  late final $StudyTemplatesTable studyTemplates = $StudyTemplatesTable(this);
  late final $StudyTemplateItemsTable studyTemplateItems =
      $StudyTemplateItemsTable(this);
  late final $StudySubjectsTable studySubjects = $StudySubjectsTable(this);
  late final $DecksTable decks = $DecksTable(this);
  late final $FlashcardsTable flashcards = $FlashcardsTable(this);
  late final $ReviewLogsTable reviewLogs = $ReviewLogsTable(this);
  late final $QuizBanksTable quizBanks = $QuizBanksTable(this);
  late final $QuizQuestionsTable quizQuestions = $QuizQuestionsTable(this);
  late final $QuizAttemptsTable quizAttempts = $QuizAttemptsTable(this);
  late final $QuizAttemptAnswersTable quizAttemptAnswers =
      $QuizAttemptAnswersTable(this);
  late final $QuizWrongAnswersTable quizWrongAnswers = $QuizWrongAnswersTable(
    this,
  );
  late final $QuizSettingsRowsTable quizSettingsRows = $QuizSettingsRowsTable(
    this,
  );
  late final $QuizSubjectsTable quizSubjects = $QuizSubjectsTable(this);
  late final $QuizTopicsTable quizTopics = $QuizTopicsTable(this);
  late final $AiConversationsTable aiConversations = $AiConversationsTable(
    this,
  );
  late final $AiMessagesTable aiMessages = $AiMessagesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    documents,
    categories,
    bookmarks,
    highlights,
    notes,
    readingProgress,
    readingSessions,
    settings,
    dictionaryEntries,
    dictionaryFavorites,
    dictionaryExamEntries,
    dictionarySearchHistory,
    translationEntries,
    translationCache,
    grammarLessons,
    grammarProgress,
    grammarFavorites,
    grammarTopics,
    vocabularyLists,
    vocabularyWords,
    studyTasks,
    studyGoals,
    studySessions,
    studyTemplates,
    studyTemplateItems,
    studySubjects,
    decks,
    flashcards,
    reviewLogs,
    quizBanks,
    quizQuestions,
    quizAttempts,
    quizAttemptAnswers,
    quizWrongAnswers,
    quizSettingsRows,
    quizSubjects,
    quizTopics,
    aiConversations,
    aiMessages,
  ];
}

typedef $$DocumentsTableCreateCompanionBuilder =
    DocumentsCompanion Function({
      required String id,
      required String title,
      required String fileName,
      required String filePath,
      Value<int> fileSize,
      Value<int> pageCount,
      Value<String?> coverPath,
      Value<String?> categoryId,
      Value<bool> isFavorite,
      required DateTime importedAt,
      Value<DateTime?> lastOpenedAt,
      Value<bool> managedFile,
      Value<int> rowid,
    });
typedef $$DocumentsTableUpdateCompanionBuilder =
    DocumentsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> fileName,
      Value<String> filePath,
      Value<int> fileSize,
      Value<int> pageCount,
      Value<String?> coverPath,
      Value<String?> categoryId,
      Value<bool> isFavorite,
      Value<DateTime> importedAt,
      Value<DateTime?> lastOpenedAt,
      Value<bool> managedFile,
      Value<int> rowid,
    });

class $$DocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
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

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get managedFile => $composableBuilder(
    column: $table.managedFile,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
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

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPath => $composableBuilder(
    column: $table.coverPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get managedFile => $composableBuilder(
    column: $table.managedFile,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentsTable> {
  $$DocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get managedFile => $composableBuilder(
    column: $table.managedFile,
    builder: (column) => column,
  );
}

class $$DocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentsTable,
          DocumentRow,
          $$DocumentsTableFilterComposer,
          $$DocumentsTableOrderingComposer,
          $$DocumentsTableAnnotationComposer,
          $$DocumentsTableCreateCompanionBuilder,
          $$DocumentsTableUpdateCompanionBuilder,
          (
            DocumentRow,
            BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow>,
          ),
          DocumentRow,
          PrefetchHooks Function()
        > {
  $$DocumentsTableTableManager(_$AppDatabase db, $DocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<bool> managedFile = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion(
                id: id,
                title: title,
                fileName: fileName,
                filePath: filePath,
                fileSize: fileSize,
                pageCount: pageCount,
                coverPath: coverPath,
                categoryId: categoryId,
                isFavorite: isFavorite,
                importedAt: importedAt,
                lastOpenedAt: lastOpenedAt,
                managedFile: managedFile,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String fileName,
                required String filePath,
                Value<int> fileSize = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<String?> coverPath = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                required DateTime importedAt,
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<bool> managedFile = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentsCompanion.insert(
                id: id,
                title: title,
                fileName: fileName,
                filePath: filePath,
                fileSize: fileSize,
                pageCount: pageCount,
                coverPath: coverPath,
                categoryId: categoryId,
                isFavorite: isFavorite,
                importedAt: importedAt,
                lastOpenedAt: lastOpenedAt,
                managedFile: managedFile,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentsTable,
      DocumentRow,
      $$DocumentsTableFilterComposer,
      $$DocumentsTableOrderingComposer,
      $$DocumentsTableAnnotationComposer,
      $$DocumentsTableCreateCompanionBuilder,
      $$DocumentsTableUpdateCompanionBuilder,
      (
        DocumentRow,
        BaseReferences<_$AppDatabase, $DocumentsTable, DocumentRow>,
      ),
      DocumentRow,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String name,
      required int colorValue,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> colorValue,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                colorValue: colorValue,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int colorValue,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                colorValue: colorValue,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$BookmarksTableCreateCompanionBuilder =
    BookmarksCompanion Function({
      required String id,
      required String documentId,
      required int pageNumber,
      Value<String?> label,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$BookmarksTableUpdateCompanionBuilder =
    BookmarksCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<int> pageNumber,
      Value<String?> label,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$BookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookmarksTable> {
  $$BookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BookmarksTable,
          BookmarkRow,
          $$BookmarksTableFilterComposer,
          $$BookmarksTableOrderingComposer,
          $$BookmarksTableAnnotationComposer,
          $$BookmarksTableCreateCompanionBuilder,
          $$BookmarksTableUpdateCompanionBuilder,
          (
            BookmarkRow,
            BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow>,
          ),
          BookmarkRow,
          PrefetchHooks Function()
        > {
  $$BookmarksTableTableManager(_$AppDatabase db, $BookmarksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookmarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookmarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookmarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                label: label,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required int pageNumber,
                Value<String?> label = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BookmarksCompanion.insert(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                label: label,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BookmarksTable,
      BookmarkRow,
      $$BookmarksTableFilterComposer,
      $$BookmarksTableOrderingComposer,
      $$BookmarksTableAnnotationComposer,
      $$BookmarksTableCreateCompanionBuilder,
      $$BookmarksTableUpdateCompanionBuilder,
      (
        BookmarkRow,
        BaseReferences<_$AppDatabase, $BookmarksTable, BookmarkRow>,
      ),
      BookmarkRow,
      PrefetchHooks Function()
    >;
typedef $$HighlightsTableCreateCompanionBuilder =
    HighlightsCompanion Function({
      required String id,
      required String documentId,
      required int pageNumber,
      Value<int> type,
      required int colorValue,
      Value<String> selectedText,
      required List<NormalizedRect> rects,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$HighlightsTableUpdateCompanionBuilder =
    HighlightsCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<int> pageNumber,
      Value<int> type,
      Value<int> colorValue,
      Value<String> selectedText,
      Value<List<NormalizedRect>> rects,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$HighlightsTableFilterComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedText => $composableBuilder(
    column: $table.selectedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<NormalizedRect>,
    List<NormalizedRect>,
    String
  >
  get rects => $composableBuilder(
    column: $table.rects,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HighlightsTableOrderingComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedText => $composableBuilder(
    column: $table.selectedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rects => $composableBuilder(
    column: $table.rects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HighlightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HighlightsTable> {
  $$HighlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get colorValue => $composableBuilder(
    column: $table.colorValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedText => $composableBuilder(
    column: $table.selectedText,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<NormalizedRect>, String> get rects =>
      $composableBuilder(column: $table.rects, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HighlightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HighlightsTable,
          HighlightRow,
          $$HighlightsTableFilterComposer,
          $$HighlightsTableOrderingComposer,
          $$HighlightsTableAnnotationComposer,
          $$HighlightsTableCreateCompanionBuilder,
          $$HighlightsTableUpdateCompanionBuilder,
          (
            HighlightRow,
            BaseReferences<_$AppDatabase, $HighlightsTable, HighlightRow>,
          ),
          HighlightRow,
          PrefetchHooks Function()
        > {
  $$HighlightsTableTableManager(_$AppDatabase db, $HighlightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HighlightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HighlightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HighlightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<int> colorValue = const Value.absent(),
                Value<String> selectedText = const Value.absent(),
                Value<List<NormalizedRect>> rects = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HighlightsCompanion(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                type: type,
                colorValue: colorValue,
                selectedText: selectedText,
                rects: rects,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required int pageNumber,
                Value<int> type = const Value.absent(),
                required int colorValue,
                Value<String> selectedText = const Value.absent(),
                required List<NormalizedRect> rects,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HighlightsCompanion.insert(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                type: type,
                colorValue: colorValue,
                selectedText: selectedText,
                rects: rects,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HighlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HighlightsTable,
      HighlightRow,
      $$HighlightsTableFilterComposer,
      $$HighlightsTableOrderingComposer,
      $$HighlightsTableAnnotationComposer,
      $$HighlightsTableCreateCompanionBuilder,
      $$HighlightsTableUpdateCompanionBuilder,
      (
        HighlightRow,
        BaseReferences<_$AppDatabase, $HighlightsTable, HighlightRow>,
      ),
      HighlightRow,
      PrefetchHooks Function()
    >;
typedef $$NotesTableCreateCompanionBuilder =
    NotesCompanion Function({
      required String id,
      required String documentId,
      required int pageNumber,
      required String content,
      Value<int> anchorType,
      Value<String?> selectedText,
      required List<NormalizedRect> rects,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$NotesTableUpdateCompanionBuilder =
    NotesCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<int> pageNumber,
      Value<String> content,
      Value<int> anchorType,
      Value<String?> selectedText,
      Value<List<NormalizedRect>> rects,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anchorType => $composableBuilder(
    column: $table.anchorType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedText => $composableBuilder(
    column: $table.selectedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    List<NormalizedRect>,
    List<NormalizedRect>,
    String
  >
  get rects => $composableBuilder(
    column: $table.rects,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anchorType => $composableBuilder(
    column: $table.anchorType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedText => $composableBuilder(
    column: $table.selectedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rects => $composableBuilder(
    column: $table.rects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get anchorType => $composableBuilder(
    column: $table.anchorType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedText => $composableBuilder(
    column: $table.selectedText,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<List<NormalizedRect>, String> get rects =>
      $composableBuilder(column: $table.rects, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          NoteRow,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
          NoteRow,
          PrefetchHooks Function()
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> anchorType = const Value.absent(),
                Value<String?> selectedText = const Value.absent(),
                Value<List<NormalizedRect>> rects = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                content: content,
                anchorType: anchorType,
                selectedText: selectedText,
                rects: rects,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required int pageNumber,
                required String content,
                Value<int> anchorType = const Value.absent(),
                Value<String?> selectedText = const Value.absent(),
                required List<NormalizedRect> rects,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                content: content,
                anchorType: anchorType,
                selectedText: selectedText,
                rects: rects,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      NoteRow,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (NoteRow, BaseReferences<_$AppDatabase, $NotesTable, NoteRow>),
      NoteRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingProgressTableCreateCompanionBuilder =
    ReadingProgressCompanion Function({
      required String documentId,
      Value<int> lastPage,
      Value<int> totalPages,
      Value<double> percent,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReadingProgressTableUpdateCompanionBuilder =
    ReadingProgressCompanion Function({
      Value<String> documentId,
      Value<int> lastPage,
      Value<int> totalPages,
      Value<double> percent,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ReadingProgressTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPage => $composableBuilder(
    column: $table.lastPage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPage => $composableBuilder(
    column: $table.lastPage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingProgressTable> {
  $$ReadingProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPage =>
      $composableBuilder(column: $table.lastPage, builder: (column) => column);

  GeneratedColumn<int> get totalPages => $composableBuilder(
    column: $table.totalPages,
    builder: (column) => column,
  );

  GeneratedColumn<double> get percent =>
      $composableBuilder(column: $table.percent, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReadingProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingProgressTable,
          ReadingProgressRow,
          $$ReadingProgressTableFilterComposer,
          $$ReadingProgressTableOrderingComposer,
          $$ReadingProgressTableAnnotationComposer,
          $$ReadingProgressTableCreateCompanionBuilder,
          $$ReadingProgressTableUpdateCompanionBuilder,
          (
            ReadingProgressRow,
            BaseReferences<
              _$AppDatabase,
              $ReadingProgressTable,
              ReadingProgressRow
            >,
          ),
          ReadingProgressRow,
          PrefetchHooks Function()
        > {
  $$ReadingProgressTableTableManager(
    _$AppDatabase db,
    $ReadingProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<int> lastPage = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<double> percent = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion(
                documentId: documentId,
                lastPage: lastPage,
                totalPages: totalPages,
                percent: percent,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                Value<int> lastPage = const Value.absent(),
                Value<int> totalPages = const Value.absent(),
                Value<double> percent = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingProgressCompanion.insert(
                documentId: documentId,
                lastPage: lastPage,
                totalPages: totalPages,
                percent: percent,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingProgressTable,
      ReadingProgressRow,
      $$ReadingProgressTableFilterComposer,
      $$ReadingProgressTableOrderingComposer,
      $$ReadingProgressTableAnnotationComposer,
      $$ReadingProgressTableCreateCompanionBuilder,
      $$ReadingProgressTableUpdateCompanionBuilder,
      (
        ReadingProgressRow,
        BaseReferences<
          _$AppDatabase,
          $ReadingProgressTable,
          ReadingProgressRow
        >,
      ),
      ReadingProgressRow,
      PrefetchHooks Function()
    >;
typedef $$ReadingSessionsTableCreateCompanionBuilder =
    ReadingSessionsCompanion Function({
      required String id,
      required String documentId,
      required int pageNumber,
      required DateTime openedAt,
      Value<int> rowid,
    });
typedef $$ReadingSessionsTableUpdateCompanionBuilder =
    ReadingSessionsCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<int> pageNumber,
      Value<DateTime> openedAt,
      Value<int> rowid,
    });

class $$ReadingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReadingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReadingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);
}

class $$ReadingSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReadingSessionsTable,
          ReadingSessionRow,
          $$ReadingSessionsTableFilterComposer,
          $$ReadingSessionsTableOrderingComposer,
          $$ReadingSessionsTableAnnotationComposer,
          $$ReadingSessionsTableCreateCompanionBuilder,
          $$ReadingSessionsTableUpdateCompanionBuilder,
          (
            ReadingSessionRow,
            BaseReferences<
              _$AppDatabase,
              $ReadingSessionsTable,
              ReadingSessionRow
            >,
          ),
          ReadingSessionRow,
          PrefetchHooks Function()
        > {
  $$ReadingSessionsTableTableManager(
    _$AppDatabase db,
    $ReadingSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReadingSessionsCompanion(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                openedAt: openedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required int pageNumber,
                required DateTime openedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReadingSessionsCompanion.insert(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                openedAt: openedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReadingSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReadingSessionsTable,
      ReadingSessionRow,
      $$ReadingSessionsTableFilterComposer,
      $$ReadingSessionsTableOrderingComposer,
      $$ReadingSessionsTableAnnotationComposer,
      $$ReadingSessionsTableCreateCompanionBuilder,
      $$ReadingSessionsTableUpdateCompanionBuilder,
      (
        ReadingSessionRow,
        BaseReferences<_$AppDatabase, $ReadingSessionsTable, ReadingSessionRow>,
      ),
      ReadingSessionRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (SettingRow, BaseReferences<_$AppDatabase, $SettingsTable, SettingRow>),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$DictionaryEntriesTableCreateCompanionBuilder =
    DictionaryEntriesCompanion Function({
      Value<int> id,
      required String word,
      required String wordLower,
      Value<String?> partOfSpeech,
      required String meaning,
      Value<String?> ipaPronunciation,
      Value<String?> exampleSentence,
    });
typedef $$DictionaryEntriesTableUpdateCompanionBuilder =
    DictionaryEntriesCompanion Function({
      Value<int> id,
      Value<String> word,
      Value<String> wordLower,
      Value<String?> partOfSpeech,
      Value<String> meaning,
      Value<String?> ipaPronunciation,
      Value<String?> exampleSentence,
    });

class $$DictionaryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryEntriesTable> {
  $$DictionaryEntriesTableFilterComposer({
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

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ipaPronunciation => $composableBuilder(
    column: $table.ipaPronunciation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryEntriesTable> {
  $$DictionaryEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ipaPronunciation => $composableBuilder(
    column: $table.ipaPronunciation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryEntriesTable> {
  $$DictionaryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get wordLower =>
      $composableBuilder(column: $table.wordLower, builder: (column) => column);

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get ipaPronunciation => $composableBuilder(
    column: $table.ipaPronunciation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exampleSentence => $composableBuilder(
    column: $table.exampleSentence,
    builder: (column) => column,
  );
}

class $$DictionaryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryEntriesTable,
          DictionaryEntryRow,
          $$DictionaryEntriesTableFilterComposer,
          $$DictionaryEntriesTableOrderingComposer,
          $$DictionaryEntriesTableAnnotationComposer,
          $$DictionaryEntriesTableCreateCompanionBuilder,
          $$DictionaryEntriesTableUpdateCompanionBuilder,
          (
            DictionaryEntryRow,
            BaseReferences<
              _$AppDatabase,
              $DictionaryEntriesTable,
              DictionaryEntryRow
            >,
          ),
          DictionaryEntryRow,
          PrefetchHooks Function()
        > {
  $$DictionaryEntriesTableTableManager(
    _$AppDatabase db,
    $DictionaryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionaryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DictionaryEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> wordLower = const Value.absent(),
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<String?> ipaPronunciation = const Value.absent(),
                Value<String?> exampleSentence = const Value.absent(),
              }) => DictionaryEntriesCompanion(
                id: id,
                word: word,
                wordLower: wordLower,
                partOfSpeech: partOfSpeech,
                meaning: meaning,
                ipaPronunciation: ipaPronunciation,
                exampleSentence: exampleSentence,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String word,
                required String wordLower,
                Value<String?> partOfSpeech = const Value.absent(),
                required String meaning,
                Value<String?> ipaPronunciation = const Value.absent(),
                Value<String?> exampleSentence = const Value.absent(),
              }) => DictionaryEntriesCompanion.insert(
                id: id,
                word: word,
                wordLower: wordLower,
                partOfSpeech: partOfSpeech,
                meaning: meaning,
                ipaPronunciation: ipaPronunciation,
                exampleSentence: exampleSentence,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryEntriesTable,
      DictionaryEntryRow,
      $$DictionaryEntriesTableFilterComposer,
      $$DictionaryEntriesTableOrderingComposer,
      $$DictionaryEntriesTableAnnotationComposer,
      $$DictionaryEntriesTableCreateCompanionBuilder,
      $$DictionaryEntriesTableUpdateCompanionBuilder,
      (
        DictionaryEntryRow,
        BaseReferences<
          _$AppDatabase,
          $DictionaryEntriesTable,
          DictionaryEntryRow
        >,
      ),
      DictionaryEntryRow,
      PrefetchHooks Function()
    >;
typedef $$DictionaryFavoritesTableCreateCompanionBuilder =
    DictionaryFavoritesCompanion Function({
      required String wordLower,
      required String word,
      Value<String?> partOfSpeech,
      required String meaning,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$DictionaryFavoritesTableUpdateCompanionBuilder =
    DictionaryFavoritesCompanion Function({
      Value<String> wordLower,
      Value<String> word,
      Value<String?> partOfSpeech,
      Value<String> meaning,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DictionaryFavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryFavoritesTable> {
  $$DictionaryFavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryFavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryFavoritesTable> {
  $$DictionaryFavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryFavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryFavoritesTable> {
  $$DictionaryFavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get wordLower =>
      $composableBuilder(column: $table.wordLower, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DictionaryFavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryFavoritesTable,
          DictionaryFavoriteRow,
          $$DictionaryFavoritesTableFilterComposer,
          $$DictionaryFavoritesTableOrderingComposer,
          $$DictionaryFavoritesTableAnnotationComposer,
          $$DictionaryFavoritesTableCreateCompanionBuilder,
          $$DictionaryFavoritesTableUpdateCompanionBuilder,
          (
            DictionaryFavoriteRow,
            BaseReferences<
              _$AppDatabase,
              $DictionaryFavoritesTable,
              DictionaryFavoriteRow
            >,
          ),
          DictionaryFavoriteRow,
          PrefetchHooks Function()
        > {
  $$DictionaryFavoritesTableTableManager(
    _$AppDatabase db,
    $DictionaryFavoritesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryFavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DictionaryFavoritesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DictionaryFavoritesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> wordLower = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String?> partOfSpeech = const Value.absent(),
                Value<String> meaning = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictionaryFavoritesCompanion(
                wordLower: wordLower,
                word: word,
                partOfSpeech: partOfSpeech,
                meaning: meaning,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String wordLower,
                required String word,
                Value<String?> partOfSpeech = const Value.absent(),
                required String meaning,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DictionaryFavoritesCompanion.insert(
                wordLower: wordLower,
                word: word,
                partOfSpeech: partOfSpeech,
                meaning: meaning,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryFavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryFavoritesTable,
      DictionaryFavoriteRow,
      $$DictionaryFavoritesTableFilterComposer,
      $$DictionaryFavoritesTableOrderingComposer,
      $$DictionaryFavoritesTableAnnotationComposer,
      $$DictionaryFavoritesTableCreateCompanionBuilder,
      $$DictionaryFavoritesTableUpdateCompanionBuilder,
      (
        DictionaryFavoriteRow,
        BaseReferences<
          _$AppDatabase,
          $DictionaryFavoritesTable,
          DictionaryFavoriteRow
        >,
      ),
      DictionaryFavoriteRow,
      PrefetchHooks Function()
    >;
typedef $$DictionaryExamEntriesTableCreateCompanionBuilder =
    DictionaryExamEntriesCompanion Function({
      required String wordLower,
      required String word,
      required String contentJson,
      Value<int> rowid,
    });
typedef $$DictionaryExamEntriesTableUpdateCompanionBuilder =
    DictionaryExamEntriesCompanion Function({
      Value<String> wordLower,
      Value<String> word,
      Value<String> contentJson,
      Value<int> rowid,
    });

class $$DictionaryExamEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $DictionaryExamEntriesTable> {
  $$DictionaryExamEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionaryExamEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionaryExamEntriesTable> {
  $$DictionaryExamEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionaryExamEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionaryExamEntriesTable> {
  $$DictionaryExamEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get wordLower =>
      $composableBuilder(column: $table.wordLower, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => column,
  );
}

class $$DictionaryExamEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionaryExamEntriesTable,
          DictionaryExamEntryRow,
          $$DictionaryExamEntriesTableFilterComposer,
          $$DictionaryExamEntriesTableOrderingComposer,
          $$DictionaryExamEntriesTableAnnotationComposer,
          $$DictionaryExamEntriesTableCreateCompanionBuilder,
          $$DictionaryExamEntriesTableUpdateCompanionBuilder,
          (
            DictionaryExamEntryRow,
            BaseReferences<
              _$AppDatabase,
              $DictionaryExamEntriesTable,
              DictionaryExamEntryRow
            >,
          ),
          DictionaryExamEntryRow,
          PrefetchHooks Function()
        > {
  $$DictionaryExamEntriesTableTableManager(
    _$AppDatabase db,
    $DictionaryExamEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionaryExamEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DictionaryExamEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DictionaryExamEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> wordLower = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> contentJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictionaryExamEntriesCompanion(
                wordLower: wordLower,
                word: word,
                contentJson: contentJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String wordLower,
                required String word,
                required String contentJson,
                Value<int> rowid = const Value.absent(),
              }) => DictionaryExamEntriesCompanion.insert(
                wordLower: wordLower,
                word: word,
                contentJson: contentJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionaryExamEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionaryExamEntriesTable,
      DictionaryExamEntryRow,
      $$DictionaryExamEntriesTableFilterComposer,
      $$DictionaryExamEntriesTableOrderingComposer,
      $$DictionaryExamEntriesTableAnnotationComposer,
      $$DictionaryExamEntriesTableCreateCompanionBuilder,
      $$DictionaryExamEntriesTableUpdateCompanionBuilder,
      (
        DictionaryExamEntryRow,
        BaseReferences<
          _$AppDatabase,
          $DictionaryExamEntriesTable,
          DictionaryExamEntryRow
        >,
      ),
      DictionaryExamEntryRow,
      PrefetchHooks Function()
    >;
typedef $$DictionarySearchHistoryTableCreateCompanionBuilder =
    DictionarySearchHistoryCompanion Function({
      required String wordLower,
      required String word,
      required DateTime searchedAt,
      Value<int> rowid,
    });
typedef $$DictionarySearchHistoryTableUpdateCompanionBuilder =
    DictionarySearchHistoryCompanion Function({
      Value<String> wordLower,
      Value<String> word,
      Value<DateTime> searchedAt,
      Value<int> rowid,
    });

class $$DictionarySearchHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $DictionarySearchHistoryTable> {
  $$DictionarySearchHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DictionarySearchHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $DictionarySearchHistoryTable> {
  $$DictionarySearchHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DictionarySearchHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $DictionarySearchHistoryTable> {
  $$DictionarySearchHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get wordLower =>
      $composableBuilder(column: $table.wordLower, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<DateTime> get searchedAt => $composableBuilder(
    column: $table.searchedAt,
    builder: (column) => column,
  );
}

class $$DictionarySearchHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DictionarySearchHistoryTable,
          SearchHistoryRow,
          $$DictionarySearchHistoryTableFilterComposer,
          $$DictionarySearchHistoryTableOrderingComposer,
          $$DictionarySearchHistoryTableAnnotationComposer,
          $$DictionarySearchHistoryTableCreateCompanionBuilder,
          $$DictionarySearchHistoryTableUpdateCompanionBuilder,
          (
            SearchHistoryRow,
            BaseReferences<
              _$AppDatabase,
              $DictionarySearchHistoryTable,
              SearchHistoryRow
            >,
          ),
          SearchHistoryRow,
          PrefetchHooks Function()
        > {
  $$DictionarySearchHistoryTableTableManager(
    _$AppDatabase db,
    $DictionarySearchHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DictionarySearchHistoryTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$DictionarySearchHistoryTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DictionarySearchHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> wordLower = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<DateTime> searchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DictionarySearchHistoryCompanion(
                wordLower: wordLower,
                word: word,
                searchedAt: searchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String wordLower,
                required String word,
                required DateTime searchedAt,
                Value<int> rowid = const Value.absent(),
              }) => DictionarySearchHistoryCompanion.insert(
                wordLower: wordLower,
                word: word,
                searchedAt: searchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DictionarySearchHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DictionarySearchHistoryTable,
      SearchHistoryRow,
      $$DictionarySearchHistoryTableFilterComposer,
      $$DictionarySearchHistoryTableOrderingComposer,
      $$DictionarySearchHistoryTableAnnotationComposer,
      $$DictionarySearchHistoryTableCreateCompanionBuilder,
      $$DictionarySearchHistoryTableUpdateCompanionBuilder,
      (
        SearchHistoryRow,
        BaseReferences<
          _$AppDatabase,
          $DictionarySearchHistoryTable,
          SearchHistoryRow
        >,
      ),
      SearchHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$TranslationEntriesTableCreateCompanionBuilder =
    TranslationEntriesCompanion Function({
      Value<int> id,
      required String langCode,
      required String wordLower,
      required String translation,
    });
typedef $$TranslationEntriesTableUpdateCompanionBuilder =
    TranslationEntriesCompanion Function({
      Value<int> id,
      Value<String> langCode,
      Value<String> wordLower,
      Value<String> translation,
    });

class $$TranslationEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $TranslationEntriesTable> {
  $$TranslationEntriesTableFilterComposer({
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

  ColumnFilters<String> get langCode => $composableBuilder(
    column: $table.langCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TranslationEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TranslationEntriesTable> {
  $$TranslationEntriesTableOrderingComposer({
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

  ColumnOrderings<String> get langCode => $composableBuilder(
    column: $table.langCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TranslationEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranslationEntriesTable> {
  $$TranslationEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get langCode =>
      $composableBuilder(column: $table.langCode, builder: (column) => column);

  GeneratedColumn<String> get wordLower =>
      $composableBuilder(column: $table.wordLower, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );
}

class $$TranslationEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranslationEntriesTable,
          TranslationEntryRow,
          $$TranslationEntriesTableFilterComposer,
          $$TranslationEntriesTableOrderingComposer,
          $$TranslationEntriesTableAnnotationComposer,
          $$TranslationEntriesTableCreateCompanionBuilder,
          $$TranslationEntriesTableUpdateCompanionBuilder,
          (
            TranslationEntryRow,
            BaseReferences<
              _$AppDatabase,
              $TranslationEntriesTable,
              TranslationEntryRow
            >,
          ),
          TranslationEntryRow,
          PrefetchHooks Function()
        > {
  $$TranslationEntriesTableTableManager(
    _$AppDatabase db,
    $TranslationEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranslationEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranslationEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranslationEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> langCode = const Value.absent(),
                Value<String> wordLower = const Value.absent(),
                Value<String> translation = const Value.absent(),
              }) => TranslationEntriesCompanion(
                id: id,
                langCode: langCode,
                wordLower: wordLower,
                translation: translation,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String langCode,
                required String wordLower,
                required String translation,
              }) => TranslationEntriesCompanion.insert(
                id: id,
                langCode: langCode,
                wordLower: wordLower,
                translation: translation,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TranslationEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranslationEntriesTable,
      TranslationEntryRow,
      $$TranslationEntriesTableFilterComposer,
      $$TranslationEntriesTableOrderingComposer,
      $$TranslationEntriesTableAnnotationComposer,
      $$TranslationEntriesTableCreateCompanionBuilder,
      $$TranslationEntriesTableUpdateCompanionBuilder,
      (
        TranslationEntryRow,
        BaseReferences<
          _$AppDatabase,
          $TranslationEntriesTable,
          TranslationEntryRow
        >,
      ),
      TranslationEntryRow,
      PrefetchHooks Function()
    >;
typedef $$TranslationCacheTableCreateCompanionBuilder =
    TranslationCacheCompanion Function({
      required String langCode,
      required String wordLower,
      required String word,
      required String translation,
      Value<String> source,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$TranslationCacheTableUpdateCompanionBuilder =
    TranslationCacheCompanion Function({
      Value<String> langCode,
      Value<String> wordLower,
      Value<String> word,
      Value<String> translation,
      Value<String> source,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$TranslationCacheTableFilterComposer
    extends Composer<_$AppDatabase, $TranslationCacheTable> {
  $$TranslationCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get langCode => $composableBuilder(
    column: $table.langCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TranslationCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $TranslationCacheTable> {
  $$TranslationCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get langCode => $composableBuilder(
    column: $table.langCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TranslationCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $TranslationCacheTable> {
  $$TranslationCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get langCode =>
      $composableBuilder(column: $table.langCode, builder: (column) => column);

  GeneratedColumn<String> get wordLower =>
      $composableBuilder(column: $table.wordLower, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get translation => $composableBuilder(
    column: $table.translation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TranslationCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TranslationCacheTable,
          TranslationCacheRow,
          $$TranslationCacheTableFilterComposer,
          $$TranslationCacheTableOrderingComposer,
          $$TranslationCacheTableAnnotationComposer,
          $$TranslationCacheTableCreateCompanionBuilder,
          $$TranslationCacheTableUpdateCompanionBuilder,
          (
            TranslationCacheRow,
            BaseReferences<
              _$AppDatabase,
              $TranslationCacheTable,
              TranslationCacheRow
            >,
          ),
          TranslationCacheRow,
          PrefetchHooks Function()
        > {
  $$TranslationCacheTableTableManager(
    _$AppDatabase db,
    $TranslationCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TranslationCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TranslationCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TranslationCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> langCode = const Value.absent(),
                Value<String> wordLower = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> translation = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TranslationCacheCompanion(
                langCode: langCode,
                wordLower: wordLower,
                word: word,
                translation: translation,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String langCode,
                required String wordLower,
                required String word,
                required String translation,
                Value<String> source = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => TranslationCacheCompanion.insert(
                langCode: langCode,
                wordLower: wordLower,
                word: word,
                translation: translation,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TranslationCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TranslationCacheTable,
      TranslationCacheRow,
      $$TranslationCacheTableFilterComposer,
      $$TranslationCacheTableOrderingComposer,
      $$TranslationCacheTableAnnotationComposer,
      $$TranslationCacheTableCreateCompanionBuilder,
      $$TranslationCacheTableUpdateCompanionBuilder,
      (
        TranslationCacheRow,
        BaseReferences<
          _$AppDatabase,
          $TranslationCacheTable,
          TranslationCacheRow
        >,
      ),
      TranslationCacheRow,
      PrefetchHooks Function()
    >;
typedef $$GrammarLessonsTableCreateCompanionBuilder =
    GrammarLessonsCompanion Function({
      required String id,
      required String category,
      required String title,
      required String summary,
      required String searchText,
      Value<int> orderIndex,
      required String contentJson,
      Value<int> rowid,
    });
typedef $$GrammarLessonsTableUpdateCompanionBuilder =
    GrammarLessonsCompanion Function({
      Value<String> id,
      Value<String> category,
      Value<String> title,
      Value<String> summary,
      Value<String> searchText,
      Value<int> orderIndex,
      Value<String> contentJson,
      Value<int> rowid,
    });

class $$GrammarLessonsTableFilterComposer
    extends Composer<_$AppDatabase, $GrammarLessonsTable> {
  $$GrammarLessonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GrammarLessonsTableOrderingComposer
    extends Composer<_$AppDatabase, $GrammarLessonsTable> {
  $$GrammarLessonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GrammarLessonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrammarLessonsTable> {
  $$GrammarLessonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => column,
  );
}

class $$GrammarLessonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrammarLessonsTable,
          GrammarLessonRow,
          $$GrammarLessonsTableFilterComposer,
          $$GrammarLessonsTableOrderingComposer,
          $$GrammarLessonsTableAnnotationComposer,
          $$GrammarLessonsTableCreateCompanionBuilder,
          $$GrammarLessonsTableUpdateCompanionBuilder,
          (
            GrammarLessonRow,
            BaseReferences<
              _$AppDatabase,
              $GrammarLessonsTable,
              GrammarLessonRow
            >,
          ),
          GrammarLessonRow,
          PrefetchHooks Function()
        > {
  $$GrammarLessonsTableTableManager(
    _$AppDatabase db,
    $GrammarLessonsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrammarLessonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrammarLessonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrammarLessonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> contentJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrammarLessonsCompanion(
                id: id,
                category: category,
                title: title,
                summary: summary,
                searchText: searchText,
                orderIndex: orderIndex,
                contentJson: contentJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String category,
                required String title,
                required String summary,
                required String searchText,
                Value<int> orderIndex = const Value.absent(),
                required String contentJson,
                Value<int> rowid = const Value.absent(),
              }) => GrammarLessonsCompanion.insert(
                id: id,
                category: category,
                title: title,
                summary: summary,
                searchText: searchText,
                orderIndex: orderIndex,
                contentJson: contentJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GrammarLessonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrammarLessonsTable,
      GrammarLessonRow,
      $$GrammarLessonsTableFilterComposer,
      $$GrammarLessonsTableOrderingComposer,
      $$GrammarLessonsTableAnnotationComposer,
      $$GrammarLessonsTableCreateCompanionBuilder,
      $$GrammarLessonsTableUpdateCompanionBuilder,
      (
        GrammarLessonRow,
        BaseReferences<_$AppDatabase, $GrammarLessonsTable, GrammarLessonRow>,
      ),
      GrammarLessonRow,
      PrefetchHooks Function()
    >;
typedef $$GrammarProgressTableCreateCompanionBuilder =
    GrammarProgressCompanion Function({
      required String lessonId,
      Value<int> status,
      Value<double> scrollProgress,
      Value<DateTime?> lastViewedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$GrammarProgressTableUpdateCompanionBuilder =
    GrammarProgressCompanion Function({
      Value<String> lessonId,
      Value<int> status,
      Value<double> scrollProgress,
      Value<DateTime?> lastViewedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$GrammarProgressTableFilterComposer
    extends Composer<_$AppDatabase, $GrammarProgressTable> {
  $$GrammarProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get scrollProgress => $composableBuilder(
    column: $table.scrollProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GrammarProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $GrammarProgressTable> {
  $$GrammarProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get scrollProgress => $composableBuilder(
    column: $table.scrollProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GrammarProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrammarProgressTable> {
  $$GrammarProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get scrollProgress => $composableBuilder(
    column: $table.scrollProgress,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$GrammarProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrammarProgressTable,
          GrammarProgressRow,
          $$GrammarProgressTableFilterComposer,
          $$GrammarProgressTableOrderingComposer,
          $$GrammarProgressTableAnnotationComposer,
          $$GrammarProgressTableCreateCompanionBuilder,
          $$GrammarProgressTableUpdateCompanionBuilder,
          (
            GrammarProgressRow,
            BaseReferences<
              _$AppDatabase,
              $GrammarProgressTable,
              GrammarProgressRow
            >,
          ),
          GrammarProgressRow,
          PrefetchHooks Function()
        > {
  $$GrammarProgressTableTableManager(
    _$AppDatabase db,
    $GrammarProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrammarProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrammarProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrammarProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lessonId = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<double> scrollProgress = const Value.absent(),
                Value<DateTime?> lastViewedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrammarProgressCompanion(
                lessonId: lessonId,
                status: status,
                scrollProgress: scrollProgress,
                lastViewedAt: lastViewedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lessonId,
                Value<int> status = const Value.absent(),
                Value<double> scrollProgress = const Value.absent(),
                Value<DateTime?> lastViewedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrammarProgressCompanion.insert(
                lessonId: lessonId,
                status: status,
                scrollProgress: scrollProgress,
                lastViewedAt: lastViewedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GrammarProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrammarProgressTable,
      GrammarProgressRow,
      $$GrammarProgressTableFilterComposer,
      $$GrammarProgressTableOrderingComposer,
      $$GrammarProgressTableAnnotationComposer,
      $$GrammarProgressTableCreateCompanionBuilder,
      $$GrammarProgressTableUpdateCompanionBuilder,
      (
        GrammarProgressRow,
        BaseReferences<
          _$AppDatabase,
          $GrammarProgressTable,
          GrammarProgressRow
        >,
      ),
      GrammarProgressRow,
      PrefetchHooks Function()
    >;
typedef $$GrammarFavoritesTableCreateCompanionBuilder =
    GrammarFavoritesCompanion Function({
      required String lessonId,
      required String title,
      required String category,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$GrammarFavoritesTableUpdateCompanionBuilder =
    GrammarFavoritesCompanion Function({
      Value<String> lessonId,
      Value<String> title,
      Value<String> category,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$GrammarFavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $GrammarFavoritesTable> {
  $$GrammarFavoritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GrammarFavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $GrammarFavoritesTable> {
  $$GrammarFavoritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GrammarFavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrammarFavoritesTable> {
  $$GrammarFavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$GrammarFavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrammarFavoritesTable,
          GrammarFavoriteRow,
          $$GrammarFavoritesTableFilterComposer,
          $$GrammarFavoritesTableOrderingComposer,
          $$GrammarFavoritesTableAnnotationComposer,
          $$GrammarFavoritesTableCreateCompanionBuilder,
          $$GrammarFavoritesTableUpdateCompanionBuilder,
          (
            GrammarFavoriteRow,
            BaseReferences<
              _$AppDatabase,
              $GrammarFavoritesTable,
              GrammarFavoriteRow
            >,
          ),
          GrammarFavoriteRow,
          PrefetchHooks Function()
        > {
  $$GrammarFavoritesTableTableManager(
    _$AppDatabase db,
    $GrammarFavoritesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrammarFavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrammarFavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrammarFavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> lessonId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrammarFavoritesCompanion(
                lessonId: lessonId,
                title: title,
                category: category,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String lessonId,
                required String title,
                required String category,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => GrammarFavoritesCompanion.insert(
                lessonId: lessonId,
                title: title,
                category: category,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GrammarFavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrammarFavoritesTable,
      GrammarFavoriteRow,
      $$GrammarFavoritesTableFilterComposer,
      $$GrammarFavoritesTableOrderingComposer,
      $$GrammarFavoritesTableAnnotationComposer,
      $$GrammarFavoritesTableCreateCompanionBuilder,
      $$GrammarFavoritesTableUpdateCompanionBuilder,
      (
        GrammarFavoriteRow,
        BaseReferences<
          _$AppDatabase,
          $GrammarFavoritesTable,
          GrammarFavoriteRow
        >,
      ),
      GrammarFavoriteRow,
      PrefetchHooks Function()
    >;
typedef $$GrammarTopicsTableCreateCompanionBuilder =
    GrammarTopicsCompanion Function({
      required String id,
      Value<String?> parentId,
      required String title,
      Value<String?> subtitle,
      Value<int> orderIndex,
      Value<bool> isLeaf,
      Value<String> searchText,
      Value<String?> contentJson,
      Value<int> rowid,
    });
typedef $$GrammarTopicsTableUpdateCompanionBuilder =
    GrammarTopicsCompanion Function({
      Value<String> id,
      Value<String?> parentId,
      Value<String> title,
      Value<String?> subtitle,
      Value<int> orderIndex,
      Value<bool> isLeaf,
      Value<String> searchText,
      Value<String?> contentJson,
      Value<int> rowid,
    });

class $$GrammarTopicsTableFilterComposer
    extends Composer<_$AppDatabase, $GrammarTopicsTable> {
  $$GrammarTopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isLeaf => $composableBuilder(
    column: $table.isLeaf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GrammarTopicsTableOrderingComposer
    extends Composer<_$AppDatabase, $GrammarTopicsTable> {
  $$GrammarTopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isLeaf => $composableBuilder(
    column: $table.isLeaf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GrammarTopicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrammarTopicsTable> {
  $$GrammarTopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isLeaf =>
      $composableBuilder(column: $table.isLeaf, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => column,
  );
}

class $$GrammarTopicsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrammarTopicsTable,
          GrammarTopicRow,
          $$GrammarTopicsTableFilterComposer,
          $$GrammarTopicsTableOrderingComposer,
          $$GrammarTopicsTableAnnotationComposer,
          $$GrammarTopicsTableCreateCompanionBuilder,
          $$GrammarTopicsTableUpdateCompanionBuilder,
          (
            GrammarTopicRow,
            BaseReferences<_$AppDatabase, $GrammarTopicsTable, GrammarTopicRow>,
          ),
          GrammarTopicRow,
          PrefetchHooks Function()
        > {
  $$GrammarTopicsTableTableManager(_$AppDatabase db, $GrammarTopicsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrammarTopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrammarTopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrammarTopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> isLeaf = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<String?> contentJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrammarTopicsCompanion(
                id: id,
                parentId: parentId,
                title: title,
                subtitle: subtitle,
                orderIndex: orderIndex,
                isLeaf: isLeaf,
                searchText: searchText,
                contentJson: contentJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                required String title,
                Value<String?> subtitle = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> isLeaf = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<String?> contentJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrammarTopicsCompanion.insert(
                id: id,
                parentId: parentId,
                title: title,
                subtitle: subtitle,
                orderIndex: orderIndex,
                isLeaf: isLeaf,
                searchText: searchText,
                contentJson: contentJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GrammarTopicsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrammarTopicsTable,
      GrammarTopicRow,
      $$GrammarTopicsTableFilterComposer,
      $$GrammarTopicsTableOrderingComposer,
      $$GrammarTopicsTableAnnotationComposer,
      $$GrammarTopicsTableCreateCompanionBuilder,
      $$GrammarTopicsTableUpdateCompanionBuilder,
      (
        GrammarTopicRow,
        BaseReferences<_$AppDatabase, $GrammarTopicsTable, GrammarTopicRow>,
      ),
      GrammarTopicRow,
      PrefetchHooks Function()
    >;
typedef $$VocabularyListsTableCreateCompanionBuilder =
    VocabularyListsCompanion Function({
      required String id,
      required String title,
      Value<String?> subtitle,
      Value<int> orderIndex,
      Value<int> wordCount,
      Value<int> rowid,
    });
typedef $$VocabularyListsTableUpdateCompanionBuilder =
    VocabularyListsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> subtitle,
      Value<int> orderIndex,
      Value<int> wordCount,
      Value<int> rowid,
    });

class $$VocabularyListsTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyListsTable> {
  $$VocabularyListsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VocabularyListsTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyListsTable> {
  $$VocabularyListsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitle => $composableBuilder(
    column: $table.subtitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordCount => $composableBuilder(
    column: $table.wordCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VocabularyListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyListsTable> {
  $$VocabularyListsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wordCount =>
      $composableBuilder(column: $table.wordCount, builder: (column) => column);
}

class $$VocabularyListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabularyListsTable,
          VocabularyListRow,
          $$VocabularyListsTableFilterComposer,
          $$VocabularyListsTableOrderingComposer,
          $$VocabularyListsTableAnnotationComposer,
          $$VocabularyListsTableCreateCompanionBuilder,
          $$VocabularyListsTableUpdateCompanionBuilder,
          (
            VocabularyListRow,
            BaseReferences<
              _$AppDatabase,
              $VocabularyListsTable,
              VocabularyListRow
            >,
          ),
          VocabularyListRow,
          PrefetchHooks Function()
        > {
  $$VocabularyListsTableTableManager(
    _$AppDatabase db,
    $VocabularyListsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subtitle = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyListsCompanion(
                id: id,
                title: title,
                subtitle: subtitle,
                orderIndex: orderIndex,
                wordCount: wordCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> subtitle = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> wordCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyListsCompanion.insert(
                id: id,
                title: title,
                subtitle: subtitle,
                orderIndex: orderIndex,
                wordCount: wordCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VocabularyListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabularyListsTable,
      VocabularyListRow,
      $$VocabularyListsTableFilterComposer,
      $$VocabularyListsTableOrderingComposer,
      $$VocabularyListsTableAnnotationComposer,
      $$VocabularyListsTableCreateCompanionBuilder,
      $$VocabularyListsTableUpdateCompanionBuilder,
      (
        VocabularyListRow,
        BaseReferences<_$AppDatabase, $VocabularyListsTable, VocabularyListRow>,
      ),
      VocabularyListRow,
      PrefetchHooks Function()
    >;
typedef $$VocabularyWordsTableCreateCompanionBuilder =
    VocabularyWordsCompanion Function({
      required String id,
      required String listId,
      required String word,
      required String wordLower,
      required String letter,
      Value<String?> ipa,
      required String urduMeaning,
      required String englishMeaning,
      Value<String?> partOfSpeech,
      Value<int> orderIndex,
      Value<String> searchText,
      Value<int> rowid,
    });
typedef $$VocabularyWordsTableUpdateCompanionBuilder =
    VocabularyWordsCompanion Function({
      Value<String> id,
      Value<String> listId,
      Value<String> word,
      Value<String> wordLower,
      Value<String> letter,
      Value<String?> ipa,
      Value<String> urduMeaning,
      Value<String> englishMeaning,
      Value<String?> partOfSpeech,
      Value<int> orderIndex,
      Value<String> searchText,
      Value<int> rowid,
    });

class $$VocabularyWordsTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyWordsTable> {
  $$VocabularyWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get letter => $composableBuilder(
    column: $table.letter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ipa => $composableBuilder(
    column: $table.ipa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get urduMeaning => $composableBuilder(
    column: $table.urduMeaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get englishMeaning => $composableBuilder(
    column: $table.englishMeaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VocabularyWordsTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyWordsTable> {
  $$VocabularyWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listId => $composableBuilder(
    column: $table.listId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordLower => $composableBuilder(
    column: $table.wordLower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get letter => $composableBuilder(
    column: $table.letter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ipa => $composableBuilder(
    column: $table.ipa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get urduMeaning => $composableBuilder(
    column: $table.urduMeaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get englishMeaning => $composableBuilder(
    column: $table.englishMeaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VocabularyWordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyWordsTable> {
  $$VocabularyWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get listId =>
      $composableBuilder(column: $table.listId, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get wordLower =>
      $composableBuilder(column: $table.wordLower, builder: (column) => column);

  GeneratedColumn<String> get letter =>
      $composableBuilder(column: $table.letter, builder: (column) => column);

  GeneratedColumn<String> get ipa =>
      $composableBuilder(column: $table.ipa, builder: (column) => column);

  GeneratedColumn<String> get urduMeaning => $composableBuilder(
    column: $table.urduMeaning,
    builder: (column) => column,
  );

  GeneratedColumn<String> get englishMeaning => $composableBuilder(
    column: $table.englishMeaning,
    builder: (column) => column,
  );

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
    column: $table.partOfSpeech,
    builder: (column) => column,
  );

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );
}

class $$VocabularyWordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VocabularyWordsTable,
          VocabularyWordRow,
          $$VocabularyWordsTableFilterComposer,
          $$VocabularyWordsTableOrderingComposer,
          $$VocabularyWordsTableAnnotationComposer,
          $$VocabularyWordsTableCreateCompanionBuilder,
          $$VocabularyWordsTableUpdateCompanionBuilder,
          (
            VocabularyWordRow,
            BaseReferences<
              _$AppDatabase,
              $VocabularyWordsTable,
              VocabularyWordRow
            >,
          ),
          VocabularyWordRow,
          PrefetchHooks Function()
        > {
  $$VocabularyWordsTableTableManager(
    _$AppDatabase db,
    $VocabularyWordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> listId = const Value.absent(),
                Value<String> word = const Value.absent(),
                Value<String> wordLower = const Value.absent(),
                Value<String> letter = const Value.absent(),
                Value<String?> ipa = const Value.absent(),
                Value<String> urduMeaning = const Value.absent(),
                Value<String> englishMeaning = const Value.absent(),
                Value<String?> partOfSpeech = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyWordsCompanion(
                id: id,
                listId: listId,
                word: word,
                wordLower: wordLower,
                letter: letter,
                ipa: ipa,
                urduMeaning: urduMeaning,
                englishMeaning: englishMeaning,
                partOfSpeech: partOfSpeech,
                orderIndex: orderIndex,
                searchText: searchText,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String listId,
                required String word,
                required String wordLower,
                required String letter,
                Value<String?> ipa = const Value.absent(),
                required String urduMeaning,
                required String englishMeaning,
                Value<String?> partOfSpeech = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VocabularyWordsCompanion.insert(
                id: id,
                listId: listId,
                word: word,
                wordLower: wordLower,
                letter: letter,
                ipa: ipa,
                urduMeaning: urduMeaning,
                englishMeaning: englishMeaning,
                partOfSpeech: partOfSpeech,
                orderIndex: orderIndex,
                searchText: searchText,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VocabularyWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VocabularyWordsTable,
      VocabularyWordRow,
      $$VocabularyWordsTableFilterComposer,
      $$VocabularyWordsTableOrderingComposer,
      $$VocabularyWordsTableAnnotationComposer,
      $$VocabularyWordsTableCreateCompanionBuilder,
      $$VocabularyWordsTableUpdateCompanionBuilder,
      (
        VocabularyWordRow,
        BaseReferences<_$AppDatabase, $VocabularyWordsTable, VocabularyWordRow>,
      ),
      VocabularyWordRow,
      PrefetchHooks Function()
    >;
typedef $$StudyTasksTableCreateCompanionBuilder =
    StudyTasksCompanion Function({
      required String id,
      required String day,
      required String title,
      Value<String?> subject,
      Value<int?> startMinute,
      Value<int?> endMinute,
      Value<int> priority,
      Value<bool> completed,
      Value<int> orderIndex,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> completedAt,
      Value<String?> topic,
      Value<String?> notes,
      Value<int> status,
      Value<int?> durationMinutes,
      Value<String> kind,
      Value<int> rowid,
    });
typedef $$StudyTasksTableUpdateCompanionBuilder =
    StudyTasksCompanion Function({
      Value<String> id,
      Value<String> day,
      Value<String> title,
      Value<String?> subject,
      Value<int?> startMinute,
      Value<int?> endMinute,
      Value<int> priority,
      Value<bool> completed,
      Value<int> orderIndex,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> completedAt,
      Value<String?> topic,
      Value<String?> notes,
      Value<int> status,
      Value<int?> durationMinutes,
      Value<String> kind,
      Value<int> rowid,
    });

class $$StudyTasksTableFilterComposer
    extends Composer<_$AppDatabase, $StudyTasksTable> {
  $$StudyTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudyTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $StudyTasksTable> {
  $$StudyTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudyTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudyTasksTable> {
  $$StudyTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinute =>
      $composableBuilder(column: $table.endMinute, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);
}

class $$StudyTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudyTasksTable,
          StudyTaskRow,
          $$StudyTasksTableFilterComposer,
          $$StudyTasksTableOrderingComposer,
          $$StudyTasksTableAnnotationComposer,
          $$StudyTasksTableCreateCompanionBuilder,
          $$StudyTasksTableUpdateCompanionBuilder,
          (
            StudyTaskRow,
            BaseReferences<_$AppDatabase, $StudyTasksTable, StudyTaskRow>,
          ),
          StudyTaskRow,
          PrefetchHooks Function()
        > {
  $$StudyTasksTableTableManager(_$AppDatabase db, $StudyTasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyTasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<int?> startMinute = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudyTasksCompanion(
                id: id,
                day: day,
                title: title,
                subject: subject,
                startMinute: startMinute,
                endMinute: endMinute,
                priority: priority,
                completed: completed,
                orderIndex: orderIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                topic: topic,
                notes: notes,
                status: status,
                durationMinutes: durationMinutes,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String day,
                required String title,
                Value<String?> subject = const Value.absent(),
                Value<int?> startMinute = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int?> durationMinutes = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudyTasksCompanion.insert(
                id: id,
                day: day,
                title: title,
                subject: subject,
                startMinute: startMinute,
                endMinute: endMinute,
                priority: priority,
                completed: completed,
                orderIndex: orderIndex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                completedAt: completedAt,
                topic: topic,
                notes: notes,
                status: status,
                durationMinutes: durationMinutes,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudyTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudyTasksTable,
      StudyTaskRow,
      $$StudyTasksTableFilterComposer,
      $$StudyTasksTableOrderingComposer,
      $$StudyTasksTableAnnotationComposer,
      $$StudyTasksTableCreateCompanionBuilder,
      $$StudyTasksTableUpdateCompanionBuilder,
      (
        StudyTaskRow,
        BaseReferences<_$AppDatabase, $StudyTasksTable, StudyTaskRow>,
      ),
      StudyTaskRow,
      PrefetchHooks Function()
    >;
typedef $$StudyGoalsTableCreateCompanionBuilder =
    StudyGoalsCompanion Function({
      required String id,
      required String day,
      required String title,
      Value<String> type,
      Value<int> targetCount,
      Value<int> currentCount,
      Value<String?> unit,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StudyGoalsTableUpdateCompanionBuilder =
    StudyGoalsCompanion Function({
      Value<String> id,
      Value<String> day,
      Value<String> title,
      Value<String> type,
      Value<int> targetCount,
      Value<int> currentCount,
      Value<String?> unit,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StudyGoalsTableFilterComposer
    extends Composer<_$AppDatabase, $StudyGoalsTable> {
  $$StudyGoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetCount => $composableBuilder(
    column: $table.targetCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudyGoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudyGoalsTable> {
  $$StudyGoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetCount => $composableBuilder(
    column: $table.targetCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudyGoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudyGoalsTable> {
  $$StudyGoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get targetCount => $composableBuilder(
    column: $table.targetCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StudyGoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudyGoalsTable,
          StudyGoalRow,
          $$StudyGoalsTableFilterComposer,
          $$StudyGoalsTableOrderingComposer,
          $$StudyGoalsTableAnnotationComposer,
          $$StudyGoalsTableCreateCompanionBuilder,
          $$StudyGoalsTableUpdateCompanionBuilder,
          (
            StudyGoalRow,
            BaseReferences<_$AppDatabase, $StudyGoalsTable, StudyGoalRow>,
          ),
          StudyGoalRow,
          PrefetchHooks Function()
        > {
  $$StudyGoalsTableTableManager(_$AppDatabase db, $StudyGoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyGoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyGoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyGoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> targetCount = const Value.absent(),
                Value<int> currentCount = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudyGoalsCompanion(
                id: id,
                day: day,
                title: title,
                type: type,
                targetCount: targetCount,
                currentCount: currentCount,
                unit: unit,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String day,
                required String title,
                Value<String> type = const Value.absent(),
                Value<int> targetCount = const Value.absent(),
                Value<int> currentCount = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StudyGoalsCompanion.insert(
                id: id,
                day: day,
                title: title,
                type: type,
                targetCount: targetCount,
                currentCount: currentCount,
                unit: unit,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudyGoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudyGoalsTable,
      StudyGoalRow,
      $$StudyGoalsTableFilterComposer,
      $$StudyGoalsTableOrderingComposer,
      $$StudyGoalsTableAnnotationComposer,
      $$StudyGoalsTableCreateCompanionBuilder,
      $$StudyGoalsTableUpdateCompanionBuilder,
      (
        StudyGoalRow,
        BaseReferences<_$AppDatabase, $StudyGoalsTable, StudyGoalRow>,
      ),
      StudyGoalRow,
      PrefetchHooks Function()
    >;
typedef $$StudySessionsTableCreateCompanionBuilder =
    StudySessionsCompanion Function({
      required String id,
      required String day,
      required DateTime startedAt,
      required int durationMinutes,
      Value<String> kind,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$StudySessionsTableUpdateCompanionBuilder =
    StudySessionsCompanion Function({
      Value<String> id,
      Value<String> day,
      Value<DateTime> startedAt,
      Value<int> durationMinutes,
      Value<String> kind,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$StudySessionsTableFilterComposer
    extends Composer<_$AppDatabase, $StudySessionsTable> {
  $$StudySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudySessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudySessionsTable> {
  $$StudySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudySessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudySessionsTable> {
  $$StudySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StudySessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudySessionsTable,
          StudySessionRow,
          $$StudySessionsTableFilterComposer,
          $$StudySessionsTableOrderingComposer,
          $$StudySessionsTableAnnotationComposer,
          $$StudySessionsTableCreateCompanionBuilder,
          $$StudySessionsTableUpdateCompanionBuilder,
          (
            StudySessionRow,
            BaseReferences<_$AppDatabase, $StudySessionsTable, StudySessionRow>,
          ),
          StudySessionRow,
          PrefetchHooks Function()
        > {
  $$StudySessionsTableTableManager(_$AppDatabase db, $StudySessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudySessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudySessionsCompanion(
                id: id,
                day: day,
                startedAt: startedAt,
                durationMinutes: durationMinutes,
                kind: kind,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String day,
                required DateTime startedAt,
                required int durationMinutes,
                Value<String> kind = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => StudySessionsCompanion.insert(
                id: id,
                day: day,
                startedAt: startedAt,
                durationMinutes: durationMinutes,
                kind: kind,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudySessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudySessionsTable,
      StudySessionRow,
      $$StudySessionsTableFilterComposer,
      $$StudySessionsTableOrderingComposer,
      $$StudySessionsTableAnnotationComposer,
      $$StudySessionsTableCreateCompanionBuilder,
      $$StudySessionsTableUpdateCompanionBuilder,
      (
        StudySessionRow,
        BaseReferences<_$AppDatabase, $StudySessionsTable, StudySessionRow>,
      ),
      StudySessionRow,
      PrefetchHooks Function()
    >;
typedef $$StudyTemplatesTableCreateCompanionBuilder =
    StudyTemplatesCompanion Function({
      required String id,
      required String name,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StudyTemplatesTableUpdateCompanionBuilder =
    StudyTemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StudyTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $StudyTemplatesTable> {
  $$StudyTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudyTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $StudyTemplatesTable> {
  $$StudyTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudyTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudyTemplatesTable> {
  $$StudyTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StudyTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudyTemplatesTable,
          StudyTemplateRow,
          $$StudyTemplatesTableFilterComposer,
          $$StudyTemplatesTableOrderingComposer,
          $$StudyTemplatesTableAnnotationComposer,
          $$StudyTemplatesTableCreateCompanionBuilder,
          $$StudyTemplatesTableUpdateCompanionBuilder,
          (
            StudyTemplateRow,
            BaseReferences<
              _$AppDatabase,
              $StudyTemplatesTable,
              StudyTemplateRow
            >,
          ),
          StudyTemplateRow,
          PrefetchHooks Function()
        > {
  $$StudyTemplatesTableTableManager(
    _$AppDatabase db,
    $StudyTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudyTemplatesCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StudyTemplatesCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudyTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudyTemplatesTable,
      StudyTemplateRow,
      $$StudyTemplatesTableFilterComposer,
      $$StudyTemplatesTableOrderingComposer,
      $$StudyTemplatesTableAnnotationComposer,
      $$StudyTemplatesTableCreateCompanionBuilder,
      $$StudyTemplatesTableUpdateCompanionBuilder,
      (
        StudyTemplateRow,
        BaseReferences<_$AppDatabase, $StudyTemplatesTable, StudyTemplateRow>,
      ),
      StudyTemplateRow,
      PrefetchHooks Function()
    >;
typedef $$StudyTemplateItemsTableCreateCompanionBuilder =
    StudyTemplateItemsCompanion Function({
      required String id,
      required String templateId,
      Value<String> kind,
      required String title,
      Value<String?> subject,
      Value<String?> topic,
      Value<int?> startMinute,
      Value<int?> endMinute,
      Value<int> priority,
      Value<String?> notes,
      Value<int> orderIndex,
      Value<int> rowid,
    });
typedef $$StudyTemplateItemsTableUpdateCompanionBuilder =
    StudyTemplateItemsCompanion Function({
      Value<String> id,
      Value<String> templateId,
      Value<String> kind,
      Value<String> title,
      Value<String?> subject,
      Value<String?> topic,
      Value<int?> startMinute,
      Value<int?> endMinute,
      Value<int> priority,
      Value<String?> notes,
      Value<int> orderIndex,
      Value<int> rowid,
    });

class $$StudyTemplateItemsTableFilterComposer
    extends Composer<_$AppDatabase, $StudyTemplateItemsTable> {
  $$StudyTemplateItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudyTemplateItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudyTemplateItemsTable> {
  $$StudyTemplateItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMinute => $composableBuilder(
    column: $table.endMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudyTemplateItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudyTemplateItemsTable> {
  $$StudyTemplateItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<int> get startMinute => $composableBuilder(
    column: $table.startMinute,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endMinute =>
      $composableBuilder(column: $table.endMinute, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );
}

class $$StudyTemplateItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudyTemplateItemsTable,
          StudyTemplateItemRow,
          $$StudyTemplateItemsTableFilterComposer,
          $$StudyTemplateItemsTableOrderingComposer,
          $$StudyTemplateItemsTableAnnotationComposer,
          $$StudyTemplateItemsTableCreateCompanionBuilder,
          $$StudyTemplateItemsTableUpdateCompanionBuilder,
          (
            StudyTemplateItemRow,
            BaseReferences<
              _$AppDatabase,
              $StudyTemplateItemsTable,
              StudyTemplateItemRow
            >,
          ),
          StudyTemplateItemRow,
          PrefetchHooks Function()
        > {
  $$StudyTemplateItemsTableTableManager(
    _$AppDatabase db,
    $StudyTemplateItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudyTemplateItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudyTemplateItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudyTemplateItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<int?> startMinute = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudyTemplateItemsCompanion(
                id: id,
                templateId: templateId,
                kind: kind,
                title: title,
                subject: subject,
                topic: topic,
                startMinute: startMinute,
                endMinute: endMinute,
                priority: priority,
                notes: notes,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateId,
                Value<String> kind = const Value.absent(),
                required String title,
                Value<String?> subject = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<int?> startMinute = const Value.absent(),
                Value<int?> endMinute = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudyTemplateItemsCompanion.insert(
                id: id,
                templateId: templateId,
                kind: kind,
                title: title,
                subject: subject,
                topic: topic,
                startMinute: startMinute,
                endMinute: endMinute,
                priority: priority,
                notes: notes,
                orderIndex: orderIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudyTemplateItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudyTemplateItemsTable,
      StudyTemplateItemRow,
      $$StudyTemplateItemsTableFilterComposer,
      $$StudyTemplateItemsTableOrderingComposer,
      $$StudyTemplateItemsTableAnnotationComposer,
      $$StudyTemplateItemsTableCreateCompanionBuilder,
      $$StudyTemplateItemsTableUpdateCompanionBuilder,
      (
        StudyTemplateItemRow,
        BaseReferences<
          _$AppDatabase,
          $StudyTemplateItemsTable,
          StudyTemplateItemRow
        >,
      ),
      StudyTemplateItemRow,
      PrefetchHooks Function()
    >;
typedef $$StudySubjectsTableCreateCompanionBuilder =
    StudySubjectsCompanion Function({
      required String id,
      required String name,
      required String nameLower,
      required int color,
      Value<bool> archived,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StudySubjectsTableUpdateCompanionBuilder =
    StudySubjectsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> nameLower,
      Value<int> color,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StudySubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $StudySubjectsTable> {
  $$StudySubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nameLower => $composableBuilder(
    column: $table.nameLower,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StudySubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $StudySubjectsTable> {
  $$StudySubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nameLower => $composableBuilder(
    column: $table.nameLower,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StudySubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StudySubjectsTable> {
  $$StudySubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get nameLower =>
      $composableBuilder(column: $table.nameLower, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StudySubjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StudySubjectsTable,
          StudySubjectRow,
          $$StudySubjectsTableFilterComposer,
          $$StudySubjectsTableOrderingComposer,
          $$StudySubjectsTableAnnotationComposer,
          $$StudySubjectsTableCreateCompanionBuilder,
          $$StudySubjectsTableUpdateCompanionBuilder,
          (
            StudySubjectRow,
            BaseReferences<_$AppDatabase, $StudySubjectsTable, StudySubjectRow>,
          ),
          StudySubjectRow,
          PrefetchHooks Function()
        > {
  $$StudySubjectsTableTableManager(_$AppDatabase db, $StudySubjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StudySubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StudySubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StudySubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> nameLower = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StudySubjectsCompanion(
                id: id,
                name: name,
                nameLower: nameLower,
                color: color,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String nameLower,
                required int color,
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StudySubjectsCompanion.insert(
                id: id,
                name: name,
                nameLower: nameLower,
                color: color,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StudySubjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StudySubjectsTable,
      StudySubjectRow,
      $$StudySubjectsTableFilterComposer,
      $$StudySubjectsTableOrderingComposer,
      $$StudySubjectsTableAnnotationComposer,
      $$StudySubjectsTableCreateCompanionBuilder,
      $$StudySubjectsTableUpdateCompanionBuilder,
      (
        StudySubjectRow,
        BaseReferences<_$AppDatabase, $StudySubjectsTable, StudySubjectRow>,
      ),
      StudySubjectRow,
      PrefetchHooks Function()
    >;
typedef $$DecksTableCreateCompanionBuilder =
    DecksCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<String?> subject,
      Value<String?> topic,
      Value<int?> color,
      Value<int?> icon,
      Value<bool> archived,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DecksTableUpdateCompanionBuilder =
    DecksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<String?> subject,
      Value<String?> topic,
      Value<int?> color,
      Value<int?> icon,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DecksTableFilterComposer extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DecksTableOrderingComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DecksTable,
          DeckRow,
          $$DecksTableFilterComposer,
          $$DecksTableOrderingComposer,
          $$DecksTableAnnotationComposer,
          $$DecksTableCreateCompanionBuilder,
          $$DecksTableUpdateCompanionBuilder,
          (DeckRow, BaseReferences<_$AppDatabase, $DecksTable, DeckRow>),
          DeckRow,
          PrefetchHooks Function()
        > {
  $$DecksTableTableManager(_$AppDatabase db, $DecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<int?> icon = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DecksCompanion(
                id: id,
                name: name,
                description: description,
                subject: subject,
                topic: topic,
                color: color,
                icon: icon,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<int?> icon = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DecksCompanion.insert(
                id: id,
                name: name,
                description: description,
                subject: subject,
                topic: topic,
                color: color,
                icon: icon,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DecksTable,
      DeckRow,
      $$DecksTableFilterComposer,
      $$DecksTableOrderingComposer,
      $$DecksTableAnnotationComposer,
      $$DecksTableCreateCompanionBuilder,
      $$DecksTableUpdateCompanionBuilder,
      (DeckRow, BaseReferences<_$AppDatabase, $DecksTable, DeckRow>),
      DeckRow,
      PrefetchHooks Function()
    >;
typedef $$FlashcardsTableCreateCompanionBuilder =
    FlashcardsCompanion Function({
      required String id,
      required String deckId,
      required String front,
      required String back,
      Value<String?> subject,
      Value<String?> topic,
      Value<String?> tags,
      Value<String?> notes,
      Value<int> difficulty,
      Value<bool> bookmarked,
      Value<bool> favorite,
      Value<int> reviewState,
      Value<DateTime?> dueAt,
      Value<int> intervalDays,
      Value<double> easeFactor,
      Value<int> repetitions,
      Value<int> lapses,
      Value<DateTime?> lastReviewedAt,
      Value<String> searchText,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$FlashcardsTableUpdateCompanionBuilder =
    FlashcardsCompanion Function({
      Value<String> id,
      Value<String> deckId,
      Value<String> front,
      Value<String> back,
      Value<String?> subject,
      Value<String?> topic,
      Value<String?> tags,
      Value<String?> notes,
      Value<int> difficulty,
      Value<bool> bookmarked,
      Value<bool> favorite,
      Value<int> reviewState,
      Value<DateTime?> dueAt,
      Value<int> intervalDays,
      Value<double> easeFactor,
      Value<int> repetitions,
      Value<int> lapses,
      Value<DateTime?> lastReviewedAt,
      Value<String> searchText,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$FlashcardsTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bookmarked => $composableBuilder(
    column: $table.bookmarked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FlashcardsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bookmarked => $composableBuilder(
    column: $table.bookmarked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get favorite => $composableBuilder(
    column: $table.favorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FlashcardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => column);

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bookmarked => $composableBuilder(
    column: $table.bookmarked,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<int> get reviewState => $composableBuilder(
    column: $table.reviewState,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FlashcardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardsTable,
          FlashcardRow,
          $$FlashcardsTableFilterComposer,
          $$FlashcardsTableOrderingComposer,
          $$FlashcardsTableAnnotationComposer,
          $$FlashcardsTableCreateCompanionBuilder,
          $$FlashcardsTableUpdateCompanionBuilder,
          (
            FlashcardRow,
            BaseReferences<_$AppDatabase, $FlashcardsTable, FlashcardRow>,
          ),
          FlashcardRow,
          PrefetchHooks Function()
        > {
  $$FlashcardsTableTableManager(_$AppDatabase db, $FlashcardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> front = const Value.absent(),
                Value<String> back = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<bool> bookmarked = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<int> reviewState = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlashcardsCompanion(
                id: id,
                deckId: deckId,
                front: front,
                back: back,
                subject: subject,
                topic: topic,
                tags: tags,
                notes: notes,
                difficulty: difficulty,
                bookmarked: bookmarked,
                favorite: favorite,
                reviewState: reviewState,
                dueAt: dueAt,
                intervalDays: intervalDays,
                easeFactor: easeFactor,
                repetitions: repetitions,
                lapses: lapses,
                lastReviewedAt: lastReviewedAt,
                searchText: searchText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String front,
                required String back,
                Value<String?> subject = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<bool> bookmarked = const Value.absent(),
                Value<bool> favorite = const Value.absent(),
                Value<int> reviewState = const Value.absent(),
                Value<DateTime?> dueAt = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FlashcardsCompanion.insert(
                id: id,
                deckId: deckId,
                front: front,
                back: back,
                subject: subject,
                topic: topic,
                tags: tags,
                notes: notes,
                difficulty: difficulty,
                bookmarked: bookmarked,
                favorite: favorite,
                reviewState: reviewState,
                dueAt: dueAt,
                intervalDays: intervalDays,
                easeFactor: easeFactor,
                repetitions: repetitions,
                lapses: lapses,
                lastReviewedAt: lastReviewedAt,
                searchText: searchText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FlashcardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardsTable,
      FlashcardRow,
      $$FlashcardsTableFilterComposer,
      $$FlashcardsTableOrderingComposer,
      $$FlashcardsTableAnnotationComposer,
      $$FlashcardsTableCreateCompanionBuilder,
      $$FlashcardsTableUpdateCompanionBuilder,
      (
        FlashcardRow,
        BaseReferences<_$AppDatabase, $FlashcardsTable, FlashcardRow>,
      ),
      FlashcardRow,
      PrefetchHooks Function()
    >;
typedef $$ReviewLogsTableCreateCompanionBuilder =
    ReviewLogsCompanion Function({
      required String id,
      required String cardId,
      required String deckId,
      required int rating,
      required String day,
      required DateTime reviewedAt,
      Value<int> durationMs,
      Value<int> rowid,
    });
typedef $$ReviewLogsTableUpdateCompanionBuilder =
    ReviewLogsCompanion Function({
      Value<String> id,
      Value<String> cardId,
      Value<String> deckId,
      Value<int> rating,
      Value<String> day,
      Value<DateTime> reviewedAt,
      Value<int> durationMs,
      Value<int> rowid,
    });

class $$ReviewLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardId => $composableBuilder(
    column: $table.cardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deckId => $composableBuilder(
    column: $table.deckId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewLogsTable> {
  $$ReviewLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cardId =>
      $composableBuilder(column: $table.cardId, builder: (column) => column);

  GeneratedColumn<String> get deckId =>
      $composableBuilder(column: $table.deckId, builder: (column) => column);

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );
}

class $$ReviewLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewLogsTable,
          ReviewLogRow,
          $$ReviewLogsTableFilterComposer,
          $$ReviewLogsTableOrderingComposer,
          $$ReviewLogsTableAnnotationComposer,
          $$ReviewLogsTableCreateCompanionBuilder,
          $$ReviewLogsTableUpdateCompanionBuilder,
          (
            ReviewLogRow,
            BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLogRow>,
          ),
          ReviewLogRow,
          PrefetchHooks Function()
        > {
  $$ReviewLogsTableTableManager(_$AppDatabase db, $ReviewLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogsCompanion(
                id: id,
                cardId: cardId,
                deckId: deckId,
                rating: rating,
                day: day,
                reviewedAt: reviewedAt,
                durationMs: durationMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cardId,
                required String deckId,
                required int rating,
                required String day,
                required DateTime reviewedAt,
                Value<int> durationMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewLogsCompanion.insert(
                id: id,
                cardId: cardId,
                deckId: deckId,
                rating: rating,
                day: day,
                reviewedAt: reviewedAt,
                durationMs: durationMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewLogsTable,
      ReviewLogRow,
      $$ReviewLogsTableFilterComposer,
      $$ReviewLogsTableOrderingComposer,
      $$ReviewLogsTableAnnotationComposer,
      $$ReviewLogsTableCreateCompanionBuilder,
      $$ReviewLogsTableUpdateCompanionBuilder,
      (
        ReviewLogRow,
        BaseReferences<_$AppDatabase, $ReviewLogsTable, ReviewLogRow>,
      ),
      ReviewLogRow,
      PrefetchHooks Function()
    >;
typedef $$QuizBanksTableCreateCompanionBuilder =
    QuizBanksCompanion Function({
      required String id,
      required String name,
      Value<String?> subject,
      Value<String?> topic,
      Value<String?> description,
      Value<int?> color,
      Value<String?> tags,
      Value<String?> version,
      Value<String> source,
      Value<String?> externalId,
      Value<String?> subjectId,
      Value<String?> topicId,
      Value<int> orderIndex,
      Value<bool> archived,
      Value<String> searchText,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$QuizBanksTableUpdateCompanionBuilder =
    QuizBanksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> subject,
      Value<String?> topic,
      Value<String?> description,
      Value<int?> color,
      Value<String?> tags,
      Value<String?> version,
      Value<String> source,
      Value<String?> externalId,
      Value<String?> subjectId,
      Value<String?> topicId,
      Value<int> orderIndex,
      Value<bool> archived,
      Value<String> searchText,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$QuizBanksTableFilterComposer
    extends Composer<_$AppDatabase, $QuizBanksTable> {
  $$QuizBanksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuizBanksTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizBanksTable> {
  $$QuizBanksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuizBanksTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizBanksTable> {
  $$QuizBanksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuizBanksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizBanksTable,
          QuizBankRow,
          $$QuizBanksTableFilterComposer,
          $$QuizBanksTableOrderingComposer,
          $$QuizBanksTableAnnotationComposer,
          $$QuizBanksTableCreateCompanionBuilder,
          $$QuizBanksTableUpdateCompanionBuilder,
          (
            QuizBankRow,
            BaseReferences<_$AppDatabase, $QuizBanksTable, QuizBankRow>,
          ),
          QuizBankRow,
          PrefetchHooks Function()
        > {
  $$QuizBanksTableTableManager(_$AppDatabase db, $QuizBanksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizBanksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizBanksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizBanksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> topicId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizBanksCompanion(
                id: id,
                name: name,
                subject: subject,
                topic: topic,
                description: description,
                color: color,
                tags: tags,
                version: version,
                source: source,
                externalId: externalId,
                subjectId: subjectId,
                topicId: topicId,
                orderIndex: orderIndex,
                archived: archived,
                searchText: searchText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> subject = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> topicId = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuizBanksCompanion.insert(
                id: id,
                name: name,
                subject: subject,
                topic: topic,
                description: description,
                color: color,
                tags: tags,
                version: version,
                source: source,
                externalId: externalId,
                subjectId: subjectId,
                topicId: topicId,
                orderIndex: orderIndex,
                archived: archived,
                searchText: searchText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuizBanksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizBanksTable,
      QuizBankRow,
      $$QuizBanksTableFilterComposer,
      $$QuizBanksTableOrderingComposer,
      $$QuizBanksTableAnnotationComposer,
      $$QuizBanksTableCreateCompanionBuilder,
      $$QuizBanksTableUpdateCompanionBuilder,
      (
        QuizBankRow,
        BaseReferences<_$AppDatabase, $QuizBanksTable, QuizBankRow>,
      ),
      QuizBankRow,
      PrefetchHooks Function()
    >;
typedef $$QuizQuestionsTableCreateCompanionBuilder =
    QuizQuestionsCompanion Function({
      required String id,
      required String bankId,
      Value<int> type,
      required String prompt,
      Value<String?> optionsJson,
      Value<String?> answerJson,
      Value<String?> explanation,
      Value<String?> subject,
      Value<String?> topic,
      Value<String?> tags,
      Value<int> difficulty,
      Value<bool> bookmarked,
      Value<String?> externalId,
      Value<String?> subjectId,
      Value<String?> topicId,
      Value<String> searchText,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$QuizQuestionsTableUpdateCompanionBuilder =
    QuizQuestionsCompanion Function({
      Value<String> id,
      Value<String> bankId,
      Value<int> type,
      Value<String> prompt,
      Value<String?> optionsJson,
      Value<String?> answerJson,
      Value<String?> explanation,
      Value<String?> subject,
      Value<String?> topic,
      Value<String?> tags,
      Value<int> difficulty,
      Value<bool> bookmarked,
      Value<String?> externalId,
      Value<String?> subjectId,
      Value<String?> topicId,
      Value<String> searchText,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$QuizQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuizQuestionsTable> {
  $$QuizQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answerJson => $composableBuilder(
    column: $table.answerJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bookmarked => $composableBuilder(
    column: $table.bookmarked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuizQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizQuestionsTable> {
  $$QuizQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answerJson => $composableBuilder(
    column: $table.answerJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bookmarked => $composableBuilder(
    column: $table.bookmarked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topicId => $composableBuilder(
    column: $table.topicId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuizQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizQuestionsTable> {
  $$QuizQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bankId =>
      $composableBuilder(column: $table.bankId, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get optionsJson => $composableBuilder(
    column: $table.optionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answerJson => $composableBuilder(
    column: $table.answerJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bookmarked => $composableBuilder(
    column: $table.bookmarked,
    builder: (column) => column,
  );

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get topicId =>
      $composableBuilder(column: $table.topicId, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuizQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizQuestionsTable,
          QuizQuestionRow,
          $$QuizQuestionsTableFilterComposer,
          $$QuizQuestionsTableOrderingComposer,
          $$QuizQuestionsTableAnnotationComposer,
          $$QuizQuestionsTableCreateCompanionBuilder,
          $$QuizQuestionsTableUpdateCompanionBuilder,
          (
            QuizQuestionRow,
            BaseReferences<_$AppDatabase, $QuizQuestionsTable, QuizQuestionRow>,
          ),
          QuizQuestionRow,
          PrefetchHooks Function()
        > {
  $$QuizQuestionsTableTableManager(_$AppDatabase db, $QuizQuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> bankId = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String?> optionsJson = const Value.absent(),
                Value<String?> answerJson = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<bool> bookmarked = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> topicId = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizQuestionsCompanion(
                id: id,
                bankId: bankId,
                type: type,
                prompt: prompt,
                optionsJson: optionsJson,
                answerJson: answerJson,
                explanation: explanation,
                subject: subject,
                topic: topic,
                tags: tags,
                difficulty: difficulty,
                bookmarked: bookmarked,
                externalId: externalId,
                subjectId: subjectId,
                topicId: topicId,
                searchText: searchText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String bankId,
                Value<int> type = const Value.absent(),
                required String prompt,
                Value<String?> optionsJson = const Value.absent(),
                Value<String?> answerJson = const Value.absent(),
                Value<String?> explanation = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> topic = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<bool> bookmarked = const Value.absent(),
                Value<String?> externalId = const Value.absent(),
                Value<String?> subjectId = const Value.absent(),
                Value<String?> topicId = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuizQuestionsCompanion.insert(
                id: id,
                bankId: bankId,
                type: type,
                prompt: prompt,
                optionsJson: optionsJson,
                answerJson: answerJson,
                explanation: explanation,
                subject: subject,
                topic: topic,
                tags: tags,
                difficulty: difficulty,
                bookmarked: bookmarked,
                externalId: externalId,
                subjectId: subjectId,
                topicId: topicId,
                searchText: searchText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuizQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizQuestionsTable,
      QuizQuestionRow,
      $$QuizQuestionsTableFilterComposer,
      $$QuizQuestionsTableOrderingComposer,
      $$QuizQuestionsTableAnnotationComposer,
      $$QuizQuestionsTableCreateCompanionBuilder,
      $$QuizQuestionsTableUpdateCompanionBuilder,
      (
        QuizQuestionRow,
        BaseReferences<_$AppDatabase, $QuizQuestionsTable, QuizQuestionRow>,
      ),
      QuizQuestionRow,
      PrefetchHooks Function()
    >;
typedef $$QuizAttemptsTableCreateCompanionBuilder =
    QuizAttemptsCompanion Function({
      required String id,
      Value<String?> bankId,
      Value<int> mode,
      Value<String?> title,
      Value<int> totalQuestions,
      Value<int> correct,
      Value<int> wrong,
      Value<int> skipped,
      required DateTime startedAt,
      Value<DateTime?> finishedAt,
      Value<int> durationMs,
      Value<String> day,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$QuizAttemptsTableUpdateCompanionBuilder =
    QuizAttemptsCompanion Function({
      Value<String> id,
      Value<String?> bankId,
      Value<int> mode,
      Value<String?> title,
      Value<int> totalQuestions,
      Value<int> correct,
      Value<int> wrong,
      Value<int> skipped,
      Value<DateTime> startedAt,
      Value<DateTime?> finishedAt,
      Value<int> durationMs,
      Value<String> day,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$QuizAttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $QuizAttemptsTable> {
  $$QuizAttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wrong => $composableBuilder(
    column: $table.wrong,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuizAttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizAttemptsTable> {
  $$QuizAttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mode => $composableBuilder(
    column: $table.mode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wrong => $composableBuilder(
    column: $table.wrong,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuizAttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizAttemptsTable> {
  $$QuizAttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get bankId =>
      $composableBuilder(column: $table.bankId, builder: (column) => column);

  GeneratedColumn<int> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get wrong =>
      $composableBuilder(column: $table.wrong, builder: (column) => column);

  GeneratedColumn<int> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get finishedAt => $composableBuilder(
    column: $table.finishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QuizAttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizAttemptsTable,
          QuizAttemptRow,
          $$QuizAttemptsTableFilterComposer,
          $$QuizAttemptsTableOrderingComposer,
          $$QuizAttemptsTableAnnotationComposer,
          $$QuizAttemptsTableCreateCompanionBuilder,
          $$QuizAttemptsTableUpdateCompanionBuilder,
          (
            QuizAttemptRow,
            BaseReferences<_$AppDatabase, $QuizAttemptsTable, QuizAttemptRow>,
          ),
          QuizAttemptRow,
          PrefetchHooks Function()
        > {
  $$QuizAttemptsTableTableManager(_$AppDatabase db, $QuizAttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizAttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizAttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizAttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> bankId = const Value.absent(),
                Value<int> mode = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<int> wrong = const Value.absent(),
                Value<int> skipped = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizAttemptsCompanion(
                id: id,
                bankId: bankId,
                mode: mode,
                title: title,
                totalQuestions: totalQuestions,
                correct: correct,
                wrong: wrong,
                skipped: skipped,
                startedAt: startedAt,
                finishedAt: finishedAt,
                durationMs: durationMs,
                day: day,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> bankId = const Value.absent(),
                Value<int> mode = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int> correct = const Value.absent(),
                Value<int> wrong = const Value.absent(),
                Value<int> skipped = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> finishedAt = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> day = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => QuizAttemptsCompanion.insert(
                id: id,
                bankId: bankId,
                mode: mode,
                title: title,
                totalQuestions: totalQuestions,
                correct: correct,
                wrong: wrong,
                skipped: skipped,
                startedAt: startedAt,
                finishedAt: finishedAt,
                durationMs: durationMs,
                day: day,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuizAttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizAttemptsTable,
      QuizAttemptRow,
      $$QuizAttemptsTableFilterComposer,
      $$QuizAttemptsTableOrderingComposer,
      $$QuizAttemptsTableAnnotationComposer,
      $$QuizAttemptsTableCreateCompanionBuilder,
      $$QuizAttemptsTableUpdateCompanionBuilder,
      (
        QuizAttemptRow,
        BaseReferences<_$AppDatabase, $QuizAttemptsTable, QuizAttemptRow>,
      ),
      QuizAttemptRow,
      PrefetchHooks Function()
    >;
typedef $$QuizAttemptAnswersTableCreateCompanionBuilder =
    QuizAttemptAnswersCompanion Function({
      required String id,
      required String attemptId,
      required String questionId,
      Value<String?> givenJson,
      Value<bool> isCorrect,
      Value<bool> skipped,
      Value<String?> subject,
      Value<int> orderIndex,
      Value<int> timeMs,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$QuizAttemptAnswersTableUpdateCompanionBuilder =
    QuizAttemptAnswersCompanion Function({
      Value<String> id,
      Value<String> attemptId,
      Value<String> questionId,
      Value<String?> givenJson,
      Value<bool> isCorrect,
      Value<bool> skipped,
      Value<String?> subject,
      Value<int> orderIndex,
      Value<int> timeMs,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$QuizAttemptAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $QuizAttemptAnswersTable> {
  $$QuizAttemptAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get givenJson => $composableBuilder(
    column: $table.givenJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuizAttemptAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizAttemptAnswersTable> {
  $$QuizAttemptAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get givenJson => $composableBuilder(
    column: $table.givenJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCorrect => $composableBuilder(
    column: $table.isCorrect,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuizAttemptAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizAttemptAnswersTable> {
  $$QuizAttemptAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get givenJson =>
      $composableBuilder(column: $table.givenJson, builder: (column) => column);

  GeneratedColumn<bool> get isCorrect =>
      $composableBuilder(column: $table.isCorrect, builder: (column) => column);

  GeneratedColumn<bool> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeMs =>
      $composableBuilder(column: $table.timeMs, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QuizAttemptAnswersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizAttemptAnswersTable,
          QuizAnswerRow,
          $$QuizAttemptAnswersTableFilterComposer,
          $$QuizAttemptAnswersTableOrderingComposer,
          $$QuizAttemptAnswersTableAnnotationComposer,
          $$QuizAttemptAnswersTableCreateCompanionBuilder,
          $$QuizAttemptAnswersTableUpdateCompanionBuilder,
          (
            QuizAnswerRow,
            BaseReferences<
              _$AppDatabase,
              $QuizAttemptAnswersTable,
              QuizAnswerRow
            >,
          ),
          QuizAnswerRow,
          PrefetchHooks Function()
        > {
  $$QuizAttemptAnswersTableTableManager(
    _$AppDatabase db,
    $QuizAttemptAnswersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizAttemptAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizAttemptAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizAttemptAnswersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> attemptId = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String?> givenJson = const Value.absent(),
                Value<bool> isCorrect = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> timeMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizAttemptAnswersCompanion(
                id: id,
                attemptId: attemptId,
                questionId: questionId,
                givenJson: givenJson,
                isCorrect: isCorrect,
                skipped: skipped,
                subject: subject,
                orderIndex: orderIndex,
                timeMs: timeMs,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String attemptId,
                required String questionId,
                Value<String?> givenJson = const Value.absent(),
                Value<bool> isCorrect = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<int> timeMs = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => QuizAttemptAnswersCompanion.insert(
                id: id,
                attemptId: attemptId,
                questionId: questionId,
                givenJson: givenJson,
                isCorrect: isCorrect,
                skipped: skipped,
                subject: subject,
                orderIndex: orderIndex,
                timeMs: timeMs,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuizAttemptAnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizAttemptAnswersTable,
      QuizAnswerRow,
      $$QuizAttemptAnswersTableFilterComposer,
      $$QuizAttemptAnswersTableOrderingComposer,
      $$QuizAttemptAnswersTableAnnotationComposer,
      $$QuizAttemptAnswersTableCreateCompanionBuilder,
      $$QuizAttemptAnswersTableUpdateCompanionBuilder,
      (
        QuizAnswerRow,
        BaseReferences<_$AppDatabase, $QuizAttemptAnswersTable, QuizAnswerRow>,
      ),
      QuizAnswerRow,
      PrefetchHooks Function()
    >;
typedef $$QuizWrongAnswersTableCreateCompanionBuilder =
    QuizWrongAnswersCompanion Function({
      required String questionId,
      Value<String?> bankId,
      Value<String?> subject,
      Value<String?> lastGivenJson,
      Value<int> wrongCount,
      required DateTime lastWrongAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$QuizWrongAnswersTableUpdateCompanionBuilder =
    QuizWrongAnswersCompanion Function({
      Value<String> questionId,
      Value<String?> bankId,
      Value<String?> subject,
      Value<String?> lastGivenJson,
      Value<int> wrongCount,
      Value<DateTime> lastWrongAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$QuizWrongAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $QuizWrongAnswersTable> {
  $$QuizWrongAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastGivenJson => $composableBuilder(
    column: $table.lastGivenJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastWrongAt => $composableBuilder(
    column: $table.lastWrongAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuizWrongAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizWrongAnswersTable> {
  $$QuizWrongAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankId => $composableBuilder(
    column: $table.bankId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastGivenJson => $composableBuilder(
    column: $table.lastGivenJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastWrongAt => $composableBuilder(
    column: $table.lastWrongAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuizWrongAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizWrongAnswersTable> {
  $$QuizWrongAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bankId =>
      $composableBuilder(column: $table.bankId, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get lastGivenJson => $composableBuilder(
    column: $table.lastGivenJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastWrongAt => $composableBuilder(
    column: $table.lastWrongAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$QuizWrongAnswersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizWrongAnswersTable,
          QuizWrongRow,
          $$QuizWrongAnswersTableFilterComposer,
          $$QuizWrongAnswersTableOrderingComposer,
          $$QuizWrongAnswersTableAnnotationComposer,
          $$QuizWrongAnswersTableCreateCompanionBuilder,
          $$QuizWrongAnswersTableUpdateCompanionBuilder,
          (
            QuizWrongRow,
            BaseReferences<_$AppDatabase, $QuizWrongAnswersTable, QuizWrongRow>,
          ),
          QuizWrongRow,
          PrefetchHooks Function()
        > {
  $$QuizWrongAnswersTableTableManager(
    _$AppDatabase db,
    $QuizWrongAnswersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizWrongAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizWrongAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizWrongAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> questionId = const Value.absent(),
                Value<String?> bankId = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> lastGivenJson = const Value.absent(),
                Value<int> wrongCount = const Value.absent(),
                Value<DateTime> lastWrongAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizWrongAnswersCompanion(
                questionId: questionId,
                bankId: bankId,
                subject: subject,
                lastGivenJson: lastGivenJson,
                wrongCount: wrongCount,
                lastWrongAt: lastWrongAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String questionId,
                Value<String?> bankId = const Value.absent(),
                Value<String?> subject = const Value.absent(),
                Value<String?> lastGivenJson = const Value.absent(),
                Value<int> wrongCount = const Value.absent(),
                required DateTime lastWrongAt,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => QuizWrongAnswersCompanion.insert(
                questionId: questionId,
                bankId: bankId,
                subject: subject,
                lastGivenJson: lastGivenJson,
                wrongCount: wrongCount,
                lastWrongAt: lastWrongAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuizWrongAnswersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizWrongAnswersTable,
      QuizWrongRow,
      $$QuizWrongAnswersTableFilterComposer,
      $$QuizWrongAnswersTableOrderingComposer,
      $$QuizWrongAnswersTableAnnotationComposer,
      $$QuizWrongAnswersTableCreateCompanionBuilder,
      $$QuizWrongAnswersTableUpdateCompanionBuilder,
      (
        QuizWrongRow,
        BaseReferences<_$AppDatabase, $QuizWrongAnswersTable, QuizWrongRow>,
      ),
      QuizWrongRow,
      PrefetchHooks Function()
    >;
typedef $$QuizSettingsRowsTableCreateCompanionBuilder =
    QuizSettingsRowsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$QuizSettingsRowsTableUpdateCompanionBuilder =
    QuizSettingsRowsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$QuizSettingsRowsTableFilterComposer
    extends Composer<_$AppDatabase, $QuizSettingsRowsTable> {
  $$QuizSettingsRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuizSettingsRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizSettingsRowsTable> {
  $$QuizSettingsRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuizSettingsRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizSettingsRowsTable> {
  $$QuizSettingsRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$QuizSettingsRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizSettingsRowsTable,
          QuizSettingRow,
          $$QuizSettingsRowsTableFilterComposer,
          $$QuizSettingsRowsTableOrderingComposer,
          $$QuizSettingsRowsTableAnnotationComposer,
          $$QuizSettingsRowsTableCreateCompanionBuilder,
          $$QuizSettingsRowsTableUpdateCompanionBuilder,
          (
            QuizSettingRow,
            BaseReferences<
              _$AppDatabase,
              $QuizSettingsRowsTable,
              QuizSettingRow
            >,
          ),
          QuizSettingRow,
          PrefetchHooks Function()
        > {
  $$QuizSettingsRowsTableTableManager(
    _$AppDatabase db,
    $QuizSettingsRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizSettingsRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizSettingsRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizSettingsRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizSettingsRowsCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => QuizSettingsRowsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuizSettingsRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizSettingsRowsTable,
      QuizSettingRow,
      $$QuizSettingsRowsTableFilterComposer,
      $$QuizSettingsRowsTableOrderingComposer,
      $$QuizSettingsRowsTableAnnotationComposer,
      $$QuizSettingsRowsTableCreateCompanionBuilder,
      $$QuizSettingsRowsTableUpdateCompanionBuilder,
      (
        QuizSettingRow,
        BaseReferences<_$AppDatabase, $QuizSettingsRowsTable, QuizSettingRow>,
      ),
      QuizSettingRow,
      PrefetchHooks Function()
    >;
typedef $$QuizSubjectsTableCreateCompanionBuilder =
    QuizSubjectsCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<int?> icon,
      Value<int?> color,
      Value<int> orderIndex,
      Value<bool> archived,
      Value<String> searchText,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$QuizSubjectsTableUpdateCompanionBuilder =
    QuizSubjectsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<int?> icon,
      Value<int?> color,
      Value<int> orderIndex,
      Value<bool> archived,
      Value<String> searchText,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$QuizSubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $QuizSubjectsTable> {
  $$QuizSubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuizSubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizSubjectsTable> {
  $$QuizSubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuizSubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizSubjectsTable> {
  $$QuizSubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuizSubjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizSubjectsTable,
          QuizSubjectRow,
          $$QuizSubjectsTableFilterComposer,
          $$QuizSubjectsTableOrderingComposer,
          $$QuizSubjectsTableAnnotationComposer,
          $$QuizSubjectsTableCreateCompanionBuilder,
          $$QuizSubjectsTableUpdateCompanionBuilder,
          (
            QuizSubjectRow,
            BaseReferences<_$AppDatabase, $QuizSubjectsTable, QuizSubjectRow>,
          ),
          QuizSubjectRow,
          PrefetchHooks Function()
        > {
  $$QuizSubjectsTableTableManager(_$AppDatabase db, $QuizSubjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizSubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizSubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizSubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> icon = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizSubjectsCompanion(
                id: id,
                name: name,
                description: description,
                icon: icon,
                color: color,
                orderIndex: orderIndex,
                archived: archived,
                searchText: searchText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int?> icon = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuizSubjectsCompanion.insert(
                id: id,
                name: name,
                description: description,
                icon: icon,
                color: color,
                orderIndex: orderIndex,
                archived: archived,
                searchText: searchText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuizSubjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizSubjectsTable,
      QuizSubjectRow,
      $$QuizSubjectsTableFilterComposer,
      $$QuizSubjectsTableOrderingComposer,
      $$QuizSubjectsTableAnnotationComposer,
      $$QuizSubjectsTableCreateCompanionBuilder,
      $$QuizSubjectsTableUpdateCompanionBuilder,
      (
        QuizSubjectRow,
        BaseReferences<_$AppDatabase, $QuizSubjectsTable, QuizSubjectRow>,
      ),
      QuizSubjectRow,
      PrefetchHooks Function()
    >;
typedef $$QuizTopicsTableCreateCompanionBuilder =
    QuizTopicsCompanion Function({
      required String id,
      required String subjectId,
      required String name,
      Value<String?> description,
      Value<int?> icon,
      Value<int?> color,
      Value<int> orderIndex,
      Value<bool> archived,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$QuizTopicsTableUpdateCompanionBuilder =
    QuizTopicsCompanion Function({
      Value<String> id,
      Value<String> subjectId,
      Value<String> name,
      Value<String?> description,
      Value<int?> icon,
      Value<int?> color,
      Value<int> orderIndex,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$QuizTopicsTableFilterComposer
    extends Composer<_$AppDatabase, $QuizTopicsTable> {
  $$QuizTopicsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$QuizTopicsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizTopicsTable> {
  $$QuizTopicsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$QuizTopicsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizTopicsTable> {
  $$QuizTopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$QuizTopicsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $QuizTopicsTable,
          QuizTopicRow,
          $$QuizTopicsTableFilterComposer,
          $$QuizTopicsTableOrderingComposer,
          $$QuizTopicsTableAnnotationComposer,
          $$QuizTopicsTableCreateCompanionBuilder,
          $$QuizTopicsTableUpdateCompanionBuilder,
          (
            QuizTopicRow,
            BaseReferences<_$AppDatabase, $QuizTopicsTable, QuizTopicRow>,
          ),
          QuizTopicRow,
          PrefetchHooks Function()
        > {
  $$QuizTopicsTableTableManager(_$AppDatabase db, $QuizTopicsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizTopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizTopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizTopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> subjectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> icon = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => QuizTopicsCompanion(
                id: id,
                subjectId: subjectId,
                name: name,
                description: description,
                icon: icon,
                color: color,
                orderIndex: orderIndex,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String subjectId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int?> icon = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => QuizTopicsCompanion.insert(
                id: id,
                subjectId: subjectId,
                name: name,
                description: description,
                icon: icon,
                color: color,
                orderIndex: orderIndex,
                archived: archived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuizTopicsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $QuizTopicsTable,
      QuizTopicRow,
      $$QuizTopicsTableFilterComposer,
      $$QuizTopicsTableOrderingComposer,
      $$QuizTopicsTableAnnotationComposer,
      $$QuizTopicsTableCreateCompanionBuilder,
      $$QuizTopicsTableUpdateCompanionBuilder,
      (
        QuizTopicRow,
        BaseReferences<_$AppDatabase, $QuizTopicsTable, QuizTopicRow>,
      ),
      QuizTopicRow,
      PrefetchHooks Function()
    >;
typedef $$AiConversationsTableCreateCompanionBuilder =
    AiConversationsCompanion Function({
      required String id,
      required String title,
      Value<String?> model,
      Value<bool> pinned,
      Value<String> searchText,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AiConversationsTableUpdateCompanionBuilder =
    AiConversationsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> model,
      Value<bool> pinned,
      Value<String> searchText,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AiConversationsTableFilterComposer
    extends Composer<_$AppDatabase, $AiConversationsTable> {
  $$AiConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiConversationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiConversationsTable> {
  $$AiConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiConversationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiConversationsTable> {
  $$AiConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<String> get searchText => $composableBuilder(
    column: $table.searchText,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AiConversationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiConversationsTable,
          AiConversationRow,
          $$AiConversationsTableFilterComposer,
          $$AiConversationsTableOrderingComposer,
          $$AiConversationsTableAnnotationComposer,
          $$AiConversationsTableCreateCompanionBuilder,
          $$AiConversationsTableUpdateCompanionBuilder,
          (
            AiConversationRow,
            BaseReferences<
              _$AppDatabase,
              $AiConversationsTable,
              AiConversationRow
            >,
          ),
          AiConversationRow,
          PrefetchHooks Function()
        > {
  $$AiConversationsTableTableManager(
    _$AppDatabase db,
    $AiConversationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiConversationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiConversationsCompanion(
                id: id,
                title: title,
                model: model,
                pinned: pinned,
                searchText: searchText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> model = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<String> searchText = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AiConversationsCompanion.insert(
                id: id,
                title: title,
                model: model,
                pinned: pinned,
                searchText: searchText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiConversationsTable,
      AiConversationRow,
      $$AiConversationsTableFilterComposer,
      $$AiConversationsTableOrderingComposer,
      $$AiConversationsTableAnnotationComposer,
      $$AiConversationsTableCreateCompanionBuilder,
      $$AiConversationsTableUpdateCompanionBuilder,
      (
        AiConversationRow,
        BaseReferences<_$AppDatabase, $AiConversationsTable, AiConversationRow>,
      ),
      AiConversationRow,
      PrefetchHooks Function()
    >;
typedef $$AiMessagesTableCreateCompanionBuilder =
    AiMessagesCompanion Function({
      required String id,
      required String conversationId,
      required int role,
      required String content,
      Value<int> status,
      Value<String?> error,
      Value<int> orderIndex,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AiMessagesTableUpdateCompanionBuilder =
    AiMessagesCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<int> role,
      Value<String> content,
      Value<int> status,
      Value<String?> error,
      Value<int> orderIndex,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AiMessagesTableFilterComposer
    extends Composer<_$AppDatabase, $AiMessagesTable> {
  $$AiMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiMessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $AiMessagesTable> {
  $$AiMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get error => $composableBuilder(
    column: $table.error,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiMessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiMessagesTable> {
  $$AiMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get error =>
      $composableBuilder(column: $table.error, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
    column: $table.orderIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AiMessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiMessagesTable,
          AiMessageRow,
          $$AiMessagesTableFilterComposer,
          $$AiMessagesTableOrderingComposer,
          $$AiMessagesTableAnnotationComposer,
          $$AiMessagesTableCreateCompanionBuilder,
          $$AiMessagesTableUpdateCompanionBuilder,
          (
            AiMessageRow,
            BaseReferences<_$AppDatabase, $AiMessagesTable, AiMessageRow>,
          ),
          AiMessageRow,
          PrefetchHooks Function()
        > {
  $$AiMessagesTableTableManager(_$AppDatabase db, $AiMessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<int> role = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiMessagesCompanion(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                status: status,
                error: error,
                orderIndex: orderIndex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required int role,
                required String content,
                Value<int> status = const Value.absent(),
                Value<String?> error = const Value.absent(),
                Value<int> orderIndex = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AiMessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                role: role,
                content: content,
                status: status,
                error: error,
                orderIndex: orderIndex,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiMessagesTable,
      AiMessageRow,
      $$AiMessagesTableFilterComposer,
      $$AiMessagesTableOrderingComposer,
      $$AiMessagesTableAnnotationComposer,
      $$AiMessagesTableCreateCompanionBuilder,
      $$AiMessagesTableUpdateCompanionBuilder,
      (
        AiMessageRow,
        BaseReferences<_$AppDatabase, $AiMessagesTable, AiMessageRow>,
      ),
      AiMessageRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DocumentsTableTableManager get documents =>
      $$DocumentsTableTableManager(_db, _db.documents);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$BookmarksTableTableManager get bookmarks =>
      $$BookmarksTableTableManager(_db, _db.bookmarks);
  $$HighlightsTableTableManager get highlights =>
      $$HighlightsTableTableManager(_db, _db.highlights);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$ReadingProgressTableTableManager get readingProgress =>
      $$ReadingProgressTableTableManager(_db, _db.readingProgress);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(_db, _db.readingSessions);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$DictionaryEntriesTableTableManager get dictionaryEntries =>
      $$DictionaryEntriesTableTableManager(_db, _db.dictionaryEntries);
  $$DictionaryFavoritesTableTableManager get dictionaryFavorites =>
      $$DictionaryFavoritesTableTableManager(_db, _db.dictionaryFavorites);
  $$DictionaryExamEntriesTableTableManager get dictionaryExamEntries =>
      $$DictionaryExamEntriesTableTableManager(_db, _db.dictionaryExamEntries);
  $$DictionarySearchHistoryTableTableManager get dictionarySearchHistory =>
      $$DictionarySearchHistoryTableTableManager(
        _db,
        _db.dictionarySearchHistory,
      );
  $$TranslationEntriesTableTableManager get translationEntries =>
      $$TranslationEntriesTableTableManager(_db, _db.translationEntries);
  $$TranslationCacheTableTableManager get translationCache =>
      $$TranslationCacheTableTableManager(_db, _db.translationCache);
  $$GrammarLessonsTableTableManager get grammarLessons =>
      $$GrammarLessonsTableTableManager(_db, _db.grammarLessons);
  $$GrammarProgressTableTableManager get grammarProgress =>
      $$GrammarProgressTableTableManager(_db, _db.grammarProgress);
  $$GrammarFavoritesTableTableManager get grammarFavorites =>
      $$GrammarFavoritesTableTableManager(_db, _db.grammarFavorites);
  $$GrammarTopicsTableTableManager get grammarTopics =>
      $$GrammarTopicsTableTableManager(_db, _db.grammarTopics);
  $$VocabularyListsTableTableManager get vocabularyLists =>
      $$VocabularyListsTableTableManager(_db, _db.vocabularyLists);
  $$VocabularyWordsTableTableManager get vocabularyWords =>
      $$VocabularyWordsTableTableManager(_db, _db.vocabularyWords);
  $$StudyTasksTableTableManager get studyTasks =>
      $$StudyTasksTableTableManager(_db, _db.studyTasks);
  $$StudyGoalsTableTableManager get studyGoals =>
      $$StudyGoalsTableTableManager(_db, _db.studyGoals);
  $$StudySessionsTableTableManager get studySessions =>
      $$StudySessionsTableTableManager(_db, _db.studySessions);
  $$StudyTemplatesTableTableManager get studyTemplates =>
      $$StudyTemplatesTableTableManager(_db, _db.studyTemplates);
  $$StudyTemplateItemsTableTableManager get studyTemplateItems =>
      $$StudyTemplateItemsTableTableManager(_db, _db.studyTemplateItems);
  $$StudySubjectsTableTableManager get studySubjects =>
      $$StudySubjectsTableTableManager(_db, _db.studySubjects);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db, _db.decks);
  $$FlashcardsTableTableManager get flashcards =>
      $$FlashcardsTableTableManager(_db, _db.flashcards);
  $$ReviewLogsTableTableManager get reviewLogs =>
      $$ReviewLogsTableTableManager(_db, _db.reviewLogs);
  $$QuizBanksTableTableManager get quizBanks =>
      $$QuizBanksTableTableManager(_db, _db.quizBanks);
  $$QuizQuestionsTableTableManager get quizQuestions =>
      $$QuizQuestionsTableTableManager(_db, _db.quizQuestions);
  $$QuizAttemptsTableTableManager get quizAttempts =>
      $$QuizAttemptsTableTableManager(_db, _db.quizAttempts);
  $$QuizAttemptAnswersTableTableManager get quizAttemptAnswers =>
      $$QuizAttemptAnswersTableTableManager(_db, _db.quizAttemptAnswers);
  $$QuizWrongAnswersTableTableManager get quizWrongAnswers =>
      $$QuizWrongAnswersTableTableManager(_db, _db.quizWrongAnswers);
  $$QuizSettingsRowsTableTableManager get quizSettingsRows =>
      $$QuizSettingsRowsTableTableManager(_db, _db.quizSettingsRows);
  $$QuizSubjectsTableTableManager get quizSubjects =>
      $$QuizSubjectsTableTableManager(_db, _db.quizSubjects);
  $$QuizTopicsTableTableManager get quizTopics =>
      $$QuizTopicsTableTableManager(_db, _db.quizTopics);
  $$AiConversationsTableTableManager get aiConversations =>
      $$AiConversationsTableTableManager(_db, _db.aiConversations);
  $$AiMessagesTableTableManager get aiMessages =>
      $$AiMessagesTableTableManager(_db, _db.aiMessages);
}
