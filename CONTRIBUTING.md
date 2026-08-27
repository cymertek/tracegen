# Contributing to CYMERTEK CUDA Trace Generator

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## Development Setup

### Prerequisites

- Go 1.21 or later
- CUDA Toolkit (optional, for GPU-related development)
- Git

### Clone and Build

```bash
git clone https://github.com/cymertek/tgrun.git
cd tgrun
go build ./cmd/tgrun
./tgrun --version
```

### Run Tests

```bash
# Run all tests
go test ./...

# Run with coverage
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out -o coverage.html

# Run benchmarks
go test -bench=. ./internal/executor/
```

## Project Structure

```
tgrun/
├── cmd/
│   └── tgrun/          # CLI entry point
│       ├── main.go        # Command routing and flag parsing
│       └── run.go         # 'run' command implementation
├── internal/
│   ├── parser/            # MP language parser
│   │   ├── lexer.go      # Tokenizer
│   │   ├── grammar.go    # Grammar rules and AST nodes
│   │   └── parser.go     # Recursive descent parser
│   ├── model/             # Program representation
│   │   ├── types.go      # Core types (Event, Rule, Schema)
│   │   ├── marshal.go    # Marshal to .mp text format
│   │   └── unmarshal.go  # Unmarshal from .mp text format
│   ├── generator/         # Code generation backends
│   │   ├── cpu.go        # CPU reference implementation
│   │   └── cuda.go       # CUDA kernel generation logic
│   ├── executor/          # Trace generation engine
│   │   ├── engine.go     # Core trace generation algorithm
│   │   ├── relations.go  # Relation tracking (PRECEDES, IN)
│   │   └── attributes.go # Attribute management
│   └── output/            # Output formatters
│       ├── json.go       # JSON trace format
│       └── nvcc.go       # CUDA source code generation
├── examples/              # Example .mp files for testing
├── docs/                  # Documentation (this file)
└── scripts/               # Build and benchmark scripts
```

## Code Style Guidelines

### Go Conventions

Follow standard Go formatting and naming conventions:

- Use `gofmt` for formatting (run `gofmt -w .` before committing)
- Follow [Effective Go](https://go.dev/doc/effective_go) guidelines
- One exported concept per file when possible
- Keep files under 300 lines; extract helpers if longer

### Naming Conventions

```go
// Variables and functions: camelCase
func getUserById(id string) (*User, error) { ... }

// Types: PascalCase
type EventProducer interface { ... }

// Constants: UPPER_SNAKE_CASE
const MaxScope = 10

// Private members: lowercase with underscore prefix
var internalCache map[string]interface{}

// Files: kebab-case for modules, PascalCase for types
lexer.go, parser.go, event_producer.go
```

### Comments and Documentation

- Document all exported functions, types, and constants
- Use godoc-style comments (one line per sentence, no markdown formatting)
- Include examples in documentation where helpful

```go
// ParseMPFile reads and validates an MP behavioral event grammar file.
//
// The parser supports all features from MP v4.0 specification including:
//   - Event grammar rules with sequence, iteration, and set patterns
//   - Composition operations (COORDINATE, SHARE)
//   - ENSURE constraints with navigation directions
//   - Probability annotations for stochastic trace generation
//
// Example usage:
//
//	parser := parser.New()
//	program, err := parser.ParseMPFile("example.mp")
//	if err != nil {
//	    log.Fatalf("parse error: %v", err)
//	}
func ParseMPFile(path string) (*model.Program, error) { ... }
```

### Error Handling

- Use typed errors with context (wrap lower-level errors)
- Never swallow errors silently; log or return them
- Distinguish between client errors (bad input) and server errors (internal failures)

```go
// Good: Typed error with context
if err != nil {
    return nil, fmt.Errorf("failed to parse MP file %q: %w", path, err)
}

// Bad: Swallowing errors
if err != nil {
    log.Println(err)  // Don't do this
}
```

## Testing Standards

### Unit Tests

Write tests for all new functionality. Use table-driven tests where appropriate:

```go
func TestParseSequencePattern(t *testing.T) {
    tests := []struct{
        name     string
        input    string
        expected []string
    }{
        {"single event", "send", []string{"send"}},
        {"two events", "(send receive)", []string{"send", "receive"}},
        {"nested sequence", "((a b) c)", []string{"a", "b", "c"}},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Test implementation...
        })
    }
}
```

### Integration Tests

Test end-to-end workflows with example MP files:

```go
func TestGenerateTracesForExample01(t *testing.T) {
    mpFile := "examples/Example01_simple_message_flow.mp"
    
    // Parse and generate traces
    program, err := parser.ParseMPFile(mpFile)
    if err != nil {
        t.Fatalf("parse error: %v", err)
    }
    
    generator := generator.NewCPUGenerator()
    traces, err := generator.Generate(program, 1)
    if err != nil {
        t.Fatalf("generation error: %v", err)
    }
    
    // Validate output matches expected format
    if len(traces) == 0 {
        t.Fatal("expected at least one trace")
    }
}
```

### Benchmark Tests

Include benchmarks for performance-sensitive code:

```go
func BenchmarkGenerateTraces(b *testing.B) {
    program := loadTestProgram()
    generator := generator.NewCPUGenerator()
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, err := generator.Generate(program, 2)
        if err != nil {
            b.Fatal(err)
        }
    }
}
```

## Pull Request Process

### Before Submitting

1. **Run all tests**: `go test ./...` must pass
2. **Check formatting**: `gofmt -l .` should return no output
3. **Update documentation**: Add godoc comments for new exported symbols
4. **Add tests**: New functionality requires new tests
5. **Run benchmarks**: Ensure performance hasn't regressed

### PR Description Template

```markdown
## Summary
Brief description of changes and motivation.

## Related Issues
Closes #123 (if applicable)

## Changes
- Added support for `FILL_EMPTY_NEST` composition operation
- Fixed parser bug with nested iteration scopes
- Updated CUDA kernel launch configuration for large scopes

## Testing
- [ ] All existing tests pass
- [ ] New tests added for changed functionality
- [ ] Benchmarks show no regression (or improvement)
- [ ] Documentation updated

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-reviewed the diff before submitting
- [ ] Linked related issues in PR description
```

### Review Process

1. **Automated checks**: CI runs tests, benchmarks, and linting
2. **Code review**: At least one maintainer reviews the changes
3. **Merge criteria**:
   - All CI checks pass
   - No unresolved review comments
   - Approved by at least one maintainer

## Development Workflow

### Feature Branches

Create feature branches from `main`:

```bash
git checkout main
git pull origin main
git checkout -b feature/add-new-parser-support
# Make changes, commit, push
git push origin feature/add-new-parser-support
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/) format:

```
feat(parser): add support for FILL_EMPTY_NEST composition

Add parser rules and AST nodes for the FILL_EMPTY_NEST operation,
which fills empty nest structures with default events.

Closes #45
```

### Releasing

1. Update version in `cmd/tgrun/main.go`
2. Tag release: `git tag -a v1.0.0 -m "Release 1.0.0"`
3. Push tags: `git push origin --tags`
4. Create GitHub release with changelog

## Releasing and Distribution

### RPM Package Building

The project supports building RPM packages for Fedora, RHEL, CentOS, and compatible distributions.

#### Build Process

```bash
# 1. Install build dependencies
make install-deps

# 2. Build binaries and generate RPM package
make rpm-build

# 3. Install the RPM (requires sudo)
sudo make rpm-install
```

#### Package Contents

The RPM installs:
- `/usr/local/bin/tgrun` — Trace generator with GPU support
- `/usr/local/bin/tgfmt` — MP file formatter
- `/usr/local/bin/tglint` — MP language linter
- `/usr/local/bin/tgserve` — Gryphon socket server
- `/usr/share/doc/gnu-trace-generator/` — Documentation

#### Customization

Edit `gnu-trace-generator.spec` to:
- Change version numbers (`Version:` and `Release:`)
- Add custom dependencies (`Requires:` section)
- Modify install paths
- Update package metadata (summary, description, license)

### Distribution Options

1. **Direct RPM**: Share the built `.rpm` file from `~/rpmbuild/RPMS/x86_64/`
2. **Package Repository**: Host RPMs in a local or remote yum/dnf repository
3. **GitHub Releases**: Attach signed RPMs to GitHub release assets

## Reporting Issues

Use GitHub Issues for bug reports and feature requests. Include:

- **For bugs**: MP file that triggers the issue, expected vs actual behavior
- **For features**: Use case description, example MP syntax (if applicable)
- **Environment details**: OS, Go version, CUDA toolkit version (if GPU-related)

## License

By contributing, you agree that your contributions will be licensed under the project's MIT license. See [LICENSE](LICENSE) for details.
