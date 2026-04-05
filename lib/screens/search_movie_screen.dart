import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/movie.dart';
import '../services/tmdb_service.dart';
import '../db/database_helper.dart';
import '../utils/widget_sync.dart';
import 'movie_details_screen.dart';

class SearchMovieScreen extends StatefulWidget {
  const SearchMovieScreen({super.key});

  @override
  State<SearchMovieScreen> createState() => _SearchMovieScreenState();
}

class _SearchMovieScreenState extends State<SearchMovieScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<TmdbMovieResult> _results = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final results = await TmdbService.searchMovies(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to search. Check your internet connection.';
      });
    }
  }

  Future<void> _addMovie(TmdbMovieResult result) async {
    final movie = Movie.fromTmdbJson({
      'id': result.id,
      'title': result.title,
      'release_date': result.releaseDate,
      'poster_path': result.posterPath,
      'overview': result.overview,
    });

    await DatabaseHelper.instance.create(movie);
    await WidgetSync.updateWidget();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '"${result.title}" added to your list',
            style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0D0D1A);
    const accentColor = Colors.deepPurpleAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        title: Text(
          'Search Movies',
          style: GoogleFonts.spaceMono(
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.spaceMono(color: Colors.white),
              cursorColor: accentColor,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search for a movie...',
                hintStyle: GoogleFonts.spaceMono(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, color: accentColor),
                  onPressed: _search,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Results ─────────────────────────────────────────────────────
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    const accentColor = Colors.deepPurpleAccent;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 56),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: GoogleFonts.spaceMono(color: Colors.white70)),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_outlined, color: Colors.white24, size: 80),
            const SizedBox(height: 16),
            Text(
              'Search for any movie',
              style: GoogleFonts.spaceMono(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, color: Colors.white24, size: 80),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.spaceMono(color: Colors.white38, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 32),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final movie = _results[index];
        return _MovieResultCard(movie: movie, onTap: () => _addMovie(movie));
      },
    );
  }
}

class _MovieResultCard extends StatelessWidget {
  final TmdbMovieResult movie;
  final VoidCallback onTap;

  const _MovieResultCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailsScreen(
              movie: Movie.fromTmdbJson({
                'id': movie.id,
                'title': movie.title,
                'release_date': movie.releaseDate,
                'poster_path': movie.posterPath,
                'overview': movie.overview,
                'vote_average': movie.voteAverage,
                'vote_count': movie.voteCount,
                'popularity': movie.popularity,
              }),
            ),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // ── Base Background Poster ──
            Row(
              children: [
                Expanded(
                  child: movie.posterUrl != null
                      ? Image.network(
                          movie.posterUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 250,
                              color: const Color(0xFF252540),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.deepPurpleAccent,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => _NoPoster(),
                        )
                      : _NoPoster(),
                ),
              ],
            ),

            // ── Frosted Gradient Overlay ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: GoogleFonts.spaceMono(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.overview != null && movie.overview!.isNotEmpty 
                          ? movie.overview! 
                          : 'Released: ${movie.releaseYear}',
                      style: GoogleFonts.spaceMono(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                         ElevatedButton(
                           onPressed: onTap,
                           style: ElevatedButton.styleFrom(
                             backgroundColor: Colors.white,
                             foregroundColor: Colors.black,
                             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(16),
                             ),
                             elevation: 0,
                             minimumSize: const Size(0, 32),
                           ),
                           child: Text(
                             'Add +',
                             style: GoogleFonts.spaceMono(
                               fontWeight: FontWeight.w900,
                               fontSize: 11,
                             ),
                           ),
                         ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoPoster extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 250,
            color: const Color(0xFF252540),
            child: const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}
