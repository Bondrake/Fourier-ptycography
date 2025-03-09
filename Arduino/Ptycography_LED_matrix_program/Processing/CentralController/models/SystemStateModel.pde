/**
 * SystemStateModel.pde
 * 
 * Manages the overall system state including running/idle status,
 * simulation mode, and hardware connection status.
 * 
 * This model centralizes state management that was previously
 * scattered across the application.
 */

class SystemStateModel {
  // State enums
  public enum RunState {
    STOPPED,
    RUNNING,
    PAUSED
  }
  
  // System states
  private RunState runState = RunState.STOPPED;
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
  
  // Observer pattern
  private ArrayList<StateObserver> observers = new ArrayList<StateObserver>();
  
  /**
   * Constructor
   */
  public SystemStateModel() {
    // Nothing needed here
  }
  
  /**
   * Add observer for state changes
   */
  public void addObserver(StateObserver observer) {
    observers.add(observer);
  }
  
  /**
   * Notify observers of state changes
   */
  private void notifyObservers() {
    for (StateObserver observer : observers) {
      observer.onStateChanged();
    }
  }
  
  /**
   * Start or resume the illumination sequence
   */
  public void startSequence() {
    if (runState == RunState.STOPPED) {
      // Start from beginning
      sequenceIndex = 0;
    }
    
    runState = RunState.RUNNING;
    idleMode = false;
    notifyObservers();
  }
  
  /**
   * Pause the illumination sequence
   */
  public void pauseSequence() {
    if (runState == RunState.RUNNING) {
      runState = RunState.PAUSED;
      notifyObservers();
    }
  }
  
  /**
   * Stop the illumination sequence
   */
  public void stopSequence() {
    runState = RunState.STOPPED;
    sequenceIndex = 0;
    currentLedX = -1;
    currentLedY = -1;
    notifyObservers();
  }
  
  /**
   * Enter idle mode
   */
  public void enterIdleMode() {
    idleMode = true;
    runState = RunState.STOPPED;
    lastBlinkTime = millis();
    currentLedX = -1;
    currentLedY = -1;
    notifyObservers();
  }
  
  /**
   * Exit idle mode
   */
  public void exitIdleMode() {
    idleMode = false;
    currentLedX = -1;
    currentLedY = -1;
    notifyObservers();
  }
  
  /**
   * Update state from Arduino status message
   */
  public void updateFromSerialStatus(boolean running, boolean idle, float progress) {
    boolean changed = false;
    
    // Update run state
    RunState newRunState = running ? RunState.RUNNING : RunState.STOPPED;
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
      notifyObservers();
    }
  }
  
  /**
   * Update current LED position
   */
  public void updateCurrentLed(int x, int y, int color) {
    boolean changed = false;
    
    if (currentLedX != x || currentLedY != y || currentColor != color) {
      currentLedX = x;
      currentLedY = y;
      currentColor = color;
      changed = true;
    }
    
    if (changed) {
      notifyObservers();
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
      
      notifyObservers();
    }
  }
  
  /**
   * Set hardware connected state
   */
  public void setHardwareConnected(boolean connected) {
    if (hardwareConnected != connected) {
      hardwareConnected = connected;
      notifyObservers();
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
      notifyObservers();
    }
  }
  
  // Getters
  
  public RunState getRunState() {
    return runState;
  }
  
  public boolean isRunning() {
    return runState == RunState.RUNNING;
  }
  
  public boolean isPaused() {
    return runState == RunState.PAUSED;
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
 * Observer interface for state changes
 */
interface StateObserver {
  void onStateChanged();
}