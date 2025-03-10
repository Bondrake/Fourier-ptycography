# Error Handling Strategy

This document outlines the error handling approach for the Ptycography LED Matrix Controller application. The system provides consistent error handling, logging, and user notifications.

## Components

The error handling system consists of the following components:

1. **ErrorManager** - Centralized handling of errors
2. **ApplicationException** - Custom exception type with severity, module, and error code
3. **ErrorSeverity** - Enum for different severity levels
4. **ErrorView** - UI component for showing error notifications

## Error Severity Levels

Errors are categorized by severity:

- **DEBUG** - Low-level debug information (not shown to users)
- **INFO** - Informational messages (may be shown briefly to users)
- **WARNING** - Warnings that don't prevent operation but need attention
- **ERROR** - Errors that prevent specific operations but not the whole app
- **CRITICAL** - Critical errors that may prevent the application from functioning

## Error Flow

1. Component detects an error condition
2. Component reports error to the ErrorManager
3. ErrorManager logs the error (console and/or file)
4. ErrorManager publishes an error event
5. ErrorView subscribes to error events and displays notifications
6. Users can dismiss notifications by clicking the X button
7. Other components may subscribe to error events for recovery actions

## Using the Error System

### Reporting Errors

To report an error from anywhere in the application:

```java
// Simple error report
getErrorManager().reportError(
  "Failed to connect to hardware",
  ErrorSeverity.ERROR,
  "SerialManager",
  "HARDWARE_CONNECTION_ERROR"
);

// Error with exception
try {
  // Some code that might throw
} catch (Exception e) {
  getErrorManager().reportError(
    "Failed to perform operation: " + e.getMessage(),
    e,
    ErrorSeverity.ERROR,
    "ModuleName",
    "ERROR_CODE"
  );
}
```

### Error Codes

Error codes should follow the format:

- Uppercase with underscores 
- Prefix indicating module (e.g., `CONFIG_LOAD_ERROR`)
- Clear indication of what went wrong

Common error code prefixes:
- `CONFIG_` - Configuration-related errors
- `SERIAL_` - Serial/hardware communication errors
- `PATTERN_` - Pattern generation errors
- `UI_` - UI-related errors
- `FILE_` - File operation errors

### Recovery Strategies

Different types of errors have different recovery approaches:

- **INFO/DEBUG** - No recovery needed, just logging
- **WARNING** - Continue execution, but notify user
- **ERROR** - Attempt to recover (retry, fallback to defaults, etc.)
- **CRITICAL** - Inform user, possibly reset application state

## Testing

You can test the error system by pressing the 'E' key, which will generate errors of different severity levels.

## Best Practices

1. **Be specific** - Include enough detail to understand what went wrong
2. **Include context** - Module name, operation being performed, etc.
3. **Suggest recovery** - When possible, include recovery information
4. **Use appropriate severity** - Don't mark everything as CRITICAL
5. **Wrap external code** - Always use try/catch around external libraries
6. **Don't swallow exceptions** - Always log or report exceptions

---

*Updated March 2025*