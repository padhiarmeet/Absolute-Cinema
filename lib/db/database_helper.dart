import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/movie.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('movies.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE movies ( 
  id INTEGER PRIMARY KEY AUTOINCREMENT, 
  tmdbId INTEGER,
  name TEXT NOT NULL,
  releaseDate TEXT NOT NULL,
  imagePath TEXT,
  overview TEXT,
  voteAverage REAL,
  voteCount INTEGER,
  popularity REAL
)
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // Add new columns for existing installs safely
      try {
        await db.execute('ALTER TABLE movies ADD COLUMN tmdbId INTEGER');
      } catch (_) {}
      
      try {
        await db.execute('ALTER TABLE movies ADD COLUMN overview TEXT');
      } catch (_) {}
    }
    
    if (oldVersion < 4) {
      try { await db.execute('ALTER TABLE movies ADD COLUMN voteAverage REAL'); } catch (_) {}
      try { await db.execute('ALTER TABLE movies ADD COLUMN voteCount INTEGER'); } catch (_) {}
      try { await db.execute('ALTER TABLE movies ADD COLUMN popularity REAL'); } catch (_) {}
    }
  }

  Future<int> create(Movie movie) async {
    final db = await instance.database;
    return await db.insert('movies', movie.toMap());
  }

  Future<List<Movie>> readAllMovies() async {
    final db = await instance.database;
    const orderBy = 'releaseDate ASC';
    final result = await db.query('movies', orderBy: orderBy);

    return result.map((json) => Movie.fromMap(json)).toList();
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'movies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
