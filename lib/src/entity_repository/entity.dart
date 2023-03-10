import 'package:jbase_package/src/entity_repository/entity_property.dart';

class Entity implements Comparable<Entity> {
  String name = '';
  final List<EntityProperty> _properties = [];

  void addProperty(EntityProperty entityProperty) {
    _properties.add(entityProperty);
  }

  List<EntityProperty> get properties => _properties;

  @override
  String toString() {
    return 'Entity{name: $name, properties: $properties}';
  }

  @override
  int compareTo(Entity other) {
    return name.compareTo(other.name);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    bool hasSameProperties = true;
    for (int i = 0; i < properties.length; i++) {
      if (!(other as Entity).properties.contains(properties[i])) {
        hasSameProperties = false;
        break;
      }
    }
    return hasSameProperties;
  }
}
