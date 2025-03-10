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

1. **`Processing/CentralController.pde`**
   - The main Processing controller application that serves as the central control point.

2. **`Processing/LED_Matrix_Hardware_Interface.ino`**
   - The minimal Arduino sketch for hardware control that should be uploaded once to the Arduino/Teensy.

3. **`Processing/README.md`**
   - Documentation for the central controller.

> **Note**: The Processing files have been restructured to use a flat directory structure (instead of subdirectories) for better compatibility with Processing requirements.

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

3. **`DOCUMENTATION_UPDATE.md`**
   - Summarizes the state of current documentation.

> **Note**: Some documentation files have been consolidated. See `DOCUMENTATION_UPDATE.md` for details.

## Implementation Steps

1. **Backup**: Create a backup of any files that will be removed, just in case they're needed for reference.
   - ✅ Backups created in `Processing/backup_YYYYMMDD/` directories

2. **Remove Redundant Files**:
   - ✅ Delete `Ptycography_LED_matrix_program.ino`
   - ✅ Delete `Ptycography_LED_matrix_program_Refactored.ino`
   - ✅ Remove nested directory structure in Processing folder
   - ✅ Consolidate redundant documentation

3. **Update Documentation**:
   - ✅ Update the main README.md to reflect the new architecture
   - ✅ Update file paths in all documentation
   - ✅ Add information about flat directory structure
   - ✅ Create DOCUMENTATION_UPDATE.md for documentation overview

4. **Final Review**:
   - ✅ Verify that all functionality needed by the central controller is available
   - ✅ Ensure no critical code has been removed

## Benefits of Cleanup

1. **Focus**: By removing redundant files, the branch focuses clearly on the central controller architecture.

2. **Clarity**: New users won't be confused by multiple approaches in the same codebase.

3. **Maintenance**: Easier to maintain with fewer files and a clear architecture.

4. **Forward-Looking**: Positions the project for future development with the central controller as the primary interface.

## After Cleanup

After the cleanup, the branch will contain only the files needed for the central controller approach, making it cleaner, more focused, and easier to understand. This supports the vision of having Processing as the single point of control for the Ptycography LED Matrix system.

## Implementation Update - April 2025

The planned cleanup has been completed:

1. ✅ **Processing Code Restructuring**:
   - All Processing code reorganized into a flat directory structure
   - Files use prefixes (Model_, View_, Controller_, Util_) for organization
   - Processing compatibility issues fixed (color type/parameter handling, static enums)

2. ✅ **Documentation Consolidation**:
   - Processing-specific documentation consolidated in `Processing/README.md`
   - Detailed documentation status cataloged in `DOCUMENTATION_UPDATE.md`
   - All file paths updated throughout documentation

3. ✅ **Cleanup Result**:
   - Cleaner structure with better Processing compatibility
   - More maintainable codebase with consistent organization
   - Easier onboarding for new developers

The branch now has a practical, sustainable structure that works well with Processing's requirements while maintaining good code organization.