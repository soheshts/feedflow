/// Represents a single feed article item
class FeedItem {
  final String title;
  final String link;
  final String description;
  final String? author;
  final DateTime? published;
  final String? imageUrl;
  final String sourceName;

  FeedItem({
    required this.title,
    required this.link,
    required this.description,
    this.author,
    this.published,
    this.imageUrl,
    required this.sourceName,
  });

  /// Returns a clean description without HTML tags (max 300 chars)
  String get cleanDescription {
    String clean = description
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
    
    if (clean.length > 300) {
      return '${clean.substring(0, 300)}...';
    }
    return clean;
  }

  /// Returns formatted date string
  String get formattedDate {
    if (published == null) return 'Unknown date';
    
    final now = DateTime.now();
    final diff = now.difference(published!);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${published!.day}/${published!.month}/${published!.year}';
    }
  }
}

/// Represents a feed source configuration
class FeedSource {
  final String name;
  final String url;
  final String category;

  FeedSource({
    required this.name,
    required this.url,
    required this.category,
  });

  factory FeedSource.fromJson(Map<String, dynamic> json, String category) {
    return FeedSource(
      name: json['name'] as String,
      url: json['url'] as String,
      category: category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'category': category,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedSource &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          url == other.url;

  @override
  int get hashCode => name.hashCode ^ url.hashCode;
}