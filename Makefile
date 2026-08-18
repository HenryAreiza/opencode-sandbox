IMAGE_NAME ?= opencode-sandbox:latest
USER_ID ?= $(shell id -u)
GROUP_ID ?= $(shell id -g)
BIN_DIR ?= $(HOME)/.local/bin
BINARY_NAME ?= opencode-sandbox

.PHONY: all build install update clean

all: build

build:
	@echo "Building $(IMAGE_NAME) for UID: $(USER_ID), GID: $(GROUP_ID)..."
	docker build \
		--build-arg USER_ID=$(USER_ID) \
		--build-arg GROUP_ID=$(GROUP_ID) \
		-t $(IMAGE_NAME) .

install:
	@echo "Installing runner script to $(BIN_DIR)/$(BINARY_NAME)..."
	@mkdir -p $(BIN_DIR)
	@install -m 755 opencode-runner.sh $(BIN_DIR)/$(BINARY_NAME)
	@echo "Done! Ensure '$(BIN_DIR)' is in your PATH."

update:
	@echo "Pulling latest base image and rebuilding $(IMAGE_NAME)..."
	docker build --pull --no-cache \
		--build-arg USER_ID=$(USER_ID) \
		--build-arg GROUP_ID=$(GROUP_ID) \
		-t $(IMAGE_NAME) .

clean:
	@echo "Removing runner script from $(BIN_DIR)..."
	@rm -f $(BIN_DIR)/$(BINARY_NAME)
	@echo "Removing Docker image $(IMAGE_NAME)..."
	-docker rmi $(IMAGE_NAME)
