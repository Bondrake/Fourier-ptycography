/**
 * MatrixView.pde
 * 
 * Responsible for visualizing the LED matrix.
 * Draws the LED grid, coordinates, and current LED state.
 * Uses the event system to update on changes.
 */

class MatrixView extends EventDispatcher {
  // Matrix dimensions
  private final int MATRIX_WIDTH;
  private final int MATRIX_HEIGHT;
  
  // Models
  private PatternModel patternModel;
  private SystemStateModel stateModel;
  private CameraModel cameraModel;
  
  // Display properties
  private int gridX;
  private int gridY;
  private int preferredCellSize;
  private int dynamicCellSize;
  private int matrixWidth;
  private int matrixHeight;
  private boolean showGrid = true;
  
  // Colors
  private final int OFF_COLOR = color(20);
  private final int RED_COLOR = color(255, 0, 0);
  private final int GREEN_COLOR = color(0, 255, 0);
  private final int BLUE_COLOR = color(0, 0, 255);
  private final int YELLOW_COLOR = color(255, 255, 0);
  private final int MAGENTA_COLOR = color(255, 0, 255);
  private final int CYAN_COLOR = color(0, 255, 255);
  private final int WHITE_COLOR = color(255, 255, 255);
  private final int PATTERN_COLOR = color(0, 100, 0);
  
  // Color constants for bitwise operations
  private final int COLOR_RED = 1;
  private final int COLOR_GREEN = 2;
  private final int COLOR_BLUE = 4;
  
  /**
   * Constructor with models
   */
  public MatrixView(PatternModel patternModel, SystemStateModel stateModel, CameraModel cameraModel, 
                  int gridX, int gridY, int preferredCellSize) {
    this.patternModel = patternModel;
    this.stateModel = stateModel;
    this.cameraModel = cameraModel;
    this.gridX = gridX;
    this.gridY = gridY;
    this.preferredCellSize = preferredCellSize;
    
    // Register for events
    registerEvent(EventType.PATTERN_CHANGED);
    registerEvent(EventType.STATE_CHANGED);
    registerEvent(EventType.CAMERA_STATUS_CHANGED);
    
    // Get dimensions from model
    MATRIX_WIDTH = patternModel.getMatrixWidth();
    MATRIX_HEIGHT = patternModel.getMatrixHeight();
    
    // Calculate cell size and dimensions
    calculateDimensions();
  }
  
  /**
   * Calculate cell size and dimensions based on available space
   */
  private void calculateDimensions() {
    // Available space calculation - the matrix should be centered in its own area
    int availableHeight = height - gridY - 40;
    
    // For width, we know the matrix should be in the main content area (right side)
    // and should not go past the right edge of the window
    int availableWidth = width - (gridX + 40);
    
    // Calculate maximum cell size that fits in the available space
    int maxCellSize = min(availableWidth / MATRIX_WIDTH, availableHeight / MATRIX_HEIGHT);
    
    // Use preferred size if smaller, otherwise use maximum available
    dynamicCellSize = min(preferredCellSize, maxCellSize);
    
    // Calculate total matrix dimensions
    matrixWidth = MATRIX_WIDTH * dynamicCellSize;
    matrixHeight = MATRIX_HEIGHT * dynamicCellSize;
  }
  
  /**
   * Handle incoming events
   */
  @Override
  public void handleEvent(String eventType, EventData data) {
    // For now, we don't need to do anything special for different events
    // Just let the draw() method handle visualization
  }
  
  /**
   * Set grid visibility
   */
  public void setShowGrid(boolean show) {
    showGrid = show;
  }
  
  /**
   * Check if grid is visible
   */
  public boolean isShowGrid() {
    return showGrid;
  }
  
  /**
   * Draw the LED matrix visualization
   */
  public void draw() {
    calculateDimensions();  // Recalculate dimensions in case window size changed
    
    // Draw matrix background and title
    noStroke();
    fill(20);
    rect(gridX - 10, gridY - 30, matrixWidth + 20, matrixHeight + 60);
    
    // Draw matrix title
    fill(200);
    textAlign(CENTER, TOP);
    textSize(14);
    text("64x64 RGB LED MATRIX", gridX + matrixWidth / 2, gridY - 25);
    
    // Draw LED pattern
    for (int y = 0; y < MATRIX_HEIGHT; y++) {
      for (int x = 0; x < MATRIX_WIDTH; x++) {
        // Calculate cell position
        int cellX = gridX + x * dynamicCellSize;
        int cellY = gridY + y * dynamicCellSize;
        
        // Determine cell color based on pattern and current LED position
        int cellColor;
        
        if (stateModel.getCurrentLedX() == x && stateModel.getCurrentLedY() == y) {
          // Current LED - use the color from state model
          cellColor = getLedColor(stateModel.getCurrentColor());
        } else if (patternModel.isLedActive(x, y)) {
          // Part of pattern but not current LED
          cellColor = PATTERN_COLOR;
        } else {
          // Inactive LED
          cellColor = OFF_COLOR;
        }
        
        // Draw cell
        fill(cellColor);
        rect(cellX, cellY, dynamicCellSize, dynamicCellSize);
      }
    }
    
    // Draw grid lines if enabled
    if (showGrid) {
      stroke(60);
      // Draw vertical lines
      for (int x = 0; x <= MATRIX_WIDTH; x += 8) {
        line(gridX + x * dynamicCellSize, gridY, gridX + x * dynamicCellSize, gridY + matrixHeight);
      }
      // Draw horizontal lines
      for (int y = 0; y <= MATRIX_HEIGHT; y += 8) {
        line(gridX, gridY + y * dynamicCellSize, gridX + matrixWidth, gridY + y * dynamicCellSize);
      }
    }
    
    // Draw camera trigger indicator in matrix corner when enabled
    if (cameraModel.isEnabled()) {
      int indicatorSize = 12;
      int indicatorX = gridX + matrixWidth - indicatorSize - 8;
      int indicatorY = gridY + 8;
      
      // Draw camera indicator background
      noStroke();
      fill(40);
      rect(indicatorX, indicatorY, indicatorSize, indicatorSize);
      
      // Draw camera status indicator
      if (cameraModel.isTriggerActive()) {
        // Show active trigger with red circle
        fill(255, 0, 0);
        ellipse(indicatorX + indicatorSize/2, indicatorY + indicatorSize/2, indicatorSize-2, indicatorSize-2);
      } else if (cameraModel.hasError()) {
        // Show error with yellow triangle
        fill(255, 255, 0);
        triangle(
          indicatorX + indicatorSize/2, indicatorY + 1,
          indicatorX + 1, indicatorY + indicatorSize - 1,
          indicatorX + indicatorSize - 1, indicatorY + indicatorSize - 1
        );
      } else if (cameraModel.getLastTriggerTime() > 0 && 
                (millis() - cameraModel.getLastTriggerTime() < 1000)) {
        // Show recent trigger with fading green circle
        float alpha = map(millis() - cameraModel.getLastTriggerTime(), 0, 1000, 255, 0);
        fill(0, 255, 0, alpha);
        ellipse(indicatorX + indicatorSize/2, indicatorY + indicatorSize/2, indicatorSize-2, indicatorSize-2);
      }
    }
    
    // Draw coordinates
    fill(150);
    textSize(10);
    textAlign(CENTER, TOP);
    
    // Draw x-axis coordinates (only every 8 for clarity)
    for (int x = 0; x < MATRIX_WIDTH; x += 8) {
      text(str(x), gridX + x * dynamicCellSize + dynamicCellSize/2, gridY + matrixHeight + 5);
    }
    
    // Draw y-axis coordinates (only every 8 for clarity)
    textAlign(RIGHT, CENTER);
    for (int y = 0; y < MATRIX_HEIGHT; y += 8) {
      text(str(y), gridX - 5, gridY + y * dynamicCellSize + dynamicCellSize/2);
    }
  }
  
  /**
   * Convert color code to actual color
   */
  private int getLedColor(int colorCode) {
    switch(colorCode) {
      case COLOR_RED:
        return RED_COLOR;
      case COLOR_GREEN:
        return GREEN_COLOR;
      case COLOR_BLUE:
        return BLUE_COLOR;
      case COLOR_RED | COLOR_GREEN:
        return YELLOW_COLOR;
      case COLOR_RED | COLOR_BLUE:
        return MAGENTA_COLOR;
      case COLOR_GREEN | COLOR_BLUE:
        return CYAN_COLOR;
      case COLOR_RED | COLOR_GREEN | COLOR_BLUE:
        return WHITE_COLOR;
      default:
        return PATTERN_COLOR;
    }
  }
  
  // Getters for matrix dimensions
  
  public int getMatrixWidth() {
    return matrixWidth;
  }
  
  public int getMatrixHeight() {
    return matrixHeight;
  }
  
  public int getGridX() {
    return gridX;
  }
  
  public int getGridY() {
    return gridY;
  }
  
  public int getCellSize() {
    return dynamicCellSize;
  }
}