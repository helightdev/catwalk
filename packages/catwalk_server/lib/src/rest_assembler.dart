import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:shelf/shelf.dart';

class RestServerEncoder {

  final CatwalkProtocol protocol;
  final RouteDefinition definition;

  RestServerEncoder(this.protocol, this.definition);

  late ResolvedAnnotations resolved = ResolvedAnnotations.resolve(definition);
  late List<CatwalkSerializerNode> argSerializers = definition.arguments.map((
      e) {
    var serializer = protocol.resolveSerializer(e.type);
    if (serializer == null) {
      throw StateError("No serializer found for ${e.type}");
    }
    return serializer;
  }).toList();

  late CatwalkSerializerNode responseSerializer = () {
    var serializer = protocol.resolveSerializer(definition.response);
    if (serializer == null) {
      throw StateError("No serializer found for ${definition.response}");
    }
    return serializer;
  }();

  late List<String> pathVariables = SegmentUtils.getVariableSegments(resolved.requestMapping.path);
  late List<int> pathArgumentIndexes = pathVariables.map((e) => definition.arguments.indexWhere((element) {
    var path = resolved.pathArguments[element];
    return path != null && path.name == e;
  })).toList();

  late List<(String, int, bool nullable)> queryArguments = resolved.queryArguments.entries.map((e) {
    var index = definition.arguments.indexOf(e.key);
    return (e.value.name!, index, e.key.nullable);
  }).toList();

  late List<(String, int, bool nullable)> headerArguments = resolved.headerArguments.entries.map((e) {
    var index = definition.arguments.indexOf(e.key);
    return (e.value.name!, index, e.key.nullable);
  }).toList();

  late int? bodyIndex = resolved.bodyArgument != null ? definition.arguments.indexOf(resolved.bodyArgument!) : null;

  late bool bodyNullable = resolved.bodyArgument?.nullable ?? false;

  Future<List> parse(Request request, List<String> pathArgs) async {
    final args = List<dynamic>.filled(argSerializers.length, null);

    final bodyIndex = this.bodyIndex;
    if (bodyIndex != null) {
      final bodyStr = await request.readAsString();
      final body = jsonDecode(bodyStr);
      if (bodyNullable && body == null) args[bodyIndex] = null;
      else args[bodyIndex] = argSerializers[bodyIndex].deserializeStructured(body);
    }

    for (var (String key, int i, bool nullable) in queryArguments) {
      var value = request.url.queryParameters[key];
      if (value == null && nullable) continue;
      args[i] = argSerializers[i].deserializeStructured(value);
    }

    for (var (String key, int i, bool nullable) in headerArguments) {
      var value = request.headers[key];
      if (value == null && nullable) continue;
      args[i] = argSerializers[i].deserializeStructured(value);
    }

    for (var i = 0; i < pathVariables.length; i++) {
      var index = pathArgumentIndexes[i];
      args[index] = pathArgs[i];
    }

    return args;
  }

  Response build(dynamic result) {
    var value = responseSerializer.serializeStructured(result);
    return Response.ok(jsonEncode(value), headers: {'Content-Type': 'application/json'});
  }

}