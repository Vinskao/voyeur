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
    const String endpoint = "/people/names";
    final String url = "${AppConfig.apiBaseURL}$endpoint";

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> names = response.data;
        return names.map((name) => Person(name: name.toString())).toList();
      } else {
        throw Exception("Failed to fetch people names: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching people: $e");
      rethrow;
    }
  }
}
