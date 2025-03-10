# Ptycography LED Matrix Program - Development Guide

## Build/Upload Commands
- Compile and upload to Arduino: Arduino IDE → Verify/Upload button
- Verify Arduino code: Arduino IDE → Sketch → Verify/Compile
- Serial Monitor: Arduino IDE → Tools → Serial Monitor (9600 baud)

## Operation Instructions
- After running the illumination sequence, the program enters idle mode automatically after 30 minutes
- Serial Commands:
  - 'i' - Manually enter idle mode (turns off LEDs, blinks center LED once per minute)
  - 'a' - Manually exit idle mode
  - Any other character will also exit idle mode

## Control System
The system uses a central controller architecture with a Processing application as the primary interface.

### Central Controller Features
1. Open and run the Processing sketch `Processing/CentralController.pde`
2. The application provides visualization and control in one interface
3. Use the UI controls to adjust pattern parameters and control the sequence

### Simulation Mode
- By default, the system runs in simulation mode (no hardware required)
- Shows a real-time visualization of the LED matrix
- Allows testing patterns and sequences without physical hardware
- Toggle grid lines with 'g' key
- Zoom in/out with '+' and '-' keys

### Hardware Mode
1. Upload `Processing/LED_Matrix_Hardware_Interface.ino` to your Arduino/Teensy
2. Connect the Arduino via USB
3. In the Processing app, toggle "Simulation Mode" off in the Hardware panel
4. Select the Arduino's serial port and click "Connect to Hardware"
5. Once connected, all commands will be sent to the physical hardware

### Validation Without Hardware
1. Run the Processing application in Simulation Mode
2. Test different patterns and configurations in the UI
3. For hardware testing, you can use a simulator like Wokwi or Tinkercad

## Code Style Guidelines
- Constants: Use `#define NAME VALUE` for program configuration
- Arrays: Define with global scope, use descriptive names (LEDpattern, LEDcenter)
- Pin Definitions: Use `#define PIN_LED_XX PIN_NUMBER` format
- Color Constants: Use power-of-2 values for bitwise operations
- Function Naming: Use snake_case (update_led, trigger_photo)
- Variable Naming: Use snake_case for local variables
- Digital IO: Use digitalWriteFast() for performance-critical operations
- Error Handling: Use bounds checking before array access or pin operations
- Parameter Validation: Validate function inputs (see send_led function)
- Timing: Use IntervalTimer for regular callbacks instead of delay loops
- Comments: Add comments for non-obvious functionality

## Power Management Features
- Idle Mode: After 30 minutes of inactivity, system enters power-saving idle mode
- Heartbeat: During idle, system blinks center LED once per minute to indicate power
- Manual Control: Use serial commands to manually enter/exit idle mode
- Activity Tracking: System tracks activity based on LED control and serial communication

## Performance Optimizations
- Row Address Caching: Pre-computed row addressing for faster LED updates
- State Tracking: Minimizes unnecessary display updates when LED state hasn't changed
- Batch Processing: Turn off LEDs in batches for better performance
- Display Buffer Dirty Flag: Tracks when updates are needed to avoid redundant refreshes
- Pin State Optimization: Uses single pin settings for multiple column clocks
- Interrupt Optimization: Skips LED updates in idle mode to reduce CPU usage

## Processing Code Organization

The Processing code follows a flat file structure with consistent naming prefixes:

- `Model_*.pde` - Data models (PatternModel, SystemStateModel, CameraModel)
- `View_*.pde` - UI components (MatrixView, StatusPanelView)
- `Controller_*.pde` - Application logic (AppController)
- `Util_*.pde` - Utilities (ConfigManager, EventSystem, SerialManager, UIManager)
- `CentralController.pde` - Main application entry point