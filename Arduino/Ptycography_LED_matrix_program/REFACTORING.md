# Ptycography LED Matrix Program Refactoring Guide

This document explains the refactoring performed on the Ptycography LED Matrix Control Program to improve its design, maintainability, and extensibility.

## Refactoring Goals

1. **Modular Structure**: Separate the code into logical modules with clear responsibilities
2. **Improved Maintainability**: Make the code easier to understand and modify
3. **Enhanced Extensibility**: Make it easier to add new features in the future
4. **Better Organization**: Group related functionality together
5. **Proper Encapsulation**: Hide implementation details that don't need to be exposed

## Modular Structure

The refactored codebase consists of the following modules:

### 1. LEDMatrix

Handles the hardware control of the LED matrix.

- **Functionality**: Low-level control of LED matrix hardware
- **Key Methods**:
  - `setLED()`: Controls a specific LED
  - `clearDisplay()`: Turns off all LEDs
  - `initAddressCache()`: Pre-computes row addresses for faster updates

### 2. PatternGenerator

Responsible for generating different LED illumination patterns.

- **Functionality**: Algorithm for creating patterns such as concentric rings, center-only, and other types
- **Key Methods**:
  - `generateConcentricRings()`: Creates a concentric rings pattern
  - `generateCenterOnly()`: Creates a center-only pattern
  - `generateSpiral()`: Creates a spiral pattern (for future use)
  - `generateGrid()`: Creates a grid pattern (for future use)

### 3. IdleManager

Handles power-saving idle mode functionality.

- **Functionality**: Controls entering/exiting idle mode and performs periodic heartbeat blinks
- **Key Methods**:
  - `enterIdleMode()`: Activates idle mode
  - `exitIdleMode()`: Deactivates idle mode
  - `blinkHeartbeat()`: Blinks center LED as a heartbeat

### 4. VisualizationManager

Manages communication with external visualization tools.

- **Functionality**: Sends LED state and pattern data to visualization tools
- **Key Methods**:
  - `sendLEDState()`: Sends current LED state
  - `exportPattern()`: Exports the full pattern

### 5. SerialCommandManager

Handles serial communication and command processing.

- **Functionality**: Processes commands received via serial and makes appropriate calls to other modules
- **Key Methods**:
  - `processCommands()`: Processes incoming serial commands
  - `safePrint()`: Safely outputs messages to serial with retry logic

## Main Program Flow

The main Arduino sketch (`Ptycography_LED_matrix_program_Refactored.ino`) coordinates these modules:

1. **Initialization** (`setup()`):
   - Initializes all modules
   - Generates the LED pattern
   - Runs the initial illumination sequence
   - Enters idle mode after completion

2. **Main Loop** (`loop()`):
   - Processes serial commands
   - Updates idle mode status
   - Updates visualization if enabled

3. **Illumination Sequence** (`runIlluminationSequence()`):
   - Systematically activates LEDs according to the pattern
   - Triggers the camera for each LED
   - Reports progress

## Benefits of the Refactoring

### 1. Better Maintainability

- Each module has a single responsibility
- Changes to one module minimally impact others
- Easier to understand each component's purpose

### 2. Improved Extensibility

- New pattern types can be added by extending `PatternGenerator`
- New commands can be added by updating `SerialCommandManager`
- New visualization methods can be added to `VisualizationManager`

### 3. Enhanced Error Handling

- Proper memory management for pattern storage
- Validation in each module
- Clear error reporting

### 4. Proper Encapsulation

- Implementation details hidden within classes
- Clear interfaces between modules
- Reduced global state

## How to Use the Refactored Code

### Original vs. Refactored

The original code (`Ptycography_LED_matrix_program.ino`) still works and is unchanged. The refactored code consists of the library modules in the `libraries/` directory and the new main sketch (`Ptycography_LED_matrix_program_Refactored.ino`).

### Testing the Refactored Code

1. Upload the refactored code to your Arduino
2. Verify that all functionality works as before
3. Try adding new pattern types or features

## Future Improvements

The refactored structure facilitates these future improvements:

1. **State Machine**: Implement a proper state machine for controlling program flow
2. **Configuration Storage**: Add EEPROM storage for configuration
3. **Command Interface**: Enhance the command interface with more options
4. **Additional Patterns**: Implement more illumination patterns
5. **Hardware Abstraction**: Further abstract hardware specifics for portability