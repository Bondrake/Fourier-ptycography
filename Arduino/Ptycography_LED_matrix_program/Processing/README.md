# Central Controller for Ptycography LED Matrix

This directory contains a complete solution for controlling the Ptycography LED Matrix through a central Processing application. This approach eliminates the need to reprogram the Arduino/Teensy when making changes to patterns or parameters.

> **IMPORTANT**: This project has been restructured to use a flat file organization (as required by Processing). Previous documentation about directory structures with models/views/controllers folders doesn't apply to this version.

## Project Structure and Organization

### File Organization

All code is kept in a flat directory structure as required by Processing. Files are organized with prefixes:

- `Model_` - Data models that manage state and pattern information
- `View_` - Visual components for rendering the UI and LED patterns
- `Controller_` - Application logic and coordinating components
- `Util_` - Utility classes for configurations, events, and communication

### Coding Standards

#### Naming Conventions

- **Classes**: Use PascalCase (e.g., `PatternModel`, `MatrixView`)
- **Methods**: Use camelCase (e.g., `updatePattern()`, `drawMatrix()`)
- **Variables**: Use camelCase (e.g., `ledColor`, `matrixSize`)
- **Constants**: Use UPPER_SNAKE_CASE (e.g., `MAX_LEDS`, `DEFAULT_COLOR`)
- **File Names**: Should match the class name with appropriate prefix (e.g., `Model_PatternModel.pde`)

#### Processing-Specific Guidelines

##### Color Handling

Processing has a special handling of the word "color" which can cause conflicts. Follow these rules:

1. **NEVER use `color` as a type** - Always use `int` instead:
   ```java
   // DO:
   private int ledColor;
   public void setColor(int newColor) {...}
   
   // DON'T:
   private color ledColor;
   public void setColor(color newColor) {...}
   ```

2. **NEVER use `color` as a parameter name or variable name**:
   ```java
   // DO:
   public void updateColor(int ledColor) {...}
   
   // DON'T:
   public void updateColor(int color) {...}
   ```

##### Enums in Classes

All enums inside classes must be static:

```java
// Correct:
public static enum PatternType {
  RING,
  SPIRAL,
  GRID
}

// Incorrect:
public enum PatternType {
  RING,
  SPIRAL,
  GRID
}
```

## System Architecture

The system consists of:

1. **Processing Central Controller** (`CentralController.pde`): A feature-rich application that serves as the single point of control for the entire system.

2. **Arduino Hardware Interface** (`LED_Matrix_Hardware_Interface.ino`): A minimal, one-time upload sketch for the Arduino/Teensy that receives commands from the Processing controller.

This architecture offers several advantages:

- **Single Control Point**: All control happens through the Processing application
- **Real-time Parameter Adjustments**: Change patterns, ring sizes, and other parameters without recompiling Arduino code
- **Hybrid Operation**: Works in both simulation mode (no hardware) and hardware control mode
- **Rich User Interface**: Visual controls for all parameters

## Setup Instructions

### Required Libraries

This project requires the **ControlP5** library for the user interface.

#### Installing ControlP5

1. Open Processing
2. Go to the menu: **Sketch > Import Library > Add Library...**
3. In the search box at the top, type **ControlP5**
4. Select the **ControlP5** library from the search results
5. Click the "Install" button on the bottom right
6. Restart Processing

#### Manual Installation (if needed)

If you're having issues with the Library Manager:

1. Download the latest version of ControlP5 from: https://github.com/sojamo/controlp5/releases 
2. Unzip the downloaded file
3. Navigate to your Processing libraries folder:
   - Windows: `Documents/Processing/libraries/`
   - Mac: `~/Documents/Processing/libraries/`
   - Linux: `~/sketchbook/libraries/`
4. Create a new folder called `controlP5` in the libraries folder
5. Copy the contents of the unzipped ControlP5 folder into the newly created `controlP5` folder
6. Restart Processing

### Initial Setup

1. Upload the `LED_Matrix_Hardware_Interface.ino` sketch to your Arduino/Teensy
2. Install Processing from [processing.org](https://processing.org/)
3. Install the ControlP5 library as described above
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

## Development Guidelines

### Best Practices

1. **Test frequently** in the Processing IDE
2. **Keep code modular** by respecting the Model-View-Controller pattern
3. **Follow the coding standards** for consistency

### Common Issues

1. **Processing Mode**: Ensure you're using Java mode in Processing
2. **Serial Port Selection**: If you can't see your Arduino, check if it's connected properly
3. **Library Compatibility**: Make sure your ControlP5 library version works with your Processing version