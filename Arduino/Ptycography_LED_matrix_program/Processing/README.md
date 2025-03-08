# Central Controller for Ptycography LED Matrix

This directory contains the Processing central controller for the Ptycography LED Matrix system. This controller is the single point of control for both simulation and hardware operation.

## Central Controller

The CentralController provides a comprehensive interface for controlling all aspects of the LED matrix system.

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

## Setup Instructions

1. Install Processing from [processing.org](https://processing.org/)
2. Install the ControlP5 library:
   - Sketch > Import Library > Add Library
   - Search for "ControlP5"
   - Click "Install"
3. Open the CentralController sketch
4. Connect your Arduino (if using hardware mode)
5. Click the Run button (▶) in the Processing IDE

## Architecture Notes

- The central controller is the only interface needed for the system
- Parameters are adjustable through the UI without reprogramming the Arduino
- The hardware interface on Arduino only needs to be uploaded once
- Pattern generation can happen either in Processing (simulation) or on the Arduino (hardware)
- The maximum radius that fits within a 64x64 matrix is 32 LED units