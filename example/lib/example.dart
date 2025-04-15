import 'package:catwalk/catwalk.dart';

final protocol = JsonRpcProtocol()
  ..path = "/api"
  ..client = JsonRpcClient(HttpClientConfig());

final restProtocol = ShelfRestProtocol();

@CatwalkEndpoint()
abstract interface class TestEndpoint implements Endpoint {
  Future<String> getName(String userId);

  Future<String?> nullableString();
}