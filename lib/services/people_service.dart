import 'package:dio/dio.dart';
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
        if (data is String) {
          print(
            "Warning: Response data is String. Attempting to decode if needed.",
          );
          // Usually Dio handles this if responseType is json.
        }

        if (data is List) {
          return data.map((json) => Person.fromJson(json)).toList();
        } else {
          print("Unexpected response format: ${data.runtimeType} - $data");
          throw Exception("Unexpected response format: ${data.runtimeType}");
        }
      } else {
        print("Server Error: ${response.statusCode} ${response.statusMessage}");
        print("Response Body: ${response.data}");
        throw Exception(
          "Failed to fetch people details: ${response.statusCode}",
        );
      }
    } catch (e) {
      if (e is DioException) {
        print("DioError fetching people: ${e.message}");
        if (e.response != null) {
          print("Response Status: ${e.response?.statusCode}");
          print("Response Data: ${e.response?.data}");
        }
      }
      print("Error fetching people details: $e");
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
        print("Batch damage API error: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      if (e is DioException) {
        print("DioError fetching batch damage: ${e.message}");
        if (e.response != null) {
          print("Response data: ${e.response?.data}");
          print("Response headers: ${e.response?.headers}");
        }
      }
      print("Error fetching batch damage: $e");
      return {};
    }
  }
}
