import 'package:catwalk/catwalk.dart';

final protocol = JsonRpcProtocol()
  ..client = JsonRpcClient(JsonRpcClientConfig());

@EndpointMacro()
abstract interface class TestEndpoint implements Endpoint {
  Future<String> getName(String userId);

  Future<String?> nullableString();
}

@ClientMacro()
class TestEndpointClient implements TestEndpoint {}