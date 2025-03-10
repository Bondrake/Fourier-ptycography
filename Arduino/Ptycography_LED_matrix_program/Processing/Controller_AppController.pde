/**
 * AppController.pde
 * 
 * Main controller for the application.
 * Coordinates between models, views, and hardware.
 * Handles user input and manages application flow.
 */

class AppController extends EventDispatcher implements SerialEventCallback {
  // Parent application
  private PApplet app;
  
  // Models
  private PatternModel patternModel;
  private SystemStateModel stateModel;
  private CameraModel cameraModel;
  
  // Views
  private MatrixView matrixView;
  private StatusPanelView statusView;
  
  // Hardware
  private SerialManager serialManager;
  
  // UI Controls
  private ControlP5 cp5;
  
  /**
   * Constructor
   */
  public AppController(PApplet app) {
    // Store the PApplet reference
    this.app = app;
    
    // Initialize ControlP5 for UI controls if needed
    cp5 = new ControlP5(app);
    
    // Register for events
    registerEvent(EventType.PATTERN_CHANGED);
    registerEvent(EventType.STATE_CHANGED);
    registerEvent(EventType.CAMERA_STATUS_CHANGED);
    registerEvent(EventType.CONFIG_LOADED);
    
    // Note: Models, views and managers are now initialized in the main sketch
    // and provided via setter methods
  }
  
  /**
   * Initialize after all components are set
   */
  public void initialize() {
    // Validate that all required components are set
    if (patternModel == null || stateModel == null || cameraModel == null) {
      println("ERROR: Essential models not set in AppController");
      return;
    }
    
    // Set up callback for serial events
    if (serialManager != null) {
      serialManager.setCallback(this);
    } else {
      println("WARNING: Serial manager not set in AppController");
    }
    
    if (matrixView == null || statusView == null) {
      println("WARNING: Views not set in AppController");
    }
    
    // Load config and apply settings
    loadConfigSettings();
    
    // Configure UI if needed
    // setupUI();
    
    println("AppController initialized successfully");
  }
  
  /**
   * Load and apply settings from configuration
   */
  private void loadConfigSettings() {
    ConfigManager config = getConfigManager();
    
    // Apply pattern settings
    JSONObject patternConfig = config.getPatternConfig();
    patternModel.setPatternType(patternConfig.getInt("patternType", 0));
    patternModel.setInnerRingRadius(patternConfig.getInt("innerRadius", 16));
    patternModel.setMiddleRingRadius(patternConfig.getInt("middleRadius", 24));
    patternModel.setOuterRingRadius(patternConfig.getInt("outerRadius", 31));
    patternModel.setGridSpacing(patternConfig.getInt("ledSkip", 2));
    
    // Apply camera settings
    JSONObject cameraConfig = config.getCameraConfig();
    cameraModel.setEnabled(cameraConfig.getBoolean("enabled", true));
    cameraModel.setPreDelay(cameraConfig.getInt("preDelay", 400));
    cameraModel.setPulseWidth(cameraConfig.getInt("pulseWidth", 100));
    cameraModel.setPostDelay(cameraConfig.getInt("postDelay", 1500));
    
    // Apply simulation mode setting
    stateModel.setSimulationMode(config.getSimulationMode());
  }
  
  /**
   * Set up the UI elements
   */
  private void setupUI() {
    // TODO: Add UI setup code
    // This would create all the ControlP5 elements
  }
  
  /**
   * Draw the interface
   */
  public void draw() {
    // Draw views
    matrixView.draw();
    statusView.draw();
    
    // Handle idle mode
    if (stateModel.isIdle() && stateModel.checkIdleHeartbeat()) {
      triggerIdleHeartbeat();
    }
  }
  
  /**
   * Handle key press events
   */
  public void keyPressed(char key) {
    // Handle keyboard shortcuts
    switch(key) {
      case 'g':
      case 'G':
        // Toggle grid
        matrixView.setShowGrid(!matrixView.isShowGrid());
        break;
        
      case ' ':
        // Toggle pause
        if (stateModel.isRunning()) {
          stateModel.pauseSequence();
        } else if (stateModel.isPaused()) {
          stateModel.startSequence();
        }
        break;
        
      case 'r':
      case 'R':
        // Refresh port list
        serialManager.refreshPortList();
        break;
    }
  }
  
  /**
   * Connect to Arduino hardware
   */
  public boolean connectToHardware(int portIndex) {
    // Set to hardware mode
    stateModel.setSimulationMode(false);
    
    // Connect to the port
    return serialManager.connect(portIndex);
  }
  
  /**
   * Disconnect from Arduino hardware
   */
  public void disconnectFromHardware() {
    serialManager.disconnect();
  }
  
  /**
   * Start simulation mode
   */
  public void startSimulation() {
    stateModel.setSimulationMode(true);
    serialManager.disconnect();
  }
  
  /**
   * Start sequence
   */
  public void startSequence() {
    // Update state model
    stateModel.startSequence();
    
    if (stateModel.isSimulationMode()) {
      // TODO: Add simulation code
    } else {
      // Send command to hardware
      serialManager.startSequence();
    }
  }
  
  /**
   * Stop sequence
   */
  public void stopSequence() {
    // Update state model
    stateModel.stopSequence();
    
    if (!stateModel.isSimulationMode()) {
      // Send command to hardware
      serialManager.stopSequence();
    }
  }
  
  /**
   * Enter idle mode
   */
  public void enterIdleMode() {
    // Update state model
    stateModel.enterIdleMode();
    
    if (!stateModel.isSimulationMode()) {
      // Send command to hardware
      serialManager.enterIdleMode();
    }
  }
  
  /**
   * Exit idle mode
   */
  public void exitIdleMode() {
    // Update state model
    stateModel.exitIdleMode();
    
    if (!stateModel.isSimulationMode()) {
      // Send command to hardware
      serialManager.exitIdleMode();
    }
  }
  
  /**
   * Update pattern type
   */
  public void setPatternType(int type) {
    // Update pattern model
    patternModel.setPatternType(type);
    
    // Send to hardware if connected
    if (!stateModel.isSimulationMode() && serialManager.isConnected()) {
      serialManager.sendPatternType();
      serialManager.sendPatternParameters();
    }
  }
  
  /**
   * Update pattern parameters
   */
  public void updatePatternParameters() {
    // Send parameters to hardware if connected
    if (!stateModel.isSimulationMode() && serialManager.isConnected()) {
      serialManager.sendPatternParameters();
    }
  }
  
  /**
   * Test camera trigger
   */
  public void testCameraTrigger() {
    if (stateModel.isSimulationMode()) {
      // Simulate camera trigger
      cameraModel.simulateTrigger();
    } else if (serialManager.isConnected()) {
      // Send test command to hardware
      serialManager.testCameraTrigger();
    } else {
      println("Cannot test camera: Hardware not connected");
    }
  }
  
  /**
   * Set camera settings
   */
  public void setCameraSettings(boolean enabled, int preDelay, int pulseWidth, int postDelay) {
    // Update camera model
    cameraModel.setEnabled(enabled);
    cameraModel.setPreDelay(preDelay);
    cameraModel.setPulseWidth(pulseWidth);
    cameraModel.setPostDelay(postDelay);
    
    // Send to hardware if connected
    if (!stateModel.isSimulationMode() && serialManager.isConnected()) {
      serialManager.sendCommand(cameraModel.getSettingsCommand(SerialManager.CMD_SET_CAMERA));
    }
  }
  
  /**
   * Trigger idle heartbeat
   * This is called from the main sketch when stateModel.checkIdleHeartbeat() is true
   */
  public void triggerIdleHeartbeat() {
    // In simulation mode, update the state directly
    if (stateModel.isSimulationMode()) {
      // Simulate heartbeat blink
      int centerX = patternModel.getMatrixWidth() / 2;
      int centerY = patternModel.getMatrixHeight() / 2;
      
      // Blink center LED
      stateModel.updateCurrentLed(centerX, centerY, 2);  // Green
      
      // Create thread to turn it off after 500ms
      Thread t = new Thread(new Runnable() {
        public void run() {
          try {
            Thread.sleep(500);
            stateModel.updateCurrentLed(-1, -1, 0);
          } catch (InterruptedException e) {
            e.printStackTrace();
          }
        }
      });
      t.start();
    }
    // In hardware mode, the Arduino handles the heartbeat
  }
  
  /**
   * Serial event callback implementation
   */
  public void onSerialData(String data) {
    // No additional processing needed here
    // SerialManager already updates the models
    
    // Publish event for other components
    publishEvent(EventType.SERIAL_DATA_RECEIVED, new EventData("data", data));
  }
  
  /**
   * Handle incoming events
   */
  @Override
  public void handleEvent(String eventType, EventData data) {
    switch (eventType) {
      case EventType.CONFIG_LOADED:
        // Configuration was loaded, update models
        loadConfigSettings();
        break;
        
      case EventType.PATTERN_CHANGED:
        // Pattern was changed, update configuration and potentially send to hardware
        getConfigManager().updatePatternConfig(patternModel);
        getConfigManager().saveToFile();
        
        if (!stateModel.isSimulationMode() && serialManager.isConnected()) {
          serialManager.sendPatternParameters();
        }
        break;
        
      case EventType.CAMERA_STATUS_CHANGED:
        // Camera status was changed, update configuration
        getConfigManager().updateCameraConfig(cameraModel);
        getConfigManager().saveToFile();
        break;
        
      case EventType.STATE_CHANGED:
        // System state changed, might need to update UI or save settings
        break;
    }
  }
  
  /**
   * Save application settings
   */
  public void saveSettings() {
    // Update all configuration from current models
    ConfigManager config = getConfigManager();
    
    // Update pattern config
    config.updatePatternConfig(patternModel);
    
    // Update camera config
    config.updateCameraConfig(cameraModel);
    
    // Update other settings
    config.setSimulationMode(stateModel.isSimulationMode());
    config.setWindowDimensions(width, height);
    
    // Save to file
    config.saveToFile();
  }
  
  /**
   * Get serial port list
   */
  public String[] getSerialPorts() {
    return serialManager.getAvailablePorts();
  }
  
  /**
   * Setter methods for component references
   */
  public void setPatternModel(PatternModel model) {
    this.patternModel = model;
  }
  
  public void setStateModel(SystemStateModel model) {
    this.stateModel = model;
  }
  
  public void setCameraModel(CameraModel model) {
    this.cameraModel = model;
  }
  
  public void setMatrixView(MatrixView view) {
    this.matrixView = view;
  }
  
  public void setStatusView(StatusPanelView view) {
    this.statusView = view;
  }
  
  public void setSerialManager(SerialManager manager) {
    this.serialManager = manager;
  }
  
  public void setUIManager(UIManager manager) {
    // Store UI manager reference if needed
  }
  
  /**
   * Get models and views for main sketch
   */
  public PatternModel getPatternModel() {
    return patternModel;
  }
  
  public SystemStateModel getStateModel() {
    return stateModel;
  }
  
  public CameraModel getCameraModel() {
    return cameraModel;
  }
  
  public MatrixView getMatrixView() {
    return matrixView;
  }
  
  public StatusPanelView getStatusView() {
    return statusView;
  }
  
  public SerialManager getSerialManager() {
    return serialManager;
  }
  
  public ControlP5 getControlP5() {
    return cp5;
  }
}