/**
 * SerialCommandManager.h
 * 
 * Class for handling serial commands and communications
 */

#ifndef SERIALCOMMANDMANAGER_H
#define SERIALCOMMANDMANAGER_H

#include <Arduino.h>

// Forward declarations
class IdleManager;
class VisualizationManager;
class CameraManager;

// Command definitions
#define CMD_IDLE_ENTER 'i'         // Command to manually enter idle mode
#define CMD_IDLE_EXIT 'a'          // Command to exit idle mode
#define CMD_VIS_START 'v'          // Command to start visualization mode
#define CMD_VIS_STOP 'q'           // Command to stop visualization mode
#define CMD_PATTERN_EXPORT 'p'     // Command to export the full pattern
#define CMD_SET_CAMERA 'C'         // Command to configure camera settings

class SerialCommandManager {
  public:
    // Constructor
    SerialCommandManager(IdleManager* idleManager, VisualizationManager* visManager,
                        CameraManager* cameraManager = nullptr,
                        unsigned long serialTimeout = 5000, int serialRetries = 3);
    
    // Initialization
    void begin(unsigned long baudRate);
    
    // Command processing
    void processCommands();
    
    // Safe printing methods
    bool safePrint(const char* message, bool newline = true);
    
    // Status methods
    bool isReady() const;
    
  private:
    // References to managers
    IdleManager* _idleManager;
    VisualizationManager* _visManager;
    CameraManager* _cameraManager;
    
    // Serial settings
    unsigned long _serialTimeout;
    int _serialRetries;
    bool _serialReady;
    
    // Command processing methods
    void handleIdleEnterCommand();
    void handleIdleExitCommand();
    void handleVisStartCommand();
    void handleVisStopCommand();
    void handlePatternExportCommand();
    void handleCameraCommand();
    void handleUnknownCommand(char cmd);
};

#endif // SERIALCOMMANDMANAGER_H