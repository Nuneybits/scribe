APP_NAME := Scribe
CONFIG ?= release

.PHONY: build run test app dmg

build:
	swift build -c $(CONFIG)

run:
	swift run $(APP_NAME)

test:
	swift test

app:
	./scripts/package_app.sh $(CONFIG)

dmg:
	./scripts/create_dmg.sh
