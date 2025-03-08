# Installing Required Libraries for Central Controller

The Central Controller for the Ptycography LED Matrix requires the ControlP5 library to be installed in Processing. This document explains how to install this library.

## Installing ControlP5

### Method 1: Using Processing's Library Manager (Recommended)

1. Open Processing
2. Go to the menu: **Sketch > Import Library > Add Library...**
3. A "Libraries" window will open
4. In the search box at the top, type **ControlP5**
5. Select the **ControlP5** library from the search results
6. Click the "Install" button on the bottom right
7. Wait for the installation to complete
8. Restart Processing

![Library Manager Screenshot](https://github.com/sojamo/controlp5/raw/master/documentation/images/controlp5-installation.png)

### Method 2: Manual Installation

If you're having issues with the Library Manager, you can install ControlP5 manually:

1. Download the latest version of ControlP5 from: https://github.com/sojamo/controlp5/releases 
2. Unzip the downloaded file
3. Navigate to your Processing libraries folder:
   - Windows: `Documents/Processing/libraries/`
   - Mac: `~/Documents/Processing/libraries/`
   - Linux: `~/sketchbook/libraries/`
4. Create a new folder called `controlP5` in the libraries folder
5. Copy the contents of the unzipped ControlP5 folder into the newly created `controlP5` folder
6. Restart Processing

## Verifying Installation

To verify that the library is installed correctly:

1. Open Processing
2. Go to the menu: **Sketch > Import Library**
3. You should see **ControlP5** in the list of available libraries

If you don't see ControlP5 in the list, try restarting Processing. If it still doesn't appear, try the manual installation method.

## Troubleshooting

If you encounter issues installing or using the library:

1. **Check Processing version**: Make sure you're using a recent version of Processing (3.x or later is recommended)
2. **Check library compatibility**: Ensure the library version is compatible with your Processing version
3. **Check folder structure**: The library should be in `libraries/controlP5/library/controlP5.jar`
4. **Check for error messages**: Look for any error messages in the Processing console

## Resources

- ControlP5 GitHub Repository: https://github.com/sojamo/controlp5
- ControlP5 Documentation: http://www.sojamo.de/libraries/controlP5/
- Processing Libraries Overview: https://processing.org/reference/libraries/