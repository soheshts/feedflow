import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feed_item.dart';
import 'feed_parser.dart';

const String _remoteFeedUrl = 'https://soheshts.github.io/feedflow/feeds.json';
const String _userFeedsKey = 'user_feeds';

/// Service for fetching and managing feeds
class FeedService {
  /// Load all available feed sources from remote
  Future<Map<String, List<FeedSource>>> loadAllFeedSources() async {
    try {
      final response = await http.get(Uri.parse(_remoteFeedUrl));
      
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(body) as Map<String, dynamic>;
        
        final Map<String, List<FeedSource>> categorizedFeeds = {};
        
        jsonData.forEach((category, sources) {
          final sourceList = (sources as List)
              .map((source) => FeedSource.fromJson(source as Map<String, dynamic>, category))
              .toList();
          categorizedFeeds[category] = sourceList;
        });
        
        return categorizedFeeds;
      } else {
        print('Failed to load remote feeds: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('Error loading remote feed sources: $e');
      return {};
    }
  }

  /// Load user's selected feed sources from local storage
  Future<List<FeedSource>> loadUserFeedSources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userFeedsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        // Return default feeds if none saved
        return await _getDefaultFeeds();
      }
      
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) {
            final map = json as Map<String, dynamic>;
            return FeedSource(
              name: map['name'] as String,
              url: map['url'] as String,
              category: map['category'] as String,
            );
          })
          .toList();
    } catch (e) {
      print('Error loading user feed sources: $e');
      return await _getDefaultFeeds();
    }
  }

  /// Get default feeds for first-time users
  Future<List<FeedSource>> _getDefaultFeeds() async {
    final allFeeds = await loadAllFeedSources();
    final defaultFeeds = <FeedSource>[];
    
    // Add first feed from each category as default
    allFeeds.forEach((category, sources) {
      if (sources.isNotEmpty) {
        defaultFeeds.add(sources.first);
      }
    });
    
    // Save defaults
    if (defaultFeeds.isNotEmpty) {
      await saveUserFeedSources(defaultFeeds);
    }
    
    return defaultFeeds;
  }

  /// Save user's selected feed sources
  Future<void> saveUserFeedSources(List<FeedSource> sources) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = sources.map((source) => source.toJson()).toList();
      await prefs.setString(_userFeedsKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving user feed sources: $e');
    }
  }

  /// Add a feed source to user's list
  Future<void> addFeedSource(FeedSource source) async {
    final sources = await loadUserFeedSources();
    if (!sources.contains(source)) {
      sources.add(source);
      await saveUserFeedSources(sources);
    }
  }

  /// Remove a feed source from user's list
  Future<void> removeFeedSource(FeedSource source) async {
    final sources = await loadUserFeedSources();
    sources.removeWhere((s) => s.name == source.name && s.url == source.url);
    await saveUserFeedSources(sources);
  }

  /// Fetch all feeds from user's selected sources
  Future<List<FeedItem>> fetchAllFeeds() async {
    final sources = await loadUserFeedSources();
    
    if (sources.isEmpty) {
      throw Exception('No feed sources configured');
    }

    // Fetch all feeds concurrently
    final results = await Future.wait(
      sources.map((source) => _fetchSingleFeed(source)),
    );

    // Merge all items into a single list
    final allItems = <FeedItem>[];
    for (var items in results) {
      allItems.addAll(items);
    }

    // Sort by published date (newest first)
    allItems.sort((a, b) {
      if (a.published == null && b.published == null) return 0;
      if (a.published == null) return 1;
      if (b.published == null) return -1;
      return b.published!.compareTo(a.published!);
    });

    return allItems;
  }

  /// Fetch and parse a single feed
  Future<List<FeedItem>> _fetchSingleFeed(FeedSource source) async {
    try {
      print('Fetching feed: ${source.name}');
      
      final response = await http.get(
        Uri.parse(source.url),
        headers: {
          'User-Agent': 'FeedFlow/1.0',
          'Accept-Charset': 'utf-8',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Ensure UTF-8 decoding
        final body = utf8.decode(response.bodyBytes);
        final items = FeedParser.parse(body, source.name);
        print('Parsed ${items.length} items from ${source.name}');
        return items;
      } else {
        print('Failed to fetch ${source.name}: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching feed ${source.name}: $e');
      return [];
    }
  }
}