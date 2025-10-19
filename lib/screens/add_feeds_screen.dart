import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/add_feeds_controller.dart';

/// Screen for browsing and adding new feed sources
class AddFeedsScreen extends StatelessWidget {
  const AddFeedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddFeedsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Feeds'),
        elevation: 2,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => controller.loadAllFeeds(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.categorizedFeeds.isEmpty) {
          return const Center(
            child: Text('No feeds available'),
          );
        }

        final categories = controller.categorizedFeeds.keys.toList()..sort();

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final feeds = controller.categorizedFeeds[category]!;

            return ExpansionTile(
              title: Text(
                category.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              leading: Icon(_getCategoryIcon(category)),
              initiallyExpanded: index == 0,
              children: feeds.map((feed) {
                return Obx(() {
                  final isAdded = controller.isSourceAdded(feed);
                  return ListTile(
                    title: Text(feed.name),
                    subtitle: Text(
                      feed.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isAdded ? Icons.check_circle : Icons.add_circle_outline,
                        color: isAdded ? Colors.green : Colors.blue,
                      ),
                      onPressed: () {
                        if (isAdded) {
                          controller.removeFeedSource(feed);
                        } else {
                          controller.addFeedSource(feed);
                        }
                      },
                    ),
                  );
                });
              }).toList(),
            );
          },
        );
      }),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
        return Icons.computer;
      case 'entertainment':
        return Icons.movie;
      case 'environment':
        return Icons.nature;
      case 'gaming':
        return Icons.sports_esports;
      case 'news':
        return Icons.newspaper;
      case 'sports':
        return Icons.sports_soccer;
      case 'business':
        return Icons.business;
      case 'science':
        return Icons.science;
      default:
        return Icons.rss_feed;
    }
  }
}