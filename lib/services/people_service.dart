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
      final response = await _dio.post(url);
      if (response.statusCode == 200) {
        dynamic data = response.data;
        // Handle case where Dio returns String instead of List (e.g. content-type issues)
        if (data is String) {
          // If response is raw string, try to parse it manually, though Dio usually handles this.
          // However, based on the error "Unexpected character", it might be an issue with
          // invisible characters or BOM if it's being treated as JSON when it's not clean.
          // But standard Dio flow with application/json should return List<dynamic>.
          // For now, let's assume if it is a String, we might need to decode it or it is an error.
          // But given the curl output was clean JSON, let's trust Dio's auto-parsing
          // for List<dynamic>. The "Unexpected character" usually comes from `jsonDecode`
          // running on something that isn't a valid JSON string (maybe empty or HTML error).
        }

        if (data is List) {
          return data.map((json) => Person.fromJson(json)).toList();
        } else {
          print("Unexpected response format: ${data.runtimeType} - $data");
          throw Exception("Unexpected response format: ${data.runtimeType}");
        }
      } else {
        throw Exception(
          "Failed to fetch people details: ${response.statusCode}",
        );
      }
    } catch (e) {
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
      print("Error fetching batch damage: $e");
      return {};
    }
  }
}
