.PHONY: build_types

BUILD_ID := $(or $(GITHUB_RUN_ID),dev)

build:
	fvm dart run build_runner build --delete-conflicting-outputs
