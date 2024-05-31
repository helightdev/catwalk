import 'dart:convert';

import 'package:catwalk/catwalk.dart';
import 'package:catwalk/src/client_runner.dart';
import 'package:catwalk/src/endpoint_macro.dart';
import 'package:catwalk/src/protocol.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;

class JsonRpcProtocol extends CatwalkProtocol {

  @override
  String get protocolName => "jsonrpc";

  JsonRpcClient? _client;

  set client(JsonRpcClient client) {
    _client = client;
  }

  @override
  ClientRunner createClientRunner(List<RouteDefinition> routes) {
    if (_client == null) {
      throw StateError("Client must be set before creating a runner");
    }
    return JsonRpcClientRunner(this, routes);
  }
}

class JsonRpcClient {

  final JsonRpcClientConfig config;
  final http.Client _httpClient = http.Client();
  JsonRpcClient._(this.config);

  factory JsonRpcClient(JsonRpcClientConfig config) {
    return JsonRpcClient._(config);
  }

  int incrementalId = 0;


  int get nextId {
    var max = double.maxFinite.toInt();
    if (incrementalId >= max) {
      incrementalId = 0;
      return incrementalId;
    } else {
      return incrementalId++;
    }
  }

  Future<Object?> makeRpcCall(String method, Map<String,Object?> structuredData) async {
    var url = Uri.parse(config.baseUrl).resolve("/rpc");
    var originalId = nextId;
    var body = <String,Object?>{
      "jsonrpc": "2.0",
      "id": originalId,
      "method": method,
      "params": structuredData,
    };
    var jsonBody = jsonEncode(body);
    var result = await _httpClient.post(url, body: jsonBody);
    var responseBody = jsonDecode(result.body);
    if (responseBody["jsonrpc"] != "2.0") throw StateError("Response is not a valid jsonrpc response");
    if (responseBody["id"] != originalId) throw StateError("Response id does not match request id");
    if (responseBody["result"] != null) {
      return responseBody["result"];
    } else {
      throw JsonRpcError.fromMap(responseBody["error"]);
    }
  }
}

class JsonRpcError {
  final int code;
  final String message;
  final Object? data;

  const JsonRpcError({
    required this.code,
    required this.message,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'message': message,
      'data': data,
    };
  }

  factory JsonRpcError.fromMap(Map<String, dynamic> map) {
    return JsonRpcError(
      code: map['code'] as int,
      message: map['message'] as String,
      data: map['data'] as Object,
    );
  }
}

class JsonRpcClientConfig {
  final String baseUrl;

  const JsonRpcClientConfig({
    this.baseUrl = "http://localhost:8080",
  });
}

typedef ArgumentAssembler = MapEntry<String, Object?> Function(dynamic argument);
typedef ResultAssembler = dynamic Function(Object? response);
typedef AssemblerEntry = ({List<ArgumentAssembler> arguments, String method, ResultAssembler result});

class JsonRpcClientRunner extends ClientRunner {
  final JsonRpcProtocol protocol;
  final List<RouteDefinition> routes;

  JsonRpcClientRunner(this.protocol, this.routes);

  late final List<AssemblerEntry?> assemblers = List.filled(routes.length, null);

  AssemblerEntry getOrCreate(int index) {
    var currentValue = assemblers[index];
    if (currentValue == null) {
      var route = routes[index];
      var argumentAssemblers = route.arguments.mapIndexed((i, e) {
        var serializer = protocol.resolveSerializer(e.type);
        if (serializer == null) {
          throw StateError("No serializer found for ${e.type}");
        }
        return (obj) => MapEntry(e.name, serializer.serializeStructured(obj));
      }).toList();
      var resultSerializer = protocol.resolveSerializer(route.response);
      if (resultSerializer == null) {
        throw StateError("No serializer found for ${route.response}");
      }
      result(obj) => resultSerializer.deserializeStructured(obj);
      currentValue = (arguments: argumentAssemblers, method: route.name, result: result);
      assemblers[index] = currentValue;
    }

    return currentValue;
  }

  @override
  Future run(int index, List args) async {
    var entry = getOrCreate(index);
    var structuredData = Map.fromEntries(args.mapIndexed((i,e) => entry.arguments[i](e)));
    var response = await protocol._client!.makeRpcCall(entry.method, structuredData);
    var result = entry.result(response);
    return result;
  }

}