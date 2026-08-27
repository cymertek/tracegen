# tglint Quick Reference Guide

## Rule Numbers (A001-A010)

| Number | Rule ID | Description | Severity |
|--------|---------|-------------|----------|
| A001 | `no-magic-numbers` | Extract hardcoded numeric values into named constants | WARNING |
| A002 | `max-function-length` | Keep functions and blocks under reasonable length | WARNING |
| A003 | `no-dead-code` | Remove commented-out code blocks | INFO |
| A004 | `naming-conventions` | Use consistent naming style (camelCase/snake_case) | INFO |
| A005 | `missing-docs` | Add documentation comments for schemas and rules | INFO |
| A006 | `comment-style-consistency` | Use consistent comment styles (`/* */` or `(* *)`) | WARNING |
| A007 | `declaration-ordering` | Maintain SCHEMA → ROOT/RULE → COORDINATE → ATTRIBUTES order | WARNING |
| A008 | `duplicate-rule-names` | Prevent duplicate rule names within same schema | ERROR |
| A009 | `colon-spacing-in-root` | Ensure consistent spacing after colon in ROOT declarations | WARNING |
| A010 | `probability-annotation-formatting` | Validate probability annotations use consistent formatting | WARNING |

## Suppression Syntax

### Basic Usage
```mp
// Suppress by rule ID
ROOT MyRule: (* event *); // nolint:naming-conventions

// Suppress by rule number  
ENSURE x == 42; // nolint:A001

// Suppress multiple rules (comma-separated)
BUILD { ... }; // nolint:no-magic-numbers,naming-conventions,A001,A004

// Suppress all rules for next line only
// nolint
ROOT AnotherRule: (* event *); // All violations suppressed here
```

### With Descriptions
```mp
// Using dash separator
ENSURE x == 42; // Magic number - suppress this // nolint:A001 - test value for demo

// Using double-dash separator  
BUILD { ... }; // Suppress for brevity // nolint:max-function-length -- example code
```

## Configuration File (`.tglint.yml`)

### Disable Rules Globally
```yaml
rules:
  no-dead-code:
    disabled: true  # Don't flag comments as dead code anywhere
```

### Change Rule Severity
```yaml
rules:
  naming-conventions:
    severity: warning  # Upgrade from info to warning globally
```

## CLI Commands

### List All Rules
```bash
tglint list-rules
```

### Lint with Config File
```bash
tglint lint --config=.tglint.yml file.mp
```

### Filter by Specific Rules
```bash
# By rule number
tglint lint --rules=A001,A002 *.mp

# By rule ID  
tglint lint --rules=no-magic-numbers *.mp

# Mix of numbers and IDs
tglint lint --rules=A001,naming-conventions *.mp
```

### Set Minimum Severity
```bash
# Only show warnings and errors (hide info-level violations)
tglint lint --severity=warning file.mp
```

## Common Use Cases

### Suppress Magic Numbers in Test Data
```mp
// Test data with intentional magic numbers // nolint:no-magic-numbers,A001 - test values
TEST_DATA := {
    price := 42;     // nolint:A001 - test value, not production code
    quantity := 99;  // nolint:A001 - another test value
};
```

### Suppress Naming Conventions for Legacy Code
```mp
// Existing rule with mixed case naming // nolint:naming-conventions,A004 - legacy code
ROOT CustomerName: (* event *); // Mixed case name from original schema
```

### Block Suppression for Multiple Lines
```mp
// All rules suppressed for next block of code
// nolint
BUILD {
    ENSURE x == 1;   // Magic number (suppressed)
    ENSURE y == 2;   // Magic number (suppressed)  
    ROOT BadName: (* event *); // Naming convention (suppressed)
};
```

## Best Practices

1. **Use specific rule IDs** when possible, not bare `// nolint` (which suppresses everything)
2. **Add descriptions** with `-` or `--` to explain why suppression is needed
3. **Place suppressions on the same line** as the violation for clarity
4. **Don't overuse suppressions** - they should be exceptions, not rules
5. **Review suppressions regularly** - a suppressed rule might indicate code that needs fixing

## Troubleshooting

### Suppression Not Working?
- Check that you're using the correct rule ID or number (case-insensitive)
- Verify the suppression is on the same line as the violation, or on the previous/next line
- Make sure inline descriptions are properly formatted with `-` or `--` separators

### Config File Not Loading?
- Ensure file is named `.tglint.yml` and located in project root
- Check YAML syntax - no tabs allowed, use spaces for indentation
- Verify rule names match exactly (case-sensitive)

### Rule Still Showing After Disabling?
- Use `--severity=info` to see all violations including info-level ones
- Check that you're not accidentally overriding severity in config file
