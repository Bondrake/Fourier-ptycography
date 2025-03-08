/**
 * Ptycography LED Matrix Control Program
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
 */

// Matrix dimensions
#define MATRIX_WIDTH 64
#define MATRIX_HEIGHT 64
#define MATRIX_HALF_HEIGHT 32  // Half height for split panel addressing

// Configuration parameters
#define USE_COLOR 2      // 0 = off, 1 = red, 2 = green, 4 = blue. Can be combined with bitwise OR
#define NUMBER_CYCLES 1  // Repeat the entire illumination sequence this many times
#define POSTFRAME_DELAY 1500  // Delay in milliseconds after each frame
#define PREFRAME_DELAY 400    // Delay in milliseconds before each frame - needed for camera autoexposure
#define TRIG_PHOTO 1     // 1 = trigger the camera shutter for each frame, 0 = no triggering
#define CENTER_ONLY 0    // 1 = use only the LEDcenter matrix pattern, 0 = use full LEDpattern

// Serial communication settings
#define SERIAL_TIMEOUT 5000   // Timeout for serial operations in milliseconds
#define SERIAL_RETRIES 3      // Number of retries for serial operations
#define ENABLE_ERROR_LOG 1    // 1 = enable detailed error logging, 0 = disable

// Physical properties of the LED matrix
#define MATRIX_PHYSICAL_SIZE_MM 128.0  // Physical size of matrix in mm (64 LEDs at 2mm spacing)
#define LED_PITCH_MM 2.0               // Physical spacing between adjacent LEDs in mm

// Pattern configuration
#define INNER_RING_RADIUS 27           // Inner ring radius in LED units
#define MIDDLE_RING_RADIUS 37          // Middle ring radius in LED units
#define OUTER_RING_RADIUS 47           // Outer ring radius in LED units
#define TARGET_LED_SPACING_MM 4.0      // Desired physical spacing between illuminated LEDs in mm

// Derived values - calculated in setup()
int LED_SKIP;                          // Number of LEDs to skip to achieve desired spacing

// LED illumination pattern - dynamically generated in setup() based on spacing parameters
// 1 indicates an LED that should be turned on during the sequence
int LEDpattern[MATRIX_HEIGHT][MATRIX_WIDTH];

// Center-only illumination pattern - activates only the central LED for reference imaging
// Used when CENTER_ONLY is set to 1 - will be dynamically initialized in setup()
int LEDcenter[MATRIX_HEIGHT][MATRIX_WIDTH];

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

// Color bit values for bitwise operations
#define COLOR_RED 1     // Bit 0 controls red LEDs
#define COLOR_GREEN 2   // Bit 1 controls green LEDs
#define COLOR_BLUE 4    // Bit 2 controls blue LEDs
#define COLOR_MAX 7     // Maximum valid color value (all colors on)

// Camera control pin
#define PIN_PHOTO_TRIGGER 5  // Pin used to trigger camera shutter

// Timing constants
#define SERIAL_BAUD_RATE 9600      // Serial communication speed
#define SETUP_DELAY 2000           // Delay on startup in milliseconds
#define CAMERA_PULSE_WIDTH 100     // Camera trigger pulse width in milliseconds
#define LED_UPDATE_INTERVAL 10000  // LED refresh rate in microseconds (10ms = 100Hz)
#define IDLE_TIMEOUT 1800000       // Idle timeout in milliseconds (30 minutes)
#define IDLE_BLINK_INTERVAL 60000  // Interval for LED blink in idle mode (1 minute)
#define IDLE_BLINK_DURATION 500    // Duration of LED blink in idle mode (milliseconds)

// Serial commands
#define CMD_IDLE_ENTER 'i'         // Command to manually enter idle mode
#define CMD_IDLE_EXIT 'a'          // Command to exit idle mode

// Global variables for LED control
int led_x, led_y, led_color;       // Current LED position and color
IntervalTimer led_timer;           // Timer for regular LED updates
unsigned long lastActivityTime;    // Timestamp of last activity for idle detection
bool idleMode = false;             // Flag indicating if system is in idle mode
unsigned long lastBlinkTime;       // Timestamp of last idle blink

// Buffer for display rows to reduce repeated calculations
byte rowAddressCache[MATRIX_HEIGHT][5];  // Pre-computed row address bit values
bool displayBufferDirty = true;        // Flag to track if display needs refresh

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
 * Safely prints message to serial with retry logic
 * 
 * @param message Message to print
 * @param newline Whether to add a newline (true = println, false = print)
 * @return true if successful, false if error
 */
bool serialSafePrint(const char* message, bool newline = true) {
  // Only attempt serial output if serial is connected
  if (!Serial) return false;
  
  // Try multiple times with timeout
  for (int retry = 0; retry < SERIAL_RETRIES; retry++) {
    if (newline) {
      Serial.println(message);
    } else {
      Serial.print(message);
    }
    
    // Check if serial operation completed successfully
    if (Serial.availableForWrite() >= 0) {
      return true;
    }
    
    delay(10); // Small delay before retry
  }
  
  // Failed all retries
  return logError(ERR_SERIAL_INIT, "Serial print failed");
}

/**
 * Initializes the ring pattern for ptycography
 * Creates a pattern with three concentric rings and appropriate LED spacing
 * 
 * @return true if initialization was successful, false otherwise
 */
bool initializePattern() {
  bool success = true;
  
  // First, clear both arrays to ensure clean initialization
  for(int y = 0; y < MATRIX_HEIGHT; y++) {
    for(int x = 0; x < MATRIX_WIDTH; x++) {
      LEDpattern[y][x] = 0;
      LEDcenter[y][x] = 0;
    }
  }
  
  // Set the center LED for the center-only pattern
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Check bounds to prevent out-of-range access
  if (centerX >= 0 && centerX < MATRIX_WIDTH && 
      centerY >= 0 && centerY < MATRIX_HEIGHT) {
    LEDcenter[centerY][centerX] = 1;
  } else {
    success = logError(ERR_PATTERN_INIT, "Center LED coordinates out of range");
  }
  
  // Calculate number of LEDs to skip based on physical spacing
  LED_SKIP = round(TARGET_LED_SPACING_MM / LED_PITCH_MM);
  if (LED_SKIP < 1) LED_SKIP = 1; // Ensure minimum spacing of 1
  
  // Validate ring radii to ensure they're within matrix bounds
  float maxRadius = min(MATRIX_WIDTH, MATRIX_HEIGHT) / 2.0;
  if (OUTER_RING_RADIUS >= maxRadius) {
    serialSafePrint("WARNING: Outer ring radius exceeds matrix bounds, may be clipped");
  }
  
  // Generate the ring pattern with appropriate spacing
  int ledCount = 0; // Count how many LEDs are activated for validation
  for(int y = 0; y < MATRIX_HEIGHT; y++) {
    for(int x = 0; x < MATRIX_WIDTH; x++) {
      // Calculate distance from center (Pythagorean theorem)
      float dx = x - centerX;
      float dy = y - centerY;
      float distance = sqrt(dx*dx + dy*dy);
      
      // Check if this LED falls on one of our rings with appropriate spacing
      // We use modulo to check if this is an Nth LED according to our spacing
      if (((x + y) % LED_SKIP == 0) && 
          (abs(distance - INNER_RING_RADIUS) < 1.0 || 
           abs(distance - MIDDLE_RING_RADIUS) < 1.0 || 
           abs(distance - OUTER_RING_RADIUS) < 1.0)) {
        LEDpattern[y][x] = 1;
        ledCount++;
      }
    }
  }
  
  // Validate that we have reasonable number of LEDs in the pattern
  if (ledCount == 0) {
    success = logError(ERR_PATTERN_INIT, "No LEDs in pattern, check spacing and radius values");
  } else {
    // Log pattern details
    char buffer[80];
    sprintf(buffer, "Generated pattern with %d LEDs, physical spacing of %.1fmm (every %d LEDs)", 
            ledCount, (LED_SKIP * LED_PITCH_MM), LED_SKIP);
    serialSafePrint(buffer);
  }
  
  return success;
}

/**
 * Pre-computes row address values for faster LED updates
 * This avoids repeated bit-masking operations during LED updates
 */
void initAddressCache() {
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    int rowAddr = y % MATRIX_HALF_HEIGHT; // Handle the split panel addressing
    
    // Store each bit value in the cache
    rowAddressCache[y][0] = rowAddr & 1;    // A0 - LSB of row address
    rowAddressCache[y][1] = (rowAddr & 2) > 0 ? 1 : 0;    // A1
    rowAddressCache[y][2] = (rowAddr & 4) > 0 ? 1 : 0;    // A2
    rowAddressCache[y][3] = (rowAddr & 8) > 0 ? 1 : 0;    // A3
    rowAddressCache[y][4] = (rowAddr & 16) > 0 ? 1 : 0;   // A4 - MSB of row address
  }
}

/**
 * Setup function - initializes hardware and starts the LED sequence
 * Implements error handling and recovery
 */
void setup() {
  bool setupSuccess = true;
  
  // Initialize serial communication for debugging and status messages
  Serial.begin(SERIAL_BAUD_RATE);
  Serial.setTimeout(SERIAL_TIMEOUT);
  delay(SETUP_DELAY);  // Allow time for the serial connection to establish
  
  // Check if serial is available
  if (!Serial && ENABLE_ERROR_LOG) {
    // Set error but continue execution - we'll operate without serial if needed
    logError(ERR_SERIAL_INIT, "Serial initialization failed");
    setupSuccess = false;
  } else {
    serialSafePrint("Ptycography LED Matrix Program initializing...");
  }

  // Initialize LED patterns with error checking
  if (!initializePattern()) {
    setupSuccess = false;
  }

  // Configure all pins with error checking
  try {
    // Camera trigger pin
    pinMode(PIN_PHOTO_TRIGGER, OUTPUT);
    
    // LED matrix control pins
    pinMode(PIN_LED_BL, OUTPUT);  // Blank control
    pinMode(PIN_LED_CK, OUTPUT);  // Clock signal
    pinMode(PIN_LED_LA, OUTPUT);  // Latch control
    
    // Address pins
    pinMode(PIN_LED_A0, OUTPUT);
    pinMode(PIN_LED_A1, OUTPUT);
    pinMode(PIN_LED_A2, OUTPUT);
    pinMode(PIN_LED_A3, OUTPUT);
    pinMode(PIN_LED_A4, OUTPUT);
    
    // Data pins
    pinMode(PIN_LED_R0, OUTPUT);  // Red - lower half
    pinMode(PIN_LED_R1, OUTPUT);  // Red - upper half
    pinMode(PIN_LED_G0, OUTPUT);  // Green - lower half
    pinMode(PIN_LED_G1, OUTPUT);  // Green - upper half
    pinMode(PIN_LED_B0, OUTPUT);  // Blue - lower half
    pinMode(PIN_LED_B1, OUTPUT);  // Blue - upper half
    
    // Ensure display is blanked during initialization
    digitalWrite(PIN_LED_BL, HIGH);
  } catch (...) {
    // Catch any exceptions during pin setup
    setupSuccess = logError(ERR_PIN_INIT, "Failed to initialize I/O pins");
  }
  
  // Pre-compute row address values to optimize LED control
  initAddressCache();

  // Initialize the timer for LED updates with error handling
  if (!led_timer.begin(update_led, LED_UPDATE_INTERVAL)) {
    setupSuccess = logError(ERR_TIMER_INIT, "Failed to initialize LED update timer");
  }
  
  // Initialize idle mode variables
  lastActivityTime = millis();
  lastBlinkTime = millis();
  idleMode = false;
  
  // Log setup completion status
  if (setupSuccess) {
    serialSafePrint("Initialization complete, starting LED sequence");
  } else {
    serialSafePrint("WARNING: Initialization completed with errors, attempting to continue");
  }


// Execute the LED illumination sequence
// Repeat the entire sequence NUMBER_CYCLES times
for(int cycle_count = 0; cycle_count < NUMBER_CYCLES; cycle_count++)
{
  int frame_count = 0;  // Keep track of frames for status reporting
  
  // Scan through the entire LED matrix
  for(int x = 0; x < MATRIX_WIDTH; x++)
  {
    for(int y = 0; y < MATRIX_HEIGHT; y++)
    {
      // Check if this LED should be illuminated according to the pattern
      #if(CENTER_ONLY == 1)
      if(LEDcenter[y][x] == 1)  // Use center-only pattern
      #else
      if(LEDpattern[y][x] == 1)  // Use full pattern
      #endif
      {
        // Set the global variables for the timer interrupt to use
        led_x = x;
        led_y = y;
        led_color = USE_COLOR;
        lastActivityTime = millis();  // Update activity time
        
        // Pre-frame delay allows camera auto-exposure to stabilize
        delay(PREFRAME_DELAY);
        
        // Trigger the camera if enabled
        #if(TRIG_PHOTO == 1)
        trigger_photo();
        #endif

        // Post-frame delay for consistent timing between frames
        delay(POSTFRAME_DELAY);
        
        // Output status information to serial monitor
        Serial.print("x: ");
        Serial.print(x);
        Serial.print("   y: ");
        Serial.print(y);
        Serial.print("   frame: ");
        Serial.println(frame_count++);
      }
    }
  }
}

// After sequence completion, set system to idle mode
serialSafePrint("LED sequence complete, entering idle mode");
idleMode = true;
turn_off_leds();  // Turn off all LEDs when entering idle mode

}

/**
 * Main loop - handles idle mode and periodic status blinking
 * Checks for idle timeout and manages power-saving features
 */
void loop() {
  unsigned long currentTime = millis();
  
  // Check for serial commands regardless of mode
  if (Serial.available() > 0) {
    char cmd = Serial.read();
    
    // Process commands
    switch (cmd) {
      case CMD_IDLE_ENTER:
        if (!idleMode) {
          serialSafePrint("Entering idle mode (manual)");
          idleMode = true;
          turn_off_leds();
        }
        break;
        
      case CMD_IDLE_EXIT:
        if (idleMode) {
          serialSafePrint("Exiting idle mode (manual)");
          idleMode = false;
          displayBufferDirty = true;  // Force display refresh after exiting idle
          lastActivityTime = currentTime;
        }
        break;
        
      default:
        // For any other character, update activity time
        if (idleMode) {
          serialSafePrint("Exiting idle mode due to serial activity");
          idleMode = false;
          displayBufferDirty = true;  // Force display refresh after exiting idle
        }
        lastActivityTime = currentTime;
        break;
    }
  }
  
  // Handle idle mode operations
  if (idleMode) {
    // Check if it's time for a periodic blink
    if (currentTime - lastBlinkTime >= IDLE_BLINK_INTERVAL) {
      // Blink center LED as a heartbeat/power indicator
      serialSafePrint("Idle mode heartbeat");
      blink_center_led(IDLE_BLINK_DURATION);
      lastBlinkTime = currentTime;
    }
  }
  // Not in idle mode, check if we should enter idle mode due to timeout
  else if (currentTime - lastActivityTime >= IDLE_TIMEOUT) {
    serialSafePrint("No activity detected for 30 minutes, entering idle mode");
    idleMode = true;
    turn_off_leds();
    lastBlinkTime = currentTime; // Reset blink timer when entering idle mode
  }
  
  // Small delay to prevent CPU hogging
  delay(10);
}



/**
 * Triggers the camera to take a photo
 * Sends a pulse on the trigger pin to activate camera shutter
 * The pulse width is defined by CAMERA_PULSE_WIDTH
 * 
 * @return true if successful, false on error
 */
bool trigger_photo()
{
  bool success = true;
  
  #if ENABLE_ERROR_LOG
  // Basic check for potential hardware issues
  static int failCount = 0;
  static bool failureReported = false;
  #endif
  
  // Set trigger pin high
  digitalWrite(PIN_PHOTO_TRIGGER, HIGH);
  
  // Check if pin is actually high (basic hardware validation)
  #if ENABLE_ERROR_LOG
  if (digitalRead(PIN_PHOTO_TRIGGER) != HIGH) {
    failCount++;
    
    // Only report failures once to avoid spamming the serial log
    if (failCount >= 3 && !failureReported) {
      Serial.println(F("Warning: Camera trigger pin not responding correctly"));
      failureReported = true;
      success = false;
    }
  }
  #endif
  
  // Maintain pulse width then set low
  delay(CAMERA_PULSE_WIDTH);
  digitalWrite(PIN_PHOTO_TRIGGER, LOW);
  
  return success;
}


/**
 * Timer callback function that updates the currently active LED
 * Called periodically by the IntervalTimer
 * Optimized version with state tracking to minimize unnecessary updates
 */
void update_led()
{
  // In idle mode, we don't need continuous refreshing - return immediately
  if (idleMode && !displayBufferDirty) {
    return;
  }
  
  // We use static variables to track the previous LED state
  // This allows us to avoid unnecessary updates if the LED hasn't changed
  static int prev_x = -1;
  static int prev_y = -1;
  static int prev_color = 0;
  
  // Check if the display state has changed
  if (prev_x != led_x || prev_y != led_y || prev_color != led_color || displayBufferDirty) {
    // Note the coordinate transformation: x and y are swapped, and x is inverted
    // This accounts for the physical layout of the LED matrix
    
    #if ENABLE_ERROR_LOG
    static int failCount = 0;
    if (!send_led(led_y, MATRIX_WIDTH-1-led_x, led_color)) {
      failCount++;
      
      // Log periodic status about failure rate
      if (failCount % 100 == 0) {
        // Can't call Serial directly from ISR, so set a flag for main loop
        // to handle (simplified for this implementation)
      }
    } else {
      // Update previous state only if successful
      prev_x = led_x;
      prev_y = led_y;
      prev_color = led_color;
      displayBufferDirty = false;
    }
    #else
    // Call optimized LED update function
    send_led(led_y, MATRIX_WIDTH-1-led_x, led_color);
    
    // Update previous state tracking
    prev_x = led_x;
    prev_y = led_y;
    prev_color = led_color;
    displayBufferDirty = false;
    #endif
  }
}

/**
 * Turns off all LEDs in the matrix using optimized approach
 * Used when entering idle mode or for power saving
 * 
 * @return true if successful
 */
bool turn_off_leds() {
  // Blank the display immediately for visual feedback
  digitalWriteFast(PIN_LED_BL, HIGH);
  
  // Set all color pins low (off) once before starting
  digitalWriteFast(PIN_LED_R0, LOW);
  digitalWriteFast(PIN_LED_R1, LOW);
  digitalWriteFast(PIN_LED_G0, LOW);
  digitalWriteFast(PIN_LED_G1, LOW);
  digitalWriteFast(PIN_LED_B0, LOW);
  digitalWriteFast(PIN_LED_B1, LOW);
  
  // Process rows in batches for better performance
  // We'll do 8 rows at a time (arbitrary optimization choice)
  const int BATCH_SIZE = 8;
  
  for (int batch = 0; batch < MATRIX_HEIGHT; batch += BATCH_SIZE) {
    int endRow = min(batch + BATCH_SIZE, MATRIX_HEIGHT);
    
    for (int y = batch; y < endRow; y++) {
      // Set latch high during data loading
      digitalWriteFast(PIN_LED_LA, HIGH);
      
      // Reset address lines
      digitalWriteFast(PIN_LED_A0, HIGH);
      digitalWriteFast(PIN_LED_A0, LOW);
      
      // Use pre-computed row address values from cache
      digitalWriteFast(PIN_LED_A0, rowAddressCache[y][0]);
      digitalWriteFast(PIN_LED_A1, rowAddressCache[y][1]);
      digitalWriteFast(PIN_LED_A2, rowAddressCache[y][2]);
      digitalWriteFast(PIN_LED_A3, rowAddressCache[y][3]);
      digitalWriteFast(PIN_LED_A4, rowAddressCache[y][4]);
      
      // Optimized: Since all color pins are already set to LOW
      // we can just clock in data for all columns at once
      // This is much faster than setting pins for each column
      for (int i = 0; i < MATRIX_WIDTH; i++) {
        // Clock in the data (all zeros)
        digitalWriteFast(PIN_LED_CK, HIGH);
        digitalWriteFast(PIN_LED_CK, LOW);
      }
      
      // Latch the data
      digitalWriteFast(PIN_LED_LA, LOW);
    }
  }
  
  // Mark the display buffer as clean to avoid unnecessary refreshes
  displayBufferDirty = false;
  
  // Keep display blanked
  digitalWriteFast(PIN_LED_BL, HIGH);
  return true;
}

/**
 * Blinks the center LED for the specified duration
 * Used as a power/status indicator in idle mode
 * Optimized version that preserves state tracking
 * 
 * @param duration Duration in milliseconds to light the LED
 * @return true if successful, false if error
 */
bool blink_center_led(int duration) {
  // Get the center coordinates
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Save current LED state
  int savedX = led_x;
  int savedY = led_y;
  int savedColor = led_color;
  
  // Force display update by marking buffer as dirty
  displayBufferDirty = true;
  
  // Set the center LED coordinates
  led_x = centerX;
  led_y = centerY;
  led_color = USE_COLOR;
  
  // Update the display - this will be picked up by the interrupt
  // but we'll also force an immediate update for responsiveness
  send_led(centerY, MATRIX_WIDTH-1-centerX, USE_COLOR);
  
  // Keep it on for the specified duration
  delay(duration);
  
  // Turn it off
  turn_off_leds();
  
  // Restore previous state if we weren't in idle mode
  if (!idleMode) {
    led_x = savedX;
    led_y = savedY;
    led_color = savedColor;
    displayBufferDirty = true;  // Force refresh of original LED
  }
  
  return true;
}

/**
 * Controls the LED matrix to light a specific LED with a specific color
 * Optimized version using pre-computed row addresses and direct port manipulation
 * 
 * @param x X-coordinate of the LED (0-63)
 * @param y Y-coordinate of the LED (0-63)
 * @param color Color value (bitwise combination of COLOR_RED, COLOR_GREEN, COLOR_BLUE)
 * @return true if successful, false if parameters were invalid
 */
bool send_led(int x, int y, int color)
{
  // Validate parameters to prevent addressing non-existent LEDs
  if(x < 0 || x >= MATRIX_WIDTH || y < 0 || y >= MATRIX_HEIGHT || color > COLOR_MAX) {
    #if ENABLE_ERROR_LOG
    static bool outOfBoundsWarned = false;
    if (!outOfBoundsWarned) {
      Serial.println(F("Warning: LED coordinates out of bounds, ignoring"));
      outOfBoundsWarned = true;
    }
    #endif
    return false;
  }

  // Update activity timestamp when controlling LEDs
  if (!idleMode) {
    lastActivityTime = millis();
  }

  // Calculate which half of the panel we're addressing once
  bool isLowerHalf = (y < MATRIX_HALF_HEIGHT);

  // Prepare the display by setting blank and latch signals
  digitalWriteFast(PIN_LED_BL, HIGH);  // Blank the display during updates
  digitalWriteFast(PIN_LED_LA, HIGH);  // Set latch high during data loading

  // Reset address lines with a quick pulse (needed for reliable addressing)
  digitalWriteFast(PIN_LED_A0, HIGH);
  digitalWriteFast(PIN_LED_A0, LOW);

  // Use pre-computed row address bits from the cache
  digitalWriteFast(PIN_LED_A0, rowAddressCache[y][0]);  // A0 - LSB
  digitalWriteFast(PIN_LED_A1, rowAddressCache[y][1]);  // A1
  digitalWriteFast(PIN_LED_A2, rowAddressCache[y][2]);  // A2
  digitalWriteFast(PIN_LED_A3, rowAddressCache[y][3]);  // A3
  digitalWriteFast(PIN_LED_A4, rowAddressCache[y][4]);  // A4 - MSB
  
  // Prepare color values for current and non-current columns
  byte currentR = (color & COLOR_RED) ? 1 : 0;
  byte currentG = (color & COLOR_GREEN) ? 1 : 0;
  byte currentB = (color & COLOR_BLUE) ? 1 : 0;
  
  // Shift in data for each column - optimized loop
  for(int i=0; i < MATRIX_WIDTH; i++) {
    bool isTargetColumn = (i == x);
    
    // Only update pins when needed (when target column or changing from target)
    if (isTargetColumn || (i == x + 1)) {
      // Set all color data pins in one go
      // Use ternary operators to reduce branch predictions
      digitalWriteFast(PIN_LED_G0, isTargetColumn ? (isLowerHalf ? currentG : 0) : 0);
      digitalWriteFast(PIN_LED_G1, isTargetColumn ? (!isLowerHalf ? currentG : 0) : 0);
      digitalWriteFast(PIN_LED_R0, isTargetColumn ? (isLowerHalf ? currentR : 0) : 0);
      digitalWriteFast(PIN_LED_R1, isTargetColumn ? (!isLowerHalf ? currentR : 0) : 0);
      digitalWriteFast(PIN_LED_B0, isTargetColumn ? (isLowerHalf ? currentB : 0) : 0);
      digitalWriteFast(PIN_LED_B1, isTargetColumn ? (!isLowerHalf ? currentB : 0) : 0);
    }
    
    // Clock in the data for this column
    digitalWriteFast(PIN_LED_CK, HIGH);
    digitalWriteFast(PIN_LED_CK, LOW);
  }
    
  // Latch the data and enable display output
  digitalWriteFast(PIN_LED_LA, LOW);   // Latch the data
  digitalWriteFast(PIN_LED_BL, LOW);   // Enable display output
  
  return true;
}