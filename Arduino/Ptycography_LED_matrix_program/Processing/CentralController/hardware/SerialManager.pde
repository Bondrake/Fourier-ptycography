/**
 * SerialManager.pde
 * 
 * Manages serial communication with the Arduino hardware.
 * Handles command sending and response parsing.
 * 
 * This module would be replaced with Rust code in a Tauri migration.
 */

import processing.serial.*;

class SerialManager {
  // Serial connection
  private Serial arduinoPort;
  private String[] availablePorts;
  private int selectedPortIndex = -1;
  private String portName = "";
  private boolean connected = false;
  
  // Command codes
  public static final char CMD_SET_PATTERN = 'P';      // Set pattern type
  public static final char CMD_SET_INNER_RADIUS = 'I'; // Set inner ring radius
  public static final char CMD_SET_MIDDLE_RADIUS = 'M';// Set middle ring radius
  public static final char CMD_SET_OUTER_RADIUS = 'O'; // Set outer radius
  public static final char CMD_SET_SPACING = 'S';      // Set LED spacing
  public static final char CMD_START_SEQUENCE = 'R';   // Run sequence
  public static final char CMD_STOP_SEQUENCE = 'X';    // Stop sequence
  public static final char CMD_ENTER_IDLE = 'i';       // Enter idle mode
  public static final char CMD_EXIT_IDLE = 'a';        // Exit idle mode
  public static final char CMD_SET_LED = 'L';          // Set specific LED
  public static final char CMD_SET_CAMERA = 'C';       // Set camera trigger settings
  
  // Buffer for incoming data
  private StringBuffer buffer = new StringBuffer();
  
  // Reference to models
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
    
    // Get list of available ports
    refreshPortList();
  }
  
  /**
   * Set the serial event callback
   */
  public void setCallback(SerialEventCallback callback) {
    this.callback = callback;
  }
  
  /**
   * Refresh the list of available serial ports
   */
  public void refreshPortList() {
    availablePorts = Serial.list();
  }
  
  /**
   * Get available serial ports
   */
  public String[] getAvailablePorts() {
    return availablePorts;
  }
  
  /**
   * Connect to a specified port
   */
  public boolean connect(int portIndex) {
    if (portIndex < 0 || portIndex >= availablePorts.length) {
      return false;
    }
    
    // Disconnect if already connected
    if (connected) {
      disconnect();
    }
    
    try {
      // Open the port
      portName = availablePorts[portIndex];
      arduinoPort = new Serial(Ptycography_2, portName, 9600);
      arduinoPort.bufferUntil('\n');
      selectedPortIndex = portIndex;
      connected = true;
      
      // Update state model
      stateModel.setHardwareConnected(true);
      
      println("Connected to: " + portName);
      return true;
    } catch (Exception e) {
      println("Error connecting to port: " + e.getMessage());
      connected = false;
      stateModel.setHardwareConnected(false);
      return false;
    }
  }
  
  /**
   * Disconnect from the current port
   */
  public void disconnect() {
    if (arduinoPort != null) {
      arduinoPort.stop();
      arduinoPort = null;
    }
    connected = false;
    stateModel.setHardwareConnected(false);
    println("Disconnected from hardware");
  }
  
  /**
   * Check if connected to hardware
   */
  public boolean isConnected() {
    return connected;
  }
  
  /**
   * Get the name of the current port
   */
  public String getPortName() {
    return portName;
  }
  
  /**
   * Get the index of the selected port
   */
  public int getSelectedPortIndex() {
    return selectedPortIndex;
  }
  
  /**
   * Send a command to the Arduino
   */
  public boolean sendCommand(String command) {
    if (!connected || arduinoPort == null) {
      println("Cannot send command: Not connected to hardware");
      return false;
    }
    
    try {
      arduinoPort.write(command + "\n");
      println("Sent to Arduino: " + command);
      return true;
    } catch (Exception e) {
      println("Error sending command: " + e.getMessage());
      return false;
    }
  }
  
  /**
   * Send pattern type to Arduino
   */
  public boolean sendPatternType() {
    return sendCommand(CMD_SET_PATTERN + "" + patternModel.getPatternType());
  }
  
  /**
   * Send pattern parameters to Arduino
   */
  public boolean sendPatternParameters() {
    if (!connected) return false;
    
    boolean success = true;
    
    // Send parameters based on pattern type
    switch (patternModel.getPatternType()) {
      case PatternModel.PATTERN_CONCENTRIC_RINGS:
        // Send ring radii for concentric rings pattern
        success &= sendCommand(CMD_SET_INNER_RADIUS + "" + patternModel.getInnerRingRadius());
        success &= sendCommand(CMD_SET_MIDDLE_RADIUS + "" + patternModel.getMiddleRingRadius());
        success &= sendCommand(CMD_SET_OUTER_RADIUS + "" + patternModel.getOuterRingRadius());
        break;
        
      case PatternModel.PATTERN_SPIRAL:
        // Send spiral parameters
        success &= sendCommand(CMD_SET_INNER_RADIUS + "" + patternModel.getSpiralMaxRadius());
        success &= sendCommand(CMD_SET_MIDDLE_RADIUS + "" + patternModel.getSpiralTurns());
        break;
        
      case PatternModel.PATTERN_GRID:
        // Send grid parameters
        success &= sendCommand(CMD_SET_INNER_RADIUS + "" + patternModel.getGridSpacing());
        success &= sendCommand(CMD_SET_MIDDLE_RADIUS + "" + patternModel.getGridPointSize());
        
        // Send X and Y offsets as a combined parameter
        int combinedOffset = (patternModel.getGridOffsetX() * 10) + patternModel.getGridOffsetY();
        success &= sendCommand(CMD_SET_OUTER_RADIUS + "" + combinedOffset);
        break;
        
      case PatternModel.PATTERN_CENTER_ONLY:
        // No parameters to send for center only
        break;
    }
    
    // Send common parameters
    success &= sendCommand(CMD_SET_SPACING + "" + patternModel.getGridSpacing());
    
    // Send camera settings
    String cameraCommand = cameraModel.getSettingsCommand(CMD_SET_CAMERA);
    success &= sendCommand(cameraCommand);
    
    return success;
  }
  
  /**
   * Send command to start the sequence
   */
  public boolean startSequence() {
    return sendCommand("" + CMD_START_SEQUENCE);
  }
  
  /**
   * Send command to stop the sequence
   */
  public boolean stopSequence() {
    return sendCommand("" + CMD_STOP_SEQUENCE);
  }
  
  /**
   * Send command to enter idle mode
   */
  public boolean enterIdleMode() {
    return sendCommand("" + CMD_ENTER_IDLE);
  }
  
  /**
   * Send command to exit idle mode
   */
  public boolean exitIdleMode() {
    return sendCommand("" + CMD_EXIT_IDLE);
  }
  
  /**
   * Send command to set a specific LED
   */
  public boolean setLed(int x, int y, int color) {
    return sendCommand(CMD_SET_LED + "," + x + "," + y + "," + color);
  }
  
  /**
   * Test camera trigger
   */
  public boolean testCameraTrigger() {
    return sendCommand(cameraModel.getTestCommand(CMD_SET_CAMERA));
  }
  
  /**
   * Process incoming serial data
   */
  public void processSerialEvent(Serial port) {
    if (port != arduinoPort) return;
    
    try {
      // Read the incoming data
      String data = port.readStringUntil('\n');
      
      // Process if not null
      if (data != null) {
        data = data.trim();
        println("Received from Arduino: " + data);
        
        // Parse data based on protocol
        if (data.startsWith("LED,")) {
          // Format: LED,x,y,color
          processLedUpdate(data);
        } else if (data.startsWith("STATUS,")) {
          // Format: STATUS,running,idle,progress,cameraEnabled,cameraTriggerActive,cameraErrorCode
          processStatusUpdate(data);
        } else if (data.startsWith("CAMERA,")) {
          // Format: CAMERA,triggerActive,errorCode
          processCameraUpdate(data);
        }
        
        // Notify callback if set
        if (callback != null) {
          callback.onSerialData(data);
        }
      }
    } catch (Exception e) {
      println("Error processing serial data: " + e.getMessage());
    }
  }
  
  /**
   * Process LED update from Arduino
   */
  private void processLedUpdate(String data) {
    // Format: LED,x,y,color
    String[] parts = data.substring(4).split(",");
    if (parts.length == 3) {
      try {
        int x = Integer.parseInt(parts[0]);
        int y = Integer.parseInt(parts[1]);
        int colorValue = Integer.parseInt(parts[2]);
        
        // Update state model
        stateModel.updateCurrentLed(x, y, colorValue);
      } catch (Exception e) {
        println("Error parsing LED data: " + e.getMessage());
      }
    }
  }
  
  /**
   * Process status update from Arduino
   */
  private void processStatusUpdate(String data) {
    // Format: STATUS,running,idle,progress,cameraEnabled,cameraTriggerActive,cameraErrorCode
    String[] parts = data.substring(7).split(",");
    if (parts.length >= 3) {
      try {
        boolean running = parts[0].equals("1");
        boolean idleMode = parts[1].equals("1");
        float progress = Float.parseFloat(parts[2]);
        
        // Update state model
        stateModel.updateFromSerialStatus(running, idleMode, progress);
        
        // Process additional camera status if available
        if (parts.length >= 4) {
          boolean cameraEnabled = parts[3].equals("1");
          cameraModel.setEnabled(cameraEnabled);
        }
        
        if (parts.length >= 6) {
          boolean cameraTriggerActive = parts[4].equals("1");
          int cameraErrorCode = Integer.parseInt(parts[5]);
          
          // Update camera model
          cameraModel.updateFromSerialData(cameraTriggerActive, cameraErrorCode);
        }
      } catch (Exception e) {
        println("Error parsing status data: " + e.getMessage());
      }
    }
  }
  
  /**
   * Process camera update from Arduino
   */
  private void processCameraUpdate(String data) {
    // Format: CAMERA,triggerActive,errorCode
    String[] parts = data.substring(7).split(",");
    if (parts.length >= 2) {
      try {
        boolean triggerActive = parts[0].equals("1");
        int errorCode = Integer.parseInt(parts[1]);
        
        // Update camera model
        cameraModel.updateFromSerialData(triggerActive, errorCode);
      } catch (Exception e) {
        println("Error parsing camera data: " + e.getMessage());
      }
    }
  }
}

/**
 * Interface for serial event callbacks
 */
interface SerialEventCallback {
  void onSerialData(String data);
}