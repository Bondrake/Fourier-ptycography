# Testing Script for Refactored Ptycography LED Matrix Controller

This script provides step-by-step instructions for testing the core functionality of the refactored application.

## Setup

1. Open Processing IDE
2. Load the `Processing/CentralController/Refactored_CentralController.pde` file
3. Verify and run the sketch (Press Play button)

## Test Case 1: Basic UI and Rendering

### Steps:
1. Check that the application window appears with:
   - Info panel on the left
   - Matrix visualization on the right
   - UI control panels properly rendered

### Expected:
- Application window opens with all elements visible
- No error messages in the console
- Status panel shows default values
- LED matrix shows the current pattern

## Test Case 2: Pattern Generation

### Steps:
1. Select different pattern types using the radio buttons:
   - Click on "Concentric Rings"
   - Click on "Spiral"
   - Click on "Grid"
   - Click on "Center Only"

### Expected:
- LED matrix visualization updates for each pattern
- Pattern parameters update in UI controls
- Status panel updates to show current pattern type
- No errors occur during pattern switching

## Test Case 3: Parameter Adjustment

### Steps:
1. Select "Concentric Rings" pattern
2. Adjust sliders for inner, middle, and outer ring radius
3. Select "Grid" pattern
4. Adjust sliders for grid spacing and point size

### Expected:
- LED pattern updates in real-time as sliders change
- Changes are reflected immediately in the visualization
- Pattern changes maintain consistency when switching between types

## Test Case 4: Simulation Control

### Steps:
1. Make sure "Simulation Mode" is enabled
2. Click "Start" button to start the illumination sequence
3. Observe LEDs illuminating in sequence
4. Click "Pause" button
5. Click "Pause" again to resume
6. Click "Stop" button

### Expected:
- Sequence starts with first LED in pattern
- LEDs illuminate one by one in sequence
- Progress is shown in status panel
- Pause/resume functionality works correctly
- Stop resets to beginning of sequence

## Test Case 5: Idle Mode

### Steps:
1. Toggle "Idle Mode" on
2. Observe center LED heartbeat
3. Toggle "Idle Mode" off

### Expected:
- System enters idle mode
- Center LED blinks at defined interval (approximately once per minute, but may be set to shorter interval for testing)
- System exits idle mode when toggled off

## Test Case 6: Grid Visibility

### Steps:
1. Toggle "Show Grid" on and off
2. Observe changes in matrix visualization

### Expected:
- Grid lines appear when enabled
- Grid lines disappear when disabled
- Pattern visualization remains unaffected

## Test Case 7: Camera Simulation

### Steps:
1. Check "Enable Camera Trigger" in Camera Control panel
2. Click "Test Camera Trigger" button
3. Observe status panel for trigger indication

### Expected:
- Camera status shows as enabled
- Trigger sequence is simulated and shown in status panel
- Timing visualization shows pre-delay, pulse, and post-delay

## Test Case 8: Circle Mask

### Steps:
1. Toggle "Circle Mask" on
2. Adjust "Mask Radius" slider
3. Toggle "Circle Mask" off

### Expected:
- Pattern is masked to a circle when enabled
- Circle size changes with radius slider
- Full pattern is visible when mask is disabled

## Test Case 9: Handling Window Resize

### Steps:
1. Resize the application window
2. Observe how UI elements adapt

### Expected:
- LED matrix visualization resizes appropriately
- UI controls remain accessible
- No rendering artifacts or cutoff elements

## Notes:

- If any test fails, note the specific behavior observed
- Check the console for error messages
- Compare behavior with the original non-refactored application
- For hardware testing, additional steps will be needed with Arduino hardware connected

## Reporting Issues:

For any issues found, please document:
1. Test case number and step where the issue occurred
2. Expected behavior
3. Actual behavior
4. Console output/error messages if applicable
5. Steps to reproduce consistently