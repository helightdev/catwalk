import 'package:catwalk/catwalk.dart';
import 'package:client/client.dart';
import 'package:shared/shared.dart';

void main(List<String> arguments) async {
  protocol.client = JsonRpcClient(JsonRpcClientConfig(baseUrl: "http://localhost:8080"));
  var client = TestEndpointClient(protocol);
  print(await client.getName("Moin!"));
}
