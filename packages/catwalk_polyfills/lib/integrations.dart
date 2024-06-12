import 'package:build/build.dart';

import 'src/builders/definition_builder.dart';
import 'src/builders/reactor_builder.dart';

Builder definitionsSubject(BuilderOptions options) =>
    DefinitionBuilder().subjectBuilder;
Builder definitionsDescriptor(BuilderOptions options) =>
    DefinitionBuilder().descriptorBuilder;
Builder reactorBuilder(BuilderOptions options) => CatwalkReactorBuilder();