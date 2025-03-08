/**
 * LEDMatrix.cpp
 * 
 * Implementation of the LEDMatrix class for controlling a 64x64 RGB LED matrix
 */

#include "LEDMatrix.h"

/**
 * Constructor - initializes pins for the LED matrix
 * 
 * @param blPin Blank control pin
 * @param ckPin Clock signal pin
 * @param laPin Latch control pin
 * @param a0Pin-a4Pin Address pins
 * @param r0Pin-b1Pin Color data pins for upper/lower half
 */
LEDMatrix::LEDMatrix(int blPin, int ckPin, int laPin, 
                     int a0Pin, int a1Pin, int a2Pin, int a3Pin, int a4Pin,
                     int r0Pin, int r1Pin, int g0Pin, int g1Pin, int b0Pin, int b1Pin) {
  // Store pin assignments
  _pinBL = blPin;
  _pinCK = ckPin;
  _pinLA = laPin;
  
  _pinA0 = a0Pin;
  _pinA1 = a1Pin;
  _pinA2 = a2Pin;
  _pinA3 = a3Pin;
  _pinA4 = a4Pin;
  
  _pinR0 = r0Pin;
  _pinR1 = r1Pin;
  _pinG0 = g0Pin;
  _pinG1 = g1Pin;
  _pinB0 = b0Pin;
  _pinB1 = b1Pin;
  
  _displayDirty = true;
}

/**
 * Initialize the LED matrix hardware
 */
void LEDMatrix::begin() {
  // Configure all pins
  pinMode(_pinBL, OUTPUT);  // Blank control
  pinMode(_pinCK, OUTPUT);  // Clock signal
  pinMode(_pinLA, OUTPUT);  // Latch control
  
  // Address pins
  pinMode(_pinA0, OUTPUT);
  pinMode(_pinA1, OUTPUT);
  pinMode(_pinA2, OUTPUT);
  pinMode(_pinA3, OUTPUT);
  pinMode(_pinA4, OUTPUT);
  
  // Data pins
  pinMode(_pinR0, OUTPUT);  // Red - lower half
  pinMode(_pinR1, OUTPUT);  // Red - upper half
  pinMode(_pinG0, OUTPUT);  // Green - lower half
  pinMode(_pinG1, OUTPUT);  // Green - upper half
  pinMode(_pinB0, OUTPUT);  // Blue - lower half
  pinMode(_pinB1, OUTPUT);  // Blue - upper half
  
  // Ensure display is blanked during initialization
  digitalWrite(_pinBL, HIGH);
  
  // Initialize the address cache for faster updates
  initAddressCache();
  
  // Clear the display to ensure a known state
  clearDisplay();
}

/**
 * Pre-computes row address values for faster LED updates
 * This avoids repeated bit-masking operations during LED updates
 */
void LEDMatrix::initAddressCache() {
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    int rowAddr = y % MATRIX_HALF_HEIGHT; // Handle the split panel addressing
    
    // Store each bit value in the cache
    _rowAddressCache[y][0] = rowAddr & 1;                // A0 - LSB of row address
    _rowAddressCache[y][1] = (rowAddr & 2) > 0 ? 1 : 0;  // A1
    _rowAddressCache[y][2] = (rowAddr & 4) > 0 ? 1 : 0;  // A2
    _rowAddressCache[y][3] = (rowAddr & 8) > 0 ? 1 : 0;  // A3
    _rowAddressCache[y][4] = (rowAddr & 16) > 0 ? 1 : 0; // A4 - MSB of row address
  }
}

/**
 * Checks if the given coordinates are within the valid range
 * 
 * @param x X-coordinate (0 to MATRIX_WIDTH-1)
 * @param y Y-coordinate (0 to MATRIX_HEIGHT-1)
 * @return True if coordinates are valid, false otherwise
 */
bool LEDMatrix::isValidCoordinate(int x, int y) const {
  return (x >= 0 && x < MATRIX_WIDTH && y >= 0 && y < MATRIX_HEIGHT);
}

/**
 * Checks if the given color value is valid
 * 
 * @param color Color value (bitwise combination of COLOR_RED, COLOR_GREEN, COLOR_BLUE)
 * @return True if color is valid, false otherwise
 */
bool LEDMatrix::isValidColor(int color) const {
  return (color >= 0 && color <= COLOR_MAX);
}

/**
 * Sets a single LED to the specified color
 * 
 * @param x X-coordinate of the LED (0-63)
 * @param y Y-coordinate of the LED (0-63)
 * @param color Color value (bitwise combination of COLOR_RED, COLOR_GREEN, COLOR_BLUE)
 * @return True if successful, false if parameters were invalid
 */
bool LEDMatrix::setLED(int x, int y, int color) {
  // Validate parameters
  if (!isValidCoordinate(x, y) || !isValidColor(color)) {
    return false;
  }

  // Calculate which half of the panel we're addressing
  bool isLowerHalf = (y < MATRIX_HALF_HEIGHT);

  // Prepare the display by setting blank and latch signals
  digitalWrite(_pinBL, HIGH);  // Blank the display during updates
  digitalWrite(_pinLA, HIGH);  // Set latch high during data loading

  // Reset address lines with a quick pulse (needed for reliable addressing)
  digitalWrite(_pinA0, HIGH);
  digitalWrite(_pinA0, LOW);

  // Use pre-computed row address bits from the cache
  digitalWrite(_pinA0, _rowAddressCache[y][0]);  // A0 - LSB
  digitalWrite(_pinA1, _rowAddressCache[y][1]);  // A1
  digitalWrite(_pinA2, _rowAddressCache[y][2]);  // A2
  digitalWrite(_pinA3, _rowAddressCache[y][3]);  // A3
  digitalWrite(_pinA4, _rowAddressCache[y][4]);  // A4 - MSB
  
  // Prepare color values for current and non-current columns
  byte currentR = (color & COLOR_RED) ? 1 : 0;
  byte currentG = (color & COLOR_GREEN) ? 1 : 0;
  byte currentB = (color & COLOR_BLUE) ? 1 : 0;
  
  // Shift in data for each column - optimized loop
  for(int i=0; i < MATRIX_WIDTH; i++) {
    bool isTargetColumn = (i == x);
    
    // Only update pins when needed (when target column or changing from target)
    if (isTargetColumn || (i == x + 1)) {
      // Set color data pins based on whether this is the target column and which half we're in
      digitalWrite(_pinG0, isTargetColumn ? (isLowerHalf ? currentG : 0) : 0);
      digitalWrite(_pinG1, isTargetColumn ? (!isLowerHalf ? currentG : 0) : 0);
      digitalWrite(_pinR0, isTargetColumn ? (isLowerHalf ? currentR : 0) : 0);
      digitalWrite(_pinR1, isTargetColumn ? (!isLowerHalf ? currentR : 0) : 0);
      digitalWrite(_pinB0, isTargetColumn ? (isLowerHalf ? currentB : 0) : 0);
      digitalWrite(_pinB1, isTargetColumn ? (!isLowerHalf ? currentB : 0) : 0);
    }
    
    // Clock in the data for this column
    digitalWrite(_pinCK, HIGH);
    digitalWrite(_pinCK, LOW);
  }
    
  // Latch the data and enable display output
  digitalWrite(_pinLA, LOW);   // Latch the data
  digitalWrite(_pinBL, LOW);   // Enable display output
  
  // Mark display as clean (just updated)
  _displayDirty = false;
  
  return true;
}

/**
 * Clears the display (turns off all LEDs)
 */
void LEDMatrix::clearDisplay() {
  // Blank the display immediately for visual feedback
  digitalWrite(_pinBL, HIGH);
  
  // Set all color pins low (off) once before starting
  digitalWrite(_pinR0, LOW);
  digitalWrite(_pinR1, LOW);
  digitalWrite(_pinG0, LOW);
  digitalWrite(_pinG1, LOW);
  digitalWrite(_pinB0, LOW);
  digitalWrite(_pinB1, LOW);
  
  // Process rows in batches for better performance
  // We'll do 8 rows at a time (arbitrary optimization choice)
  const int BATCH_SIZE = 8;
  
  for (int batch = 0; batch < MATRIX_HEIGHT; batch += BATCH_SIZE) {
    int endRow = min(batch + BATCH_SIZE, MATRIX_HEIGHT);
    
    for (int y = batch; y < endRow; y++) {
      // Set latch high during data loading
      digitalWrite(_pinLA, HIGH);
      
      // Reset address lines
      digitalWrite(_pinA0, HIGH);
      digitalWrite(_pinA0, LOW);
      
      // Use pre-computed row address values from cache
      digitalWrite(_pinA0, _rowAddressCache[y][0]);
      digitalWrite(_pinA1, _rowAddressCache[y][1]);
      digitalWrite(_pinA2, _rowAddressCache[y][2]);
      digitalWrite(_pinA3, _rowAddressCache[y][3]);
      digitalWrite(_pinA4, _rowAddressCache[y][4]);
      
      // Since all color pins are already set to LOW,
      // we just clock in zeros for all columns
      for (int i = 0; i < MATRIX_WIDTH; i++) {
        // Clock in the data (all zeros)
        digitalWrite(_pinCK, HIGH);
        digitalWrite(_pinCK, LOW);
      }
      
      // Latch the data
      digitalWrite(_pinLA, LOW);
    }
  }
  
  // Mark the display buffer as clean
  _displayDirty = false;
  
  // Keep display blanked
  digitalWrite(_pinBL, HIGH);
}

/**
 * Check if the display needs to be refreshed
 * 
 * @return True if display needs refreshing, false otherwise
 */
bool LEDMatrix::isDisplayDirty() const {
  return _displayDirty;
}

/**
 * Set the display dirty flag
 * 
 * @param dirty New value for the dirty flag
 */
void LEDMatrix::setDisplayDirty(bool dirty) {
  _displayDirty = dirty;
}