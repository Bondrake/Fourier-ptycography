# Processing Code Organization Update

## Important Notice

The Processing code for the Ptycography LED Matrix project has been restructured and simplified.

### Changes Made:

1. **Directory Structure Simplified**: 
   - All code now resides in a flat structure in the `Processing/` directory
   - No more nested directories (models/views/controllers/utils)
   - Consistent file naming with prefixes (Model_, View_, Controller_, Util_)

2. **Documentation Consolidated**:
   - Previous documentation has been consolidated into a single README.md file
   - See `Processing/README.md` for detailed instructions and coding standards

3. **Processing Compatibility Issues Fixed**:
   - Fixed issues with the `color` type/parameter name
   - Added `static` to enum declarations as required by Processing
   - All code is now directly compatible with Processing's requirements

### Previous Documentation

The following documentation files are now **outdated** and kept only for reference:
- `PROCESSING_CODING_STANDARDS.md`
- `PROCESSING_STRUCTURE.md`
- `PROCESSING_WORKAROUNDS.md`

Please refer to `Processing/README.md` for the current documentation.

### Key Tips for Processing Development

1. All code must be in a flat directory structure (no subdirectories)
2. Use prefixes to organize code:
   - `Model_` for data models
   - `View_` for visualization components
   - `Controller_` for application logic
   - `Util_` for utility classes

3. Always use `int` instead of `color` for color variables and parameters
4. All enums inside classes must be declared as `static`

Please see the consolidated documentation in `Processing/README.md` for more details.