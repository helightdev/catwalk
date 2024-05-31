/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'package:catwalk/catwalk.dart';

final protocol = JsonRpcProtocol();

@EndpointMacro()
abstract interface class TestEndpoint implements Endpoint {
  Future<String> getName(String userId);

  Future<String?> nullableString();
}