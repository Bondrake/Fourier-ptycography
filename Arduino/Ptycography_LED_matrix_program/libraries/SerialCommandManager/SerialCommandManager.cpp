/**
 * SerialCommandManager.cpp
 * 
 * Implementation of SerialCommandManager class for handling serial commands
 */

#include "SerialCommandManager.h"
#include "../IdleManager/IdleManager.h"
#include "../VisualizationManager/VisualizationManager.h"
#include "../CameraManager/CameraManager.h"

/**
 * Constructor
 * 
 * @param idleManager Pointer to IdleManager instance
 * @param visManager Pointer to VisualizationManager instance
 * @param serialTimeout Timeout for serial operations in ms
 * @param serialRetries Number of retries for serial operations
 */
SerialCommandManager::SerialCommandManager(IdleManager* idleManager, VisualizationManager* visManager,
                                          CameraManager* cameraManager,
                                          unsigned long serialTimeout, int serialRetries) {
  _idleManager = idleManager;
  _visManager = visManager;
  _cameraManager = cameraManager;
  _serialTimeout = serialTimeout;
  _serialRetries = serialRetries;
  _serialReady = false;
}

/**
 * Initialize the serial command manager
 * 
 * @param baudRate Serial baud rate
 */
void SerialCommandManager::begin(unsigned long baudRate) {
  Serial.begin(baudRate);
  Serial.setTimeout(_serialTimeout);
  _serialReady = true;
}

/**
 * Process incoming serial commands
 */
void SerialCommandManager::processCommands() {
  if (!_serialReady || !Serial.available()) return;
  
  char cmd = Serial.read();
  
  // Process commands
  switch (cmd) {
    case CMD_IDLE_ENTER:
      handleIdleEnterCommand();
      break;
      
    case CMD_IDLE_EXIT:
      handleIdleExitCommand();
      break;
    
    case CMD_VIS_START:
      handleVisStartCommand();
      break;
      
    case CMD_VIS_STOP:
      handleVisStopCommand();
      break;
      
    case CMD_PATTERN_EXPORT:
      handlePatternExportCommand();
      break;
      
    case CMD_SET_CAMERA:
      handleCameraCommand();
      break;
      
    default:
      handleUnknownCommand(cmd);
      break;
  }
}

/**
 * Safely prints message to serial with retry logic
 * 
 * @param message Message to print
 * @param newline Whether to add a newline (true = println, false = print)
 * @return True if successful, false if error
 */
bool SerialCommandManager::safePrint(const char* message, bool newline) {
  // Only attempt serial output if serial is connected
  if (!_serialReady || !Serial) return false;
  
  // Try multiple times with timeout
  for (int retry = 0; retry < _serialRetries; retry++) {
    if (newline) {
      Serial.println(message);
    } else {
      Serial.print(message);
    }
    
    // Check if serial operation completed successfully
    if (Serial.availableForWrite() >= 0) {
      return true;
    }
    
    delay(10); // Small delay before retry
  }
  
  // Failed all retries
  return false;
}

/**
 * Check if serial communication is ready
 * 
 * @return True if ready, false otherwise
 */
bool SerialCommandManager::isReady() const {
  return _serialReady && Serial;
}

/**
 * Handle idle enter command
 */
void SerialCommandManager::handleIdleEnterCommand() {
  if (_idleManager != nullptr && !_idleManager->isIdle()) {
    safePrint("Entering idle mode (manual)");
    _idleManager->enterIdleMode();
  }
}

/**
 * Handle idle exit command
 */
void SerialCommandManager::handleIdleExitCommand() {
  if (_idleManager != nullptr && _idleManager->isIdle()) {
    safePrint("Exiting idle mode (manual)");
    _idleManager->exitIdleMode();
  }
}

/**
 * Handle visualization start command
 */
void SerialCommandManager::handleVisStartCommand() {
  if (_visManager != nullptr && !_visManager->isEnabled()) {
    safePrint("Starting visualization mode");
    _visManager->enable();
    // Pattern export is handled by the main sketch
  }
}

/**
 * Handle visualization stop command
 */
void SerialCommandManager::handleVisStopCommand() {
  if (_visManager != nullptr && _visManager->isEnabled()) {
    safePrint("Stopping visualization mode");
    _visManager->disable();
  }
}

/**
 * Handle pattern export command
 */
void SerialCommandManager::handlePatternExportCommand() {
  safePrint("Exporting LED pattern...");
  // Pattern export is handled by the main sketch
}

/**
 * Handle camera configuration command
 * 
 * Format: C<type>,<param1>,<param2>,...
 * Types:
 *   S = Settings: S,<enabled>,<preDelay>,<pulseWidth>,<postDelay>
 *   T = Test: T,<enabled>,<pulseWidth>
 */
void SerialCommandManager::handleCameraCommand() {
  if (_cameraManager == nullptr) {
    safePrint("ERROR: No camera manager available");
    return;
  }
  
  // Wait for more data
  delay(10);
  if (!Serial.available()) return;
  
  // Read command type
  char type = Serial.read();
  if (type != 'S' && type != 'T') {
    safePrint("ERROR: Invalid camera command type");
    return;
  }
  
  // Read comma separator
  if (!Serial.available() || Serial.read() != ',') {
    safePrint("ERROR: Invalid camera command format");
    return;
  }
  
  // Process settings command
  if (type == 'S') {
    int enabled = Serial.parseInt();
    
    // Check for comma after enabled parameter
    if (!Serial.available() || Serial.read() != ',') {
      safePrint("ERROR: Invalid camera settings format");
      return;
    }
    
    int preDelay = Serial.parseInt();
    
    // Check for comma after preDelay parameter
    if (!Serial.available() || Serial.read() != ',') {
      safePrint("ERROR: Invalid camera settings format");
      return;
    }
    
    int pulseWidth = Serial.parseInt();
    
    // Check for comma after pulseWidth parameter
    if (!Serial.available() || Serial.read() != ',') {
      safePrint("ERROR: Invalid camera settings format");
      return;
    }
    
    int postDelay = Serial.parseInt();
    
    // Apply the settings
    _cameraManager->setEnabled(enabled != 0);
    _cameraManager->setPreDelay(preDelay);
    _cameraManager->setPulseWidth(pulseWidth);
    _cameraManager->setPostDelay(postDelay);
    
    safePrint("Camera settings updated");
  }
  
  // Process test command
  else if (type == 'T') {
    int enabled = Serial.parseInt();
    
    // Check for comma after enabled parameter
    if (!Serial.available() || Serial.read() != ',') {
      safePrint("ERROR: Invalid camera test format");
      return;
    }
    
    int pulseWidth = Serial.parseInt();
    
    // Only proceed with test if camera is enabled
    if (enabled != 0) {
      safePrint("Testing camera trigger...");
      bool success = _cameraManager->testTrigger(pulseWidth);
      
      if (success) {
        safePrint("Camera test completed successfully");
      } else {
        safePrint("ERROR: Camera test failed");
      }
    } else {
      safePrint("Camera test skipped (camera disabled)");
    }
  }
}

/**
 * Handle unknown command
 * 
 * @param cmd The command character received
 */
void SerialCommandManager::handleUnknownCommand(char cmd) {
  // For any other character, update activity time
  if (_idleManager != nullptr) {
    if (_idleManager->isIdle()) {
      safePrint("Exiting idle mode due to serial activity");
      _idleManager->exitIdleMode();
    }
    _idleManager->updateActivityTime();
  }
}