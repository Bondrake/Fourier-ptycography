# LED Matrix Visualizer Setup Guide

## Introduction and Motivation

The LED Matrix Visualizer provides two primary ways to visualize and test the Ptycography LED Matrix Program, giving you flexibility based on your available resources and development needs:

### Why Use the Visualizer?

1. **Hardware-Free Development**: Develop and test your LED patterns without requiring physical hardware, saving time and resources.
2. **Algorithm Validation**: Verify that your pattern generation algorithms produce the expected results before deploying to hardware.
3. **Debugging**: Identify and fix issues in your code by seeing a visual representation of what's happening.
4. **Education and Demonstration**: Explain how the system works to others without needing physical equipment.

### Choosing the Right Setup Path

- **Physical Hardware Path**: Use when you have the complete hardware setup including Arduino and 64x64 RGB LED matrix properly configured. This is the only path that allows you to see the actual LED patterns on physical hardware and is required for final testing and deployment.

- **Processing-Only Simulation Path**: Best for rapid development iterations and algorithm testing when you're primarily concerned with the pattern generation and not the hardware-specific aspects. This is ideal for development when you don't have access to the physical hardware.

## Setup Paths

### 1. Physical Hardware Path

**When to choose this path:**
- You have the complete hardware setup including Arduino and 64x64 RGB LED matrix
- You need to test with actual hardware timing and LED illumination
- You want to verify the complete system behavior including camera triggering
- You're in the final stages of testing before deployment

**Requirements:**
- Arduino Teensy board
- 64x64 RGB LED matrix properly connected to the Arduino
- Pin connections as defined in the LED Matrix Program
- Power supply suitable for the LED matrix
- Computer with Arduino IDE installed
- USB cable
- (Optional) Camera setup if testing the triggering mechanism

**Steps:**
1. **Verify Hardware Setup**
   - Ensure your 64x64 RGB LED matrix is properly connected to the Arduino
   - Double-check all pin connections match those defined in the program
   - Ensure proper power supply for the LED matrix

2. **Install Arduino IDE and Teensy Support**
   - Download Arduino IDE from [arduino.cc/en/software](https://arduino.cc/en/software)
   - Install Teensyduino from [pjrc.com/teensy/teensyduino.html](https://www.pjrc.com/teensy/teensyduino.html)

3. **Configure the Arduino Code**
   - Open `Ptycography_LED_matrix_program.ino` in Arduino IDE
   - Set `#define VISUALIZATION_MODE 1` to enable visualization
   - Ensure other settings match your hardware configuration

4. **Upload to Arduino**
   - Connect your Teensy board via USB
   - Select the appropriate board and port in Arduino IDE
   - Upload the code
   - Verify that the LED matrix displays the expected patterns

5. **Set Up Processing (Optional for additional visualization)**
   - Install Processing from [processing.org/download](https://processing.org/download/)
   - Open `LED_Matrix_Visualizer.pde` in Processing
   - Run the sketch and press 's' to switch to Hardware Mode
   - Press 'v' to start visualization data streaming from Arduino

**Advantages:**
- Actual physical testing with the exact hardware that will be used
- Validates LED brightness, color, and timing in real-world conditions
- Tests camera trigger functionality if connected
- Identifies hardware-specific issues that simulations might miss

**Limitations:**
- Requires complete hardware setup
- Setup can be complex and requires careful wiring
- Upload process takes time for each code change

### 2. Processing-Only Simulation Path

**When to choose this path:**
- You don't have access to the physical hardware setup
- You're primarily focused on pattern algorithm development
- You want the fastest development iteration cycle
- You're teaching or demonstrating the pattern concepts
- You're in early development stages

**Requirements:**
- Computer with Processing installed
- No Arduino hardware needed

**Steps:**
1. **Install Processing**
   - Download from [processing.org/download](https://processing.org/download/)
   - Install and launch

2. **Open and Run the Visualizer**
   - Open `LED_Matrix_Visualizer.pde`
   - Run the sketch (it starts in Simulation Mode by default)
   - Use keyboard controls to manipulate the visualization:
     - 'p' to toggle between full pattern and center-only
     - Space to pause/resume
     - 'g' to toggle grid lines
     - 'r' to reinitialize patterns

**Advantages:**
- Fastest development iteration
- No hardware dependencies
- Focus solely on pattern algorithms
- Great for teaching and demonstrations
- Can be used anywhere, regardless of hardware availability

**Limitations:**
- Doesn't test hardware-specific behavior
- Cannot test actual LED brightness and color reproduction
- Cannot verify camera triggering functionality
- Simulated timing may differ from actual hardware behavior

## Troubleshooting Common Issues

### Physical Hardware Issues
- **Issue**: LED matrix doesn't display the expected pattern
  - **Solution**: Verify all pin connections match the definitions in the code
  - **Solution**: Check power supply is adequate for the LED matrix
  - **Solution**: Test each LED color channel individually
  - **Solution**: Verify the LED matrix addressing method matches what's in the code

### Serial Connection Problems
- **Issue**: Processing can't connect to Arduino
  - **Solution**: Ensure the correct port is selected and no other program is using it
  - **Solution**: Close Arduino Serial Monitor before connecting with Processing
  - **Solution**: Try a different USB port or cable

### Display Issues
- **Issue**: Visualization doesn't match expected pattern
  - **Solution**: Verify pattern generation parameters match between Arduino and Processing
  - **Solution**: Check for coordinate transformation issues in the visualization
  - **Solution**: Use serial logging to debug pattern generation

### Performance Problems
- **Issue**: Visualization runs slowly
  - **Solution**: Reduce the cell size or increase update interval
  - **Solution**: Simplify the pattern for testing
  - **Solution**: Close other applications to free up resources

## Additional Resources

- [Processing Documentation](https://processing.org/reference/)
- [Arduino Documentation](https://www.arduino.cc/reference/en/)
- [Teensy Documentation](https://www.pjrc.com/teensy/)