import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/services/log_service.dart';

class McpDiagnosticsService {
  final Dio _dio = Dio();
  final LogService _log = LogService();

  Future<DiagnosticResult> diagnoseServer(String endpoint) async {
    final result = DiagnosticResult(endpoint: endpoint);
    result.networkConnectivity = await _checkNetworkConnectivity(endpoint);
    result.dnsResolution = await _checkDnsResolution(endpoint);
    result.httpConnection = await _checkHttpConnection(endpoint);
    result.availableEndpoints = await _scanEndpoints(endpoint);
    result.recommendations = _generateRecommendations(result);
    return result;
  }

  Future<bool> _checkNetworkConnectivity(String endpoint) async {
    try {
      final uri = Uri.parse(endpoint);
      final socket = await Socket.connect(uri.host, uri.port ?? 80, timeout: const Duration(seconds: 5));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkDnsResolution(String endpoint) async {
    try {
      final uri = Uri.parse(endpoint);
      final addresses = await InternetAddress.lookup(uri.host);
      return addresses.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _checkHttpConnection(String endpoint) async {
    try {
      final response = await _dio.get(endpoint, 
        options: Options(receiveTimeout: const Duration(seconds: 5))
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<EndpointStatus>> _scanEndpoints(String endpoint) async {
    final uri = Uri.parse(endpoint);
    final baseUrl = uri.scheme + '://' + uri.host + ':' + uri.port.toString();
    final endpoints = ['/health', '/api/health', '/ping', '/api/kubernetes/sse', '/sse', '/tools'];
    final results = <EndpointStatus>[];
    
    for (final path in endpoints) {
      try {
        final response = await _dio.get(baseUrl + path,
          options: Options(
            receiveTimeout: const Duration(seconds: 3),
            validateStatus: (status) => status != null && status < 500,
          )
        ).timeout(const Duration(seconds: 3));
        results.add(EndpointStatus(path: path, statusCode: response.statusCode, available: response.statusCode! < 400));
      } catch (e) {
        results.add(EndpointStatus(path: path, available: false));
      }
    }
    return results;
  }

  List<String> _generateRecommendations(DiagnosticResult result) {
    final recs = <String>[];
    if (!result.networkConnectivity) recs.add('Network connection failed');
    if (!result.dnsResolution) recs.add('DNS resolution failed');
    if (!result.httpConnection) recs.add('HTTP connection failed');
    if (result.availableEndpoints.isEmpty) recs.add('No valid endpoints');
    return recs;
  }
}

class DiagnosticResult {
  final String endpoint;
  final DateTime timestamp = DateTime.now();
  late bool networkConnectivity;
  late bool dnsResolution;
  late bool httpConnection;
  late List<EndpointStatus> availableEndpoints;
  late List<String> recommendations;

  DiagnosticResult({required this.endpoint});

  List<String> get issues {
    final issues = <String>[];
    if (!networkConnectivity) issues.add('Network failed');
    if (!dnsResolution) issues.add('DNS failed');
    if (!httpConnection) issues.add('HTTP failed');
    if (availableEndpoints.isEmpty) issues.add('No endpoints');
    return issues;
  }
}

class EndpointStatus {
  final String path;
  final int? statusCode;
  final bool available;
  EndpointStatus({required this.path, this.statusCode, required this.available});
}
