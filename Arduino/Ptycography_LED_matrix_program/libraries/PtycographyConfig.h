/**
 * PtycographyConfig.h
 * 
 * Centralized configuration file for Ptycography LED Matrix Control Program
 * Contains all shared constants and configuration values to avoid duplication
 * across multiple files.
 * 
 * This file can be included by both Arduino code and Processing (with appropriate guards)
 */

#ifndef PTYCOGRAPHY_CONFIG_H
#define PTYCOGRAPHY_CONFIG_H

// Matrix dimensions
#define MATRIX_WIDTH 64
#define MATRIX_HEIGHT 64
#define MATRIX_HALF_HEIGHT 32  // Half height for split panel addressing

// Physical properties of the LED matrix
#define MATRIX_PHYSICAL_SIZE_MM 128.0  // Physical size of matrix in mm (64 LEDs at 2mm spacing)
#define LED_PITCH_MM 2.0               // Physical spacing between adjacent LEDs in mm

// Pattern configuration
#define INNER_RING_RADIUS 16           // Inner ring radius in LED units
#define MIDDLE_RING_RADIUS 24          // Middle ring radius in LED units
#define OUTER_RING_RADIUS 31           // Outer ring radius in LED units (max for 64x64 matrix is 32)
#define TARGET_LED_SPACING_MM 4.0      // Desired physical spacing between illuminated LEDs in mm

// Color bit values for bitwise operations
#define COLOR_RED 1     // Bit 0 controls red LEDs
#define COLOR_GREEN 2   // Bit 1 controls green LEDs
#define COLOR_BLUE 4    // Bit 2 controls blue LEDs
#define COLOR_MAX 7     // Maximum valid color value (all colors on)

// Configuration parameters
#define USE_COLOR 2      // 0 = off, 1 = red, 2 = green, 4 = blue. Can be combined with bitwise OR
#define NUMBER_CYCLES 1  // Repeat the entire illumination sequence this many times
#define POSTFRAME_DELAY 1500  // Delay in milliseconds after each frame
#define PREFRAME_DELAY 400    // Delay in milliseconds before each frame - needed for camera autoexposure
#define TRIG_PHOTO 1     // 1 = trigger the camera shutter for each frame, 0 = no triggering

// Pattern types (for PatternGenerator)
#define PATTERN_CONCENTRIC_RINGS 0
#define PATTERN_CENTER_ONLY 1
#define PATTERN_SPIRAL 2
#define PATTERN_GRID 3

// Arduino-specific configuration
#ifdef ARDUINO

// Serial communication settings
#define SERIAL_TIMEOUT 5000   // Timeout for serial operations in milliseconds
#define SERIAL_RETRIES 3      // Number of retries for serial operations
#define ENABLE_ERROR_LOG 1    // 1 = enable detailed error logging, 0 = disable

// Timing constants
#define SERIAL_BAUD_RATE 9600      // Serial communication speed
#define SETUP_DELAY 2000           // Delay on startup in milliseconds
#define CAMERA_PULSE_WIDTH 100     // Camera trigger pulse width in milliseconds
#define LED_UPDATE_INTERVAL 10000  // LED refresh rate in microseconds (10ms = 100Hz)
#define IDLE_TIMEOUT 1800000       // Idle timeout in milliseconds (30 minutes)
#define IDLE_BLINK_INTERVAL 60000  // Interval for LED blink in idle mode (1 minute)
#define IDLE_BLINK_DURATION 500    // Duration of LED blink in idle mode (milliseconds)
#define VIS_UPDATE_INTERVAL 100    // Update visualization data every 100ms

// LED Matrix Pin Definitions
// These pins control the 64x64 RGB LED matrix
#define PIN_LED_BL 25  // Blank control
#define PIN_LED_CK 26  // Clock signal
#define PIN_LED_A2 27  // Address bit A2
#define PIN_LED_A0 28  // Address bit A0
#define PIN_LED_B1 29  // Blue data for second half of display
#define PIN_LED_R1 30  // Red data for second half of display
#define PIN_LED_B0 31  // Blue data for first half of display
#define PIN_LED_R0 32  // Red data for first half of display
#define PIN_LED_LA 42  // Latch control
#define PIN_LED_A3 43  // Address bit A3
#define PIN_LED_A1 44  // Address bit A1
#define PIN_LED_A4 45  // Address bit A4
#define PIN_LED_G1 46  // Green data for second half of display
#define PIN_LED_G0 47  // Green data for first half of display

// Camera control pin
#define PIN_PHOTO_TRIGGER 5  // Pin used to trigger camera shutter

// Serial commands
#define CMD_IDLE_ENTER 'i'         // Command to manually enter idle mode
#define CMD_IDLE_EXIT 'a'          // Command to exit idle mode
#define CMD_VIS_START 'v'          // Command to start visualization mode
#define CMD_VIS_STOP 'q'           // Command to stop visualization mode
#define CMD_PATTERN_EXPORT 'p'     // Command to export the full pattern
#define CMD_SET_CAMERA 'C'         // Command to configure camera settings

#endif // ARDUINO

// Process-specific configuration 
#ifndef ARDUINO  // Processing doesn't define ARDUINO

// These values will be used for the Processing visualizer
#define CELL_SIZE 8               // Size of each LED in pixels
#define GRID_PADDING_LEFT 240     // Left padding for grid
#define GRID_PADDING_TOP 50       // Top padding for grid
#define INFO_PANEL_WIDTH 220      // Width of the info panel on the left
#define UPDATE_INTERVAL 500       // Update interval in milliseconds

// Color definitions for Processing
// Note: These will be handled differently in Processing code

// Serial commands (same as Arduino)
#define CMD_IDLE_ENTER 'i'
#define CMD_IDLE_EXIT 'a'
#define CMD_VIS_START 'v'
#define CMD_VIS_STOP 'q'
#define CMD_PATTERN_EXPORT 'p'

#endif // !ARDUINO

#endif // PTYCOGRAPHY_CONFIG_H