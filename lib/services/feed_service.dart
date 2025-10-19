import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/feed_item.dart';
import 'feed_parser.dart';

/// Service for fetching and managing feeds
class FeedService {
  /// Load feed sources from assets
  Future<List<FeedSource>> loadFeedSources() async {
    try {
      final jsonString = await rootBundle.loadString('assets/feeds.json');
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => FeedSource.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading feed sources: $e');
      return [];
    }
  }

  /// Fetch all feeds concurrently and merge them
  Future<List<FeedItem>> fetchAllFeeds() async {
    final sources = await loadFeedSources();
    
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