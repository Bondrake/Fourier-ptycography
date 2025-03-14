# Event Flow Documentation

This document provides a comprehensive overview of the event system in the Ptycography LED Matrix Control application. Understanding how events flow through the system is essential for maintaining and extending the codebase.

## Event System Architecture

The application uses a publisher-subscriber pattern for event-based communication between components:

- **EventBus**: Central hub for event publication and subscription
- **EventDispatcher**: Base class that components extend to easily publish/subscribe to events
- **ThrottledEventDispatcher**: Extension that limits event frequency for performance
- **EventData**: Class for passing data with events using key-value pairs

This architecture enables decoupled communication, allowing components to interact without direct dependencies.

## Event Types Overview

The system defines the following event types in the `EventType` class:

### System Events
- `PATTERN_CHANGED`: Triggered when the LED pattern changes
- `STATE_CHANGED`: Triggered when the system state changes (running, idle, etc.)
- `CAMERA_STATUS_CHANGED`: Triggered when camera status changes
- `CAMERA_SETTINGS_CHANGED`: Triggered when camera settings are modified
- `HARDWARE_CONNECTED`: Triggered when hardware connection is established
- `HARDWARE_DISCONNECTED`: Triggered when hardware connection is lost
- `SERIAL_DATA_RECEIVED`: Triggered when data is received from serial port
- `SERIAL_PORTS_CHANGED`: Triggered when available serial ports change
- `SERIAL_CONNECTED`: Triggered when successfully connected to serial port
- `SERIAL_DISCONNECTED`: Triggered when disconnected from serial port

### UI Events
- `REFRESH_UI`: Triggered to request UI refresh
- `UI_SIZE_CHANGED`: Triggered when UI size changes

### Configuration Events
- `CONFIG_LOADED`: Triggered when configuration is loaded
- `CONFIG_SAVED`: Triggered when configuration is saved

## Event Flow Diagram

```
                                                          
                            EventBus          EventData   
                                                          
                                  ^                   ^
                                                     
                                  �                   �
                                                       
 Publishers           �  Event Types       Subscribers 
                                                       
                                                   
      �                          �                   �
                                                       
 Models                  Configuration      Views       
 Controllers             UI Events          Controllers 
 Managers                System Events      Managers    
                                                       
```

## Event Publishers

Components that produce events:

### PatternModel
- Publishes `PATTERN_CHANGED`: When pattern type, parameters, or configuration changes

### SystemStateModel
- Publishes `STATE_CHANGED`: When run state changes, idle mode toggles, hardware connection status changes, or sequence progress updates

### CameraModel
- Publishes `CAMERA_STATUS_CHANGED`: When camera enabled/disabled, trigger status changes, or camera errors occur

### SerialManager
- Publishes `SERIAL_PORTS_CHANGED`: When available serial port list is refreshed
- Publishes `SERIAL_CONNECTED`: When connection to Arduino is established
- Publishes `SERIAL_DISCONNECTED`: When disconnected from Arduino
- Publishes `SERIAL_DATA_RECEIVED`: When data is received from Arduino

### AppController
- Publishes `SERIAL_DATA_RECEIVED`: When forwarding data from SerialManager
- Publishes `CONFIG_SAVED`: When configuration is saved

### ConfigManager
- Publishes `CONFIG_LOADED`: When configuration is loaded
- Publishes `CONFIG_SAVED`: When configuration is saved

## Event Subscribers

Components that consume events:

### AppController
- Subscribes to:
  - `PATTERN_CHANGED`: Updates config and sends pattern to hardware
  - `STATE_CHANGED`: Updates UI and handles state transitions
  - `CAMERA_STATUS_CHANGED`: Updates config and UI
  - `CONFIG_LOADED`: Applies loaded settings to models
  - `CONFIG_SAVED`: Shows confirmation message

### StatusPanelView
- Subscribes to:
  - `STATE_CHANGED`: Updates status display
  - `PATTERN_CHANGED`: Updates pattern info
  - `CAMERA_STATUS_CHANGED`: Updates camera status

### MatrixView
- Subscribes to:
  - `PATTERN_CHANGED`: Redraws visualization
  - `STATE_CHANGED`: Updates LED display

### UIManager
- Subscribes to:
  - `STATE_CHANGED`: Updates UI controls based on state
  - `PATTERN_CHANGED`: Updates pattern selection UI
  - `SERIAL_PORTS_CHANGED`: Updates serial port dropdown
  - `CONFIG_LOADED`: Updates UI controls with loaded settings
  - `CONFIG_SAVED`: Updates UI controls with saved settings

## Event Data

Data typically passed with events:

### PATTERN_CHANGED
- No specific data typically passed

### STATE_CHANGED
- No specific data typically passed (state is retrieved from stateModel)

### CAMERA_STATUS_CHANGED
- No specific data typically passed (state is retrieved from cameraModel)

### SERIAL_PORTS_CHANGED
- `ports`: String array of available port names

### SERIAL_DATA_RECEIVED
- `data`: String containing received data

### CONFIG_LOADED / CONFIG_SAVED
- `source`: String indicating the source (e.g., "file")

## Throttled Events

The system implements event throttling to prevent performance issues with rapidly firing events:

### ThrottledSystemStateModel
- Throttles `STATE_CHANGED` events:
  - Default throttle interval: 100ms
  - Configured in CentralController.pde with 50ms throttle interval
  - Prevents performance issues with rapid LED updates during sequence execution
  - Particularly important when hardware is sending frequent status updates

### Throttling Mechanism
- `ThrottledEventDispatcher` provides base throttling functionality
- Stores pending events and publishes them after their throttle interval has passed
- Events can be force-published with `forcePublishPending()`
- All throttled dispatchers are updated in the main draw loop

## Best Practices

When working with the event system:

1. **For Publishers**:
   - Always check for state changes before publishing events
   - Include relevant data in EventData for context
   - Consider event throttling for high-frequency events

2. **For Subscribers**:
   - Keep event handlers lightweight
   - Avoid complex processing in event handlers
   - Don't modify state in ways that trigger recursive events

3. **Event Documentation**:
   - Document new events in EventType class
   - Update this document when adding new event types
   - Describe expected EventData fields for new events

---

*Last Updated: March 2025*