/**
 * LED Matrix Hardware Interface
 * 
 * This is a minimal Arduino sketch that serves as the hardware interface for
 * the Ptycography LED Matrix, receiving commands from the Processing
 * CentralController application.
 * 
 * It implements a simple serial command protocol for controlling the LED matrix
 * without requiring direct programming of the Arduino.
 */

// Matrix dimensions
#define MATRIX_WIDTH 64
#define MATRIX_HEIGHT 64
#define MATRIX_HALF_HEIGHT 32  // Half height for split panel addressing

// Pattern settings
int innerRingRadius = 16;
int middleRingRadius = 24;
int outerRingRadius = 31;
int ledSkip = 2;
int patternType = 0;  // 0 = concentric rings, 1 = center only, 2 = spiral, 3 = grid

// LED illumination pattern - dynamically generated based on parameters
boolean ledPattern[MATRIX_HEIGHT][MATRIX_WIDTH];

// Command codes
const char CMD_SET_PATTERN = 'P';     // Set pattern type
const char CMD_SET_INNER_RADIUS = 'I';  // Set inner ring radius
const char CMD_SET_MIDDLE_RADIUS = 'M'; // Set middle ring radius
const char CMD_SET_OUTER_RADIUS = 'O';  // Set outer ring radius
const char CMD_SET_SPACING = 'S';      // Set LED spacing
const char CMD_START_SEQUENCE = 'R';   // Run sequence
const char CMD_STOP_SEQUENCE = 'X';    // Stop sequence
const char CMD_ENTER_IDLE = 'i';       // Enter idle mode
const char CMD_EXIT_IDLE = 'a';        // Exit idle mode
const char CMD_SET_LED = 'L';          // Set specific LED
const char CMD_SET_CAMERA = 'C';       // Set camera trigger settings

// Status variables
boolean running = false;
boolean idleMode = false;
int currentSequenceIndex = 0;
int totalSequenceSteps = 0;

// Camera parameters
boolean cameraEnabled = true;
int cameraPreDelay = 400;    // Delay in ms before triggering (for auto-exposure)
int cameraPulseWidth = 100;  // Camera trigger pulse width in ms
int cameraPostDelay = 1500;  // Delay in ms after triggering (for capture)
#define PIN_PHOTO_TRIGGER 5  // Pin used to trigger camera shutter

// Camera status tracking
boolean cameraTriggerActive = false;
int cameraErrorCode = 0;     // 0 = no error, error codes match CameraManager

// Current LED state
int currentLedX = -1;
int currentLedY = -1;
int currentColor = 2;  // Green by default

// Timing variables
unsigned long lastUpdateTime = 0;
const unsigned long UPDATE_INTERVAL = 500;  // 500ms between LED updates
unsigned long lastIdleBlinkTime = 0;
const unsigned long IDLE_BLINK_INTERVAL = 60000;  // 60 seconds between idle blinks
const unsigned long IDLE_BLINK_DURATION = 500;    // 500ms blink duration

// LED Matrix Pin Definitions
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

// Color constants
#define COLOR_RED 1
#define COLOR_GREEN 2
#define COLOR_BLUE 4
#define COLOR_MAX 7

// Command buffer
String inputBuffer = "";
boolean commandComplete = false;

// Illumination sequence
int *sequenceX;
int *sequenceY;
int sequenceLength = 0;

void setup() {
  // Initialize serial communication
  Serial.begin(9600);
  
  // Configure LED matrix pins
  initializePins();
  
  // Generate default pattern
  generatePattern();
  
  // Generate illumination sequence
  generateSequence();
  
  // Send initial status
  sendStatus();
  
  Serial.println("LED Matrix Hardware Interface Ready");
}

void loop() {
  // Process any incoming commands
  processSerialCommands();
  
  // Update LED sequence if running
  if (running) {
    updateSequence();
  }
  
  // Handle idle mode
  if (idleMode) {
    handleIdleMode();
  }
}

void initializePins() {
  // Configure all pins for LED matrix
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
  
  // Camera control pin
  pinMode(PIN_PHOTO_TRIGGER, OUTPUT);
  digitalWrite(PIN_PHOTO_TRIGGER, LOW);
  
  // Set default states
  digitalWrite(PIN_LED_BL, HIGH);  // Blank display initially
}

void serialEvent() {
  // Read incoming serial data
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    
    // Add character to buffer if not newline
    if (inChar == '\n') {
      commandComplete = true;
    } else {
      inputBuffer += inChar;
    }
  }
}

void processSerialCommands() {
  // Process complete commands
  if (commandComplete) {
    // Get the command code (first character)
    char command = inputBuffer.charAt(0);
    String value = inputBuffer.substring(1);
    
    // Process the command
    switch (command) {
      case CMD_SET_PATTERN:
        patternType = value.toInt();
        generatePattern();
        generateSequence();
        break;
        
      case CMD_SET_INNER_RADIUS:
        innerRingRadius = value.toInt();
        generatePattern();
        generateSequence();
        break;
        
      case CMD_SET_MIDDLE_RADIUS:
        middleRingRadius = value.toInt();
        generatePattern();
        generateSequence();
        break;
        
      case CMD_SET_OUTER_RADIUS:
        outerRingRadius = value.toInt();
        generatePattern();
        generateSequence();
        break;
        
      case CMD_SET_SPACING:
        ledSkip = value.toInt();
        generatePattern();
        generateSequence();
        break;
        
      case CMD_START_SEQUENCE:
        running = true;
        idleMode = false;
        currentSequenceIndex = 0;
        break;
        
      case CMD_STOP_SEQUENCE:
        running = false;
        currentSequenceIndex = 0;
        currentLedX = -1;
        currentLedY = -1;
        turnOffLeds();
        break;
        
      case CMD_ENTER_IDLE:
        idleMode = true;
        running = false;
        currentLedX = -1;
        currentLedY = -1;
        turnOffLeds();
        lastIdleBlinkTime = millis();
        break;
        
      case CMD_EXIT_IDLE:
        idleMode = false;
        turnOffLeds();
        break;
        
      case CMD_SET_LED:
        // Format: L,x,y,color
        // Parse coordinates and color
        int commaIndex1 = value.indexOf(',');
        int commaIndex2 = value.indexOf(',', commaIndex1 + 1);
        
        if (commaIndex1 > 0 && commaIndex2 > commaIndex1) {
          int x = value.substring(0, commaIndex1).toInt();
          int y = value.substring(commaIndex1 + 1, commaIndex2).toInt();
          int color = value.substring(commaIndex2 + 1).toInt();
          
          // Set the LED
          currentLedX = x;
          currentLedY = y;
          currentColor = color;
          setLed(x, y, color);
        }
        break;
        
      case CMD_SET_CAMERA:
        // Format: C<type>,<param1>,<param2>,...
        // Parse the command type (S = settings, T = test)
        if (value.length() > 0) {
          char type = value.charAt(0);
          
          // Check for S or T commands and comma separator
          if ((type == 'S' || type == 'T') && value.indexOf(',') > 0) {
            // Extract the parameters
            value = value.substring(2);  // Skip type and comma
            
            // For S command - Settings: S,<enabled>,<preDelay>,<pulseWidth>,<postDelay>
            if (type == 'S') {
              int commaIndex1 = value.indexOf(',');
              int commaIndex2 = value.indexOf(',', commaIndex1 + 1);
              int commaIndex3 = value.indexOf(',', commaIndex2 + 1);
              
              if (commaIndex1 > 0 && commaIndex2 > commaIndex1 && commaIndex3 > commaIndex2) {
                // Parse all four parameters
                boolean newEnabled = value.substring(0, commaIndex1).toInt() != 0;
                int newPreDelay = value.substring(commaIndex1 + 1, commaIndex2).toInt();
                int newPulseWidth = value.substring(commaIndex2 + 1, commaIndex3).toInt();
                int newPostDelay = value.substring(commaIndex3 + 1).toInt();
                
                // Update camera settings
                cameraEnabled = newEnabled;
                cameraPreDelay = newPreDelay;
                cameraPulseWidth = newPulseWidth;
                cameraPostDelay = newPostDelay;
                
                Serial.println("Camera settings updated");
              }
            }
            
            // For T command - Test: T,<enabled>,<pulseWidth>
            else if (type == 'T') {
              int commaIndex = value.indexOf(',');
              
              if (commaIndex > 0) {
                // Parse the parameters
                boolean testEnabled = value.substring(0, commaIndex).toInt() != 0;
                int testPulseWidth = value.substring(commaIndex + 1).toInt();
                
                // Only proceed with test if camera is enabled
                if (testEnabled) {
                  Serial.println("Testing camera trigger...");
                  triggerCamera(testPulseWidth);
                  Serial.println("Camera test completed");
                } else {
                  Serial.println("Camera test skipped (camera disabled)");
                }
              }
            }
          }
        }
        break;
    }
    
    // Clear the buffer for the next command
    inputBuffer = "";
    commandComplete = false;
    
    // Send updated status after processing command
    sendStatus();
  }
}

void generatePattern() {
  // Clear the pattern
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      ledPattern[y][x] = false;
    }
  }
  
  // Get center coordinates
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Set the center LED for all patterns
  ledPattern[centerY][centerX] = true;
  
  // Generate pattern based on type
  switch (patternType) {
    case 0: // Concentric rings
      generateConcentricRings();
      break;
      
    case 1: // Center only
      // Center LED is already set
      break;
      
    case 2: // Spiral
      generateSpiral();
      break;
      
    case 3: // Grid
      generateGrid();
      break;
  }
  
  Serial.println("Pattern generated");
}

void generateConcentricRings() {
  // Get center coordinates
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Generate the ring pattern
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      // Skip LEDs based on spacing
      if ((x + y) % ledSkip != 0) continue;
      
      // Calculate distance from center
      float dx = x - centerX;
      float dy = y - centerY;
      float distance = sqrt(dx*dx + dy*dy);
      
      // Check if this LED falls on one of our rings
      if (abs(distance - innerRingRadius) < 1.0 || 
          abs(distance - middleRingRadius) < 1.0 || 
          abs(distance - outerRingRadius) < 1.0) {
        ledPattern[y][x] = true;
      }
    }
  }
}

void generateSpiral() {
  // Get center coordinates
  int centerX = MATRIX_WIDTH / 2;
  int centerY = MATRIX_HEIGHT / 2;
  
  // Maximum radius to stay within matrix bounds
  float maxRadius = min(centerX, centerY) - 5;
  
  // Generate the spiral
  for (float angle = 0; angle < 2 * PI * 3; angle += 0.1) {
    float radius = (angle / (2 * PI)) * maxRadius / 3;
    
    // Calculate LED coordinates (polar to cartesian conversion)
    int x = centerX + round(radius * cos(angle));
    int y = centerY + round(radius * sin(angle));
    
    // Validate coordinates and apply spacing
    if (x >= 0 && x < MATRIX_WIDTH && y >= 0 && y < MATRIX_HEIGHT && 
        ((x + y) % ledSkip == 0)) {
      ledPattern[y][x] = true;
    }
  }
}

void generateGrid() {
  // Use LED skip for grid spacing
  for (int y = 0; y < MATRIX_HEIGHT; y += ledSkip) {
    for (int x = 0; x < MATRIX_WIDTH; x += ledSkip) {
      ledPattern[y][x] = true;
    }
  }
}

void generateSequence() {
  // Count LEDs in pattern
  sequenceLength = 0;
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      if (ledPattern[y][x]) {
        sequenceLength++;
      }
    }
  }
  
  // Allocate memory for sequence
  if (sequenceX != NULL) {
    free(sequenceX);
    free(sequenceY);
  }
  
  sequenceX = (int*)malloc(sequenceLength * sizeof(int));
  sequenceY = (int*)malloc(sequenceLength * sizeof(int));
  
  // Fill sequence arrays
  int index = 0;
  for (int y = 0; y < MATRIX_HEIGHT; y++) {
    for (int x = 0; x < MATRIX_WIDTH; x++) {
      if (ledPattern[y][x]) {
        sequenceX[index] = x;
        sequenceY[index] = y;
        index++;
      }
    }
  }
  
  // Reset sequence index
  currentSequenceIndex = 0;
  totalSequenceSteps = sequenceLength;
  
  Serial.print("Sequence generated with ");
  Serial.print(sequenceLength);
  Serial.println(" steps");
}

void updateSequence() {
  // Check if it's time to update
  unsigned long currentTime = millis();
  if (currentTime - lastUpdateTime < UPDATE_INTERVAL) {
    return;
  }
  
  lastUpdateTime = currentTime;
  
  // Check if we've reached the end of the sequence
  if (currentSequenceIndex >= sequenceLength) {
    // Loop back to the beginning
    currentSequenceIndex = 0;
  }
  
  // Get the current LED coordinates
  currentLedX = sequenceX[currentSequenceIndex];
  currentLedY = sequenceY[currentSequenceIndex];
  
  // Set the LED
  setLed(currentLedX, currentLedY, COLOR_GREEN);
  
  // Send update to Processing
  sendLedUpdate();
  
  // Trigger camera if enabled
  if (cameraEnabled) {
    triggerCamera();
  }
  
  // Increment sequence index
  currentSequenceIndex++;
}

void handleIdleMode() {
  // Check if it's time for a heartbeat blink
  unsigned long currentTime = millis();
  if (currentTime - lastIdleBlinkTime >= IDLE_BLINK_INTERVAL) {
    // Blink the center LED
    int centerX = MATRIX_WIDTH / 2;
    int centerY = MATRIX_HEIGHT / 2;
    
    // Turn on center LED
    setLed(centerX, centerY, COLOR_GREEN);
    currentLedX = centerX;
    currentLedY = centerY;
    
    // Send update to Processing
    sendLedUpdate();
    
    // Schedule turning it off
    lastIdleBlinkTime = currentTime;
    
    // Create a timer to turn off after blink duration
    // In a real implementation, this would use a timer interrupt
    delay(IDLE_BLINK_DURATION);
    
    // Turn off the LED
    turnOffLeds();
    currentLedX = -1;
    currentLedY = -1;
    
    // Send update to Processing
    sendLedUpdate();
  }
}

void setLed(int x, int y, int color) {
  // In a real implementation, this would use the functions
  // from the original LED matrix code to control the hardware
  // For now, we'll just track the LED state
  
  currentLedX = x;
  currentLedY = y;
  currentColor = color;
  
  // Here would be the call to the hardware control functions:
  // sendLed(x, y, color);
}

void turnOffLeds() {
  // In a real implementation, this would turn off all LEDs
  // on the physical matrix, similar to the original code
  
  // For now, we'll just reset the state
  currentLedX = -1;
  currentLedY = -1;
}

void sendLedUpdate() {
  // Send the current LED state to Processing
  Serial.print("LED,");
  Serial.print(currentLedX);
  Serial.print(",");
  Serial.print(currentLedY);
  Serial.print(",");
  Serial.println(currentColor);
}

void sendStatus() {
  // Send status update to Processing
  // Format: STATUS,running,idle,progress,cameraEnabled,cameraTriggerActive,cameraErrorCode
  Serial.print("STATUS,");
  Serial.print(running ? "1" : "0");
  Serial.print(",");
  Serial.print(idleMode ? "1" : "0");
  Serial.print(",");
  
  // Calculate progress (0.0 to 1.0)
  float progress = 0.0;
  if (sequenceLength > 0) {
    progress = (float)currentSequenceIndex / sequenceLength;
  }
  Serial.print(progress);
  
  // Add camera status
  Serial.print(",");
  Serial.print(cameraEnabled ? "1" : "0");
  
  // Add camera trigger status (active/inactive)
  Serial.print(",");
  Serial.print(cameraTriggerActive ? "1" : "0");
  
  // Add camera error code (0 = no error)
  Serial.print(",");
  Serial.println(cameraErrorCode);
  
  // Also send detailed camera status as a separate message
  sendCameraStatus();
}

/**
 * Send detailed camera status to Processing
 * Format: CAMERA,triggerActive,errorCode
 */
void sendCameraStatus() {
  Serial.print("CAMERA,");
  Serial.print(cameraTriggerActive ? "1" : "0");
  Serial.print(",");
  Serial.println(cameraErrorCode);
}

/**
 * Trigger the camera shutter
 * 
 * @param customPulseWidth Optional custom pulse width (use default if <= 0)
 * @return True if successful, false on error
 */
bool triggerCamera(int customPulseWidth = -1) {
  // Reset error code
  cameraErrorCode = 0;
  
  // Skip if camera triggering is disabled
  if (!cameraEnabled) return true;
  
  // Set trigger state active and send status update
  cameraTriggerActive = true;
  sendCameraStatus();
  
  // Use custom or default pulse width
  int pulseWidth = (customPulseWidth > 0) ? customPulseWidth : cameraPulseWidth;
  
  // Pre-trigger delay for camera auto-exposure to adjust
  if (cameraPreDelay > 0) {
    delay(cameraPreDelay);
  }
  
  // Set trigger pin high
  digitalWrite(PIN_PHOTO_TRIGGER, HIGH);
  
  // Maintain pulse width then set low
  delay(pulseWidth);
  digitalWrite(PIN_PHOTO_TRIGGER, LOW);
  
  // Post-trigger delay to ensure image is captured
  if (cameraPostDelay > 0) {
    delay(cameraPostDelay);
  }
  
  // Reset trigger state and send status update
  cameraTriggerActive = false;
  sendCameraStatus();
  
  return true;
}