import 'dart:async';

import 'package:http/http.dart' as http;

class HttpClientConfig {

  String baseUrl;
  Map<String,String> headers;
  List<ClientRequestInterceptor> interceptors;

  HttpClientConfig._(this.baseUrl, this.headers, this.interceptors);

  factory HttpClientConfig({String? baseUrl, Map<String,String>? headers, List<ClientRequestInterceptor>? interceptors}) {
    return HttpClientConfig._(baseUrl ?? "http://localhost:8080", headers ?? {}, interceptors ?? []);
  }

  Future<http.Request> prepare(http.Request request) async {
    request.headers.addAll(headers);
    for (var interceptor in interceptors) {
      request = await interceptor.interceptRequest(request);
    }
    return request;
  }
}

abstract class ClientRequestInterceptor {
  FutureOr<http.Request> interceptRequest(http.Request request);
}