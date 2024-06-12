import 'package:macros/macros.dart';

extension BuilderExtension on TypePhaseIntrospector {
  Future<List<Identifier>> resolveMany(List<(Uri, String)> args) async {
    return await Future.wait(args.map((e) => resolveIdentifier(e.$1, e.$2)));
  }
}

extension MacroIterableExtension<T extends Object> on Iterable<T> {
  List<Object> get commaDelimited {
    if (isEmpty) return [];
    return expand((e) => [e, ","]).skipLast(1).toList();
  }

  List<T> skipLast(int n) {
    var list = toList();
    if (n == 0) return list;
    if (n >= list.length) return [];
    return list.sublist(0, list.length - n);
  }

  List<Object> get simplifyParts {
    return expand<Object>((e) {
      return switch (e) {
        Iterable<Object>() => e.simplifyParts,
        Code() => [e],
        String() => [e],
        Identifier() => [e],
        Object() => [e.toString()],
      };
    }).toList();
  }

  Future<T?> firstOfStaticType(TypeAnnotation Function(T) selector,
      DeclarationPhaseIntrospector builder, Identifier searched) async {
    var annotation = NamedTypeAnnotationCode(name: searched);
    var searchedType = await builder.resolve(annotation);
    for (var element in this) {
      var type = selector(element);
      if (type is! NamedTypeAnnotation) continue;
      var otherType = await builder.resolve(type.code);
      if (await otherType.isSubtypeOf(searchedType)) {
        return element;
      }
    }
    return null;
  }
}

/// Create the code for a lyell qualified type tree from a type annotation.
/// Requires the identifiers for terminal and narg type trees from the lyell
/// package.
Code createLyellTypeTree(
    TypeAnnotation annotation, Identifier qtId, Identifier ttnId) {
  if (annotation is! NamedTypeAnnotationCode) {
    throw ArgumentError.value(
        annotation, 'annotation', 'Must be a NamedTypeAnnotation');
  }
  var argCodes = annotation.typeArguments
      .map((e) => createLyellTypeTree(e, qtId, ttnId))
      .toList();

  if (argCodes.isEmpty) {
    return RawCode.fromParts([
      NamedTypeAnnotationCode(name: qtId, typeArguments: [
        NamedTypeAnnotationCode(name: annotation.name)
      ]),
      "()"
    ]);
  } else {
    return RawCode.fromParts([
      NamedTypeAnnotationCode(name: ttnId, typeArguments: [
        annotation.code,
        NamedTypeAnnotationCode(name: annotation.name)
      ]),
      "([",
      ...argCodes.commaDelimited,
      "])"
    ]);
  }
}

Code recreateAnnotation(MetadataAnnotation annotation) {
  if (annotation is ConstructorMetadataAnnotation) {
    var parts = <Object>[annotation.type.code, "("];
    for (var arg in annotation.positionalArguments) {
      parts.add(arg);
      parts.add(",");
    }
    for (var arg in annotation.namedArguments.entries) {
      parts.add(arg.key);
      parts.add(":");
      parts.add(arg.value);
      parts.add(",");
    }
    parts.add(")");
    return RawCode.fromParts(parts);
  } else if (annotation is IdentifierMetadataAnnotation) {
    return NamedTypeAnnotationCode(name: annotation.identifier);
  }

  throw ArgumentError.value(annotation, 'annotation', 'Unsupported annotation');
}

Future<Code> createMetaList(Iterable<MetadataAnnotation> metadata,
    Identifier retainedAnnotationType, DefinitionBuilder builder) async {
  var staticType = await builder
      .resolve(NamedTypeAnnotationCode(name: retainedAnnotationType));
  var parts = <Object>["["];
  for (var meta in metadata) {
    if (meta is ConstructorMetadataAnnotation) {
      var type = await builder.resolve(meta.type.code);
      if (await type.isSubtypeOf(staticType)) {
        parts.add(recreateAnnotation(meta));
        parts.add(",");
      }
    } else if (meta is IdentifierMetadataAnnotation) {
      var dec = await builder.declarationOf(meta.identifier);
      if (dec is FunctionDeclaration) {
        var type = await builder.resolve(dec.returnType.code);
        if (await type.isSubtypeOf(staticType)) {
          parts.add(recreateAnnotation(meta));
          parts.add(",");
        }
      }
    }
  }
  parts.add("]");
  return RawCode.fromParts(parts);
}

List<MethodDeclaration> filterCatwalkMethodCandidates(
    Iterable<MethodDeclaration> methods) {
  return methods
      .where((method) =>
          !method.isGetter &&
          !method.isSetter &&
          !method.isOperator &&
          !method.identifier.name.startsWith("_") &&
          !method.hasStatic
  ).toList();
}
