/**
 * Ptycography LED Matrix Control Program
 * 
 * This program controls a 64x64 RGB LED matrix for Fourier ptycography imaging applications.
 * It systematically illuminates LEDs in a specific pattern and can trigger a camera
 * for each illumination to capture the resulting diffraction patterns.
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

// Global variables for LED control
int led_x, led_y, led_color;  // Current LED position and color
IntervalTimer led_timer;      // Timer for regular LED updates

/**
 * Initializes the ring pattern for ptycography
 * Creates a pattern with three concentric rings and appropriate LED spacing
 */
void initializePattern() {
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
  LEDcenter[centerY][centerX] = 1;
  
  // Calculate number of LEDs to skip based on physical spacing
  LED_SKIP = round(TARGET_LED_SPACING_MM / LED_PITCH_MM);
  if (LED_SKIP < 1) LED_SKIP = 1; // Ensure minimum spacing of 1
  
  // Generate the ring pattern with appropriate spacing
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
      }
    }
  }
  
  // Log pattern details
  Serial.print("Generated pattern with physical spacing of ");
  Serial.print(LED_SKIP * LED_PITCH_MM);
  Serial.print("mm (every ");
  Serial.print(LED_SKIP);
  Serial.println(" LEDs)");
}

/**
 * Setup function - initializes hardware and starts the LED sequence
 */
void setup() {
// Initialize serial communication for debugging and status messages
Serial.begin(SERIAL_BAUD_RATE);
delay(SETUP_DELAY);  // Allow time for the serial connection to establish

// Initialize LED patterns
initializePattern();

// Configure all control pins as outputs
pinMode(PIN_PHOTO_TRIGGER, OUTPUT);  // Camera trigger

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

// Initialize the timer for LED updates
led_timer.begin(update_led, LED_UPDATE_INTERVAL);


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


}

/**
 * Main loop - remains mostly idle as the LED control is handled by the timer interrupt
 * and the illumination sequence is completed in setup()
 */
void loop() {
  // The main work is done in setup() and via the timer interrupt
  // This loop is intentionally kept empty with minimal delay
  delay(1);  // 1ms delay to prevent CPU hogging
}



/**
 * Triggers the camera to take a photo
 * Sends a pulse on the trigger pin to activate camera shutter
 * The pulse width is defined by CAMERA_PULSE_WIDTH
 */
void trigger_photo()
{
  digitalWrite(PIN_PHOTO_TRIGGER, HIGH);
  delay(CAMERA_PULSE_WIDTH);  // Pulse width for reliable camera triggering
  digitalWrite(PIN_PHOTO_TRIGGER, LOW);
}


/**
 * Timer callback function that updates the currently active LED
 * Called periodically by the IntervalTimer
 */
void update_led()
{
  // Note the coordinate transformation: x and y are swapped, and x is inverted
  // This accounts for the physical layout of the LED matrix
  send_led(led_y, MATRIX_WIDTH-1-led_x, led_color);
}

/**
 * Controls the LED matrix to light a specific LED with a specific color
 * 
 * @param x X-coordinate of the LED (0-63)
 * @param y Y-coordinate of the LED (0-63)
 * @param color Color value (bitwise combination of COLOR_RED, COLOR_GREEN, COLOR_BLUE)
 */
void send_led(int x, int y, int color)
{
  // Validate parameters to prevent addressing non-existent LEDs
  if(x < 0 || x >= MATRIX_WIDTH || y < 0 || y >= MATRIX_HEIGHT || color > COLOR_MAX)
    {
      return;
    }

  // Prepare the display by setting blank and latch signals
  digitalWriteFast(PIN_LED_BL, HIGH);  // Blank the display during updates
  digitalWriteFast(PIN_LED_LA, HIGH);  // Set latch high during data loading

  // Reset address lines with a quick pulse (required by some LED matrix controllers)
  digitalWrite(PIN_LED_A0, HIGH);
  digitalWrite(PIN_LED_A0, LOW);

  // Set row address bits (5-bit address for rows within each half)
  // The y%MATRIX_HALF_HEIGHT handles the half-panel addressing
  digitalWriteFast(PIN_LED_A0, y%MATRIX_HALF_HEIGHT & 1);    // A0 - LSB of row address
  digitalWriteFast(PIN_LED_A1, y%MATRIX_HALF_HEIGHT & 2);    // A1
  digitalWriteFast(PIN_LED_A2, y%MATRIX_HALF_HEIGHT & 4);    // A2
  digitalWriteFast(PIN_LED_A3, y%MATRIX_HALF_HEIGHT & 8);    // A3
  digitalWriteFast(PIN_LED_A4, y%MATRIX_HALF_HEIGHT & 16);   // A4 - MSB of row address
  
  // Shift in data for each column
  for(int i=0; i < MATRIX_WIDTH; i++)
    {
      // Calculate which half of the panel we're addressing
      bool isLowerHalf = (y < MATRIX_HALF_HEIGHT);
      bool isTargetColumn = (i == x);
      
      // Set green data pins for current column
      // G0 for lower half, G1 for upper half
      digitalWriteFast(PIN_LED_G0, isTargetColumn && isLowerHalf && (color & COLOR_GREEN));
      digitalWriteFast(PIN_LED_G1, isTargetColumn && !isLowerHalf && (color & COLOR_GREEN));

      // Set red data pins for current column
      digitalWriteFast(PIN_LED_R0, isTargetColumn && isLowerHalf && (color & COLOR_RED));
      digitalWriteFast(PIN_LED_R1, isTargetColumn && !isLowerHalf && (color & COLOR_RED));
      
      // Set blue data pins for current column
      digitalWriteFast(PIN_LED_B0, isTargetColumn && isLowerHalf && (color & COLOR_BLUE));
      digitalWriteFast(PIN_LED_B1, isTargetColumn && !isLowerHalf && (color & COLOR_BLUE));

      // Clock in the data for this column
      digitalWrite(PIN_LED_CK, HIGH);
      // Original had a 1µs delay that was commented out for speed
      digitalWrite(PIN_LED_CK, LOW);
    }
    
  // Latch the data and enable display output
  digitalWriteFast(PIN_LED_LA, LOW);   // Latch the data
  digitalWriteFast(PIN_LED_BL, LOW);   // Enable display output
}