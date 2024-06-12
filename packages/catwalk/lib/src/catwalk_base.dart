import 'dart:async';

import 'package:lyell/lyell.dart';
abstract interface class Endpoint {}

class EndpointPolyfill {
  const EndpointPolyfill();
}

typedef MethodProxy<T> = FutureOr<dynamic> Function(T obj, List<dynamic> args);

class RouteDefinition<T> {
  final List<RetainedAnnotation> annotations;
  final QualifiedTypeTree response;
  final bool nullable;
  final List<MethodArgument> arguments;
  final MethodProxy<T> proxy;
  final String name;

  const RouteDefinition(this.annotations, this.response, this.nullable, this.arguments, this.proxy, this.name);

  @override
  String toString() {
    return 'RouteDefinition{annotations: $annotations, response: $response, arguments: $arguments, proxy: $proxy, name: $name}';
  }

  dynamic invokeProxy(dynamic obj, List args) => proxy(obj as T, args);
}

class MethodArgument {
  final QualifiedTypeTree type;
  final bool nullable;
  final String name;
  final List<RetainedAnnotation> annotations;

  const MethodArgument(this.type, this.nullable, this.name, this.annotations);

  @override
  String toString() {
    return 'MethodArgument{type: $type, nullable: $nullable, name: $name, annotations: $annotations}';
  }
}

extension StringExtension on String {

  List<String> get segments {
    var str = this;
    if (str.startsWith('/')) {
      str = str.substring(1);
    }
    if (str.endsWith('/')) {
      str = str.substring(0, str.length - 1);
    }
    return str.split('/');
  }
}

class SegmentUtils {

  static List<String> getVariableSegments(String path) => path.segments
      .where((element) => element.startsWith(':'))
      .map((element) => element.substring(1))
      .toList();

}