import 'package:catwalk/catwalk.dart';
import 'package:collection/collection.dart';
import 'package:lyell/lyell.dart';

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

  var isVoid = route.response.typeArgument == const TypeToken<void>().typeArgument;
  var isDynamic = route.response.typeArgument == const TypeToken<dynamic>().typeArgument;

  if (isVoid || isDynamic) {
    return (arguments: argumentAssemblers, method: route.name, result: (_) => null);
  }

  var resultSerializer = protocol.resolveSerializer(route.response);
  if (resultSerializer == null) {
    throw StateError("No serializer found for ${route.response}");
  }
  result(obj) => resultSerializer.deserializeStructured(obj);
  return (arguments: argumentAssemblers, method: route.name, result: result);
}