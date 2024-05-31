import 'package:shared/shared.dart';

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