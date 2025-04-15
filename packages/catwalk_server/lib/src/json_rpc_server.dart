import 'dart:async';
import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:catwalk_server/src/server_base.dart';
import 'package:lyell/lyell.dart';
import 'package:shelf/shelf.dart';
import 'package:collection/collection.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_openrouter/shelf_openrouter.dart';

typedef ArgumentAssembler = dynamic Function(Map<String,Object?> argument);
typedef ResultAssembler = Object? Function(dynamic response);
typedef AssemblerEntry = ({List<ArgumentAssembler> arguments, String method, ResultAssembler result});

class RpcRouterEntry<T extends Endpoint> extends RouterEntryBase {
  final CatwalkProtocol protocol;
  final T endpoint;
  final List<RouteDefinition<T>> routes;

  RpcRouterEntry(this.protocol, this.endpoint, this.routes);

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
          return serializer.deserializeStructured(obj[e.name]);
        };
      }).toList();
      var isVoid = route.response.typeArgument == const TypeToken<void>().typeArgument;
      var isDynamic = route.response.typeArgument == const TypeToken<dynamic>().typeArgument;

      if (isVoid || isDynamic) {
        currentValue = (arguments: argumentAssemblers, method: route.name, result: (_) => null);
        assemblers[index] = currentValue;
        return currentValue;
      }

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

  Future<Response> _handle(Request request) async {
    Map<String, dynamic> jsonBody;
    try {
      var body = await request.readAsString();
      jsonBody = jsonDecode(body);
    } on Exception catch (e) {
      return errorResponse(-32700, "Parse error", e.toString());
    }

    var method = jsonBody['method'];
    var params = jsonBody['params'];
    var id = jsonBody['id'];

    Completer<Response> completer = Completer();
    runZonedGuarded(() async {
      var route = routes.firstWhereOrNull((e) {
        return e.name == method;
      });

      if (route == null) {
        throw JsonRpcError(code: -32601, message: "Method not found");
      }

      var routeIndex = routes.indexOf(route);
      var entry = getOrCreate(routeIndex);

      var args = entry.arguments.map((e) => e.call(params)).toList();

      var methodResult = await route.proxy(endpoint, args);

      var result = null;
      if (methodResult == null) {
        if (!route.nullable) throw JsonRpcError(code: -32603, message: "Internal error");
        result = null;
      } else {
        result = entry.result(methodResult);
      }

      var responseBody = jsonEncode({
        'jsonrpc': '2.0',
        'result': result,
        'id': id
      });

      completer.complete(Response.ok(responseBody, headers: {
        'Content-Type': 'application/json-rpc'
      }));
    }, (err,trace) {
      print("Error: $err\n$trace");
      JsonRpcError error = switch(err) {
        JsonRpcError() => err,
        _ => JsonRpcError(code: -32603, message: "Internal error")
      };
      var response = Response.ok(jsonEncode({
        'jsonrpc': '2.0',
        'error': error.toMap(),
        'id': id
      }), headers: {
        'Content-Type': 'application/json-rpc'
      });
      completer.complete(response);
    }, zoneValues: {
      #request: request,
      #id: id
    });
    return await completer.future;
  }

  static Response errorResponse(int code, String message, Object? data) {
    return Response.ok(jsonEncode({
      'jsonrpc': '2.0',
      'error': {
        'code': code,
        'message': message,
        'data': data
      },
      'id': null
    }), headers: {
      'Content-Type': 'application/json-rpc'
    });
  }

  @override
  Future<Response> handle(Request request, List<String> pathArgs) {
    return _handle(request);
  }
}

class JsonRpcServer {

  final router = OpenRouter<RpcRouterEntry>();

  JsonRpcServer();

  void register<T extends Endpoint>(T endpoint, JsonRpcProtocol protocol, List<RouteDefinition<T>> definitions, {String? path = null}) {
    var segments = path?.segments ?? [];
    var entry = RpcRouterEntry<T>(protocol, endpoint, definitions);
    router.addRoute([...segments, "rpc"], "POST", entry);
  }

  Future serve() async {
    var handler = const Pipeline().addMiddleware(logRequests()).addHandler((Request request) async {
      var result = router.lookup(request.url.pathSegments, request.method, []);
      if (result == null) return Response.notFound("");
      return result._handle(request);
    });
    var server = await shelf_io.serve(handler, 'localhost', 8080);
    print('Serving at http://${server.address.host}:${server.port}');
  }
}