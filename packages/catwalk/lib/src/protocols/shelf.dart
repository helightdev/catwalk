import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:catwalk/src/protocols/http_client.dart';
import 'package:http/http.dart' as http;

import 'shelf/rest_assembler.dart';

export 'shelf/annotations.dart';
export 'shelf/resolution.dart';
export 'shelf/openapi.dart';

class ShelfRestProtocol extends CatwalkProtocol {

  @override
  String get protocolName => "shelf:rest";

  ShelfRestClient? _client;

  set client(ShelfRestClient client) {
    _client = client;
  }

  @override
  ClientRunner createClientRunner(List<RouteDefinition> routes) {
    if (_client == null) {
      throw StateError("Client must be set before creating a runner");
    }
    return ShelfRestClientRunner(_client!, this, routes);
  }
}

class ShelfRestClient {

  final HttpClientConfig config;
  ShelfRestClient._(this.config);

  final http.Client _httpClient = http.Client();

  factory ShelfRestClient(HttpClientConfig config) {
    return ShelfRestClient._(config);
  }

}

class ShelfRestClientRunner extends ClientRunner {

  final ShelfRestClient client;
  final ShelfRestProtocol protocol;
  final List<RouteDefinition> routes;

  ShelfRestClientRunner(this.client, this.protocol, this.routes);

  late final List<RestClientEncoder> encoders = routes.map((e) => RestClientEncoder(protocol, e)).toList();
  Future<dynamic> run(int index, List args) async {
    final encoder = encoders[index];
    final request = encoder.build(client.config.baseUrl, args);
    final response = await client._httpClient.send(request);
    if (response.statusCode != 200) {
      throw StateError("Request failed with status code ${response.statusCode}");
    }
    final body = await response.stream.bytesToString();
    final jsonBody = jsonDecode(body);
    final result = encoder.responseSerializer.deserializeStructured(jsonBody);
    return result;
  }
}