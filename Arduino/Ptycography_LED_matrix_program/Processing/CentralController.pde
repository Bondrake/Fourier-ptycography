/**
 * Refactored CentralController for Ptycography LED Matrix
 * 
 * This Processing sketch serves as the central control point for the Ptycography 
 * LED matrix system. It provides a unified interface for both simulation and
 * hardware control, eliminating the need for separate Arduino programming.
 * 
 * Features:
 * - Complete UI for controlling all aspects of the system
 * - Hardware mode for controlling a physical LED matrix via Arduino/Teensy
 * - Simulation mode for running without hardware
 * - Pattern creation and editing tools
 * - Sequence control and monitoring
 * - Parameter adjustment without reprogramming Arduino
 */

// Import necessary libraries
import controlP5.*;
import processing.serial.*;

// IMPORTANT: Processing requires manually loading classes from subdirectories
// These lines ensures all the classes from the subdirectories are properly loaded
/* 
 * This is a workaround for Processing's limitations with directory structures.
 * All class files in subdirectories are automatically included when the sketch is run.
 * See: https://github.com/processing/processing/wiki/FAQ#why-cant-i-use-java-packages-in-processing
 */

// Models
PatternModel patternModel;
SystemStateModel stateModel;
CameraModel cameraModel;

// Controller
AppController appController;

// UI and utilities
UIManager uiManager;
SerialManager serialManager;
MatrixView matrixView;
StatusPanelView statusView;

// Collection of throttled event dispatchers to update
ArrayList<ThrottledEventDispatcher> throttledDispatchers;

// Constants
final int WINDOW_WIDTH = 1080;
final int WINDOW_HEIGHT = 1100; 
final int INFO_PANEL_WIDTH = 330;
final int MATRIX_WIDTH = 64;
final int MATRIX_HEIGHT = 64;
final int CELL_SIZE = 8;
final int GRID_PADDING_TOP = 50;

/**
 * Setup function - called once at startup
 */
void setup() {
  // Set window size
  size(1080, 1100);
  surface.setTitle("Ptycography LED Matrix Controller");
  
  // Initialize collection for throttled dispatchers
  throttledDispatchers = new ArrayList<ThrottledEventDispatcher>();
  
  // Initialize models
  patternModel = new PatternModel(MATRIX_WIDTH, MATRIX_HEIGHT);
  // Use throttled state model to prevent performance issues with rapid state changes
  stateModel = new ThrottledSystemStateModel(50); // 50ms throttle interval for state changes
  cameraModel = new CameraModel();
  
  // Initialize sequence info after pattern generation
  stateModel.setSequenceInfo(0, patternModel.getSequenceLength());
  
  // Initialize managers
  serialManager = new SerialManager(stateModel, patternModel, cameraModel);
  
  // Calculate center position for the matrix view (centered in the right portion of the window)
  int matrixAreaWidth = WINDOW_WIDTH - INFO_PANEL_WIDTH;
  int matrixXcenter = INFO_PANEL_WIDTH + (matrixAreaWidth / 2);
  int matrixXoffset = (MATRIX_WIDTH * CELL_SIZE) / 2;
  int matrixX = matrixXcenter - matrixXoffset;
  
  // Initialize views using event-based components
  matrixView = new MatrixView(patternModel, stateModel, cameraModel, 
                             matrixX, GRID_PADDING_TOP, CELL_SIZE);
  
  // Position the status panel at 55% down the screen
  int statusPanelY = (int)(WINDOW_HEIGHT * 0.55);
  statusView = new StatusPanelView(patternModel, stateModel, cameraModel,
                                  0, statusPanelY, INFO_PANEL_WIDTH);
  
  // Initialize UI
  uiManager = new UIManager(this, patternModel, stateModel, cameraModel, serialManager);
  
  // Initialize controller with all components
  appController = new AppController(this);
  
  // Connect components to the controller
  appController.setPatternModel(patternModel);
  appController.setStateModel(stateModel);
  appController.setCameraModel(cameraModel);
  appController.setSerialManager(serialManager);
  appController.setMatrixView(matrixView);
  appController.setStatusView(statusView);
  appController.setUIManager(uiManager);
  
  // Initialize the controller after all components are set
  appController.initialize();
  
  // Setup environment
  frameRate(30);
  background(0);
  textSize(14);
  
  // Display startup message
  println("Ptycography LED Matrix Central Controller (Refactored)");
  println("Hardware Mode: " + (stateModel.isSimulationMode() ? "Disabled" : "Enabled"));
}

/**
 * Draw function - called continuously
 */
void draw() {
  // Clear background
  background(0);
  
  // Draw components
  statusView.draw();
  matrixView.draw();
  
  // Update simulation if running
  if (stateModel.isSimulationMode() && stateModel.isRunning() && !stateModel.isPaused()) {
    updateSimulation();
  }
  
  // Handle idle mode in simulation
  if (stateModel.isSimulationMode() && stateModel.isIdle() && stateModel.checkIdleHeartbeat()) {
    // This will trigger heartbeat through the controller
    appController.triggerIdleHeartbeat();
  }
  
  // Process serial data if connected to hardware
  if (!stateModel.isSimulationMode() && stateModel.isHardwareConnected()) {
    // Serial processing is now handled by the SerialManager
  }
  
  // Update all throttled event dispatchers
  for (ThrottledEventDispatcher dispatcher : throttledDispatchers) {
    dispatcher.update();
  }
}

/**
 * Update the simulation state
 */
void updateSimulation() {
  // Get update interval from UI
  int updateInterval = (int)uiManager.getControlP5().get(Slider.class, "updateInterval").getValue();
  
  // Check if it's time to update
  if (millis() - getLastUpdateTime() < updateInterval) {
    return;
  }
  
  // Get sequence from pattern model
  ArrayList<PVector> sequence = patternModel.getIlluminationSequence();
  int sequenceIndex = stateModel.getSequenceIndex();
  
  // Check if we've reached the end
  if (sequenceIndex >= sequence.size()) {
    // Loop back to beginning
    sequenceIndex = 0;
    stateModel.setSequenceInfo(sequenceIndex, sequence.size());
    return;
  }
  
  // Update the current LED
  PVector led = sequence.get(sequenceIndex);
  stateModel.updateCurrentLed((int)led.x, (int)led.y, 2); // Green color
  
  // Increment sequence index
  sequenceIndex++;
  stateModel.setSequenceInfo(sequenceIndex, sequence.size());
  
  // Store last update time
  setLastUpdateTime(millis());
}

// Simulation timing
private int lastUpdateTime = 0;

private int getLastUpdateTime() {
  return lastUpdateTime;
}

private void setLastUpdateTime(int time) {
  lastUpdateTime = time;
}

/**
 * Handle serial events from Arduino
 */
void serialEvent(Serial port) {
  serialManager.processSerialEvent(port);
}

/**
 * Handle key press events
 */
void keyPressed() {
  appController.keyPressed(key);
}

/**
 * Handle control events from ControlP5
 */
void controlEvent(ControlEvent event) {
  // Prevent events during initialization when uiManager might be null
  if (uiManager != null) {
    uiManager.handleControlEvent(event);
  }
}

// UI control event handlers
// These functions will be called by ControlP5 when the corresponding
// UI controls are activated

// Pattern type radio button
void patternTypeRadio(int value) {
  patternModel.setPatternType(value);
}

// UI control handlers - connected to UI Manager
void startButton() { uiManager.startButton(); }
void pauseButton() { uiManager.pauseButton(); }
void stopButton() { uiManager.stopButton(); }
void regenerateButton() { uiManager.regenerateButton(); }
void connectButton() { uiManager.connectButton(); }
void testCameraButton() { uiManager.testCameraButton(); }

// Mode toggles
void simulationToggle(boolean value) {
  stateModel.setSimulationMode(value);
}

void idleToggle(boolean value) {
  if (value) {
    stateModel.enterIdleMode();
  } else {
    stateModel.exitIdleMode();
  }
}

void gridToggle(boolean value) {
  matrixView.setShowGrid(value);
}

void circleMaskToggle(boolean value) {
  patternModel.setCircleMaskMode(value);
}

// Camera settings
void cameraEnabled(boolean value) {
  cameraModel.setEnabled(value);
}

/**
 * Register a throttled event dispatcher for automatic updating in the draw loop
 * 
 * @param dispatcher The ThrottledEventDispatcher to register
 */
void registerThrottledDispatcher(ThrottledEventDispatcher dispatcher) {
  if (dispatcher != null && !throttledDispatchers.contains(dispatcher)) {
    throttledDispatchers.add(dispatcher);
  }
}

/**
 * Unregister a throttled event dispatcher
 * 
 * @param dispatcher The ThrottledEventDispatcher to unregister
 */
void unregisterThrottledDispatcher(ThrottledEventDispatcher dispatcher) {
  if (dispatcher != null) {
    throttledDispatchers.remove(dispatcher);
  }
}