/**
 * VisualizationManager.h
 * 
 * Class for managing the visualization of LED patterns
 * Handles communication with external visualization tools
 */

#ifndef VISUALIZATIONMANAGER_H
#define VISUALIZATIONMANAGER_H

#include <Arduino.h>

class VisualizationManager {
  public:
    // Constructor
    VisualizationManager(unsigned long updateInterval = 100);
    
    // Visualization control
    void begin();
    void enable();
    void disable();
    bool isEnabled() const;
    
    // Data transmission
    void sendLEDState(int x, int y, int color);
    void exportPattern(bool** pattern, int width, int height);
    
    // Periodic update (call in main loop)
    void update();
    
  private:
    bool _enabled;                    // Whether visualization is enabled
    unsigned long _updateInterval;    // Time between visualization updates (ms)
    unsigned long _lastUpdateTime;    // Time of last visualization update
    
    // Internal methods
    bool isUpdateIntervalExceeded(unsigned long currentTime) const;
};

#endif // VISUALIZATIONMANAGER_H