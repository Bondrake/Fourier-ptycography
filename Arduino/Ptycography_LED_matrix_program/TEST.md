# Ptycography LED Matrix Controller - Testing Guide

This document provides a comprehensive approach to testing the Ptycography LED Matrix Controller, including both a test plan and specific test scripts for verification.

## 1. Test Environment

### Setup
1. Install latest Processing and required libraries
2. Clone repository
3. Open `Processing/CentralController.pde` sketch in Processing
4. Set up Arduino hardware if testing hardware integration

### Configuration
- Set up both simulation and hardware test configurations
- Create test configuration files for different patterns and settings

## 2. Unit Tests

### 2.1 Model Tests

#### PatternModel
- Test pattern generation for all pattern types
- Verify circle mask application
- Test parameter validation and bounds checking
- Verify illumination sequence generation

#### SystemStateModel  
- Test state transitions (running, paused, stopped)
- Test idle mode entry/exit
- Verify sequence tracking
- Test hardware connection state management

#### CameraModel
- Test camera settings validation
- Verify trigger timing calculations
- Test error status handling
- Validate simulation of camera triggers

### 2.2 Utility Tests

#### SerialManager
- Test command formatting
- Test serial message parsing
- Verify port connection/disconnection
- Test error handling for disconnections

#### ConfigManager
- Test loading/saving configuration
- Verify default values are applied correctly
- Test configuration validation
- Verify configuration changes are persisted

#### EventSystem
- Test event publishing/subscribing
- Verify event data passing
- Test event handler registration/unregistration
- Validate event routing

### 2.3 View Tests

#### MatrixView
- Test LED visualization based on pattern and state
- Verify grid drawing
- Test coordinate display
- Validate camera status indicator display

#### StatusPanel
- Test status information display
- Verify display updates based on state changes
- Test progress bar display
- Verify camera timing visualization

### 2.4 Controller Tests

#### AppController
- Test command routing to models
- Verify event handling
- Test hardware communication coordination
- Validate simulation mode operation

#### UIManager
- Test UI component creation
- Verify control event handling
- Test UI updates based on model changes
- Validate accordion behavior

## 3. Integration Tests

### 3.1 Model Integration
- Test interaction between PatternModel and SystemStateModel
- Verify camera model integration with state model
- Test pattern and camera model coordination

### 3.2 UI and Models
- Test UI controls updating model properties
- Verify model changes reflect in UI
- Test accordion panel switching effects on model data

### 3.3 Hardware Communication
- Test serial communication with Arduino
- Verify command/response handling
- Test connection stability
- Validate error recovery

## 4. System Tests

### 4.1 Pattern Generation and Display

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC-PG-01  | Generate and display concentric rings pattern | Pattern displays correctly with three rings at specified radii |
| TC-PG-02  | Generate and display spiral pattern | Spiral pattern with correct number of turns and radius displays |
| TC-PG-03  | Generate and display grid pattern | Grid with correct spacing and point size displays |
| TC-PG-04  | Apply circle mask to patterns | Patterns are properly masked to circular area |
| TC-PG-05  | Change pattern parameters with UI controls | Pattern updates in real-time with parameter changes |

### 4.2 Sequence Control

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC-SC-01  | Start sequence in simulation mode | LEDs illuminate in sequence matching the pattern |
| TC-SC-02  | Pause and resume sequence | Sequence pauses at current LED and resumes from same point |
| TC-SC-03  | Stop sequence | Sequence stops and resets to beginning |
| TC-SC-04  | Start sequence in hardware mode | Commands sent to Arduino and LEDs illuminate on hardware |
| TC-SC-05  | Monitor sequence progress | Progress bar and LED count updates correctly |

### 4.3 Camera Control

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC-CC-01  | Test camera trigger in simulation | Status panel shows trigger timing sequence visually |
| TC-CC-02  | Adjust camera timing parameters | Settings update correctly and impact trigger timing |
| TC-CC-03  | Test camera trigger with hardware | Arduino reports correct trigger timing and status |
| TC-CC-04  | Disable/enable camera | Status updates correctly and trigger functions enable/disable |
| TC-CC-05  | Test camera error reporting | Errors displayed correctly in status panel |

### 4.4 Idle Mode

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC-IM-01  | Enter idle mode manually | System stops sequence and shows idle status |
| TC-IM-02  | Test idle heartbeat | Center LED blinks at specified interval |
| TC-IM-03  | Exit idle mode | System resumes normal operation |
| TC-IM-04  | Test idle mode in hardware | Commands sent correctly to Arduino |

### 4.5 Hardware Connection

| Test Case | Description | Expected Result |
|-----------|-------------|-----------------|
| TC-HC-01  | Connect to Arduino hardware | Connection established and status updated |
| TC-HC-02  | Upload pattern to hardware | Pattern parameters sent correctly to Arduino |
| TC-HC-03  | Test communication error handling | Application responds gracefully to disconnection |
| TC-HC-04  | Test mode switching (Simulation/Hardware) | Application switches modes correctly |

## 5. Test Scripts

### Test Script 1: Basic UI and Rendering

#### Steps:
1. Open Processing IDE
2. Load the `Processing/CentralController.pde` file
3. Verify and run the sketch
4. Check that the application window appears with:
   - Info panel on the left
   - Matrix visualization on the right
   - UI control panels properly rendered

#### Expected:
- Application window opens with all elements visible
- No error messages in the console
- Status panel shows default values
- LED matrix shows the current pattern

### Test Script 2: Pattern Generation

#### Steps:
1. Run the application
2. Select different pattern types using the radio buttons:
   - Click on "Concentric Rings"
   - Click on "Spiral"
   - Click on "Grid"
   - Click on "Center Only"
3. For each pattern type, adjust the relevant parameters:
   - For concentric rings: adjust ring radii
   - For spiral: adjust turns and radius
   - For grid: adjust spacing and point size

#### Expected:
- Pattern type changes immediately when selected
- Parameter changes affect the visualization in real-time
- Each pattern displays correctly according to its parameters
- Default parameters for each pattern are sensible

### Test Script 3: Sequence Control

#### Steps:
1. Run the application in simulation mode
2. Click the "Start" button
3. Observe the sequence running
4. Click the "Pause" button
5. Click the "Start" button again to resume
6. Click the "Stop" button

#### Expected:
- Start: Sequence begins, LEDs light up in order
- Pause: Current LED remains lit, sequence halts
- Resume: Sequence continues from paused position
- Stop: All LEDs turn off, sequence index resets

### Test Script 4: Hardware Mode

#### Steps:
1. Connect Arduino via USB
2. Run the application
3. Set simulation mode to "Hardware" using the toggle
4. Select the correct serial port
5. Click "Connect"
6. Test pattern generation and sequence control

#### Expected:
- Application connects to Arduino
- Status panel shows "Connected"
- Commands are sent to Arduino when controls used
- LED matrix on hardware responds correctly

## 6. Performance Tests

### 6.1 Simulation Performance
- Test with maximum matrix size
- Verify performance with all LEDs active
- Measure frame rate during simulation

### 6.2 Hardware Communication Efficiency
- Measure command throughput
- Test with minimum update interval
- Verify stability over extended operation

## 7. Regression Tests

- Verify all existing functionality from original monolithic application
- Test compatibility with existing saved configurations
- Ensure consistent behavior with the original application

## 8. Reporting

1. Document test results in a standardized format
2. Report any issues with detailed reproduction steps
3. Provide screenshots or videos of failures
4. Track issues in project repository

## 9. Success Criteria

- All unit tests pass
- System tests meet expected results
- Performance matches or exceeds original application
- No regressions in functionality
- Usability tests show intuitive interaction