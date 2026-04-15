import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/app_session.dart';
import '../models/app_models.dart';

class ApiClient {
  ApiClient({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000',
            );

  final String baseUrl;
  String? accessToken;

  Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null && accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(response);
    return AuthPayload(
      token: data['tokens']['access'].toString(),
      profile: UserProfile.fromJson(data['profile'] as Map<String, dynamic>),
    );
  }

  Future<AuthPayload> register({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    final data = _decode(response);
    return AuthPayload(
      token: data['tokens']['access'].toString(),
      profile: UserProfile.fromJson(data['profile'] as Map<String, dynamic>),
    );
  }

  Future<UserProfile> fetchProfile() async {
    final response = await http.get(Uri.parse('$baseUrl/api/profile/me'), headers: _headers);
    return UserProfile.fromJson(_decode(response));
  }

  Future<UserProfile> updateProfile({
    required String fullName,
    required String email,
    required String university,
    required String bio,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/profile/me'),
      headers: _headers,
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'university': university,
        'bio': bio,
      }),
    );
    return UserProfile.fromJson(_decode(response));
  }

  Future<List<LessonSummary>> fetchLessons() async {
    final response = await http.get(Uri.parse('$baseUrl/api/lessons'), headers: _headers);
    final data = _decode(response) as List<dynamic>;
    return data.map((lesson) => LessonSummary.fromJson(lesson as Map<String, dynamic>)).toList();
  }

  Future<LessonDetail> fetchLessonDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/lessons/$id'), headers: _headers);
    return LessonDetail.fromJson(_decode(response));
  }

  Future<LessonDetail> submitLessonCompletion({
    required int lessonId,
    required int scorePercent,
    required int rating,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/lessons/$lessonId/complete'),
      headers: _headers,
      body: jsonEncode({
        'score_percent': scorePercent,
        'rating': rating,
      }),
    );
    final data = _decode(response) as Map<String, dynamic>;
    return LessonDetail.fromJson(data['lesson'] as Map<String, dynamic>);
  }

  Future<List<LessonSummary>> fetchBookmarks() async {
    final response = await http.get(Uri.parse('$baseUrl/api/bookmarks'), headers: _headers);
    final data = _decode(response) as List<dynamic>;
    return data
        .map((item) => LessonSummary.fromJson((item as Map<String, dynamic>)['lesson'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleBookmark(int lessonId, {required bool bookmarked}) async {
    final uri = Uri.parse('$baseUrl/api/bookmarks/$lessonId');
    if (bookmarked) {
      await http.delete(uri, headers: _headers);
    } else {
      await http.post(uri, headers: _headers);
    }
  }

  Future<List<HintStory>> fetchHints() async {
    final response = await http.get(Uri.parse('$baseUrl/api/hints/'), headers: _headers);
    final data = _decode(response) as List<dynamic>;
    return data.map((item) => HintStory.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<SearchResult> semanticSearch(String query) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/search/semantic'),
      headers: _headers,
      body: jsonEncode({'query': query}),
    );
    return SearchResult.fromJson(_decode(response));
  }

  Future<List<SearchHistoryItem>> fetchSearchHistory() async {
    final response = await http.get(Uri.parse('$baseUrl/api/search/history'), headers: _headers);
    final data = _decode(response) as List<dynamic>;
    return data.map((item) => SearchHistoryItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<RecommendationItem>> fetchRecommendations() async {
    final response = await http.get(Uri.parse('$baseUrl/api/recommendations/'), headers: _headers);
    final data = _decode(response) as List<dynamic>;
    return data.map((item) => RecommendationItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  dynamic _decode(http.Response response) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) {
      throw ApiException(data.toString());
    }
    return data;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
