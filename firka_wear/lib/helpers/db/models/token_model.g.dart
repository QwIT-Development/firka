// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTokenModelCollection on Isar {
  IsarCollection<TokenModel> get tokenModels => this.collection();
}

const TokenModelSchema = CollectionSchema(
  name: r'TokenModel',
  id: 6587729607152393036,
  properties: {
    r'accessToken': PropertySchema(
      id: 0,
      name: r'accessToken',
      type: IsarType.string,
    ),
    r'expiryDate': PropertySchema(
      id: 1,
      name: r'expiryDate',
      type: IsarType.dateTime,
    ),
    r'idToken': PropertySchema(
      id: 2,
      name: r'idToken',
      type: IsarType.string,
    ),
    r'iss': PropertySchema(
      id: 3,
      name: r'iss',
      type: IsarType.string,
    ),
    r'refreshToken': PropertySchema(
      id: 4,
      name: r'refreshToken',
      type: IsarType.string,
    )
  },
  estimateSize: _tokenModelEstimateSize,
  serialize: _tokenModelSerialize,
  deserialize: _tokenModelDeserialize,
  deserializeProp: _tokenModelDeserializeProp,
  idName: r'studentId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _tokenModelGetId,
  getLinks: _tokenModelGetLinks,
  attach: _tokenModelAttach,
  version: '3.1.0+1',
);

int _tokenModelEstimateSize(
  TokenModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.accessToken;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.idToken;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.iss;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.refreshToken;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _tokenModelSerialize(
  TokenModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accessToken);
  writer.writeDateTime(offsets[1], object.expiryDate);
  writer.writeString(offsets[2], object.idToken);
  writer.writeString(offsets[3], object.iss);
  writer.writeString(offsets[4], object.refreshToken);
}

TokenModel _tokenModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TokenModel();
  object.accessToken = reader.readStringOrNull(offsets[0]);
  object.expiryDate = reader.readDateTimeOrNull(offsets[1]);
  object.idToken = reader.readStringOrNull(offsets[2]);
  object.iss = reader.readStringOrNull(offsets[3]);
  object.refreshToken = reader.readStringOrNull(offsets[4]);
  object.studentId = id;
  return object;
}

P _tokenModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _tokenModelGetId(TokenModel object) {
  return object.studentId ?? Isar.autoIncrement;
}

List<IsarLinkBase<dynamic>> _tokenModelGetLinks(TokenModel object) {
  return [];
}

void _tokenModelAttach(IsarCollection<dynamic> col, Id id, TokenModel object) {
  object.studentId = id;
}

extension TokenModelQueryWhereSort
    on QueryBuilder<TokenModel, TokenModel, QWhere> {
  QueryBuilder<TokenModel, TokenModel, QAfterWhere> anyStudentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TokenModelQueryWhere
    on QueryBuilder<TokenModel, TokenModel, QWhereClause> {
  QueryBuilder<TokenModel, TokenModel, QAfterWhereClause> studentIdEqualTo(
      Id studentId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: studentId,
        upper: studentId,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterWhereClause> studentIdNotEqualTo(
      Id studentId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: studentId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: studentId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: studentId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: studentId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterWhereClause> studentIdGreaterThan(
      Id studentId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: studentId, includeLower: include),
      );
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterWhereClause> studentIdLessThan(
      Id studentId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: studentId, includeUpper: include),
      );
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterWhereClause> studentIdBetween(
    Id lowerStudentId,
    Id upperStudentId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerStudentId,
        includeLower: includeLower,
        upper: upperStudentId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TokenModelQueryFilter
    on QueryBuilder<TokenModel, TokenModel, QFilterCondition> {
  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'accessToken',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'accessToken',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accessToken',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accessToken',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accessToken',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      accessTokenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accessToken',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      expiryDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'expiryDate',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      expiryDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'expiryDate',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> expiryDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiryDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      expiryDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expiryDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      expiryDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expiryDate',
        value: value,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> expiryDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expiryDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> idTokenIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'idToken',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      idTokenIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'idToken',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> idTokenEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      idTokenGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'idToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> idTokenLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'idToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> idTokenBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'idToken',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> idTokenStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'idToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> idTokenEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'idToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> idTokenContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'idToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> idTokenMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'idToken',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> idTokenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'idToken',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      idTokenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'idToken',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'iss',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'iss',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iss',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'iss',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'iss',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'iss',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'iss',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'iss',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'iss',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'iss',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'iss',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> issIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'iss',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'refreshToken',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'refreshToken',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'refreshToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'refreshToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'refreshToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'refreshToken',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'refreshToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'refreshToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'refreshToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'refreshToken',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'refreshToken',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      refreshTokenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'refreshToken',
        value: '',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      studentIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'studentId',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      studentIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'studentId',
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> studentIdEqualTo(
      Id? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'studentId',
        value: value,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition>
      studentIdGreaterThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'studentId',
        value: value,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> studentIdLessThan(
    Id? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'studentId',
        value: value,
      ));
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterFilterCondition> studentIdBetween(
    Id? lower,
    Id? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'studentId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TokenModelQueryObject
    on QueryBuilder<TokenModel, TokenModel, QFilterCondition> {}

extension TokenModelQueryLinks
    on QueryBuilder<TokenModel, TokenModel, QFilterCondition> {}

extension TokenModelQuerySortBy
    on QueryBuilder<TokenModel, TokenModel, QSortBy> {
  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> sortByAccessToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessToken', Sort.asc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> sortByAccessTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessToken', Sort.desc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> sortByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.asc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> sortByExpiryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.desc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> sortByIdToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idToken', Sort.asc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> sortByIdTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idToken', Sort.desc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> sortByIss() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iss', Sort.asc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> sortByIssDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iss', Sort.desc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> sortByRefreshToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refreshToken', Sort.asc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> sortByRefreshTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refreshToken', Sort.desc);
    });
  }
}

extension TokenModelQuerySortThenBy
    on QueryBuilder<TokenModel, TokenModel, QSortThenBy> {
  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByAccessToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessToken', Sort.asc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByAccessTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessToken', Sort.desc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.asc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByExpiryDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiryDate', Sort.desc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByIdToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idToken', Sort.asc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByIdTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'idToken', Sort.desc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByIss() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iss', Sort.asc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByIssDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'iss', Sort.desc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByRefreshToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refreshToken', Sort.asc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByRefreshTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'refreshToken', Sort.desc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByStudentId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentId', Sort.asc);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QAfterSortBy> thenByStudentIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'studentId', Sort.desc);
    });
  }
}

extension TokenModelQueryWhereDistinct
    on QueryBuilder<TokenModel, TokenModel, QDistinct> {
  QueryBuilder<TokenModel, TokenModel, QDistinct> distinctByAccessToken(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accessToken', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QDistinct> distinctByExpiryDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiryDate');
    });
  }

  QueryBuilder<TokenModel, TokenModel, QDistinct> distinctByIdToken(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'idToken', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QDistinct> distinctByIss(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'iss', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TokenModel, TokenModel, QDistinct> distinctByRefreshToken(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'refreshToken', caseSensitive: caseSensitive);
    });
  }
}

extension TokenModelQueryProperty
    on QueryBuilder<TokenModel, TokenModel, QQueryProperty> {
  QueryBuilder<TokenModel, int, QQueryOperations> studentIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'studentId');
    });
  }

  QueryBuilder<TokenModel, String?, QQueryOperations> accessTokenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accessToken');
    });
  }

  QueryBuilder<TokenModel, DateTime?, QQueryOperations> expiryDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiryDate');
    });
  }

  QueryBuilder<TokenModel, String?, QQueryOperations> idTokenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'idToken');
    });
  }

  QueryBuilder<TokenModel, String?, QQueryOperations> issProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'iss');
    });
  }

  QueryBuilder<TokenModel, String?, QQueryOperations> refreshTokenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'refreshToken');
    });
  }
}
