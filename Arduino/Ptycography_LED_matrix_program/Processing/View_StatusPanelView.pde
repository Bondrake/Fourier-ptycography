/**
 * StatusPanelView.pde
 * 
 * Responsible for visualizing system status information.
 * Displays operational mode, camera status, LED status, etc.
 * Uses the event system for updates.
 */

class StatusPanelView extends EventDispatcher {
  // Models
  private PatternModel patternModel;
  private SystemStateModel stateModel;
  private CameraModel cameraModel;
  
  // Layout constants
  private final int INFO_PANEL_WIDTH;
  private final int SECTION_SPACING = 15;
  private final int FIELD_SPACING = 22;
  private final int LABEL_WIDTH = 100;
  private final int VALUE_WIDTH = 120;
  
  // Position
  private int panelX;
  private int panelY;
  
  // Temporary message display
  private String temporaryMessage = "";
  private int temporaryMessageDuration = 0;
  private int temporaryMessageStartTime = 0;
  
  /**
   * Constructor with models and position
   */
  public StatusPanelView(PatternModel patternModel, SystemStateModel stateModel, CameraModel cameraModel,
                       int panelX, int panelY, int panelWidth) {
    this.patternModel = patternModel;
    this.stateModel = stateModel;
    this.cameraModel = cameraModel;
    this.panelX = panelX;
    this.panelY = panelY;
    this.INFO_PANEL_WIDTH = panelWidth;
    
    // Register for events
    registerEvent(EventType.PATTERN_CHANGED);
    registerEvent(EventType.STATE_CHANGED);
    registerEvent(EventType.CAMERA_STATUS_CHANGED);
  }
  
  /**
   * Handle events
   */
  @Override
  public void handleEvent(String eventType, EventData data) {
    // The view will be updated in the draw method
  }
  
  /**
   * Draw the status panel
   */
  public void draw() {
    // Draw panel background
    fill(40);
    noStroke();
    rect(panelX, 0, INFO_PANEL_WIDTH, height);
    
    // Draw panel header
    fill(200);
    textSize(18);
    textAlign(LEFT, TOP);
    text("Ptycography LED Control", panelX + 10, 10);
    
    // Draw header separator
    stroke(100);
    line(panelX + 10, 35, panelX + INFO_PANEL_WIDTH - 10, 35);
    
    // Draw temporary message if active
    if (temporaryMessage != null && !temporaryMessage.isEmpty()) {
      // Check if message duration has expired
      if (millis() - temporaryMessageStartTime < temporaryMessageDuration) {
        // Draw message with semi-transparent background
        fill(20, 160, 20, 220);
        noStroke();
        rect(panelX + 10, 35, INFO_PANEL_WIDTH - 20, 30);
        
        // Draw message text
        fill(255);
        textAlign(CENTER, CENTER);
        textSize(14);
        text(temporaryMessage, panelX + INFO_PANEL_WIDTH/2, 50);
        
        // Reset text alignment
        textAlign(LEFT, TOP);
      } else {
        // Clear message once duration is exceeded
        temporaryMessage = "";
      }
    }
    
    // Start position for status sections
    // We keep the header at the top but position the actual status sections at the specified Y position
    int yPos = panelY;
    
    // SECTION: Status Information
    drawSectionHeader("STATUS", yPos);
    yPos += 25;
    
    // Prepare text values
    String modeText = stateModel.isSimulationMode() ? "SIMULATION" : "HARDWARE";
    String statusText = stateModel.isRunning() ? 
                      (stateModel.isPaused() ? "PAUSED" : "RUNNING") : "STOPPED";
    String idleText = stateModel.isIdle() ? "IDLE MODE" : "ACTIVE";
    String maskText = patternModel.isCircleMaskMode() ? 
                    "ON (r=" + patternModel.getCircleMaskRadius() + ")" : "OFF";
    String cameraText = cameraModel.isEnabled() ? "ENABLED" : "DISABLED";
    String patternText = "";
    
    switch (patternModel.getPatternType()) {
      case PatternModel.PATTERN_CONCENTRIC_RINGS: 
        patternText = "CONCENTRIC RINGS"; 
        break;
      case PatternModel.PATTERN_CENTER_ONLY: 
        patternText = "CENTER ONLY"; 
        break;
      case PatternModel.PATTERN_SPIRAL: 
        patternText = "SPIRAL"; 
        break;
      case PatternModel.PATTERN_GRID: 
        patternText = "GRID"; 
        break;
    }
    
    // Draw status fields
    drawField("Mode:", modeText, yPos);
    yPos += FIELD_SPACING;
    
    drawField("Status:", statusText, yPos);
    yPos += FIELD_SPACING;
    
    drawField("Power:", idleText, yPos);
    yPos += FIELD_SPACING;
    
    drawField("Pattern:", patternText, yPos);
    yPos += FIELD_SPACING;
    
    drawField("Mask:", maskText, yPos);
    yPos += FIELD_SPACING;
    
    drawField("Camera:", cameraText, yPos);
    yPos += FIELD_SPACING;
    
    // If camera is enabled, show detailed status
    if (cameraModel.isEnabled()) {
      // Show active/idle status
      String triggerText = cameraModel.isTriggerActive() ? "ACTIVE" : "IDLE";
      drawField("Trigger:", triggerText, yPos, 
               cameraModel.isTriggerActive() ? color(255, 0, 0) : color(220));
      yPos += FIELD_SPACING;
      
      // Show last trigger time
      if (cameraModel.getLastTriggerTime() > 0) {
        int timeSince = cameraModel.getTimeSinceLastTrigger();
        String timeText = timeSince < 5000 ? (timeSince + "ms ago") : "Ready";
        drawField("Last Trigger:", timeText, yPos);
        yPos += FIELD_SPACING;
      }
      
      // Show error status if any
      if (cameraModel.hasError()) {
        drawField("Error:", cameraModel.getErrorStatus(), yPos, color(255, 200, 0));
        yPos += FIELD_SPACING;
      }
      
      // Add timing visualization if camera was used
      if (cameraModel.getLastTriggerTime() > 0) {
        yPos += 10;
        
        // Draw timing bar showing pre-delay, trigger and post-delay periods
        int barWidth = 180;
        int barHeight = 12;
        int barX = panelX + 20;
        float totalTime = cameraModel.getPreDelay() + cameraModel.getPulseWidth() + cameraModel.getPostDelay();
        float preDelayWidth = (cameraModel.getPreDelay() / totalTime) * barWidth;
        float pulseWidth = (cameraModel.getPulseWidth() / totalTime) * barWidth;
        float postDelayWidth = (cameraModel.getPostDelay() / totalTime) * barWidth;
        
        // Background
        stroke(100);
        fill(30);
        rect(barX, yPos, barWidth, barHeight);
        
        // Pre-delay section (blue)
        fill(0, 0, 180);
        noStroke();
        rect(barX, yPos, preDelayWidth, barHeight);
        
        // Pulse width section (red)
        fill(180, 0, 0);
        rect(barX + preDelayWidth, yPos, pulseWidth, barHeight);
        
        // Post-delay section (green)
        fill(0, 180, 0);
        rect(barX + preDelayWidth + pulseWidth, yPos, postDelayWidth, barHeight);
        
        // Labels
        yPos += barHeight + 5;
        fill(220);
        textAlign(LEFT, TOP);
        textSize(10);
        text("Pre: " + cameraModel.getPreDelay() + "ms", barX, yPos);
        text("Pulse: " + cameraModel.getPulseWidth() + "ms", barX + preDelayWidth + 5, yPos);
        text("Post: " + cameraModel.getPostDelay() + "ms", barX + preDelayWidth + pulseWidth + 5, yPos);
        
        yPos += 15;
      }
    }
    
    yPos += SECTION_SPACING;
    
    // SECTION: Current LED Information
    drawSectionHeader("CURRENT LED", yPos);
    yPos += 25;
    
    drawField("X:", stateModel.getCurrentLedX() == -1 ? "None" : 
              String.valueOf(stateModel.getCurrentLedX()), yPos);
    yPos += FIELD_SPACING;
    
    drawField("Y:", stateModel.getCurrentLedY() == -1 ? "None" : 
              String.valueOf(stateModel.getCurrentLedY()), yPos);
    yPos += FIELD_SPACING + SECTION_SPACING;
    
    // SECTION: Hardware Information (only in hardware mode)
    if (!stateModel.isSimulationMode()) {
      drawSectionHeader("HARDWARE", yPos);
      yPos += 25;
      
      drawField("Connected:", stateModel.isHardwareConnected() ? "YES" : "NO", yPos, 
               stateModel.isHardwareConnected() ? color(0, 255, 0) : color(255, 0, 0));
      yPos += FIELD_SPACING;
      
      drawField("Com Port:", "TODO: Get Port", yPos);
      yPos += FIELD_SPACING + SECTION_SPACING;
    }
    
    // SECTION: Sequence Progress (only when sequence exists)
    if (stateModel.getSequenceLength() > 0) {
      drawSectionHeader("SEQUENCE", yPos);
      yPos += 25;
      
      drawField("Progress:", 
        String.format("%d / %d (%.1f%%)", 
          stateModel.getSequenceIndex(),
          stateModel.getSequenceLength(),
          stateModel.getSequenceProgress() * 100), 
        yPos);
      yPos += FIELD_SPACING;
      
      // Draw progress bar
      int barWidth = 180;
      int barHeight = 15;
      int barX = panelX + 20;
      int barY = yPos;
      float progress = stateModel.getSequenceProgress();
      
      // Background
      stroke(100);
      noFill();
      rect(barX, barY, barWidth, barHeight);
      
      // Progress fill
      fill(0, 255, 0);
      noStroke();
      rect(barX, barY, barWidth * progress, barHeight);
      
      yPos += 20; // Extra space after the bar
    }
  }
  
  /**
   * Helper method to draw a section header
   */
  private void drawSectionHeader(String title, int yPos) {
    fill(180);
    textAlign(LEFT, TOP);
    textSize(14);
    text(title, panelX + 20, yPos);
    
    // Draw a subtle separator line
    stroke(80);
    line(panelX + 85, yPos + 7, panelX + INFO_PANEL_WIDTH - 20, yPos + 7);
  }
  
  /**
   * Helper method to draw a field with label and value
   */
  private void drawField(String label, String value, int yPos) {
    drawField(label, value, yPos, color(255));
  }
  
  /**
   * Helper method to draw a field with label and value and custom color
   */
  private void drawField(String label, String value, int yPos, int valueColor) {
    fill(200);
    textAlign(LEFT, TOP);
    textSize(13);
    text(label, panelX + 20, yPos);
    
    fill(valueColor);
    // Use ellipsis for long values to prevent spillover
    if (value.length() > 13 && !value.contains("CONCENTRIC")) {
      value = value.substring(0, 10) + "...";
    }
    text(value, panelX + 100, yPos);
  }
  
  /**
   * Show a temporary message in the status panel
   * 
   * @param message The message to display
   * @param duration The duration in milliseconds (default 3000ms)
   */
  public void showTemporaryMessage(String message, int duration) {
    temporaryMessage = message;
    temporaryMessageDuration = duration;
    temporaryMessageStartTime = millis();
  }
  
  /**
   * Show a temporary message with default duration (3 seconds)
   * 
   * @param message The message to display
   */
  public void showTemporaryMessage(String message) {
    showTemporaryMessage(message, 3000);
  }
}