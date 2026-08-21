.PHONY: all build test clean release lint vet

GOFLAGS := -ldflags="-s -w"
GOTOOLCHAIN ?= go1.22.5

all: build

# Build all binaries
build:
	GOTOOLCHAIN=$(GOTOOLCHAIN) go build $(GOFLAGS) -o bin/tgeval ./cmd/tgeval/
	GOTOOLCHAIN=$(GOTOOLCHAIN) go build $(GOFLAGS) -o bin/tgrun ./cmd/tgrun/
	GOTOOLCHAIN=$(GOTOOLCHAIN) go build $(GOFLAGS) -o bin/tgserve ./cmd/server/

# Cross-compile for distribution
release: clean
	@mkdir -p bin/linux-amd64 bin/windows-amd64
	GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=linux GOARCH=amd64 go build $(GOFLAGS) -o bin/linux-amd64/tgeval ./cmd/tgeval/
	GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=linux GOARCH=amd64 go build $(GOFLAGS) -o bin/linux-amd64/tgrun ./cmd/tgrun/
	GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=linux GOARCH=amd64 go build $(GOFLAGS) -o bin/linux-amd64/tgserve ./cmd/server/
	GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=windows GOARCH=amd64 go build $(GOFLAGS) -o bin/windows-amd64/tgeval.exe ./cmd/tgeval/
	GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=windows GOARCH=amd64 go build $(GOFLAGS) -o bin/windows-amd64/tgrun.exe ./cmd/tgrun/
	GOTOOLCHAIN=$(GOTOOLCHAIN) GOOS=windows GOARCH=amd64 go build $(GOFLAGS) -o bin/windows-amd64/tgserve.exe ./cmd/server/

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
	rm -rf bin/ tracegen-*.zip output/

# Install binaries to /usr/local/bin
install: build
	sudo cp bin/tgeval bin/tgrun bin/tgserve /usr/local/bin/

# Create distribution tar.gz files (more portable than zip)
package: release
	cd bin/linux-amd64 && tar -czf ../../tracegen-linux-amd64.tar.gz ./* && cd ../..
	cd bin/windows-amd64 && tar -czf ../../tracegen-windows-amd64.tar.gz ./* && cd ../..

# Show version info
version:
	@echo "CYMERTEK Trace Generator"
	@git describe --tags 2>/dev/null || echo "development"
