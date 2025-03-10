/**
 * EventSystem.pde
 * 
 * A complete event system for component communication in the Ptycography application.
 * Implements a publisher-subscriber pattern for decoupled communication.
 * 
 * This system allows components to register for events and publish events
 * without needing to know about each other directly, promoting loose coupling.
 * 
 * Key Components:
 * - EventType: Constants defining the supported event types
 * - EventData: Container for data passed with events
 * - EventHandler: Interface for components that handle events
 * - EventBus: Central hub for event publication and subscription
 * - EventDispatcher: Base class to simplify event handling for components
 * - ThrottledEventDispatcher: Extension that limits event frequency
 * 
 * @see EVENT_FLOW.md for comprehensive documentation of event flow
 */

/**
 * EventType class defines all events used in the application.
 * 
 * This class contains constants for all event types to ensure consistent
 * event naming throughout the application. Events are organized into
 * categories (system events, UI events, configuration events).
 * 
 * When adding new events:
 * 1. Add a constant here with clear, descriptive name
 * 2. Use snake_case for event type names
 * 3. Update EVENT_FLOW.md documentation
 * 4. Consider if the event needs throttling
 */
static final class EventType {
  /**
   * System events relate to core application functionality
   */
  
  /** Triggered when the pattern configuration changes */
  public static final String PATTERN_CHANGED = "pattern_changed";
  
  /** Triggered when system state (running, paused, idle) changes */
  public static final String STATE_CHANGED = "state_changed";
  
  /** Triggered when camera is enabled/disabled or status changes */
  public static final String CAMERA_STATUS_CHANGED = "camera_status_changed";
  
  /** Triggered when camera settings (delays, pulse width) change */
  public static final String CAMERA_SETTINGS_CHANGED = "camera_settings_changed";
  
  /** Triggered when hardware connection is established */
  public static final String HARDWARE_CONNECTED = "hardware_connected";
  
  /** Triggered when hardware connection is lost */
  public static final String HARDWARE_DISCONNECTED = "hardware_disconnected";
  
  /** Triggered when data is received from serial port */
  public static final String SERIAL_DATA_RECEIVED = "serial_data_received";
  
  /** Triggered when available serial ports change */
  public static final String SERIAL_PORTS_CHANGED = "serial_ports_changed";
  
  /** Triggered when successfully connected to serial port */
  public static final String SERIAL_CONNECTED = "serial_connected";
  
  /** Triggered when disconnected from serial port */
  public static final String SERIAL_DISCONNECTED = "serial_disconnected";
  
  /**
   * UI events relate to user interface updates
   */
  
  /** Triggered to request UI refresh */
  public static final String REFRESH_UI = "refresh_ui";
  
  /** Triggered when UI size changes */
  public static final String UI_SIZE_CHANGED = "ui_size_changed";
  
  /**
   * Configuration events relate to loading/saving settings
   */
  
  /** Triggered when configuration is loaded */
  public static final String CONFIG_LOADED = "config_loaded";
  
  /** Triggered when configuration is saved */
  public static final String CONFIG_SAVED = "config_saved";
}

/**
 * EventData class for passing data with events.
 * 
 * This class provides a flexible key-value store for attaching data to events.
 * It supports various data types and provides type-safe accessors for common types.
 * 
 * Usage example:
 * ```
 * EventData data = new EventData("count", 5)
 *                    .put("name", "example")
 *                    .put("active", true);
 * ```
 */
class EventData {
  /** Internal storage for key-value pairs */
  private HashMap<String, Object> data;
  
  /**
   * Create an empty EventData object
   */
  public EventData() {
    data = new HashMap<String, Object>();
  }
  
  /**
   * Create an EventData object with a single key-value pair
   * 
   * @param key The key for the data
   * @param value The value to store
   */
  public EventData(String key, Object value) {
    this();
    put(key, value);
  }
  
  /**
   * Add a key-value pair to the event data
   * 
   * @param key The key for the data
   * @param value The value to store
   * @return This EventData instance for method chaining
   */
  public EventData put(String key, Object value) {
    data.put(key, value);
    return this;
  }
  
  /**
   * Get a value from the event data
   * 
   * @param key The key to look up
   * @return The value associated with the key, or null if not found
   */
  public Object get(String key) {
    return data.get(key);
  }
  
  /**
   * Check if the event data contains a specific key
   * 
   * @param key The key to check
   * @return True if the key exists, false otherwise
   */
  public boolean hasKey(String key) {
    return data.containsKey(key);
  }
  
  /**
   * Get a string value from the event data
   * 
   * @param key The key to look up
   * @param defaultValue The default value to return if key not found or value is not a String
   * @return The String value or defaultValue
   */
  public String getString(String key, String defaultValue) {
    Object value = get(key);
    return (value instanceof String) ? (String)value : defaultValue;
  }
  
  /**
   * Get an integer value from the event data
   * 
   * @param key The key to look up
   * @param defaultValue The default value to return if key not found or value is not an Integer
   * @return The int value or defaultValue
   */
  public int getInt(String key, int defaultValue) {
    Object value = get(key);
    return (value instanceof Integer) ? (Integer)value : defaultValue;
  }
  
  /**
   * Get a float value from the event data
   * 
   * @param key The key to look up
   * @param defaultValue The default value to return if key not found or value is not a Float
   * @return The float value or defaultValue
   */
  public float getFloat(String key, float defaultValue) {
    Object value = get(key);
    return (value instanceof Float) ? (Float)value : defaultValue;
  }
  
  /**
   * Get a boolean value from the event data
   * 
   * @param key The key to look up
   * @param defaultValue The default value to return if key not found or value is not a Boolean
   * @return The boolean value or defaultValue
   */
  public boolean getBoolean(String key, boolean defaultValue) {
    Object value = get(key);
    return (value instanceof Boolean) ? (Boolean)value : defaultValue;
  }
}

/**
 * EventHandler interface defines the contract for objects that can handle events.
 * 
 * Any class that wants to receive events must implement this interface.
 * The EventDispatcher class implements this interface to make event handling easier.
 */
interface EventHandler {
  /**
   * Handle an incoming event
   * 
   * @param eventType The type of event being handled (from EventType constants)
   * @param data The data associated with the event
   */
  void handleEvent(String eventType, EventData data);
}

/**
 * EventBus is the central hub for event publication and subscription.
 * 
 * This class maintains a registry of event handlers and routes events to
 * the appropriate subscribers. It's implemented as a singleton to ensure
 * a single, application-wide event bus.
 * 
 * Due to Processing's limitations with static methods, we use a global function
 * and variable to implement the singleton pattern.
 */

/** Singleton instance - must be outside the class for Processing compatibility */
EventBus eventBusInstance = null;

/**
 * Global function to get the EventBus singleton instance.
 * 
 * @return The singleton EventBus instance
 */
EventBus getEventBus() {
  if (eventBusInstance == null) {
    eventBusInstance = new EventBus();
  }
  return eventBusInstance;
}

/**
 * EventBus class manages event subscriptions and event publishing.
 */
class EventBus {
  /** Map of event types to their subscribers */
  private HashMap<String, ArrayList<EventHandler>> subscribers;
  
  /**
   * Private constructor (singleton pattern)
   */
  private EventBus() {
    subscribers = new HashMap<String, ArrayList<EventHandler>>();
  }
  
  /**
   * Instance getter (non-static for Processing compatibility)
   * Use the global getEventBus() function instead
   * 
   * @return The singleton EventBus instance
   */
  public EventBus getInstance() {
    return getEventBus();
  }
  
  /**
   * Subscribe to an event
   * 
   * @param eventType The event type to subscribe to
   * @param handler The handler to receive notifications
   */
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
  
  /**
   * Unsubscribe from an event
   * 
   * @param eventType The event type to unsubscribe from
   * @param handler The handler to remove
   */
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
  
  /**
   * Publish an event without data
   * 
   * @param eventType The event type to publish
   */
  public void publish(String eventType) {
    publish(eventType, new EventData());
  }
  
  /**
   * Publish an event with data
   * 
   * @param eventType The event type to publish
   * @param data The data to include with the event
   */
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
  
  /**
   * Check if there are any subscribers for an event type
   * 
   * @param eventType The event type to check
   * @return True if there are subscribers, false otherwise
   */
  public boolean hasSubscribers(String eventType) {
    ArrayList<EventHandler> handlers = subscribers.get(eventType);
    return handlers != null && !handlers.isEmpty();
  }
  
  /**
   * Clear all subscribers
   * Useful for cleanup or testing
   */
  public void clear() {
    subscribers.clear();
  }
}

/**
 * EventDispatcher is a base class that simplifies event handling for components.
 * 
 * This class implements the EventHandler interface and provides convenient methods
 * for registering, unregistering, and publishing events. Components should
 * extend this class to easily participate in the event system.
 * 
 * Usage example:
 * ```
 * class MyComponent extends EventDispatcher {
 *   public MyComponent() {
 *     // Register for events
 *     registerEvent(EventType.STATE_CHANGED);
 *     registerEvent(EventType.CONFIG_LOADED);
 *   }
 *   
 *   @Override
 *   public void handleEvent(String eventType, EventData data) {
 *     if (eventType.equals(EventType.STATE_CHANGED)) {
 *       // Handle state change
 *     }
 *   }
 *   
 *   public void doSomething() {
 *     // Publish an event
 *     publishEvent(EventType.PATTERN_CHANGED);
 *   }
 * }
 * ```
 */
class EventDispatcher implements EventHandler {
  /**
   * Register to receive notifications for an event type
   * 
   * @param eventType The event type to register for
   */
  protected void registerEvent(String eventType) {
    getEventBus().subscribe(eventType, this);
  }
  
  /**
   * Unregister from receiving notifications for an event type
   * 
   * @param eventType The event type to unregister from
   */
  protected void unregisterEvent(String eventType) {
    getEventBus().unsubscribe(eventType, this);
  }
  
  /**
   * Publish an event without data
   * 
   * @param eventType The event type to publish
   */
  protected void publishEvent(String eventType) {
    getEventBus().publish(eventType);
  }
  
  /**
   * Publish an event with data
   * 
   * @param eventType The event type to publish
   * @param data The data to include with the event
   */
  protected void publishEvent(String eventType, EventData data) {
    getEventBus().publish(eventType, data);
  }
  
  /**
   * Handle incoming events (to be overridden by subclasses)
   * 
   * @param eventType The type of event being handled
   * @param data The data associated with the event
   */
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
 * 
 * @see ThrottledSystemStateModel For an example implementation
 * @see EVENT_FLOW.md For information about throttled events in the application
 */

/**
 * ThrottledEventDispatcher extends EventDispatcher to add event throttling.
 * 
 * This class limits how frequently events can be published to prevent
 * performance issues with rapidly firing events. It stores pending events
 * and publishes them once their throttle interval has passed.
 * 
 * This is particularly useful for events that might be triggered many times
 * in rapid succession, such as:
 * - UI interactions (mouse movements, slider adjustments)
 * - Hardware status updates
 * - Animation frame updates
 * 
 * Usage example:
 * ```
 * ThrottledEventDispatcher dispatcher = new ThrottledEventDispatcher();
 * dispatcher.setThrottleInterval(EventType.STATE_CHANGED, 50); // 50ms throttle
 * registerThrottledDispatcher(dispatcher); // Register with central controller
 * ```
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