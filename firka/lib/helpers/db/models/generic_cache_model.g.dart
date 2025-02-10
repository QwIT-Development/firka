// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generic_cache_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetGenericCacheModelCollection on Isar {
  IsarCollection<GenericCacheModel> get genericCacheModels => this.collection();
}

const GenericCacheModelSchema = CollectionSchema(
  name: r'GenericCacheModel',
  id: 3174486726793780620,
  properties: {
    r'cacheData': PropertySchema(
      id: 0,
      name: r'cacheData',
      type: IsarType.string,
    )
  },
  estimateSize: _genericCacheModelEstimateSize,
  serialize: _genericCacheModelSerialize,
  deserialize: _genericCacheModelDeserialize,
  deserializeProp: _genericCacheModelDeserializeProp,
  idName: r'cacheKey',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _genericCacheModelGetId,
  getLinks: _genericCacheModelGetLinks,
  attach: _genericCacheModelAttach,
  version: '3.1.0+1',
);

int _genericCacheModelEstimateSize(
  GenericCacheModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.cacheData;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _genericCacheModelSerialize(
  GenericCacheModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cacheData);
}

GenericCacheModel _genericCacheModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GenericCacheModel();
  object.cacheData = reader.readStringOrNull(offsets[0]);
  object.cacheKey = id;
  return object;
}

P _genericCacheModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _genericCacheModelGetId(GenericCacheModel object) {
  return object.cacheKey ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _genericCacheModelGetLinks(
    GenericCacheModel object) {
  return [];
}

void _genericCacheModelAttach(
    IsarCollection<dynamic> col, Id id, GenericCacheModel object) {
  object.cacheKey = id;
}

extension GenericCacheModelQueryWhereSort
    on QueryBuilder<GenericCacheModel, GenericCacheModel, QWhere> {
  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterWhere>
      anyCacheKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GenericCacheModelQueryWhere
    on QueryBuilder<GenericCacheModel, GenericCacheModel, QWhereClause> {
  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterWhereClause>
      cacheKeyEqualTo(Id cacheKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: cacheKey,
        upper: cacheKey,
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterWhereClause>
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

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterWhereClause>
      cacheKeyGreaterThan(Id cacheKey, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: cacheKey, includeLower: include),
      );
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterWhereClause>
      cacheKeyLessThan(Id cacheKey, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: cacheKey, includeUpper: include),
      );
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterWhereClause>
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

extension GenericCacheModelQueryFilter
    on QueryBuilder<GenericCacheModel, GenericCacheModel, QFilterCondition> {
  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cacheData',
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cacheData',
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cacheData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cacheData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cacheData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cacheData',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cacheData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cacheData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cacheData',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cacheData',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cacheData',
        value: '',
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheDataIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cacheData',
        value: '',
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheKeyIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cacheKey',
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheKeyIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cacheKey',
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
      cacheKeyEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cacheKey',
        value: value,
      ));
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
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

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
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

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterFilterCondition>
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
}

extension GenericCacheModelQueryObject
    on QueryBuilder<GenericCacheModel, GenericCacheModel, QFilterCondition> {}

extension GenericCacheModelQueryLinks
    on QueryBuilder<GenericCacheModel, GenericCacheModel, QFilterCondition> {}

extension GenericCacheModelQuerySortBy
    on QueryBuilder<GenericCacheModel, GenericCacheModel, QSortBy> {
  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterSortBy>
      sortByCacheData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheData', Sort.asc);
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterSortBy>
      sortByCacheDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheData', Sort.desc);
    });
  }
}

extension GenericCacheModelQuerySortThenBy
    on QueryBuilder<GenericCacheModel, GenericCacheModel, QSortThenBy> {
  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterSortBy>
      thenByCacheData() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheData', Sort.asc);
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterSortBy>
      thenByCacheDataDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheData', Sort.desc);
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterSortBy>
      thenByCacheKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.asc);
    });
  }

  QueryBuilder<GenericCacheModel, GenericCacheModel, QAfterSortBy>
      thenByCacheKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cacheKey', Sort.desc);
    });
  }
}

extension GenericCacheModelQueryWhereDistinct
    on QueryBuilder<GenericCacheModel, GenericCacheModel, QDistinct> {
  QueryBuilder<GenericCacheModel, GenericCacheModel, QDistinct>
      distinctByCacheData({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cacheData', caseSensitive: caseSensitive);
    });
  }
}

extension GenericCacheModelQueryProperty
    on QueryBuilder<GenericCacheModel, GenericCacheModel, QQueryProperty> {
  QueryBuilder<GenericCacheModel, int, QQueryOperations> cacheKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cacheKey');
    });
  }

  QueryBuilder<GenericCacheModel, String?, QQueryOperations>
      cacheDataProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cacheData');
    });
  }
}
