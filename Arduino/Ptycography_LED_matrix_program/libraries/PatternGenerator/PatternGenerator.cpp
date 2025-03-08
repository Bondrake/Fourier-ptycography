/**
 * PatternGenerator.cpp
 * 
 * Implementation of the PatternGenerator class for generating LED patterns
 */

#include "PatternGenerator.h"

/**
 * Constructor - initializes pattern generator with matrix parameters
 * 
 * @param width Width of the LED matrix in LEDs
 * @param height Height of the LED matrix in LEDs
 * @param physicalSizeMM Physical size of the matrix in mm
 * @param ledPitchMM Physical spacing between adjacent LEDs in mm
 */
PatternGenerator::PatternGenerator(int width, int height, float physicalSizeMM, float ledPitchMM) {
  _width = width;
  _height = height;
  _physicalSizeMM = physicalSizeMM;
  _ledPitchMM = ledPitchMM;
}

/**
 * Gets the X-coordinate of the center of the matrix
 * 
 * @return Center X-coordinate
 */
int PatternGenerator::getCenterX() const {
  return _width / 2;
}

/**
 * Gets the Y-coordinate of the center of the matrix
 * 
 * @return Center Y-coordinate
 */
int PatternGenerator::getCenterY() const {
  return _height / 2;
}

/**
 * Calculates the Euclidean distance between two points
 * 
 * @param x1, y1 Coordinates of first point
 * @param x2, y2 Coordinates of second point
 * @return Distance between the points
 */
float PatternGenerator::calculateDistance(int x1, int y1, int x2, int y2) const {
  float dx = x2 - x1;
  float dy = y2 - y1;
  return sqrt(dx*dx + dy*dy);
}

/**
 * Checks if the given coordinates are within the valid range
 * 
 * @param x X-coordinate
 * @param y Y-coordinate
 * @return True if coordinates are valid, false otherwise
 */
bool PatternGenerator::isValidCoordinate(int x, int y) const {
  return (x >= 0 && x < _width && y >= 0 && y < _height);
}

/**
 * Calculates the number of LEDs to skip to achieve desired physical spacing
 * 
 * @param desiredSpacingMM Desired physical spacing in mm
 * @return Number of LEDs to skip
 */
int PatternGenerator::calculateLEDSkip(float desiredSpacingMM) const {
  int skip = round(desiredSpacingMM / _ledPitchMM);
  return (skip < 1) ? 1 : skip;  // Ensure minimum spacing of 1
}

/**
 * Calculates the radius of a ring based on the ring number
 * 
 * @param ringNumber Ring number (0 = innermost)
 * @param baseRadius Radius of the innermost ring
 * @param spacing Spacing between rings
 * @return Radius of the specified ring
 */
float PatternGenerator::calculateRingRadius(int ringNumber, float baseRadius, float spacing) const {
  return baseRadius + (ringNumber * spacing);
}

/**
 * Generates a pattern based on the specified type
 * 
 * @param pattern 2D array to store the pattern (preallocated)
 * @param type Type of pattern to generate
 * @return True if successful, false otherwise
 */
bool PatternGenerator::generatePattern(bool** pattern, PatternType type) {
  switch (type) {
    case PATTERN_CONCENTRIC_RINGS:
      // Default values for concentric rings pattern
      return generateConcentricRings(pattern, 27.0, 37.0, 47.0, 4.0);
    
    case PATTERN_CENTER_ONLY:
      return generateCenterOnly(pattern);
    
    case PATTERN_SPIRAL:
      return generateSpiral(pattern, 4.0, 3);
    
    case PATTERN_GRID:
      return generateGrid(pattern, 4, 4);
    
    default:
      return false;
  }
}

/**
 * Generates a concentric rings pattern
 * 
 * @param pattern 2D array to store the pattern (preallocated)
 * @param innerRadius Radius of the inner ring in LED units
 * @param middleRadius Radius of the middle ring in LED units
 * @param outerRadius Radius of the outer ring in LED units
 * @param targetSpacingMM Desired physical spacing between LEDs in mm
 * @return True if successful, false otherwise
 */
bool PatternGenerator::generateConcentricRings(bool** pattern, float innerRadius, float middleRadius, 
                                              float outerRadius, float targetSpacingMM) {
  // Clear pattern first
  for (int y = 0; y < _height; y++) {
    for (int x = 0; x < _width; x++) {
      pattern[y][x] = false;
    }
  }
  
  // Calculate LED skip based on desired spacing
  int ledSkip = calculateLEDSkip(targetSpacingMM);
  
  // Get center coordinates
  int centerX = getCenterX();
  int centerY = getCenterY();
  
  // Validate ring radii
  float maxRadius = min(_width, _height) / 2.0;
  if (outerRadius >= maxRadius) {
    // Ring is too large for the matrix
    return false;
  }
  
  // Generate the ring pattern
  int ledCount = 0;
  for (int y = 0; y < _height; y++) {
    for (int x = 0; x < _width; x++) {
      // Skip LEDs based on spacing
      if ((x + y) % ledSkip != 0) continue;
      
      // Calculate distance from center
      float distance = calculateDistance(x, y, centerX, centerY);
      
      // Check if this LED falls on one of our rings
      if (abs(distance - innerRadius) < 1.0 || 
          abs(distance - middleRadius) < 1.0 || 
          abs(distance - outerRadius) < 1.0) {
        pattern[y][x] = true;
        ledCount++;
      }
    }
  }
  
  // Validate that we have a reasonable number of LEDs in the pattern
  return (ledCount > 0);
}

/**
 * Generates a center-only pattern (just the center LED)
 * 
 * @param pattern 2D array to store the pattern (preallocated)
 * @return True if successful, false otherwise
 */
bool PatternGenerator::generateCenterOnly(bool** pattern) {
  // Clear pattern first
  for (int y = 0; y < _height; y++) {
    for (int x = 0; x < _width; x++) {
      pattern[y][x] = false;
    }
  }
  
  // Get center coordinates
  int centerX = getCenterX();
  int centerY = getCenterY();
  
  // Set center LED
  if (isValidCoordinate(centerX, centerY)) {
    pattern[centerY][centerX] = true;
    return true;
  }
  
  return false;
}

/**
 * Generates a spiral pattern
 * 
 * @param pattern 2D array to store the pattern (preallocated)
 * @param spacingMM Desired physical spacing between LEDs in mm
 * @param turns Number of turns in the spiral
 * @return True if successful, false otherwise
 */
bool PatternGenerator::generateSpiral(bool** pattern, float spacingMM, int turns) {
  // Clear pattern first
  for (int y = 0; y < _height; y++) {
    for (int x = 0; x < _width; x++) {
      pattern[y][x] = false;
    }
  }
  
  // Get center coordinates
  int centerX = getCenterX();
  int centerY = getCenterY();
  
  // Calculate LED skip based on desired spacing
  int ledSkip = calculateLEDSkip(spacingMM);
  
  // Maximum radius to stay within matrix bounds
  float maxRadius = min(centerX, centerY);
  
  // Generate spiral points
  int ledCount = 0;
  float radiusStep = maxRadius / (turns * 8);  // Approximate steps for smooth spiral
  
  // Start with center point
  pattern[centerY][centerX] = true;
  ledCount++;
  
  // Generate the spiral
  for (float angle = 0; angle < 2 * PI * turns; angle += 0.1) {
    float radius = (angle / (2 * PI)) * maxRadius / turns;
    
    // Calculate LED coordinates (polar to cartesian conversion)
    int x = centerX + round(radius * cos(angle));
    int y = centerY + round(radius * sin(angle));
    
    // Validate coordinates and apply spacing
    if (isValidCoordinate(x, y) && ((x + y) % ledSkip == 0)) {
      pattern[y][x] = true;
      ledCount++;
    }
  }
  
  return (ledCount > 0);
}

/**
 * Generates a rectangular grid pattern
 * 
 * @param pattern 2D array to store the pattern (preallocated)
 * @param spacingX Horizontal spacing between LEDs
 * @param spacingY Vertical spacing between LEDs
 * @return True if successful, false otherwise
 */
bool PatternGenerator::generateGrid(bool** pattern, int spacingX, int spacingY) {
  // Clear pattern first
  for (int y = 0; y < _height; y++) {
    for (int x = 0; x < _width; x++) {
      pattern[y][x] = false;
    }
  }
  
  // Validate spacing
  if (spacingX < 1 || spacingY < 1) return false;
  
  // Generate grid pattern
  int ledCount = 0;
  for (int y = 0; y < _height; y += spacingY) {
    for (int x = 0; x < _width; x += spacingX) {
      if (isValidCoordinate(x, y)) {
        pattern[y][x] = true;
        ledCount++;
      }
    }
  }
  
  return (ledCount > 0);
}

/**
 * Counts the number of active LEDs in a pattern
 * 
 * @param pattern Pattern to analyze
 * @return Number of active LEDs
 */
int PatternGenerator::countActiveLEDs(bool** pattern) const {
  int count = 0;
  for (int y = 0; y < _height; y++) {
    for (int x = 0; x < _width; x++) {
      if (pattern[y][x]) count++;
    }
  }
  return count;
}

/**
 * Validates a pattern to ensure it's usable
 * 
 * @param pattern Pattern to validate
 * @return True if pattern is valid, false otherwise
 */
bool PatternGenerator::validatePattern(bool** pattern) const {
  // A valid pattern should have at least one LED
  return (countActiveLEDs(pattern) > 0);
}