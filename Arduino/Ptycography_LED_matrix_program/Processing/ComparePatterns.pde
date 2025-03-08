/**
 * Pattern Comparison Visualizer
 * 
 * This Processing sketch compares the original LED pattern with the new resized pattern
 * that fits within the 64x64 matrix bounds. It shows both patterns side by side
 * for direct visual comparison.
 */

// Matrix dimensions
final int MATRIX_WIDTH = 64;
final int MATRIX_HEIGHT = 64;

// Display settings
final int CELL_SIZE = 6;             // Smaller cells to fit both patterns
final int GRID_PADDING = 50;
final int SPACING = 40;              // Space between the two patterns
boolean showGrid = true;

// Color definitions
final color OFF_COLOR = color(20);
final color ON_COLOR = color(0, 255, 0);   // Green for active LEDs
final color CENTER_COLOR = color(255, 0, 0); // Red for center LED
final color GRID_COLOR = color(60);

// Pattern arrays
boolean[][] originalPattern;
boolean[][] resizedPattern;

void setup() {
  // Create window with appropriate size to fit both patterns
  size(900, 600);
  
  // Set up the display
  background(0);
  frameRate(30);
  textSize(14);
  
  // Generate the patterns
  originalPattern = generateOriginalPattern();
  resizedPattern = generateResizedPattern();
  
  println("Pattern Comparison Visualizer");
  println("Press 'g' to toggle grid lines");
  println("Press 's' to save the comparison as an image");
}

void draw() {
  // Clear the background
  background(0);
  
  // Draw title
  fill(255);
  textAlign(CENTER, TOP);
  textSize(20);
  text("LED Pattern Comparison", width/2, 10);
  
  // Calculate starting positions for both patterns
  int totalWidth = (MATRIX_WIDTH * CELL_SIZE * 2) + SPACING;
  int startX = (width - totalWidth) / 2;
  int gridY = GRID_PADDING + 30;
  
  // Draw original pattern
  drawPattern(originalPattern, startX, gridY, "Original Pattern (27, 37, 47)");
  
  // Draw resized pattern
  int resizedX = startX + (MATRIX_WIDTH * CELL_SIZE) + SPACING;
  drawPattern(resizedPattern, resizedX, gridY, "Resized Pattern (16, 24, 31)");
  
  // Draw explanation text
  textAlign(CENTER, BOTTOM);
  fill(200);
  textSize(14);
  text("The original pattern used larger rings (27, 37, 47) that extended beyond the matrix boundaries.", width/2, height - 40);
  text("The resized pattern (16, 24, 31) keeps all rings within the 64x64 matrix bounds.", width/2, height - 20);
}

void drawPattern(boolean[][] pattern, int gridX, int gridY, String title) {
  // Draw pattern title
  fill(255);
  textAlign(CENTER, TOP);
  textSize(16);
  text(title, gridX + (MATRIX_WIDTH * CELL_SIZE / 2), gridY - 25);
  
  // Draw grid background
  noStroke();
  fill(30);
  rect(gridX - 1, gridY - 1, MATRIX_WIDTH * CELL_SIZE + 2, MATRIX_HEIGHT * CELL_SIZE + 2);
  
  // Draw each LED cell
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      // Determine cell color based on pattern
      color cellColor = OFF_COLOR;
      if (pattern[y][x]) {
        cellColor = (x == centerX && y == centerY) ? CENTER_COLOR : ON_COLOR;
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
    stroke(GRID_COLOR);
    // Draw vertical lines
    for (int x = 0; x <= MATRIX_WIDTH; x += 8) {
      line(gridX + x * CELL_SIZE, gridY, gridX + x * CELL_SIZE, gridY + MATRIX_HEIGHT * CELL_SIZE);
    }
    // Draw horizontal lines
    for (int y = 0; y <= MATRIX_HEIGHT; y += 8) {
      line(gridX, gridY + y * CELL_SIZE, gridX + MATRIX_WIDTH * CELL_SIZE, gridY + y * CELL_SIZE);
    }
    
    // Draw maximum radius circle (32)
    noFill();
    stroke(color(255, 255, 0, 80)); // Semi-transparent yellow
    float maxRadius = 32 * CELL_SIZE;
    ellipse(gridX + centerX * CELL_SIZE + CELL_SIZE/2, 
           gridY + centerY * CELL_SIZE + CELL_SIZE/2, 
           maxRadius * 2, maxRadius * 2);
  }
}

boolean[][] generateOriginalPattern() {
  // Initialize a 64x64 matrix
  boolean[][] pattern = new boolean[MATRIX_HEIGHT][MATRIX_WIDTH];
  
  // Define the ring radii from the original code
  int innerRadius = 27;
  int middleRadius = 37;
  int outerRadius = 47;
  
  // Get center coordinates
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Set center LED
  pattern[centerY][centerX] = true;
  
  // Generate the ring pattern
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      // Skip LEDs based on spacing
      if ((x + y) % 2 != 0) continue;
      
      // Calculate distance from center
      float dx = x - centerX;
      float dy = y - centerY;
      float distance = sqrt(dx*dx + dy*dy);
      
      // Check if this LED falls on one of our rings
      if (abs(distance - innerRadius) < 1.0 || 
          abs(distance - middleRadius) < 1.0 || 
          abs(distance - outerRadius) < 1.0) {
        pattern[y][x] = true;
      }
    }
  }
  
  return pattern;
}

boolean[][] generateResizedPattern() {
  // Initialize a 64x64 matrix
  boolean[][] pattern = new boolean[MATRIX_HEIGHT][MATRIX_WIDTH];
  
  // Define the ring radii from our config
  int innerRadius = 16;
  int middleRadius = 24;
  int outerRadius = 31;
  
  // Get center coordinates
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Set center LED
  pattern[centerY][centerX] = true;
  
  // Generate the ring pattern
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      // Skip LEDs based on spacing
      if ((x + y) % 2 != 0) continue;
      
      // Calculate distance from center
      float dx = x - centerX;
      float dy = y - centerY;
      float distance = sqrt(dx*dx + dy*dy);
      
      // Check if this LED falls on one of our rings
      if (abs(distance - innerRadius) < 1.0 || 
          abs(distance - middleRadius) < 1.0 || 
          abs(distance - outerRadius) < 1.0) {
        pattern[y][x] = true;
      }
    }
  }
  
  return pattern;
}

void keyPressed() {
  // Toggle grid lines
  if (key == 'g' || key == 'G') {
    showGrid = !showGrid;
  }
  
  // Save the pattern as an image
  if (key == 's' || key == 'S') {
    String filename = "pattern_comparison_" + year() + month() + day() + hour() + minute() + second() + ".png";
    save(filename);
    println("Comparison saved as: " + filename);
  }
}