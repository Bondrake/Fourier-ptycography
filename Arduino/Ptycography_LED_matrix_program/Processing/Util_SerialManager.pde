/**
 * SerialManager.pde
 * 
 * Manages serial communication with the Arduino hardware.
 * Abstracts the communication protocol and command formatting.
 */

interface SerialEventCallback {
  void onSerialData(String data);
}

class SerialManager extends EventDispatcher {
  // Command codes for Arduino communication
  public static final char CMD_SET_PATTERN = 'P';     // Set pattern type
  public static final char CMD_SET_INNER_RADIUS = 'I';  // Set inner ring radius
  public static final char CMD_SET_MIDDLE_RADIUS = 'M'; // Set middle ring radius
  public static final char CMD_SET_OUTER_RADIUS = 'O';  // Set outer ring radius
  public static final char CMD_SET_SPACING = 'S';      // Set LED spacing
  public static final char CMD_START_SEQUENCE = 'R';   // Run sequence
  public static final char CMD_STOP_SEQUENCE = 'X';    // Stop sequence
  public static final char CMD_ENTER_IDLE = 'i';       // Enter idle mode
  public static final char CMD_EXIT_IDLE = 'a';        // Exit idle mode
  public static final char CMD_SET_LED = 'L';          // Set specific LED
  public static final char CMD_SET_CAMERA = 'C';       // Set camera trigger settings
  
  // Serial port connection
  private Serial arduinoPort;
  private boolean connected = false;
  private String[] availablePorts;
  
  // Referenced models
  private SystemStateModel stateModel;
  private PatternModel patternModel;
  private CameraModel cameraModel;
  
  // Callback for serial events
  private SerialEventCallback callback;
  
  /**
   * Constructor
   */
  public SerialManager(SystemStateModel stateModel, PatternModel patternModel, CameraModel cameraModel) {
    this.stateModel = stateModel;
    this.patternModel = patternModel;
    this.cameraModel = cameraModel;
    
    // Initialize with available ports
    refreshPortList();
  }
  
  /**
   * Refresh the list of available serial ports
   */
  public void refreshPortList() {
    availablePorts = Serial.list();
    publishEvent(EventType.SERIAL_PORTS_CHANGED, new EventData("ports", availablePorts));
  }
  
  /**
   * Connect to a specific port
   */
  public boolean connect(int portIndex) {
    if (portIndex < 0 || portIndex >= availablePorts.length) {
      println("Invalid port index: " + portIndex);
      return false;
    }
    
    // Disconnect if already connected
    if (connected) {
      disconnect();
    }
    
    try {
      // Connect to the selected port
      arduinoPort = new Serial(getPApplet(), availablePorts[portIndex], 9600);
      arduinoPort.bufferUntil('\n');
      connected = true;
      
      // Update status
      stateModel.setHardwareConnected(true);
      
      println("Connected to hardware on port: " + availablePorts[portIndex]);
      publishEvent(EventType.SERIAL_CONNECTED);
      
      return true;
    } catch (Exception e) {
      println("Error connecting to hardware: " + e.getMessage());
      connected = false;
      stateModel.setHardwareConnected(false);
      return false;
    }
  }
  
  /**
   * Disconnect from serial port
   */
  public void disconnect() {
    if (arduinoPort != null) {
      arduinoPort.stop();
      arduinoPort = null;
    }
    connected = false;
    stateModel.setHardwareConnected(false);
    publishEvent(EventType.SERIAL_DISCONNECTED);
  }
  
  /**
   * Process serial data from the Arduino
   */
  public void processSerialEvent(Serial port) {
    if (port != arduinoPort) return;
    
    String data = port.readStringUntil('\n');
    if (data != null) {
      data = data.trim();
      println("Received from Arduino: " + data);
      
      // Notify callback
      if (callback != null) {
        callback.onSerialData(data);
      }
      
      // Parse data based on protocol
      parseArduinoData(data);
    }
  }
  
  /**
   * Parse data received from Arduino
   */
  private void parseArduinoData(String data) {
    if (data.startsWith("LED,")) {
      // Format: LED,x,y,color
      parseArduinoLedData(data);
    } else if (data.startsWith("STATUS,")) {
      // Format: STATUS,running,idle,progress,sequence_length
      parseArduinoStatusData(data);
    } else if (data.startsWith("CAMERA,")) {
      // Format: CAMERA,triggerActive,errorCode
      parseArduinoCameraData(data);
    }
  }
  
  /**
   * Parse LED data from Arduino
   * Format: LED,x,y,color
   */
  private void parseArduinoLedData(String data) {
    String[] parts = data.substring(4).split(",");
    if (parts.length >= 3) {
      try {
        int x = Integer.parseInt(parts[0]);
        int y = Integer.parseInt(parts[1]);
        int colorValue = Integer.parseInt(parts[2]);
        
        // Update status model
        stateModel.updateCurrentLed(x, y, colorValue);
      } catch (Exception e) {
        println("Error parsing LED data: " + e.getMessage());
      }
    }
  }
  
  /**
   * Parse status data from Arduino
   * Format: STATUS,running,idle,progress,cameraEnabled,cameraTriggerActive,cameraErrorCode
   */
  private void parseArduinoStatusData(String data) {
    String[] parts = data.substring(7).split(",");
    if (parts.length >= 3) {
      try {
        boolean running = parts[0].equals("1");
        boolean idle = parts[1].equals("1");
        float progress = Float.parseFloat(parts[2]);
        
        // Update system state
        stateModel.updateFromSerialStatus(running, idle, progress);
        
        // Process additional camera status if available
        if (parts.length >= 4) {
          boolean cameraEnabled = parts[3].equals("1");
          cameraModel.setEnabled(cameraEnabled);
        }
        
        if (parts.length >= 6) {
          boolean cameraTriggerActive = parts[4].equals("1");
          int cameraErrorCode = Integer.parseInt(parts[5]);
          
          // Update camera model
          cameraModel.updateFromSerialStatus(cameraTriggerActive, cameraErrorCode);
        }
      } catch (Exception e) {
        println("Error parsing status data: " + e.getMessage());
      }
    }
  }
  
  /**
   * Parse camera data from Arduino
   * Format: CAMERA,triggerActive,errorCode
   */
  private void parseArduinoCameraData(String data) {
    String[] parts = data.substring(7).split(",");
    if (parts.length >= 2) {
      try {
        boolean triggerActive = parts[0].equals("1");
        int errorCode = Integer.parseInt(parts[1]);
        
        // Update camera model
        cameraModel.updateFromSerialStatus(triggerActive, errorCode);
      } catch (Exception e) {
        println("Error parsing camera data: " + e.getMessage());
      }
    }
  }
  
  /**
   * Send a raw command to the Arduino
   */
  public void sendCommand(String command) {
    if (!connected || arduinoPort == null) return;
    
    arduinoPort.write(command + "\n");
    println("Sent to Arduino: " + command);
  }
  
  /**
   * Send current pattern type to Arduino
   */
  public void sendPatternType() {
    if (!connected) return;
    
    // Send pattern type command: P<type>
    String command = CMD_SET_PATTERN + String.valueOf(patternModel.getPatternType());
    sendCommand(command);
  }
  
  /**
   * Send pattern parameters to Arduino based on current pattern
   */
  public void sendPatternParameters() {
    if (!connected) return;
    
    // Send parameters based on pattern type
    switch (patternModel.getPatternType()) {
      case PatternModel.PATTERN_CONCENTRIC_RINGS:
        // Send ring radii for concentric rings pattern
        sendCommand(CMD_SET_INNER_RADIUS + String.valueOf(patternModel.getInnerRingRadius()));
        sendCommand(CMD_SET_MIDDLE_RADIUS + String.valueOf(patternModel.getMiddleRingRadius()));
        sendCommand(CMD_SET_OUTER_RADIUS + String.valueOf(patternModel.getOuterRingRadius()));
        break;
        
      case PatternModel.PATTERN_SPIRAL:
        // Send spiral parameters
        sendCommand(CMD_SET_INNER_RADIUS + String.valueOf(patternModel.getSpiralMaxRadius()));
        sendCommand(CMD_SET_MIDDLE_RADIUS + String.valueOf(patternModel.getSpiralTurns()));
        break;
        
      case PatternModel.PATTERN_GRID:
        // Send grid parameters
        sendCommand(CMD_SET_INNER_RADIUS + String.valueOf(patternModel.getGridSpacing()));
        sendCommand(CMD_SET_MIDDLE_RADIUS + String.valueOf(patternModel.getGridPointSize()));
        
        // Send X and Y offsets as a combined parameter
        int combinedOffset = (patternModel.getGridOffsetX() * 10) + patternModel.getGridOffsetY();
        sendCommand(CMD_SET_OUTER_RADIUS + String.valueOf(combinedOffset));
        break;
        
      case PatternModel.PATTERN_CENTER_ONLY:
        // No parameters for center only
        break;
    }
    
    // Send common parameters
    sendCommand(CMD_SET_SPACING + String.valueOf(patternModel.getGridSpacing()));
    
    // Send camera settings
    sendCameraSettings();
  }
  
  /**
   * Send camera settings to Arduino
   */
  public void sendCameraSettings() {
    if (!connected) return;
    
    // Format camera settings command
    String command = CMD_SET_CAMERA + 
                   "S," +  // S for settings
                   (cameraModel.isEnabled() ? "1" : "0") + "," +
                   cameraModel.getPreDelay() + "," +
                   cameraModel.getPulseWidth() + "," +
                   cameraModel.getPostDelay();
    
    sendCommand(command);
  }
  
  /**
   * Test camera trigger
   */
  public void testCameraTrigger() {
    if (!connected) return;
    
    // Send test trigger command
    String command = CMD_SET_CAMERA + 
                 "T," + // T for test
                 (cameraModel.isEnabled() ? "1" : "0") + "," +
                 cameraModel.getPulseWidth();
    
    sendCommand(command);
  }
  
  /**
   * Send a command to start the sequence
   */
  public void startSequence() {
    if (!connected) return;
    sendCommand(String.valueOf(CMD_START_SEQUENCE));
  }
  
  /**
   * Send a command to stop the sequence
   */
  public void stopSequence() {
    if (!connected) return;
    sendCommand(String.valueOf(CMD_STOP_SEQUENCE));
  }
  
  /**
   * Send a command to enter idle mode
   */
  public void enterIdleMode() {
    if (!connected) return;
    sendCommand(String.valueOf(CMD_ENTER_IDLE));
  }
  
  /**
   * Send a command to exit idle mode
   */
  public void exitIdleMode() {
    if (!connected) return;
    sendCommand(String.valueOf(CMD_EXIT_IDLE));
  }
  
  /**
   * Set callback for serial events
   */
  public void setCallback(SerialEventCallback callback) {
    this.callback = callback;
  }
  
  /**
   * Get the list of available ports
   */
  public String[] getAvailablePorts() {
    return availablePorts;
  }
  
  /**
   * Check if we're connected to hardware
   */
  public boolean isConnected() {
    return connected;
  }
  
  /**
   * Get the parent PApplet instance
   */
  private PApplet getPApplet() {
    // Get the parent PApplet from Processing's built-in global variable
    return g.parent;
  }
}