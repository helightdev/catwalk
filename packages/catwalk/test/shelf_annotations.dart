import 'dart:math';

import 'package:catwalk/catwalk.dart';
import 'package:catwalk/src/protocols/shelf.dart';
import 'package:lyell/lyell.dart';
import 'package:test/test.dart';

void main() {
  test("Implicit Path", () {
    var route = RouteDefinition([], QualifiedTypeTree.terminal<String>(), false, [
      MethodArgument(QualifiedTypeTree.terminal<String>(), false, "body", [body])
    ], (obj,args) => throw UnimplementedError(), "test");
    var annotations = ResolvedAnnotations.resolve(route);
    expect(annotations.requestMapping.path, "/test");
    expect(annotations.requestMapping.method, "POST");
    expect(annotations.bodyArgument, isNotNull);
    expect(annotations.bodyArgument!.name, "body");
    expect(annotations.unresolvedArguments, isEmpty);
  });

  test("Implicit Path Arg", () {
    var route = RouteDefinition([
      GET("/hello/:name")
    ], QualifiedTypeTree.terminal<String>(), false, [
      MethodArgument(QualifiedTypeTree.terminal<String>(), false, "name", []),
      MethodArgument(QualifiedTypeTree.terminal<String>(), false, "body", [body])
    ], (obj,args) => throw UnimplementedError(), "test");
    var annotations = ResolvedAnnotations.resolve(route);
    expect(annotations.requestMapping.path, "/hello/:name");
    expect(annotations.requestMapping.method, "GET");
    expect(annotations.bodyArgument, isNotNull);
    expect(annotations.bodyArgument!.name, "body");
    expect(annotations.unresolvedArguments, isEmpty);
  });

  test("Explicit Path Arg", () {
    var route = RouteDefinition([
      GET("/hello/:id")
    ], QualifiedTypeTree.terminal<String>(), false, [
      MethodArgument(QualifiedTypeTree.terminal<String>(), false, "userId", [Path("id")]),
      MethodArgument(QualifiedTypeTree.terminal<String>(), false, "body", [body])
    ], (obj,args) => throw UnimplementedError(), "test");
    var annotations = ResolvedAnnotations.resolve(route);
    expect(annotations.requestMapping.path, "/hello/:id");
    expect(annotations.requestMapping.method, "GET");
    expect(annotations.pathArguments.length, 1);
    expect(annotations.pathArguments.values.first.name, "id");
    expect(annotations.bodyArgument, isNotNull);
    expect(annotations.bodyArgument!.name, "body");
    expect(annotations.unresolvedArguments, isEmpty);
  });

  test("Implicit Body", () {
    var route = RouteDefinition([
      POST("/hello")
    ], QualifiedTypeTree.terminal<String>(), false, [
      MethodArgument(QualifiedTypeTree.terminal<String>(), false, "body", [])
    ], (obj,args) => throw UnimplementedError(), "test");
    var annotations = ResolvedAnnotations.resolve(route);
    expect(annotations.requestMapping.path, "/hello");
    expect(annotations.requestMapping.method, "POST");
    expect(annotations.bodyArgument, isNotNull);
    expect(annotations.unresolvedArguments, isEmpty);
  });

  test("Query Arg", () {
    var route = RouteDefinition([
      GET("/hello")
    ], QualifiedTypeTree.terminal<String>(), false, [
      MethodArgument(QualifiedTypeTree.terminal<String>(), false, "name", [query]),
      MethodArgument(QualifiedTypeTree.terminal<String>(), false, "ageStr", [Query("age")]),
    ], (obj,args) => throw UnimplementedError(), "test");
    var annotations = ResolvedAnnotations.resolve(route);
    expect(annotations.requestMapping.path, "/hello");
    expect(annotations.requestMapping.method, "GET");
    expect(annotations.queryArguments.length, 2);
    expect(annotations.queryArguments.values.first.name, "name");
    expect(annotations.queryArguments.values.last.name, "age");
    expect(annotations.unresolvedArguments, isEmpty);
  });

  test("Header Arg", () {
    var route = RouteDefinition([
      GET("/hello")
    ], QualifiedTypeTree.terminal<String>(), false, [
      MethodArgument(QualifiedTypeTree.terminal<String>(), false, "name", [header]),
      MethodArgument(QualifiedTypeTree.terminal<String>(), false, "ageStr", [Header("age")]),
    ], (obj,args) => throw UnimplementedError(), "test");
    var annotations = ResolvedAnnotations.resolve(route);
    expect(annotations.requestMapping.path, "/hello");
    expect(annotations.requestMapping.method, "GET");
    expect(annotations.headerArguments.length, 2);
    expect(annotations.headerArguments.values.first.name, "name");
    expect(annotations.headerArguments.values.last.name, "age");
    expect(annotations.unresolvedArguments, isEmpty);
  });
}