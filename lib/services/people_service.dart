import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/person.dart';
import 'app_config.dart';

class PeopleService {
  static final PeopleService shared = PeopleService._();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );
  final Logger _logger = Logger();

  PeopleService._();

  Future<List<Person>> fetchPeople() async {
    const String endpoint = "/people/get-all";
    final String url = "${AppConfig.apiBaseURL}$endpoint";

    try {
      // Use POST as requested for /get-all
      // Send empty JSON to ensure Content-Type is application/json and body is valid JSON
      final response = await _dio.post(
        url,
        data: {},
        options: Options(contentType: Headers.jsonContentType),
      );

      if (response.statusCode == 200) {
        dynamic data = response.data;

        // Handle case where response is a String (e.g. valid JSON string but Dio didn't parse it)
          _logger.w(
            "Response data is String. Attempting to decode if needed.",
          );

        if (data is List) {
          return data.map((json) => Person.fromJson(json)).toList();
        } else {
          _logger.e("Unexpected response format: ${data.runtimeType} - $data");
          throw Exception("Unexpected response format: ${data.runtimeType}");
        }
      } else {
        _logger.e("Server Error: ${response.statusCode} ${response.statusMessage}");
        _logger.e("Response Body: ${response.data}");
        throw Exception(
          "Failed to fetch people details: ${response.statusCode}",
        );
      }
    } catch (e) {
      if (e is DioException) {
        _logger.e("DioError fetching people: ${e.message}");
        if (e.response != null) {
          _logger.e("Response Status: ${e.response?.statusCode}");
          _logger.e("Response Data: ${e.response?.data}");
        }
      }
      _logger.e("Error fetching people details: $e");
      rethrow;
    }
  }

  Future<Map<String, int>> fetchBatchDamage(List<String> names) async {
    const String endpoint = "/people/batchDamageWithWeapon";
    final String url = "${AppConfig.apiBaseURL}$endpoint";

    try {
      final response = await _dio.post(url, data: {"names": names});
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data['damageResults'] ?? {};
        return data.map((key, value) => MapEntry(key, value as int));
      } else {
        _logger.e("Batch damage API error: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      if (e is DioException) {
        _logger.e("DioError fetching batch damage: ${e.message}");
        if (e.response != null) {
          _logger.e("Response data: ${e.response?.data}");
          _logger.e("Response headers: ${e.response?.headers}");
        }
      }
      _logger.e("Error fetching batch damage: $e");
      return {};
    }
  }
}
