# Documentation Update - March 2025

> **Note**: This document describes the documentation organization in the `modularization` branch.

## Important Notice: Documentation Consolidation

The project documentation has been consolidated and reorganized for better clarity:

1. **Documentation Simplification**:
   - Primary documentation has been consolidated into just a few key files
   - Historical/reference documentation has been moved to the `docs-archive` directory
   - Documentation now has a clear hierarchy

2. **Current Documentation Structure**:
   - `README.md` - Main project overview and getting started guide
   - `ARCHITECTURE.md` - Comprehensive architecture documentation (consolidated)
   - `TEST.md` - Complete testing documentation (consolidated)
   - `CLAUDE.md` - Development guide for AI assistant
   - `Processing/README.md` - Processing code documentation

3. **Documentation Hierarchy**:
   - Start with the main `README.md` for an overview
   - Reference `ARCHITECTURE.md` for design details
   - Use `TEST.md` for testing information
   - See `Processing/README.md` for Processing-specific implementation

## Historical Documentation

The following documentation has been moved to the `docs-archive` directory:

- `BRANCH_CLEANUP_PLAN.md` - Branch organization docs
- `CENTRAL_CONTROLLER.md` - Now consolidated into ARCHITECTURE.md
- `CONFIG_SETUP.md` - Old configuration approach
- `JAVA_PROJECT_SETUP.md` - Alternative approach (not implemented)
- `MODULARIZATION_PLAN.md` - Initial modularization approach
- `REFACTORING.md` - Original refactoring approach
- `REFACTORING_PROGRESS.md` - Tracking document for refactoring
- `TEST_PLAN.md` - Now consolidated into TEST.md
- `TEST_SCRIPT.md` - Now consolidated into TEST.md

These files are preserved for historical reference but should not be used for current development.

## Processing Code Structure

The Processing code uses a flat directory structure with consistent naming prefixes:

- `Model_*.pde` - Data models (PatternModel, SystemStateModel, CameraModel)
- `View_*.pde` - UI components (MatrixView, StatusPanelView)
- `Controller_*.pde` - Application logic (AppController)
- `Util_*.pde` - Utilities (ConfigManager, EventSystem, SerialManager, UIManager)
- `CentralController.pde` - Main application entry point