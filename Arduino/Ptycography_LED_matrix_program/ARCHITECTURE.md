# Ptycography LED Matrix Controller - Architecture Overview

This document provides a comprehensive overview of the architecture for the Ptycography LED Matrix Controller application, explaining both the central controller approach and the component design.

> **Note**: This document describes the architecture implemented in the `modularization` branch.

## 1. Central Controller Architecture

The central controller architecture represents a significant shift in how the Ptycography LED Matrix is controlled. Instead of having the Arduino/Teensy as the primary controller, this architecture places the Processing application as the central control point for both simulation and hardware operation.

### 1.1 Key Components

1. **Processing Central Controller**: A feature-rich application that provides:
   - Complete user interface for all parameters
   - Pattern generation and visualization
   - LED sequence control
   - Hardware communication

2. **Arduino Hardware Interface**: A minimal firmware that:
   - Receives commands from Processing
   - Controls physical LED matrix hardware
   - Sends status updates to Processing
   - Doesn't require reprogramming when changing patterns

### 1.2 Architecture Benefits

This approach provides several advantages over the original design:

#### User-Friendly Control
- **Visual Interface**: All controls are available through a graphical interface
- **Real-time Adjustment**: See changes immediately as you adjust parameters
- **No Recompiling**: Change patterns without recompiling Arduino code

#### Enhanced Flexibility
- **Multiple Pattern Types**: Support for various illumination patterns
- **Seamless Switching**: Easily switch between simulation and hardware modes
- **Pattern Experimentation**: Quickly test different pattern configurations

#### Simplified Workflow
- **One-Time Arduino Setup**: Upload the hardware interface once, then control via Processing
- **Unified Development Environment**: Make all changes in Processing rather than across multiple environments
- **Integrated Visualization**: Pattern design and visualization in the same application

### 1.3 Communication Protocol

The Processing application and Arduino communicate via a simple text-based serial protocol:

1. **Commands** (Processing → Arduino):
   - Set pattern type and parameters
   - Control sequence execution
   - Manage power states
   - Directly control individual LEDs

2. **Status Updates** (Arduino → Processing):
   - Current LED position and color
   - System status (running, idle, progress)
   - Error conditions

## 2. Component Architecture

The application follows a modified MVC (Model-View-Controller) architecture with additional utility components to enhance modularity and maintainability.

### 2.1 Architecture Diagram

```
+-----------------------------------------------------------+
|                   CentralController                       |
+-----------------------------------------------------------+
           |                |               |
           v                v               v
+----------------+  +----------------+  +----------------+
|     Models     |  |   Controllers  |  |     Views      |
+----------------+  +----------------+  +----------------+
| Model_PatternModel|  | Controller_App | | View_MatrixView|
| Model_SystemState|  | Util_UIManager  | | View_StatusPanel|
| Model_CameraModel|  |                 | |                 |
+----------------+  +----------------+  +----------------+
           |                |               |
           v                v               v
+-----------------------------------------------------------+
|                       Utilities                           |
| Util_EventSystem | Util_ConfigManager | Util_SerialManager |
+-----------------------------------------------------------+
           |                                |
           v                                v
+-------------------+            +-------------------+
| Physical Hardware |            |  Processing IDE   |
| (Arduino/Teensy)  |            |    Environment    |
+-------------------+            +-------------------+
```

> **Note**: The class names in this diagram reflect the actual file naming convention used in the flat file structure.

### 2.2 Component Descriptions

#### 2.2.1 Models

Models represent the core data structures and business logic of the application.

##### Model_PatternModel
- Manages LED pattern generation and storage
- Implements different pattern algorithms (concentric rings, spiral, grid, etc.)
- Tracks pattern parameters and state
- Publishes events when patterns change

##### Model_SystemStateModel
- Maintains application operational state (running, paused, idle)
- Tracks sequence progress and current LED position
- Manages simulation vs hardware mode settings
- Publishes events on state changes

##### Model_CameraModel
- Controls camera triggering parameters and timing
- Manages camera status (enabled, active, error states)
- Simulates camera triggering in simulation mode
- Publishes events on camera status changes

#### 2.2.2 Controllers

Controllers coordinate between models, views, and the hardware interface.

##### Controller_AppController
- Central coordinator for the application
- Manages communication between components
- Handles key events and user commands
- Coordinates between hardware and simulation modes

##### Util_UIManager
- Manages UI components and layout
- Handles user interaction with UI elements
- Updates UI based on model changes
- Dispatches user actions to appropriate components

#### 2.2.3 Views

Views are responsible for rendering the user interface and visualizing data from the models.

##### View_MatrixView / View_MatrixViewRefactored
- Renders the LED matrix visualization
- Displays the current pattern and active LED
- Shows coordinates and grid lines
- Indicates camera status visually

##### View_StatusPanelView / View_StatusPanelViewRefactored
- Displays system status information
- Shows camera settings and status
- Displays sequence progress
- Provides visual feedback on hardware status

#### 2.2.4 Utilities

Utilities provide cross-cutting functionality used by multiple components.

##### Util_EventSystem
- Implements a publisher-subscriber pattern
- Allows decoupled communication between components
- Replaces direct observer pattern with more flexible event mechanism
- Supports structured event data with type safety

##### Util_ConfigManager
- Manages configuration persistence
- Loads/saves settings to JSON files
- Provides defaults and validation
- Supports application state persistence

##### Util_SerialManager
- Handles communication with Arduino hardware
- Implements command protocol and message formatting
- Manages connection state and error handling
- Parses incoming data from hardware

## 3. Communication Patterns

### 3.1 Event-Based Communication

The application uses an event system to enable decoupled communication between components:

1. **Event Publishing**: Components publish events when their state changes
2. **Event Subscription**: Components subscribe to events they're interested in
3. **Event Handling**: Components implement handlers for each event type
4. **Event Data**: Events carry structured data to provide context

Example flow:
```
Model_PatternModel changes → Publishes PATTERN_CHANGED event →
Util_UIManager receives event → Updates pattern controls →
View_MatrixView receives event → Redraws the pattern visualization
```

### 3.2 Hardware Communication

Communication with the Arduino hardware follows a command-response pattern:

1. **Commands**: Application sends commands to Arduino (e.g., set pattern, start sequence)
2. **Status Updates**: Arduino sends regular status updates (LED position, sequence progress)
3. **Event Notifications**: Arduino sends event notifications (camera trigger, errors)
4. **Parameter Transfers**: Application sends configuration parameters

## 4. Design Principles

### 4.1 Separation of Concerns
- Each component has a single responsibility
- UI is separated from business logic
- Hardware communication is isolated in SerialManager

### 4.2 Loose Coupling
- Components communicate through events, not direct method calls
- Models don't know about views or controllers
- Components can be replaced or modified independently

### 4.3 Testability
- Components can be tested in isolation
- Event system facilitates testing with mocks
- Simulation mode allows testing without hardware

### 4.4 Configuration over Code
- Settings are externalized in configuration
- UI layout is determined by configuration
- Hardware parameters are configurable

## 5. Implementation Details

### 5.1 Event System Implementation

The event system (implemented in `Util_EventSystem.pde`) consists of:
- `EventBus`: Singleton that manages event subscriptions and publishing
- `EventDispatcher`: Base class that simplifies event publishing/subscribing
- `EventData`: Class for passing structured data with events
- `EventType`: Constants for event type identification

### 5.2 Model Updates

Models publish events when their state changes:
```java
public void setPatternType(int type) {
  if (this.patternType != type) {
    this.patternType = type;
    generatePattern();
    publishEvent(EventType.PATTERN_CHANGED);
  }
}
```

In the flat file structure, this is implemented in `Model_PatternModel.pde`.

### 5.3 View Updates

Views subscribe to events and update their display:
```java
public void handleEvent(String eventType, EventData data) {
  if (eventType.equals(EventType.PATTERN_CHANGED)) {
    needsRedraw = true;
  }
}
```

## 6. Physical Implementation

### 6.1 Processing Implementation
- Written in Processing 4.x
- Uses ControlP5 library for UI components
- Uses Processing's Serial library for hardware communication
- Uses standard Processing drawing functions for visualization

### 6.2 Arduino Implementation
- Minimal sketch that focuses on hardware control
- Implements serial command parser
- Controls LED matrix directly
- Sends status updates to Processing

## 7. Using This Architecture

To use this architecture:

1. **Arduino Setup**: Upload `Processing/LED_Matrix_Hardware_Interface.ino` to your Arduino/Teensy
2. **Processing Setup**: Install Processing and the ControlP5 library
3. **Run Controller**: Open and run `Processing/CentralController.pde` in Processing

For detailed instructions, see `Processing/README.md`