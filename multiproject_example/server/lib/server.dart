import 'dart:async';

import 'package:catwalk_server/catwalk_server.dart';
import 'package:shared/shared.dart';

class TestController extends RestController implements TestEndpoint {

  @override
  Future<String> getName(String userId) {
    return Future.value("Answer: $userId");
  }

  @override
  Future<String?> nullableString() {
    return Future.value(null);
  }

  @override
  FutureOr<String> stuff(String body, String testHeader, String queryParam) {
    return "Body: $body, Header: $testHeader, Query: $queryParam";
  }
}