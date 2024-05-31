import 'package:catwalk/catwalk.dart';
import 'package:catwalk_server/catwalk_server.dart';
import 'package:example/example.dart';

void main(List<String> arguments) async {
  var server = JsonRpcServer(protocol, TestController(), TestEndpoint.routes);
  await server.serve();

  protocol.client = JsonRpcClient(JsonRpcClientConfig(baseUrl: "http://localhost:8080"));
  var client = TestEndpointClient(protocol);
  print(await client.getName("Moin!"));
}

class TestController implements TestEndpoint {

  @override
  Future<String> getName(String userId) {
    return Future.value("Answer: $userId");
  }

  @override
  Future<String?> nullableString() {
    return Future.value(null);
  }
}