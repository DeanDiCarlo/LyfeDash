XCODE_PROJECT := LifeTrack.xcodeproj
SCHEME := LifeTrack
DESTINATION := platform=iOS Simulator,name=iPhone 16

.PHONY: setup generate build test clean

setup:
	./scripts/bootstrap-macos.sh

generate:
	xcodegen generate

build: generate
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' build

test: generate
	xcodebuild -project $(XCODE_PROJECT) -scheme $(SCHEME) -destination '$(DESTINATION)' test

clean:
	rm -rf $(XCODE_PROJECT)
