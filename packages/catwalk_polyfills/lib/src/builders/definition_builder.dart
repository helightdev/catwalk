import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:lyell/lyell.dart';
import 'package:lyell_gen/lyell_gen.dart';
import 'package:source_gen/source_gen.dart';
import 'package:uuid/uuid.dart';
import 'package:catwalk/catwalk.dart';

import '../catwalk_generator_base.dart';

class DefinitionBuilder extends SimpleAdapter<EndpointPolyfill> {
  DefinitionBuilder() : super(archetype: "endpoint");

  @override
  FutureOr<SubjectDescriptor> generateDescriptor(
      SubjectGenContext<Element> context) {
    var descriptor = context.defaultDescriptor();
    descriptor.meta["names"] = context.matches.map((e) => e.name).toList();
    return descriptor;
  }

  @override
  FutureOr<void> generateSubject(SubjectGenContext<Element> genContext,
      SubjectCodeContext codeContext) async {
    if (genContext.matches.isEmpty) {
      print("No matches");
      codeContext.noGenerate = true;
      return;
    }
    await tryInitialize(genContext.step);

    codeContext.additionalImports.add(AliasImport("dart:async", null));
    codeContext.additionalImports
        .add(AliasImport.gen("package:lyell/lyell.dart"));
    codeContext.additionalImports
        .add(AliasImport.gen("package:catwalk/catwalk.dart"));

    for (var classElement in genContext.matches) {
      if (classElement is! ClassElement) {
        print("Not class element $classElement");
        continue;
      }
      var retainedAnnotationChecker = TypeChecker.fromRuntime(RetainedAnnotation);

      List<String> routes = [];
      for (var element in classElement.methods) {
        var parameters = element.parameters
            .map((e) =>
        "gen.MethodArgument(${getTypeTree(e.type).code(codeContext.cachedCounter)}, ${e.type.nullabilitySuffix != NullabilitySuffix.none},'${sqsLiteralEscape(e.name)}', [${e.metadata.whereTypeChecker(retainedAnnotationChecker).map((e) => codeContext.annotationSource(e)).join(",")}])")
            .toList();

        var futureTypeChecker = TypeChecker.fromRuntime(Future);
        var futureOrTypeChecker = TypeChecker.fromUrl("dart:async#FutureOr");
        if (!futureTypeChecker.isAssignableFromType(element.returnType) && !futureOrTypeChecker.isAssignableFromType(element.returnType)) {
          throw "Return type must be a Future";
        }

        var returnType = (element.returnType as InterfaceType).typeArguments[0];

        var body = "gen.RouteDefinition<${codeContext.className(classElement)}>("
            "[${element.metadata.whereTypeChecker(retainedAnnotationChecker).map((e) => codeContext.annotationSource(e)).join(",")}],"
            "${getTypeTree(returnType).code(codeContext.cachedCounter)},"
            "${returnType.nullabilitySuffix == NullabilitySuffix.question},"
            "[${parameters.join(",")}],"
            "(obj,args) => obj.${element.name}(${List.generate(parameters.length, (index) => "args[$index]").join(",")}),"
            "'${sqsLiteralEscape(element.name)}',"
            ")";

        routes.add(body);
      }
      codeContext.codeBuffer.writeln("final List<gen.RouteDefinition<${codeContext.className(classElement)}>> ${classElement.name}_routes = [${routes.join(",")}];");
    }
  }
}
