# tglint - MP Language Linter

`tglint` is a standalone linter for MP (Monterey Phoenix) behavioral event grammar files. It checks for common issues and enforces best practices through 5 built-in rules.

## Installation

```bash
go install github.com/cymertek/tracegen/cmd/tglint@latest
```

Or build from source:

```bash
cd /path/to/tracegen
go build -o tglint ./cmd/tglint
```

## Commands

### `lint` - Run Linter

Analyze one or more `.mp` files for violations.

```bash
tglint lint [file.mp ...] [flags]
```

**Flags:**

| Flag | Default | Description |
|------|---------|-------------|
| `--rules=LIST` | all | Comma-separated rule IDs to check |
| `--severity=LEVEL` | `info` | Minimum severity: `error`, `warning`, `info` |
| `-v, --verbose` | off | Show detailed rule descriptions |
| `-q, --quiet` | off | Only show violations (no summary) |

**Examples:**

```bash
# Check all rules on a file
tglint lint model.mp

# Run specific rules only
tglint lint --rules=no-magic-numbers,max-function-length model.mp

# Only show errors and warnings (not info)
tglint lint --severity=warning model.mp

# Quiet mode for scripting/CI
tglint lint -q *.mp

# Verbose output with rule descriptions
tglint lint -v model.mp
```

### `list-rules` - Show Available Rules

Display all available linting rules with descriptions.

```bash
tglint list-rules
```

**Output:**
```
Available linting rules:
--------------------------------------------------------------------------------

no-magic-numbers
  Severity: WARNING
  Description: Extract hardcoded numeric values into named constants for clarity and maintainability.

max-function-length
  Severity: WARNING
  Description: Keep functions and blocks under a reasonable length for readability.

... (5 rules total)
```

## Built-in Rules

### 1. `no-magic-numbers` ⚠️ Warning

Detects hardcoded numeric literals that should be extracted into named constants.

**Why it matters:** Magic numbers reduce code readability and make maintenance harder. Named constants document intent.

**Example violation:**
```mp
ENSURE FOREACH $x: send FROM Sender
    (#send.count == 5);  // ❌ Magic number 5
```

**Fix:**
```mp
CONSTANT MaxSendCount = 5;

ENSURE FOREACH $x: send FROM Sender
    (#send.count == MaxSendCount);  // ✅ Named constant
```

### 2. `max-function-length` ⚠️ Warning

Warns when functions or code blocks exceed 100 lines.

**Why it matters:** Long functions are hard to understand, test, and maintain. Breaking them into smaller units improves readability.

**Example violation:**
```mp
SCHEMA long_model
ROOT Complex: (* very_long_sequence_of_events ... *);
// Block exceeds 100 lines ❌
END SCHEMA;
```

### 3. `no-dead-code` ℹ️ Info

Detects commented-out code that may no longer be needed.

**Why it matters:** Commented-out code becomes stale and misleading. Use version control (git) instead.

**Example violation:**
```mp
// send_message();  // ❌ Commented-out function call
```

**Fix:** Remove the comment or use git to track history:
```bash
git log -p -- model.mp  # View historical changes
```

### 4. `naming-conventions` ℹ️ Info

Enforces consistent naming style for events and variables.

**Why it matters:** Consistent naming improves readability and reduces cognitive load when reading MP models.

**Example violation:**
```mp
ROOT Sender: (* sendMessage *);  // ❌ Mixed case
```

**Fix:** Use snake_case or camelCase consistently:
```mp
ROOT Sender: (* send_message *);  // ✅ snake_case
# OR
ROOT Sender: (* sendMessage *);   // ✅ camelCase (but be consistent)
```

### 5. `missing-docs` ℹ️ Info

Requires documentation comments before SCHEMA declarations.

**Why it matters:** Documentation helps other developers understand the purpose of complex models.

**Example violation:**
```mp
SCHEMA undocumented;  // ❌ No comment explaining purpose
```

**Fix:**
```mp
/*
 * This schema models a simple client-server communication pattern.
 * It demonstrates COORDINATE operations between Sender and Receiver roots.
 */
SCHEMA documented_model;  // ✅ Documented
```

## Severity Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| `error` | Critical issues that should be fixed | Breaking changes, syntax errors |
| `warning` | Important issues that should be addressed | Code quality, maintainability |
| `info` | Informational suggestions | Best practices, style consistency |

Filter by severity with `--severity`:

```bash
# Only show errors
tglint lint --severity=error model.mp

# Show warnings and errors (default)
tglint lint --severity=warning model.mp

# Show all including info (default)
tglint lint --severity=info model.mp
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Lint MP Files
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install tglint
        run: go install github.com/cymertek/tracegen/cmd/tglint@latest
      
      - name: Run linter
        run: tglint lint --severity=warning --exit-code **/*.mp
```

### Pre-commit Hook

Add to `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: tgfmt
        name: tgfmt
        entry: tgfmt format -w
        language: golang
        types: [text]
        files: '\.mp$'
      
      - id: tglint
        name: tglint
        entry: tglint lint --severity=warning
        language: golang
        types: [text]
        files: '\.mp$'
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | No violations found (or all violations below severity threshold) |
| `1` | Violations found at or above configured severity level |
| `2` | Error reading input files or configuration |

Use `--exit-code` flag with `check` command to fail CI builds on formatting issues.

## Custom Rules

To add custom linting rules, extend the `Rule` struct in `internal/linter/rules.go`:

```go
var MyCustomRule = Rule{
    ID:          "my-custom-rule",
    Description: "Check for something specific to your project",
    Severity:    "warning",
    Check:       checkMyCustomRule,
}

func checkMyCustomRule(content string, filename string) []Violation {
    // Your checking logic here
    return violations
}
```

Then register it in `AllRules()`:

```go
func AllRules() []Rule {
    return []Rule{
        Rule5NoMagicNumbers,
        Rule6MaxFunctionLength,
        Rule7NoDeadCode,
        Rule8NamingConventions,
        Rule9MissingDocs,
        MyCustomRule,  // Add your custom rule here
    }
}
```

## Comparison with golangci-lint

While `golangci-lint` is a comprehensive Go linter, `tglint` is specialized for MP behavioral event grammar. It understands MP-specific constructs like:
- SCHEMA/ROOT declarations
- COORDINATE blocks
- ENSURE constraints
- Event patterns (`(* ... *)`, `{+ ... +}`)

This makes it more relevant and actionable for MP model development than a generic linter.
