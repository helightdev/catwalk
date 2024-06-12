import 'package:catwalk/catwalk.dart';
import 'package:lyell/lyell.dart';

class RequestMapping implements RetainedAnnotation {
  final String method;
  final String path;
  const RequestMapping(this.path, {this.method = "POST"});

  static RequestMapping from(RouteDefinition route) {
    var method = "POST";
    var name = "/${route.name}";
    for (var annotation in route.annotations.whereType<RequestMapping>()) {
      method = annotation.method;
      name = annotation.path;
    }
    return RequestMapping(name, method: method);
  }
}

class GET extends RequestMapping {
  const GET(super.path) : super(method: "GET");
}

class POST extends RequestMapping {
  const POST(super.path) : super(method: "POST");
}

class PUT extends RequestMapping {
  const PUT(super.path) : super(method: "PUT");
}

class DELETE extends RequestMapping {
  const DELETE(super.path) : super(method: "DELETE");
}

class PATCH extends RequestMapping {
  const PATCH(super.path) : super(method: "PATCH");
}

class OPTIONS extends RequestMapping {
  const OPTIONS(super.path) : super(method: "OPTIONS");
}

class TRACE extends RequestMapping {
  const TRACE(super.path) : super(method: "TRACE");
}

class CONNECT extends RequestMapping {
  const CONNECT(super.path) : super(method: "CONNECT");
}

class ALL extends RequestMapping {
  const ALL(super.path) : super(method: "ALL");
}

class CATCHALL extends RequestMapping {
  const CATCHALL(super.path) : super(method: "CATCHALL");
}


const body = Body();
const path = Path();
const query = Query();
const header = Header();

class Body extends RetainedAnnotation {
  const Body();
}

class Path extends RetainedAnnotation {
  final String? name;
  const Path([this.name]);

  static Map<MethodArgument, Path> getPaths(RouteDefinition route) {
    var pathVariables = SegmentUtils.getVariableSegments(RequestMapping.from(route).path);
    var remainingArguments = route.arguments.toList();
    var pathArguments = <MethodArgument, Path>{};

    for (var arg in remainingArguments.where((e) => pathVariables.contains(e.name)).toList()) {
      remainingArguments.remove(arg);
      pathArguments[arg] = Path(arg.name);
    }

    for (var arg in remainingArguments) {
      var path = arg.annotations.whereType<Path>().firstOrNull;
      if (path == null) continue;
      if (path.name == null) path = Path(arg.name); // Should never ne reached
      pathArguments[arg] = path;
    }

    return pathArguments;
  }
}

class Query extends RetainedAnnotation {
  final String? name;
  const Query([this.name]);

  static Query? of(MethodArgument argument) {
    var query = argument.annotations.whereType<Query>().firstOrNull;
    if (query == null) return null;
    if (query.name == null) query = Query(argument.name);
    return query;
  }
}

class Header extends RetainedAnnotation {
  final String? name;
  const Header([this.name]);

  static Header? of(MethodArgument argument) {
    var header = argument.annotations.whereType<Header>().firstOrNull;
    if (header == null) return null;
    if (header.name == null) header = Header(argument.name);
    return header;
  }
}