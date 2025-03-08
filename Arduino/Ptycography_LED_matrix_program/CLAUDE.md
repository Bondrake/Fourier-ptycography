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

## Visualization System
The program includes a dual-mode visualization system that allows you to see the LED matrix state in real-time without physical hardware.

### Enabling Visualization Mode
1. Set `#define VISUALIZATION_MODE 1` in the Arduino code
2. Upload the code to the Arduino (or use a simulator)
3. Use the Processing sketch `LED_Matrix_Visualizer.pde` (in the Processing folder) to view the matrix

### Visualization Commands
- 'v' - Start visualization mode (sends LED pattern and real-time updates to visualizer)
- 'q' - Stop visualization mode
- 'p' - Export the full LED pattern to the visualizer

### Processing Visualizer Features
- Shows the 64x64 LED matrix as a grid of colored squares
- Works in two modes:
  - Simulation Mode: Runs the LED pattern algorithm within Processing
  - Hardware Mode: Connects to Arduino via serial to show real-time LED states
- Toggle between modes with 's' key
- Toggle full pattern/center-only with 'p' key
- Pause/resume with space bar
- Toggle grid lines with 'g' key

### Validation Without Hardware
1. Run the Processing sketch in Simulation Mode to validate the LED pattern algorithm
2. Run Arduino code in a simulator like Wokwi or Tinkercad with visualization enabled
3. Connect the Processing sketch to the simulator's serial port

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