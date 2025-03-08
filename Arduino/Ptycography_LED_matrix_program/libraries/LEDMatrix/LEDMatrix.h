/**
 * LEDMatrix.h
 * 
 * Class for controlling a 64x64 RGB LED matrix for Fourier ptycography
 * Handles the low-level hardware control of the LED matrix
 */

#ifndef LEDMATRIX_H
#define LEDMATRIX_H

#include <Arduino.h>

// Matrix dimensions
#define MATRIX_WIDTH 64
#define MATRIX_HEIGHT 64
#define MATRIX_HALF_HEIGHT 32  // Half height for split panel addressing

// Color bit values for bitwise operations
#define COLOR_RED 1     // Bit 0 controls red LEDs
#define COLOR_GREEN 2   // Bit 1 controls green LEDs
#define COLOR_BLUE 4    // Bit 2 controls blue LEDs
#define COLOR_MAX 7     // Maximum valid color value (all colors on)

class LEDMatrix {
  public:
    // Constructor
    LEDMatrix(int blPin, int ckPin, int laPin, 
              int a0Pin, int a1Pin, int a2Pin, int a3Pin, int a4Pin,
              int r0Pin, int r1Pin, int g0Pin, int g1Pin, int b0Pin, int b1Pin);
    
    // Initialization
    void begin();
    
    // LED control methods
    bool setLED(int x, int y, int color);
    void clearDisplay();
    
    // Row address caching for optimization
    void initAddressCache();
    
    // Status tracking
    bool isDisplayDirty() const;
    void setDisplayDirty(bool dirty);
    
  private:
    // Pin definitions
    int _pinBL;  // Blank control
    int _pinCK;  // Clock signal
    int _pinLA;  // Latch control
    
    // Address pins
    int _pinA0;
    int _pinA1;
    int _pinA2;
    int _pinA3;
    int _pinA4;
    
    // Data pins
    int _pinR0;  // Red data for first half of display
    int _pinR1;  // Red data for second half of display
    int _pinG0;  // Green data for first half of display
    int _pinG1;  // Green data for second half of display
    int _pinB0;  // Blue data for first half of display
    int _pinB1;  // Blue data for second half of display
    
    // Row address cache for faster updates
    byte _rowAddressCache[MATRIX_HEIGHT][5];  // Pre-computed row address bit values
    bool _displayDirty;                       // Flag to track if display needs refresh
    
    // Helper methods
    bool isValidCoordinate(int x, int y) const;
    bool isValidColor(int color) const;
};

#endif // LEDMATRIX_H