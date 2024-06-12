import 'package:catwalk/catwalk.dart';
import 'package:catwalk_server/catwalk_server.dart';
import 'package:server/server.dart' as server;
import 'package:server/server.dart';
import 'package:shared/shared.dart';

void main(List<String> arguments) async {
  print(TestEndpoint_routes);
  var server = RestServer();
  server.registerAll(TestController(), protocol, TestEndpoint_routes);
  server.registerSwagger(protocol, TestEndpoint_routes);
  await server.serve();
}
