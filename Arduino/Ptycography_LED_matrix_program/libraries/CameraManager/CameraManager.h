/**
 * CameraManager.h
 * 
 * Manages camera trigger functionality for Ptycography system
 */

#ifndef CAMERAMANAGER_H
#define CAMERAMANAGER_H

#include <Arduino.h>
#include "../PtycographyConfig.h"

class CameraManager {
  public:
    // Constructor
    CameraManager(int triggerPin = PIN_PHOTO_TRIGGER);
    
    // Initialization
    void begin();
    
    // Camera control methods
    bool triggerCamera(bool waitForReady = true);
    bool testTrigger(int customPulseWidth = -1);
    
    // Settings management
    void setEnabled(bool enabled);
    void setPulseWidth(int width);
    void setPreDelay(int delay);
    void setPostDelay(int delay);
    
    // Status methods
    bool isEnabled() const;
    int getPulseWidth() const;
    int getPreDelay() const;
    int getPostDelay() const;
    
    // Event tracking
    unsigned long getLastTriggerTime() const;
    int getTriggerCount() const;
    
  private:
    int _triggerPin;
    bool _enabled;
    int _pulseWidth;
    int _preDelay;
    int _postDelay;
    unsigned long _lastTriggerTime;
    int _triggerCount;
    
    // Internal methods
    bool sendTriggerPulse(int pulseWidth);
};

#endif // CAMERAMANAGER_H