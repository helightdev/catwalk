import 'package:catwalk/catwalk.dart';
import 'package:catwalk/src/protocols/shelf/resolution.dart';
import 'package:conduit_open_api/v3.dart';

class ShelfOpenapi {
  static APIDocument generate(CatwalkProtocol protocol, Type endpoint, List<RouteDefinition> definitions) {
    var document = APIDocument();
    document.version = "3.0.0";
    document.info = APIInfo("Catwalk API", "1.0.0");

    var resolvedDefs = definitions.map((e) => ResolvedAnnotations.resolve(e)).toList();
    var pathSet = resolvedDefs.map((e) => e.requestMapping.path).toSet();

    Map<String,APIPath> paths = {};
    for (var path in pathSet) {
      var formattedPath = path.split("/").map((e) {
        if (e.startsWith(":")) {
          return "{${e.substring(1)}}";
        }
        return e;
      }).join("/");

      Map<String, APIOperation> operations = {};
      var childDefs = resolvedDefs.where((e) => e.requestMapping.path == path).toList();
      for (var child in childDefs) {
        var index = resolvedDefs.indexOf(child);
        var definition = definitions[index];
        var response = protocol.resolveSerializer(definition.response)!;

        var responses = {
          "200": APIResponse(
              "Default response",
              content: {
                "application/json": APIMediaType(
                    schema: response.getStructuredSchema()
                )
              }
          )
        };

        var operation = APIOperation(
            definition.name, responses
        );

        child.pathArguments.forEach((arg,path) {
          operation.addParameter(APIParameter.path(path.name));
        });

        child.queryArguments.forEach((arg, query) {
          operation.addParameter(APIParameter.query(query.name, schema: APISchemaObject.string(), isRequired: !arg.nullable));
        });

        child.headerArguments.forEach((arg, header) {
          operation.addParameter(APIParameter.header(header.name, schema: APISchemaObject.string(), isRequired: !arg.nullable));
        });

        if (child.bodyArgument != null) {
          var body = child.bodyArgument!;
          var isRequired = !body.nullable;
          operation.requestBody = APIRequestBody({
            "application/json": APIMediaType(
                schema: protocol.resolveSerializer(body.type)!.getStructuredSchema()
            )
          }, isRequired: isRequired);
        }

        operations[child.requestMapping.method] = operation;
      }
      protocol.serializerModules.forEach((element) {
        element.getSchemaObjects().forEach((key, value) {
          document.components!.schemas[key] = value;
        });
      });

      paths[formattedPath] = APIPath(operations: operations);
    }
    document.paths = paths;

    return document;
  }

}