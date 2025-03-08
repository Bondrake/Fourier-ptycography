/**
 * IdleManager.cpp
 * 
 * Implementation of IdleManager class for handling idle mode and power management
 */

#include "IdleManager.h"
#include "../LEDMatrix/LEDMatrix.h"  // Include the LEDMatrix class

/**
 * Constructor
 * 
 * @param ledMatrix Pointer to LEDMatrix instance
 * @param idleTimeout Time in ms before entering idle mode
 * @param blinkInterval Time in ms between heartbeat blinks
 * @param blinkDuration Duration in ms of each heartbeat blink
 */
IdleManager::IdleManager(LEDMatrix* ledMatrix, unsigned long idleTimeout, 
                         unsigned long blinkInterval, unsigned long blinkDuration) {
  _ledMatrix = ledMatrix;
  _idleTimeout = idleTimeout;
  _blinkInterval = blinkInterval;
  _blinkDuration = blinkDuration;
  
  _idleMode = false;
  _lastActivityTime = 0;
  _lastBlinkTime = 0;
}

/**
 * Initialize the idle manager
 */
void IdleManager::begin() {
  // Initialize with the current time
  _lastActivityTime = millis();
  _lastBlinkTime = millis();
  _idleMode = false;
}

/**
 * Enter idle mode - turns off LEDs and activates power saving
 */
void IdleManager::enterIdleMode() {
  if (!_idleMode) {
    _idleMode = true;
    
    // Turn off all LEDs to save power
    if (_ledMatrix != nullptr) {
      _ledMatrix->clearDisplay();
    }
    
    // Reset blink timer when entering idle mode
    _lastBlinkTime = millis();
  }
}

/**
 * Exit idle mode - returns to normal operation
 */
void IdleManager::exitIdleMode() {
  if (_idleMode) {
    _idleMode = false;
    
    // Update activity time when exiting idle mode
    _lastActivityTime = millis();
    
    // Force LED matrix refresh
    if (_ledMatrix != nullptr) {
      _ledMatrix->setDisplayDirty(true);
    }
  }
}

/**
 * Record activity to prevent entering idle mode
 */
void IdleManager::updateActivityTime() {
  _lastActivityTime = millis();
}

/**
 * Check if the system is in idle mode
 * 
 * @return True if in idle mode, false otherwise
 */
bool IdleManager::isIdle() const {
  return _idleMode;
}

/**
 * Get the time since last activity
 * 
 * @return Time in ms since last activity
 */
unsigned long IdleManager::getIdleTime() const {
  return millis() - _lastActivityTime;
}

/**
 * Check if idle timeout has been exceeded
 * 
 * @param currentTime Current system time in ms
 * @return True if idle timeout exceeded, false otherwise
 */
bool IdleManager::isIdleTimeoutExceeded(unsigned long currentTime) const {
  return (currentTime - _lastActivityTime >= _idleTimeout);
}

/**
 * Check if blink interval has been exceeded
 * 
 * @param currentTime Current system time in ms
 * @return True if blink interval exceeded, false otherwise
 */
bool IdleManager::isBlinkIntervalExceeded(unsigned long currentTime) const {
  return (currentTime - _lastBlinkTime >= _blinkInterval);
}

/**
 * Update the idle manager state
 * Should be called regularly from the main loop
 */
void IdleManager::update() {
  unsigned long currentTime = millis();
  
  if (_idleMode) {
    // In idle mode, check if it's time for a heartbeat blink
    if (isBlinkIntervalExceeded(currentTime)) {
      blinkHeartbeat();
      _lastBlinkTime = currentTime;
    }
  } else {
    // Not in idle mode, check if we should enter idle mode
    if (isIdleTimeoutExceeded(currentTime)) {
      enterIdleMode();
    }
  }
}

/**
 * Blink the center LED as a heartbeat
 * 
 * @return True if successful, false on error
 */
bool IdleManager::blinkHeartbeat() {
  if (_ledMatrix == nullptr) return false;
  
  // Get center coordinates
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Turn on center LED
  _ledMatrix->setLED(centerX, centerY, COLOR_GREEN);
  
  // Keep it on for the specified duration
  delay(_blinkDuration);
  
  // Turn it off
  _ledMatrix->clearDisplay();
  
  return true;
}