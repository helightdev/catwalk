import 'package:catwalk/catwalk.dart';
import 'package:collection/collection.dart';

typedef ArgumentAssembler = MapEntry<String, Object?> Function(dynamic argument);
typedef ResultAssembler = dynamic Function(Object? response);
typedef AssemblerEntry = ({List<ArgumentAssembler> arguments, String method, ResultAssembler result});

AssemblerEntry createAssemblerEntry(CatwalkProtocol protocol, RouteDefinition route) {
  var argumentAssemblers = route.arguments.mapIndexed((i, e) {
    var serializer = protocol.resolveSerializer(e.type);
    if (serializer == null) {
      throw StateError("No serializer found for ${e.type}");
    }
    return (obj) => MapEntry(e.name, serializer.serializeStructured(obj));
  }).toList();
  var resultSerializer = protocol.resolveSerializer(route.response);
  if (resultSerializer == null) {
    throw StateError("No serializer found for ${route.response}");
  }
  result(obj) => resultSerializer.deserializeStructured(obj);
  return (arguments: argumentAssemblers, method: route.name, result: result);
}


typedef ServerArgumentAssembler = dynamic Function(Map<String,Object?> argument);
typedef ServerResultAssembler = Object? Function(dynamic response);
typedef ServerAssemblerEntry = ({List<ServerArgumentAssembler> arguments, String method, ServerResultAssembler result});

ServerAssemblerEntry createServerAssemblerEntry(CatwalkProtocol protocol, RouteDefinition route) {
  var argumentAssemblers = route.arguments.mapIndexed((i, e) {
    var serializer = protocol.resolveSerializer(e.type);
    if (serializer == null) {
      throw StateError("No serializer found for ${e.type}");
    }
    return (Map<String,Object?> obj) {
      var paramValue = obj[e.name];
      print("paramValue: $paramValue for ${e.name}");
      return serializer.deserializeStructured(paramValue);
    };
  }).toList();
  var resultSerializer = protocol.resolveSerializer(route.response);
  if (resultSerializer == null) {
    throw StateError("No serializer found for ${route.response}");
  }
  result(obj) => resultSerializer.serializeStructured(obj);
  return (arguments: argumentAssemblers, method: route.name, result: result);
}