/**
 * MatrixView.pde
 * 
 * Responsible for visualizing the LED matrix.
 * Draws the LED grid, coordinates, and current LED state.
 * Implements both PatternObserver and StateObserver interfaces to update on changes.
 */

class MatrixView implements PatternObserver, StateObserver, CameraObserver {
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
  private final color OFF_COLOR = color(20);
  private final color RED_COLOR = color(255, 0, 0);
  private final color GREEN_COLOR = color(0, 255, 0);
  private final color BLUE_COLOR = color(0, 0, 255);
  private final color YELLOW_COLOR = color(255, 255, 0);
  private final color MAGENTA_COLOR = color(255, 0, 255);
  private final color CYAN_COLOR = color(0, 255, 255);
  private final color WHITE_COLOR = color(255, 255, 255);
  private final color PATTERN_COLOR = color(0, 100, 0);
  
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
    
    // Register as observer
    patternModel.addObserver(this);
    stateModel.addObserver(this);
    cameraModel.addObserver(this);
    
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
    // Determine the maximum size that fits in the available space
    int availableWidth = width - gridX - 40;
    int availableHeight = height - gridY - 40;
    
    int maxCellSize = min(availableWidth / MATRIX_WIDTH, availableHeight / MATRIX_HEIGHT);
    
    // Use preferred size if smaller, otherwise use maximum available
    dynamicCellSize = min(preferredCellSize, maxCellSize);
    
    // Calculate total matrix dimensions
    matrixWidth = MATRIX_WIDTH * dynamicCellSize;
    matrixHeight = MATRIX_HEIGHT * dynamicCellSize;
  }
  
  /**
   * Observer callback for pattern changes
   */
  public void onPatternChanged() {
    // Pattern has changed, will be reflected in next draw
  }
  
  /**
   * Observer callback for state changes
   */
  public void onStateChanged() {
    // State has changed, will be reflected in next draw
  }
  
  /**
   * Observer callback for camera status changes
   */
  public void onCameraStatusChanged() {
    // Camera status has changed, will be reflected in next draw
  }
  
  /**
   * Set grid visibility
   */
  public void setShowGrid(boolean show) {
    showGrid = show;
  }
  
  /**
   * Draw the LED matrix visualization
   */
  public void draw() {
    calculateDimensions();  // Recalculate dimensions in case window size changed
    
    // Draw background
    noStroke();
    fill(10);
    rect(gridX, gridY, matrixWidth, matrixHeight);
    
    // Draw LED pattern
    for (int y = 0; y < MATRIX_HEIGHT; y++) {
      for (int x = 0; x < MATRIX_WIDTH; x++) {
        // Calculate cell position
        int cellX = gridX + x * dynamicCellSize;
        int cellY = gridY + y * dynamicCellSize;
        
        // Determine cell color based on pattern and current LED position
        color cellColor;
        
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
  private color getLedColor(int colorCode) {
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