# Ptycography LED Matrix Program - Development Guide

## Build/Upload Commands
- Compile and upload to Arduino: Arduino IDE → Verify/Upload button
- Verify Arduino code: Arduino IDE → Sketch → Verify/Compile
- Serial Monitor: Arduino IDE → Tools → Serial Monitor (9600 baud)

## Code Style Guidelines
- Constants: Use `#define NAME VALUE` for program configuration
- Arrays: Define with global scope, use descriptive names (LEDpattern, LEDcenter)
- Pin Definitions: Use `#define PIN_LED_XX PIN_NUMBER` format
- Color Constants: Use power-of-2 values for bitwise operations
- Function Naming: Use snake_case (update_led, trigger_photo)
- Variable Naming: Use snake_case for local variables
- Digital IO: Use digitalWriteFast() for performance-critical operations
- Error Handling: Use bounds checking before array access or pin operations
- Parameter Validation: Validate function inputs (see send_led function)
- Timing: Use IntervalTimer for regular callbacks instead of delay loops
- Comments: Add comments for non-obvious functionality