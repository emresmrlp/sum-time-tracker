# Sum Time Tracker

A beautiful, ultra-minimalist, and professional macOS time tracker that lives right in your menu bar. Built natively using Swift and SwiftUI, it helps you track your work hours effortlessly without cluttering your workspace.

## Features

- **Menu Bar Integration:** Access the tracker instantly from your macOS menu bar. The icon dynamically updates to indicate whether you are actively recording time or idle.
- **Personalized Setup:** On the first launch, choose exactly where your time data is saved and pick an accent color from a curated 6-color palette to match your style.
- **Ultra-Minimalist UI:** Designed with a sleek, dark-mode focused monochrome aesthetic, avoiding neon colors or unnecessary visual noise.
- **Detailed Reports & Comparisons:** View your work hours for Today, This Week, and This Month, and instantly compare them with the previous day, week, and month.
- **Generate Detailed Logs:** Export beautifully formatted text reports showing a summary of your stats alongside a detailed chronological log of all your recent sessions. 
- **Transparent Data:** Your sessions are saved in standard `data.json` format using ISO8601 timestamps, allowing you to easily read, export, or analyze your raw data.
- **Smart Pause:** The tracker automatically pauses and securely saves your session if your Mac goes to sleep or shuts down.
- **Path Validation:** Built-in safeguards ensure your selected data directory is always valid.

## Installation & Build Instructions

This project requires no complex Xcode setup to compile. It comes with a simple `Makefile` that uses the native Swift compiler (`swiftc`) to build the application and package it into a standard macOS disk image (`.dmg`).

### Prerequisites
- macOS 13.0 or higher
- Apple Command Line Tools (or full Xcode) installed

### How to Build
1. Clone or download the repository to your Mac.
2. Open your terminal and navigate to the project directory.
3. Run the following command:
   ```bash
   make dmg
   ```
4. The script will compile the Swift files, bundle the resources, and generate a `SumTimeTracker.dmg` file.
5. Open the `.dmg` file and drag `SumTimeTracker.app` into the provided `Applications` shortcut folder.

### Cleaning the Build
To clean up the generated build files and the `.dmg`, run:
```bash
make clean
```

## Tech Stack
- **Swift & SwiftUI:** Core logic and UI design.
- **AppKit:** Used for handling the Menu Bar (`NSStatusItem`), the Popover (`NSPopover`), and detecting sleep/shutdown events (`NSWorkspace`).
- **Make & hdiutil:** Used for automated building and DMG packaging.

## Data Storage
Your data is completely private and stored locally on your machine. By default, it is saved to a folder named `sum-time-tracker-data` in your home directory, but you can change this during the initial setup (or later via the settings menu).

## License
This project is open-source and available for personal or professional use.
