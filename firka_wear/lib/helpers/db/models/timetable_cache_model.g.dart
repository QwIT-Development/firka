// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_cache_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTimetableCacheModelCollection on Isar {
  IsarCollection<TimetableCacheModel> get timetableCacheModels =>
      this.collection();
}

const TimetableCacheModelSchema = CollectionSchema(
  name: r'TimetableCacheModel',
  id: -8626340955125680275,
  properties: {
    r'values': PropertySchema(
      id: 0,
      name: r'values',
      type: IsarType.stringList,
    )
  },
  estimateSize: _timetableCacheModelEstimateSize,
  serialize: _timetableCacheModelSerialize,
  deserialize: _timetableCacheModelDeserialize,
  deserializeProp: _timetableCacheModelDeserializeProp,
  idName: r'cacheKey',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _timetableCacheModelGetId,
  getLinks: _timetableCacheModelGetLinks,
  attach: _timetableCacheModelAttach,
  version: '3.1.0+1',
);

int _timetableCacheModelEstimateSize(
  TimetableCacheModel object,
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

void _timetableCacheModelSerialize(
  TimetableCacheModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.values);
}

TimetableCacheModel _timetableCacheModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimetableCacheModel();
  object.cacheKey = id;
  object.values = reader.readStringList(offsets[0]);
  return object;
}

P _timetableCacheModelDeserializeProp<P>(
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

Id _timetableCacheModelGetId(TimetableCacheModel object) {
  return object.cacheKey ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _timetableCacheModelGetLinks(
    TimetableCacheModel object) {
  return [];
}

void _timetableCacheModelAttach(
    IsarCollection<dynamic> col, Id id, TimetableCacheModel object) {
  object.cacheKey = id;
}

extension TimetableCacheModelQueryWhereSort
    on QueryBuilder<TimetableCacheModel, TimetableCacheModel, QWhere> {
  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterWhere>
      anyCacheKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TimetableCacheModelQueryWhere
    on QueryBuilder<TimetableCacheModel, TimetableCacheModel, QWhereClause> {
  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterWhereClause>
      cacheKeyEqualTo(Id cacheKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: cacheKey,
        upper: cacheKey,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterWhereClause>
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

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterWhereClause>
      cacheKeyGreaterThan(Id cacheKey, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: cacheKey, includeLower: include),
      );
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterWhereClause>
      cacheKeyLessThan(Id cacheKey, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: cacheKey, includeUpper: include),
      );
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterWhereClause>
      cacheKeyBetween(
    Id lowerCacheKey,
    Id upperCacheKey, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerCacheKey,
        includeLower: includeLower,
        upper: upperCacheKey,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TimetableCacheModelQueryFilter on QueryBuilder<TimetableCacheModel,
    TimetableCacheModel, QFilterCondition> {
  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      cacheKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cacheKey',
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      cacheKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cacheKey',
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      cacheKeyEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cacheKey',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      cacheKeyGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cacheKey',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      cacheKeyLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cacheKey',
        value: value,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      cacheKeyBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cacheKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'values',
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'values',
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'values',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'values',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'values',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'values',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'values',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'values',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'values',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'values',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'values',
        value: '',
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'values',
        value: '',
      ));
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
      valuesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'values',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterFilterCondition>
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

extension TimetableCacheModelQueryObject on QueryBuilder<TimetableCacheModel,
    TimetableCacheModel, QFilterCondition> {}

extension TimetableCacheModelQueryLinks on QueryBuilder<TimetableCacheModel,
    TimetableCacheModel, QFilterCondition> {}

extension TimetableCacheModelQuerySortBy
    on QueryBuilder<TimetableCacheModel, TimetableCacheModel, QSortBy> {}

extension TimetableCacheModelQuerySortThenBy
    on QueryBuilder<TimetableCacheModel, TimetableCacheModel, QSortThenBy> {
  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterSortBy>
      thenByCacheKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.asc);
    });
  }

  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QAfterSortBy>
      thenByCacheKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.desc);
    });
  }
}

extension TimetableCacheModelQueryWhereDistinct
    on QueryBuilder<TimetableCacheModel, TimetableCacheModel, QDistinct> {
  QueryBuilder<TimetableCacheModel, TimetableCacheModel, QDistinct>
      distinctByValues() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'values');
    });
  }
}

extension TimetableCacheModelQueryProperty
    on QueryBuilder<TimetableCacheModel, TimetableCacheModel, QQueryProperty> {
  QueryBuilder<TimetableCacheModel, int, QQueryOperations> cacheKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cacheKey');
    });
  }

  QueryBuilder<TimetableCacheModel, List<String>?, QQueryOperations>
      valuesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'values');
    });
  }
}
