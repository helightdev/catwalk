import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:catwalk/src/protocols/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

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
    var runner = ShelfRestClientRunner(_client!, this, routes);
    try {
      runner.createEncoders();
    } catch (e) {
      print("Error creating encoders: $e");
      rethrow;
    }
    return runner;
  }

  ShelfRestProtocol clone() {
    var clone = ShelfRestProtocol();
    for (var module in serializerModules) {
      clone.serializerModules.add(module);
    }
    if (_client != null) clone.client = _client!;
    return clone;
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

  late final List<RestClientEncoder> encoders;

  void createEncoders() {
    encoders = routes.map((e) => RestClientEncoder(protocol, e)).toList();
  }

  @override
  Future<dynamic> run(int index, List args) async {
    final encoder = encoders[index];
    var request = encoder.build(client.config.baseUrl, args);
    request = await client.config.prepare(request);

    final response = await client._httpClient.send(request);
    if (response.statusCode >= 300) {
      throw StateError("Request failed with status code ${response.statusCode}");
    }

    final res = await Response.fromStream(response);
    return encoder.decode(res);
  }
}