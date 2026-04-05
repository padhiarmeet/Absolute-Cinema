import 'dart:convert';
import 'package:http/http.dart' as http;

const String _bearerToken =
    'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI0ZGYwOGNlNWZmZThkZjNmMTY0YjAxZDM5OTMwNmQyNyIsIm5iZiI6MTc3MzM3OTkwNi40MDcsInN1YiI6IjY5YjNhMTQyM2Y3ZTkzODc2MmRjOGNmMyIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.S49qCV4rf7yiHURIUxmQ6AknWbLwO7nLafTZ3C48ehw';

class TmdbMovieResult {
  final int id;
  final String title;
  final String? releaseDate;
  final String? posterPath;
  final String? overview;
  final double? voteAverage;
  final int? voteCount;
  final double? popularity;

  TmdbMovieResult({
    required this.id,
    required this.title,
    this.releaseDate,
    this.posterPath,
    this.overview,
    this.voteAverage,
    this.voteCount,
    this.popularity,
  });

  String? get posterUrl =>
      posterPath != null ? 'https://image.tmdb.org/t/p/w500$posterPath' : null;

  String get releaseYear {
    if (releaseDate == null || releaseDate!.isEmpty) return 'N/A';
    return releaseDate!.split('-').first;
  }

  factory TmdbMovieResult.fromJson(Map<String, dynamic> json) {
    return TmdbMovieResult(
      id: json['id'] as int,
      title: json['title'] as String? ??
          json['original_title'] as String? ??
          'Unknown',
      releaseDate: json['release_date'] as String?,
      posterPath: json['poster_path'] as String?,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
      popularity: (json['popularity'] as num?)?.toDouble(),
    );
  }
}

class TmdbService {
  static const String _baseUrl = 'https://api.themoviedb.org/3';

  static Map<String, String> get _headers => {
        'Authorization': 'Bearer $_bearerToken',
        'accept': 'application/json',
      };

  /// Searches for movies by query string. Returns a list of results.
  static Future<List<TmdbMovieResult>> searchMovies(String query) async {
    if (query.trim().isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(query.trim());
    final uri = Uri.parse('$_baseUrl/search/movie?query=$encodedQuery');

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      return results
          .map((e) => TmdbMovieResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to search movies. Status: ${response.statusCode}');
    }
  }
}
