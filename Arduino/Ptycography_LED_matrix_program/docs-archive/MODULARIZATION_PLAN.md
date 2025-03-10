# Ptycography Controller Modularization Plan

## Goals
1. Modularize Processing code for better maintainability
2. Separate concerns (UI, business logic, hardware communication)
3. Improve code organization and reduce duplication
4. Prepare for eventual migration to Tauri

## Modularization Strategy

### 1. Create a Clean Architecture (✅ IMPLEMENTED)

```
Processing/CentralController/
├── models/              # Data structures and business logic
│   ├── PatternModel.pde
│   ├── SystemStateModel.pde
│   └── CameraModel.pde
├── controllers/         # Application control flow
│   └── AppController.pde
├── views/               # UI components and rendering
│   ├── MatrixViewRefactored.pde
│   └── StatusPanelViewRefactored.pde
├── utils/               # Utilities and helpers
│   ├── EventSystem.pde
│   ├── ConfigManager.pde
│   └── SerialManager.pde
└── Refactored_CentralController.pde  # Main application entry point
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

## Step-by-Step Refactoring Process (Current Progress)

### Phase 1: Extract Models (✅ COMPLETED)

1. ✅ Create base data structures
2. ✅ Move pattern generation algorithms to PatternModel
3. ✅ Move camera state management to CameraModel
4. ✅ Create proper state management in SystemStateModel

### Phase 2: Extract Controllers (✅ COMPLETED)

1. ✅ Move control logic from main file to appropriate controllers
2. ✅ Ensure controllers only depend on models, not views
3. ✅ Implement event-based communication between controllers

### Phase 3: Extract Views (🔄 IN PROGRESS)

1. ✅ Move UI rendering to specialized view classes
2. ✅ Implement observer pattern for model-view communication
3. ✅ Create event-based architecture for component interaction
4. 🔄 Migrate all views to use the event system (in progress)
5. ⏳ Remove old observer-based views

### Phase 4: Refine Hardware Communication (✅ COMPLETED)

1. ✅ Create a proper serial protocol specification
2. ✅ Extract serial communication to SerialManager
3. ✅ Implement error handling and retry logic

### Phase 5: Integration and Testing (🔄 IN PROGRESS)

1. ✅ Create a complete refactored main controller
2. ✅ Create a comprehensive test plan
3. 🔄 Execute the test plan and verify all functionality
4. ⏳ Clean up deprecated files
5. ⏳ Finalize documentation

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

## Completed Actions

1. ✅ Created the directory structure for models, views, controllers, and utilities
2. ✅ Extracted PatternModel, CameraModel, and SystemStateModel
3. ✅ Implemented EventSystem for component communication
4. ✅ Created views with both observer pattern and event system
5. ✅ Created SerialManager for hardware communication
6. ✅ Created ConfigManager for persisting settings
7. ✅ Created fully refactored main controller

## Next Actions

1. Clean up .pde files (only one main .pde file per directory)
2. Execute test plan and verify functionality
3. Remove deprecated observer-based views
4. Finalize documentation
5. Optimize performance and error handling

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