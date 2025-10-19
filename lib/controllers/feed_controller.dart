import 'package:get/get.dart';
import '../models/feed_item.dart';
import '../services/feed_service.dart';

/// Controller for managing feed state and operations
class FeedController extends GetxController {
  final FeedService _feedService = FeedService();
  
  // Observable state
  final RxList<FeedItem> feedItems = <FeedItem>[].obs;
  final RxList<FeedItem> allFeedItems = <FeedItem>[].obs;
  final RxList<FeedSource> feedSources = <FeedSource>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;
  final RxInt currentIndex = 0.obs;
  final Rxn<String> selectedSource = Rxn<String>(null); // null means "All"

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
      
      // Load feed sources first
      feedSources.value = await _feedService.loadFeedSources();
      
      final items = await _feedService.fetchAllFeeds();
      
      if (items.isEmpty) {
        errorMessage.value = 'No articles found. Please check your feed sources.';
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
      
      feedSources.value = await _feedService.loadFeedSources();
      final items = await _feedService.fetchAllFeeds();
      
      if (items.isEmpty) {
        errorMessage.value = 'No articles found. Please check your feed sources.';
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
    currentIndex.value = 0;
    _applyFilter();
  }

  /// Apply current filter
  void _applyFilter() {
    if (selectedSource.value == null) {
      // Show all feeds
      feedItems.value = allFeedItems;
    } else {
      // Filter by selected source
      feedItems.value = allFeedItems
          .where((item) => item.sourceName == selectedSource.value)
          .toList();
    }
  }

  /// Update current viewing index
  void updateCurrentIndex(int index) {
    currentIndex.value = index;
  }
}