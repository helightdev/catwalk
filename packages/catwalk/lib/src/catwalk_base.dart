import 'dart:async';

import 'package:lyell/lyell.dart';
abstract interface class Endpoint {}


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