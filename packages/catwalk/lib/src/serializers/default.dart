import 'package:catwalk/catwalk.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:lyell/lyell.dart';
import 'package:lyell/src/qualified_tree.dart';

class DefaultSerializerModule extends CatwalkSerializerModule {
  final Map<Type, CatwalkSerializerNode> serializers = {
    String: StringSerializer(),
    int: IntSerializer(),
    double: DoubleSerializer(),
    bool: BoolSerializer(),
  };

  @override
  CatwalkSerializerNode? resolveSerializer(QualifiedTypeTree<dynamic, dynamic> type) {
    return serializers[type.qualified.typeArgument];
  }
}

class StringSerializer extends CatwalkSerializerNode {
  @override
  Object? serializeStructured(dynamic object) => object as String;

  @override
  dynamic deserializeStructured(Object? object) => object as String;

  @override
  APISchemaObject? getStructuredSchema() => APISchemaObject.string();
}

class IntSerializer extends CatwalkSerializerNode {
  @override
  Object? serializeStructured(dynamic object) => object as int;

  @override
  dynamic deserializeStructured(Object? object) => object as int;

  @override
  APISchemaObject? getStructuredSchema() => APISchemaObject.integer();
}

class DoubleSerializer extends CatwalkSerializerNode {
  @override
  Object? serializeStructured(dynamic object) => object as double;

  @override
  dynamic deserializeStructured(Object? object) => object as double;

  @override
  APISchemaObject? getStructuredSchema() => APISchemaObject.number();
}

class BoolSerializer extends CatwalkSerializerNode {
  @override
  Object? serializeStructured(dynamic object) => object as bool;

  @override
  dynamic deserializeStructured(Object? object) => object as bool;

  @override
  APISchemaObject? getStructuredSchema() => APISchemaObject.boolean();
}