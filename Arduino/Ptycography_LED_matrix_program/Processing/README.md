# Processing Visualizers for Ptycography LED Matrix

This directory contains several Processing sketches for visualizing and controlling the LED patterns used in the Ptycography LED Matrix program. 

- The main visualizer integrates with the Arduino hardware
- The CentralController provides a unified control interface
- Additional tools help visualize and compare patterns

## Available Visualizers

### 1. LED_Matrix_Visualizer
The main visualizer that displays the LED matrix in real-time or simulation mode. This visualizer is fully integrated with the Arduino code.

**Features:**
- Simulation Mode: Runs the LED pattern algorithm within Processing
- Hardware Mode: Connects to Arduino via serial to display real-time LED states
- Toggle between full pattern and center-only modes
- Regenerate configuration from Arduino header file

**Usage:**
- Press 's' to toggle between simulation and hardware modes
- Press 'p' to toggle between full pattern and center-only modes
- Press 'space' to pause/resume the animation
- Press 'g' to toggle grid lines
- Press 'c' to regenerate config from Arduino header file

### 2. OriginalPatternVisualizer
Displays the original LED pattern from the first version of the Arduino program, showing how the concentric rings were initially defined.

**Usage:**
- Open Processing and load the `OriginalPatternVisualizer/OriginalPatternVisualizer.pde` sketch
- Press 'g' to toggle grid lines
- Press 's' to save the pattern as an image

### 3. ComparePatterns
Shows the original and resized LED patterns side by side for direct comparison, clearly illustrating how the resized pattern fits within the matrix boundaries.

**Usage:**
- Open Processing and load the `ComparePatterns/ComparePatterns.pde` sketch
- Press 'g' to toggle grid lines (also shows the maximum radius circle)
- Press 's' to save the comparison as an image

### 4. CentralController
A comprehensive application that serves as the central control point for the entire system, supporting both simulation and hardware control through a unified interface.

**Features:**
- Complete UI for all pattern parameters and sequence control
- Hardware mode for controlling physical LED matrix via Arduino/Teensy
- Simulation mode for running without hardware
- Multiple pattern types (concentric rings, center only, spiral, grid)
- Real-time parameter adjustments without reprogramming Arduino
- Full status display and progress tracking

**Usage:**
- Install the ControlP5 library in Processing
- Upload the `CentralController/LED_Matrix_Hardware_Interface.ino` to your Arduino/Teensy (once only)
- Open the `CentralController/CentralController.pde` sketch
- Use the control panel to adjust settings and control the system
- See `CentralController/README.md` for detailed instructions

This controller is part of the central controller architecture available in the `processing-central-control` branch.

## Setup Instructions

1. Install Processing from [processing.org](https://processing.org/)
2. Open Processing and load the desired sketch
3. Connect your Arduino (if using hardware mode with the main visualizer)
4. Click the Run button (▶) in the Processing IDE

## Notes

- Each visualizer is in its own directory to avoid naming conflicts
- The original pattern used rings with radii of 27, 37, and 47 LED units
- The resized pattern uses rings with radii of 16, 24, and 31 LED units
- The maximum radius that fits within a 64x64 matrix is 32 LED units