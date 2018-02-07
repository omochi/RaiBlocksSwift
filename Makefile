.PHONY:	clean build test

clean:
	swift package clean

build:
	swift build

test:
	swift test

xcode:
	swift package generate-xcodeproj
	cd Script; \
		swift run fix-xcodeproj
