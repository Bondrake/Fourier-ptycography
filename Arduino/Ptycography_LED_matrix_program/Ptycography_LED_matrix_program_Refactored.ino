/**
 * Ptycography LED Matrix Control Program (Refactored)
 * 
 * This program controls a 64x64 RGB LED matrix for Fourier ptycography imaging applications.
 * It systematically illuminates LEDs in a specific pattern and can trigger a camera
 * for each illumination to capture the resulting diffraction patterns.
 * 
 * Power Management Features:
 * - After 30 minutes of inactivity, the system enters idle mode to save power
 * - In idle mode, all LEDs are turned off except for a periodic center LED blink (once per minute)
 * - Send 'i' over serial to manually enter idle mode
 * - Send 'a' over serial (or any other character) to exit idle mode
 * 
 * Visualization Features:
 * - Send 'v' over serial to start visualization mode
 * - Send 'q' over serial to stop visualization mode
 * - Send 'p' to export the full LED pattern
 */

// Include all the module headers
#include "libraries/LEDMatrix/LEDMatrix.h"
#include "libraries/PatternGenerator/PatternGenerator.h"
#include "libraries/IdleManager/IdleManager.h"
#include "libraries/VisualizationManager/VisualizationManager.h"
#include "libraries/SerialCommandManager/SerialCommandManager.h"

// Configuration parameters
#define USE_COLOR 2      // 0 = off, 1 = red, 2 = green, 4 = blue. Can be combined with bitwise OR
#define NUMBER_CYCLES 1  // Repeat the entire illumination sequence this many times
#define POSTFRAME_DELAY 1500  // Delay in milliseconds after each frame
#define PREFRAME_DELAY 400    // Delay in milliseconds before each frame - needed for camera autoexposure
#define TRIG_PHOTO 1     // 1 = trigger the camera shutter for each frame, 0 = no triggering

// Default pattern type (can be changed at runtime)
#define DEFAULT_PATTERN_TYPE PATTERN_CONCENTRIC_RINGS // PATTERN_CENTER_ONLY, PATTERN_CONCENTRIC_RINGS

// Serial communication settings
#define SERIAL_TIMEOUT 5000   // Timeout for serial operations in milliseconds
#define SERIAL_RETRIES 3      // Number of retries for serial operations
#define ENABLE_ERROR_LOG 1    // 1 = enable detailed error logging, 0 = disable

// Physical properties of the LED matrix
#define MATRIX_PHYSICAL_SIZE_MM 128.0  // Physical size of matrix in mm (64 LEDs at 2mm spacing)
#define LED_PITCH_MM 2.0               // Physical spacing between adjacent LEDs in mm

// Pattern configuration for concentric rings
#define INNER_RING_RADIUS 27           // Inner ring radius in LED units
#define MIDDLE_RING_RADIUS 37          // Middle ring radius in LED units
#define OUTER_RING_RADIUS 47           // Outer ring radius in LED units
#define TARGET_LED_SPACING_MM 4.0      // Desired physical spacing between illuminated LEDs in mm

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

// Error handling variables
enum ErrorCode {
  ERR_NONE = 0,
  ERR_SERIAL_INIT = 1,
  ERR_PATTERN_INIT = 2,
  ERR_PIN_INIT = 3,
  ERR_TIMER_INIT = 4,
  ERR_LED_CONTROL = 5,
  ERR_CAMERA_TRIGGER = 6,
  ERR_IDLE_MODE = 7,
  ERR_POWER_MANAGEMENT = 8
};

ErrorCode lastError = ERR_NONE;  // Last error that occurred
int errorCount = 0;              // Total number of errors encountered

// Create module instances
LEDMatrix ledMatrix(
  PIN_LED_BL, PIN_LED_CK, PIN_LED_LA,
  PIN_LED_A0, PIN_LED_A1, PIN_LED_A2, PIN_LED_A3, PIN_LED_A4,
  PIN_LED_R0, PIN_LED_R1, PIN_LED_G0, PIN_LED_G1, PIN_LED_B0, PIN_LED_B1
);

PatternGenerator patternGenerator(
  MATRIX_WIDTH, MATRIX_HEIGHT, 
  MATRIX_PHYSICAL_SIZE_MM, LED_PITCH_MM
);

IdleManager idleManager(
  &ledMatrix, IDLE_TIMEOUT, IDLE_BLINK_INTERVAL, IDLE_BLINK_DURATION
);

VisualizationManager visualizationManager(
  VIS_UPDATE_INTERVAL
);

SerialCommandManager serialCommandManager(
  &idleManager, &visualizationManager, SERIAL_TIMEOUT, SERIAL_RETRIES
);

// Global state variables
bool patternInitialized = false;
IntervalTimer ledTimer;
int currentLedX = -1;
int currentLedY = -1;
int currentLedColor = 0;
bool** ledPattern = nullptr;  // Dynamic 2D array for the pattern

/**
 * Logs an error with descriptive message
 * 
 * @param code Error code from ErrorCode enum
 * @param message Descriptive error message
 * @return false (to allow inline use in boolean expressions)
 */
bool logError(ErrorCode code, const char* message) {
  lastError = code;
  errorCount++;
  
  #if ENABLE_ERROR_LOG
  // Only log error details if logging is enabled
  Serial.print(F("ERROR ["));
  Serial.print(code);
  Serial.print(F("]: "));
  Serial.println(message);
  #endif
  
  return false;
}

/**
 * Allocates memory for a 2D boolean array for the LED pattern
 * 
 * @param width Width of the array
 * @param height Height of the array
 * @return Pointer to the allocated array, or nullptr on failure
 */
bool** allocatePatternArray(int width, int height) {
  bool** array = new bool*[height];
  if (array == nullptr) return nullptr;
  
  for (int i = 0; i < height; i++) {
    array[i] = new bool[width];
    if (array[i] == nullptr) {
      // Clean up already allocated rows
      for (int j = 0; j < i; j++) {
        delete[] array[j];
      }
      delete[] array;
      return nullptr;
    }
    
    // Initialize to false
    for (int j = 0; j < width; j++) {
      array[i][j] = false;
    }
  }
  
  return array;
}

/**
 * Frees memory allocated for a 2D boolean array
 * 
 * @param array Pointer to the array
 * @param height Height of the array
 */
void freePatternArray(bool** array, int height) {
  if (array == nullptr) return;
  
  for (int i = 0; i < height; i++) {
    delete[] array[i];
  }
  delete[] array;
}

/**
 * Initialize the LED pattern
 * 
 * @return True if successful, false on error
 */
bool initializePattern() {
  // Allocate memory for the pattern
  ledPattern = allocatePatternArray(MATRIX_WIDTH, MATRIX_HEIGHT);
  if (ledPattern == nullptr) {
    return logError(ERR_PATTERN_INIT, "Failed to allocate memory for pattern");
  }
  
  // Generate the concentric rings pattern
  bool success = patternGenerator.generateConcentricRings(
    ledPattern, 
    INNER_RING_RADIUS, 
    MIDDLE_RING_RADIUS, 
    OUTER_RING_RADIUS, 
    TARGET_LED_SPACING_MM
  );
  
  if (!success) {
    return logError(ERR_PATTERN_INIT, "Failed to generate pattern");
  }
  
  // Log success
  int ledCount = patternGenerator.countActiveLEDs(ledPattern);
  char buffer[80];
  sprintf(buffer, "Generated pattern with %d LEDs", ledCount);
  serialCommandManager.safePrint(buffer);
  
  patternInitialized = true;
  return true;
}

/**
 * Timer callback function that updates the currently active LED
 */
void updateLedCallback() {
  if (currentLedX >= 0 && currentLedY >= 0 && currentLedColor > 0) {
    ledMatrix.setLED(currentLedX, currentLedY, currentLedColor);
  }
}

/**
 * Triggers the camera to take a photo
 * 
 * @return True if successful, false on error
 */
bool triggerPhoto() {
  // Set trigger pin high
  digitalWrite(PIN_PHOTO_TRIGGER, HIGH);
  
  // Maintain pulse width then set low
  delay(CAMERA_PULSE_WIDTH);
  digitalWrite(PIN_PHOTO_TRIGGER, LOW);
  
  return true;
}

/**
 * Setup function - initializes hardware and starts the LED sequence
 */
void setup() {
  // Initialize serial communication manager
  serialCommandManager.begin(SERIAL_BAUD_RATE);
  delay(SETUP_DELAY);  // Allow time for the serial connection to establish
  
  serialCommandManager.safePrint("Ptycography LED Matrix Program initializing...");
  
  // Initialize the LED matrix
  ledMatrix.begin();
  
  // Initialize the idle manager
  idleManager.begin();
  
  // Initialize the visualization manager
  visualizationManager.begin();
  
  // Initialize the pattern
  if (!initializePattern()) {
    serialCommandManager.safePrint("WARNING: Pattern initialization failed");
  }
  
  // Initialize camera trigger pin
  pinMode(PIN_PHOTO_TRIGGER, OUTPUT);
  digitalWrite(PIN_PHOTO_TRIGGER, LOW);
  
  // Initialize the timer for LED updates
  if (!ledTimer.begin(updateLedCallback, LED_UPDATE_INTERVAL)) {
    logError(ERR_TIMER_INIT, "Failed to initialize LED update timer");
    serialCommandManager.safePrint("WARNING: Timer initialization failed");
  }
  
  serialCommandManager.safePrint("Initialization complete, starting LED sequence");
  
  // Execute the LED illumination sequence
  runIlluminationSequence();
  
  // After sequence completion, set system to idle mode
  serialCommandManager.safePrint("LED sequence complete, entering idle mode");
  idleManager.enterIdleMode();
}

/**
 * Main loop function - handles serial commands and idle mode
 */
void loop() {
  // Process any serial commands
  serialCommandManager.processCommands();
  
  // Update the idle manager
  idleManager.update();
  
  // Update the visualization manager if enabled
  visualizationManager.update();
  
  // Small delay to prevent CPU hogging
  delay(10);
}

/**
 * Runs the illumination sequence through all pattern LEDs
 */
void runIlluminationSequence() {
  if (!patternInitialized || ledPattern == nullptr) {
    serialCommandManager.safePrint("ERROR: Pattern not initialized, cannot run sequence");
    return;
  }
  
  // Repeat the entire sequence NUMBER_CYCLES times
  for (int cycle_count = 0; cycle_count < NUMBER_CYCLES; cycle_count++) {
    int frame_count = 0;  // Keep track of frames for status reporting
    
    // Scan through the entire LED matrix
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      for (int y = 0; y < MATRIX_HEIGHT; y++) {
        // Check if this LED should be illuminated according to the pattern
        if (ledPattern[y][x] == true) {
          // Set the current LED coordinates and color
          currentLedX = x;
          currentLedY = y;
          currentLedColor = USE_COLOR;
          
          // Record activity to prevent idle mode
          idleManager.updateActivityTime();
          
          // Update visualization if enabled
          if (visualizationManager.isEnabled()) {
            visualizationManager.sendLEDState(x, y, currentLedColor);
          }
          
          // Pre-frame delay allows camera auto-exposure to stabilize
          delay(PREFRAME_DELAY);
          
          // Trigger the camera if enabled
          #if TRIG_PHOTO == 1
          triggerPhoto();
          #endif
          
          // Post-frame delay for consistent timing between frames
          delay(POSTFRAME_DELAY);
          
          // Output status information to serial monitor
          char buffer[80];
          sprintf(buffer, "x: %d   y: %d   frame: %d", x, y, frame_count++);
          serialCommandManager.safePrint(buffer);
        }
      }
    }
  }
  
  // Clear the LED after sequence completes
  currentLedX = -1;
  currentLedY = -1;
  currentLedColor = 0;
}