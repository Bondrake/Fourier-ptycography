# Setting Up a Java Project for Processing

This guide explains how to set up a Java project that uses Processing libraries, allowing us to use proper package structure while maintaining compatibility with the Processing ecosystem.

## Prerequisites

1. Java Development Kit (JDK) 11 or newer
2. A Java IDE (IntelliJ IDEA, Eclipse, or VS Code)
3. Processing 4.x installed
4. Maven or Gradle for dependency management

## Project Structure

We'll use the following structure for our Java project:

```
ptycography-controller/
├── pom.xml                          # Maven project definition
├── src/
│   └── main/
│       ├── java/                    # Java source files
│       │   └── org/ptycography/
│       │       ├── PtycographyApp.java   # Main application entry point
│       │       ├── models/               # Models package
│       │       ├── views/                # Views package
│       │       ├── controllers/          # Controllers package
│       │       └── utils/                # Utilities package
│       └── resources/                # Resource files (images, data, etc.)
└── processing-lib/                  # Local Processing libraries (if needed)
```

## Step 1: Create a Maven Project

1. Create a new directory for the project:
```bash
mkdir -p ptycography-controller/src/main/java/org/ptycography
```

2. Create a `pom.xml` file in the project root:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>org.ptycography</groupId>
    <artifactId>ptycography-controller</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
        <processing.version>4.0.1</processing.version>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <repositories>
        <repository>
            <id>processing-repo</id>
            <url>https://dl.bintray.com/processing/processing-core</url>
        </repository>
    </repositories>

    <dependencies>
        <!-- Processing Core -->
        <dependency>
            <groupId>org.processing</groupId>
            <artifactId>core</artifactId>
            <version>${processing.version}</version>
        </dependency>
        <!-- ControlP5 - You'll need to install this locally -->
        <dependency>
            <groupId>cc.controlp5</groupId>
            <artifactId>controlp5</artifactId>
            <version>2.2.6</version>
            <scope>system</scope>
            <systemPath>${project.basedir}/processing-lib/controlP5.jar</systemPath>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-shade-plugin</artifactId>
                <version>3.2.4</version>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>shade</goal>
                        </goals>
                        <configuration>
                            <transformers>
                                <transformer implementation="org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
                                    <mainClass>org.ptycography.PtycographyApp</mainClass>
                                </transformer>
                            </transformers>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

## Step 2: Copy Processing Libraries

1. Copy the Processing core and ControlP5 libraries to your project:

```bash
# Create processing-lib directory
mkdir -p ptycography-controller/processing-lib

# Copy ControlP5 library
cp /path/to/processing/libraries/controlP5/library/controlP5.jar ptycography-controller/processing-lib/
```

## Step 3: Create the Main Application Class

Create `src/main/java/org/ptycography/PtycographyApp.java`:

```java
package org.ptycography;

import processing.core.PApplet;
import controlP5.ControlP5;

/**
 * Main Processing application for Ptycography LED Matrix Controller
 */
public class PtycographyApp extends PApplet {
    
    // Constants
    private static final int WINDOW_WIDTH = 1080;
    private static final int WINDOW_HEIGHT = 1100;
    
    // UI Components
    private ControlP5 cp5;
    
    /**
     * Entry point - this passes command line arguments to PApplet
     */
    public static void main(String[] args) {
        PApplet.main(PtycographyApp.class.getName(), args);
    }
    
    /**
     * Processing settings method - called before setup()
     */
    @Override
    public void settings() {
        size(WINDOW_WIDTH, WINDOW_HEIGHT);
    }
    
    /**
     * Processing setup method - initialize components
     */
    @Override
    public void setup() {
        // Initialize UI
        cp5 = new ControlP5(this);
        
        // Set window title
        surface.setTitle("Ptycography LED Matrix Controller");
        
        // Initialize components
        // TODO: Initialize models, views, and controllers
        
        // Setup environment
        frameRate(30);
        background(0);
        textSize(14);
        
        println("Ptycography LED Matrix Controller started");
    }
    
    /**
     * Processing draw method - called continuously
     */
    @Override
    public void draw() {
        // Clear background
        background(0);
        
        // Draw components
        // TODO: Draw UI components
    }
    
    /**
     * Handle key press events
     */
    @Override
    public void keyPressed() {
        // TODO: Handle key events
    }
}
```

## Step 4: Create Package Structure and Migrate Classes

1. Create the necessary directories to match our package structure:

```bash
mkdir -p ptycography-controller/src/main/java/org/ptycography/models
mkdir -p ptycography-controller/src/main/java/org/ptycography/views
mkdir -p ptycography-controller/src/main/java/org/ptycography/controllers
mkdir -p ptycography-controller/src/main/java/org/ptycography/utils
```

2. Convert existing `.pde` files to Java classes:
   - Add proper package declarations
   - Use proper Java imports
   - Change `.pde` extension to `.java`
   - Fix any Processing-specific syntax

## Step 5: Run and Debug

1. Import the Maven project into your Java IDE
2. Build the project: `mvn compile`
3. Run the main class: `PtycographyApp.java`

## Processing-Specific Considerations

1. **Resources**: Files in `data/` directory should be moved to `src/main/resources/`
2. **PDE Preprocessor**: Processing does some preprocessing that Java doesn't. Watch for:
   - Method overloading with different return types
   - Automatic type conversion
   - Special Processing syntax

3. **Library Initialization**: Some Processing libraries require explicit initialization:
```java
// Instead of the automatic Processing import
import controlP5.*;

// Use explicit Java import
import controlP5.ControlP5;
import controlP5.Button;
```

## IDEs and Development Flow

### IntelliJ IDEA
1. Import as Maven project
2. Run configurations for direct execution
3. Use the Processing plugin for p5.js support

### VS Code
1. Use Maven extension
2. Configure Java Project properly
3. Set up launch configurations

### Eclipse
1. Import as Maven project
2. Set up run configurations

## Deployment

To create a runnable JAR:

```bash
mvn package
```

This will create a JAR that includes all required dependencies.