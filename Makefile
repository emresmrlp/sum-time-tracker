APP_NAME = SumTimeTracker
VERSION = 0.1.0
APP_BUNDLE = $(APP_NAME).app
MACOS_DIR = $(APP_BUNDLE)/Contents/MacOS
RESOURCES_DIR = $(APP_BUNDLE)/Contents/Resources
DMG_NAME = $(APP_NAME)-v$(VERSION).dmg
DMG_STAGE = dmg_stage
ICONSET_DIR = AppIcon.iconset

SWIFT_FILES = $(wildcard Sources/*.swift)

all: build dmg

build:
	@echo "Building $(APP_NAME)..."
	@mkdir -p "$(MACOS_DIR)"
	@mkdir -p "$(RESOURCES_DIR)"
	@cp Info.plist "$(APP_BUNDLE)/Contents/Info.plist"
	@if [ -f "Assets/AppIcon.icns" ]; then \
		cp "Assets/AppIcon.icns" "$(RESOURCES_DIR)/AppIcon.icns"; \
	fi
	@swiftc $(SWIFT_FILES) -o "$(MACOS_DIR)/$(APP_NAME)"
	@echo "Build complete."

dmg: build
	@echo "Creating DMG..."
	@rm -rf $(DMG_STAGE)
	@mkdir -p $(DMG_STAGE)
	@cp -R "$(APP_BUNDLE)" "$(DMG_STAGE)/"
	@ln -s /Applications "$(DMG_STAGE)/Applications"
	@hdiutil create -volname "$(APP_NAME)" -srcfolder "$(DMG_STAGE)" -ov -format UDZO "$(DMG_NAME)"
	@rm -rf $(DMG_STAGE)
	@echo "DMG created: $(DMG_NAME)"

clean:
	@rm -rf "$(APP_BUNDLE)" "$(DMG_NAME)" "$(DMG_STAGE)"
