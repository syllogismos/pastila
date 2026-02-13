APP_NAME = Pastila
BUILD_DIR = build
APP_BUNDLE = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS_DIR = $(CONTENTS)/MacOS
SWIFT_FILES = $(shell find Sources -name '*.swift')

SWIFTC = swiftc
FRAMEWORKS = -framework AppKit -framework Carbon -framework CoreGraphics
RELEASE_FLAGS = -O -whole-module-optimization
DEBUG_FLAGS = -g -Onone

.PHONY: all clean run debug

all: $(MACOS_DIR)/$(APP_NAME)

$(MACOS_DIR)/$(APP_NAME): $(SWIFT_FILES) Info.plist | $(MACOS_DIR)
	$(SWIFTC) $(RELEASE_FLAGS) $(FRAMEWORKS) $(SWIFT_FILES) -o $@
	cp Info.plist $(CONTENTS)/Info.plist

$(MACOS_DIR):
	mkdir -p $(MACOS_DIR)

debug: $(SWIFT_FILES) Info.plist | $(MACOS_DIR)
	$(SWIFTC) $(DEBUG_FLAGS) $(FRAMEWORKS) $(SWIFT_FILES) -o $(MACOS_DIR)/$(APP_NAME)
	cp Info.plist $(CONTENTS)/Info.plist

run: all
	open $(APP_BUNDLE)

clean:
	rm -rf $(BUILD_DIR)
