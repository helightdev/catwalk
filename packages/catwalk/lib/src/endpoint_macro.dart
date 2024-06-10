import 'dart:async';

import 'package:catwalk/src/macro_utils.dart';
import 'package:macros/macros.dart';
import 'package:lyell/lyell.dart';
import 'package:lyell/src/lyell_base.dart';
import 'package:collection/collection.dart';

macro class EndpointMacro implements ClassDeclarationsMacro, ClassDefinitionMacro {

  const EndpointMacro();

  @override
  FutureOr<void> buildDeclarationsForClass(ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    var [dartList, catwalkRouteDefinition, overrideAnnotation] = await builder.resolveMany([
      (_dartCore, 'List'),
      (_catwalk, 'RouteDefinition'),
      (_dartCore, 'override')
    ]);

    builder.declareInType(DeclarationCode.fromParts([
      "external static ",
      NamedTypeAnnotationCode(name: dartList, typeArguments: [NamedTypeAnnotationCode(name: catwalkRouteDefinition, typeArguments: [NamedTypeAnnotationCode(name: clazz.identifier)])]),
      " get routes;"
    ]));
  }

  @override
  FutureOr<void> buildDefinitionForClass(ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    var [dartList, dartObject, catwalkRouteDefinition, catwalkMethodArgument,
    qualifiedTerminal, qualifiedTypeTreeN, retainedAnnotation] = await builder.resolveMany([
      (_dartCore, 'List'),
      (_dartCore, 'Object'),
      (_catwalk, 'RouteDefinition'),
      (_catwalk, 'MethodArgument'),
      (_lyellQualifiedTree, 'QualifiedTerminal'),
      (_lyellQualifiedTree, 'QualifiedTypeTreeN'),
      (_lyellBase, 'RetainedAnnotation')
    ]);

    List<Code> routes = [];
    for (var method in filterCatwalkMethodCandidates(await builder.methodsOf(clazz))) {
      List<Code> arguments = [];
      for (var argument in method.positionalParameters) {
        arguments.add(RawCode.fromParts([
          NamedTypeAnnotationCode(name: catwalkMethodArgument),
          "(",
          createLyellTypeTree(argument.type.code, qualifiedTerminal, qualifiedTypeTreeN),
          ", ",
          argument.type.isNullable ? "true" : "false",
          ", \"${argument.identifier.name}\", ",
          await createMetaList(argument.metadata, retainedAnnotation, builder),
          ")"
        ]));
      }
      var resultType = (method.returnType as NamedTypeAnnotation).typeArguments.first;

      routes.add(RawCode.fromParts([
        NamedTypeAnnotationCode(name: catwalkRouteDefinition, typeArguments: [NamedTypeAnnotationCode(name: clazz.identifier)]),
        "(",
        await createMetaList(method.metadata, retainedAnnotation, builder),
        ", ",
        // Use the first type argument T since the response must always be a Future<T>
        createLyellTypeTree(resultType.code.asNonNullable, qualifiedTerminal, qualifiedTypeTreeN),
        ", ",
        resultType.isNullable ? "true" : "false",
        ", [",
        ...arguments.commaDelimited,
        "], (obj,x) => obj.",
        method.identifier.name,
        "(",
        ...List.generate(arguments.length, (index) => "x[$index]").commaDelimited,
        "), '",
        method.identifier.name,
        "')"
      ]));
    }

    var routesGetter = await builder.methodsOf(clazz).then((methods) =>
        methods.firstWhere((element) =>
        element.identifier.name == 'routes' && element.isGetter));

    var routesBuilder = await builder.buildMethod(routesGetter.identifier);
    routesBuilder.augment(FunctionBodyCode.fromParts([
      "=> [",
      ...routes.commaDelimited,
      "];"
    ]));
  }
}

// Library Urls
final _dartCore = Uri.parse('dart:core');
final _catwalk = Uri.parse('package:catwalk/src/catwalk_base.dart');
final _lyellQualifiedTree = Uri.parse('package:lyell/src/qualified_tree.dart');
final _lyellBase = Uri.parse('package:lyell/src/lyell_base.dart');