/**
 * CameraModel.pde
 * 
 * Encapsulates camera functionality and state.
 * Manages camera settings, trigger status, and error reporting.
 * 
 * This model will be a prime candidate for porting to Rust in the future Tauri migration.
 */

class CameraModel extends EventDispatcher {
  // Camera settings
  private boolean enabled = true;
  private int preDelay = 400;        // Delay before trigger in ms
  private int pulseWidth = 100;      // Trigger pulse width in ms
  private int postDelay = 1500;      // Delay after trigger in ms
  
  // Camera status
  private boolean triggerActive = false;
  private int lastTriggerTime = 0;
  private int errorCode = 0;
  private String errorStatus = "";
  
  // Error code definitions
  public static final int ERROR_NONE = 0;
  public static final int ERROR_TIMEOUT = 1;
  public static final int ERROR_TRIGGER_FAILURE = 2;
  public static final int ERROR_NOT_READY = 3;
  
  /**
   * Constructor with default settings
   */
  public CameraModel() {
    // Use defaults
  }
  
  /**
   * Constructor with specified settings
   */
  public CameraModel(boolean enabled, int preDelay, int pulseWidth, int postDelay) {
    this.enabled = enabled;
    this.preDelay = preDelay;
    this.pulseWidth = pulseWidth;
    this.postDelay = postDelay;
  }
  
  /**
   * Simulate camera trigger (for simulation mode)
   */
  public void simulateTrigger() {
    if (!enabled) return;
    
    // Reset error state
    errorCode = ERROR_NONE;
    errorStatus = "";
    
    // Set trigger active and notify observers
    triggerActive = true;
    lastTriggerTime = millis();
    publishEvent(EventType.CAMERA_STATUS_CHANGED);
    
    // Create a thread to simulate the camera timing sequence
    Thread t = new Thread(new Runnable() {
      public void run() {
        try {
          // Simulate pre-delay
          Thread.sleep(preDelay);
          
          // Simulate trigger active
          Thread.sleep(pulseWidth);
          
          // End of trigger pulse
          triggerActive = false;
          publishEvent(EventType.CAMERA_STATUS_CHANGED);
          
          // Simulate post-delay
          Thread.sleep(postDelay);
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
      }
    });
    t.start();
  }
  
  /**
   * Update camera status from serial data
   */
  public void updateFromSerialData(boolean triggerActive, int errorCode) {
    boolean changed = false;
    
    if (this.triggerActive != triggerActive) {
      this.triggerActive = triggerActive;
      changed = true;
      
      // Update last trigger time when camera becomes active
      if (triggerActive) {
        lastTriggerTime = millis();
      }
    }
    
    if (this.errorCode != errorCode) {
      this.errorCode = errorCode;
      updateErrorStatus();
      changed = true;
    }
    
    if (changed) {
      publishEvent(EventType.CAMERA_STATUS_CHANGED);
    }
  }
  
  /**
   * Update camera status from Arduino status message
   */
  public void updateFromSerialStatus(boolean triggerActive, int errorCode) {
    boolean changed = false;
    
    if (this.triggerActive != triggerActive) {
      this.triggerActive = triggerActive;
      
      if (triggerActive) {
        lastTriggerTime = millis();
      }
      
      changed = true;
    }
    
    if (this.errorCode != errorCode) {
      this.errorCode = errorCode;
      updateErrorStatus();
      changed = true;
    }
    
    if (changed) {
      publishEvent(EventType.CAMERA_STATUS_CHANGED);
    }
  }
  
  /**
   * Update error status text based on error code
   */
  private void updateErrorStatus() {
    // Map error code to human-readable message
    switch (errorCode) {
      case ERROR_NONE:
        errorStatus = "";
        break;
      case ERROR_TIMEOUT:
        errorStatus = "TIMEOUT";
        break;
      case ERROR_TRIGGER_FAILURE:
        errorStatus = "TRIGGER FAILURE";
        break;
      case ERROR_NOT_READY:
        errorStatus = "NOT READY";
        break;
      default:
        errorStatus = "ERROR " + errorCode;
        break;
    }
  }
  
  // Getters and setters
  
  public boolean isEnabled() {
    return enabled;
  }
  
  public void setEnabled(boolean enabled) {
    if (this.enabled != enabled) {
      this.enabled = enabled;
      publishEvent(EventType.CAMERA_STATUS_CHANGED);
    }
  }
  
  public int getPreDelay() {
    return preDelay;
  }
  
  public void setPreDelay(int delay) {
    if (preDelay != delay && delay >= 0) {
      preDelay = delay;
      publishEvent(EventType.CAMERA_STATUS_CHANGED);
    }
  }
  
  public int getPulseWidth() {
    return pulseWidth;
  }
  
  public void setPulseWidth(int width) {
    if (pulseWidth != width && width > 0) {
      pulseWidth = width;
      publishEvent(EventType.CAMERA_STATUS_CHANGED);
    }
  }
  
  public int getPostDelay() {
    return postDelay;
  }
  
  public void setPostDelay(int delay) {
    if (postDelay != delay && delay >= 0) {
      postDelay = delay;
      publishEvent(EventType.CAMERA_STATUS_CHANGED);
    }
  }
  
  public boolean isTriggerActive() {
    return triggerActive;
  }
  
  public int getLastTriggerTime() {
    return lastTriggerTime;
  }
  
  public int getTimeSinceLastTrigger() {
    if (lastTriggerTime == 0) return -1;
    return millis() - lastTriggerTime;
  }
  
  public int getErrorCode() {
    return errorCode;
  }
  
  public String getErrorStatus() {
    return errorStatus;
  }
  
  public boolean hasError() {
    return errorCode != ERROR_NONE;
  }
  
  public void clearError() {
    if (errorCode != ERROR_NONE) {
      errorCode = ERROR_NONE;
      errorStatus = "";
      publishEvent(EventType.CAMERA_STATUS_CHANGED);
    }
  }
  
  /**
   * Get settings as a formatted string for Arduino command
   */
  public String getSettingsCommand(char commandChar) {
    return commandChar + 
           "S," +  // S for settings
           (enabled ? "1" : "0") + "," +
           preDelay + "," +
           pulseWidth + "," +
           postDelay;
  }
  
  /**
   * Get test trigger command for Arduino
   */
  public String getTestCommand(char commandChar) {
    return commandChar + 
           "T," + // T for test
           (enabled ? "1" : "0") + "," +
           pulseWidth;
  }
}

// Using EventSystem instead of observer pattern