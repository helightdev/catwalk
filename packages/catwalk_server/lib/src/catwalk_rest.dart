import 'dart:async';
import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:catwalk_server/catwalk_server.dart';
import 'package:catwalk_server/src/rest_assembler.dart';
import 'package:catwalk_server/src/server_base.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_openrouter/shelf_openrouter.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

abstract class RestController {
  Request get request => Zone.current[#request];
}
class RestRouterEntry extends RouterEntryBase {
  final CatwalkProtocol protocol;
  final RouteDefinition definition;
  final RestController controller;

  final bool removeBody;

  RestRouterEntry(this.controller, this.protocol, this.definition, {this.removeBody = false});

  late RestServerEncoder encoder;

  void createEncoder() {
    encoder = RestServerEncoder(protocol, definition);
  }

  Future<Response> handle(Request request, List<String> pathArgs) async {
    var args = await encoder.parse(request, pathArgs);
    var completer = Completer<Response>();
    runZonedGuarded(() async {
      var ret = await definition.invokeProxy(controller, args);
      completer.complete(encoder.build(ret));
    }, (err,trace) {
      if (err is Response) {
        completer.complete(err);
      } else {
        print("Request Error: $err\n$trace");
        completer.complete(Response.internalServerError());
      }
    }, zoneValues: {
      #request: request
    });
    var result = await completer.future;
    if (removeBody) return Response.ok("");
    return encoder.build(result);
  }
}