import 'dart:async';

import 'package:catwalk/src/endpoint_macro.dart';
import 'package:catwalk/src/client_runner.dart';
import 'package:catwalk/src/protocol.dart';
import 'package:catwalk/src/macro_utils.dart';
import 'package:macros/macros.dart';

macro class ClientMacro implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const ClientMacro();

  @override
  FutureOr<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    var [
      dartList,
      catwalkEndpoint,
      catwalkRouteDefinition,
      overrideAnnotation,
      clientRunner,
      protocol,
    ] = await builder.resolveMany([(_dartCore, 'List'), (_catwalk, 'Endpoint'), (_catwalk, 'RouteDefinition'), (_dartCore, 'override'), (_clientRunner, 'ClientRunner'), (_protocol, 'CatwalkProtocol')]);
    var endpoint = await clazz.interfaces
        .firstOfStaticType((x) => x, builder, catwalkEndpoint);

    if (endpoint == null) {
      throw 'Class must implement an Endpoint';
    }

    builder.declareInType(DeclarationCode.fromParts([
      "final ",
      NamedTypeAnnotationCode(name: protocol),
      " protocol;"
    ]));

    // Define constructor
    builder.declareInType(DeclarationCode.fromParts([
      "${clazz.identifier.name}(this.protocol);"
    ]));

    builder.declareInType(DeclarationCode.fromParts([
      "final ",
      NamedTypeAnnotationCode(name: dartList, typeArguments: [NamedTypeAnnotationCode(name: catwalkRouteDefinition, typeArguments: [NamedTypeAnnotationCode(name: endpoint.identifier)])]),
      " routes = ",
      NamedTypeAnnotationCode(name: endpoint.identifier),
      ".routes;"
    ]));

    builder.declareInType(DeclarationCode.fromParts([
      "late final ",
      NamedTypeAnnotationCode(name: clientRunner),
      " runner = ",
      "protocol.createClientRunner(",
      NamedTypeAnnotationCode(name: endpoint.identifier),
      ".routes",
      ");"
    ]));

    var type = await builder.typeDeclarationOf(endpoint.identifier);
    for (var method in filterCatwalkMethodCandidates(await builder.methodsOf(type))) {
      builder.declareInType(DeclarationCode.fromParts([
        "@",
        NamedTypeAnnotationCode(name: overrideAnnotation),
        " external ",
        method.returnType.code,
        " ",
        method.identifier.name,
        "(",
        ...method.positionalParameters.map((e) => RawCode.fromParts([
          e.type.code,
          " ",
          e.identifier.name
        ])).commaDelimited,
        ")",
        ";"
      ]));
    }
  }

  @override
  FutureOr<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    var [
    dartList,
    catwalkEndpoint,
    catwalkRouteDefinition,
    overrideAnnotation,
    clientRunner
    ] = await builder.resolveMany([
      (_dartCore, 'List'), (_catwalk, 'Endpoint'), (_catwalk, 'RouteDefinition'),
      (_dartCore, 'override'), (_clientRunner, 'ClientRunner')
    ]);
    var endpoint = await clazz.interfaces
        .firstOfStaticType((x) => x, builder, catwalkEndpoint);

    if (endpoint == null) {
      throw 'Class must implement an Endpoint';
    }
    var type = await builder.typeDeclarationOf(endpoint.identifier);
    var declaredMethods = await builder.methodsOf(clazz);


    var indexCounter = 0;
    for (var method in filterCatwalkMethodCandidates(await builder.methodsOf(type))) {
      var declaredMethod = declaredMethods.firstWhere((x) => x.identifier.name == method.identifier.name);
      var methodBuilder = await builder.buildMethod(declaredMethod.identifier);
      methodBuilder.augment(FunctionBodyCode.fromParts([
        "async { return await runner.run(",
        indexCounter.toString(),
        ", [",
        ...method.positionalParameters.map((e) => e.identifier.name).commaDelimited,
        "]); }",
      ]));
      indexCounter++;
    }
  }
}

// Library Urls
final _dartCore = Uri.parse('dart:core');
final _catwalk = Uri.parse('package:catwalk/src/catwalk_base.dart');
final _clientRunner = Uri.parse('package:catwalk/src/client_runner.dart');
final _protocol = Uri.parse('package:catwalk/src/protocol.dart');
final _lyellQualifiedTree = Uri.parse('package:lyell/src/qualified_tree.dart');
final _lyellBase = Uri.parse('package:lyell/src/lyell_base.dart');
