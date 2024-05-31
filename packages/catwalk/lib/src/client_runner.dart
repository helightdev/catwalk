import 'package:catwalk/catwalk.dart';
import 'package:catwalk/src/protocol.dart';

abstract class ClientRunner {
  Future<dynamic> run(int index, List args);
}