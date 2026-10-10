# Sum Time Tracker

![Version](https://img.shields.io/badge/version-v0.1.0-blue.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Swift](https://img.shields.io/badge/swift-5.0-orange.svg)

A beautiful, ultra-minimalist, and professional macOS time tracker that lives right in your menu bar. Built natively using Swift and SwiftUI, it helps you track your work hours effortlessly without cluttering your workspace.

## Features

- **Menu Bar Integration:** Access the tracker instantly from your macOS menu bar. The icon dynamically updates (`timer` to `timer.circle.fill`) to indicate whether you are actively recording time or idle.
- **Smart Launch Alerts:** On the very first launch, a welcome pop-up guides you to the menu bar and provides a quick link to this GitHub page. Subsequent launches will discreetly remind you that the app is running in the background.
- **Personalized Setup:** On the first launch, choose exactly where your time data is saved and pick an accent color from a curated 6-color palette to match your style.
- **Ultra-Minimalist UI:** Designed with a sleek, dark-mode focused monochrome aesthetic, avoiding neon colors or unnecessary visual noise.
- **Detailed Reports & Comparisons:** View your work hours for Today, This Week, and This Month, and instantly compare them with the previous day, week, and month.
- **Generate Detailed Logs:** Export beautifully formatted `.txt` reports to your data folder. The app prevents accidental overwrites by ensuring you can only generate one safe report per minute. 
- **Transparent Data:** Your sessions are saved in a highly readable `data.json` format using precise ISO8601 timestamps. Easily read, export, or parse your raw data with external analysis tools.
- **Smart Pause:** The tracker automatically pauses and securely saves your session if your Mac goes to sleep, shuts down, or loses power.

## Installation & Build Instructions

This project requires no complex Xcode setup to compile. It comes with a streamlined `Makefile` that uses the native Swift compiler (`swiftc`) to build the application and package it into a versioned macOS disk image (`.dmg`).

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
4. The script will compile the Swift files, bundle the custom assets (including the `AppIcon.icns`), and generate a versioned DMG file (e.g., `SumTimeTracker-v0.1.0.dmg`).
5. Open the `.dmg` file and drag `SumTimeTracker.app` into the provided `Applications` shortcut folder.

### Cleaning the Build
To clean up the generated build files and the `.dmg`, run:
```bash
make clean
```

## Tech Stack
- **Swift & SwiftUI:** Core logic and UI design.
- **AppKit:** Used for handling the Menu Bar (`NSStatusItem`), the Popover (`NSPopover`), managing Launch Alerts (`NSAlert`), and detecting sleep/shutdown events (`NSWorkspace`).
- **Make & hdiutil:** Used for automated building and DMG packaging.

## Data Storage
Your data is completely private and stored locally on your machine. By default, it is saved to a folder named `sum-time-tracker-data` in your home directory, but you can change this during the initial setup (or later via the settings menu).

## License
This project is open-source and available for personal or professional use.
