import 'dart:convert';

import 'package:jbase_package/jbase_package.dart';
import 'package:jbase_package/src/json_parser/json_parser.dart';
import 'package:jbase_package/src/json_parser/json_parser_result.dart';

class EntityRepository {
  final ControlPlane controlPlane;
  EntityRepository(this.controlPlane);
  final JsonParser _jsonParser = JsonParser();
  final List<Entity> _entities = [];

  Entity addEntity(String name, String json) {
    Entity? existingEntity = matchingEntity(json);
    if (existingEntity != null) {
      return existingEntity;
    }
    Entity entity = Entity(name: name.toLowerCase());
    JsonParserResult jsonParserResult = _jsonParser.buildMapFromJson(json);
    List<Map<String, dynamic>> nestedArrayEntities = [];
    for (int i = 0; i < jsonParserResult.mappedJson.length; i++) {
      EntityPropertyType entityPropertyType = EntityPropertyType.string;
      Entity? entityPropertyValue;
      String key = jsonParserResult.mappedJson.keys.elementAt(i);
      dynamic value = jsonParserResult.mappedJson.values.elementAt(i);
      if (value is int) {
        entityPropertyType = EntityPropertyType.int;
      } else if (value is double) {
        entityPropertyType = EntityPropertyType.double;
      } else if (value is bool) {
        entityPropertyType = EntityPropertyType.bool;
      } else if (value is String) {
        if (value == 'NESTED_ARRAY') {
          entityPropertyType = EntityPropertyType.foreignKey;
        } else {
          entityPropertyType = EntityPropertyType.string;
        }
      } else if (value is Map<String, dynamic>) {
        //Nested
        if (value == {}) {
          continue;
        }
        entityPropertyValue = addEntity(key, jsonEncode(value));
        entityPropertyType = EntityPropertyType.entity;
      } else if (value is List<dynamic> && value.isNotEmpty) {
        // Array
        dynamic firstValue = value.first;
        if (firstValue is Map<String, dynamic>) {
          //entityPropertyValue = addEntity(key, jsonEncode(value));
          firstValue[entity.name] = 'NESTED_ARRAY';
          nestedArrayEntities.add({'key': key, 'value': firstValue});
        } else {
          continue;
        }
        entityPropertyType = EntityPropertyType.list;
      } else {
        continue;
      }
      if (entityPropertyType == EntityPropertyType.list) {
        continue;
      } else {
        final String databaseManagementSystemColumnType = controlPlane
            .databaseManagementSystem
            .entityPropertyTypeToColumnDataType(entityPropertyType);
        entity.addProperty(EntityProperty(
            key: key,
            type: entityPropertyType,
            value: entityPropertyValue,
            databaseManagementSystemColumnType:
                databaseManagementSystemColumnType));
      }
    }
    _entities.add(entity);

    nestedArrayEntities.forEach((element) {
      Entity arrayEntity =
          addEntity(element['key'], jsonEncode(element['value']));

      Entity? parentEntity = getEntity(entity.name);
      if (parentEntity != null) {
        parentEntity.addProperty(EntityProperty(
            key: element['key'],
            type: EntityPropertyType.list,
            value: arrayEntity,
            databaseManagementSystemColumnType: controlPlane
                .databaseManagementSystem
                .entityPropertyTypeToColumnDataType(EntityPropertyType.list)));
      }
    });

    return entity;
  }

  void removeEntity(String name) {
    _entities.removeWhere((entity) => entity.name == name);
  }

  List<Entity> get entities => _entities;

  Entity? getEntity(String name) {
    List<Entity> matchingEntities =
        _entities.where((entity) => entity.name == name).toList();
    if (matchingEntities.isNotEmpty) {
      return matchingEntities.first;
    }
    return null;
  }

  Entity? matchingEntity(String json) {
    Entity? matchingEntity;
    JsonParserResult jsonParserResult = _jsonParser.buildMapFromJson(json);
    for (Entity entity in _entities) {
      for (int i = 0; i < entity.properties.length; i++) {
        matchingEntity = entity;

        if (!jsonParserResult.mappedJson
            .containsKey(entity.properties[i].key)) {
          matchingEntity = null;
        }
      }
    }
    return matchingEntity;
  }

  Map<String, dynamic> toMap() {
    return {
      'entities': _entities.map((x) => x.toMap()).toList(),
    };
  }
}
