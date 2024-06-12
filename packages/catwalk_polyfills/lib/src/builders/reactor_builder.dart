import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:lyell_gen/lyell_gen.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class CatwalkReactorBuilder extends SubjectReactorBuilder {
  CatwalkReactorBuilder() : super("catwalk", "catwalk.g.dart");

  late BuildStep _buildStep;

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    _buildStep = buildStep;
    await super.build(buildStep);
  }

  @override
  FutureOr<void> buildReactor(
      List<SubjectDescriptor> descriptors, SubjectCodeContext code) async {
    code.additionalImports.add(AliasImport("dart:async", null));
    code.additionalImports.add(AliasImport.gen("package:lyell/lyell.dart"));

    descriptors.forEach((descriptor) {
      code.codeBuffer.writeln("export '${descriptor.uri}';");
    });
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        r"$lib$": [reactorFileName]
      };
}
