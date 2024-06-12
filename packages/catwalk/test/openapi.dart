import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:catwalk/src/protocols/shelf.dart';
import 'package:lyell/lyell.dart';
import 'package:test/test.dart';

void main() {
  test("Test", () {
    var routes = [
      RouteDefinition([], QualifiedTypeTree.terminal<int>(), false, [
        MethodArgument(QualifiedTypeTree.terminal<String>(), false, "body", [body])
      ], (obj,args) => throw UnimplementedError(), "someInt"),

      RouteDefinition([
        GET("/hello/:name")
      ], QualifiedTypeTree.terminal<String>(), false, [
        MethodArgument(QualifiedTypeTree.terminal<String>(), false, "name", []),
      ], (obj,args) => throw UnimplementedError(), "helloVariable"),

      RouteDefinition([
        DELETE("/hello/:name")
      ], QualifiedTypeTree.terminal<String>(), false, [
        MethodArgument(QualifiedTypeTree.terminal<String>(), false, "name", []),
      ], (obj,args) => throw UnimplementedError(), "byeVariable"),

      RouteDefinition([
        GET("/helloQuery")
      ], QualifiedTypeTree.terminal<String>(), false, [
        MethodArgument(QualifiedTypeTree.terminal<String>(), true, "name", [Query("name")]),
      ], (obj,args) => throw UnimplementedError(), "helloQuery"),

      RouteDefinition([
        GET("/helloHeader")
      ], QualifiedTypeTree.terminal<String>(), false, [
        MethodArgument(QualifiedTypeTree.terminal<String>(), false, "name", [Header("name")]),
      ], (obj,args) => throw UnimplementedError(), "helloHeader"),
    ];
    var protocol = ShelfRestProtocol();
    var doc = ShelfOpenapi.generate(protocol, ShelfOpenapi, routes);
    print(jsonEncode(doc.asMap()));
    // If this completes we are fine for now, no need to expect anything for now
  });
}