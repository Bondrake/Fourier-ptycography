# Ptycography LED Matrix Controller - Project Status

## Current State

The Ptycography LED Matrix Controller provides a unified interface for both simulation and hardware control of LED arrays for Fourier ptycography. The system is currently functional with a focus on maintainable, modular architecture.

## Recent Major Improvements

### 1. Code Structure Refactoring
- Reorganized code into a flat file structure for Processing compatibility
- Implemented MVC pattern with clear separation of concerns
- Standardized file naming conventions (Model_*, View_*, Controller_*, Util_*)

### 2. Event-Based Architecture
- Implemented publisher-subscriber pattern using EventBus
- Created a robust event system for decoupled component communication
- Added event throttling to prevent performance issues with high-frequency events
- Added comprehensive event documentation (see EVENT_FLOW.md)

### 3. Error Handling System
- Implemented centralized ErrorManager for consistent error handling
- Created severity-based error classification (DEBUG, INFO, WARNING, ERROR, CRITICAL)
- Added user-friendly error notifications with auto-dismissal and close buttons
- Implemented structured error reporting with module names and error codes
- Added comprehensive error handling documentation (see ERROR_HANDLING.md)

### 4. UI Improvements
- Centered LED matrix visualization in the main window
- Improved control panel organization with consistent spacing
- Enhanced status display with better information hierarchy
- Added temporary message capabilities to StatusPanelView

### 5. Configuration Management
- Implemented robust configuration loading/saving using JSON files
- Added event-based configuration change notifications
- Enhanced error recovery for configuration issues

## Key Components

### Models
- **PatternModel**: Manages LED pattern generation and configuration
- **SystemStateModel**: Tracks application state (running, idle, simulation mode)
- **CameraModel**: Handles camera configuration and triggering

### Views
- **MatrixView**: Visualizes the LED matrix in both simulation and hardware modes
- **StatusPanelView**: Displays system status information
- **ErrorView**: Shows error notifications with severity-based styling

### Controllers
- **AppController**: Central coordination of application components

### Utilities
- **ConfigManager**: Handles loading/saving settings
- **EventBus**: Core event publishing and subscription system
- **SerialManager**: Manages hardware communication
- **ErrorManager**: Central error handling and reporting
- **UIManager**: Manages ControlP5 UI components

## Usage Modes

1. **Simulation Mode**: Test patterns and sequences without physical hardware
   - Visualize LED patterns in real-time
   - Adjust parameters and see immediate results
   - Toggle grid lines and zoom with keyboard shortcuts

2. **Hardware Mode**: Control physical LED matrix via Arduino/Teensy
   - Connect via serial port
   - Send patterns to hardware
   - Trigger camera for image acquisition

## Current Priorities

See FUTURE_IMPROVEMENTS.md for detailed information on upcoming development priorities. Key focus areas include:

1. UI Component Architecture improvements
2. Configuration Management enhancements
3. Documentation standards improvements

## Documentation

The project includes several documentation files:
- **ARCHITECTURE.md**: Overall system architecture
- **EVENT_FLOW.md**: Event system documentation
- **ERROR_HANDLING.md**: Error handling system documentation
- **FUTURE_IMPROVEMENTS.md**: Upcoming development priorities
- **CLAUDE.md**: Development guide and operational instructions

---

*Last updated: March 2025*