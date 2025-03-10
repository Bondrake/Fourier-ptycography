/**
 * ConfigManager.pde
 * 
 * Manages configuration settings for the application.
 * Supports loading/saving from/to JSON files.
 * Implements EventDispatcher for event-based communication.
 * 
 * This would be reimplemented using Rust in a Tauri migration.
 */

// Singleton instance - must be outside the class for Processing compatibility
ConfigManager configManagerInstance = null;

// Global function to get ConfigManager instance (Processing compatibility)
ConfigManager getConfigManager() {
  if (configManagerInstance == null) {
    configManagerInstance = new ConfigManager();
  }
  return configManagerInstance;
}

class ConfigManager extends EventDispatcher {
  private JSONObject config;
  private String configFilePath;
  
  // Default configuration values
  private static final int DEFAULT_WINDOW_WIDTH = 1280;
  private static final int DEFAULT_WINDOW_HEIGHT = 800;
  private static final boolean DEFAULT_SIMULATION_MODE = true;
  private static final int DEFAULT_PATTERN_TYPE = 3; // Grid pattern
  private static final int DEFAULT_INNER_RADIUS = 16;
  private static final int DEFAULT_MIDDLE_RADIUS = 24;
  private static final int DEFAULT_OUTER_RADIUS = 31;
  private static final int DEFAULT_LED_SKIP = 2;
  private static final boolean DEFAULT_CAMERA_ENABLED = true;
  private static final int DEFAULT_CAMERA_PRE_DELAY = 400;
  private static final int DEFAULT_CAMERA_PULSE_WIDTH = 100;
  private static final int DEFAULT_CAMERA_POST_DELAY = 1500;
  
  // Private constructor (singleton pattern)
  private ConfigManager() {
    try {
      println("Initializing ConfigManager");
      
      config = new JSONObject();
      configFilePath = dataPath("config.json");
      
      // Create data directory if it doesn't exist
      File dataDir = new File(dataPath(""));
      if (!dataDir.exists()) {
        dataDir.mkdirs();
        println("Created data directory: " + dataDir.getAbsolutePath());
      }
      
      // Load existing configuration or create a new one
      if (fileExists(configFilePath)) {
        println("Found existing config file");
        // Use a direct load approach without events during initialization
        try {
          config = loadJSONObject(configFilePath);
          validateConfig();
        } catch (Exception e) {
          println("Error loading config, using defaults: " + e.getMessage());
          setDefaults();
        }
      } else {
        println("No config file found, creating defaults");
        setDefaults();
        saveToFile();
      }
      
      println("ConfigManager initialized successfully");
    } catch (Exception e) {
      println("Error in ConfigManager constructor: " + e.getMessage());
      e.printStackTrace();
      // Initialize with empty config to prevent further errors
      config = new JSONObject();
      setDefaults();
    }
  }
  
  // Get singleton instance (non-static for Processing compatibility)
  public ConfigManager getInstance() {
    if (configManagerInstance == null) {
      configManagerInstance = new ConfigManager();
    }
    return configManagerInstance;
  }
  
  // Set default configuration values
  private void setDefaults() {
    // Window settings
    config.setInt("windowWidth", DEFAULT_WINDOW_WIDTH);
    config.setInt("windowHeight", DEFAULT_WINDOW_HEIGHT);
    
    // Mode settings
    config.setBoolean("simulationMode", DEFAULT_SIMULATION_MODE);
    
    // Pattern settings
    JSONObject patternConfig = new JSONObject();
    patternConfig.setInt("patternType", DEFAULT_PATTERN_TYPE);
    patternConfig.setInt("innerRadius", DEFAULT_INNER_RADIUS);
    patternConfig.setInt("middleRadius", DEFAULT_MIDDLE_RADIUS);
    patternConfig.setInt("outerRadius", DEFAULT_OUTER_RADIUS);
    patternConfig.setInt("ledSkip", DEFAULT_LED_SKIP);
    config.setJSONObject("pattern", patternConfig);
    
    // Camera settings
    JSONObject cameraConfig = new JSONObject();
    cameraConfig.setBoolean("enabled", DEFAULT_CAMERA_ENABLED);
    cameraConfig.setInt("preDelay", DEFAULT_CAMERA_PRE_DELAY);
    cameraConfig.setInt("pulseWidth", DEFAULT_CAMERA_PULSE_WIDTH);
    cameraConfig.setInt("postDelay", DEFAULT_CAMERA_POST_DELAY);
    config.setJSONObject("camera", cameraConfig);
    
    // Hardware settings
    JSONObject hardwareConfig = new JSONObject();
    hardwareConfig.setString("lastPort", "");
    config.setJSONObject("hardware", hardwareConfig);
  }
  
  // Flag to prevent recursive loading
  private boolean isLoading = false;
  
  // Load configuration from file
  public boolean loadFromFile() {
    // Prevent recursive calls
    if (isLoading) {
      println("WARNING: Recursive call to loadFromFile() prevented");
      return false;
    }
    
    isLoading = true;
    
    try {
      println("Loading configuration from: " + configFilePath);
      
      // Check if file exists before trying to load it
      if (!fileExists(configFilePath)) {
        println("Config file not found, using defaults");
        setDefaults();
        isLoading = false;
        return false;
      }
      
      // Load the config file
      config = loadJSONObject(configFilePath);
      
      // Validate and ensure all required fields exist
      validateConfig();
      
      // Notify that configuration has been loaded
      EventData configData = new EventData("source", "file");
      publishEvent(EventType.CONFIG_LOADED, configData);
      println("Configuration loaded successfully");
      
      isLoading = false;
      return true;
    } catch (Exception e) {
      println("Error loading configuration: " + e.getMessage());
      e.printStackTrace();
      
      // Fall back to defaults
      setDefaults();
      isLoading = false;
      return false;
    }
  }
  
  // Flag to prevent recursive saving
  private boolean isSaving = false;
  
  // Save configuration to file
  public boolean saveToFile() {
    // Prevent recursive calls
    if (isSaving) {
      println("WARNING: Recursive call to saveToFile() prevented");
      return false;
    }
    
    isSaving = true;
    
    try {
      println("Saving configuration to: " + configFilePath);
      
      // Make sure data directory exists
      File dataDir = new File(dataPath(""));
      if (!dataDir.exists()) {
        dataDir.mkdirs();
      }
      
      // Save the config file
      saveJSONObject(config, configFilePath);
      
      // Notify that configuration has been saved
      EventData configData = new EventData("source", "file");
      publishEvent(EventType.CONFIG_SAVED, configData);
      println("Configuration saved successfully");
      
      isSaving = false;
      return true;
    } catch (Exception e) {
      println("Error saving configuration: " + e.getMessage());
      e.printStackTrace();
      isSaving = false;
      return false;
    }
  }
  
  // Validate the configuration and ensure all required fields exist
  private void validateConfig() {
    // Check pattern config
    if (!config.hasKey("pattern")) {
      println("Config missing pattern key, creating default pattern config");
      JSONObject patternConfig = new JSONObject();
      patternConfig.setInt("patternType", DEFAULT_PATTERN_TYPE);
      patternConfig.setInt("innerRadius", DEFAULT_INNER_RADIUS);
      patternConfig.setInt("middleRadius", DEFAULT_MIDDLE_RADIUS);
      patternConfig.setInt("outerRadius", DEFAULT_OUTER_RADIUS);
      patternConfig.setInt("ledSkip", DEFAULT_LED_SKIP);
      config.setJSONObject("pattern", patternConfig);
    } else {
      // Debug - check the pattern type 
      JSONObject patternConfig = config.getJSONObject("pattern");
      println("Loaded pattern type from config: " + patternConfig.getInt("patternType", -1));
    }
    
    // Check camera config
    if (!config.hasKey("camera")) {
      JSONObject cameraConfig = new JSONObject();
      cameraConfig.setBoolean("enabled", DEFAULT_CAMERA_ENABLED);
      cameraConfig.setInt("preDelay", DEFAULT_CAMERA_PRE_DELAY);
      cameraConfig.setInt("pulseWidth", DEFAULT_CAMERA_PULSE_WIDTH);
      cameraConfig.setInt("postDelay", DEFAULT_CAMERA_POST_DELAY);
      config.setJSONObject("camera", cameraConfig);
    }
    
    // Check hardware config
    if (!config.hasKey("hardware")) {
      JSONObject hardwareConfig = new JSONObject();
      hardwareConfig.setString("lastPort", "");
      config.setJSONObject("hardware", hardwareConfig);
    }
  }
  
  // Check if a file exists
  private boolean fileExists(String path) {
    File file = new File(path);
    return file.exists();
  }
  
  // Get pattern configuration
  public JSONObject getPatternConfig() {
    return config.getJSONObject("pattern");
  }
  
  // Get camera configuration
  public JSONObject getCameraConfig() {
    return config.getJSONObject("camera");
  }
  
  // Get hardware configuration
  public JSONObject getHardwareConfig() {
    return config.getJSONObject("hardware");
  }
  
  // Get window width
  public int getWindowWidth() {
    return config.getInt("windowWidth", DEFAULT_WINDOW_WIDTH);
  }
  
  // Get window height
  public int getWindowHeight() {
    return config.getInt("windowHeight", DEFAULT_WINDOW_HEIGHT);
  }
  
  // Get simulation mode
  public boolean getSimulationMode() {
    return config.getBoolean("simulationMode", DEFAULT_SIMULATION_MODE);
  }
  
  // Set window dimensions
  public void setWindowDimensions(int width, int height) {
    config.setInt("windowWidth", width);
    config.setInt("windowHeight", height);
  }
  
  // Set simulation mode
  public void setSimulationMode(boolean simulationMode) {
    config.setBoolean("simulationMode", simulationMode);
  }
  
  // Set last used serial port
  public void setLastSerialPort(String portName) {
    JSONObject hardwareConfig = config.getJSONObject("hardware");
    hardwareConfig.setString("lastPort", portName);
    config.setJSONObject("hardware", hardwareConfig);
  }
  
  // Get last used serial port
  public String getLastSerialPort() {
    JSONObject hardwareConfig = config.getJSONObject("hardware");
    return hardwareConfig.getString("lastPort", "");
  }
  
  // Update pattern configuration
  public void updatePatternConfig(PatternModel model) {
    JSONObject patternConfig = config.getJSONObject("pattern");
    patternConfig.setInt("patternType", model.getPatternType());
    patternConfig.setInt("innerRadius", model.getInnerRingRadius());
    patternConfig.setInt("middleRadius", model.getMiddleRingRadius());
    patternConfig.setInt("outerRadius", model.getOuterRingRadius());
    patternConfig.setInt("ledSkip", model.getGridSpacing());
    config.setJSONObject("pattern", patternConfig);
  }
  
  // Update camera configuration
  public void updateCameraConfig(CameraModel model) {
    JSONObject cameraConfig = config.getJSONObject("camera");
    cameraConfig.setBoolean("enabled", model.isEnabled());
    cameraConfig.setInt("preDelay", model.getPreDelay());
    cameraConfig.setInt("pulseWidth", model.getPulseWidth());
    cameraConfig.setInt("postDelay", model.getPostDelay());
    config.setJSONObject("camera", cameraConfig);
  }
  
  /**
   * Handle events from the event system
   * Currently the ConfigManager publishes events but doesn't subscribe to any
   */
  @Override
  public void handleEvent(String eventType, EventData data) {
    // Implement if ConfigManager needs to respond to events in the future
    switch (eventType) {
      // Add event handling as needed
      
      default:
        // Unknown event type - just ignore
        break;
    }
  }
}