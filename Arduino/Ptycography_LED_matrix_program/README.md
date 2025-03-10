# Ptycography LED Matrix Control System

This repository contains a comprehensive control system for a 64x64 RGB LED matrix used in Fourier ptycography imaging applications. The system systematically illuminates LEDs in a specific pattern and can trigger a camera for each illumination to capture the resulting diffraction patterns.

## Central Controller Architecture

This branch (`modularization`) implements a central controller architecture where:

1. **Processing is the primary control interface**
   - A comprehensive Processing application provides all control functions
   - User-friendly UI for pattern configuration and sequence control
   - Real-time visualization of the LED matrix state

2. **Arduino/Teensy serves as a hardware interface**
   - A minimal sketch that receives commands from Processing
   - Controls the physical LED matrix based on those commands
   - Only needs to be uploaded once

This approach eliminates the need to reprogram the Arduino when changing patterns or parameters, making the system much more user-friendly and flexible.

## System Components

### Processing Controller

The Processing sketch in the `Processing/` directory provides:

- Complete UI for controlling all aspects of the system
- Pattern selection (concentric rings, center only, spiral, grid)
- Parameter adjustment (ring sizes, LED spacing, timing)
- Sequence control (start, pause, stop)
- Power management (idle mode)
- Hardware connection management

> **Note**: The Processing code has been restructured to use a flat file organization with prefixes (Model_, View_, Controller_, Util_) as required by Processing.

### Processing Code Organization

The Processing code follows these naming conventions for clarity:

- `Model_*.pde` - Data models (PatternModel, SystemStateModel, CameraModel)
- `View_*.pde` - UI components (MatrixView, StatusPanelView)
- `Controller_*.pde` - Application logic (AppController)
- `Util_*.pde` - Utilities (ConfigManager, EventSystem, SerialManager, UIManager)
- `CentralController.pde` - Main application entry point

### Processing Development Guidelines

When developing for Processing, remember:

1. Keep all code in the flat directory structure (no subdirectories)
2. Always use `int` instead of `color` for color variables and parameters
3. All enums inside classes must be declared as `static`
4. Use the event system for communication between components

### Arduino Hardware Interface

The `Processing/LED_Matrix_Hardware_Interface.ino` sketch:

- Receives commands from Processing via serial
- Controls the physical LED matrix hardware
- Generates patterns based on received parameters
- Executes illumination sequences
- Sends status updates to Processing

## Setup Instructions

1. **Hardware Interface Setup**:
   - Upload `Processing/LED_Matrix_Hardware_Interface.ino` to your Arduino/Teensy
   - This only needs to be done once

2. **Processing Controller Setup**:
   - Install Processing from [processing.org](https://processing.org/)
   - Install the ControlP5 library:
     - Sketch > Import Library > Add Library
     - Search for "ControlP5"
     - Click "Install"
   - Open `Processing/CentralController.pde`
   - Run the sketch

3. **Hardware Connection**:
   - Connect your Arduino/Teensy via USB
   - In the Processing app, toggle "Simulation Mode" off
   - Select your Arduino's serial port from the dropdown
   - Click "Connect to Hardware"

## Usage

The central controller provides a comprehensive interface for:

- **Pattern Configuration**: Select pattern types and adjust parameters
- **Sequence Control**: Start, pause, and stop the illumination sequence
- **Power Management**: Toggle idle mode with heartbeat functionality
- **Visualization**: See the LED matrix state in real-time

For detailed usage instructions, see `Processing/README.md`.

## Focus on Central Control

The `modularization` branch focuses exclusively on the central controller architecture:

- **Single Control Interface**: The Processing central controller is the only interface needed
- **Streamlined Approach**: All other visualizers and tools have been removed
- **Pattern Documentation**: Available in the controller itself through its UI

## Documentation

The project documentation has been consolidated for better clarity:

- **README.md** (this file) - Main project overview and getting started guide
- **ARCHITECTURE.md** - Comprehensive architecture documentation
- **TEST.md** - Complete testing documentation
- **CLAUDE.md** - Development guide for AI assistant
- **Processing/README.md** - Processing code documentation
- **DOCUMENTATION_UPDATE.md** - Overview of documentation organization

### Documentation Hierarchy

- Start with this README.md for an overview
- Reference ARCHITECTURE.md for design details
- Use TEST.md for testing information
- See Processing/README.md for Processing-specific implementation

> **Note**: Historical documentation has been moved to the `docs-archive` directory. See `DOCUMENTATION_UPDATE.md` for details.

## Power Management Features

- After 30 minutes of inactivity, the system enters idle mode to save power
- In idle mode, all LEDs are turned off except for a periodic center LED blink (once per minute)
- Idle mode can be manually toggled through the Processing interface