# Example

## Shared Library Content
```dart
// Create a protocol instance that should be used by this endpoint.
// This contains serializers and the transport format that should be used.
final protocol = JsonRpcProtocol();

// Create an endpoint interface that will be implemented by both the client and server.
@EndpointMacro()
abstract interface class TestEndpoint implements Endpoint {
  Future<String> getName(String userId);

  Future<String?> nullableString();
}
```

## Server
```dart
// Create a simple rpc server that uses the TestController to handle requests.
void main(List<String> arguments) async {
  var server = JsonRpcServer(protocol, TestController(), TestEndpoint.routes);
  await server.serve();
}

// The server sided implementation of the TestEndpoint.
class TestController implements TestEndpoint {

  @override
  Future<String> getName(String userId) {
    return Future.value("Answer: $userId");
  }

  @override
  Future<String?> nullableString() {
    return Future.value(null);
  }
}
```

## Client
```dart
// Access the server using the TestEndpointClient.
void main(List<String> arguments) async {
  protocol.client = JsonRpcClient(JsonRpcClientConfig(baseUrl: "http://localhost:8080"));
  var client = TestEndpointClient(protocol);
  print(await client.getName("Moin!"));
}

@ClientMacro()
class TestEndpointClient implements TestEndpoint {}
```