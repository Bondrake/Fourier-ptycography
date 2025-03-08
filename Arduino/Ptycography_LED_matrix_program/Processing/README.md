# LED Matrix Visualizer for Ptycography

This Processing sketch provides a dual-mode visualization system for the Ptycography LED Matrix Program. It allows you to visualize the 64x64 LED matrix without requiring physical hardware, making it ideal for testing and development.

## Features

- Real-time visualization of the 64x64 LED matrix
- Dual operation modes:
  - **Simulation Mode**: Runs the LED pattern algorithm directly within Processing
  - **Hardware Mode**: Connects to Arduino via serial to display real-time LED states
- Visual representation of the illumination pattern
- Interactive controls for testing different scenarios

## Requirements

- [Processing 3+](https://processing.org/download/)
- Arduino IDE (for hardware mode)
- Arduino with Ptycography LED Matrix Program uploaded (for hardware mode)

## Setup Instructions

1. Install Processing from [processing.org](https://processing.org/download/)
2. Open `LED_Matrix_Visualizer.pde` in Processing
3. Click the Run button (▶) to start the visualizer

### For Hardware Mode:

1. Set `#define VISUALIZATION_MODE 1` in the Arduino code
2. Upload the code to your Arduino board
3. Connect the Arduino to your computer via USB
4. Run the Processing sketch
5. Press 's' to switch to Hardware Mode
6. Press 'v' to start visualization data streaming from Arduino

## Controls

- **s**: Toggle between Simulation and Hardware modes
- **p**: Toggle between Full Pattern and Center-Only modes
- **Space**: Pause/resume the animation
- **g**: Toggle grid lines
- **r**: Reinitialize patterns

### Hardware Mode Commands

- **v**: Start visualization mode on Arduino
- **q**: Stop visualization mode on Arduino
- **i**: Enter idle mode on Arduino
- **a**: Exit idle mode on Arduino

## Validation Without Hardware

You can validate your LED pattern algorithm without physical hardware by:

1. Running the Processing sketch in Simulation Mode
2. Using an Arduino simulator like Wokwi or Tinkercad with visualization enabled
3. Connecting the Processing sketch to the simulator's serial port

## Customization

You can customize the visualization by modifying these constants in the code:

- `CELL_SIZE`: Change the size of each LED in pixels
- `UPDATE_INTERVAL`: Adjust the speed of the simulation
- Color values: Modify the RGB values for different LED colors
- Pattern parameters: Adjust ring radii and spacing to match your needs