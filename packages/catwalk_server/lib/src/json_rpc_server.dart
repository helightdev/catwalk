import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:shelf/shelf.dart';
import 'package:collection/collection.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

typedef ArgumentAssembler = dynamic Function(Map<String,Object?> argument);
typedef ResultAssembler = Object? Function(dynamic response);
typedef AssemblerEntry = ({List<ArgumentAssembler> arguments, String method, ResultAssembler result});

class JsonRpcServer<T extends Endpoint> {

  final CatwalkProtocol protocol;
  final T endpoint;
  final List<RouteDefinition<T>> routes;

  JsonRpcServer(this.protocol, this.endpoint, this.routes);

  late final List<AssemblerEntry?> assemblers = List.filled(routes.length, null);

  AssemblerEntry getOrCreate(int index) {
    var currentValue = assemblers[index];
    if (currentValue == null) {
      var route = routes[index];
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
      currentValue = (arguments: argumentAssemblers, method: route.name, result: result);
      assemblers[index] = currentValue;
    }

    return currentValue;
  }

  Future serve() async {
    var handler = const Pipeline().addMiddleware(logRequests()).addHandler(_handle);
    var server = await shelf_io.serve(handler, 'localhost', 8080);
    print('Serving at http://${server.address.host}:${server.port}');
  }

  Future<Response> _handle(Request request) async {
    if (request.method != 'POST') {
      return Response.notFound('Not Found');
    }
    if (request.requestedUri.path != "/rpc") {
      return Response.notFound('Not Found');
    }
    var body = await request.readAsString();
    var jsonBody = jsonDecode(body);

    var method = jsonBody['method'];
    var params = jsonBody['params'];

    var route = routes.firstWhere((e) {
      return e.name == method;
    });
    var routeIndex = routes.indexOf(route);
    var entry = getOrCreate(routeIndex);

    var args = entry.arguments.map((e) => e.call(params)).toList();
    var methodResult = await route.proxy(endpoint, args);
    var result = entry.result(methodResult);

    var responseBody = jsonEncode({
      'jsonrpc': '2.0',
      'result': result,
      'id': jsonBody['id']
    });

    return Response.ok(responseBody);
  }

}