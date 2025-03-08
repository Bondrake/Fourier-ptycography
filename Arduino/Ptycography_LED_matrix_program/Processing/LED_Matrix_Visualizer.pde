/**
 * LED Matrix Visualizer for Ptycography
 * 
 * This Processing sketch provides a dual-mode visualization system:
 * 1. Simulation Mode: Runs the LED pattern algorithm directly within Processing
 * 2. Hardware Mode: Connects to Arduino via serial to display real-time LED states
 * 
 * The sketch creates a window with a grid of colored squares representing the 64x64 LED matrix
 * Press 's' to toggle between simulation and hardware modes
 * Press 'p' to toggle between full pattern and center-only modes
 * Press space to pause/resume the animation
 * Press 'g' to toggle grid lines
 */

// Matrix dimensions
final int MATRIX_WIDTH = 64;
final int MATRIX_HEIGHT = 64;

// Display settings
final int CELL_SIZE = 8;          // Size of each LED in pixels 
final int GRID_PADDING_LEFT = 240; // Left padding for grid (moved to the right)
final int GRID_PADDING_TOP = 50;   // Top padding for grid
final int INFO_PANEL_WIDTH = 220;  // Width of the info panel on the left
boolean showGrid = true;           // Whether to show grid lines

// Pattern settings (same as Arduino code)
final int INNER_RING_RADIUS = 27;
final int MIDDLE_RING_RADIUS = 37;  
final int OUTER_RING_RADIUS = 47;
final float LED_PITCH_MM = 2.0;
final float TARGET_LED_SPACING_MM = 4.0;
int LED_SKIP;                     // Will be calculated in setup

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

final int COLOR_RED = 1;
final int COLOR_GREEN = 2;
final int COLOR_BLUE = 4;

// Operation modes
boolean simulationMode = true;    // true = simulation, false = hardware connection
boolean centerOnly = false;       // true = only show center LED, false = show full pattern
boolean running = true;           // true = animation running, false = paused
int currentLedX = -1;             // Current LED X coordinate
int currentLedY = -1;             // Current LED Y coordinate
int currentColor = COLOR_GREEN;   // Current LED color (default to green)

// Timing variables
int lastUpdateTime = 0;
final int UPDATE_INTERVAL = 500;  // Update interval in milliseconds

// Pattern storage
boolean[][] ledPattern;           // Full LED pattern
boolean[][] ledCenter;            // Center-only pattern

// Serial connection
import processing.serial.*;
Serial arduinoPort;
boolean serialConnected = false;
StringBuffer serialBuffer = new StringBuffer();
boolean receivingPattern = false;

void setup() {
  // Create window with appropriate size
  size(800, 600);  // Wider window with info panel and visualization side by side
  
  // Initialize the patterns
  ledPattern = new boolean[MATRIX_HEIGHT][MATRIX_WIDTH];
  ledCenter = new boolean[MATRIX_HEIGHT][MATRIX_WIDTH];
  
  // Calculate LED skip value based on spacing
  LED_SKIP = round(TARGET_LED_SPACING_MM / LED_PITCH_MM);
  if (LED_SKIP < 1) LED_SKIP = 1;
  
  // Initialize the patterns
  initializePatterns();
  
  // Set up the display
  background(0);
  frameRate(30);
  textSize(14);
  
  // Try to connect to Arduino (will be used in hardware mode)
  tryConnectToArduino();
  
  println("LED Matrix Visualizer");
  println("Press 's' to toggle between simulation and hardware modes");
  println("Press 'p' to toggle between full pattern and center-only modes");
  println("Press space to pause/resume the animation");
  println("Press 'g' to toggle grid lines");
}

void draw() {
  // Clear the background
  background(0);
  
  // Draw the mode indicator
  drawModeIndicator();
  
  // Draw the LED matrix
  drawLEDMatrix();
  
  // Update the simulation if running in simulation mode
  if (simulationMode && running) {
    updateSimulation();
  }
  
  // In hardware mode, we process serial data
  if (!simulationMode && serialConnected) {
    processSerialData();
  }
}

void drawModeIndicator() {
  // Draw the info panel background
  fill(40);
  noStroke();
  rect(0, 0, INFO_PANEL_WIDTH, height);
  
  // Draw panel title
  fill(200);
  textAlign(CENTER, TOP);
  textSize(16);
  text("LED MATRIX VISUALIZER", INFO_PANEL_WIDTH/2, 20);
  
  // Draw separator line
  stroke(100);
  line(10, 45, INFO_PANEL_WIDTH-10, 45);
  
  // Draw status information
  fill(255);
  textAlign(LEFT, TOP);
  textSize(14);
  
  String modeText = simulationMode ? "SIMULATION MODE" : "HARDWARE MODE";
  String patternText = centerOnly ? "CENTER ONLY" : "FULL PATTERN";
  String statusText = running ? "RUNNING" : "PAUSED";
  
  int yOffset = 60;
  text("Mode:", 20, yOffset);
  text(modeText, 120, yOffset);
  
  yOffset += 25;
  text("Pattern:", 20, yOffset);
  text(patternText, 120, yOffset);
  
  yOffset += 25;
  text("Status:", 20, yOffset);
  text(statusText, 120, yOffset);
  
  if (!simulationMode) {
    yOffset += 25;
    String connectionText = serialConnected ? "CONNECTED" : "NOT CONNECTED";
    text("Arduino:", 20, yOffset);
    text(connectionText, 120, yOffset);
  }
  
  // Draw separator line
  stroke(100);
  line(10, yOffset + 20, INFO_PANEL_WIDTH-10, yOffset + 20);
  
  // Display current LED position
  yOffset += 40;
  text("Current LED:", 20, yOffset);
  text("x = " + currentLedX, 20, yOffset + 25);
  text("y = " + currentLedY, 20, yOffset + 50);
  
  // Draw controls help
  yOffset = height - 150;
  stroke(100);
  line(10, yOffset - 10, INFO_PANEL_WIDTH-10, yOffset - 10);
  
  fill(200);
  text("CONTROLS:", 20, yOffset);
  fill(255);
  text("s - Toggle simulation/hardware", 20, yOffset + 25);
  text("p - Toggle pattern mode", 20, yOffset + 50);
  text("Space - Pause/resume", 20, yOffset + 75);
  text("g - Toggle grid", 20, yOffset + 100);
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
      if ((currentLedX != x || currentLedY != y) || !running) {
        // Check if this LED is part of the pattern
        boolean isInPattern = centerOnly ? ledCenter[y][x] : ledPattern[y][x];
        if (isInPattern) {
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

void keyPressed() {
  // Toggle simulation/hardware modes
  if (key == 's' || key == 'S') {
    simulationMode = !simulationMode;
    if (!simulationMode && !serialConnected) {
      tryConnectToArduino();
    }
  }
  
  // Toggle pattern mode
  if (key == 'p' || key == 'P') {
    centerOnly = !centerOnly;
  }
  
  // Toggle pause/resume
  if (key == ' ') {
    running = !running;
  }
  
  // Toggle grid lines
  if (key == 'g' || key == 'G') {
    showGrid = !showGrid;
  }
  
  // Reinitialize patterns
  if (key == 'r' || key == 'R') {
    initializePatterns();
  }
  
  // Send commands to Arduino in hardware mode
  if (!simulationMode && serialConnected) {
    if (key == 'v' || key == 'V') {
      arduinoPort.write('v');  // Start visualization mode
    } else if (key == 'q' || key == 'Q') {
      arduinoPort.write('q');  // Stop visualization mode
    } else if (key == 'i' || key == 'I') {
      arduinoPort.write('i');  // Enter idle mode
    } else if (key == 'a' || key == 'A') {
      arduinoPort.write('a');  // Exit idle mode
    }
  }
}

void initializePatterns() {
  // Clear the patterns
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      ledPattern[y][x] = false;
      ledCenter[y][x] = false;
    }
  }
  
  // Set center LED
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  ledCenter[centerY][centerX] = true;
  
  // Generate the pattern
  int ledCount = 0;
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      // Calculate distance from center (Pythagorean theorem)
      float dx = x - centerX;
      float dy = y - centerY;
      float distance = sqrt(dx*dx + dy*dy);
      
      // Check if this LED falls on one of our rings with appropriate spacing
      if (((x + y) % LED_SKIP == 0) && 
          (abs(distance - INNER_RING_RADIUS) < 1.0 || 
           abs(distance - MIDDLE_RING_RADIUS) < 1.0 || 
           abs(distance - OUTER_RING_RADIUS) < 1.0)) {
        ledPattern[y][x] = true;
        ledCount++;
      }
    }
  }
  
  println("Pattern initialized with " + ledCount + " LEDs");
  println("LED skip: " + LED_SKIP + " (physical spacing: " + (LED_SKIP * LED_PITCH_MM) + "mm)");
}

void updateSimulation() {
  // Only update at specified intervals
  if (millis() - lastUpdateTime < UPDATE_INTERVAL) {
    return;
  }
  lastUpdateTime = millis();
  
  // Find the next LED to illuminate based on the pattern
  boolean foundNext = false;
  
  // Start searching from current position
  int startX = currentLedX;
  int startY = currentLedY;
  
  // If we're at the beginning or end, start from the beginning
  if (startX < 0 || startY < 0) {
    startX = 0;
    startY = 0;
  } else {
    // Move to the next position
    startX++;
    if (startX >= MATRIX_WIDTH) {
      startX = 0;
      startY++;
      if (startY >= MATRIX_HEIGHT) {
        startY = 0; // Wrap around to the beginning
      }
    }
  }
  
  // Search for the next LED in the pattern
  for (int y = startY; y < MATRIX_HEIGHT && !foundNext; y++) {
    for (int x = (y == startY ? startX : 0); x < MATRIX_WIDTH && !foundNext; x++) {
      boolean isInPattern = centerOnly ? ledCenter[y][x] : ledPattern[y][x];
      if (isInPattern) {
        currentLedX = x;
        currentLedY = y;
        foundNext = true;
      }
    }
  }
  
  // If we didn't find anything starting from current position,
  // search from the beginning (in case we're in the middle of the matrix)
  if (!foundNext && startY > 0) {
    for (int y = 0; y <= startY && !foundNext; y++) {
      for (int x = 0; x < (y == startY ? startX : MATRIX_WIDTH) && !foundNext; x++) {
        boolean isInPattern = centerOnly ? ledCenter[y][x] : ledPattern[y][x];
        if (isInPattern) {
          currentLedX = x;
          currentLedY = y;
          foundNext = true;
        }
      }
    }
  }
  
  // If we still didn't find anything, reset to the beginning
  if (!foundNext) {
    currentLedX = -1;
    currentLedY = -1;
  }
}

void tryConnectToArduino() {
  // Attempt to connect to the Arduino
  println("Available serial ports:");
  printArray(Serial.list());
  
  // Try to connect to the first available port
  if (Serial.list().length > 0) {
    try {
      arduinoPort = new Serial(this, Serial.list()[0], 9600);
      arduinoPort.bufferUntil('\n');
      serialConnected = true;
      println("Connected to: " + Serial.list()[0]);
    } catch (Exception e) {
      println("Failed to connect: " + e.getMessage());
      serialConnected = false;
    }
  } else {
    println("No serial ports available");
    serialConnected = false;
  }
}

void serialEvent(Serial port) {
  // Process incoming serial data
  String data = port.readStringUntil('\n');
  if (data != null) {
    data = data.trim();
    
    // Check for pattern data
    if (data.equals("PATTERN_START")) {
      receivingPattern = true;
      // Clear existing pattern before receiving new one
      for (int y = 0; y < MATRIX_HEIGHT; y++) {
        for (int x = 0; x < MATRIX_WIDTH; x++) {
          ledPattern[y][x] = false;
        }
      }
      return;
    } else if (data.equals("PATTERN_END")) {
      receivingPattern = false;
      return;
    }
    
    if (receivingPattern) {
      if (data.startsWith("PATTERN,")) {
        String[] parts = data.substring(8).split(",");
        if (parts.length == 2) {
          try {
            int x = Integer.parseInt(parts[0]);
            int y = Integer.parseInt(parts[1]);
            if (x >= 0 && x < MATRIX_WIDTH && y >= 0 && y < MATRIX_HEIGHT) {
              ledPattern[y][x] = true;
            }
          } catch (Exception e) {
            println("Error parsing pattern data: " + e.getMessage());
          }
        }
      }
    } else if (data.startsWith("LED,")) {
      String[] parts = data.substring(4).split(",");
      if (parts.length == 3) {
        try {
          int x = Integer.parseInt(parts[0]);
          int y = Integer.parseInt(parts[1]);
          int colorValue = Integer.parseInt(parts[2]);
          
          // Update the current LED
          currentLedX = x;
          currentLedY = y;
          currentColor = colorValue;
        } catch (Exception e) {
          println("Error parsing LED data: " + e.getMessage());
        }
      }
    }
  }
}

void processSerialData() {
  // This is called from draw() to handle any buffered serial data
  // The actual processing happens in the serialEvent method
}