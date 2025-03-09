# Ptycography Controller Modularization Plan

## Goals
1. Modularize Processing code for better maintainability
2. Separate concerns (UI, business logic, hardware communication)
3. Improve code organization and reduce duplication
4. Prepare for eventual migration to Tauri

## Modularization Strategy

### 1. Create a Clean Architecture

```
Processing/CentralController/
├── models/           # Data structures and business logic
├── controllers/      # Application control flow
├── views/            # UI components and rendering
├── hardware/         # Hardware communication
├── utils/            # Utilities and helpers
└── CentralController.pde  # Main application entry point
```

### 2. Key Module Definitions

#### Models
- **PatternModel**: Encapsulates pattern data and generation algorithms
- **CameraModel**: Manages camera settings and state
- **SystemStateModel**: Handles the application state (running, idle, etc.)
- **ConfigModel**: Stores and manages configuration

#### Controllers
- **PatternController**: Controls pattern generation and manipulation
- **CameraController**: Controls camera operations
- **SerialController**: Manages serial communication
- **SequenceController**: Controls the illumination sequence

#### Views
- **MatrixView**: Renders the LED matrix
- **StatusPanelView**: Renders status information
- **ControlPanelView**: Renders control elements
- **CameraStatusView**: Renders camera status

#### Hardware
- **SerialManager**: Handles serial communication details
- **ArduinoCommands**: Defines commands for Arduino communication

## Step-by-Step Refactoring Process

### Phase 1: Extract Models

1. Create base data structures
2. Move pattern generation algorithms to PatternModel
3. Move camera state management to CameraModel
4. Create proper state management in SystemStateModel

### Phase 2: Extract Controllers

1. Move control logic from main file to appropriate controllers
2. Ensure controllers only depend on models, not views
3. Implement event-based communication between controllers

### Phase 3: Extract Views

1. Move UI rendering to specialized view classes
2. Implement observer pattern for model-view communication
3. Create a clean interface for controller-view interaction

### Phase 4: Refine Hardware Communication

1. Create a proper serial protocol specification
2. Extract serial communication to SerialManager
3. Implement error handling and retry logic

## Tauri Migration Notes

When migrating to Tauri later, this architecture will help by:

1. **Clear Boundaries**: The separation of concerns will make it clear which parts become frontend (views) and which parts become backend (models, hardware)

2. **Models → Rust Backend**: 
   - Models will be reimplemented in Rust
   - JSON structures will define data exchange between frontend and backend

3. **Views → Web Frontend**:
   - Views will be replaced with React/Vue/Svelte components
   - Styling will use CSS instead of Processing drawing

4. **Controllers → Split**:
   - Some controller logic will move to Rust backend
   - UI control logic will move to frontend components
   - Communication will use Tauri's API binding system

5. **Hardware → Rust**:
   - Serial communication will be implemented in Rust
   - Using libraries like `serialport-rs`

## Specific Migration Paths for Key Components

### Pattern Generator
- Processing: PatternModel class
- Tauri: Rust backend function exposed via Tauri commands

### Camera Control
- Processing: CameraController class
- Tauri: Rust backend with hardware communication exposed to frontend

### LED Matrix Visualization
- Processing: MatrixView class
- Tauri: Canvas or SVG rendering in web frontend

### Control Panel
- Processing: ControlPanelView with ControlP5
- Tauri: React components with modern UI framework

## Immediate Actions

1. Create the directory structure
2. Start with extracting PatternModel and MatrixView
3. Implement a basic event system for component communication
4. Create SystemStateModel to manage application state

## Processing-Specific Implementation Notes

### Using Processing's Object-Oriented Features
- Each module will be a proper Java/Processing class
- Main sketch will instantiate and coordinate modules

### Event System for Processing
- Create a simple EventBus class for inter-module communication
- Use interfaces and callbacks for event handling

### Handling Processing's Draw Loop
- Main sketch coordinates the draw sequence
- View objects have render() methods called from draw()
- Controllers update models outside of the draw loop

### File Organization in Processing
- Each class in its own .pde file in the sketch folder
- Group related files in tabs (Processing IDE) or subfolders (VS Code)

## Future Tauri Architecture Preview

```
ptycography-tauri/
├── src/                 # Rust backend
│   ├── main.rs          # Application entry
│   ├── models/          # Data models
│   ├── hardware/        # Hardware communication
│   └── commands/        # API exposed to frontend
├── src-ui/              # Web frontend
│   ├── components/      # UI components
│   ├── models/          # Frontend data structures
│   ├── services/        # API communication
│   └── views/           # Page components
└── build/               # Compiled applications
```