import 'package:catwalk/catwalk.dart';
class ResolvedAnnotations {

  final Map<MethodArgument, Path> pathArguments;
  final Map<MethodArgument, Query> queryArguments;
  final Map<MethodArgument, Header> headerArguments;
  final MethodArgument? bodyArgument;
  final RequestMapping requestMapping;
  final List<MethodArgument> unresolvedArguments;

  const ResolvedAnnotations._({
    required this.pathArguments,
    required this.queryArguments,
    required this.headerArguments,
    this.bodyArgument,
    required this.requestMapping,
    required this.unresolvedArguments,
  });

  factory ResolvedAnnotations.resolve(RouteDefinition definition) {
    var arguments = definition.arguments.toList();
    Map<MethodArgument, Query> queryArguments = {};
    Map<MethodArgument, Header> headerArguments = {};
    MethodArgument? bodyArgument;

    var paths = Path.getPaths(definition);
    arguments.removeWhere((e) => paths.containsKey(e));

    for (var argument in arguments) {
      var query = Query.of(argument);
      if (query != null) {
        queryArguments[argument] = query;
        continue;
      }

      var header = Header.of(argument);
      if (header != null) {
        headerArguments[argument] = header;
        continue;
      }

      var body = argument.annotations.whereType<Body>().firstOrNull;
      if (body != null) {
        bodyArgument = argument;
        continue;
      }
    }

    arguments.removeWhere((e) => queryArguments.containsKey(e));
    arguments.removeWhere((e) => headerArguments.containsKey(e));
    arguments.removeWhere((e) => e == bodyArgument);

    if (bodyArgument == null && arguments.isNotEmpty) {
      bodyArgument = arguments.removeAt(0);
    }

    final requestMapping = RequestMapping.from(definition);

    return ResolvedAnnotations._(
      requestMapping: requestMapping,
      pathArguments: paths,
      queryArguments: queryArguments,
      headerArguments: headerArguments,
      bodyArgument: bodyArgument,
      unresolvedArguments: arguments,
    );
  }

  @override
  String toString() {
    return 'ResolvedArguments{\n'
        'pathArguments: $pathArguments,\n '
        'queryArguments: $queryArguments, \n'
        'headerArguments: $headerArguments, \n'
        'bodyArgument: $bodyArgument, \n'
        'unresolvedArguments: $unresolvedArguments\n'
        '}';
  }
}