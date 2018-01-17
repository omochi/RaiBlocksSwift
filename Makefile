LIBS_DIR := ${CURDIR}/Libs/macos
SWIFT_FLAGS += -Xlinker "-L${LIBS_DIR}"
SWIFT_FLAGS += -Xlinker "-lb2"

.PHONY:	clean build test

clean:
	swift package clean

build:
	swift build ${SWIFT_FLAGS}

test:
	swift test ${SWIFT_FLAGS}

xcode:
	swift package ${SWIFT_FLAGS} generate-xcodeproj

