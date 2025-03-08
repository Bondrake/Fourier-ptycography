/**
 * Central Controller for Ptycography LED Matrix
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

// Constants
final int MATRIX_WIDTH = 64;
final int MATRIX_HEIGHT = 64;
final int CELL_SIZE = 8;
final int GRID_PADDING_LEFT = 240;
final int GRID_PADDING_TOP = 50;
final int INFO_PANEL_WIDTH = 220;
final int CONTROL_PANEL_HEIGHT = 200;

// Pattern types
final int PATTERN_CONCENTRIC_RINGS = 0;
final int PATTERN_CENTER_ONLY = 1;
final int PATTERN_SPIRAL = 2;
final int PATTERN_GRID = 3;

// Pattern parameters (default values)
int innerRingRadius = 16;
int middleRingRadius = 24;
int outerRingRadius = 31;
float ledPitchMM = 2.0;
float targetLedSpacingMM = 4.0;
int ledSkip;
int patternType = PATTERN_CONCENTRIC_RINGS;

// Arduino communication
Serial arduinoPort;
boolean hardwareConnected = false;
String[] availablePorts;

// Command codes for Arduino communication
final char CMD_SET_PATTERN = 'P';     // Set pattern type
final char CMD_SET_INNER_RADIUS = 'I';  // Set inner ring radius
final char CMD_SET_MIDDLE_RADIUS = 'M'; // Set middle ring radius
final char CMD_SET_OUTER_RADIUS = 'O';  // Set outer ring radius
final char CMD_SET_SPACING = 'S';      // Set LED spacing
final char CMD_START_SEQUENCE = 'R';   // Run sequence
final char CMD_STOP_SEQUENCE = 'X';    // Stop sequence
final char CMD_ENTER_IDLE = 'i';       // Enter idle mode
final char CMD_EXIT_IDLE = 'a';        // Exit idle mode
final char CMD_SET_LED = 'L';          // Set specific LED

// Color definitions
final color OFF_COLOR = color(20);
final color RED_COLOR = color(255, 0, 0);
final color GREEN_COLOR = color(0, 255, 0);
final color BLUE_COLOR = color(0, 0, 255);
final color YELLOW_COLOR = color(255, 255, 0);
final color MAGENTA_COLOR = color(255, 0, 255);
final color CYAN_COLOR = color(0, 255, 255);
final color WHITE_COLOR = color(255, 255, 255);
final color PATTERN_COLOR = color(0, 100, 0);

// Color constants for bitwise operations
final int COLOR_RED = 1;
final int COLOR_GREEN = 2;
final int COLOR_BLUE = 4;

// Operation modes
boolean simulationMode = true;
boolean showGrid = true;
boolean running = false;
boolean paused = false;
boolean idleMode = false;

// Pattern storage
boolean[][] ledPattern;
int currentLedX = -1;
int currentLedY = -1;
int currentColor = COLOR_GREEN;
int sequenceIndex = 0;
ArrayList<int[]> illuminationSequence;

// Timing variables
int lastUpdateTime = 0;
int updateInterval = 500;  // ms between LED updates
int idleBlinkInterval = 60000;  // 60 seconds
int lastBlinkTime = 0;

// UI components
ControlP5 cp5;
Accordion accordion;

void setup() {
  // Create window with appropriate size
  size(1000, 700);
  
  // Initialize the pattern arrays
  ledPattern = new boolean[MATRIX_HEIGHT][MATRIX_WIDTH];
  
  // Calculate LED skip value based on spacing
  ledSkip = round(targetLedSpacingMM / ledPitchMM);
  if (ledSkip < 1) ledSkip = 1;
  
  // Initialize UI
  setupUI();
  
  // Generate the initial pattern
  regeneratePattern();
  
  // Create illumination sequence
  generateIlluminationSequence();
  
  // List available serial ports
  availablePorts = Serial.list();
  updatePortList();
  
  // Set up the display
  background(0);
  frameRate(30);
  textSize(14);
  
  println("Ptycography LED Matrix Central Controller");
  println("Hardware Mode: " + (simulationMode ? "Disabled" : "Enabled"));
}

void draw() {
  // Clear the background
  background(0);
  
  // Draw the information panel
  drawInfoPanel();
  
  // Draw the LED matrix
  drawLEDMatrix();
  
  // Update the simulation if running in simulation mode
  if (simulationMode && running && !paused) {
    updateSimulation();
  }
  
  // Handle idle mode in simulation mode
  if (simulationMode && idleMode) {
    handleIdleMode();
  }
  
  // Process any serial data if connected to hardware
  if (!simulationMode && hardwareConnected) {
    processSerialData();
  }
}

void drawInfoPanel() {
  // Draw the info panel background
  fill(40);
  noStroke();
  rect(0, 0, INFO_PANEL_WIDTH, height);
  
  // Draw panel title
  fill(200);
  textAlign(CENTER, TOP);
  textSize(16);
  text("LED MATRIX CONTROLLER", INFO_PANEL_WIDTH/2, 10);
  
  // Draw separator line
  stroke(100);
  line(10, 35, INFO_PANEL_WIDTH-10, 35);
  
  // Draw mode information
  fill(255);
  textAlign(LEFT, TOP);
  textSize(14);
  
  String modeText = simulationMode ? "SIMULATION" : "HARDWARE";
  String statusText = running ? (paused ? "PAUSED" : "RUNNING") : "STOPPED";
  String idleText = idleMode ? "IDLE MODE" : "ACTIVE";
  
  int yOffset = 330; // Position below the control panel
  text("Mode:", 20, yOffset);
  text(modeText, 120, yOffset);
  
  yOffset += 25;
  text("Status:", 20, yOffset);
  text(statusText, 120, yOffset);
  
  yOffset += 25;
  text("Power:", 20, yOffset);
  text(idleText, 120, yOffset);
  
  yOffset += 25;
  text("Pattern:", 20, yOffset);
  String patternText = "";
  switch (patternType) {
    case PATTERN_CONCENTRIC_RINGS: patternText = "CONCENTRIC RINGS"; break;
    case PATTERN_CENTER_ONLY: patternText = "CENTER ONLY"; break;
    case PATTERN_SPIRAL: patternText = "SPIRAL"; break;
    case PATTERN_GRID: patternText = "GRID"; break;
  }
  text(patternText, 120, yOffset);
  
  // Display current LED position
  yOffset += 40;
  text("Current LED:", 20, yOffset);
  text("x = " + currentLedX, 20, yOffset + 25);
  text("y = " + currentLedY, 20, yOffset + 50);
  
  // Draw hardware connection status
  if (!simulationMode) {
    yOffset += 90;
    text("Hardware:", 20, yOffset);
    text(hardwareConnected ? "CONNECTED" : "DISCONNECTED", 120, yOffset);
    
    if (hardwareConnected && arduinoPort != null) {
      text("Port:", 20, yOffset + 25);
      // Display the currently selected port name from the dropdown list
      int portIndex = (int)cp5.get(ScrollableList.class, "serialPortsList").getValue();
      if (portIndex >= 0 && portIndex < availablePorts.length) {
        text(availablePorts[portIndex], 120, yOffset + 25);
      } else {
        text("Unknown", 120, yOffset + 25);
      }
    }
  }
  
  // Draw progress information
  if (illuminationSequence != null && illuminationSequence.size() > 0) {
    yOffset += 90;
    text("Sequence Progress:", 20, yOffset);
    text(sequenceIndex + " / " + illuminationSequence.size(), 120, yOffset);
    
    // Draw progress bar
    float progress = (float)sequenceIndex / illuminationSequence.size();
    stroke(100);
    noFill();
    rect(20, yOffset + 25, 180, 15);
    fill(0, 255, 0);
    noStroke();
    rect(20, yOffset + 25, 180 * progress, 15);
  }
}

void drawLEDMatrix() {
  // Calculate grid position
  int gridX = GRID_PADDING_LEFT;
  int gridY = GRID_PADDING_TOP;
  
  // Draw matrix area background
  fill(20);
  noStroke();
  rect(INFO_PANEL_WIDTH, 0, width - INFO_PANEL_WIDTH, height);
  
  // Draw matrix title
  fill(200);
  textAlign(CENTER, TOP);
  textSize(14);
  text("64x64 RGB LED MATRIX", gridX + (MATRIX_WIDTH * CELL_SIZE) / 2, 20);
  
  // Draw grid background
  noStroke();
  fill(30);
  rect(gridX - 1, gridY - 1, MATRIX_WIDTH * CELL_SIZE + 2, MATRIX_HEIGHT * CELL_SIZE + 2);
  
  // Draw each LED cell
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      // Determine cell color
      color cellColor = OFF_COLOR;
      
      // In simulation mode or when no special LED is active
      if ((currentLedX != x || currentLedY != y) || !running || paused) {
        // Check if this LED is part of the pattern
        if (ledPattern[y][x]) {
          // Use a dimmer color to indicate pattern but not active
          cellColor = PATTERN_COLOR;
        }
      } else if (currentLedX == x && currentLedY == y) {
        // This is the currently active LED
        // Determine color based on current color setting
        if ((currentColor & COLOR_RED) != 0 && (currentColor & COLOR_GREEN) != 0 && (currentColor & COLOR_BLUE) != 0) {
          cellColor = WHITE_COLOR;
        } else if ((currentColor & COLOR_RED) != 0 && (currentColor & COLOR_GREEN) != 0) {
          cellColor = YELLOW_COLOR;
        } else if ((currentColor & COLOR_RED) != 0 && (currentColor & COLOR_BLUE) != 0) {
          cellColor = MAGENTA_COLOR;
        } else if ((currentColor & COLOR_GREEN) != 0 && (currentColor & COLOR_BLUE) != 0) {
          cellColor = CYAN_COLOR;
        } else if ((currentColor & COLOR_RED) != 0) {
          cellColor = RED_COLOR;
        } else if ((currentColor & COLOR_GREEN) != 0) {
          cellColor = GREEN_COLOR;
        } else if ((currentColor & COLOR_BLUE) != 0) {
          cellColor = BLUE_COLOR;
        }
      }
      
      // Draw the cell
      fill(cellColor);
      int cellX = gridX + x * CELL_SIZE;
      int cellY = gridY + y * CELL_SIZE;
      rect(cellX, cellY, CELL_SIZE, CELL_SIZE);
    }
  }
  
  // Draw grid lines if enabled
  if (showGrid) {
    stroke(60);
    // Draw vertical lines
    for (int x = 0; x <= MATRIX_WIDTH; x += 8) {
      line(gridX + x * CELL_SIZE, gridY, gridX + x * CELL_SIZE, gridY + MATRIX_HEIGHT * CELL_SIZE);
    }
    // Draw horizontal lines
    for (int y = 0; y <= MATRIX_HEIGHT; y += 8) {
      line(gridX, gridY + y * CELL_SIZE, gridX + MATRIX_WIDTH * CELL_SIZE, gridY + y * CELL_SIZE);
    }
  }
  
  // Draw coordinates
  fill(150);
  textSize(10);
  textAlign(CENTER, TOP);
  
  // Draw x-axis coordinates (only every 8 for clarity)
  for (int x = 0; x < MATRIX_WIDTH; x += 8) {
    text(str(x), gridX + x * CELL_SIZE + CELL_SIZE/2, gridY + MATRIX_HEIGHT * CELL_SIZE + 5);
  }
  
  // Draw y-axis coordinates (only every 8 for clarity)
  textAlign(RIGHT, CENTER);
  for (int y = 0; y < MATRIX_HEIGHT; y += 8) {
    text(str(y), gridX - 5, gridY + y * CELL_SIZE + CELL_SIZE/2);
  }
}

void setupUI() {
  cp5 = new ControlP5(this);
  
  // Create groups
  Group patternGroup = cp5.addGroup("Pattern Settings")
    .setPosition(10, 40)
    .setBackgroundColor(color(0, 64))
    .setWidth(200)
    .setBackgroundHeight(100)
    .setBarHeight(20);
    
  Group controlGroup = cp5.addGroup("Controls")
    .setPosition(10, 160)
    .setBackgroundColor(color(0, 64))
    .setWidth(200)
    .setBackgroundHeight(100)
    .setBarHeight(20);
    
  Group hardwareGroup = cp5.addGroup("Hardware")
    .setPosition(10, 280)
    .setBackgroundColor(color(0, 64))
    .setWidth(200)
    .setBackgroundHeight(100)
    .setBarHeight(20);
    
  // Add controls to pattern group
  cp5.addRadioButton("patternTypeRadio")
    .setPosition(10, 10)
    .setSize(18, 18)
    .setColorForeground(color(120))
    .setColorActive(color(0, 255, 0))
    .setColorLabel(color(255))
    .setItemsPerRow(1)
    .setSpacingRow(6)
    .addItem("Concentric Rings", PATTERN_CONCENTRIC_RINGS)
    .addItem("Center Only", PATTERN_CENTER_ONLY)
    .addItem("Spiral", PATTERN_SPIRAL)
    .addItem("Grid", PATTERN_GRID)
    .activate(PATTERN_CONCENTRIC_RINGS)
    .moveTo(patternGroup);
    
  // Add sliders for ring radii
  cp5.addSlider("innerRingRadius")
    .setPosition(10, 100)
    .setSize(180, 15)
    .setRange(5, 30)
    .setValue(16)
    .setLabel("Inner Ring Radius")
    .moveTo(patternGroup);
    
  cp5.addSlider("middleRingRadius")
    .setPosition(10, 120)
    .setSize(180, 15)
    .setRange(10, 40)
    .setValue(24)
    .setLabel("Middle Ring Radius")
    .moveTo(patternGroup);
    
  cp5.addSlider("outerRingRadius")
    .setPosition(10, 140)
    .setSize(180, 15)
    .setRange(15, 31)
    .setValue(31)
    .setLabel("Outer Ring Radius")
    .moveTo(patternGroup);
    
  cp5.addSlider("targetLedSpacingMM")
    .setPosition(10, 160)
    .setSize(180, 15)
    .setRange(2, 6)
    .setValue(4)
    .setLabel("LED Spacing (mm)")
    .moveTo(patternGroup);
    
  // Add control buttons
  cp5.addButton("startButton")
    .setPosition(10, 10)
    .setSize(90, 20)
    .setLabel("Start")
    .moveTo(controlGroup);
    
  cp5.addButton("pauseButton")
    .setPosition(110, 10)
    .setSize(90, 20)
    .setLabel("Pause")
    .moveTo(controlGroup);
    
  cp5.addButton("stopButton")
    .setPosition(10, 40)
    .setSize(90, 20)
    .setLabel("Stop")
    .moveTo(controlGroup);
    
  cp5.addButton("regenerateButton")
    .setPosition(110, 40)
    .setSize(90, 20)
    .setLabel("Regenerate")
    .moveTo(controlGroup);
    
  cp5.addToggle("idleToggle")
    .setPosition(10, 70)
    .setSize(90, 20)
    .setLabel("Idle Mode")
    .setValue(false)
    .moveTo(controlGroup);
    
  cp5.addToggle("gridToggle")
    .setPosition(110, 70)
    .setSize(90, 20)
    .setLabel("Show Grid")
    .setValue(true)
    .moveTo(controlGroup);
    
  cp5.addSlider("updateInterval")
    .setPosition(10, 100)
    .setSize(180, 15)
    .setRange(100, 2000)
    .setValue(500)
    .setLabel("Update Interval (ms)")
    .moveTo(controlGroup);
    
  // Add hardware controls
  cp5.addToggle("simulationToggle")
    .setPosition(10, 10)
    .setSize(180, 20)
    .setLabel("Simulation Mode")
    .setValue(true)
    .moveTo(hardwareGroup);
    
  cp5.addScrollableList("serialPortsList")
    .setPosition(10, 40)
    .setSize(180, 100)
    .setBarHeight(20)
    .setItemHeight(20)
    .setLabel("Serial Port")
    .moveTo(hardwareGroup);
    
  cp5.addButton("connectButton")
    .setPosition(10, 150)
    .setSize(180, 20)
    .setLabel("Connect to Hardware")
    .moveTo(hardwareGroup);
    
  cp5.addButton("uploadPatternButton")
    .setPosition(10, 180)
    .setSize(180, 20)
    .setLabel("Upload Pattern to Hardware")
    .moveTo(hardwareGroup);
    
  // Create accordion
  accordion = cp5.addAccordion("acc")
    .setPosition(10, 40)
    .setWidth(200)
    .addItem(patternGroup)
    .addItem(controlGroup)
    .addItem(hardwareGroup)
    .open(0, 1, 2);
    
  accordion.setCollapseMode(Accordion.MULTI);
}

// Event handlers for UI components
public void patternTypeRadio(int value) {
  patternType = value;
  regeneratePattern();
  generateIlluminationSequence();
  
  // If hardware connected, send pattern type
  if (!simulationMode && hardwareConnected) {
    sendPatternTypeToHardware();
  }
}

public void simulationToggle(boolean value) {
  simulationMode = value;
  
  // If switching to hardware mode, disconnect if connected
  if (simulationMode && hardwareConnected) {
    disconnectHardware();
  }
  
  println("Switched to " + (simulationMode ? "Simulation" : "Hardware") + " mode");
}

public void serialPortsList(int index) {
  // Select port from the list
  if (index >= 0 && index < availablePorts.length) {
    println("Selected port: " + availablePorts[index]);
  }
}

public void connectButton() {
  if (simulationMode) {
    println("Cannot connect in simulation mode. Switch to hardware mode first.");
    return;
  }
  
  // Get selected port
  int portIndex = (int)cp5.get(ScrollableList.class, "serialPortsList").getValue();
  if (portIndex < 0 || portIndex >= availablePorts.length) {
    println("Please select a valid serial port");
    return;
  }
  
  // Try to connect
  try {
    if (hardwareConnected) {
      disconnectHardware();
    }
    
    // Connect to the selected port
    arduinoPort = new Serial(this, availablePorts[portIndex], 9600);
    arduinoPort.bufferUntil('\n');
    hardwareConnected = true;
    
    println("Connected to hardware on port: " + availablePorts[portIndex]);
  } catch (Exception e) {
    println("Error connecting to hardware: " + e.getMessage());
    hardwareConnected = false;
  }
}

public void uploadPatternButton() {
  if (!hardwareConnected) {
    println("Cannot upload pattern: Hardware not connected");
    return;
  }
  
  // Send pattern parameters
  sendPatternTypeToHardware();
  sendPatternParametersToHardware();
  
  println("Pattern uploaded to hardware");
}

public void startButton() {
  running = true;
  paused = false;
  
  if (sequenceIndex >= illuminationSequence.size()) {
    sequenceIndex = 0;
  }
  
  // If in hardware mode, send command to start sequence
  if (!simulationMode && hardwareConnected) {
    arduinoPort.write(CMD_START_SEQUENCE);
  }
}

public void pauseButton() {
  paused = !paused;
  
  // No direct pause command for hardware - we'll manage it in software
}

public void stopButton() {
  running = false;
  paused = false;
  sequenceIndex = 0;
  currentLedX = -1;
  currentLedY = -1;
  
  // If in hardware mode, send command to stop sequence
  if (!simulationMode && hardwareConnected) {
    arduinoPort.write(CMD_STOP_SEQUENCE);
  }
}

public void regenerateButton() {
  regeneratePattern();
  generateIlluminationSequence();
  sequenceIndex = 0;
  
  // If in hardware mode, send updated pattern
  if (!simulationMode && hardwareConnected) {
    sendPatternParametersToHardware();
  }
}

public void idleToggle(boolean value) {
  idleMode = value;
  
  // If in hardware mode, send idle command
  if (!simulationMode && hardwareConnected) {
    if (idleMode) {
      arduinoPort.write(CMD_ENTER_IDLE);
    } else {
      arduinoPort.write(CMD_EXIT_IDLE);
    }
  }
  
  // In simulation mode, handle locally
  if (simulationMode) {
    if (idleMode) {
      running = false;
      paused = false;
      currentLedX = -1;
      currentLedY = -1;
      lastBlinkTime = millis();
    }
  }
}

public void gridToggle(boolean value) {
  showGrid = value;
}

public void controlEvent(ControlEvent event) {
  // Listen for parameter changes
  if (event.isController()) {
    String name = event.getController().getName();
    if (name.equals("innerRingRadius") || 
        name.equals("middleRingRadius") || 
        name.equals("outerRingRadius") || 
        name.equals("targetLedSpacingMM")) {
      // Recalculate LED skip
      ledSkip = round(targetLedSpacingMM / ledPitchMM);
      if (ledSkip < 1) ledSkip = 1;
      
      // Regenerate pattern with new parameters
      regeneratePattern();
      generateIlluminationSequence();
      
      // If in hardware mode and connected, send updated parameters
      if (!simulationMode && hardwareConnected) {
        sendPatternParametersToHardware();
      }
    }
  }
}

void regeneratePattern() {
  // Clear the pattern
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      ledPattern[y][x] = false;
    }
  }
  
  // Get center coordinates
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Set the center LED for center-only pattern
  ledPattern[centerY][centerX] = true;
  
  // Generate pattern based on type
  switch (patternType) {
    case PATTERN_CONCENTRIC_RINGS:
      generateConcentricRings();
      break;
    case PATTERN_CENTER_ONLY:
      // Center LED is already set
      break;
    case PATTERN_SPIRAL:
      generateSpiral();
      break;
    case PATTERN_GRID:
      generateGrid();
      break;
  }
}

void generateConcentricRings() {
  // Get center coordinates
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Generate the ring pattern
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      // Skip LEDs based on spacing
      if ((x + y) % ledSkip != 0) continue;
      
      // Calculate distance from center
      float dx = x - centerX;
      float dy = y - centerY;
      float distance = sqrt(dx*dx + dy*dy);
      
      // Check if this LED falls on one of our rings
      if (abs(distance - innerRingRadius) < 1.0 || 
          abs(distance - middleRingRadius) < 1.0 || 
          abs(distance - outerRingRadius) < 1.0) {
        ledPattern[y][x] = true;
      }
    }
  }
}

void generateSpiral() {
  // Get center coordinates
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Maximum radius to stay within matrix bounds
  float maxRadius = min(centerX, centerY) - 5;
  
  // Generate spiral points
  float radiusStep = maxRadius / 50;  // Approximate steps for smooth spiral
  
  // Generate the spiral
  for (float angle = 0; angle < 2 * PI * 3; angle += 0.1) {
    float radius = (angle / (2 * PI)) * maxRadius / 3;
    
    // Calculate LED coordinates (polar to cartesian conversion)
    int x = centerX + round(radius * cos(angle));
    int y = centerY + round(radius * sin(angle));
    
    // Validate coordinates and apply spacing
    if (x >= 0 && x < MATRIX_WIDTH && y >= 0 && y < MATRIX_HEIGHT && 
        ((x + y) % ledSkip == 0)) {
      ledPattern[y][x] = true;
    }
  }
}

void generateGrid() {
  // Use LED skip for grid spacing
  for (int y = 0; y < MATRIX_HEIGHT; y += ledSkip) {
    for (int x = 0; x < MATRIX_WIDTH; x += ledSkip) {
      ledPattern[y][x] = true;
    }
  }
}

void generateIlluminationSequence() {
  // Create a list of all LEDs in the pattern
  illuminationSequence = new ArrayList<int[]>();
  
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      if (ledPattern[y][x]) {
        illuminationSequence.add(new int[] {x, y});
      }
    }
  }
  
  sequenceIndex = 0;
  println("Generated illumination sequence with " + illuminationSequence.size() + " steps");
}

void updateSimulation() {
  // Only update at specified intervals
  if (millis() - lastUpdateTime < updateInterval) {
    return;
  }
  lastUpdateTime = millis();
  
  // If we've reached the end of the sequence, stop or loop
  if (sequenceIndex >= illuminationSequence.size()) {
    // Option 1: Stop the animation
    // running = false;
    
    // Option 2: Loop back to the beginning
    sequenceIndex = 0;
    return;
  }
  
  // Get the next LED coordinates
  int[] coords = illuminationSequence.get(sequenceIndex);
  currentLedX = coords[0];
  currentLedY = coords[1];
  currentColor = COLOR_GREEN;  // Default to green
  
  // Increment the sequence index
  sequenceIndex++;
}

void handleIdleMode() {
  // Check if it's time for a heartbeat blink
  if (millis() - lastBlinkTime >= idleBlinkInterval) {
    // Blink the center LED
    int centerX = MATRIX_WIDTH / 2;
    int centerY = MATRIX_HEIGHT / 2;
    currentLedX = centerX;
    currentLedY = centerY;
    currentColor = COLOR_GREEN;
    
    // Reset the timer
    lastBlinkTime = millis();
    
    // Create a timer to turn off the LED after 500ms
    Thread t = new Thread(new Runnable() {
      public void run() {
        try {
          Thread.sleep(500);
          currentLedX = -1;
          currentLedY = -1;
        } catch (InterruptedException e) {
          e.printStackTrace();
        }
      }
    });
    t.start();
  }
}

void updatePortList() {
  // Add serial ports to dropdown
  ScrollableList portList = cp5.get(ScrollableList.class, "serialPortsList");
  portList.clear();
  
  for (int i = 0; i < availablePorts.length; i++) {
    portList.addItem(availablePorts[i], i);
  }
  
  if (availablePorts.length > 0) {
    portList.setValue(0);
  }
}

void disconnectHardware() {
  if (arduinoPort != null) {
    arduinoPort.stop();
    arduinoPort = null;
  }
  hardwareConnected = false;
  println("Disconnected from hardware");
}

void sendPatternTypeToHardware() {
  if (!hardwareConnected) return;
  
  // Send pattern type command: P<type>
  arduinoPort.write(CMD_SET_PATTERN + "" + patternType + "\n");
}

void sendPatternParametersToHardware() {
  if (!hardwareConnected) return;
  
  // Send ring radii
  arduinoPort.write(CMD_SET_INNER_RADIUS + "" + innerRingRadius + "\n");
  arduinoPort.write(CMD_SET_MIDDLE_RADIUS + "" + middleRingRadius + "\n");
  arduinoPort.write(CMD_SET_OUTER_RADIUS + "" + outerRingRadius + "\n");
  
  // Send LED spacing
  arduinoPort.write(CMD_SET_SPACING + "" + ledSkip + "\n");
}

void processSerialData() {
  // Process any incoming serial data
  if (arduinoPort.available() > 0) {
    String data = arduinoPort.readStringUntil('\n');
    if (data != null) {
      data = data.trim();
      println("Received from Arduino: " + data);
      
      // Parse data based on protocol
      if (data.startsWith("LED,")) {
        // Format: LED,x,y,color
        String[] parts = data.substring(4).split(",");
        if (parts.length == 3) {
          try {
            int x = Integer.parseInt(parts[0]);
            int y = Integer.parseInt(parts[1]);
            int colorValue = Integer.parseInt(parts[2]);
            
            // Update LED display
            currentLedX = x;
            currentLedY = y;
            currentColor = colorValue;
          } catch (Exception e) {
            println("Error parsing LED data: " + e.getMessage());
          }
        }
      } else if (data.startsWith("STATUS,")) {
        // Format: STATUS,running,idle,progress
        String[] parts = data.substring(7).split(",");
        if (parts.length == 3) {
          try {
            running = parts[0].equals("1");
            idleMode = parts[1].equals("1");
            float progress = Float.parseFloat(parts[2]);
            sequenceIndex = (int)(progress * illuminationSequence.size());
          } catch (Exception e) {
            println("Error parsing status data: " + e.getMessage());
          }
        }
      }
    }
  }
}

void serialEvent(Serial port) {
  // This is called when data is available from the serial port
  processSerialData();
}

void keyPressed() {
  // Keyboard shortcuts
  if (key == 'g' || key == 'G') {
    showGrid = !showGrid;
    cp5.getController("gridToggle").setValue(showGrid ? 1 : 0);
  }
  
  if (key == ' ') {
    paused = !paused;
  }
  
  if (key == 's' || key == 'S') {
    String filename = "led_matrix_" + year() + month() + day() + hour() + minute() + second() + ".png";
    save(filename);
    println("Pattern saved as: " + filename);
  }
  
  if (key == 'r' || key == 'R') {
    // Refresh the serial port list
    availablePorts = Serial.list();
    updatePortList();
    println("Serial port list refreshed");
  }
}