# Makefile for Google Workspace SCIM Sync

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod

# Build parameters
BINARY_NAME=scim-sync
BINARY_PATH=./cmd
DIST_DIR=dist

# Version information
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DATE ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

# Build flags
LDFLAGS=-ldflags="-s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.date=$(DATE)"
BUILD_FLAGS=-v $(LDFLAGS)

# Test flags
TEST_FLAGS=-v -race -coverprofile=coverage.out

.PHONY: all build clean dist-clean test test-coverage test-unit lint fmt vet deps deps-update help run dev build-all pre-commit validate install-tools check-tidy

# Default target
all: clean deps test build

# Build the application
build:
	@echo "Building $(BINARY_NAME)..."
	$(GOBUILD) $(BUILD_FLAGS) -o $(BINARY_NAME) $(BINARY_PATH)

# Clean build artifacts
clean:
	@echo "Cleaning..."
	$(GOCLEAN)
	rm -f $(BINARY_NAME)
	rm -f coverage.out

# Clean distribution directory
dist-clean:
	@echo "Cleaning distribution directory..."
	rm -rf $(DIST_DIR)

# Run all tests
test: test-unit

# Run unit tests with coverage
test-unit:
	@echo "Running unit tests..."
	$(GOTEST) $(TEST_FLAGS) ./...

# Run tests and generate coverage report
test-coverage: test-unit
	@echo "Generating coverage report..."
	$(GOCMD) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated: coverage.html"

# Run linter (requires golangci-lint to be installed)
lint:
	@echo "Running linter..."
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run --timeout=5m; \
	else \
		echo "golangci-lint not installed. Install with: go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest"; \
		exit 1; \
	fi

# Format code
fmt:
	@echo "Formatting code..."
	$(GOCMD) fmt ./...

# Run go vet
vet:
	@echo "Running go vet..."
	$(GOCMD) vet ./...

# Download dependencies
deps:
	@echo "Downloading dependencies..."
	$(GOMOD) download
	$(GOMOD) tidy

# Update dependencies
deps-update:
	@echo "Updating dependencies..."
	$(GOMOD) get -u ./...
	$(GOMOD) tidy

# Run the application in development mode
dev: build
	@echo "Running in development mode..."
	./$(BINARY_NAME) --help

# Run the application
run: build
	@echo "Running $(BINARY_NAME)..."
	./$(BINARY_NAME)

# Install development tools
install-tools:
	@echo "Installing development tools..."
	$(GOCMD) install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Check if go mod tidy is needed
check-tidy:
	@echo "Checking if go mod tidy is needed..."
	@cp go.mod go.mod.backup
	@cp go.sum go.sum.backup
	@$(GOMOD) tidy
	@if ! cmp -s go.mod go.mod.backup || ! cmp -s go.sum go.sum.backup; then \
		echo "go mod tidy would make changes. Please run 'make deps' to fix."; \
		mv go.mod.backup go.mod; \
		mv go.sum.backup go.sum; \
		exit 1; \
	else \
		rm go.mod.backup go.sum.backup; \
		echo "go.mod and go.sum are tidy"; \
	fi

# Validate all code quality checks
validate: fmt vet lint test check-tidy
	@echo "All validation checks passed!"

# Build for multiple platforms
build-all: dist-clean
	@echo "Building for multiple platforms..."
	@mkdir -p $(DIST_DIR)
	GOOS=linux GOARCH=amd64 $(GOBUILD) $(BUILD_FLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-linux-amd64 $(BINARY_PATH)
	GOOS=darwin GOARCH=amd64 $(GOBUILD) $(BUILD_FLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-darwin-amd64 $(BINARY_PATH)
	GOOS=darwin GOARCH=arm64 $(GOBUILD) $(BUILD_FLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-darwin-arm64 $(BINARY_PATH)
	GOOS=windows GOARCH=amd64 $(GOBUILD) $(BUILD_FLAGS) -o $(DIST_DIR)/$(BINARY_NAME)-windows-amd64.exe $(BINARY_PATH)

# Pre-commit hook (runs before committing)
pre-commit: validate
	@echo "Pre-commit checks completed successfully!"

# Display help
help:
	@echo "Available targets:"
	@echo "  all           - Clean, download deps, test, and build"
	@echo "  build         - Build the application"
	@echo "  clean         - Clean build artifacts"
	@echo "  dist-clean    - Clean distribution directory"
	@echo "  test          - Run all tests"
	@echo "  test-unit     - Run unit tests with coverage"
	@echo "  test-coverage - Generate HTML coverage report"
	@echo "  lint          - Run golangci-lint"
	@echo "  fmt           - Format code with go fmt"
	@echo "  vet           - Run go vet"
	@echo "  deps          - Download and tidy dependencies"
	@echo "  deps-update   - Update all dependencies"
	@echo "  dev           - Build and show help (development mode)"
	@echo "  run           - Build and run the application"
	@echo "  install-tools - Install development tools"
	@echo "  security      - Check for security vulnerabilities"
	@echo "  check-tidy    - Check if go mod tidy is needed"
	@echo "  validate      - Run all validation checks (fmt, vet, lint, test, tidy)"
	@echo "  build-all     - Build for multiple platforms"
	@echo "  pre-commit    - Run pre-commit validation checks"
	@echo "  help          - Show this help message"
