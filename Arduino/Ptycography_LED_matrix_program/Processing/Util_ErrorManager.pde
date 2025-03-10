/**
 * Util_ErrorManager.pde
 * 
 * A centralized error handling system for the Ptycography application.
 * This class provides consistent logging, recovery strategies, and
 * user notifications for errors throughout the application.
 * 
 * The error manager uses the event system to notify components of errors,
 * allowing for decoupled error handling and reporting.
 */

/**
 * Error severity levels
 */
enum ErrorSeverity {
  DEBUG,    // Low-level debug information, not shown to users
  INFO,     // Informational messages, may be shown to users
  WARNING,  // Warnings that don't prevent operation but need attention
  ERROR,    // Errors that prevent specific operations but not the whole app
  CRITICAL  // Critical errors that may prevent the application from functioning
}

/**
 * Custom exception class for application errors
 */
class ApplicationException extends Exception {
  private ErrorSeverity severity;
  private String module;
  private String errorCode;
  
  /**
   * Create a new application exception
   * 
   * @param message The error message
   * @param severity The error severity
   * @param module The module where the error occurred
   * @param errorCode A specific error code if available
   */
  public ApplicationException(String message, ErrorSeverity severity, String module, String errorCode) {
    super(message);
    this.severity = severity;
    this.module = module;
    this.errorCode = errorCode;
  }
  
  /**
   * Create a new application exception with a cause
   * 
   * @param message The error message
   * @param cause The underlying cause
   * @param severity The error severity
   * @param module The module where the error occurred
   * @param errorCode A specific error code if available
   */
  public ApplicationException(String message, Throwable cause, ErrorSeverity severity, String module, String errorCode) {
    super(message, cause);
    this.severity = severity;
    this.module = module;
    this.errorCode = errorCode;
  }
  
  // Getters
  public ErrorSeverity getSeverity() { return severity; }
  public String getModule() { return module; }
  public String getErrorCode() { return errorCode; }
}

// Add error events to EventType
static final class ErrorEventType {
  public static final String ERROR_OCCURRED = "error_occurred";
  public static final String ERROR_CLEARED = "error_cleared";
}

/**
 * ErrorManager provides centralized error handling for the application.
 * 
 * This class handles logging, recovery, and notification of errors.
 * It's implemented as a singleton to ensure centralized error handling.
 */
 
// Singleton instance - must be outside the class for Processing compatibility
ErrorManager errorManagerInstance = null;

// Global function to get ErrorManager instance (Processing compatibility)
ErrorManager getErrorManager() {
  if (errorManagerInstance == null) {
    errorManagerInstance = new ErrorManager();
  }
  return errorManagerInstance;
}

/**
 * ErrorManager class for centralized error handling
 */
class ErrorManager extends EventDispatcher {
  // Current active errors
  private ArrayList<ApplicationException> activeErrors;
  
  // Maximum number of errors to keep in history
  private static final int MAX_ERROR_HISTORY = 100;
  // Error history for debugging
  private ArrayList<ApplicationException> errorHistory;
  
  // Flag for whether to log to console
  private boolean logToConsole = true;
  // Flag for whether to log to file
  private boolean logToFile = false;
  // Log file path
  private String logFilePath = "error_log.txt";
  
  /**
   * Constructor
   */
  private ErrorManager() {
    activeErrors = new ArrayList<ApplicationException>();
    errorHistory = new ArrayList<ApplicationException>();
    
    // Create log file if logging to file is enabled
    if (logToFile) {
      try {
        java.io.PrintWriter writer = new java.io.PrintWriter(new java.io.FileWriter(logFilePath, true));
        writer.println("--- Error Log Started: " + new java.util.Date() + " ---");
        writer.close();
      } catch (Exception e) {
        println("Failed to create error log file: " + e.getMessage());
        logToFile = false;
      }
    }
  }
  
  /**
   * Report an error with specific details
   * 
   * @param message The error message
   * @param severity The error severity level
   * @param module The module where the error occurred
   * @param errorCode A specific error code if available
   * @return The created ApplicationException
   */
  public ApplicationException reportError(String message, ErrorSeverity severity, String module, String errorCode) {
    ApplicationException exception = new ApplicationException(message, severity, module, errorCode);
    handleException(exception);
    return exception;
  }
  
  /**
   * Report an error from an existing exception
   * 
   * @param message A descriptive message about the error
   * @param cause The original exception that caused this error
   * @param severity The error severity level
   * @param module The module where the error occurred
   * @param errorCode A specific error code if available
   * @return The created ApplicationException
   */
  public ApplicationException reportError(String message, Throwable cause, ErrorSeverity severity, String module, String errorCode) {
    ApplicationException exception = new ApplicationException(message, cause, severity, module, errorCode);
    handleException(exception);
    return exception;
  }
  
  /**
   * Report an error with default error code
   * 
   * @param message The error message
   * @param severity The error severity level
   * @param module The module where the error occurred
   * @return The created ApplicationException
   */
  public ApplicationException reportError(String message, ErrorSeverity severity, String module) {
    return reportError(message, severity, module, "ERR_UNKNOWN");
  }
  
  /**
   * Report an error from an existing exception with default error code
   * 
   * @param message A descriptive message about the error
   * @param cause The original exception that caused this error
   * @param severity The error severity level
   * @param module The module where the error occurred
   * @return The created ApplicationException
   */
  public ApplicationException reportError(String message, Throwable cause, ErrorSeverity severity, String module) {
    return reportError(message, cause, severity, module, "ERR_UNKNOWN");
  }
  
  /**
   * Handle an ApplicationException
   * 
   * @param exception The exception to handle
   */
  private void handleException(ApplicationException exception) {
    // Add to active errors if ERROR or CRITICAL
    if (exception.getSeverity() == ErrorSeverity.ERROR || 
        exception.getSeverity() == ErrorSeverity.CRITICAL) {
      activeErrors.add(exception);
    }
    
    // Add to error history
    addToErrorHistory(exception);
    
    // Log the error
    logError(exception);
    
    // Publish error event with event data
    EventData errorData = new EventData()
      .put("message", exception.getMessage())
      .put("severity", exception.getSeverity())
      .put("module", exception.getModule())
      .put("errorCode", exception.getErrorCode());
    
    publishEvent(ErrorEventType.ERROR_OCCURRED, errorData);
  }
  
  /**
   * Add an error to the error history
   * 
   * @param exception The exception to add
   */
  private void addToErrorHistory(ApplicationException exception) {
    errorHistory.add(exception);
    
    // Trim history if needed
    if (errorHistory.size() > MAX_ERROR_HISTORY) {
      errorHistory.remove(0);
    }
  }
  
  /**
   * Log an error to console and/or file
   * 
   * @param exception The exception to log
   */
  private void logError(ApplicationException exception) {
    // Format the error message
    String logMessage = formatErrorMessage(exception);
    
    // Log to console if enabled
    if (logToConsole) {
      println(logMessage);
      
      // Print stack trace for ERROR and CRITICAL
      if (exception.getSeverity() == ErrorSeverity.ERROR || 
          exception.getSeverity() == ErrorSeverity.CRITICAL) {
        exception.printStackTrace();
      }
    }
    
    // Log to file if enabled
    if (logToFile) {
      try {
        java.io.PrintWriter writer = new java.io.PrintWriter(new java.io.FileWriter(logFilePath, true));
        writer.println(logMessage);
        
        // Write stack trace for ERROR and CRITICAL
        if (exception.getSeverity() == ErrorSeverity.ERROR || 
            exception.getSeverity() == ErrorSeverity.CRITICAL) {
          exception.printStackTrace(writer);
        }
        
        writer.close();
      } catch (Exception e) {
        println("Failed to write to error log file: " + e.getMessage());
      }
    }
  }
  
  /**
   * Format an error message for logging
   * 
   * @param exception The exception to format
   * @return The formatted error message
   */
  private String formatErrorMessage(ApplicationException exception) {
    return String.format("[%s] [%s] [%s] %s - %s",
                         new java.util.Date(),
                         exception.getSeverity(),
                         exception.getModule(),
                         exception.getErrorCode(),
                         exception.getMessage());
  }
  
  /**
   * Clear a specific error
   * 
   * @param exception The exception to clear
   */
  public void clearError(ApplicationException exception) {
    if (activeErrors.remove(exception)) {
      // Publish error cleared event
      EventData errorData = new EventData()
        .put("message", exception.getMessage())
        .put("severity", exception.getSeverity())
        .put("module", exception.getModule())
        .put("errorCode", exception.getErrorCode());
      
      publishEvent(ErrorEventType.ERROR_CLEARED, errorData);
    }
  }
  
  /**
   * Clear all errors
   */
  public void clearAllErrors() {
    activeErrors.clear();
    publishEvent(ErrorEventType.ERROR_CLEARED);
  }
  
  /**
   * Get all active errors
   * 
   * @return A list of active errors
   */
  public ArrayList<ApplicationException> getActiveErrors() {
    return new ArrayList<ApplicationException>(activeErrors);
  }
  
  /**
   * Get active errors for a specific module
   * 
   * @param module The module to get errors for
   * @return A list of active errors for the module
   */
  public ArrayList<ApplicationException> getActiveErrorsForModule(String module) {
    ArrayList<ApplicationException> result = new ArrayList<ApplicationException>();
    
    for (ApplicationException exception : activeErrors) {
      if (exception.getModule().equals(module)) {
        result.add(exception);
      }
    }
    
    return result;
  }
  
  /**
   * Check if there are any active errors
   * 
   * @return True if there are active errors, false otherwise
   */
  public boolean hasActiveErrors() {
    return !activeErrors.isEmpty();
  }
  
  /**
   * Check if there are any active errors of a specific severity
   * 
   * @param severity The severity level to check
   * @return True if there are active errors of the specified severity
   */
  public boolean hasActiveErrorsWithSeverity(ErrorSeverity severity) {
    for (ApplicationException exception : activeErrors) {
      if (exception.getSeverity() == severity) {
        return true;
      }
    }
    
    return false;
  }
  
  /**
   * Get the error history
   * 
   * @return A list of all errors in the history
   */
  public ArrayList<ApplicationException> getErrorHistory() {
    return new ArrayList<ApplicationException>(errorHistory);
  }
  
  /**
   * Set whether to log errors to the console
   * 
   * @param enabled True to enable console logging, false to disable
   */
  public void setLogToConsole(boolean enabled) {
    logToConsole = enabled;
  }
  
  /**
   * Set whether to log errors to a file
   * 
   * @param enabled True to enable file logging, false to disable
   * @param filePath The path to the log file
   */
  public void setLogToFile(boolean enabled, String filePath) {
    logToFile = enabled;
    logFilePath = filePath;
    
    // Create log file if enabling file logging
    if (logToFile) {
      try {
        java.io.PrintWriter writer = new java.io.PrintWriter(new java.io.FileWriter(logFilePath, true));
        writer.println("--- Error Log Started: " + new java.util.Date() + " ---");
        writer.close();
      } catch (Exception e) {
        println("Failed to create error log file: " + e.getMessage());
        logToFile = false;
      }
    }
  }
}