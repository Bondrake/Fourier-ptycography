/**
 * UIManager.pde
 * 
 * Manages UI elements and layout for the application.
 * Handles user interaction with the ControlP5 UI components.
 */

class UIManager extends EventDispatcher {
  // UI components
  private ControlP5 cp5;
  private PApplet app;
  
  // UI groups
  private Group patternGroup;
  private Group concentricRingsGroup;
  private Group spiralGroup;
  private Group gridGroup;
  private Group centerGroup;
  private Group controlGroup;
  private Group hardwareGroup;
  private Group cameraGroup;
  
  // Accordion for collapsible panels
  private Accordion accordion;
  
  // Constants for layout
  private final int INFO_PANEL_WIDTH = 330;
  private final int CONTROL_MARGIN = 10;
  private final int BAR_HEIGHT = 20;
  private final int GRID_PADDING_TOP = 50;
  private final int PARAM_GROUP_Y = 150;  // Y position for parameter groups
  
  // Model references
  private PatternModel patternModel;
  private SystemStateModel stateModel;
  private CameraModel cameraModel;
  private SerialManager serialManager;
  
  /**
   * Constructor
   */
  public UIManager(PApplet app, PatternModel patternModel, SystemStateModel stateModel, CameraModel cameraModel, SerialManager serialManager) {
    this.app = app;
    this.patternModel = patternModel;
    this.stateModel = stateModel;
    this.cameraModel = cameraModel;
    this.serialManager = serialManager;
    
    // Create control components
    cp5 = new ControlP5(app);
    
    // Disable broadcasting during setup to prevent events during initialization
    cp5.setBroadcast(false);
    
    // Set up UI components
    setupUI();
    
    // Re-enable broadcasting after setup
    cp5.setBroadcast(true);
    
    // Register for events
    registerEvent(EventType.PATTERN_CHANGED);
    registerEvent(EventType.STATE_CHANGED);
    registerEvent(EventType.CAMERA_STATUS_CHANGED);
    registerEvent(EventType.SERIAL_PORTS_CHANGED);
    registerEvent(EventType.CONFIG_LOADED);
    registerEvent(EventType.CONFIG_SAVED);
  }
  
  /**
   * Set up UI components
   */
  private void setupUI() {
    // Create accordion groups
    setupPatternGroup();
    setupControlGroup();
    setupHardwareGroup();
    setupCameraGroup();
    
    // Create accordion
    accordion = cp5.addAccordion("acc")
      .setPosition(CONTROL_MARGIN, 40)
      .setWidth(INFO_PANEL_WIDTH - CONTROL_MARGIN * 2)
      .addItem(patternGroup)
      .addItem(controlGroup)
      .addItem(hardwareGroup)
      .addItem(cameraGroup);
    
    // Open just the first panel by default, to avoid overlap
    accordion.open(0);
    
    // Change accordion mode to not allow multiple open panels
    accordion.setCollapseMode(Accordion.SINGLE);
  }
  
  /**
   * Set up pattern settings group
   */
  private void setupPatternGroup() {
    final int GROUP_WIDTH = INFO_PANEL_WIDTH - CONTROL_MARGIN * 2;
    final int PATTERN_GROUP_HEIGHT = 380; // Increased from 350 to accommodate lower parameter groups
    
    // Create Pattern Settings Group
    patternGroup = cp5.addGroup("Pattern Settings")
      .setPosition(CONTROL_MARGIN, 40)
      .setBackgroundColor(color(0, 64))
      .setWidth(GROUP_WIDTH)
      .setBackgroundHeight(PATTERN_GROUP_HEIGHT)
      .setBarHeight(BAR_HEIGHT);
    
    // Add pattern type radio button
    cp5.addTextlabel("patternTitle")
      .setText("Select Pattern Type:")
      .setPosition(CONTROL_MARGIN, 10)
      .setColorValue(color(220))
      .setFont(createFont("Arial", 14))
      .moveTo(patternGroup);
    
    // Add pattern type radio buttons
    cp5.addRadioButton("patternTypeRadio")
      .setPosition(CONTROL_MARGIN, 30)
      .setSize(20, 20)
      .setColorForeground(color(120))
      .setColorActive(color(0, 255, 0))
      .setColorLabel(color(255))
      .setItemsPerRow(1)
      .setSpacingRow(12) // Increased from 10 to add more spacing between radio buttons
      .addItem("Concentric Rings", PatternModel.PATTERN_CONCENTRIC_RINGS)
      .addItem("Center Only", PatternModel.PATTERN_CENTER_ONLY)
      .addItem("Spiral", PatternModel.PATTERN_SPIRAL)
      .addItem("Grid", PatternModel.PATTERN_GRID)
      .activate(patternModel.getPatternType())
      .moveTo(patternGroup);
    
    // Add parameter groups
    setupPatternParameterGroups();
    
    // Add circle mask toggle
    cp5.addTextlabel("maskTitle")
      .setText("Circle Mask:")
      .setPosition(CONTROL_MARGIN, 240)
      .setColorValue(color(220))
      .setFont(createFont("Arial", 14))
      .moveTo(patternGroup);
    
    // Calculate dynamic Y position for mask controls (below all parameter groups)
    int circleMaskY = PARAM_GROUP_Y + 135;  // Reduced from 185 to position closer to parameter groups
    
    // Add a divider and label for the mask controls section
    cp5.addTextlabel("maskTitle")
      .setText("Circle Mask Settings:")
      .setPosition(CONTROL_MARGIN, circleMaskY - 20)
      .setColorValue(color(200))
      .setFont(createFont("Arial", 12))
      .moveTo(patternGroup);
    
    cp5.addToggle("circleMaskToggle")
      .setPosition(CONTROL_MARGIN + 100, circleMaskY)
      .setSize(50, 15)
      .setLabel("Enable")
      .setValue(patternModel.isCircleMaskMode())
      .moveTo(patternGroup);
    
    // Circle Mask Radius slider
    cp5.addSlider("circleMaskRadius")
      .setPosition(CONTROL_MARGIN, circleMaskY + 30)
      .setSize(150, 15)
      .setRange(5, 32)
      .setValue(patternModel.getCircleMaskRadius())
      .setLabel("Mask Radius")
      .moveTo(patternGroup);
  }
  
  /**
   * Set up parameter groups for each pattern type
   */
  private void setupPatternParameterGroups() {
    final int GROUP_WIDTH = INFO_PANEL_WIDTH - CONTROL_MARGIN * 4;
    final int GROUP_HEIGHT = 100;
    final int GRID_GROUP_HEIGHT = 150;
    final int SLIDER_WIDTH = 150;
    // Using class-level constant PARAM_GROUP_Y
    
    // Create concentric rings group
    concentricRingsGroup = cp5.addGroup("concentricRingsParams")
      .setPosition(CONTROL_MARGIN, PARAM_GROUP_Y)
      .setWidth(GROUP_WIDTH)
      .setBackgroundHeight(GROUP_HEIGHT)
      .setBackgroundColor(color(30, 30, 30, 100))
      .hideBar()
      .moveTo(patternGroup);
    
    // Add sliders for concentric rings
    int yPos = 10;
    cp5.addSlider("innerRingRadius")
      .setPosition(10, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(2, 32)
      .setValue(patternModel.getInnerRingRadius())
      .setLabel("Inner Ring Radius")
      .moveTo(concentricRingsGroup);
    yPos += 25;
    
    cp5.addSlider("middleRingRadius")
      .setPosition(10, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(8, 45)
      .setValue(patternModel.getMiddleRingRadius())
      .setLabel("Middle Ring Radius")
      .moveTo(concentricRingsGroup);
    yPos += 25;
    
    cp5.addSlider("outerRingRadius")
      .setPosition(10, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(12, 50)
      .setValue(patternModel.getOuterRingRadius())
      .setLabel("Outer Ring Radius")
      .moveTo(concentricRingsGroup);
    
    // Create spiral group
    spiralGroup = cp5.addGroup("spiralParams")
      .setPosition(CONTROL_MARGIN, PARAM_GROUP_Y)
      .setWidth(GROUP_WIDTH)
      .setBackgroundHeight(GROUP_HEIGHT)
      .setBackgroundColor(color(30, 30, 30, 100))
      .hideBar()
      .moveTo(patternGroup);
    
    // Add sliders for spiral
    yPos = 10;
    cp5.addSlider("spiralMaxRadius")
      .setPosition(10, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(10, 50)
      .setValue(patternModel.getSpiralMaxRadius())
      .setLabel("Max Radius")
      .moveTo(spiralGroup);
    yPos += 25;
    
    cp5.addSlider("spiralTurns")
      .setPosition(10, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(1, 5)
      .setValue(patternModel.getSpiralTurns())
      .setLabel("Number of Turns")
      .moveTo(spiralGroup);
    
    // Create grid group
    gridGroup = cp5.addGroup("gridParams")
      .setPosition(CONTROL_MARGIN, PARAM_GROUP_Y)
      .setWidth(GROUP_WIDTH)
      .setBackgroundHeight(GRID_GROUP_HEIGHT)
      .setBackgroundColor(color(30, 30, 30, 100))
      .hideBar()
      .moveTo(patternGroup);
    
    // Add sliders for grid
    yPos = 10;
    cp5.addSlider("gridSpacing")
      .setPosition(10, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(0, 12)
      .setValue(patternModel.getGridSpacing())
      .setLabel("Grid Spacing")
      .moveTo(gridGroup);
    yPos += 25;
    
    cp5.addSlider("gridPointSize")
      .setPosition(10, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(1, 3)
      .setValue(patternModel.getGridPointSize())
      .setLabel("Grid Point Size")
      .moveTo(gridGroup);
    yPos += 25;
    
    cp5.addSlider("gridOffsetX")
      .setPosition(10, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(0, 4)
      .setValue(patternModel.getGridOffsetX())
      .setLabel("X Offset")
      .moveTo(gridGroup);
    yPos += 25;
    
    cp5.addSlider("gridOffsetY")
      .setPosition(10, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(0, 4)
      .setValue(patternModel.getGridOffsetY())
      .setLabel("Y Offset")
      .moveTo(gridGroup);
    
    // Create center only group
    centerGroup = cp5.addGroup("centerParams")
      .setPosition(CONTROL_MARGIN, PARAM_GROUP_Y)
      .setWidth(GROUP_WIDTH)
      .setBackgroundHeight(GROUP_HEIGHT)
      .setBackgroundColor(color(30, 30, 30, 100))
      .hideBar()
      .moveTo(patternGroup);
    
    // Add label for center only
    cp5.addTextlabel("centerLabel")
      .setText("Center LED only - no additional parameters")
      .setPosition(10, 10)
      .setColorValue(color(200))
      .setFont(createFont("Arial", 12))
      .moveTo(centerGroup);
    
    // Initially show only the parameter panel for the current pattern type
    showParameterGroupForPatternType(patternModel.getPatternType());
  }
  
  /**
   * Set up control group (buttons and simulation controls)
   */
  private void setupControlGroup() {
    final int GROUP_WIDTH = INFO_PANEL_WIDTH - CONTROL_MARGIN * 2;
    final int CONTROL_GROUP_HEIGHT = 270;  // Increased from 250 to accommodate the additional spacing
    final int BUTTON_WIDTH = (GROUP_WIDTH - CONTROL_MARGIN * 3) / 2;
    final int BUTTON_HEIGHT = 30;
    
    // Create Controls Group
    controlGroup = cp5.addGroup("Controls")
      .setPosition(CONTROL_MARGIN, 40)
      .setBackgroundColor(color(0, 64))
      .setWidth(GROUP_WIDTH)
      .setBackgroundHeight(CONTROL_GROUP_HEIGHT)
      .setBarHeight(BAR_HEIGHT);
    
    // Add controls title
    cp5.addTextlabel("controlsTitle")
      .setText("Sequence Controls:")
      .setPosition(CONTROL_MARGIN, 10)
      .setColorValue(color(220))
      .setFont(createFont("Arial", 14))
      .moveTo(controlGroup);
    
    // Button positioning
    int buttonY = 40;
    
    // First row of buttons
    cp5.addButton("startButton")
      .setPosition(CONTROL_MARGIN, buttonY)
      .setSize(BUTTON_WIDTH, BUTTON_HEIGHT)
      .setLabel("Start")
      .setColorBackground(color(0, 120, 0))
      .moveTo(controlGroup);
    
    cp5.addButton("pauseButton")
      .setPosition(CONTROL_MARGIN * 2 + BUTTON_WIDTH, buttonY)
      .setSize(BUTTON_WIDTH, BUTTON_HEIGHT)
      .setLabel("Pause")
      .setColorBackground(color(120, 120, 0))
      .moveTo(controlGroup);
    
    // Second row of buttons
    buttonY += BUTTON_HEIGHT + 10;
    
    cp5.addButton("stopButton")
      .setPosition(CONTROL_MARGIN, buttonY)
      .setSize(BUTTON_WIDTH, BUTTON_HEIGHT)
      .setLabel("Stop")
      .setColorBackground(color(120, 0, 0))
      .moveTo(controlGroup);
    
    cp5.addButton("regenerateButton")
      .setPosition(CONTROL_MARGIN * 2 + BUTTON_WIDTH, buttonY)
      .setSize(BUTTON_WIDTH, BUTTON_HEIGHT)
      .setLabel("Regenerate")
      .moveTo(controlGroup);
    
    // Settings title
    buttonY += BUTTON_HEIGHT + 20;
    
    cp5.addTextlabel("settingsTitle")
      .setText("Settings:")
      .setPosition(CONTROL_MARGIN, buttonY)
      .setColorValue(color(220))
      .setFont(createFont("Arial", 14))
      .moveTo(controlGroup);
    
    // Toggles for settings
    buttonY += 30;
    
    cp5.addToggle("idleToggle")
      .setPosition(CONTROL_MARGIN, buttonY)
      .setSize(BUTTON_WIDTH, 25)
      .setLabel("Idle Mode")
      .setValue(stateModel.isIdle())
      .moveTo(controlGroup);
    
    cp5.addToggle("gridToggle")
      .setPosition(CONTROL_MARGIN * 2 + BUTTON_WIDTH, buttonY)
      .setSize(BUTTON_WIDTH, 25)
      .setLabel("Show Grid")
      .setValue(true)
      .moveTo(controlGroup);
    
    // Interval slider - add more spacing before this section
    buttonY += 55;  // Increased from 40 to add 15 more pixels of space
    
    // Added a text label for the interval slider section
    cp5.addTextlabel("updateIntervalLabel")
      .setText("Simulation Speed:")
      .setPosition(CONTROL_MARGIN, buttonY)
      .setColorValue(color(200))
      .setFont(createFont("Arial", 12))
      .moveTo(controlGroup);
    buttonY += 20;
    
    // Made slider width consistent with other sliders (SLIDER_WIDTH = 150)
    cp5.addSlider("updateInterval")
      .setPosition(CONTROL_MARGIN, buttonY)
      .setSize(150, 15)  // Same size as other sliders (150x15)
      .setRange(100, 2000)
      .setValue(500)
      .setLabel("Update Interval (ms)")
      .moveTo(controlGroup);
  }
  
  /**
   * Set up hardware group (connection and mode controls)
   */
  private void setupHardwareGroup() {
    final int GROUP_WIDTH = INFO_PANEL_WIDTH - CONTROL_MARGIN * 2;
    final int HARDWARE_GROUP_HEIGHT = 300;
    final int BUTTON_HEIGHT = 30;
    
    // Create Hardware Group
    hardwareGroup = cp5.addGroup("Hardware")
      .setPosition(CONTROL_MARGIN, 40)
      .setBackgroundColor(color(0, 64))
      .setWidth(GROUP_WIDTH)
      .setBackgroundHeight(HARDWARE_GROUP_HEIGHT)
      .setBarHeight(BAR_HEIGHT);
    
    // Add a title for Hardware group
    cp5.addTextlabel("hardwareTitle")
      .setText("Hardware Configuration:")
      .setPosition(CONTROL_MARGIN, 10)
      .setColorValue(color(220))
      .setFont(createFont("Arial", 14))
      .moveTo(hardwareGroup);
    
    // Mode selection toggle
    cp5.addToggle("simulationToggle")
      .setPosition(CONTROL_MARGIN, 40)
      .setSize(GROUP_WIDTH - CONTROL_MARGIN * 2, BUTTON_HEIGHT)
      .setLabel("Simulation Mode")
      .setValue(stateModel.isSimulationMode())
      .moveTo(hardwareGroup);
    
    // Connection section
    cp5.addTextlabel("connectionTitle")
      .setText("Arduino Connection:")
      .setPosition(CONTROL_MARGIN, 90)
      .setColorValue(color(220))
      .setFont(createFont("Arial", 14))
      .moveTo(hardwareGroup);
    
    // Serial port selection
    cp5.addScrollableList("serialPortsList")
      .setPosition(CONTROL_MARGIN, 120)
      .setSize(GROUP_WIDTH - CONTROL_MARGIN * 2, 120)
      .setBarHeight(25)
      .setItemHeight(25)
      .setLabel("Serial Port")
      .moveTo(hardwareGroup);
    
    // Connection button
    cp5.addButton("connectButton")
      .setPosition(CONTROL_MARGIN, 250)
      .setSize(GROUP_WIDTH - CONTROL_MARGIN * 2, BUTTON_HEIGHT)
      .setLabel("Connect to Hardware")
      .setColorBackground(color(0, 0, 120))
      .moveTo(hardwareGroup);
    
    // Initialize serial port list
    updateSerialPortsList(serialManager.getAvailablePorts());
  }
  
  /**
   * Set up camera control group
   */
  private void setupCameraGroup() {
    final int GROUP_WIDTH = INFO_PANEL_WIDTH - CONTROL_MARGIN * 2;
    final int CAMERA_GROUP_HEIGHT = 200;
    final int BUTTON_HEIGHT = 30;
    final int SLIDER_WIDTH = 150;
    
    // Create Camera Control Group
    cameraGroup = cp5.addGroup("Camera Control")
      .setPosition(CONTROL_MARGIN, 40)
      .setBackgroundColor(color(0, 64))
      .setWidth(GROUP_WIDTH)
      .setBackgroundHeight(CAMERA_GROUP_HEIGHT)
      .setBarHeight(BAR_HEIGHT);
    
    // Camera enable toggle
    cp5.addToggle("cameraEnabled")
      .setPosition(CONTROL_MARGIN, 10)
      .setSize(GROUP_WIDTH - CONTROL_MARGIN * 2, 25)
      .setLabel("Enable Camera Trigger")
      .setValue(cameraModel.isEnabled())
      .moveTo(cameraGroup);
    
    // Add camera parameter sliders
    int yPos = 45;
    
    // Pre-delay slider
    cp5.addSlider("cameraPreDelay")
      .setPosition(CONTROL_MARGIN, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(0, 2000)
      .setValue(cameraModel.getPreDelay())
      .setLabel("Pre-Trigger Delay (ms)")
      .moveTo(cameraGroup);
    yPos += 25;
    
    // Pulse width slider
    cp5.addSlider("cameraPulseWidth")
      .setPosition(CONTROL_MARGIN, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(10, 500)
      .setValue(cameraModel.getPulseWidth())
      .setLabel("Trigger Pulse (ms)")
      .moveTo(cameraGroup);
    yPos += 25;
    
    // Post-delay slider
    cp5.addSlider("cameraPostDelay")
      .setPosition(CONTROL_MARGIN, yPos)
      .setSize(SLIDER_WIDTH, 15)
      .setRange(100, 5000)
      .setValue(cameraModel.getPostDelay())
      .setLabel("Post-Trigger Delay (ms)")
      .moveTo(cameraGroup);
    yPos += 35;
    
    // Manual trigger test button
    cp5.addButton("testCameraButton")
      .setPosition(CONTROL_MARGIN, yPos)
      .setSize(GROUP_WIDTH - CONTROL_MARGIN * 2, BUTTON_HEIGHT)
      .setLabel("Test Camera Trigger")
      .setColorBackground(color(0, 120, 100))
      .moveTo(cameraGroup);
  }
  
  /**
   * Show parameter group for the current pattern type
   */
  private void showParameterGroupForPatternType(int patternType) {
    // Hide all parameter groups
    concentricRingsGroup.hide();
    spiralGroup.hide();
    gridGroup.hide();
    centerGroup.hide();
    
    // Show the appropriate group based on pattern type
    switch (patternType) {
      case PatternModel.PATTERN_CONCENTRIC_RINGS:
        concentricRingsGroup.show();
        break;
      case PatternModel.PATTERN_SPIRAL:
        spiralGroup.show();
        break;
      case PatternModel.PATTERN_GRID:
        gridGroup.show();
        break;
      case PatternModel.PATTERN_CENTER_ONLY:
        centerGroup.show();
        break;
    }
  }
  
  /**
   * Update serial ports list
   */
  private void updateSerialPortsList(String[] ports) {
    ScrollableList portList = cp5.get(ScrollableList.class, "serialPortsList");
    portList.clear();
    
    for (int i = 0; i < ports.length; i++) {
      portList.addItem(ports[i], i);
    }
    
    if (ports.length > 0) {
      portList.setValue(0);
    }
  }
  
  /**
   * Handle ControlP5 events
   */
  public void handleControlEvent(ControlEvent event) {
    if (event.isController()) {
      String name = event.getController().getName();
      
      if (name.equals("patternTypeRadio")) {
        int type = (int)event.getController().getValue();
        patternModel.setPatternType(type);
        showParameterGroupForPatternType(type);
      }
      else if (name.equals("innerRingRadius")) {
        patternModel.setInnerRingRadius((int)event.getController().getValue());
      }
      else if (name.equals("middleRingRadius")) {
        patternModel.setMiddleRingRadius((int)event.getController().getValue());
      }
      else if (name.equals("outerRingRadius")) {
        patternModel.setOuterRingRadius((int)event.getController().getValue());
      }
      else if (name.equals("spiralMaxRadius")) {
        patternModel.setSpiralMaxRadius((int)event.getController().getValue());
      }
      else if (name.equals("spiralTurns")) {
        patternModel.setSpiralTurns((int)event.getController().getValue());
      }
      else if (name.equals("gridSpacing")) {
        patternModel.setGridSpacing((int)event.getController().getValue());
      }
      else if (name.equals("gridPointSize")) {
        patternModel.setGridPointSize((int)event.getController().getValue());
      }
      else if (name.equals("gridOffsetX")) {
        patternModel.setGridOffsetX((int)event.getController().getValue());
      }
      else if (name.equals("gridOffsetY")) {
        patternModel.setGridOffsetY((int)event.getController().getValue());
      }
      else if (name.equals("circleMaskToggle")) {
        patternModel.setCircleMaskMode(event.getController().getValue() > 0);
      }
      else if (name.equals("circleMaskRadius")) {
        patternModel.setCircleMaskRadius((int)event.getController().getValue());
      }
      else if (name.equals("cameraEnabled")) {
        cameraModel.setEnabled(event.getController().getValue() > 0);
      }
      else if (name.equals("cameraPreDelay")) {
        cameraModel.setPreDelay((int)event.getController().getValue());
      }
      else if (name.equals("cameraPulseWidth")) {
        cameraModel.setPulseWidth((int)event.getController().getValue());
      }
      else if (name.equals("cameraPostDelay")) {
        cameraModel.setPostDelay((int)event.getController().getValue());
      }
      else if (name.equals("simulationToggle")) {
        boolean simulationMode = event.getController().getValue() > 0;
        stateModel.setSimulationMode(simulationMode);
      }
      else if (name.equals("idleToggle")) {
        boolean idleMode = event.getController().getValue() > 0;
        if (idleMode) {
          stateModel.enterIdleMode();
        } else {
          stateModel.exitIdleMode();
        }
      }
    }
  }
  
  // Button handlers
  
  public void startButton() {
    stateModel.startSequence();
  }
  
  public void pauseButton() {
    if (stateModel.isRunning()) {
      stateModel.pauseSequence();
    } else if (stateModel.isPaused()) {
      stateModel.startSequence();
    }
  }
  
  public void stopButton() {
    stateModel.stopSequence();
  }
  
  public void regenerateButton() {
    patternModel.generatePattern();
  }
  
  public void connectButton() {
    if (stateModel.isSimulationMode()) {
      println("Cannot connect in simulation mode. Turn off simulation mode first.");
      return;
    }
    
    // Get selected port
    int portIndex = (int)cp5.get(ScrollableList.class, "serialPortsList").getValue();
    if (portIndex < 0 || portIndex >= serialManager.getAvailablePorts().length) {
      println("Please select a valid serial port");
      return;
    }
    
    // Try to connect
    serialManager.connect(portIndex);
  }
  
  public void testCameraButton() {
    if (stateModel.isSimulationMode()) {
      // Simulate camera trigger
      cameraModel.simulateTrigger();
    } else if (stateModel.isHardwareConnected()) {
      // Send test command to hardware
      serialManager.testCameraTrigger();
    } else {
      println("Cannot test camera: Hardware not connected");
    }
  }
  
  /**
   * Handle incoming events
   */
  @Override
  public void handleEvent(String eventType, EventData data) {
    switch (eventType) {
      case EventType.PATTERN_CHANGED:
        // Update UI to reflect pattern changes
        cp5.get(RadioButton.class, "patternTypeRadio").activate(patternModel.getPatternType());
        showParameterGroupForPatternType(patternModel.getPatternType());
        break;
      
      case EventType.STATE_CHANGED:
        // Update UI to reflect state changes
        // Use setBroadcast(false) to prevent triggering callbacks
        Toggle idleToggle = cp5.get(Toggle.class, "idleToggle");
        Toggle simToggle = cp5.get(Toggle.class, "simulationToggle");
        
        idleToggle.setBroadcast(false);
        idleToggle.setValue(stateModel.isIdle() ? 1 : 0);
        idleToggle.setBroadcast(true);
        
        simToggle.setBroadcast(false);
        simToggle.setValue(stateModel.isSimulationMode() ? 1 : 0);
        simToggle.setBroadcast(true);
        break;
      
      case EventType.CAMERA_STATUS_CHANGED:
        // Update camera UI with broadcast disabled to prevent recursive events
        Toggle camToggle = cp5.get(Toggle.class, "cameraEnabled");
        camToggle.setBroadcast(false);
        camToggle.setValue(cameraModel.isEnabled() ? 1 : 0);
        camToggle.setBroadcast(true);
        break;
      
      case EventType.SERIAL_PORTS_CHANGED:
        // Update serial ports list
        if (data != null && data.hasKey("ports")) {
          updateSerialPortsList((String[])data.get("ports"));
        } else {
          updateSerialPortsList(serialManager.getAvailablePorts());
        }
        break;
        
      case EventType.CONFIG_LOADED:
        // Update UI with loaded configuration values
        updateControlsFromModels();
        break;
        
      case EventType.CONFIG_SAVED:
        // Update UI to reflect saved configuration
        updateControlsFromModels();
        break;
    }
  }
  
  /**
   * Update control values from models
   */
  private void updateControlsFromModels() {
    // Temporarily disable broadcast to prevent recursive events
    cp5.setBroadcast(false);
    
    // Update pattern controls
    cp5.get(RadioButton.class, "patternTypeRadio").activate(patternModel.getPatternType());
    cp5.get(Slider.class, "innerRingRadius").setValue(patternModel.getInnerRingRadius());
    cp5.get(Slider.class, "middleRingRadius").setValue(patternModel.getMiddleRingRadius());
    cp5.get(Slider.class, "outerRingRadius").setValue(patternModel.getOuterRingRadius());
    cp5.get(Slider.class, "spiralMaxRadius").setValue(patternModel.getSpiralMaxRadius());
    cp5.get(Slider.class, "spiralTurns").setValue(patternModel.getSpiralTurns());
    cp5.get(Slider.class, "gridSpacing").setValue(patternModel.getGridSpacing());
    cp5.get(Slider.class, "gridPointSize").setValue(patternModel.getGridPointSize());
    cp5.get(Slider.class, "gridOffsetX").setValue(patternModel.getGridOffsetX());
    cp5.get(Slider.class, "gridOffsetY").setValue(patternModel.getGridOffsetY());
    cp5.get(Toggle.class, "circleMaskToggle").setValue(patternModel.isCircleMaskMode() ? 1 : 0);
    cp5.get(Slider.class, "circleMaskRadius").setValue(patternModel.getCircleMaskRadius());
    
    // Update camera controls
    cp5.get(Toggle.class, "cameraEnabled").setValue(cameraModel.isEnabled() ? 1 : 0);
    cp5.get(Slider.class, "cameraPreDelay").setValue(cameraModel.getPreDelay());
    cp5.get(Slider.class, "cameraPulseWidth").setValue(cameraModel.getPulseWidth());
    cp5.get(Slider.class, "cameraPostDelay").setValue(cameraModel.getPostDelay());
    
    // Update mode controls
    cp5.get(Toggle.class, "simulationToggle").setValue(stateModel.isSimulationMode() ? 1 : 0);
    cp5.get(Toggle.class, "idleToggle").setValue(stateModel.isIdle() ? 1 : 0);
    
    // Re-enable broadcast after all updates
    cp5.setBroadcast(true);
    
    // Show the appropriate parameter group
    showParameterGroupForPatternType(patternModel.getPatternType());
  }
  
  /**
   * Get the ControlP5 instance
   */
  public ControlP5 getControlP5() {
    return cp5;
  }
}