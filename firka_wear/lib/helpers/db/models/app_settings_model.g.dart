// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAppSettingsModelCollection on Isar {
  IsarCollection<AppSettingsModel> get appSettingsModels => this.collection();
}

const AppSettingsModelSchema = CollectionSchema(
  name: r'AppSettingsModel',
  id: -638838212012723081,
  properties: {
    r'customHost': PropertySchema(
      id: 0,
      name: r'customHost',
      type: IsarType.string,
    ),
    r'useCustomHost': PropertySchema(
      id: 1,
      name: r'useCustomHost',
      type: IsarType.bool,
    )
  },
  estimateSize: _appSettingsModelEstimateSize,
  serialize: _appSettingsModelSerialize,
  deserialize: _appSettingsModelDeserialize,
  deserializeProp: _appSettingsModelDeserializeProp,
  idName: r'ignored',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _appSettingsModelGetId,
  getLinks: _appSettingsModelGetLinks,
  attach: _appSettingsModelAttach,
  version: '3.1.0+1',
);

int _appSettingsModelEstimateSize(
  AppSettingsModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.customHost;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _appSettingsModelSerialize(
  AppSettingsModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.customHost);
  writer.writeBool(offsets[1], object.useCustomHost);
}

AppSettingsModel _appSettingsModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppSettingsModel();
  object.customHost = reader.readStringOrNull(offsets[0]);
  object.id = id;
  object.useCustomHost = reader.readBoolOrNull(offsets[1]);
  return object;
}

P _appSettingsModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _appSettingsModelGetId(AppSettingsModel object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _appSettingsModelGetLinks(AppSettingsModel object) {
  return [];
}

void _appSettingsModelAttach(
    IsarCollection<dynamic> col, Id id, AppSettingsModel object) {
  object.id = id;
}

extension AppSettingsModelQueryWhereSort
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QWhere> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhere> anyIgnored() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppSettingsModelQueryWhere
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QWhereClause> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause>
      ignoredEqualTo(Id ignored) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: ignored,
        upper: ignored,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause>
      ignoredNotEqualTo(Id ignored) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: ignored, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: ignored, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: ignored, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: ignored, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause>
      ignoredGreaterThan(Id ignored, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: ignored, includeLower: include),
      );
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause>
      ignoredLessThan(Id ignored, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: ignored, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause>
      ignoredBetween(
    Id lowerIgnored,
    Id upperIgnored, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIgnored,
        includeLower: includeLower,
        upper: upperIgnored,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension AppSettingsModelQueryFilter
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QFilterCondition> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'customHost',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'customHost',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customHost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'customHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'customHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'customHost',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'customHost',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customHost',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      customHostIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'customHost',
        value: '',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      ignoredIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ignored',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      ignoredIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ignored',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      ignoredEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ignored',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      ignoredGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ignored',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      ignoredLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ignored',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      ignoredBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ignored',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      useCustomHostIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'useCustomHost',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      useCustomHostIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'useCustomHost',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      useCustomHostEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'useCustomHost',
        value: value,
      ));
    });
  }
}

extension AppSettingsModelQueryObject
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QFilterCondition> {}

extension AppSettingsModelQueryLinks
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QFilterCondition> {}

extension AppSettingsModelQuerySortBy
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QSortBy> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByCustomHost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customHost', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByCustomHostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customHost', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByUseCustomHost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCustomHost', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByUseCustomHostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCustomHost', Sort.desc);
    });
  }
}

extension AppSettingsModelQuerySortThenBy
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QSortThenBy> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByCustomHost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customHost', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByCustomHostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customHost', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByIgnored() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignored', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByIgnoredDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignored', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByUseCustomHost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCustomHost', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByUseCustomHostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useCustomHost', Sort.desc);
    });
  }
}

extension AppSettingsModelQueryWhereDistinct
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByCustomHost({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customHost', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByUseCustomHost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'useCustomHost');
    });
  }
}

extension AppSettingsModelQueryProperty
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QQueryProperty> {
  QueryBuilder<AppSettingsModel, int, QQueryOperations> ignoredProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ignored');
    });
  }

  QueryBuilder<AppSettingsModel, String?, QQueryOperations>
      customHostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customHost');
    });
  }

  QueryBuilder<AppSettingsModel, bool?, QQueryOperations>
      useCustomHostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'useCustomHost');
    });
  }
}
