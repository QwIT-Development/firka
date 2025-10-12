// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'homework_cache_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHomeworkCacheModelCollection on Isar {
  IsarCollection<HomeworkCacheModel> get homeworkCacheModels =>
      this.collection();
}

const HomeworkCacheModelSchema = CollectionSchema(
  name: r'HomeworkCacheModel',
  id: -356692531669197690,
  properties: {
    r'values': PropertySchema(
      id: 0,
      name: r'values',
      type: IsarType.stringList,
    ),
  },

  estimateSize: _homeworkCacheModelEstimateSize,
  serialize: _homeworkCacheModelSerialize,
  deserialize: _homeworkCacheModelDeserialize,
  deserializeProp: _homeworkCacheModelDeserializeProp,
  idName: r'cacheKey',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _homeworkCacheModelGetId,
  getLinks: _homeworkCacheModelGetLinks,
  attach: _homeworkCacheModelAttach,
  version: '3.3.0',
);

int _homeworkCacheModelEstimateSize(
  HomeworkCacheModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.values;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  return bytesCount;
}

void _homeworkCacheModelSerialize(
  HomeworkCacheModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.values);
}

HomeworkCacheModel _homeworkCacheModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HomeworkCacheModel();
  object.cacheKey = id;
  object.values = reader.readStringList(offsets[0]);
  return object;
}

P _homeworkCacheModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _homeworkCacheModelGetId(HomeworkCacheModel object) {
  return object.cacheKey ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _homeworkCacheModelGetLinks(
  HomeworkCacheModel object,
) {
  return [];
}

void _homeworkCacheModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  HomeworkCacheModel object,
) {
  object.cacheKey = id;
}

extension HomeworkCacheModelQueryWhereSort
    on QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QWhere> {
  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterWhere>
  anyCacheKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HomeworkCacheModelQueryWhere
    on QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QWhereClause> {
  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterWhereClause>
  cacheKeyEqualTo(Id cacheKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(lower: cacheKey, upper: cacheKey),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterWhereClause>
  cacheKeyNotEqualTo(Id cacheKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: cacheKey, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: cacheKey, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: cacheKey, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: cacheKey, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterWhereClause>
  cacheKeyGreaterThan(Id cacheKey, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: cacheKey, includeLower: include),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterWhereClause>
  cacheKeyLessThan(Id cacheKey, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: cacheKey, includeUpper: include),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterWhereClause>
  cacheKeyBetween(
    Id lowerCacheKey,
    Id upperCacheKey, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerCacheKey,
          includeLower: includeLower,
          upper: upperCacheKey,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension HomeworkCacheModelQueryFilter
    on QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QFilterCondition> {
  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  cacheKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'cacheKey'),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  cacheKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'cacheKey'),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  cacheKeyEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cacheKey', value: value),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  cacheKeyGreaterThan(Id? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cacheKey',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  cacheKeyLessThan(Id? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cacheKey',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  cacheKeyBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cacheKey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'values'),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'values'),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'values',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'values',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'values',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'values',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'values',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'values',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'values',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'values',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'values', value: ''),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'values', value: ''),
      );
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'values', length, true, length, true);
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'values', 0, true, 0, true);
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'values', 0, false, 999999, true);
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'values', 0, true, length, include);
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'values', length, include, 999999, true);
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterFilterCondition>
  valuesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension HomeworkCacheModelQueryObject
    on QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QFilterCondition> {}

extension HomeworkCacheModelQueryLinks
    on QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QFilterCondition> {}

extension HomeworkCacheModelQuerySortBy
    on QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QSortBy> {}

extension HomeworkCacheModelQuerySortThenBy
    on QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QSortThenBy> {
  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterSortBy>
  thenByCacheKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.asc);
    });
  }

  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QAfterSortBy>
  thenByCacheKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.desc);
    });
  }
}

extension HomeworkCacheModelQueryWhereDistinct
    on QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QDistinct> {
  QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QDistinct>
  distinctByValues() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'values');
    });
  }
}

extension HomeworkCacheModelQueryProperty
    on QueryBuilder<HomeworkCacheModel, HomeworkCacheModel, QQueryProperty> {
  QueryBuilder<HomeworkCacheModel, int, QQueryOperations> cacheKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cacheKey');
    });
  }

  QueryBuilder<HomeworkCacheModel, List<String>?, QQueryOperations>
  valuesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'values');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHomeworkDoneModelCollection on Isar {
  IsarCollection<HomeworkDoneModel> get homeworkDoneModels => this.collection();
}

const HomeworkDoneModelSchema = CollectionSchema(
  name: r'HomeworkDoneModel',
  id: -864135255844965497,
  properties: {
    r'doneAt': PropertySchema(
      id: 0,
      name: r'doneAt',
      type: IsarType.dateTime,
    ),
    r'homeworkId': PropertySchema(
      id: 1,
      name: r'homeworkId',
      type: IsarType.string,
    )
  },
  estimateSize: _homeworkDoneModelEstimateSize,
  serialize: _homeworkDoneModelSerialize,
  deserialize: _homeworkDoneModelDeserialize,
  deserializeProp: _homeworkDoneModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _homeworkDoneModelGetId,
  getLinks: _homeworkDoneModelGetLinks,
  attach: _homeworkDoneModelAttach,
  version: '3.1.0+1',
);

int _homeworkDoneModelEstimateSize(
  HomeworkDoneModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.homeworkId.length * 3;
  return bytesCount;
}

void _homeworkDoneModelSerialize(
  HomeworkDoneModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.doneAt);
  writer.writeString(offsets[1], object.homeworkId);
}

HomeworkDoneModel _homeworkDoneModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HomeworkDoneModel();
  object.doneAt = reader.readDateTime(offsets[0]);
  object.homeworkId = reader.readString(offsets[1]);
  object.id = id;
  return object;
}

P _homeworkDoneModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _homeworkDoneModelGetId(HomeworkDoneModel object) {
  return object.id ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _homeworkDoneModelGetLinks(
    HomeworkDoneModel object) {
  return [];
}

void _homeworkDoneModelAttach(
    IsarCollection<dynamic> col, Id id, HomeworkDoneModel object) {
  object.id = id;
}

extension HomeworkDoneModelQueryWhereSort
    on QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QWhere> {
  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HomeworkDoneModelQueryWhere
    on QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QWhereClause> {
  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension HomeworkDoneModelQueryFilter
    on QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QFilterCondition> {
  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      doneAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'doneAt',
        value: value,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      doneAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'doneAt',
        value: value,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      doneAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'doneAt',
        value: value,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      doneAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'doneAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      homeworkIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'homeworkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      homeworkIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'homeworkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      homeworkIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'homeworkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      homeworkIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'homeworkId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      homeworkIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'homeworkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      homeworkIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'homeworkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      homeworkIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'homeworkId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      homeworkIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'homeworkId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      homeworkIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'homeworkId',
        value: '',
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      homeworkIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'homeworkId',
        value: '',
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      idGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      idLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterFilterCondition>
      idBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension HomeworkDoneModelQueryObject
    on QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QFilterCondition> {}

extension HomeworkDoneModelQueryLinks
    on QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QFilterCondition> {}

extension HomeworkDoneModelQuerySortBy
    on QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QSortBy> {
  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterSortBy>
      sortByDoneAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'doneAt', Sort.asc);
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterSortBy>
      sortByDoneAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'doneAt', Sort.desc);
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterSortBy>
      sortByHomeworkId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'homeworkId', Sort.asc);
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterSortBy>
      sortByHomeworkIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'homeworkId', Sort.desc);
    });
  }
}

extension HomeworkDoneModelQuerySortThenBy
    on QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QSortThenBy> {
  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterSortBy>
      thenByDoneAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'doneAt', Sort.asc);
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterSortBy>
      thenByDoneAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'doneAt', Sort.desc);
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterSortBy>
      thenByHomeworkId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'homeworkId', Sort.asc);
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterSortBy>
      thenByHomeworkIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'homeworkId', Sort.desc);
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension HomeworkDoneModelQueryWhereDistinct
    on QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QDistinct> {
  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QDistinct>
      distinctByDoneAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'doneAt');
    });
  }

  QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QDistinct>
      distinctByHomeworkId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'homeworkId', caseSensitive: caseSensitive);
    });
  }
}

extension HomeworkDoneModelQueryProperty
    on QueryBuilder<HomeworkDoneModel, HomeworkDoneModel, QQueryProperty> {
  QueryBuilder<HomeworkDoneModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HomeworkDoneModel, DateTime, QQueryOperations> doneAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'doneAt');
    });
  }

  QueryBuilder<HomeworkDoneModel, String, QQueryOperations>
      homeworkIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'homeworkId');
    });
  }
}
