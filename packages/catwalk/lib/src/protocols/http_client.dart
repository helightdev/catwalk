import 'package:http/http.dart' as http;

class HttpClientConfig {

  String baseUrl;

  HttpClientConfig._(this.baseUrl);

  factory HttpClientConfig({String? baseUrl}) {
    return HttpClientConfig._(baseUrl ?? "http://localhost:8080");
  }
}