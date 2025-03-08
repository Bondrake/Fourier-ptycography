/**
 * VisualizationManager.cpp
 * 
 * Implementation of VisualizationManager class for handling visualization
 */

#include "VisualizationManager.h"

/**
 * Constructor
 * 
 * @param updateInterval Time in ms between visualization updates
 */
VisualizationManager::VisualizationManager(unsigned long updateInterval) {
  _updateInterval = updateInterval;
  _enabled = false;
  _lastUpdateTime = 0;
}

/**
 * Initialize the visualization manager
 */
void VisualizationManager::begin() {
  _lastUpdateTime = millis();
  _enabled = false;
}

/**
 * Enable visualization
 */
void VisualizationManager::enable() {
  _enabled = true;
  _lastUpdateTime = millis();
}

/**
 * Disable visualization
 */
void VisualizationManager::disable() {
  _enabled = false;
}

/**
 * Check if visualization is enabled
 * 
 * @return True if enabled, false otherwise
 */
bool VisualizationManager::isEnabled() const {
  return _enabled;
}

/**
 * Check if update interval has been exceeded
 * 
 * @param currentTime Current system time in ms
 * @return True if update interval exceeded, false otherwise
 */
bool VisualizationManager::isUpdateIntervalExceeded(unsigned long currentTime) const {
  return (currentTime - _lastUpdateTime >= _updateInterval);
}

/**
 * Send LED state to the visualization tool
 * Format: "LED,x,y,color\n"
 * 
 * @param x X-coordinate of the LED
 * @param y Y-coordinate of the LED
 * @param color Color value
 */
void VisualizationManager::sendLEDState(int x, int y, int color) {
  if (!_enabled) return;
  
  Serial.print("LED,");
  Serial.print(x);
  Serial.print(",");
  Serial.print(y);
  Serial.print(",");
  Serial.println(color);
}

/**
 * Export full LED pattern to the visualization tool
 * 
 * @param pattern 2D pattern array
 * @param width Width of the pattern
 * @param height Height of the pattern
 */
void VisualizationManager::exportPattern(bool** pattern, int width, int height) {
  if (!_enabled) return;
  
  Serial.println("PATTERN_START");
  
  // Send all LEDs in the pattern
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      if (pattern[y][x]) {
        Serial.print("PATTERN,");
        Serial.print(x);
        Serial.print(",");
        Serial.println(y);
      }
    }
  }
  
  Serial.println("PATTERN_END");
}

/**
 * Update the visualization manager
 * Should be called regularly from the main loop
 */
void VisualizationManager::update() {
  if (!_enabled) return;
  
  unsigned long currentTime = millis();
  
  // Update the last update time if interval exceeded
  if (isUpdateIntervalExceeded(currentTime)) {
    _lastUpdateTime = currentTime;
    
    // No automatic updates needed - LED states are sent directly
    // via sendLEDState when LED is updated
  }
}