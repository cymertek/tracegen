# tgfmt - MP Language Formatter

`tgfmt` is a standalone formatter for MP (Monterey Phoenix) behavioral event grammar files. It enforces consistent styling and can convert between comment styles.

## Installation

```bash
go install github.com/cymertek/tracegen/cmd/tgfmt@latest
```

Or build from source:

```bash
cd /path/to/tracegen
go build -o tgfmt ./cmd/tgfmt
```

## Commands

### `format` - Format MP Files

Format one or more `.mp` files according to style rules.

```bash
tgfmt format [file.mp ...] [flags]
```

**Flags:**

| Flag | Default | Description |
|------|---------|-------------|
| `--config=FILE` | `.tgfmt.yml` | Configuration file path |
| `--indent=N` | `4` | Indentation width in spaces |
| `--line-width=N` | `100` | Maximum line width |
| `--comment-style=mp\|c` | `mp` | Comment style: MP `(* ... *)` or C `/* ... */` |
| `-w` | off | Write to file instead of stdout |
| `-v, --verbose` | off | Show formatting details |

**Examples:**

```bash
# Format a single file to stdout
tgfmt format model.mp

# Format and write back to file
tgfmt format -w model.mp

# Format multiple files with custom indent
tgfmt format --indent=2 *.mp -w

# Use C-style comments instead of MP style
tgfmt format --comment-style=c model.mp
```

### `check` - Verify Formatting

Check if files are properly formatted without modifying them. Returns exit code 1 if formatting issues found.

```bash
tgfmt check [file.mp ...] [flags]
```

**Flags:**

| Flag | Default | Description |
|------|---------|-------------|
| `--config=FILE` | `.tgfmt.yml` | Configuration file path |
| `--exit-code` | off | Return non-zero exit code if files need formatting |
| `-v, --verbose` | off | Show which files need formatting |

**Examples:**

```bash
# Check all MP files in current directory
tgfmt check *.mp

# Use with CI/CD (fails on formatting issues)
tgfmt check --exit-code *.mp

# Verbose output showing which files need fixing
tgfmt check -v *.mp
```

## Configuration File

Create `.tgfmt.yml` in your project root:

```yaml
# tgfmt configuration file
indent_width: 4
line_width: 100
comment_style: "mp"  # or "c" for /* ... */ style
```

**Options:**

- `indent_width`: Number of spaces per indentation level (default: 4)
- `line_width`: Maximum line length before wrapping (default: 100)
- `comment_style`: Comment format - `"mp"` uses `(* ... *)`, `"c"` uses `/* ... */`

## Formatting Rules

### Comments

The formatter automatically converts comments based on the configured style:

**MP Style (`(* ... *)`):**
```mp
(* This is an MP comment *)
// Converts to (* // comment *)
```

**C Style (`/* ... */`):**
```c
/* This is a C comment */
// Converts to /* // comment */
```

### Indentation

Lines are indented based on context. The formatter uses heuristics to detect indentation levels:

```mp
SCHEMA example
ROOT Sender: (* send *);     # Level 0
COORDINATE                  # Level 0
    $x: send FROM Sender,   # Level 1 (4 spaces)
    $y: receive FROM Receiver
DO                          # Level 1
    ADD $x PRECEDES $y;     # Level 2 (8 spaces)
OD;                         # Level 1
END SCHEMA;                 # Level 0
```

### Line Width

Lines exceeding `line_width` are left as-is with a warning capability. Full reflow is not yet implemented but may be added in future versions.

## Integration with tracegen

While `tgfmt` is a standalone tool, it complements the main `tracegen` workflow:

```bash
# Format before linting
tgfmt format -w model.mp
tglint lint model.mp

# Use in pre-commit hook
#!/bin/bash
tgfmt check --exit-code *.mp || exit 1
tglint lint --severity=warning *.mp || exit 1
```

## Comparison with gofmt

Unlike Go's `gofmt`, which has a single canonical style, `tgfmt` offers configuration options to match team preferences. This is particularly useful for MP files where different projects may prefer different comment styles or indentation widths.
