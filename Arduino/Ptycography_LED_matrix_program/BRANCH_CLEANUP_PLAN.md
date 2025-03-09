# Branch Cleanup Plan for Processing-Central-Control

This document outlines the plan for cleaning up the `processing-central-control` branch by removing redundant files that are no longer needed in the central controller architecture.

## Files to Remove

### Arduino Sketches

1. **`Ptycography_LED_matrix_program.ino`**
   - This is the original Arduino sketch that is now replaced by the hardware interface in the central controller.
   - All needed functionality is integrated into the `LED_Matrix_Hardware_Interface.ino`.

2. **`Ptycography_LED_matrix_program_Refactored.ino`**
   - The refactored version is also unnecessary in the controller-centric architecture.
   - Core functionality has been adapted for the hardware interface.

## Files to Retain

### Processing Controller Files

1. **`Processing/CentralController/CentralController.pde`**
   - The main Processing controller application that serves as the central control point.

2. **`Processing/CentralController/LED_Matrix_Hardware_Interface.ino`**
   - The minimal Arduino sketch for hardware control that should be uploaded once to the Arduino/Teensy.

3. **`Processing/CentralController/README.md`**
   - Documentation for the central controller.

### ~~Visualization Tools~~ (Removed)

The separate visualization tools have been removed as they don't meet the project needs:

- ~~`Processing/OriginalPatternVisualizer/`~~
- ~~`Processing/ComparePatterns/`~~

Instead, all visualization is handled directly by the central controller.

### Configuration Files

1. **`libraries/PtycographyConfig.h`**
   - While the central controller manages most settings, this file is still useful for hardware-specific constants.

### Documentation Files

1. **`CENTRAL_CONTROLLER.md`**
   - Explains the central controller architecture.

2. **`BRANCH_CLEANUP_PLAN.md`** (this document)
   - Documents the cleanup plan.

3. **`CONFIG_SETUP.md`**
   - Documents the configuration approach.

## Implementation Steps

1. **Backup**: Create a backup of any files that will be removed, just in case they're needed for reference.

2. **Remove Redundant Files**:
   - Delete `Ptycography_LED_matrix_program.ino`
   - Delete `Ptycography_LED_matrix_program_Refactored.ino`

3. **Update Documentation**:
   - Update the main README.md to reflect that this branch uses a different architecture
   - Clarify that the central controller is the primary interface, not the Arduino sketches

4. **Final Review**:
   - Verify that all functionality needed by the central controller is available
   - Ensure no critical code has been removed

## Benefits of Cleanup

1. **Focus**: By removing redundant files, the branch focuses clearly on the central controller architecture.

2. **Clarity**: New users won't be confused by multiple approaches in the same codebase.

3. **Maintenance**: Easier to maintain with fewer files and a clear architecture.

4. **Forward-Looking**: Positions the project for future development with the central controller as the primary interface.

## After Cleanup

After the cleanup, the branch will contain only the files needed for the central controller approach, making it cleaner, more focused, and easier to understand. This supports the vision of having Processing as the single point of control for the Ptycography LED Matrix system.