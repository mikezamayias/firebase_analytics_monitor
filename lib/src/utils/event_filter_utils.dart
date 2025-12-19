/// Utility class for event filtering operations
class EventFilterUtils {
  // Private constructor to prevent instantiation
  EventFilterUtils._();

  /// Check if an event should be skipped based on hide/show filters
  ///
  /// Returns true if the event should be skipped (not displayed)
  ///
  /// [eventName] - The name of the event to check
  /// [hideEvents] - List of event names to hide
  /// [showOnlyEvents] - If non-empty, only show events in this list
  static bool shouldSkipEvent(
    String eventName,
    List<String> hideEvents,
    List<String> showOnlyEvents,
  ) {
    // If show-only is specified, only show those events
    if (showOnlyEvents.isNotEmpty) {
      return !showOnlyEvents.contains(eventName);
    }

    // If hide is specified, skip those events
    if (hideEvents.isNotEmpty) {
      return hideEvents.contains(eventName);
    }

    return false;
  }
}
