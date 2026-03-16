// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'source_subscription.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSourceSubscriptionCollection on Isar {
  IsarCollection<SourceSubscription> get sourceSubscriptions =>
      this.collection();
}

const SourceSubscriptionSchema = CollectionSchema(
  name: r'SourceSubscription',
  id: 4545363412549571718,
  properties: {
    r'autoUpdate': PropertySchema(
      id: 0,
      name: r'autoUpdate',
      type: IsarType.bool,
    ),
    r'customOrder': PropertySchema(
      id: 1,
      name: r'customOrder',
      type: IsarType.long,
    ),
    r'lastUpdateTime': PropertySchema(
      id: 2,
      name: r'lastUpdateTime',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 4,
      name: r'type',
      type: IsarType.long,
    ),
    r'url': PropertySchema(
      id: 5,
      name: r'url',
      type: IsarType.string,
    )
  },
  estimateSize: _sourceSubscriptionEstimateSize,
  serialize: _sourceSubscriptionSerialize,
  deserialize: _sourceSubscriptionDeserialize,
  deserializeProp: _sourceSubscriptionDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _sourceSubscriptionGetId,
  getLinks: _sourceSubscriptionGetLinks,
  attach: _sourceSubscriptionAttach,
  version: '3.1.0+1',
);

int _sourceSubscriptionEstimateSize(
  SourceSubscription object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.url.length * 3;
  return bytesCount;
}

void _sourceSubscriptionSerialize(
  SourceSubscription object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.autoUpdate);
  writer.writeLong(offsets[1], object.customOrder);
  writer.writeLong(offsets[2], object.lastUpdateTime);
  writer.writeString(offsets[3], object.name);
  writer.writeLong(offsets[4], object.type);
  writer.writeString(offsets[5], object.url);
}

SourceSubscription _sourceSubscriptionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SourceSubscription(
    autoUpdate: reader.readBoolOrNull(offsets[0]) ?? false,
    customOrder: reader.readLongOrNull(offsets[1]) ?? 0,
    lastUpdateTime: reader.readLongOrNull(offsets[2]) ?? 0,
    name: reader.readStringOrNull(offsets[3]) ?? "",
    type: reader.readLongOrNull(offsets[4]) ?? 0,
    url: reader.readStringOrNull(offsets[5]) ?? "",
  );
  object.id = id;
  return object;
}

P _sourceSubscriptionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 2:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 3:
      return (reader.readStringOrNull(offset) ?? "") as P;
    case 4:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 5:
      return (reader.readStringOrNull(offset) ?? "") as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _sourceSubscriptionGetId(SourceSubscription object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _sourceSubscriptionGetLinks(
    SourceSubscription object) {
  return [];
}

void _sourceSubscriptionAttach(
    IsarCollection<dynamic> col, Id id, SourceSubscription object) {
  object.id = id;
}

extension SourceSubscriptionQueryWhereSort
    on QueryBuilder<SourceSubscription, SourceSubscription, QWhere> {
  QueryBuilder<SourceSubscription, SourceSubscription, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SourceSubscriptionQueryWhere
    on QueryBuilder<SourceSubscription, SourceSubscription, QWhereClause> {
  QueryBuilder<SourceSubscription, SourceSubscription, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterWhereClause>
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

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterWhereClause>
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

extension SourceSubscriptionQueryFilter
    on QueryBuilder<SourceSubscription, SourceSubscription, QFilterCondition> {
  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      autoUpdateEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'autoUpdate',
        value: value,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      customOrderEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      customOrderGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      customOrderLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customOrder',
        value: value,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      customOrderBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customOrder',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
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

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      idLessThan(
    Id value, {
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

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
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

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      lastUpdateTimeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      lastUpdateTimeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUpdateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      lastUpdateTimeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUpdateTime',
        value: value,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      lastUpdateTimeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUpdateTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      typeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      typeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      typeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      typeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      urlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      urlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'url',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      urlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'url',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      urlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'url',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'url',
        value: '',
      ));
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterFilterCondition>
      urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'url',
        value: '',
      ));
    });
  }
}

extension SourceSubscriptionQueryObject
    on QueryBuilder<SourceSubscription, SourceSubscription, QFilterCondition> {}

extension SourceSubscriptionQueryLinks
    on QueryBuilder<SourceSubscription, SourceSubscription, QFilterCondition> {}

extension SourceSubscriptionQuerySortBy
    on QueryBuilder<SourceSubscription, SourceSubscription, QSortBy> {
  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByAutoUpdate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoUpdate', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByAutoUpdateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoUpdate', Sort.desc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByCustomOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customOrder', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByCustomOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customOrder', Sort.desc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByLastUpdateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdateTime', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByLastUpdateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdateTime', Sort.desc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension SourceSubscriptionQuerySortThenBy
    on QueryBuilder<SourceSubscription, SourceSubscription, QSortThenBy> {
  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByAutoUpdate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoUpdate', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByAutoUpdateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'autoUpdate', Sort.desc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByCustomOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customOrder', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByCustomOrderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customOrder', Sort.desc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByLastUpdateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdateTime', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByLastUpdateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdateTime', Sort.desc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QAfterSortBy>
      thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension SourceSubscriptionQueryWhereDistinct
    on QueryBuilder<SourceSubscription, SourceSubscription, QDistinct> {
  QueryBuilder<SourceSubscription, SourceSubscription, QDistinct>
      distinctByAutoUpdate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'autoUpdate');
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QDistinct>
      distinctByCustomOrder() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customOrder');
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QDistinct>
      distinctByLastUpdateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdateTime');
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QDistinct>
      distinctByName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QDistinct>
      distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }

  QueryBuilder<SourceSubscription, SourceSubscription, QDistinct> distinctByUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }
}

extension SourceSubscriptionQueryProperty
    on QueryBuilder<SourceSubscription, SourceSubscription, QQueryProperty> {
  QueryBuilder<SourceSubscription, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SourceSubscription, bool, QQueryOperations>
      autoUpdateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'autoUpdate');
    });
  }

  QueryBuilder<SourceSubscription, int, QQueryOperations>
      customOrderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customOrder');
    });
  }

  QueryBuilder<SourceSubscription, int, QQueryOperations>
      lastUpdateTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdateTime');
    });
  }

  QueryBuilder<SourceSubscription, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<SourceSubscription, int, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<SourceSubscription, String, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }
}
