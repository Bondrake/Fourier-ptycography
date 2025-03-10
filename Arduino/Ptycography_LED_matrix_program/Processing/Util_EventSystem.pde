/**
 * EventSystem.pde
 * 
 * A simple event system for component communication.
 * Implements a publisher-subscriber pattern for decoupled communication.
 * 
 * This system allows components to register for events and publish events
 * without needing to know about each other directly.
 */

// Define event types as static final strings
static final class EventType {
  // System events
  public static final String PATTERN_CHANGED = "pattern_changed";
  public static final String STATE_CHANGED = "state_changed";
  public static final String CAMERA_STATUS_CHANGED = "camera_status_changed";
  public static final String CAMERA_SETTINGS_CHANGED = "camera_settings_changed";
  public static final String HARDWARE_CONNECTED = "hardware_connected";
  public static final String HARDWARE_DISCONNECTED = "hardware_disconnected";
  public static final String SERIAL_DATA_RECEIVED = "serial_data_received";
  public static final String SERIAL_PORTS_CHANGED = "serial_ports_changed";
  public static final String SERIAL_CONNECTED = "serial_connected";
  public static final String SERIAL_DISCONNECTED = "serial_disconnected";
  
  // UI events
  public static final String REFRESH_UI = "refresh_ui";
  public static final String UI_SIZE_CHANGED = "ui_size_changed";
  
  // Configuration events
  public static final String CONFIG_LOADED = "config_loaded";
  public static final String CONFIG_SAVED = "config_saved";
}

/**
 * EventData class for passing data with events
 */
class EventData {
  private HashMap<String, Object> data;
  
  public EventData() {
    data = new HashMap<String, Object>();
  }
  
  public EventData(String key, Object value) {
    this();
    put(key, value);
  }
  
  public EventData put(String key, Object value) {
    data.put(key, value);
    return this;
  }
  
  public Object get(String key) {
    return data.get(key);
  }
  
  public boolean hasKey(String key) {
    return data.containsKey(key);
  }
  
  public String getString(String key, String defaultValue) {
    Object value = get(key);
    return (value instanceof String) ? (String)value : defaultValue;
  }
  
  public int getInt(String key, int defaultValue) {
    Object value = get(key);
    return (value instanceof Integer) ? (Integer)value : defaultValue;
  }
  
  public float getFloat(String key, float defaultValue) {
    Object value = get(key);
    return (value instanceof Float) ? (Float)value : defaultValue;
  }
  
  public boolean getBoolean(String key, boolean defaultValue) {
    Object value = get(key);
    return (value instanceof Boolean) ? (Boolean)value : defaultValue;
  }
}

/**
 * Event handler interface
 */
interface EventHandler {
  void handleEvent(String eventType, EventData data);
}

/**
 * Event bus for publishing and subscribing to events
 */
// Singleton instance - must be outside the class for Processing compatibility
EventBus eventBusInstance = null;

// Global function to get EventBus instance (Processing compatibility)
EventBus getEventBus() {
  if (eventBusInstance == null) {
    eventBusInstance = new EventBus();
  }
  return eventBusInstance;
}

class EventBus {
  private HashMap<String, ArrayList<EventHandler>> subscribers;
  
  // Private constructor (singleton pattern)
  private EventBus() {
    subscribers = new HashMap<String, ArrayList<EventHandler>>();
  }
  
  // Instance getter (non-static for Processing compatibility)
  // Use the global getEventBus() function instead
  public EventBus getInstance() {
    return getEventBus();
  }
  
  // Subscribe to an event
  public void subscribe(String eventType, EventHandler handler) {
    // Get or create the list of subscribers for this event type
    ArrayList<EventHandler> handlers = subscribers.get(eventType);
    if (handlers == null) {
      handlers = new ArrayList<EventHandler>();
      subscribers.put(eventType, handlers);
    }
    
    // Add the handler if it's not already subscribed
    if (!handlers.contains(handler)) {
      handlers.add(handler);
    }
  }
  
  // Unsubscribe from an event
  public void unsubscribe(String eventType, EventHandler handler) {
    ArrayList<EventHandler> handlers = subscribers.get(eventType);
    if (handlers != null) {
      handlers.remove(handler);
      
      // Remove the event type if there are no more subscribers
      if (handlers.isEmpty()) {
        subscribers.remove(eventType);
      }
    }
  }
  
  // Publish an event
  public void publish(String eventType) {
    publish(eventType, new EventData());
  }
  
  // Publish an event with data
  public void publish(String eventType, EventData data) {
    ArrayList<EventHandler> handlers = subscribers.get(eventType);
    if (handlers != null) {
      // Create a copy of the handlers list to prevent concurrent modification
      ArrayList<EventHandler> handlersCopy = new ArrayList<EventHandler>(handlers);
      
      // Notify all subscribers
      for (EventHandler handler : handlersCopy) {
        handler.handleEvent(eventType, data);
      }
    }
  }
  
  // Check if there are any subscribers for an event type
  public boolean hasSubscribers(String eventType) {
    ArrayList<EventHandler> handlers = subscribers.get(eventType);
    return handlers != null && !handlers.isEmpty();
  }
  
  // Clear all subscribers
  public void clear() {
    subscribers.clear();
  }
}

/**
 * Class to make event subscription and publishing easier
 * by implementing common functionality
 */
class EventDispatcher implements EventHandler {
  // Register for events with the bus
  protected void registerEvent(String eventType) {
    getEventBus().subscribe(eventType, this);
  }
  
  // Unregister from events with the bus
  protected void unregisterEvent(String eventType) {
    getEventBus().unsubscribe(eventType, this);
  }
  
  // Publish an event
  protected void publishEvent(String eventType) {
    getEventBus().publish(eventType);
  }
  
  // Publish an event with data
  protected void publishEvent(String eventType, EventData data) {
    getEventBus().publish(eventType, data);
  }
  
  // Handle incoming events (to be overridden by subclasses)
  public void handleEvent(String eventType, EventData data) {
    // Default implementation does nothing
  }
}

/**
 * ThrottledEventSystem
 * 
 * This file contains classes related to event throttling in the event system.
 * Throttling prevents performance issues by limiting the frequency of events,
 * particularly for rapid UI updates and hardware/serial communication.
 * 
 * Key components:
 * - ThrottledEventDispatcher: Base class for throttling event publishing
 * - Event-specific implementations (e.g., ThrottledSystemStateModel)
 * 
 * Usage:
 * 1. Extend ThrottledEventDispatcher for a component that needs throttling
 * 2. Override publishEvent to use throttling for specific event types
 * 3. Register the throttled dispatcher with the central controller
 * 4. Call update() regularly (this happens automatically in the draw loop)
 */

/**
 * ThrottledEventDispatcher extends EventDispatcher to add event throttling.
 * This class limits how frequently events can be published to prevent
 * performance issues with rapidly firing events.
 */
class ThrottledEventDispatcher extends EventDispatcher {
  // Map to track last time an event was published by type
  private HashMap<String, Long> lastPublishTime;
  // Map to store default throttle intervals by event type
  private HashMap<String, Integer> throttleIntervals;
  // Map to store pending events that need to be published after throttle
  private HashMap<String, EventData> pendingEvents;
  
  // Default throttle interval in milliseconds
  private static final int DEFAULT_THROTTLE_INTERVAL = 100;
  
  /**
   * Constructor
   */
  public ThrottledEventDispatcher() {
    super();
    lastPublishTime = new HashMap<String, Long>();
    throttleIntervals = new HashMap<String, Integer>();
    pendingEvents = new HashMap<String, EventData>();
  }
  
  /**
   * Set throttle interval for a specific event type
   * 
   * @param eventType The event type to throttle
   * @param interval Throttle interval in milliseconds
   */
  public void setThrottleInterval(String eventType, int interval) {
    throttleIntervals.put(eventType, interval);
  }
  
  /**
   * Get throttle interval for a specific event type
   * 
   * @param eventType The event type
   * @return Throttle interval in milliseconds
   */
  public int getThrottleInterval(String eventType) {
    Integer interval = throttleIntervals.get(eventType);
    return (interval != null) ? interval : DEFAULT_THROTTLE_INTERVAL;
  }
  
  /**
   * Publish an event with throttling
   * 
   * @param eventType The event type
   */
  @Override
  protected void publishEvent(String eventType) {
    publishEvent(eventType, new EventData());
  }
  
  /**
   * Publish an event with data and throttling
   * 
   * @param eventType The event type
   * @param data Event data
   */
  @Override
  protected void publishEvent(String eventType, EventData data) {
    long currentTime = millis();
    Long lastTime = lastPublishTime.get(eventType);
    int interval = getThrottleInterval(eventType);
    
    // Check if we've published this event recently
    if (lastTime == null || currentTime - lastTime >= interval) {
      // It's been long enough since the last publish, so publish now
      super.publishEvent(eventType, data);
      lastPublishTime.put(eventType, Long.valueOf(currentTime));
      pendingEvents.remove(eventType); // Clear any pending event
    } else {
      // Store this as a pending event to be published later
      pendingEvents.put(eventType, data);
    }
  }
  
  /**
   * Update method - should be called regularly (e.g., in draw())
   * Publishes any pending events that have exceeded their throttle interval
   */
  public void update() {
    long currentTime = millis();
    
    // Create a copy of the keys to prevent concurrent modification
    ArrayList<String> eventTypes = new ArrayList<String>(pendingEvents.keySet());
    
    for (String eventType : eventTypes) {
      Long lastTime = lastPublishTime.get(eventType);
      int interval = getThrottleInterval(eventType);
      
      // Check if enough time has passed since the last publish
      if (lastTime != null && currentTime - lastTime >= interval) {
        // Get the pending event data and publish it
        EventData data = pendingEvents.get(eventType);
        if (data != null) {
          super.publishEvent(eventType, data);
          lastPublishTime.put(eventType, Long.valueOf(currentTime));
          pendingEvents.remove(eventType);
        }
      }
    }
  }
  
  /**
   * Force immediate publication of a pending event,
   * ignoring the throttle interval
   * 
   * @param eventType The event type to force publish
   * @return True if a pending event was published, false otherwise
   */
  public boolean forcePublishPending(String eventType) {
    EventData data = pendingEvents.get(eventType);
    if (data != null) {
      super.publishEvent(eventType, data);
      lastPublishTime.put(eventType, Long.valueOf(millis()));
      pendingEvents.remove(eventType);
      return true;
    }
    return false;
  }
  
  /**
   * Check if there's a pending event for the given type
   * 
   * @param eventType The event type to check
   * @return True if there's a pending event, false otherwise
   */
  public boolean hasPendingEvent(String eventType) {
    return pendingEvents.containsKey(eventType);
  }
}