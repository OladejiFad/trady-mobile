import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_model.dart';
import '../config.dart';
import '../global/admin_auth_data.dart';

class JobService {
  Future<void> createAdminJob({
    required String title,
    required String description,
    required String location,
    required String jobType,
    required DateTime deadline,
    required String email, // ✅ added email
  }) async {
    final uri = Uri.parse('$baseUrl/api/jobs/trady');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AdminAuthData.token}',
      },
      body: jsonEncode({
        'title': title,
        'description': description,
        'location': location,
        'jobType': jobType,
        'deadline': deadline.toIso8601String(),
        'email': email, // ✅ send email
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create job: ${response.body}');
    }
  }

  Future<List<Job>> fetchPublicJobs() async {
    final uri = Uri.parse('$baseUrl/api/jobs/trady');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load jobs: ${response.body}');
    }

    final List data = jsonDecode(response.body);
    return data.map((json) => Job.fromJson(json)).toList();
  }
}
