# Central Controller Architecture

This document explains the central controller architecture implemented in the `processing-central-control` branch.

## Architecture Overview

The central controller architecture represents a significant shift in how the Ptycography LED Matrix is controlled. Instead of having the Arduino/Teensy as the primary controller, this architecture places the Processing application as the central control point for both simulation and hardware operation.

### Key Components

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

## Architecture Benefits

This architecture provides several advantages over the original design:

### User-Friendly Control

- **Visual Interface**: All controls are available through a graphical interface
- **Real-time Adjustment**: See changes immediately as you adjust parameters
- **No Recompiling**: Change patterns without recompiling Arduino code

### Enhanced Flexibility

- **Multiple Pattern Types**: Support for various illumination patterns
- **Seamless Switching**: Easily switch between simulation and hardware modes
- **Pattern Experimentation**: Quickly test different pattern configurations

### Simplified Workflow

- **One-Time Arduino Setup**: Upload the hardware interface once, then control via Processing
- **Unified Development Environment**: Make all changes in Processing rather than across multiple environments
- **Integrated Visualization**: Pattern design and visualization in the same application

## How It Works

### Communication Protocol

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

### Execution Flow

1. **Pattern Definition**: User defines pattern type and parameters through the Processing UI
2. **Pattern Generation**: Processing generates the pattern and visualizes it
3. **Parameter Upload**: When connected to hardware, parameters are sent to the Arduino
4. **Sequence Execution**: 
   - In simulation mode: Processing handles the sequence
   - In hardware mode: Arduino runs the sequence and reports status back

## Implementation Considerations

### Processing Application

- Written in Processing with ControlP5 for UI components
- Supports both simulation and hardware control modes
- Includes comprehensive pattern generation algorithms
- Handles serial communication with error handling

### Arduino Firmware

- Simple command interpreter
- Implements the same pattern generation algorithms as Processing
- Controls physical LED matrix hardware
- Sends status updates to Processing

## Using This Architecture

To use this architecture:

1. **Switch to Branch**: `git checkout processing-central-control`
2. **Arduino Setup**: Upload `LED_Matrix_Hardware_Interface.ino` to your Arduino/Teensy
3. **Processing Setup**: Install Processing and the ControlP5 library
4. **Run Controller**: Open and run `CentralController.pde` in Processing

For detailed instructions, see `Processing/CentralController/README.md`