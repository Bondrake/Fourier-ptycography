/**
 * View_ErrorView.pde
 * 
 * A component for displaying error notifications to the user.
 * This view monitors error events from the ErrorManager and
 * displays appropriate notifications based on error severity.
 */

/**
 * ErrorView displays error notifications in the UI
 */
class ErrorView extends EventDispatcher {
  // UI positioning
  private int posX;
  private int posY;
  private int width;
  private int maxHeight;
  
  // UI Display settings
  private static final int NOTIFICATION_HEIGHT = 40;
  private static final int NOTIFICATION_PADDING = 10;
  private static final int NOTIFICATION_MARGIN = 5;
  private static final int MAX_VISIBLE_NOTIFICATIONS = 3;
  
  // Active notifications
  private ArrayList<ErrorNotification> activeNotifications;
  
  // Color scheme
  private color bgDebug = color(100, 100, 100, 220);
  private color bgInfo = color(50, 120, 200, 220);
  private color bgWarning = color(240, 160, 0, 220);
  private color bgError = color(220, 80, 80, 220);
  private color bgCritical = color(180, 0, 0, 220);
  private color textColor = color(255, 255, 255);
  
  /**
   * Constructor
   * 
   * @param x X position of the error view
   * @param y Y position of the error view
   * @param w Width of the error view
   * @param maxH Maximum height of the error view
   */
  public ErrorView(int x, int y, int w, int maxH) {
    this.posX = x;
    this.posY = y;
    this.width = w;
    this.maxHeight = maxH;
    
    activeNotifications = new ArrayList<ErrorNotification>();
    
    // Register for error events
    registerEvent(ErrorEventType.ERROR_OCCURRED);
    registerEvent(ErrorEventType.ERROR_CLEARED);
  }
  
  /**
   * Handle error events
   */
  @Override
  public void handleEvent(String eventType, EventData data) {
    if (eventType.equals(ErrorEventType.ERROR_OCCURRED)) {
      // Create a new notification
      String message = data.getString("message", "Unknown error");
      ErrorSeverity severity = (ErrorSeverity)data.get("severity");
      String module = data.getString("module", "Unknown");
      String errorCode = data.getString("errorCode", "ERR_UNKNOWN");
      
      // Skip DEBUG severity notifications
      if (severity == ErrorSeverity.DEBUG) {
        return;
      }
      
      // Add the notification
      addNotification(message, severity, module, errorCode);
    }
    else if (eventType.equals(ErrorEventType.ERROR_CLEARED)) {
      // Clear notifications if specifically requested
      if (data != null && data.hasKey("message")) {
        String message = data.getString("message", "");
        
        // Find and remove notifications with this message
        for (int i = activeNotifications.size() - 1; i >= 0; i--) {
          ErrorNotification notification = activeNotifications.get(i);
          if (notification.message.equals(message)) {
            activeNotifications.remove(i);
          }
        }
      } else {
        // Clear all notifications
        activeNotifications.clear();
      }
    }
  }
  
  /**
   * Add a new error notification
   * 
   * @param message The error message
   * @param severity The error severity
   * @param module The module where the error occurred
   * @param errorCode The error code
   */
  public void addNotification(String message, ErrorSeverity severity, String module, String errorCode) {
    // Create a notification
    ErrorNotification notification = new ErrorNotification(message, severity, module, errorCode);
    
    // Add to active notifications
    activeNotifications.add(notification);
    
    // Remove old notifications if we have too many
    while (activeNotifications.size() > MAX_VISIBLE_NOTIFICATIONS) {
      activeNotifications.remove(0);
    }
    
    // Schedule auto-dismissal for INFO and WARNING notifications
    if (severity == ErrorSeverity.INFO || severity == ErrorSeverity.WARNING) {
      // Auto-dismiss after a timeout
      final ErrorNotification notif = notification;
      new java.util.Timer().schedule(
        new java.util.TimerTask() {
          @Override
          public void run() {
            activeNotifications.remove(notif);
          }
        },
        severity == ErrorSeverity.INFO ? 5000 : 10000  // 5s for INFO, 10s for WARNING
      );
    }
  }
  
  /**
   * Draw the error view
   */
  public void draw() {
    // Skip if no notifications
    if (activeNotifications.isEmpty()) {
      return;
    }
    
    // Draw notifications from bottom to top
    int yOffset = posY + maxHeight - NOTIFICATION_HEIGHT;
    
    for (int i = activeNotifications.size() - 1; i >= 0; i--) {
      ErrorNotification notification = activeNotifications.get(i);
      
      // Store the current y position for mouse interaction
      notification.yPos = yOffset;
      
      // Choose background color based on severity
      color bgColor;
      switch (notification.severity) {
        case DEBUG:
          bgColor = bgDebug;
          break;
        case INFO:
          bgColor = bgInfo;
          break;
        case WARNING:
          bgColor = bgWarning;
          break;
        case ERROR:
          bgColor = bgError;
          break;
        case CRITICAL:
          bgColor = bgCritical;
          break;
        default:
          bgColor = bgInfo;
      }
      
      // Draw notification background
      fill(bgColor);
      noStroke();
      rect(posX, yOffset, width, NOTIFICATION_HEIGHT, 3);
      
      // Draw message
      fill(textColor);
      textAlign(LEFT, CENTER);
      textSize(14);
      
      // Reserve space for close button
      int closeButtonWidth = 30;
      
      // Truncate message if needed
      String displayMessage = notification.message;
      if (textWidth(displayMessage) > width - NOTIFICATION_PADDING * 4 - closeButtonWidth) {
        // Truncate and add ellipsis
        int maxChars = displayMessage.length();
        while (maxChars > 0 && textWidth(displayMessage.substring(0, maxChars) + "...") > width - NOTIFICATION_PADDING * 4 - closeButtonWidth) {
          maxChars--;
        }
        displayMessage = displayMessage.substring(0, maxChars) + "...";
      }
      
      text(displayMessage, posX + NOTIFICATION_PADDING, yOffset + NOTIFICATION_HEIGHT / 2);
      
      // Draw close button (X)
      float closeX = posX + width - 25;
      float closeY = yOffset + NOTIFICATION_HEIGHT / 2;
      
      // Draw close button background
      fill(255, 255, 255, 180);
      ellipse(closeX, closeY, 20, 20);
      
      // Draw X
      stroke(50);
      strokeWeight(2);
      line(closeX - 5, closeY - 5, closeX + 5, closeY + 5);
      line(closeX + 5, closeY - 5, closeX - 5, closeY + 5);
      noStroke();
      
      // Move up for next notification
      yOffset -= (NOTIFICATION_HEIGHT + NOTIFICATION_MARGIN);
      
      // Stop if we've reached the top of our area
      if (yOffset < posY) {
        break;
      }
    }
  }
  
  /**
   * Clear all notifications
   */
  public void clearAllNotifications() {
    activeNotifications.clear();
  }
  
  /**
   * Check if there are any active notifications
   * 
   * @return True if there are active notifications
   */
  public boolean hasActiveNotifications() {
    return !activeNotifications.isEmpty();
  }
  
  /**
   * Handle mouse clicks to dismiss notifications
   */
  public void mousePressed() {
    // Check if any notification's close button was clicked
    for (int i = activeNotifications.size() - 1; i >= 0; i--) {
      ErrorNotification notification = activeNotifications.get(i);
      
      // Calculate close button position
      float closeX = posX + width - 25;
      float closeY = notification.yPos + NOTIFICATION_HEIGHT / 2;
      
      // Check if close button was clicked
      float d = dist(mouseX, mouseY, closeX, closeY);
      if (d <= 10) {
        // Remove this notification
        activeNotifications.remove(i);
        return; // Only remove one notification per click
      }
    }
  }
  
  /**
   * Inner class to represent an error notification
   */
  private class ErrorNotification {
    String message;
    ErrorSeverity severity;
    String module;
    String errorCode;
    long timestamp;
    int yPos; // Store current y position for mouse interaction
    
    /**
     * Constructor
     */
    public ErrorNotification(String message, ErrorSeverity severity, String module, String errorCode) {
      this.message = message;
      this.severity = severity;
      this.module = module;
      this.errorCode = errorCode;
      this.timestamp = millis();
      this.yPos = 0;
    }
  }
}