# Contractor Must Do - Makefile
# ==============================
# Quick commands for building and testing

.PHONY: setup build test lint clean open

# Generate Xcode project
setup:
	@./setup.sh

# Open project in Xcode
open:
	@open ContractorMustDo.xcodeproj

# Build the app
build:
	@echo "🔨 Building..."
	@xcodebuild -scheme ContractorMustDo -destination 'platform=iOS Simulator,name=iPhone 15' build | xcpretty

# Run tests
test:
	@echo "🧪 Running tests..."
	@xcodebuild test -scheme ContractorMustDo -destination 'platform=iOS Simulator,name=iPhone 15' | xcpretty

# Run SwiftLint
lint:
	@echo "🔍 Linting..."
	@if command -v swiftlint &> /dev/null; then \
		swiftlint lint --strict; \
	else \
		echo "SwiftLint not installed. Run: brew install swiftlint"; \
	fi

# Clean build artifacts
clean:
	@echo "🧹 Cleaning..."
	@xcodebuild clean -scheme ContractorMustDo
	@rm -rf ~/Library/Developer/Xcode/DerivedData/ContractorMustDo-*

# Install dependencies (xcodegen, swiftlint, xcpretty)
deps:
	@echo "📦 Installing dependencies..."
	@brew install xcodegen swiftlint xcpretty

# Full setup: install deps + generate project
all: deps setup
	@echo "✅ Ready to go! Run 'make open' to open in Xcode"

# Help
help:
	@echo "Available commands:"
	@echo "  make setup  - Generate Xcode project"
	@echo "  make open   - Open project in Xcode"
	@echo "  make build  - Build the app"
	@echo "  make test   - Run unit tests"
	@echo "  make lint   - Run SwiftLint"
	@echo "  make clean  - Clean build artifacts"
	@echo "  make deps   - Install dependencies"
	@echo "  make all    - Full setup (deps + generate)"
