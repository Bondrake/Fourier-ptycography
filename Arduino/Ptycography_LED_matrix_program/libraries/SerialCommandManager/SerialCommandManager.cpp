/**
 * SerialCommandManager.cpp
 * 
 * Implementation of SerialCommandManager class for handling serial commands
 */

#include "SerialCommandManager.h"
#include "../IdleManager/IdleManager.h"
#include "../VisualizationManager/VisualizationManager.h"

/**
 * Constructor
 * 
 * @param idleManager Pointer to IdleManager instance
 * @param visManager Pointer to VisualizationManager instance
 * @param serialTimeout Timeout for serial operations in ms
 * @param serialRetries Number of retries for serial operations
 */
SerialCommandManager::SerialCommandManager(IdleManager* idleManager, VisualizationManager* visManager,
                                          unsigned long serialTimeout, int serialRetries) {
  _idleManager = idleManager;
  _visManager = visManager;
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