# Claude Meter — macOS menu bar app
# Build & package into a relocatable .app bundle

APP_NAME    := Claude Meter
BUNDLE_ID   := com.claudemeter.menubar
EXECUTABLE  := ClaudeMeter
BUILD_DIR   := .build/release
APP_DIR     := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS    := $(APP_DIR)/Contents
MACOS_DIR   := $(CONTENTS)/MacOS
RES_DIR     := $(CONTENTS)/Resources

.PHONY: build bundle run clean dmg

# ── Build optimised binary ──────────────────────────────────────────
build:
	swift build -c release

# ── Assemble .app bundle ────────────────────────────────────────────
bundle: build
	@echo "→ Assembling $(APP_NAME).app …"
	@mkdir -p "$(MACOS_DIR)" "$(RES_DIR)"
	@cp "$(BUILD_DIR)/$(EXECUTABLE)" "$(MACOS_DIR)/$(EXECUTABLE)"
	@cp Resources/Info.plist "$(CONTENTS)/Info.plist"
	@echo "✓ $(APP_DIR)"

# ── Build + run immediately ─────────────────────────────────────────
run: bundle
	@open "$(APP_DIR)"

# ── Install to /Applications ────────────────────────────────────────
install: bundle
	@echo "→ Installing to /Applications …"
	@rm -rf "/Applications/$(APP_NAME).app"
	@cp -R "$(APP_DIR)" "/Applications/$(APP_NAME).app"
	@echo "✓ Installed"

# ── Package as DMG ──────────────────────────────────────────────────
DMG_NAME := ClaudeMeter.dmg
dmg: bundle
	@echo "→ Creating $(DMG_NAME) …"
	@rm -f "$(BUILD_DIR)/$(DMG_NAME)"
	@hdiutil create -volname "Claude Meter" \
		-srcfolder "$(APP_DIR)" \
		-ov -format UDZO \
		"$(BUILD_DIR)/$(DMG_NAME)" > /dev/null
	@echo "✓ $(BUILD_DIR)/$(DMG_NAME)"

# ── Clean ───────────────────────────────────────────────────────────
clean:
	swift package clean
	rm -rf .build
