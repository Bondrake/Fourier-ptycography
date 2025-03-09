/**
 * ConfigManager.pde
 * 
 * Manages configuration settings for the application.
 * Supports loading/saving from/to JSON files.
 * 
 * This would be reimplemented using Rust in a Tauri migration.
 */

class ConfigManager {
  private JSONObject config;
  private String configFilePath;
  private static ConfigManager instance = null;
  
  // Default configuration values
  private static final int DEFAULT_WINDOW_WIDTH = 1280;
  private static final int DEFAULT_WINDOW_HEIGHT = 800;
  private static final boolean DEFAULT_SIMULATION_MODE = true;
  private static final int DEFAULT_PATTERN_TYPE = 0; // Concentric rings
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
    config = new JSONObject();
    configFilePath = dataPath("config.json");
    
    // Load existing configuration or create a new one
    if (fileExists(configFilePath)) {
      loadFromFile();
    } else {
      setDefaults();
      saveToFile();
    }
  }
  
  // Get singleton instance
  public static ConfigManager getInstance() {
    if (instance == null) {
      instance = new ConfigManager();
    }
    return instance;
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
  
  // Load configuration from file
  public boolean loadFromFile() {
    try {
      config = loadJSONObject(configFilePath);
      
      // Validate and ensure all required fields exist
      validateConfig();
      
      // Notify that configuration has been loaded
      EventBus.getInstance().publish(EventType.CONFIG_LOADED);
      
      return true;
    } catch (Exception e) {
      println("Error loading configuration: " + e.getMessage());
      
      // Fall back to defaults
      setDefaults();
      return false;
    }
  }
  
  // Save configuration to file
  public boolean saveToFile() {
    try {
      saveJSONObject(config, configFilePath);
      
      // Notify that configuration has been saved
      EventBus.getInstance().publish(EventType.CONFIG_SAVED);
      
      return true;
    } catch (Exception e) {
      println("Error saving configuration: " + e.getMessage());
      return false;
    }
  }
  
  // Validate the configuration and ensure all required fields exist
  private void validateConfig() {
    // Check pattern config
    if (!config.hasKey("pattern")) {
      JSONObject patternConfig = new JSONObject();
      patternConfig.setInt("patternType", DEFAULT_PATTERN_TYPE);
      patternConfig.setInt("innerRadius", DEFAULT_INNER_RADIUS);
      patternConfig.setInt("middleRadius", DEFAULT_MIDDLE_RADIUS);
      patternConfig.setInt("outerRadius", DEFAULT_OUTER_RADIUS);
      patternConfig.setInt("ledSkip", DEFAULT_LED_SKIP);
      config.setJSONObject("pattern", patternConfig);
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
}