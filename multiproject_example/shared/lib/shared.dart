/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'package:catwalk/catwalk.dart';
import 'package:lyell/lyell.dart';

final protocol = JsonRpcProtocol();

@EndpointMacro()
abstract interface class TestEndpoint implements Endpoint {
  Future<String> getName(String userId);

  @TestAnnotation("Test")
  Future<String?> nullableString();
}

class TestAnnotation implements RetainedAnnotation {
  final String value;
  const TestAnnotation(this.value);
}