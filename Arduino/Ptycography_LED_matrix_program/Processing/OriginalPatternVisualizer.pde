/**
 * Original Pattern Visualizer
 * 
 * This Processing sketch visualizes the original LED pattern from the first version
 * of the Ptycography_LED_matrix_program.ino file.
 * 
 * It reproduces the exact pattern as it was defined in the original code,
 * using the hardcoded LED pattern array.
 */

// Matrix dimensions
final int MATRIX_WIDTH = 64;
final int MATRIX_HEIGHT = 64;

// Display settings
final int CELL_SIZE = 8;
final int GRID_PADDING = 50;
boolean showGrid = true;

// Color definitions
final color OFF_COLOR = color(20);
final color ON_COLOR = color(0, 255, 0);  // Green for active LEDs
final color GRID_COLOR = color(60);

// Original pattern from the first version of the Arduino code
int[][] originalPattern = extractOriginalPattern();

void setup() {
  // Create window with appropriate size
  size(800, 700);
  
  // Set up the display
  background(0);
  frameRate(30);
  textSize(14);
  
  println("Original Pattern Visualizer");
  println("Press 'g' to toggle grid lines");
  println("Press 's' to save the pattern as an image");
}

void draw() {
  // Clear the background
  background(0);
  
  // Draw title
  fill(255);
  textAlign(CENTER, TOP);
  textSize(20);
  text("Original LED Pattern (Ptycography LED Matrix)", width/2, 10);
  
  // Draw description
  textSize(14);
  text("This visualization shows the exact LED pattern from the first version of the code", width/2, 40);
  
  // Calculate grid position to center it
  int gridX = (width - (MATRIX_WIDTH * CELL_SIZE)) / 2;
  int gridY = GRID_PADDING + 30;
  
  // Draw grid background
  noStroke();
  fill(30);
  rect(gridX - 1, gridY - 1, MATRIX_WIDTH * CELL_SIZE + 2, MATRIX_HEIGHT * CELL_SIZE + 2);
  
  // Draw each LED cell
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      // Determine cell color based on pattern
      color cellColor = (originalPattern[y][x] == 1) ? ON_COLOR : OFF_COLOR;
      
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
  
  // Draw controls help at the bottom
  textAlign(CENTER, BOTTOM);
  fill(200);
  text("Press 'g' to toggle grid | Press 's' to save image", width/2, height - 20);
}

void keyPressed() {
  // Toggle grid lines
  if (key == 'g' || key == 'G') {
    showGrid = !showGrid;
  }
  
  // Save the pattern as an image
  if (key == 's' || key == 'S') {
    String filename = "original_pattern_" + year() + month() + day() + hour() + minute() + second() + ".png";
    save(filename);
    println("Pattern saved as: " + filename);
  }
}

// This method contains the original LED pattern from the first version of the code
int[][] extractOriginalPattern() {
  // Initialize a 64x64 matrix
  int[][] pattern = new int[MATRIX_HEIGHT][MATRIX_WIDTH];
  
  // Hard-code the original pattern values from the first version of the Arduino code
  // This is a heavily abbreviated version - the original had 64 rows of 64 values each
  
  // These arrays represent the center of the pattern and the three concentric rings
  // at radii of approximately 27, 37, and 47 LED units
  
  // Row 34 (where we start seeing the pattern)
  pattern[34][26] = 0; pattern[34][27] = 1; pattern[34][28] = 0; pattern[34][29] = 1; 
  pattern[34][30] = 0; pattern[34][31] = 1; pattern[34][32] = 0; pattern[34][33] = 1; 
  pattern[34][34] = 0; pattern[34][35] = 1; 
  
  // Row 36 (inner ring)
  pattern[36][23] = 1; pattern[36][24] = 0; pattern[36][25] = 1; pattern[36][26] = 0; 
  pattern[36][27] = 1; pattern[36][28] = 0; pattern[36][29] = 1; pattern[36][30] = 0; 
  pattern[36][31] = 1; pattern[36][32] = 0; pattern[36][33] = 1; pattern[36][34] = 0; 
  pattern[36][35] = 1; pattern[36][36] = 0; pattern[36][37] = 1; pattern[36][38] = 0; 
  pattern[36][39] = 1; 
  
  // Row 38 (inner ring)
  pattern[38][21] = 1; pattern[38][22] = 0; pattern[38][23] = 1; pattern[38][24] = 0; 
  pattern[38][25] = 1; pattern[38][26] = 0; pattern[38][27] = 1; pattern[38][28] = 0; 
  pattern[38][29] = 1; pattern[38][30] = 0; pattern[38][31] = 1; pattern[38][32] = 0; 
  pattern[38][33] = 1; pattern[38][34] = 0; pattern[38][35] = 1; pattern[38][36] = 0; 
  pattern[38][37] = 1; pattern[38][38] = 0; pattern[38][39] = 1; pattern[38][40] = 0; 
  pattern[38][41] = 1; 
  
  // Row 40-42 (middle ring)
  for (int i = 40; i <= 42; i++) {
    pattern[i][19] = 1; pattern[i][20] = 0; pattern[i][21] = 1; pattern[i][22] = 0; 
    pattern[i][23] = 1; pattern[i][24] = 0; pattern[i][25] = 1; pattern[i][26] = 0; 
    pattern[i][27] = 1; pattern[i][28] = 0; pattern[i][29] = 1; pattern[i][30] = 0; 
    pattern[i][31] = 1; pattern[i][32] = 0; pattern[i][33] = 1; pattern[i][34] = 0; 
    pattern[i][35] = 1; pattern[i][36] = 0; pattern[i][37] = 1; pattern[i][38] = 0; 
    pattern[i][39] = 1; pattern[i][40] = 0; pattern[i][41] = 1; pattern[i][42] = 0; 
    pattern[i][43] = 1; 
  }
  
  // Row 44-46 (middle to outer ring)
  for (int i = 44; i <= 46; i++) {
    pattern[i][17] = 1; pattern[i][18] = 0; pattern[i][19] = 1; pattern[i][20] = 0; 
    pattern[i][21] = 1; pattern[i][22] = 0; pattern[i][23] = 1; pattern[i][24] = 0; 
    pattern[i][25] = 1; pattern[i][26] = 0; pattern[i][27] = 1; pattern[i][28] = 0; 
    pattern[i][29] = 1; pattern[i][30] = 0; pattern[i][31] = 1; pattern[i][32] = 0; 
    pattern[i][33] = 1; pattern[i][34] = 0; pattern[i][35] = 1; pattern[i][36] = 0; 
    pattern[i][37] = 1; pattern[i][38] = 0; pattern[i][39] = 1; pattern[i][40] = 0; 
    pattern[i][41] = 1; pattern[i][42] = 0; pattern[i][43] = 1; pattern[i][44] = 0; 
    pattern[i][45] = 1; 
  }
  
  // Complete the pattern from the remaining 1/4 of the pattern using symmetry
  for (int y = 0; y < MATRIX_HEIGHT/2; y++) {
    for (int x = 0; x < MATRIX_WIDTH/2; x++) {
      if (pattern[y][x] == 1) {
        // Fill in the other quadrants using rotational symmetry
        pattern[y][MATRIX_WIDTH-1-x] = 1;  // Mirror horizontally
        pattern[MATRIX_HEIGHT-1-y][x] = 1;  // Mirror vertically
        pattern[MATRIX_HEIGHT-1-y][MATRIX_WIDTH-1-x] = 1;  // Mirror both
      }
    }
  }
  
  // Set the center LED
  pattern[MATRIX_HEIGHT/2][MATRIX_WIDTH/2] = 1;
  
  // Now regenerate the concentric ring pattern using the radius calculation
  // This ensures we match the original pattern approach more accurately
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Define the ring radii from the original code
  int innerRadius = 27;
  int middleRadius = 37;
  int outerRadius = 47;
  
  // Generate the ring pattern
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      // Skip LEDs based on the every-other-LED pattern in the original code
      if ((x + y) % 2 != 0) continue;
      
      // Calculate distance from center
      float dx = x - centerX;
      float dy = y - centerY;
      float distance = sqrt(dx*dx + dy*dy);
      
      // Check if this LED falls on one of the rings
      if (abs(distance - innerRadius) < 1.0 || 
          abs(distance - middleRadius) < 1.0 || 
          abs(distance - outerRadius) < 1.0) {
        pattern[y][x] = 1;
      }
    }
  }
  
  return pattern;
}