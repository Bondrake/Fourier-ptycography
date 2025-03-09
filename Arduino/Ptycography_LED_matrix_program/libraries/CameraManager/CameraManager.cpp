/**
 * CameraManager.cpp
 * 
 * Implementation of Camera control functionality for Ptycography system
 */

#include "CameraManager.h"

/**
 * Constructor
 * 
 * @param triggerPin Pin number connected to camera trigger
 */
CameraManager::CameraManager(int triggerPin) {
  _triggerPin = triggerPin;
  _enabled = true;  // Default to enabled
  _pulseWidth = CAMERA_PULSE_WIDTH;
  _preDelay = PREFRAME_DELAY;
  _postDelay = POSTFRAME_DELAY;
  _lastTriggerTime = 0;
  _triggerCount = 0;
}

/**
 * Initialize the camera manager
 */
void CameraManager::begin() {
  // Configure trigger pin as output
  pinMode(_triggerPin, OUTPUT);
  digitalWrite(_triggerPin, LOW);
  
  #if CAMERA_USE_READY_SIGNAL == 1
  pinMode(CAMERA_BUSY_PIN, INPUT_PULLUP);
  #endif
}

/**
 * Trigger the camera shutter
 * 
 * @param waitForReady Whether to wait for camera ready signal (if enabled)
 * @return True if successful, false on error
 */
bool CameraManager::triggerCamera(bool waitForReady) {
  // Skip if camera triggering is disabled
  if (!_enabled) return true;
  
  // Pre-trigger delay for camera auto-exposure to adjust
  if (_preDelay > 0) {
    delay(_preDelay);
  }
  
  // Send the trigger pulse
  bool success = sendTriggerPulse(_pulseWidth);
  if (!success) return false;
  
  // Wait for camera to complete capture if requested and configured
  #if CAMERA_USE_READY_SIGNAL == 1
  if (waitForReady) {
    unsigned long startTime = millis();
    
    // Wait for the camera to signal it's no longer busy (pin goes LOW)
    while (digitalRead(CAMERA_BUSY_PIN) == HIGH) {
      delay(10);
      
      // Check for timeout
      if (millis() - startTime > CAMERA_READY_TIMEOUT) {
        return false;  // Timeout waiting for camera
      }
    }
  }
  #endif
  
  // Post-trigger delay to ensure image is captured
  if (_postDelay > 0) {
    delay(_postDelay);
  }
  
  return true;
}

/**
 * Test the camera trigger with optional custom pulse width
 * 
 * @param customPulseWidth Optional custom pulse width (use default if -1)
 * @return True if successful, false on error
 */
bool CameraManager::testTrigger(int customPulseWidth) {
  int pulseWidth = (customPulseWidth > 0) ? customPulseWidth : _pulseWidth;
  return sendTriggerPulse(pulseWidth);
}

/**
 * Send trigger pulse to the camera
 * 
 * @param pulseWidth Width of trigger pulse in milliseconds
 * @return True if successful
 */
bool CameraManager::sendTriggerPulse(int pulseWidth) {
  // Set trigger pin high
  digitalWrite(_triggerPin, HIGH);
  
  // Maintain pulse width then set low
  delay(pulseWidth);
  digitalWrite(_triggerPin, LOW);
  
  // Update tracking information
  _lastTriggerTime = millis();
  _triggerCount++;
  
  return true;
}

/**
 * Enable or disable camera triggering
 * 
 * @param enabled True to enable, false to disable
 */
void CameraManager::setEnabled(bool enabled) {
  _enabled = enabled;
}

/**
 * Set the camera trigger pulse width
 * 
 * @param width Pulse width in milliseconds
 */
void CameraManager::setPulseWidth(int width) {
  if (width > 0 && width <= 1000) {  // Reasonable limits
    _pulseWidth = width;
  }
}

/**
 * Set the pre-trigger delay
 * 
 * @param delay Delay in milliseconds
 */
void CameraManager::setPreDelay(int delay) {
  if (delay >= 0 && delay <= 5000) {  // Reasonable limits
    _preDelay = delay;
  }
}

/**
 * Set the post-trigger delay
 * 
 * @param delay Delay in milliseconds
 */
void CameraManager::setPostDelay(int delay) {
  if (delay >= 0 && delay <= 10000) {  // Reasonable limits
    _postDelay = delay;
  }
}

/**
 * Check if camera triggering is enabled
 * 
 * @return True if enabled, false if disabled
 */
bool CameraManager::isEnabled() const {
  return _enabled;
}

/**
 * Get the current trigger pulse width
 * 
 * @return Pulse width in milliseconds
 */
int CameraManager::getPulseWidth() const {
  return _pulseWidth;
}

/**
 * Get the current pre-trigger delay
 * 
 * @return Delay in milliseconds
 */
int CameraManager::getPreDelay() const {
  return _preDelay;
}

/**
 * Get the current post-trigger delay
 * 
 * @return Delay in milliseconds
 */
int CameraManager::getPostDelay() const {
  return _postDelay;
}

/**
 * Get the timestamp of the last trigger
 * 
 * @return Timestamp in milliseconds (from millis())
 */
unsigned long CameraManager::getLastTriggerTime() const {
  return _lastTriggerTime;
}

/**
 * Get the number of times the camera has been triggered
 * 
 * @return Trigger count
 */
int CameraManager::getTriggerCount() const {
  return _triggerCount;
}