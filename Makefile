.PHONY: all build test clean release lint vet build-all package-all

GOFLAGS := -ldflags="-s -w" -buildvcs=false
GOTOOLCHAIN ?= go1.22.5
BINS := tgeval tgrun tgserve

# Build for current platform only
build:
	@for bin in $(BINS); do \
		GOTOOLCHAIN=$(GOTOOLCHAIN) go build $(GOFLAGS) -o bin/$$bin ./cmd/$$bin/; \
	done

# Cross-compile for all common platforms (Linux, macOS, Windows) on amd64/arm64
build-all: clean
	@echo "Building for all platforms..."
	@mkdir -p bin/{linux-amd64,linux-arm64,darwin-amd64,darwin-arm64,windows-amd64,windows-arm64}

	# Linux builds (amd64 and arm64)
	@for bin in $(BINS); do \
		echo "Building $$bin for linux/amd64..."; \
		GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=linux GOARCH=amd64 go build $(GOFLAGS) -o bin/linux-amd64/$$bin ./cmd/$$bin/; \
	done
	@for bin in $(BINS); do \
		echo "Building $$bin for linux/arm64..."; \
		GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=linux GOARCH=arm64 go build $(GOFLAGS) -o bin/linux-arm64/$$bin ./cmd/$$bin/; \
	done

	# macOS builds (darwin-amd64 and darwin-arm64)
	@for bin in $(BINS); do \
		echo "Building $$bin for darwin/amd64..."; \
		GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=darwin GOARCH=amd64 go build $(GOFLAGS) -o bin/darwin-amd64/$$bin ./cmd/$$bin/; \
	done
	@for bin in $(BINS); do \
		echo "Building $$bin for darwin/arm64..."; \
		GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=darwin GOARCH=arm64 go build $(GOFLAGS) -o bin/darwin-arm64/$$bin ./cmd/$$bin/; \
	done

	# Windows builds (amd64 and arm64)
	@for bin in $(BINS); do \
		echo "Building $$bin for windows/amd64..."; \
		GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=windows GOARCH=amd64 go build $(GOFLAGS) -o bin/windows-amd64/$$bin.exe ./cmd/$$bin/; \
	done
	@for bin in $(BINS); do \
		echo "Building $$bin for windows/arm64..."; \
		GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=windows GOARCH=arm64 go build $(GOFLAGS) -o bin/windows-arm64/$$bin.exe ./cmd/$$bin/; \
	done

	@echo "Build complete. Binaries in bin/"

# Cross-compile for Alpine-compatible static binaries (uses CGO_ENABLED=0 with musl)
build-alpine: clean
	@echo "Building Alpine-compatible static binaries..."
	@mkdir -p bin/alpine-amd64 bin/alpine-arm64

	# Alpine amd64 (static, no external dependencies)
	@for bin in $(BINS); do \
		echo "Building $$bin for alpine/amd64..."; \
		CGO_ENABLED=0 GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=linux GOARCH=amd64 go build -tags muslc $(GOFLAGS) -o bin/alpine-amd64/$$bin ./cmd/$$bin/; \
	done

	# Alpine arm64 (static, no external dependencies)
	@for bin in $(BINS); do \
		echo "Building $$bin for alpine/arm64..."; \
		CGO_ENABLED=0 GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=linux GOARCH=arm64 go build -tags muslc $(GOFLAGS) -o bin/alpine-arm64/$$bin ./cmd/$$bin/; \
	done

	@echo "Alpine builds complete. Binaries in bin/alpine-*"

# Run all tests with race detector
test:
	GOTOOLCHAIN=$(GOTOOLCHAIN) go test -race -count=1 ./...

# Run vet checks
vet:
	GOTOOLCHAIN=$(GOTOOLCHAIN) go vet ./...

# Run linter (requires golangci-lint)
lint:
	golangci-lint run ./...

# Clean build artifacts
clean:
	rm -rf bin/ tracegen-*.tar.gz output/

# Install binaries to /usr/local/bin
install: build
	sudo cp bin/tgeval bin/tgrun bin/tgserve /usr/local/bin/

# Create distribution tarballs for all platforms
package-all: build-all
	@echo "Creating distribution packages..."

	# Linux packages
	cd bin/linux-amd64 && tar -czf ../../tracegen-linux-amd64.tar.gz ./* && cd ../..
	cd bin/linux-arm64 && tar -czf ../../tracegen-linux-arm64.tar.gz ./* && cd ../..
	cd bin/alpine-amd64 && tar -czf ../../tracegen-alpine-amd64.tar.gz ./* && cd ../..
	cd bin/alpine-arm64 && tar -czf ../../tracegen-alpine-arm64.tar.gz ./* && cd ../..

	# macOS packages
	cd bin/darwin-amd64 && tar -czf ../../tracegen-darwin-amd64.tar.gz ./* && cd ../..
	cd bin/darwin-arm64 && tar -czf ../../tracegen-darwin-arm64.tar.gz ./* && cd ../..

	# Windows packages (zip instead of tar for better compatibility)
	cd bin/windows-amd64 && zip -r ../../tracegen-windows-amd64.zip ./* && cd ../..
	cd bin/windows-arm64 && zip -r ../../tracegen-windows-arm64.zip ./* && cd ../..

	@echo "Packages created: tracegen-*.tar.gz (Linux/macOS/Alpine), tracegen-*.zip (Windows)"

# Show version info
version:
	@echo "CYMERTEK Trace Generator"
	@git describe --tags 2>/dev/null || echo "development"
