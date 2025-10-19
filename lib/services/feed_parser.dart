import 'dart:convert';
import 'package:xml/xml.dart';
import '../models/feed_item.dart';

/// Service for parsing RSS, Atom, and JSON Feed formats
class FeedParser {
  /// Parse feed content based on detected format
  static List<FeedItem> parse(String content, String sourceName) {
    try {
      // Try JSON Feed first
      if (content.trim().startsWith('{')) {
        return _parseJsonFeed(content, sourceName);
      }
      
      // Try XML-based feeds (RSS/Atom)
      return _parseXmlFeed(content, sourceName);
    } catch (e) {
      print('Error parsing feed from $sourceName: $e');
      return [];
    }
  }

  /// Parse JSON Feed 1.x format
  static List<FeedItem> _parseJsonFeed(String content, String sourceName) {
    final json = jsonDecode(content) as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>?;
    
    if (items == null) return [];
    
    return items.map((item) {
      final itemMap = item as Map<String, dynamic>;
      
      // Get image from multiple possible locations
      String? imageUrl;
      if (itemMap['image'] != null) {
        imageUrl = itemMap['image'] as String;
      } else if (itemMap['banner_image'] != null) {
        imageUrl = itemMap['banner_image'] as String;
      } else if (itemMap['attachments'] != null) {
        final attachments = itemMap['attachments'] as List<dynamic>;
        if (attachments.isNotEmpty) {
          final first = attachments[0] as Map<String, dynamic>;
          if (first['mime_type']?.toString().startsWith('image/') == true) {
            imageUrl = first['url'] as String?;
          }
        }
      }
      
      return FeedItem(
        title: itemMap['title'] as String? ?? 'Untitled',
        link: itemMap['url'] as String? ?? '',
        description: itemMap['content_html'] as String? ?? 
                     itemMap['content_text'] as String? ?? 
                     itemMap['summary'] as String? ?? '',
        author: itemMap['authors']?[0]?['name'] as String? ?? 
                itemMap['author']?['name'] as String?,
        published: itemMap['date_published'] != null
            ? DateTime.tryParse(itemMap['date_published'] as String)
            : null,
        imageUrl: imageUrl,
        sourceName: sourceName,
      );
    }).toList();
  }

  /// Parse XML-based feeds (RSS 2.0 and Atom 1.0)
  static List<FeedItem> _parseXmlFeed(String content, String sourceName) {
    final document = XmlDocument.parse(content);
    
    // Detect feed type
    final rssChannel = document.findAllElements('channel').firstOrNull;
    if (rssChannel != null) {
      return _parseRss(document, sourceName);
    }
    
    final atomFeed = document.findAllElements('feed').firstOrNull;
    if (atomFeed != null) {
      return _parseAtom(document, sourceName);
    }
    
    return [];
  }

  /// Parse RSS 2.0 format
  static List<FeedItem> _parseRss(XmlDocument document, String sourceName) {
    final items = document.findAllElements('item');
    
    return items.map((item) {
      final title = item.findElements('title').firstOrNull?.innerText ?? 'Untitled';
      final link = item.findElements('link').firstOrNull?.innerText ?? '';
      final description = item.findElements('description').firstOrNull?.innerText ?? '';
      final author = item.findElements('author').firstOrNull?.innerText ??
                     item.findElements('dc:creator').firstOrNull?.innerText;
      final pubDate = item.findElements('pubDate').firstOrNull?.innerText;
      
      // Try to find image from multiple sources
      String? imageUrl;
      
      // Check media:content
      final mediaContent = item.findElements('media:content').firstOrNull;
      if (mediaContent != null) {
        imageUrl = mediaContent.getAttribute('url');
      }
      
      // Check media:thumbnail
      if (imageUrl == null) {
        final mediaThumbnail = item.findElements('media:thumbnail').firstOrNull;
        if (mediaThumbnail != null) {
          imageUrl = mediaThumbnail.getAttribute('url');
        }
      }
      
      // Check enclosure
      if (imageUrl == null) {
        final enclosure = item.findElements('enclosure').firstOrNull;
        if (enclosure != null && 
            enclosure.getAttribute('type')?.startsWith('image/') == true) {
          imageUrl = enclosure.getAttribute('url');
        }
      }
      
      // Extract from content:encoded or description
      if (imageUrl == null) {
        final contentEncoded = item.findElements('content:encoded').firstOrNull?.innerText;
        imageUrl = _extractImageFromHtml(contentEncoded ?? description);
      }
      
      return FeedItem(
        title: title,
        link: link,
        description: description,
        author: author,
        published: pubDate != null ? _parseDate(pubDate) : null,
        imageUrl: imageUrl,
        sourceName: sourceName,
      );
    }).toList();
  }

  /// Parse Atom 1.0 format
  static List<FeedItem> _parseAtom(XmlDocument document, String sourceName) {
    final entries = document.findAllElements('entry');
    
    return entries.map((entry) {
      final title = entry.findElements('title').firstOrNull?.innerText ?? 'Untitled';
      
      // Get link
      String link = '';
      final links = entry.findElements('link');
      for (var l in links) {
        if (l.getAttribute('rel') == 'alternate' || 
            l.getAttribute('type')?.contains('html') == true) {
          link = l.getAttribute('href') ?? '';
          break;
        }
      }
      if (link.isEmpty && links.isNotEmpty) {
        link = links.first.getAttribute('href') ?? '';
      }
      
      final summary = entry.findElements('summary').firstOrNull?.innerText ?? '';
      final content = entry.findElements('content').firstOrNull?.innerText ?? '';
      final description = content.isNotEmpty ? content : summary;
      
      final author = entry.findElements('author')
          .firstOrNull?.findElements('name').firstOrNull?.innerText;
      
      final published = entry.findElements('published').firstOrNull?.innerText ??
                       entry.findElements('updated').firstOrNull?.innerText;
      
      // Try to find image
      String? imageUrl;
      
      // Check for link with image type
      for (var l in links) {
        final type = l.getAttribute('type');
        if (type?.startsWith('image/') == true) {
          imageUrl = l.getAttribute('href');
          break;
        }
      }
      
      // Extract from content
      if (imageUrl == null) {
        imageUrl = _extractImageFromHtml(description);
      }
      
      return FeedItem(
        title: title,
        link: link,
        description: description,
        author: author,
        published: published != null ? DateTime.tryParse(published) : null,
        imageUrl: imageUrl,
        sourceName: sourceName,
      );
    }).toList();
  }

  /// Parse various date formats
  static DateTime? _parseDate(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // Try RFC 822 format (common in RSS)
      try {
        final parts = dateString.split(' ');
        if (parts.length >= 4) {
          final day = int.parse(parts[1]);
          final monthStr = parts[2];
          final year = int.parse(parts[3]);
          final time = parts[4].split(':');
          
          final months = {
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
          };
          
          final month = months[monthStr] ?? 1;
          
          return DateTime(
            year,
            month,
            day,
            int.parse(time[0]),
            int.parse(time[1]),
            time.length > 2 ? int.parse(time[2]) : 0,
          );
        }
      } catch (e) {
        print('Failed to parse date: $dateString');
      }
    }
    return null;
  }

  /// Extract first image URL from HTML content
  static String? _extractImageFromHtml(String html) {
    final imgRegex = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false);
    final match = imgRegex.firstMatch(html);
    return match?.group(1);
  }
}