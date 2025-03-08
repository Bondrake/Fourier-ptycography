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
final int GRID_PADDING_LEFT = 350;  // Increased to account for wider info panel
final int GRID_PADDING_TOP = 50;
final int INFO_PANEL_WIDTH = 330;   // Made even wider to accommodate side labels
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
boolean circleMaskMode = false;  // Toggle for circle mask mode
int circleMaskRadius = 25;       // Radius for the circle mask in pixels

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
  // Create window with appropriate size - increased height by 300 pixels
  size(1080, 1060);
  
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
  final int SECTION_SPACING = 15;  // Space between sections
  final int FIELD_SPACING = 25;    // Space between fields
  final int LABEL_WIDTH = 100;     // Width for labels
  final int VALUE_WIDTH = 120;     // Width for values
  
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
  
  // Start position for information display - moved to the bottom of the panel
  int yPos = height - 250;  // Start status section from the bottom
  
  // SECTION: Status Information
  drawSectionHeader("STATUS", yPos);
  yPos += 25;
  
  // Draw mode information with consistent spacing
  fill(255);
  textAlign(LEFT, TOP);
  textSize(14);
  
  // Prepare text values
  String modeText = simulationMode ? "SIMULATION" : "HARDWARE";
  String statusText = running ? (paused ? "PAUSED" : "RUNNING") : "STOPPED";
  String idleText = idleMode ? "IDLE MODE" : "ACTIVE";
  String maskText = circleMaskMode ? "ON (r=" + circleMaskRadius + ")" : "OFF";
  String patternText = "";
  switch (patternType) {
    case PATTERN_CONCENTRIC_RINGS: patternText = "CONCENTRIC RINGS"; break;
    case PATTERN_CENTER_ONLY: patternText = "CENTER ONLY"; break;
    case PATTERN_SPIRAL: patternText = "SPIRAL"; break;
    case PATTERN_GRID: patternText = "GRID"; break;
  }
  
  // Draw status fields
  drawField("Mode:", modeText, yPos);
  yPos += FIELD_SPACING;
  
  drawField("Status:", statusText, yPos);
  yPos += FIELD_SPACING;
  
  drawField("Power:", idleText, yPos);
  yPos += FIELD_SPACING;
  
  drawField("Pattern:", patternText, yPos);
  yPos += FIELD_SPACING;
  
  drawField("Mask:", maskText, yPos);
  yPos += FIELD_SPACING + SECTION_SPACING;
  
  // SECTION: Current LED Information
  drawSectionHeader("CURRENT LED", yPos);
  yPos += 25;
  
  drawField("X:", currentLedX == -1 ? "None" : String.valueOf(currentLedX), yPos);
  yPos += FIELD_SPACING;
  
  drawField("Y:", currentLedY == -1 ? "None" : String.valueOf(currentLedY), yPos);
  yPos += FIELD_SPACING + SECTION_SPACING;
  
  // SECTION: Hardware Status (only in hardware mode)
  if (!simulationMode) {
    drawSectionHeader("HARDWARE", yPos);
    yPos += 25;
    
    drawField("Status:", hardwareConnected ? "CONNECTED" : "DISCONNECTED", yPos);
    yPos += FIELD_SPACING;
    
    if (hardwareConnected && arduinoPort != null) {
      // Display the currently selected port name
      int portIndex = (int)cp5.get(ScrollableList.class, "serialPortsList").getValue();
      String portName = "Unknown";
      if (portIndex >= 0 && portIndex < availablePorts.length) {
        portName = availablePorts[portIndex];
        // Truncate if too long
        if (portName.length() > 15) {
          portName = portName.substring(0, 12) + "...";
        }
      }
      drawField("Port:", portName, yPos);
      yPos += FIELD_SPACING;
    }
    
    yPos += SECTION_SPACING;
  }
  
  // SECTION: Sequence Progress (only if sequence exists)
  if (illuminationSequence != null && illuminationSequence.size() > 0) {
    drawSectionHeader("SEQUENCE", yPos);
    yPos += 25;
    
    // Progress text
    drawField("Progress:", sequenceIndex + " / " + illuminationSequence.size(), yPos);
    yPos += FIELD_SPACING;
    
    // Progress bar
    text("", 20, yPos); // Empty label
    float progress = (float)sequenceIndex / illuminationSequence.size();
    int barWidth = 180;
    int barHeight = 12;
    int barX = 20;
    int barY = yPos;
    
    // Background
    stroke(100);
    noFill();
    rect(barX, barY, barWidth, barHeight);
    
    // Progress fill
    fill(0, 255, 0);
    noStroke();
    rect(barX, barY, barWidth * progress, barHeight);
    
    yPos += 20; // Extra space after the bar
  }
}

// Helper method to draw a section header
void drawSectionHeader(String title, int yPos) {
  fill(180);
  textAlign(LEFT, TOP);
  textSize(14);
  text(title, 20, yPos);
  
  // Draw a subtle separator line
  stroke(80);
  line(85, yPos + 7, INFO_PANEL_WIDTH - 20, yPos + 7);
}

// Helper method to draw a field with label and value
void drawField(String label, String value, int yPos) {
  fill(200);
  textAlign(LEFT, TOP);
  textSize(13);
  text(label, 20, yPos);
  
  fill(255);
  // Use ellipsis for long values to prevent spillover
  if (value.length() > 13 && !value.contains("CONCENTRIC")) {
    value = value.substring(0, 10) + "...";
  }
  text(value, 100, yPos);
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
  
  // Constants for UI layout
  final int GROUP_WIDTH = INFO_PANEL_WIDTH - 20;  // Make group width match info panel width
  final int CONTROL_MARGIN = 10;
  final int BAR_HEIGHT = 20;
  
  // Calculate heights for each group - increased as requested
  final int PATTERN_GROUP_HEIGHT = 370;  // Increased to accommodate circle mask controls
  final int CONTROL_GROUP_HEIGHT = 220;  // Reduced since we moved circle mask controls
  final int HARDWARE_GROUP_HEIGHT = 300; // Increased by 80 pixels
  
  // Calculate spacing between groups in accordion mode
  final int GROUP_SPACING = BAR_HEIGHT + 5;
  
  // Create Pattern Settings Group
  Group patternGroup = cp5.addGroup("Pattern Settings")
    .setPosition(CONTROL_MARGIN, 40)
    .setBackgroundColor(color(0, 64))
    .setWidth(GROUP_WIDTH)
    .setBackgroundHeight(PATTERN_GROUP_HEIGHT)
    .setBarHeight(BAR_HEIGHT);
    
  // Create Controls Group
  Group controlGroup = cp5.addGroup("Controls")
    .setPosition(CONTROL_MARGIN, 40 + PATTERN_GROUP_HEIGHT + GROUP_SPACING)
    .setBackgroundColor(color(0, 64))
    .setWidth(GROUP_WIDTH)
    .setBackgroundHeight(CONTROL_GROUP_HEIGHT)
    .setBarHeight(BAR_HEIGHT);
    
  // Create Hardware Group
  Group hardwareGroup = cp5.addGroup("Hardware")
    .setPosition(CONTROL_MARGIN, 40 + PATTERN_GROUP_HEIGHT + CONTROL_GROUP_HEIGHT + GROUP_SPACING*2)
    .setBackgroundColor(color(0, 64))
    .setWidth(GROUP_WIDTH)
    .setBackgroundHeight(HARDWARE_GROUP_HEIGHT)
    .setBarHeight(BAR_HEIGHT);
    
  // Add a title for Pattern group
  cp5.addTextlabel("patternTitle")
    .setText("Select Pattern Type:")
    .setPosition(CONTROL_MARGIN, 10)
    .setColorValue(color(220))
    .setFont(createFont("Arial", 14))
    .moveTo(patternGroup);
    
  // Add controls to pattern group with better spacing
  cp5.addRadioButton("patternTypeRadio")
    .setPosition(CONTROL_MARGIN, 40)  // Moved down to make room for title
    .setSize(20, 20)   // Larger radio buttons
    .setColorForeground(color(120))
    .setColorActive(color(0, 255, 0))
    .setColorLabel(color(255))
    .setItemsPerRow(1)
    .setSpacingRow(15) // Increased spacing between radio buttons
    .addItem("Concentric Rings", PATTERN_CONCENTRIC_RINGS)
    .addItem("Center Only", PATTERN_CENTER_ONLY)
    .addItem("Spiral", PATTERN_SPIRAL)
    .addItem("Grid", PATTERN_GRID)
    .activate(PATTERN_CONCENTRIC_RINGS)
    .moveTo(patternGroup);
    
  // Add a title for the sliders - moved much lower to avoid overlap with radio buttons
  cp5.addTextlabel("slidersTitle")
    .setText("Adjust Pattern Parameters:")
    .setPosition(CONTROL_MARGIN, 140)
    .setColorValue(color(220))
    .setFont(createFont("Arial", 14))
    .moveTo(patternGroup);
    
  // Calculate slider dimensions to leave room for labels
  final int SLIDER_WIDTH = 140; // Significantly narrower to leave room for labels
  final int LABEL_OFFSET = 8;   // Space between slider and its label
  
  // Add sliders for ring radii - with narrower width to avoid label spillover
  Slider innerSlider = cp5.addSlider("innerRingRadius")
    .setPosition(CONTROL_MARGIN, 180)
    .setSize(SLIDER_WIDTH, 15)
    .setRange(5, 30)
    .setValue(16)
    .setLabel("Inner Ring Radius")
    .moveTo(patternGroup);
  // Configure label after adding to group
  innerSlider.getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER).setPaddingX(LABEL_OFFSET);
    
  Slider middleSlider = cp5.addSlider("middleRingRadius")
    .setPosition(CONTROL_MARGIN, 210)
    .setSize(SLIDER_WIDTH, 15)
    .setRange(10, 40)
    .setValue(24)
    .setLabel("Middle Ring Radius")
    .moveTo(patternGroup);
  // Configure label after adding to group
  middleSlider.getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER).setPaddingX(LABEL_OFFSET);
    
  Slider outerSlider = cp5.addSlider("outerRingRadius")
    .setPosition(CONTROL_MARGIN, 240)
    .setSize(SLIDER_WIDTH, 15)
    .setRange(15, 31)
    .setValue(31)
    .setLabel("Outer Ring Radius")
    .moveTo(patternGroup);
  // Configure label after adding to group
  outerSlider.getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER).setPaddingX(LABEL_OFFSET);
    
  Slider spacingSlider = cp5.addSlider("targetLedSpacingMM")
    .setPosition(CONTROL_MARGIN, 270)
    .setSize(SLIDER_WIDTH, 15)
    .setRange(2, 6)
    .setValue(4)
    .setLabel("LED Spacing (mm)")
    .moveTo(patternGroup);
  // Configure label after adding to group
  spacingSlider.getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER).setPaddingX(LABEL_OFFSET);
  
  // Add Circle Mask section title
  cp5.addTextlabel("maskTitle")
    .setText("Circle Mask:")
    .setPosition(CONTROL_MARGIN, 300)
    .setColorValue(color(220))
    .setFont(createFont("Arial", 14))
    .moveTo(patternGroup);
    
  // Add Circle Mask Toggle
  cp5.addToggle("circleMaskToggle")
    .setPosition(CONTROL_MARGIN + 100, 300)
    .setSize(50, 15)
    .setLabel("")
    .setValue(false)
    .moveTo(patternGroup);
    
  // Circle Mask Radius slider
  Slider circleMaskSlider = cp5.addSlider("circleMaskRadius")
    .setPosition(CONTROL_MARGIN, 330)
    .setSize(SLIDER_WIDTH, 15)
    .setRange(5, 32)
    .setValue(25)
    .setLabel("Mask Radius")
    .moveTo(patternGroup);
  // Configure label after adding to group
  circleMaskSlider.getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER).setPaddingX(LABEL_OFFSET);
    
  // Add control buttons with more consistent spacing
  int buttonWidth = (GROUP_WIDTH - CONTROL_MARGIN*3) / 2;
  
  // Add a title for Controls group
  cp5.addTextlabel("controlsTitle")
    .setText("Sequence Controls:")
    .setPosition(CONTROL_MARGIN, 10)
    .setColorValue(color(220))
    .setFont(createFont("Arial", 14))
    .moveTo(controlGroup);
  
  // First row of buttons - larger and more spaced
  cp5.addButton("startButton")
    .setPosition(CONTROL_MARGIN, 40)
    .setSize(buttonWidth, 30)
    .setLabel("Start")
    .setColorBackground(color(0, 120, 0))
    .moveTo(controlGroup);
    
  cp5.addButton("pauseButton")
    .setPosition(CONTROL_MARGIN*2 + buttonWidth, 40)
    .setSize(buttonWidth, 30)
    .setLabel("Pause")
    .setColorBackground(color(120, 120, 0))
    .moveTo(controlGroup);
    
  // Second row of buttons
  cp5.addButton("stopButton")
    .setPosition(CONTROL_MARGIN, 80)
    .setSize(buttonWidth, 30)
    .setLabel("Stop")
    .setColorBackground(color(120, 0, 0))
    .moveTo(controlGroup);
    
  cp5.addButton("regenerateButton")
    .setPosition(CONTROL_MARGIN*2 + buttonWidth, 80)
    .setSize(buttonWidth, 30)
    .setLabel("Regenerate")
    .moveTo(controlGroup);
  
  // Settings title  
  cp5.addTextlabel("settingsTitle")
    .setText("Settings:")
    .setPosition(CONTROL_MARGIN, 120)
    .setColorValue(color(220))
    .setFont(createFont("Arial", 14))
    .moveTo(controlGroup);
    
  // Toggles for settings - first row
  cp5.addToggle("idleToggle")
    .setPosition(CONTROL_MARGIN, 150)
    .setSize(buttonWidth, 25)
    .setLabel("Idle Mode")
    .setValue(false)
    .moveTo(controlGroup);
    
  cp5.addToggle("gridToggle")
    .setPosition(CONTROL_MARGIN*2 + buttonWidth, 150)
    .setSize(buttonWidth, 25)
    .setLabel("Show Grid")
    .setValue(true)
    .moveTo(controlGroup);
    
  // Circle mask toggle was moved to Pattern Settings
    
  // Interval slider - made narrower like pattern sliders
  Slider intervalSlider = cp5.addSlider("updateInterval")
    .setPosition(CONTROL_MARGIN, 190)
    .setSize(SLIDER_WIDTH, 20)
    .setRange(100, 2000)
    .setValue(500)
    .setLabel("Update Interval (ms)")
    .moveTo(controlGroup);
  // Configure label after adding to group
  intervalSlider.getCaptionLabel().align(ControlP5.RIGHT_OUTSIDE, ControlP5.CENTER).setPaddingX(LABEL_OFFSET);
  
  // Circle mask radius slider was moved to Pattern Settings
    
  // Add hardware controls with better spacing
  
  // Add a title for Hardware group
  cp5.addTextlabel("hardwareTitle")
    .setText("Hardware Configuration:")
    .setPosition(CONTROL_MARGIN, 10)
    .setColorValue(color(220))
    .setFont(createFont("Arial", 14))
    .moveTo(hardwareGroup);
  
  // Mode selection toggle
  cp5.addToggle("simulationToggle")
    .setPosition(CONTROL_MARGIN, 40)
    .setSize(GROUP_WIDTH - CONTROL_MARGIN*2, 30)
    .setLabel("Simulation Mode")
    .setValue(true)
    .moveTo(hardwareGroup);
    
  // Connection section
  cp5.addTextlabel("connectionTitle")
    .setText("Arduino Connection:")
    .setPosition(CONTROL_MARGIN, 90)
    .setColorValue(color(220))
    .setFont(createFont("Arial", 14))
    .moveTo(hardwareGroup);
    
  // Serial port selection
  cp5.addScrollableList("serialPortsList")
    .setPosition(CONTROL_MARGIN, 120)
    .setSize(GROUP_WIDTH - CONTROL_MARGIN*2, 120)
    .setBarHeight(25)
    .setItemHeight(25)
    .setLabel("Serial Port")
    .moveTo(hardwareGroup);
    
  // Connection button
  cp5.addButton("connectButton")
    .setPosition(CONTROL_MARGIN, 250)
    .setSize(GROUP_WIDTH - CONTROL_MARGIN*2, 30)
    .setLabel("Connect to Hardware")
    .setColorBackground(color(0, 0, 120))
    .moveTo(hardwareGroup);
    
  // Upload button  
  cp5.addButton("uploadPatternButton")
    .setPosition(CONTROL_MARGIN, 290)
    .setSize(GROUP_WIDTH - CONTROL_MARGIN*2, 30)
    .setLabel("Upload Pattern to Hardware")
    .setColorBackground(color(0, 120, 120))
    .moveTo(hardwareGroup);
    
  // Create accordion
  accordion = cp5.addAccordion("acc")
    .setPosition(CONTROL_MARGIN, 40)
    .setWidth(GROUP_WIDTH)
    .addItem(patternGroup)
    .addItem(controlGroup)
    .addItem(hardwareGroup);
  
  // Open just the first panel by default, to avoid overlap
  accordion.open(0);
  
  // Change accordion mode to not allow multiple open panels
  accordion.setCollapseMode(Accordion.SINGLE);
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

public void circleMaskToggle(boolean value) {
  circleMaskMode = value;
  // Regenerate pattern when toggling circle mask mode
  regeneratePattern();
  generateIlluminationSequence();
}

public void controlEvent(ControlEvent event) {
  // Listen for parameter changes
  if (event.isController()) {
    String name = event.getController().getName();
    if (name.equals("innerRingRadius") || 
        name.equals("middleRingRadius") || 
        name.equals("outerRingRadius") || 
        name.equals("targetLedSpacingMM") ||
        name.equals("circleMaskRadius")) {
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
  
  // Apply circle mask if enabled
  if (circleMaskMode) {
    applyCircleMask(centerX, centerY);
  }
}

// Apply a circular mask to the pattern, only keeping LEDs within the specified radius
void applyCircleMask(int centerX, int centerY) {
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      // Calculate distance from center
      float dx = x - centerX;
      float dy = y - centerY;
      float distance = sqrt(dx*dx + dy*dy);
      
      // Disable LEDs outside the mask radius
      if (distance > circleMaskRadius) {
        ledPattern[y][x] = false;
      }
    }
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