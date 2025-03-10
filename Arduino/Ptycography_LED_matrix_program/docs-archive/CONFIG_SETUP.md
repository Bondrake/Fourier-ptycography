# Ptycography LED Matrix Program - Configuration System

This document explains the centralized configuration system implemented for the Ptycography LED Matrix Control Program.

## Overview

To reduce code duplication and make the codebase more maintainable, we've implemented a centralized configuration system. This ensures that constants like pattern dimensions, timing parameters, and pin assignments are defined in a single location and shared across all components.

## Structure

The configuration system consists of:

1. **Arduino Configuration Header** (`libraries/PtycographyConfig.h`)
   - Contains all constants and configuration values for Arduino code
   - Uses conditional compilation (`#ifdef ARDUINO`) to separate Arduino and Processing specific values

2. **Processing Configuration Class** (`Processing/Util_ConfigManager.pde`)
   - Processing implementation of the configuration values
   - Loads/saves configuration in JSON format for persistence

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

To change configuration values (like ring sizes, timing parameters, etc.):

1. **For Arduino**:
   - Edit the appropriate section in `libraries/PtycographyConfig.h`
   - Recompile and upload the Arduino code

2. **For Processing**:
   - Use the UI controls in the Processing application to adjust parameters
   - Changes will be saved automatically to the configuration file

### Adding New Configuration Values

To add a new configuration parameter:

1. **For Arduino**:
   - Add the new parameter to `libraries/PtycographyConfig.h` in the appropriate section
   - Use the parameter in your Arduino code by including the configuration header

2. **For Processing**:
   - Add the parameter to the `ConfigManager` class in `Processing/Util_ConfigManager.pde`
   - Add UI controls to modify the parameter if needed
   - Update the `loadConfig()` and `saveConfig()` methods to handle the new parameter

## Configuration Persistence

The Processing application now uses a JSON-based configuration system:

1. **Util_ConfigManager.pde**
   - Manages loading/saving configuration values
   - Stores settings in a JSON file for persistence
   - Provides defaults for all configuration values
   - Enables configuration through the UI without code changes

### How to Use the ConfigManager

1. To access configuration in any component:
   ```java
   // Get a configuration value
   int radius = configManager.getInnerRingRadius();
   
   // Set a configuration value
   configManager.setInnerRingRadius(15);
   ```

2. To save the current configuration:
   ```java
   configManager.saveConfig();
   ```

This ensures that settings are preserved between application launches without needing to modify code.

## Future Improvements

The system could be further enhanced to:

1. Support runtime configuration through EEPROM or SD card storage
2. Add a configuration interface for adjusting parameters without recompiling
3. Extend the parser to handle more complex data types and structures

## Related Files

- `libraries/PtycographyConfig.h` - Main configuration header for Arduino
- `Processing/Util_ConfigManager.pde` - Configuration management for Processing
- `Processing/CentralController.pde` - Main Processing application
- `Processing/LED_Matrix_Hardware_Interface.ino` - Arduino hardware interface sketch

> **Note**: This documentation has been updated to reflect the new flat file structure in the Processing directory.