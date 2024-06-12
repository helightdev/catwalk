/// Support for doing something awesome.
///
/// More dartdocs go here.
library;

import 'dart:async';

import 'package:catwalk/catwalk.dart';
import 'package:lyell/lyell.dart';

export 'catwalk.g.dart';

final protocol = ShelfRestProtocol();

@EndpointPolyfill()
abstract interface class TestEndpoint implements Endpoint {

  @GET("/name/:userId")
  FutureOr<String> getName(String userId);

  @POST("/stuff")
  FutureOr<String> stuff(@body String body, @header String testHeader, @query String queryParam);

  @TestAnnotation("Test")
  FutureOr<String?> nullableString();
}

class TestAnnotation implements RetainedAnnotation {
  final String value;
  const TestAnnotation(this.value);
}