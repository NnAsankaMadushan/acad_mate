import 'dart:convert';
import 'package:acad_mate/core/config/app_config.dart';
import 'package:acad_mate/domain/entities/academic_filter.dart';
import 'package:acad_mate/domain/entities/past_paper.dart';
import 'package:acad_mate/domain/entities/question_set.dart';
import 'package:acad_mate/domain/repositories/academic_repository.dart';
import 'package:http/http.dart' as http;

class BackendAcademicRepository implements AcademicRepository {
  BackendAcademicRepository({
    required String baseUrl,
    http.Client? client,
  })  : _baseUri = Uri.parse(baseUrl.trim().replaceFirst(RegExp(r'/$'), '')),
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  @override
  Future<List<QuestionSet>> fetchQuestionSets({
    required CatalogFilter filter,
  }) async {
    final Map<String, String> params = <String, String>{};
    if (filter.grade != 'All') params['grade'] = filter.grade;
    if (filter.subject != 'All') params['subject'] = filter.subject;
    if (filter.stream != 'All') params['stream'] = filter.stream;
    if (filter.search.isNotEmpty) params['search'] = filter.search;

    final Uri uri = _uri('/academic/question-sets').replace(queryParameters: params);
    
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{'Accept': 'application/json'},
    );

    final List<dynamic> data = _decodeListResponse(response);
    return data.map((dynamic item) => QuestionSet.fromMap(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<QuestionSet?> fetchQuestionSetById(String setId) async {
    final Uri uri = _uri('/academic/question-sets/$setId');
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{'Accept': 'application/json'},
    );

    if (response.statusCode == 404) return null;
    final Map<String, dynamic> data = _decodeObjectResponse(response);
    return QuestionSet.fromMap(data);
  }

  @override
  Future<List<PastPaper>> fetchPastPapers({
    required CatalogFilter filter,
  }) async {
    final Map<String, String> params = <String, String>{};
    if (filter.grade != 'All') params['grade'] = filter.grade;
    if (filter.subject != 'All') params['subject'] = filter.subject;
    if (filter.stream != 'All') params['stream'] = filter.stream;
    if (filter.search.isNotEmpty) params['search'] = filter.search;

    final Uri uri = _uri('/academic/past-papers').replace(queryParameters: params);
    
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{'Accept': 'application/json'},
    );

    final List<dynamic> data = _decodeListResponse(response);
    return data.map((dynamic item) => PastPaper.fromMap(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<PastPaper?> fetchPastPaperById(String paperId) async {
    final Uri uri = _uri('/academic/past-papers/$paperId');
    final http.Response response = await _client.get(
      uri,
      headers: <String, String>{'Accept': 'application/json'},
    );

    if (response.statusCode == 404) return null;
    final Map<String, dynamic> data = _decodeObjectResponse(response);
    return PastPaper.fromMap(data);
  }

  Uri _uri(String path) {
    final String normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return _baseUri.resolve(normalizedPath);
  }

  List<dynamic> _decodeListResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Backend request failed (${response.statusCode}): ${response.body}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is List) return decoded;
    throw Exception('Backend returned unexpected payload: ${response.body}');
  }

  Map<String, dynamic> _decodeObjectResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Backend request failed (${response.statusCode}): ${response.body}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Backend returned unexpected payload: ${response.body}');
  }
}
