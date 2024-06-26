import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:catwalk/src/protocols/shelf.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart';

class RestClientEncoder {

  final CatwalkProtocol protocol;
  final RouteDefinition definition;

  RestClientEncoder(this.protocol, this.definition);
  late ResolvedAnnotations resolved = ResolvedAnnotations.resolve(definition);
  late List<CatwalkSerializerNode> argSerializers = definition.arguments.map((e) {
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

  Request build(String baseUrl, List args) {
    var p = resolved.requestMapping.path;
    for (var i = 0; i < pathVariables.length; i++) {
      var index = pathArgumentIndexes[i];
      var arg = args[index];
      p = p.replaceFirst(":${pathVariables[i]}", arg);
    }
    Map<String,String> queryParameters = {};
    for (var (String key, int i, bool nullable) in queryArguments) {
      var serializer = argSerializers[i];
      var argv = args[i];
      if (argv == null && nullable) continue;
      var value = serializer.serializeStructured(argv);
      queryParameters[key] = value.toString();
    }
    var base = Uri.parse(baseUrl);
    var uri = base.replace(path: p, queryParameters: queryParameters);
    
    var request = Request(resolved.requestMapping.method, uri);
    for (var (String key, int i, bool nullable) in headerArguments) {
      var serializer = argSerializers[i];
      var argv = args[i];
      if (argv == null && nullable) continue;
      var value = serializer.serializeStructured(argv);
      request.headers[key] = value.toString();
    }
    
    if (bodyIndex != null) {
      var serializer = argSerializers[bodyIndex!];
      var value = serializer.serializeStructured(args[bodyIndex!]);
      request.body = jsonEncode(value);
    }

    return request;
  }

  dynamic decode(Response response) {
    var body = response.body;
    var jsonBody = jsonDecode(body);
    if (jsonBody == null && definition.nullable) return null;
    return responseSerializer.deserializeStructured(jsonBody);
  }
}