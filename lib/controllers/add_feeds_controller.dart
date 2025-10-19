import 'package:get/get.dart';
import '../models/feed_item.dart';
import '../services/feed_service.dart';
import 'feed_controller.dart';

/// Controller for managing available feeds and adding/removing them
class AddFeedsController extends GetxController {
  final FeedService _feedService = FeedService();
  
  final RxMap<String, List<FeedSource>> categorizedFeeds = <String, List<FeedSource>>{}.obs;
  final RxList<FeedSource> userFeeds = <FeedSource>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAllFeeds();
    loadUserFeeds();
  }

  /// Load all available feeds from remote
  Future<void> loadAllFeeds() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final feeds = await _feedService.loadAllFeedSources();
      categorizedFeeds.value = feeds;
    } catch (e) {
      errorMessage.value = 'Failed to load feeds: ${e.toString()}';
      print('Error loading all feeds: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load user's current feeds
  Future<void> loadUserFeeds() async {
    userFeeds.value = await _feedService.loadUserFeedSources();
  }

  /// Check if a source is already added by user
  bool isSourceAdded(FeedSource source) {
    return userFeeds.any((s) => s.name == source.name && s.url == source.url);
  }

  /// Add a feed source to user's list
  Future<void> addFeedSource(FeedSource source) async {
    try {
      await _feedService.addFeedSource(source);
      await loadUserFeeds();
      
      // Update main feed controller
      final feedController = Get.find<FeedController>();
      await feedController.loadFeeds();
      
      Get.snackbar(
        'Added',
        '${source.name} added to your feeds',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add feed source',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Remove a feed source from user's list
  Future<void> removeFeedSource(FeedSource source) async {
    try {
      await _feedService.removeFeedSource(source);
      await loadUserFeeds();
      
      // Update main feed controller
      final feedController = Get.find<FeedController>();
      await feedController.loadFeeds();
      
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
}