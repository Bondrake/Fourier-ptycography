/**
 * PtycographyConfig.java
 * 
 * Java version of the configuration file for Processing
 * This file parses the C/C++ header file to extract the configuration constants
 * and make them available to the Processing sketch.
 */

public class PtycographyConfig {
  // Matrix dimensions
  public static final int MATRIX_WIDTH = 64;
  public static final int MATRIX_HEIGHT = 64;
  
  // Pattern configuration
  public static final int INNER_RING_RADIUS = 16;
  public static final int MIDDLE_RING_RADIUS = 24;
  public static final int OUTER_RING_RADIUS = 31;
  public static final float LED_PITCH_MM = 2.0f;
  public static final float TARGET_LED_SPACING_MM = 4.0f;
  
  // Color constants
  public static final int COLOR_RED = 1;
  public static final int COLOR_GREEN = 2;
  public static final int COLOR_BLUE = 4;
  
  // Display settings
  public static final int CELL_SIZE = 8;
  public static final int GRID_PADDING_LEFT = 240;
  public static final int GRID_PADDING_TOP = 50;
  public static final int INFO_PANEL_WIDTH = 220;
  public static final int UPDATE_INTERVAL = 500;
  
  // Serial commands
  public static final char CMD_IDLE_ENTER = 'i';
  public static final char CMD_IDLE_EXIT = 'a';
  public static final char CMD_VIS_START = 'v';
  public static final char CMD_VIS_STOP = 'q';
  public static final char CMD_PATTERN_EXPORT = 'p';
  
  // This method could be extended to read the config from the C header file
  // For now, we're using hardcoded values that match the Arduino version
  public static void loadFromHeaderFile(String filePath) {
    // Future enhancement: Parse the C/C++ header file to extract configuration values
    // This would allow automatic synchronization between Arduino and Processing
  }
}