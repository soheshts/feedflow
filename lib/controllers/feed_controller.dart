import 'package:get/get.dart';
import '../models/feed_item.dart';
import '../services/feed_service.dart';

/// Controller for managing feed state and operations
class FeedController extends GetxController {
  final FeedService _feedService = FeedService();
  
  // Observable state
  final RxList<FeedItem> feedItems = <FeedItem>[].obs;
  final RxList<FeedItem> allFeedItems = <FeedItem>[].obs;
  final RxList<FeedSource> userFeedSources = <FeedSource>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentIndex = 0.obs;
  final Rxn<String> selectedSource = Rxn<String>(null); // null means "All"
  final Rxn<String> selectedCategory = Rxn<String>(null); // null means "All"

  @override
  void onInit() {
    super.onInit();
    loadFeeds();
  }

  /// Load feeds from all sources
  Future<void> loadFeeds() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Load user's feed sources
      userFeedSources.value = await _feedService.loadUserFeedSources();
      
      final items = await _feedService.fetchAllFeeds();
      
      if (items.isEmpty) {
        errorMessage.value = 'No articles found. Please add some feed sources.';
      } else {
        allFeedItems.value = items;
        _applyFilter();
      }
    } catch (e) {
      errorMessage.value = 'Failed to load feeds: ${e.toString()}';
      print('Error loading feeds: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh feeds (pull-to-refresh)
  Future<void> refreshFeeds() async {
    try {
      isRefreshing.value = true;
      errorMessage.value = '';
      
      userFeedSources.value = await _feedService.loadUserFeedSources();
      final items = await _feedService.fetchAllFeeds();
      
      if (items.isEmpty) {
        errorMessage.value = 'No articles found. Please add some feed sources.';
      } else {
        allFeedItems.value = items;
        _applyFilter();
        // Reset to first item after refresh
        currentIndex.value = 0;
        
        Get.snackbar(
          'Success',
          'Feeds refreshed with ${feedItems.length} articles',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      errorMessage.value = 'Failed to refresh feeds: ${e.toString()}';
      Get.snackbar(
        'Error',
        'Failed to refresh feeds',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isRefreshing.value = false;
    }
  }

  /// Filter feeds by source
  void filterBySource(String? sourceName) {
    selectedSource.value = sourceName;
    selectedCategory.value = null;
    currentIndex.value = 0;
    _applyFilter();
  }

  /// Filter feeds by category
  void filterByCategory(String? category) {
    selectedCategory.value = category;
    selectedSource.value = null;
    currentIndex.value = 0;
    _applyFilter();
  }

  /// Apply current filter
  void _applyFilter() {
    if (selectedSource.value != null) {
      // Filter by selected source
      feedItems.value = allFeedItems
          .where((item) => item.sourceName == selectedSource.value)
          .toList();
    } else if (selectedCategory.value != null) {
      // Filter by selected category
      final categorySourceNames = userFeedSources
          .where((source) => source.category == selectedCategory.value)
          .map((source) => source.name)
          .toSet();
      feedItems.value = allFeedItems
          .where((item) => categorySourceNames.contains(item.sourceName))
          .toList();
    } else {
      // Show all feeds
      feedItems.value = allFeedItems;
    }
  }

  /// Remove a feed source
  Future<void> removeFeedSource(FeedSource source) async {
    try {
      await _feedService.removeFeedSource(source);
      userFeedSources.remove(source);
      
      // Reload feeds after removal
      await loadFeeds();
      
      Get.snackbar(
        'Removed',
        '${source.name} removed from your feeds',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to remove feed source',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Update current viewing index
  void updateCurrentIndex(int index) {
    currentIndex.value = index;
  }
}