import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/movie.dart';
import '../db/database_helper.dart';
import '../utils/widget_sync.dart';
import 'search_movie_screen.dart';
import 'movie_details_screen.dart';

enum SortOption { dateDesc, dateAsc, nameAsc, nameDesc }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Movie>> _moviesFuture;
  SortOption _currentSort = SortOption.dateDesc;

  @override
  void initState() {
    super.initState();
    _refreshMovies();
  }

  void _refreshMovies() {
    setState(() {
      _moviesFuture = DatabaseHelper.instance.readAllMovies();
    });
  }

  Future<void> _deleteMovie(int id) async {
    await DatabaseHelper.instance.delete(id);
    await WidgetSync.updateWidget();
    _refreshMovies();
  }

  List<Movie> _sortMovies(List<Movie> movies) {
    final sorted = List<Movie>.from(movies);
    switch (_currentSort) {
      case SortOption.dateDesc:
        sorted.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        break;
      case SortOption.dateAsc:
        sorted.sort((a, b) => a.releaseDate.compareTo(b.releaseDate));
        break;
      case SortOption.nameAsc:
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameDesc:
        sorted.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    // Original App Dark Theme Colors
    const bgColor = Color(0xFF0D0D1A);
    const cardColor = Color(0xFF1A1A2E);
    const accentColor = Colors.deepPurpleAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Row(
          children: [
            const Icon(Icons.movie_creation_rounded, color: accentColor),
            const SizedBox(width: 8),
            Text(
              'Movie Tracker',
              style: GoogleFonts.spaceMono(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          PopupMenuButton<SortOption>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white, size: 28),
            color: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (option) {
              setState(() {
                _currentSort = option;
              });
            },
            itemBuilder: (context) => [
              _buildSortItem(SortOption.dateDesc, 'Date (Newest)', Icons.arrow_downward_rounded),
              _buildSortItem(SortOption.dateAsc, 'Date (Oldest)', Icons.arrow_upward_rounded),
              _buildSortItem(SortOption.nameAsc, 'Name (A-Z)', Icons.sort_by_alpha_rounded),
              _buildSortItem(SortOption.nameDesc, 'Name (Z-A)', Icons.sort_by_alpha_rounded),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Movie>>(
        future: _moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColor));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.spaceMono(color: Colors.red)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.movie_filter_rounded, color: Colors.white24, size: 80),
                  const SizedBox(height: 24),
                  Text(
                    'No movies yet',
                    style: GoogleFonts.spaceMono(color: Colors.white54, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          final sortedMovies = _sortMovies(snapshot.data!);

          return MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: const EdgeInsets.all(8),
            itemCount: sortedMovies.length,
            itemBuilder: (context, index) {
              final movie = sortedMovies[index];
              return _MovieCard(
                movie: movie,
                onDelete: movie.id != null ? () => _deleteMovie(movie.id!) : null,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchMovieScreen()),
          );
          if (result == true) {
            _refreshMovies();
          }
        },
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.search_rounded),
        label: Text('Search', style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }

  PopupMenuItem<SortOption> _buildSortItem(SortOption value, String text, IconData icon) {
    final isSelected = _currentSort == value;
    const accentColor = Colors.deepPurpleAccent;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: isSelected ? accentColor : Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: GoogleFonts.spaceMono(
              color: isSelected ? accentColor : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onDelete;

  const _MovieCard({required this.movie, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = movie.imagePath != null && movie.imagePath!.startsWith('http');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailsScreen(movie: movie),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), // Reduced from 28
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
            // Using a Row with Expanded ensures the Image width fits the grid cell width,
            // while taking up its natural aspect ratio height.
            Row(
              children: [
                Expanded(
                  child: _buildPoster(isNetworkImage),
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
                    // Title
                    Text(
                      movie.name,
                      style: GoogleFonts.spaceMono(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Subtitle (Overview or Date)
                    Text(
                      movie.overview != null && movie.overview!.isNotEmpty 
                          ? movie.overview! 
                          : 'Released: ${DateFormat('yyyy').format(movie.releaseDate)}',
                      style: GoogleFonts.spaceMono(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // ── Top Right Delete Button ──
            if (onDelete != null)
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(

                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  radius: 14,
                  child: IconButton(
                    iconSize: 14,
                    padding: const EdgeInsets.all(0),
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoster(bool isNetworkImage) {
    if (movie.imagePath == null) return _fallbackPoster();
    if (isNetworkImage) {
      return Image.network(
        movie.imagePath!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 250, // Base height for Masonry blocks evaluating while loading
            color: const Color(0xFF252540),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurpleAccent),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _fallbackPoster(),
      );
    }
    return _fallbackPoster();
  }

  Widget _fallbackPoster() {
    return Container(
      height: 250,
      color: const Color(0xFF252540),
      child: const Center(
        child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 40),
      ),
    );
  }
}
