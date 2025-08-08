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
    r'valueBool': PropertySchema(
      id: 0,
      name: r'valueBool',
      type: IsarType.bool,
    ),
    r'valueDouble': PropertySchema(
      id: 1,
      name: r'valueDouble',
      type: IsarType.double,
    )
  },
  estimateSize: _appSettingsModelEstimateSize,
  serialize: _appSettingsModelSerialize,
  deserialize: _appSettingsModelDeserialize,
  deserializeProp: _appSettingsModelDeserializeProp,
  idName: r'id',
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
  return bytesCount;
}

void _appSettingsModelSerialize(
  AppSettingsModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.valueBool);
  writer.writeDouble(offsets[1], object.valueDouble);
}

AppSettingsModel _appSettingsModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AppSettingsModel();
  object.id = id;
  object.valueBool = reader.readBoolOrNull(offsets[0]);
  object.valueDouble = reader.readDoubleOrNull(offsets[1]);
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
      return (reader.readBoolOrNull(offset)) as P;
    case 1:
      return (reader.readDoubleOrNull(offset)) as P;
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
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AppSettingsModelQueryWhere
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QWhereClause> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause>
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

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterWhereClause> idBetween(
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

extension AppSettingsModelQueryFilter
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QFilterCondition> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      idIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      idIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'id',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      idEqualTo(Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
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

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      valueBoolIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'valueBool',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      valueBoolIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'valueBool',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      valueBoolEqualTo(bool? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valueBool',
        value: value,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      valueDoubleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'valueDouble',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      valueDoubleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'valueDouble',
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      valueDoubleEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'valueDouble',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      valueDoubleGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'valueDouble',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      valueDoubleLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'valueDouble',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterFilterCondition>
      valueDoubleBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'valueDouble',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
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
      sortByValueBool() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueBool', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByValueBoolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueBool', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByValueDouble() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueDouble', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      sortByValueDoubleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueDouble', Sort.desc);
    });
  }
}

extension AppSettingsModelQuerySortThenBy
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QSortThenBy> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByValueBool() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueBool', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByValueBoolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueBool', Sort.desc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByValueDouble() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueDouble', Sort.asc);
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QAfterSortBy>
      thenByValueDoubleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'valueDouble', Sort.desc);
    });
  }
}

extension AppSettingsModelQueryWhereDistinct
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct> {
  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByValueBool() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valueBool');
    });
  }

  QueryBuilder<AppSettingsModel, AppSettingsModel, QDistinct>
      distinctByValueDouble() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'valueDouble');
    });
  }
}

extension AppSettingsModelQueryProperty
    on QueryBuilder<AppSettingsModel, AppSettingsModel, QQueryProperty> {
  QueryBuilder<AppSettingsModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AppSettingsModel, bool?, QQueryOperations> valueBoolProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valueBool');
    });
  }

  QueryBuilder<AppSettingsModel, double?, QQueryOperations>
      valueDoubleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'valueDouble');
    });
  }
}
