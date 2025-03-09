# Central Controller for Ptycography LED Matrix

This directory contains a complete solution for controlling the Ptycography LED Matrix through a central Processing application. This approach eliminates the need to reprogram the Arduino/Teensy when making changes to patterns or parameters.

## Approach Overview

The system consists of:

1. **Processing Central Controller** (`CentralController.pde`): A feature-rich application that serves as the single point of control for the entire system.

2. **Arduino Hardware Interface** (`LED_Matrix_Hardware_Interface.ino`): A minimal, one-time upload sketch for the Arduino/Teensy that receives commands from the Processing controller.

This architecture offers several advantages:

- **Single Control Point**: All control happens through the Processing application
- **Real-time Parameter Adjustments**: Change patterns, ring sizes, and other parameters without recompiling Arduino code
- **Hybrid Operation**: Works in both simulation mode (no hardware) and hardware control mode
- **Rich User Interface**: Visual controls for all parameters

## Setup Instructions

### Initial Setup

1. Upload the `LED_Matrix_Hardware_Interface.ino` sketch to your Arduino/Teensy
2. Install Processing from [processing.org](https://processing.org/)
3. Install the ControlP5 library in Processing:
   - Sketch > Import Library > Add Library
   - Search for "ControlP5"
   - Click "Install"
   - See [LIBRARY_INSTALLATION.md](LIBRARY_INSTALLATION.md) for detailed instructions if you have trouble
4. Open the `CentralController.pde` sketch in Processing
5. Run the sketch

### Hardware Setup

When you want to control physical hardware:

1. Connect your Arduino/Teensy via USB
2. In the Processing app, toggle "Simulation Mode" off in the Hardware panel
3. Select your Arduino's serial port from the dropdown list
4. Click "Connect to Hardware"
5. Once connected, click "Upload Pattern to Hardware" to send your pattern parameters

## Usage

### Pattern Configuration

The central controller provides controls for:

- **Pattern Types**: Concentric Rings, Center Only, Spiral, Grid
- **Ring Radii**: Adjust inner, middle, and outer ring sizes
- **LED Spacing**: Control the spacing between illuminated LEDs

### Sequence Control

- **Start**: Begin the LED illumination sequence
- **Pause/Resume**: Temporarily pause or resume the sequence
- **Stop**: Reset to the beginning of the sequence
- **Regenerate**: Recreate the pattern with current parameters

### Power Management

- **Idle Mode**: Toggle the power-saving idle mode (with periodic heartbeat blinking)

### Hardware Communication

- **Connection Controls**: Connect/disconnect from Arduino hardware
- **Upload Pattern**: Send current pattern settings to the hardware

## Serial Protocol

The Processing application communicates with the Arduino using a simple text-based protocol:

- **P{value}**: Set pattern type (0-3)
- **I{value}**: Set inner ring radius
- **M{value}**: Set middle ring radius
- **O{value}**: Set outer ring radius
- **S{value}**: Set LED spacing
- **R**: Run sequence
- **X**: Stop sequence
- **i**: Enter idle mode
- **a**: Exit idle mode
- **L,x,y,color**: Set specific LED at coordinates (x,y) with color

The Arduino responds with status updates:

- **LED,x,y,color**: Current LED position and color
- **STATUS,running,idle,progress**: System status information

## Advantages Over Original Approach

1. **Easier Parameter Tweaking**: Adjust parameters through UI controls without recompiling
2. **Multiple Pattern Types**: Support for various illumination patterns
3. **Real-time Visual Feedback**: See changes immediately in the visual interface
4. **No Programming Required**: Once the hardware interface is uploaded, all control is through the Processing application
5. **Enhanced Visualization**: Rich information display with sequence progress and status indicators