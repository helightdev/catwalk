import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:catwalk_server/src/rest_assembler.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_openrouter/shelf_openrouter.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

abstract class RestController {
  late RequestContext context;
}

class RequestContext {

}

class RestServer {
  final OpenRouter<RouterEntryBase> router = OpenRouter();

  void register(RestController controller, CatwalkProtocol protocol, RouteDefinition definition) {
    var entry = RouteEntry(controller, protocol, definition);
    var mapping = entry.encoder.resolved.requestMapping;
    router.addRoute(mapping.path.segments, mapping.method, entry);

    if (mapping.method == "GET") {
      router.addRoute(mapping.path.segments, "HEAD", RouteEntry(controller, protocol, definition, removeBody: true));
    }
  }

  void registerAll(RestController controller, CatwalkProtocol protocol, List<RouteDefinition> definitions) {
    for (var definition in definitions) {
      register(controller, protocol, definition);
    }
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
    print(pathVariableBuffer);
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

class RouteEntry extends RouterEntryBase {
  final CatwalkProtocol protocol;
  final RouteDefinition definition;
  final RestController controller;

  final bool removeBody;

  RouteEntry(this.controller, this.protocol, this.definition, {this.removeBody = false});

  late RestServerEncoder encoder = RestServerEncoder(protocol, definition);

  Future<Response> handle(Request request, List<String> pathArgs) async {
    var args = await encoder.parse(request, pathArgs);
    var result = await definition.invokeProxy(controller, args);
    if (removeBody) return Response.ok("");
    return encoder.build(result);
  }
}