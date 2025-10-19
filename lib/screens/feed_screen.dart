import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/feed_controller.dart';
import '../models/feed_item.dart';
import '../widgets/feed_card.dart';
import 'article_screen.dart';
import 'add_feeds_screen.dart';

/// Main screen displaying the vertical feed of articles
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(FeedController());
    final pageController = PageController();

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(controller),
      appBar: AppBar(
        title: const Text(
          'FeedFlow',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Feeds',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFeedsScreen(),
                ),
              );
            },
          ),
          Obx(() => IconButton(
                icon: controller.isRefreshing.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: controller.isRefreshing.value
                    ? null
                    : () => controller.refreshFeeds(),
              )),
        ],
      ),
      body: Obx(() {
        // Loading state
        if (controller.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading feeds...'),
              ],
            ),
          );
        }

        // Error state
        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => controller.loadFeeds(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Empty state
        if (controller.feedItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.rss_feed,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No articles available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add some feed sources to get started',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddFeedsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Feeds'),
                  ),
                ],
              ),
            ),
          );
        }

        // Feed content
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => controller.refreshFeeds(),
              child: PageView.builder(
                controller: pageController,
                scrollDirection: Axis.vertical,
                itemCount: controller.feedItems.length,
                onPageChanged: (index) => controller.updateCurrentIndex(index),
                itemBuilder: (context, index) {
                  final item = controller.feedItems[index];
                  return FeedCard(
                    feedItem: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArticleScreen(feedItem: item),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            // Go to Top button (only show if not on first item)
            Obx(() => controller.currentIndex.value > 0
                ? Positioned(
                    bottom: 20,
                    right: 20,
                    child: FloatingActionButton(
                      onPressed: () {
                        pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Icon(Icons.arrow_upward),
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        );
      }),
    );
  }

  /// Build the drawer with feed source filter
  Widget _buildDrawer(FeedController controller) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple,
                  Colors.deepPurple.shade700,
                ],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.rss_feed,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 8),
                Text(
                  'My Feeds',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.userFeedSources.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'No feeds added yet.\nTap the + button to add feeds.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // Group sources by category
              final Map<String, List<FeedSource>> categorized = {};
              for (var source in controller.userFeedSources) {
                categorized.putIfAbsent(source.category, () => []).add(source);
              }

              // Sort categories alphabetically
              final sortedCategories = categorized.keys.toList()..sort();

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  // "All" option
                  Obx(() => ListTile(
                        leading: const Icon(Icons.select_all),
                        title: const Text(
                          'All Sources',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: controller.selectedSource.value == null &&
                                controller.selectedCategory.value == null
                            ? const Icon(Icons.check, color: Colors.deepPurple)
                            : null,
                        selected: controller.selectedSource.value == null &&
                            controller.selectedCategory.value == null,
                        onTap: () {
                          controller.filterBySource(null);
                          Get.back();
                        },
                      )),
                  const Divider(),
                  
                  // Categories with sources
                  ...sortedCategories.map((category) {
                    final sources = categorized[category]!;
                    return ExpansionTile(
                      leading: Icon(_getCategoryIcon(category)),
                      title: Text(
                        category.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Obx(() {
                        return controller.selectedCategory.value == category
                            ? const Icon(Icons.check, color: Colors.deepPurple)
                            : const SizedBox.shrink();
                      }),
                      onExpansionChanged: (expanded) {
                        if (expanded) {
                          controller.filterByCategory(category);
                        }
                      },
                      children: sources.map((source) {
                        return Obx(() => ListTile(
                              contentPadding: const EdgeInsets.only(left: 72, right: 16),
                              title: Text(source.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (controller.selectedSource.value == source.name)
                                    const Icon(Icons.check, color: Colors.deepPurple, size: 20),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    color: Colors.red,
                                    onPressed: () {
                                      controller.removeFeedSource(source);
                                    },
                                  ),
                                ],
                              ),
                              selected: controller.selectedSource.value == source.name,
                              onTap: () {
                                controller.filterBySource(source.name);
                                Get.back();
                              },
                            ));
                      }).toList(),
                    );
                  }).toList(),
                ],
              );
            }),
          ),
        ],
      ),
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