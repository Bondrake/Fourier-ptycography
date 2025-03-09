/**
 * Refactored_CentralController_Example.pde
 * 
 * Example skeleton of how the refactored main sketch would look.
 * This demonstrates the reduced complexity in the main file by using the
 * modular architecture.
 * 
 * This file shows how all the pieces connect together but is not meant
 * to be used directly. It's a reference for the refactoring process.
 */

import controlP5.*;
import processing.serial.*;

// Main controller
AppController controller;

/**
 * Setup function - runs once at the beginning
 */
void setup() {
  // Setup window
  size(1280, 800);
  surface.setTitle("Ptycography LED Matrix Controller");
  
  // Create controller
  controller = new AppController(this);
  
  // Print startup message
  println("Ptycography LED Matrix Controller started");
  println("Use keys: g=grid, space=pause/resume, r=refresh ports");
}

/**
 * Draw function - runs continuously
 */
void draw() {
  // Clear background
  background(20);
  
  // Let controller handle drawing
  controller.draw();
  
  // Draw framerate for debugging
  fill(150);
  textAlign(RIGHT, BOTTOM);
  textSize(12);
  text("FPS: " + int(frameRate), width - 10, height - 5);
}

/**
 * Serial event handler
 */
void serialEvent(Serial port) {
  // Pass to controller's serial manager
  controller.getSerialManager().processSerialEvent(port);
}

/**
 * Key pressed handler
 */
void keyPressed() {
  // Let controller handle key presses
  controller.keyPressed(key);
}

/**
 * Mouse pressed handler
 */
void mousePressed() {
  // If needed, pass to controller
}

/**
 * Window resize handler
 */
void windowResized() {
  // Update layout if needed
}

// ControlP5 callbacks would be defined here
// They would simply call appropriate controller methods

/**
 * Start sequence button callback
 */
public void startSequenceButton() {
  controller.startSequence();
}

/**
 * Stop sequence button callback
 */
public void stopSequenceButton() {
  controller.stopSequence();
}

/**
 * Enter idle mode button callback
 */
public void enterIdleButton() {
  controller.enterIdleMode();
}

/**
 * Exit idle mode button callback
 */
public void exitIdleButton() {
  controller.exitIdleMode();
}

/**
 * Pattern type dropdown callback
 */
public void patternTypeDropdown(int value) {
  controller.setPatternType(value);
}

/**
 * Hardware connect button callback
 */
public void connectButton() {
  int selectedPort = controller.getControlP5().get(ScrollableList.class, "portList").getValue();
  controller.connectToHardware(selectedPort);
}

/**
 * Hardware disconnect button callback
 */
public void disconnectButton() {
  controller.disconnectFromHardware();
}

/**
 * Simulation mode toggle callback
 */
public void simulationModeToggle(boolean value) {
  if (value) {
    controller.startSimulation();
  }
}

/**
 * Camera test button callback
 */
public void testCameraButton() {
  controller.testCameraTrigger();
}

/**
 * Camera settings update callback
 */
public void updateCameraSettings() {
  boolean enabled = controller.getControlP5().get(Toggle.class, "cameraEnabledToggle").getState();
  int preDelay = controller.getControlP5().get(Slider.class, "cameraPreDelaySlider").getValue();
  int pulseWidth = controller.getControlP5().get(Slider.class, "cameraPulseWidthSlider").getValue();
  int postDelay = controller.getControlP5().get(Slider.class, "cameraPostDelaySlider").getValue();
  
  controller.setCameraSettings(enabled, preDelay, pulseWidth, postDelay);
}