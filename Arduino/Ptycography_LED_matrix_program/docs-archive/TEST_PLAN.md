# Ptycography LED Matrix Controller Test Plan

This document outlines the test plan for verifying the functionality of the refactored Ptycography LED Matrix Controller application.

## 1. Test Environment

### Setup
- Processing IDE 4.0+
- Arduino IDE 2.0+
- Optional: Arduino hardware (Uno/Mega/Teensy)
- Optional: LED matrix hardware for full end-to-end testing

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

## 5. Usability Tests

### 5.1 UI Responsiveness
- Test UI responsiveness with large patterns
- Verify smooth drawing with simulation running
- Test accordion panels opening/closing fluidity

### 5.2 Error Handling
- Test application behavior with invalid inputs
- Verify user feedback for error conditions
- Test recovery from serial communication errors

### 5.3 User Workflow
- Test common user workflows for pattern creation
- Verify ease of adjusting parameters
- Test switching between different patterns

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

## 8. Test Execution Procedure

### 8.1 Setup
1. Install latest Processing and required libraries
2. Clone repository
3. Open `Processing/CentralController.pde` sketch in Processing
4. Set up Arduino hardware if testing hardware integration

### 8.2 Execution
1. Run unit tests (manual or automated)
2. Execute integration tests
3. Perform system tests according to test cases
4. Conduct usability tests with test users
5. Run performance tests under different conditions

### 8.3 Reporting
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

## 10. Testing Schedule

1. Unit and Integration Testing: 2 days
2. System Testing: 3 days
3. Usability Testing: 1 day
4. Performance Testing: 1 day
5. Regression Testing: 1 day

## 11. Tooling and Resources

- Processing IDE for runtime testing
- Arduino IDE for hardware testing
- Simulation mode for hardware-independent testing
- Version control for tracking test code
- Test data sets for consistent testing