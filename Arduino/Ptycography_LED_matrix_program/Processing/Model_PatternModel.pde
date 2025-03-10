/**
 * PatternModel.pde
 * 
 * Responsible for generating and managing LED patterns.
 * Abstracts the pattern generation algorithm from the visualization.
 * 
 * This model will be a prime candidate for porting to Rust in the future Tauri migration.
 */

class PatternModel extends EventDispatcher {
  // Pattern types
  public static final int PATTERN_CONCENTRIC_RINGS = 0;
  public static final int PATTERN_CENTER_ONLY = 1;
  public static final int PATTERN_SPIRAL = 2;
  public static final int PATTERN_GRID = 3;
  
  // Pattern properties
  private int matrixWidth;
  private int matrixHeight;
  private int patternType = PATTERN_GRID;  // Default pattern
  private boolean[][] ledPattern;
  private ArrayList<PVector> illuminationSequence;
  
  // Pattern parameters
  private int innerRingRadius = 16;
  private int middleRingRadius = 24;
  private int outerRingRadius = 31;
  private int spiralMaxRadius = 30;
  private int spiralTurns = 3;
  private int gridSpacing = 2;
  private int gridPointSize = 1;
  private int gridOffsetX = 0;
  private int gridOffsetY = 0;
  private boolean circleMaskMode = true;
  private int circleMaskRadius = 19;
  
  /**
   * Constructor
   */
  public PatternModel(int width, int height) {
    this.matrixWidth = width;
    this.matrixHeight = height;
    this.ledPattern = new boolean[height][width];
    this.illuminationSequence = new ArrayList<PVector>();
    generatePattern();
  }
  
  /**
   * Generate the LED pattern based on current settings
   */
  public void generatePattern() {
    // Clear the pattern
    for (int y = 0; y < matrixHeight; y++) {
      for (int x = 0; x < matrixWidth; x++) {
        ledPattern[y][x] = false;
      }
    }
    
    // Generate pattern based on type
    switch (patternType) {
      case PATTERN_CONCENTRIC_RINGS:
        generateConcentricRings();
        break;
        
      case PATTERN_CENTER_ONLY:
        generateCenterOnly();
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
      applyCircleMask();
    }
    
    // Generate the illumination sequence
    generateIlluminationSequence();
    
    // Notify about pattern change
    publishEvent(EventType.PATTERN_CHANGED);
  }
  
  /**
   * Generate a concentric rings pattern
   */
  private void generateConcentricRings() {
    // Get center coordinates
    int centerX = matrixWidth / 2;
    int centerY = matrixHeight / 2;
    
    // Set the center LED
    ledPattern[centerY][centerX] = true;
    
    // Generate the ring pattern
    for (int y = 0; y < matrixHeight; y++) {
      for (int x = 0; x < matrixWidth; x++) {
        // Skip LEDs based on spacing
        if ((x + y) % gridSpacing != 0) continue;
        
        // Calculate distance from center
        float dx = x - centerX;
        float dy = y - centerY;
        float distance = sqrt(dx*dx + dy*dy);
        
        // Check if this LED falls on one of our rings
        if (abs(distance - innerRingRadius) < 0.5 || 
            abs(distance - middleRingRadius) < 0.5 || 
            abs(distance - outerRingRadius) < 0.5) {
          ledPattern[y][x] = true;
        }
      }
    }
  }
  
  /**
   * Generate a center-only pattern
   */
  private void generateCenterOnly() {
    // Just set the center LED
    int centerX = matrixWidth / 2;
    int centerY = matrixHeight / 2;
    ledPattern[centerY][centerX] = true;
  }
  
  /**
   * Generate a spiral pattern
   */
  private void generateSpiral() {
    // Get center coordinates
    int centerX = matrixWidth / 2;
    int centerY = matrixHeight / 2;
    
    // Set the center LED
    ledPattern[centerY][centerX] = true;
    
    // Maximum radius
    float maxRadius = min(centerX, centerY) - 5;
    if (spiralMaxRadius > 0) {
      maxRadius = min(maxRadius, spiralMaxRadius);
    }
    
    // Generate the spiral
    for (float angle = 0; angle < 2 * PI * spiralTurns; angle += 0.1) {
      float radius = (angle / (2 * PI)) * maxRadius / spiralTurns;
      
      // Calculate LED coordinates (polar to cartesian conversion)
      int x = centerX + round(radius * cos(angle));
      int y = centerY + round(radius * sin(angle));
      
      // Validate coordinates and apply spacing
      if (x >= 0 && x < matrixWidth && y >= 0 && y < matrixHeight && 
          ((x + y) % gridSpacing == 0)) {
        ledPattern[y][x] = true;
      }
    }
  }
  
  /**
   * Generate a grid pattern
   */
  private void generateGrid() {
    // Get center for offset alignment
    int centerX = matrixWidth / 2;
    int centerY = matrixHeight / 2;
    
    // Use spacing for grid spacing
    for (int y = 0; y < matrixHeight; y += gridSpacing) {
      for (int x = 0; x < matrixWidth; x += gridSpacing) {
        // Apply offset if configured
        int offsetX = (x + gridOffsetX) % matrixWidth;
        int offsetY = (y + gridOffsetY) % matrixHeight;
        
        // Draw point with size
        for (int py = 0; py < gridPointSize; py++) {
          for (int px = 0; px < gridPointSize; px++) {
            int finalX = (offsetX + px) % matrixWidth;
            int finalY = (offsetY + py) % matrixHeight;
            
            if (finalX >= 0 && finalX < matrixWidth && finalY >= 0 && finalY < matrixHeight) {
              ledPattern[finalY][finalX] = true;
            }
          }
        }
      }
    }
    
    // Always include the center point
    ledPattern[centerY][centerX] = true;
  }
  
  /**
   * Apply a circular mask to the pattern
   */
  private void applyCircleMask() {
    int centerX = matrixWidth / 2;
    int centerY = matrixHeight / 2;
    
    for (int y = 0; y < matrixHeight; y++) {
      for (int x = 0; x < matrixWidth; x++) {
        // Calculate distance from center
        float dx = x - centerX;
        float dy = y - centerY;
        float distance = sqrt(dx*dx + dy*dy);
        
        // Mask out LEDs outside the circle
        if (distance > circleMaskRadius) {
          ledPattern[y][x] = false;
        }
      }
    }
  }
  
  /**
   * Generate the illumination sequence from the pattern
   */
  private void generateIlluminationSequence() {
    // Clear current sequence
    illuminationSequence.clear();
    
    // Add active LEDs to sequence
    for (int y = 0; y < matrixHeight; y++) {
      for (int x = 0; x < matrixWidth; x++) {
        if (ledPattern[y][x]) {
          illuminationSequence.add(new PVector(x, y));
        }
      }
    }
  }
  
  // Getters and setters
  
  public int getPatternType() {
    return patternType;
  }
  
  public void setPatternType(int patternType) {
    // Debug - log pattern type changes
    println("PatternModel: Setting pattern type to " + patternType + 
            " (0=Rings, 1=Center, 2=Spiral, 3=Grid)");
            
    if (this.patternType != patternType) {
      this.patternType = patternType;
      generatePattern();
    }
  }
  
  public int getInnerRingRadius() {
    return innerRingRadius;
  }
  
  public void setInnerRingRadius(int radius) {
    if (innerRingRadius != radius) {
      innerRingRadius = radius;
      if (patternType == PATTERN_CONCENTRIC_RINGS) {
        generatePattern();
      }
    }
  }
  
  public int getMiddleRingRadius() {
    return middleRingRadius;
  }
  
  public void setMiddleRingRadius(int radius) {
    if (middleRingRadius != radius) {
      middleRingRadius = radius;
      if (patternType == PATTERN_CONCENTRIC_RINGS) {
        generatePattern();
      }
    }
  }
  
  public int getOuterRingRadius() {
    return outerRingRadius;
  }
  
  public void setOuterRingRadius(int radius) {
    if (outerRingRadius != radius) {
      outerRingRadius = radius;
      if (patternType == PATTERN_CONCENTRIC_RINGS) {
        generatePattern();
      }
    }
  }
  
  public int getSpiralMaxRadius() {
    return spiralMaxRadius;
  }
  
  public void setSpiralMaxRadius(int radius) {
    if (spiralMaxRadius != radius) {
      spiralMaxRadius = radius;
      if (patternType == PATTERN_SPIRAL) {
        generatePattern();
      }
    }
  }
  
  public int getSpiralTurns() {
    return spiralTurns;
  }
  
  public void setSpiralTurns(int turns) {
    if (spiralTurns != turns) {
      spiralTurns = turns;
      if (patternType == PATTERN_SPIRAL) {
        generatePattern();
      }
    }
  }
  
  public int getGridSpacing() {
    return gridSpacing;
  }
  
  public void setGridSpacing(int spacing) {
    if (gridSpacing != spacing && spacing > 0) {
      gridSpacing = spacing;
      generatePattern();
    }
  }
  
  public int getGridPointSize() {
    return gridPointSize;
  }
  
  public void setGridPointSize(int size) {
    if (gridPointSize != size && size > 0) {
      gridPointSize = size;
      if (patternType == PATTERN_GRID) {
        generatePattern();
      }
    }
  }
  
  public int getGridOffsetX() {
    return gridOffsetX;
  }
  
  public void setGridOffsetX(int offset) {
    if (gridOffsetX != offset) {
      gridOffsetX = offset;
      if (patternType == PATTERN_GRID) {
        generatePattern();
      }
    }
  }
  
  public int getGridOffsetY() {
    return gridOffsetY;
  }
  
  public void setGridOffsetY(int offset) {
    if (gridOffsetY != offset) {
      gridOffsetY = offset;
      if (patternType == PATTERN_GRID) {
        generatePattern();
      }
    }
  }
  
  public boolean isCircleMaskMode() {
    return circleMaskMode;
  }
  
  public void setCircleMaskMode(boolean enabled) {
    if (circleMaskMode != enabled) {
      circleMaskMode = enabled;
      generatePattern();
    }
  }
  
  public int getCircleMaskRadius() {
    return circleMaskRadius;
  }
  
  public void setCircleMaskRadius(int radius) {
    if (circleMaskRadius != radius) {
      circleMaskRadius = radius;
      if (circleMaskMode) {
        generatePattern();
      }
    }
  }
  
  public boolean isLedActive(int x, int y) {
    if (x >= 0 && x < matrixWidth && y >= 0 && y < matrixHeight) {
      return ledPattern[y][x];
    }
    return false;
  }
  
  public ArrayList<PVector> getIlluminationSequence() {
    return illuminationSequence;
  }
  
  public int getSequenceLength() {
    return illuminationSequence.size();
  }
  
  public int getMatrixWidth() {
    return matrixWidth;
  }
  
  public int getMatrixHeight() {
    return matrixHeight;
  }
}

// Using EventSystem instead of observer pattern