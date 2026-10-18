import "dart:convert";
import "package:http/http.dart" as http;
import "models.dart";

class StokkuApi {
  StokkuApi({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ??
            const String.fromEnvironment(
              "STOKKU_API_URL",
              defaultValue: "http://localhost:8080/api",
            ),
        _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<List<Product>> getProducts() async {
    try {
      final response = await _client.get(Uri.parse("$baseUrl/products")).timeout(const Duration(seconds: 3));
      _ensureSuccess(response);
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createInvoice(InvoiceInput input) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/invoices"),
        headers: const {
          "content-type": "application/json",
          "x-stokku-role": "admin",
        },
        body: jsonEncode(input.toJson()),
      ).timeout(const Duration(seconds: 4));
      _ensureSuccess(response);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<InvoiceComment>> getInvoiceComments(int invoiceId, {required String role}) async {
    try {
      final response = await _client.get(
        Uri.parse("$baseUrl/invoices/$invoiceId/comments"),
        headers: {"x-stokku-role": role},
      ).timeout(const Duration(seconds: 3));
      _ensureSuccess(response);
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) => InvoiceComment.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> addInvoiceComment(int invoiceId, String message, {String actor = "Budi Santoso"}) async {
    try {
      final response = await _client.post(
        Uri.parse("$baseUrl/invoices/$invoiceId/comments"),
        headers: const {
          "content-type": "application/json",
          "x-stokku-role": "manager",
        },
        body: jsonEncode({"actor": actor, "message": message}),
      ).timeout(const Duration(seconds: 4));
      _ensureSuccess(response);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProfitStatistics({
    required String period,
  }) async {
    try {
      final selectedPeriod = period == "month" ? "month" : "week";
      final response = await _client.get(
        Uri.parse("$baseUrl/statistics/profit?period=$selectedPeriod"),
        headers: const {"x-stokku-role": "manager"},
      ).timeout(const Duration(seconds: 4));
      _ensureSuccess(response);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse("$baseUrl/products/$id"),
        headers: const {"x-stokku-role": "admin"},
      ).timeout(const Duration(seconds: 4));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteInvoice(int id) async {
    try {
      final response = await _client.delete(
        Uri.parse("$baseUrl/invoices/$id"),
        headers: const {"x-stokku-role": "admin"},
      ).timeout(const Duration(seconds: 4));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void close() => _client.close();

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StokkuApiException(response.statusCode, response.body);
    }
  }
}

class StokkuApiException implements Exception {
  const StokkuApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => "StokkuApiException($statusCode): $message";
}
