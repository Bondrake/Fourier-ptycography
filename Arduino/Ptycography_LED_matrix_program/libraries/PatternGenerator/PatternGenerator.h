/**
 * PatternGenerator.h
 * 
 * Class for generating patterns for the LED matrix in Fourier ptycography applications
 * Handles pattern generation algorithms for different illumination strategies
 */

#ifndef PATTERNGENERATOR_H
#define PATTERNGENERATOR_H

#include <Arduino.h>
#include "../PtycographyConfig.h"

// Pattern types are now defined in PtycographyConfig.h
typedef int PatternType;

class PatternGenerator {
  public:
    // Constructor
    PatternGenerator(int width, int height, float physicalSizeMM, float ledPitchMM);
    
    // Pattern generation methods
    bool generatePattern(bool** pattern, PatternType type = PATTERN_CONCENTRIC_RINGS);
    bool generateConcentricRings(bool** pattern, float innerRadius, float middleRadius, float outerRadius, float targetSpacingMM);
    bool generateCenterOnly(bool** pattern);
    
    // Advanced pattern methods (for future expansion)
    bool generateSpiral(bool** pattern, float spacingMM, int turns);
    bool generateGrid(bool** pattern, int spacingX, int spacingY);
    
    // Pattern info and validation
    int countActiveLEDs(bool** pattern) const;
    bool validatePattern(bool** pattern) const;
    
    // Utility methods
    float calculateRingRadius(int ringNumber, float baseRadius, float spacing) const;
    int calculateLEDSkip(float desiredSpacingMM) const;
    
  private:
    // Matrix dimensions
    int _width;
    int _height;
    
    // Physical properties
    float _physicalSizeMM;  // Physical size of the matrix in mm
    float _ledPitchMM;      // Physical spacing between adjacent LEDs
    
    // Helper methods
    int getCenterX() const;
    int getCenterY() const;
    float calculateDistance(int x1, int y1, int x2, int y2) const;
    bool isValidCoordinate(int x, int y) const;
};

#endif // PATTERNGENERATOR_H