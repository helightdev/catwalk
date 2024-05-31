import 'package:catwalk/catwalk.dart';
import 'package:catwalk/src/client_macro.dart';
import 'package:catwalk/src/endpoint_macro.dart';

void main() {
  var controller = TestController.routes;
  print(controller);
}

@EndpointMacro()
abstract interface class TestController implements Endpoint {
  Future<String> getName(String userId);

  Future<Map<String, String>> getMap(String userId, String attribute);

  Future<void> noReturnValue();

  Future<String?> nullableString();
}

@ClientMacro()
class TestClient implements TestController {}
