// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unused_field, unused_import, public_member_api_docs, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

import 'dart:core';
import 'dart:async';
import 'package:lyell/lyell.dart' as gen;
import 'package:catwalk/catwalk.dart' as gen;
import 'dart:core' as gen0;
import 'package:shared/shared.dart' as gen1;
import 'package:catwalk/src/protocols/shelf/annotations.dart' as gen2;
import 'package:shared/shared.dart';

final List<gen.RouteDefinition<gen1.TestEndpoint>> TestEndpoint_routes = [
  gen.RouteDefinition<gen1.TestEndpoint>(
    [gen2.GET('/name/:userId')],
    gen.QualifiedTerminal<gen0.String>(),
    false,
    [gen.MethodArgument(gen.QualifiedTerminal<gen0.String>(), false, 'userId', [])],
    (obj, args) => obj.getName(args[0]),
    'getName',
  ),
  gen.RouteDefinition<gen1.TestEndpoint>(
    [gen2.POST('/stuff')],
    gen.QualifiedTerminal<gen0.String>(),
    false,
    [
      gen.MethodArgument(gen.QualifiedTerminal<gen0.String>(), false, 'body', [gen2.body]),
      gen.MethodArgument(gen.QualifiedTerminal<gen0.String>(), false, 'testHeader', [gen2.header]),
      gen.MethodArgument(gen.QualifiedTerminal<gen0.String>(), false, 'queryParam', [gen2.query])
    ],
    (obj, args) => obj.stuff(args[0], args[1], args[2]),
    'stuff',
  ),
  gen.RouteDefinition<gen1.TestEndpoint>(
    [gen1.TestAnnotation('Test')],
    gen.QualifiedTerminal<gen0.String>(),
    true,
    [],
    (obj, args) => obj.nullableString(),
    'nullableString',
  )
];
