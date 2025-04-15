import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:conduit_open_api/v3.dart';
import 'package:lyell/lyell.dart';

abstract class CatwalkProtocol {
  CatwalkProtocol();
  String get protocolName;

  final List<CatwalkSerializerModule> serializerModules = [
    DefaultSerializerModule()
  ];

  void addSerializerModule(CatwalkSerializerModule module) {
    serializerModules.add(module);
  }

  CatwalkSerializerNode? resolveSerializer(QualifiedTypeTree type) {
    for (var module in serializerModules) {
      var serializer = module.resolveSerializer(type);
      if (serializer != null) {
        return serializer;
      }
    }
    return null;
  }

  ClientRunner createClientRunner(List<RouteDefinition> routes);
}

abstract class CatwalkSerializerModule {
  CatwalkSerializerNode? resolveSerializer(QualifiedTypeTree type);
  Map<String,APISchemaObject> getSchemaObjects() => {};
}

abstract class CatwalkSerializerNode {

  /// Convert an object into a [jsonEncode] serializable form.
  Object? serializeStructured(dynamic object);

  /// Convert a [jsonEncode] serializable form into an object.
  dynamic deserializeStructured(Object? object);

  /// Returns the schema of the object's serialized structured form.
  APISchemaObject? getStructuredSchema();

  //TODO: Raw / Binary serialization for REST
}