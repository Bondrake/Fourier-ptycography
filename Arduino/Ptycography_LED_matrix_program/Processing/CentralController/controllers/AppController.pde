/**
 * AppController.pde
 * 
 * Main controller for the application.
 * Coordinates between models, views, and hardware.
 * Handles user input and manages application flow.
 */

class AppController implements SerialEventCallback {
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
    // Create models
    patternModel = new PatternModel(64, 64);
    stateModel = new SystemStateModel();
    cameraModel = new CameraModel();
    
    // Create hardware manager
    serialManager = new SerialManager(stateModel, patternModel, cameraModel);
    serialManager.setCallback(this);
    
    // Create UI Controls
    cp5 = new ControlP5(app);
    
    // Create views
    matrixView = new MatrixView(patternModel, stateModel, cameraModel, 
                               330, 50, 8);
    statusView = new StatusPanelView(patternModel, stateModel, cameraModel,
                                    0, 50, 330);
    
    // Configure UI
    setupUI();
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
   */
  private void triggerIdleHeartbeat() {
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
  }
  
  /**
   * Get serial port list
   */
  public String[] getSerialPorts() {
    return serialManager.getAvailablePorts();
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