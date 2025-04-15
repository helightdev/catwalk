import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:catwalk_server/catwalk_server.dart';
import 'package:shelf/shelf.dart';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_openrouter/shelf_openrouter.dart';

class CatwalkServer {
  final OpenRouter<RouterEntryBase> router = OpenRouter();

  void register(RestController controller, CatwalkProtocol protocol, RouteDefinition definition) {
    var entry = RestRouterEntry(controller, protocol, definition);
    try {
      entry.createEncoder();
    } catch (e) {
      print("Error creating encoder for $definition: $e");
      rethrow;
    }

    var mapping = entry.encoder.resolved.requestMapping;
    router.addRoute(mapping.path.segments, mapping.method, entry);

    if (mapping.method == "GET") {
      router.addRoute(mapping.path.segments, "HEAD", RestRouterEntry(controller, protocol, definition, removeBody: true));
    }
  }

  void registerAll(RestController controller, CatwalkProtocol protocol, List<RouteDefinition> definitions) {
    for (var definition in definitions) {
      register(controller, protocol, definition);
    }
  }

  void registerRpc<T extends Endpoint>(T endpoint, JsonRpcProtocol protocol, List<RouteDefinition<T>> definitions, {String? path}) {
    var segments =  protocol.path?.segments ?? [];
    var entry = RpcRouterEntry<T>(protocol, endpoint, definitions);
    router.addRoute([...segments, "rpc"], "POST", entry);
  }

  void registerSwagger(CatwalkProtocol protocol, List<RouteDefinition> definitions, {
    String urlBase = "http://localhost:8080",
    String path = "/api/v3",
  }) {
    var pathSegments = path.segments;

    router.addRoute([...pathSegments, "openapi.json"], "GET", ManualRouteEntry((request, pathArgs) async {
      var document = ShelfOpenapi.generate(protocol, ShelfOpenapi, definitions);
      return Response.ok(jsonEncode(document.asMap()), headers: {"Content-Type": "application/json"});
    }));

    router.addRoute([...pathSegments, "swagger-ui"], "GET", ManualRouteEntry((request, pathArgs) async {
      return Response.ok("""<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="description" content="SwaggerUI" />
    <title>SwaggerUI</title>
    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui.css" />
  </head>
  <body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-bundle.js" crossorigin></script>
  <script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-standalone-preset.js" crossorigin></script>
  <script>
    window.onload = () => {
      window.ui = SwaggerUIBundle({
        url: '${urlBase}/api/v3/openapi.json',
        dom_id: '#swagger-ui',
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIStandalonePreset
        ],
        layout: "StandaloneLayout",
      });
    };
  </script>
  </body>
</html>""", headers: {"Content-Type": "text/html"});
    }));

    print("Swagger UI available at $urlBase$path/swagger-ui");
  }

  Future<Response> call(Request request) async {
    var method = request.method;
    var pathVariableBuffer = <String>[];
    var result = router.lookup(request.url.pathSegments, method, pathVariableBuffer);
    if (result == null) {
      return Response.notFound("");
    }
    return result.handle(request, pathVariableBuffer);
  }

  Future serve() async {
    var handler = const Pipeline().addMiddleware(logRequests()).addHandler(call);
    var server = await shelf_io.serve(handler, 'localhost', 8080);
    print('Serving at http://${server.address.host}:${server.port}');
  }
}

abstract class RouterEntryBase {
  Future<Response> handle(Request request, List<String> pathArgs);
}

class ManualRouteEntry extends RouterEntryBase {
  final Future<Response> Function(Request, List<String>) handler;

  ManualRouteEntry(this.handler);

  @override
  Future<Response> handle(Request request, List<String> pathArgs) {
    return handler(request, pathArgs);
  }
}
