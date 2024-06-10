import 'package:catwalk/catwalk.dart';
import 'package:catwalk/src/protocols/shelf.dart';
import 'package:test/test.dart';


@EndpointMacro()
abstract interface class ShelfAnnotationEndpoint implements Endpoint {

  @GET("/hello/:name")
  Future<String> helloName(
      String name, @body String body);

}

void main() {
  test("Path Recognized", () {
    var route = ShelfAnnotationEndpoint.routes
        .firstWhere((e) => e.name == "helloName");
    print(route);
    var annotations = ResolvedAnnotations.resolve(route);
    print(annotations);
    expect(annotations.bodyArgument, isNotNull);
    expect(annotations.bodyArgument!.name, "body");
  });
}