package com.example.movie_tracker

import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*

class MovieWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return MovieRemoteViewsFactory(this.applicationContext)
    }
}

class MovieRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private data class MovieItem(
        val name: String,
        val releaseDate: String,
        val imagePath: String?,
        val dateMs: Long
    )

    private var movies: List<MovieItem> = emptyList()
    private val posterCache = mutableMapOf<String, Bitmap>()
    private val parseFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
    private val displayFormat = SimpleDateFormat("MMM dd, yyyy", Locale.US)

    override fun onCreate() {}

    override fun onDataSetChanged() {
        val prefs = es.antonborri.home_widget.HomeWidgetPlugin.getData(context)
        val moviesJson = prefs.getString("movie_list", "[]") ?: "[]"

        val list = mutableListOf<MovieItem>()
        try {
            val jsonArray = JSONArray(moviesJson)
            for (i in 0 until jsonArray.length()) {
                val obj = jsonArray.getJSONObject(i)
                val name = obj.optString("name", "Unknown")
                val dateStr = obj.optString("releaseDate", "")
                val imagePath = obj.optString("imagePath", "").takeIf { it.isNotBlank() }

                val dateMs = try {
                    parseFormat.parse(dateStr)?.time ?: 0L
                } catch (e: Exception) { 0L }

                list.add(MovieItem(name, dateStr, imagePath, dateMs))
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }

        list.sortBy { it.dateMs }
        movies = list
        posterCache.clear()
    }

    override fun onDestroy() {
        posterCache.clear()
    }

    override fun getCount(): Int = movies.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_item)
        val movie = movies[position]

        val dateDisplay = try {
            val d = parseFormat.parse(movie.releaseDate)
            if (d != null) displayFormat.format(d) else movie.releaseDate
        } catch (e: Exception) { movie.releaseDate }

        views.setTextViewText(R.id.movie_name, movie.name)
        views.setTextViewText(R.id.movie_date, dateDisplay)

        val bitmap = loadPoster(movie.imagePath)
        if (bitmap != null) {
            views.setImageViewBitmap(R.id.movie_poster, bitmap)
        } else {
            views.setImageViewResource(R.id.movie_poster, android.R.drawable.ic_menu_gallery)
        }

        return views
    }

    private fun loadPoster(imageUrl: String?): Bitmap? {
        if (imageUrl.isNullOrBlank()) return null
        posterCache[imageUrl]?.let { return it }

        return try {
            val connection = URL(imageUrl).openConnection() as HttpURLConnection
            connection.connectTimeout = 5000
            connection.readTimeout = 10000
            connection.doInput = true
            connection.connect()

            val raw = BitmapFactory.decodeStream(connection.inputStream)
            connection.disconnect()

            if (raw != null) {
                val scaled = Bitmap.createScaledBitmap(raw, 300, 450, true)
                if (scaled !== raw) raw.recycle()
                posterCache[imageUrl] = scaled
                scaled
            } else null
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
