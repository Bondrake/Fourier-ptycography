# Ptycography LED Matrix Program - Configuration System

This document explains the centralized configuration system implemented for the Ptycography LED Matrix Control Program.

## Overview

To reduce code duplication and make the codebase more maintainable, we've implemented a centralized configuration system. This ensures that constants like pattern dimensions, timing parameters, and pin assignments are defined in a single location and shared across all components.

## Structure

The configuration system consists of:

1. **Arduino Configuration Header** (`libraries/PtycographyConfig.h`)
   - Contains all constants and configuration values for Arduino code
   - Uses conditional compilation (`#ifdef ARDUINO`) to separate Arduino and Processing specific values

2. **Processing Configuration Class** (`Processing/PtycographyConfig.java`)
   - Java implementation of the same configuration values for Processing
   - Provides consistent constant definitions for the visualizer

## Advantages

This approach provides several benefits:

1. **Single Source of Truth**
   - Configuration values are defined in one place
   - Changes only need to be made once
   - Reduces the risk of inconsistencies between components

2. **Easier Maintenance**
   - Pattern parameters (like ring radii) only need to be updated in one file
   - Adding new configuration parameters is simpler

3. **Cross-Platform Consistency**
   - Arduino code and Processing visualizer use the same values
   - Visualizer accurately represents the physical LED matrix

## How to Use

### Changing Configuration Values

To change any configuration value (like ring sizes, timing parameters, etc.):

1. Edit the appropriate section in `libraries/PtycographyConfig.h`
2. Update the corresponding value in `Processing/PtycographyConfig.java`
3. Recompile and upload the Arduino code
4. Restart the Processing visualizer

### Adding New Configuration Values

To add a new configuration parameter:

1. Add the new parameter to `libraries/PtycographyConfig.h` in the appropriate section
2. Add the corresponding parameter to `Processing/PtycographyConfig.java` if needed by the visualizer
3. Use the parameter in your code by including the configuration header/class

## Future Improvements

In the future, this system could be enhanced to:

1. Automatically generate the Processing configuration class from the Arduino header file
2. Support runtime configuration through EEPROM or SD card storage
3. Add a configuration interface for adjusting parameters without recompiling

## Related Files

- `libraries/PtycographyConfig.h` - Main configuration header for Arduino
- `Processing/PtycographyConfig.java` - Configuration class for Processing
- `Ptycography_LED_matrix_program.ino` - Original Arduino sketch
- `Ptycography_LED_matrix_program_Refactored.ino` - Refactored Arduino sketch
- `Processing/LED_Matrix_Visualizer.pde` - Processing visualizer