class Movie {
  final int? id;
  final int? tmdbId;
  final String name;
  final DateTime releaseDate;
  final String? imagePath; // Can be a TMDB URL or local file path
  final String? overview;
  final double? voteAverage;
  final int? voteCount;
  final double? popularity;

  Movie({
    this.id,
    this.tmdbId,
    required this.name,
    required this.releaseDate,
    this.imagePath,
    this.overview,
    this.voteAverage,
    this.voteCount,
    this.popularity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tmdbId': tmdbId,
      'name': name,
      'releaseDate': releaseDate.toIso8601String(),
      'imagePath': imagePath,
      'overview': overview,
      'voteAverage': voteAverage,
      'voteCount': voteCount,
      'popularity': popularity,
    };
  }

  factory Movie.fromMap(Map<String, dynamic> map) {
    return Movie(
      id: map['id'],
      tmdbId: map['tmdbId'],
      name: map['name'],
      releaseDate: DateTime.parse(map['releaseDate']),
      imagePath: map['imagePath'],
      overview: map['overview'],
      voteAverage: map['voteAverage'],
      voteCount: map['voteCount'],
      popularity: map['popularity'],
    );
  }

  /// Creates a Movie from a TMDB search result JSON object.
  factory Movie.fromTmdbJson(Map<String, dynamic> json) {
    final posterPath = json['poster_path'] as String?;
    final releaseDateStr = json['release_date'] as String?;

    return Movie(
      tmdbId: json['id'] as int?,
      name: json['title'] as String? ?? json['original_title'] as String? ?? 'Unknown',
      releaseDate: (releaseDateStr != null && releaseDateStr.isNotEmpty)
          ? DateTime.tryParse(releaseDateStr) ?? DateTime.now()
          : DateTime.now(),
      imagePath: posterPath != null
          ? 'https://image.tmdb.org/t/p/w500$posterPath'
          : null,
      overview: json['overview'] as String?,
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'] as int?,
      popularity: (json['popularity'] as num?)?.toDouble(),
    );
  }
}
