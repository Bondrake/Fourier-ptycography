/**
 * IdleManager.h
 * 
 * Class for managing idle mode and power-saving features
 */

#ifndef IDLEMANAGER_H
#define IDLEMANAGER_H

#include <Arduino.h>

class LEDMatrix; // Forward declaration

class IdleManager {
  public:
    // Constructor
    IdleManager(LEDMatrix* ledMatrix, unsigned long idleTimeout, 
                unsigned long blinkInterval, unsigned long blinkDuration);
    
    // Idle mode control
    void begin();
    void enterIdleMode();
    void exitIdleMode();
    void updateActivityTime();
    
    // Status methods
    bool isIdle() const;
    unsigned long getIdleTime() const;
    
    // Periodic update method (call in main loop)
    void update();
    
    // Heartbeat LED methods
    bool blinkHeartbeat();
    
  private:
    LEDMatrix* _ledMatrix;           // Reference to the LED matrix
    
    // Configuration
    unsigned long _idleTimeout;      // Time before entering idle mode (ms)
    unsigned long _blinkInterval;    // Time between blinks in idle mode (ms)
    unsigned long _blinkDuration;    // Duration of each blink (ms)
    
    // State tracking
    bool _idleMode;                  // Whether idle mode is active
    unsigned long _lastActivityTime; // Time of last activity
    unsigned long _lastBlinkTime;    // Time of last heartbeat blink
    
    // Internal methods
    bool isIdleTimeoutExceeded(unsigned long currentTime) const;
    bool isBlinkIntervalExceeded(unsigned long currentTime) const;
};

#endif // IDLEMANAGER_H