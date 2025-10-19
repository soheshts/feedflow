import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/feed_controller.dart';
import '../models/feed_item.dart';
import '../widgets/feed_card.dart';
import 'article_screen.dart';

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
          return const Center(
            child: Text('No articles available'),
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
                  'Feed Sources',
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
              if (controller.feedSources.isEmpty) {
                return const Center(
                  child: Text('No sources available'),
                );
              }

              // Sort feed sources alphabetically by name
              final sortedSources = List<FeedSource>.from(controller.feedSources)
                ..sort((a, b) => a.name.compareTo(b.name));

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
                        trailing: controller.selectedSource.value == null
                            ? const Icon(Icons.check, color: Colors.deepPurple)
                            : null,
                        selected: controller.selectedSource.value == null,
                        onTap: () {
                          controller.filterBySource(null);
                          Get.back(); // Close drawer
                        },
                      )),
                  const Divider(),
                  // Individual sources (sorted alphabetically)
                  ...sortedSources.map((source) {
                    return Obx(() => ListTile(
                          leading: const Icon(Icons.rss_feed),
                          title: Text(source.name),
                          trailing:
                              controller.selectedSource.value == source.name
                                  ? const Icon(Icons.check,
                                      color: Colors.deepPurple)
                                  : null,
                          selected:
                              controller.selectedSource.value == source.name,
                          onTap: () {
                            controller.filterBySource(source.name);
                            Get.back(); // Close drawer
                          },
                        ));
                  }).toList(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}