import 'package:catwalk/catwalk.dart';
import 'package:client/client.dart';
import 'package:shared/shared.dart';

void main(List<String> arguments) async {
  protocol.client = ShelfRestClient(HttpClientConfig(baseUrl: "http://localhost:8080"));
  var client = TestEndpointClient(protocol, TestEndpoint_routes);
  print(await client.getName("Moin!"));
  print(await client.stuff("Hello", "World", "123"));
}
