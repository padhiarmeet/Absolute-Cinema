import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../db/database_helper.dart';

class WidgetSync {
  static const String appGroupId = 'group.movie_tracker'; // Not strictly needed for Android unless sharing files, but good practice.
  static const String androidWidgetName = 'MovieWidgetProvider';

  static Future<void> updateWidget() async {
    final movies = await DatabaseHelper.instance.readAllMovies();
    
    // Serialize the list of movies to JSON
    final moviesJson = jsonEncode(movies.map((m) => m.toMap()).toList());

    // Save to HomeWidget storage
    await HomeWidget.saveWidgetData<String>('movie_list', moviesJson);
    
    // Update the widget
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      qualifiedAndroidName: 'com.example.movie_tracker.MovieWidgetProvider',
    );
  }
}
