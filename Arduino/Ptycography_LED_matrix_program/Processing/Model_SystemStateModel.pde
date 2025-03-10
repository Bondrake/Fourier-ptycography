/**
 * SystemStateModel.pde
 * 
 * Manages the overall system state including running/idle status,
 * simulation mode, and hardware connection status.
 * 
 * This model centralizes state management that was previously
 * scattered across the application.
 */

class SystemStateModel extends EventDispatcher {
  // State constants
  public static final int STOPPED = 0;
  public static final int RUNNING = 1;
  public static final int PAUSED = 2;
  
  // System states
  private int runState = STOPPED;
  private boolean idleMode = false;
  private boolean simulationMode = true;  // Default to simulation mode
  private boolean hardwareConnected = false;
  
  // Sequence tracking
  private int sequenceIndex = 0;
  private int sequenceLength = 0;
  
  // Current LED tracking
  private int currentLedX = -1;
  private int currentLedY = -1;
  private int currentColor = 0;
  
  // Idle mode timing
  private int lastBlinkTime = 0;
  private int idleBlinkInterval = 60000;  // 1 minute between blinks
  
  /**
   * Constructor
   */
  public SystemStateModel() {
    // Nothing needed here
  }
  
  /**
   * Start or resume the illumination sequence
   */
  public void startSequence() {
    if (runState == STOPPED) {
      // Start from beginning
      sequenceIndex = 0;
    }
    
    runState = RUNNING;
    idleMode = false;
    publishEvent(EventType.STATE_CHANGED);
  }
  
  /**
   * Pause the illumination sequence
   */
  public void pauseSequence() {
    if (runState == RUNNING) {
      runState = PAUSED;
      publishEvent(EventType.STATE_CHANGED);
    }
  }
  
  /**
   * Stop the illumination sequence
   */
  public void stopSequence() {
    runState = STOPPED;
    sequenceIndex = 0;
    currentLedX = -1;
    currentLedY = -1;
    publishEvent(EventType.STATE_CHANGED);
  }
  
  /**
   * Enter idle mode
   */
  public void enterIdleMode() {
    idleMode = true;
    runState = STOPPED;
    lastBlinkTime = millis();
    currentLedX = -1;
    currentLedY = -1;
    publishEvent(EventType.STATE_CHANGED);
  }
  
  /**
   * Exit idle mode
   */
  public void exitIdleMode() {
    idleMode = false;
    currentLedX = -1;
    currentLedY = -1;
    publishEvent(EventType.STATE_CHANGED);
  }
  
  /**
   * Update state from Arduino status message
   */
  public void updateFromSerialStatus(boolean running, boolean idle, float progress) {
    boolean changed = false;
    
    // Update run state
    int newRunState = running ? RUNNING : STOPPED;
    if (runState != newRunState) {
      runState = newRunState;
      changed = true;
    }
    
    // Update idle mode
    if (idleMode != idle) {
      idleMode = idle;
      changed = true;
      
      if (idle) {
        lastBlinkTime = millis();
      }
    }
    
    // Update sequence progress
    int newIndex = (int)(progress * sequenceLength);
    if (sequenceIndex != newIndex) {
      sequenceIndex = newIndex;
      changed = true;
    }
    
    if (changed) {
      publishEvent(EventType.STATE_CHANGED);
    }
  }
  
  /**
   * Update current LED position
   */
  public void updateCurrentLed(int x, int y, int ledColor) {
    boolean changed = false;
    
    if (currentLedX != x || currentLedY != y || currentColor != ledColor) {
      currentLedX = x;
      currentLedY = y;
      currentColor = ledColor;
      changed = true;
    }
    
    if (changed) {
      publishEvent(EventType.STATE_CHANGED);
    }
  }
  
  /**
   * Check if it's time for idle heartbeat
   */
  public boolean checkIdleHeartbeat() {
    if (idleMode && millis() - lastBlinkTime >= idleBlinkInterval) {
      lastBlinkTime = millis();
      return true;
    }
    return false;
  }
  
  /**
   * Set simulation mode
   */
  public void setSimulationMode(boolean simulationMode) {
    if (this.simulationMode != simulationMode) {
      this.simulationMode = simulationMode;
      
      // Reset hardware connection in simulation mode
      if (simulationMode) {
        hardwareConnected = false;
      }
      
      publishEvent(EventType.STATE_CHANGED);
    }
  }
  
  /**
   * Set hardware connected state
   */
  public void setHardwareConnected(boolean connected) {
    if (hardwareConnected != connected) {
      hardwareConnected = connected;
      publishEvent(EventType.STATE_CHANGED);
    }
  }
  
  /**
   * Set sequence parameters
   */
  public void setSequenceInfo(int index, int length) {
    boolean changed = false;
    
    if (sequenceIndex != index) {
      sequenceIndex = index;
      changed = true;
    }
    
    if (sequenceLength != length) {
      sequenceLength = length;
      changed = true;
    }
    
    if (changed) {
      publishEvent(EventType.STATE_CHANGED);
    }
  }
  
  // Getters
  
  public int getRunState() {
    return runState;
  }
  
  public boolean isRunning() {
    return runState == RUNNING;
  }
  
  public boolean isPaused() {
    return runState == PAUSED;
  }
  
  public boolean isIdle() {
    return idleMode;
  }
  
  public boolean isSimulationMode() {
    return simulationMode;
  }
  
  public boolean isHardwareConnected() {
    return hardwareConnected;
  }
  
  public int getSequenceIndex() {
    return sequenceIndex;
  }
  
  public int getSequenceLength() {
    return sequenceLength;
  }
  
  public float getSequenceProgress() {
    if (sequenceLength <= 0) return 0;
    return (float)sequenceIndex / sequenceLength;
  }
  
  public int getCurrentLedX() {
    return currentLedX;
  }
  
  public int getCurrentLedY() {
    return currentLedY;
  }
  
  public int getCurrentColor() {
    return currentColor;
  }
  
  public boolean hasCurrentLed() {
    return currentLedX >= 0 && currentLedY >= 0;
  }
}

/**
 * Throttled version of SystemStateModel that limits how frequently 
 * state change events are published to prevent overwhelming subscribers.
 * Particularly useful for rapid LED updates during sequence execution.
 */
class ThrottledSystemStateModel extends SystemStateModel {
  // Internal throttled event dispatcher
  private ThrottledEventDispatcher throttledDispatcher;
  
  /**
   * Constructor
   * 
   * @param stateChangeInterval The throttle interval for state change events in ms (default: 100ms)
   */
  public ThrottledSystemStateModel(int stateChangeInterval) {
    super();
    // Create the throttled dispatcher
    throttledDispatcher = new ThrottledEventDispatcher();
    // Set the interval for state changed events
    throttledDispatcher.setThrottleInterval(EventType.STATE_CHANGED, stateChangeInterval);
    
    // Register the dispatcher with the main controller
    if (throttledDispatchers != null) {
      registerThrottledDispatcher(throttledDispatcher);
    }
  }
  
  /**
   * Constructor with default throttle interval of 100ms
   */
  public ThrottledSystemStateModel() {
    this(100); // Default to 100ms throttling
  }
  
  /**
   * Override publishEvent to use throttled dispatcher for state changes
   */
  @Override
  protected void publishEvent(String eventType) {
    publishEvent(eventType, new EventData());
  }
  
  /**
   * Override publishEvent to use throttled dispatcher for state changes
   */
  @Override
  protected void publishEvent(String eventType, EventData data) {
    if (eventType.equals(EventType.STATE_CHANGED)) {
      // Use throttled publishing for state change events
      throttledDispatcher.publishEvent(eventType, data);
    } else {
      // Use regular publishing for other event types
      super.publishEvent(eventType, data);
    }
  }
  
  /**
   * Set throttle interval for state change events
   * 
   * @param interval Throttle interval in milliseconds
   */
  public void setStateChangeThrottleInterval(int interval) {
    throttledDispatcher.setThrottleInterval(EventType.STATE_CHANGED, interval);
  }
  
  /**
   * Force immediate publication of any pending state change events
   */
  public void forcePublishStateChange() {
    throttledDispatcher.forcePublishPending(EventType.STATE_CHANGED);
  }
}

// Using EventSystem instead of observer pattern