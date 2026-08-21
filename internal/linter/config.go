// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package linter

import (
	"fmt"
	"os"
	"strings"
)

// DefaultConfig returns the default configuration with all rules enabled at their default severity.
func DefaultConfig() *Config {
	return &Config{
		Rules: make(map[string]RuleConfig),
	}
}

// LoadConfig reads and parses a .tglint.yml configuration file.
func LoadConfig(path string) (*Config, error) {
	config := DefaultConfig()

	data, err := os.ReadFile(path)
	if err != nil {
		return config, fmt.Errorf("config file not found or unreadable: %s", path)
	}

	content := strings.TrimSpace(string(data))
	if content == "" {
		return config, nil
	}

	// Parse simple YAML-like format (no external dependency)
	lines := strings.Split(content, "\n")
	currentRule := ""

	for _, line := range lines {
		trimmed := strings.TrimSpace(line)

		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			continue
		}

		// Parse rule section headers like "no-magic-numbers:"
		if strings.HasSuffix(trimmed, ":") && !strings.Contains(trimmed, " ") {
			ruleName := strings.TrimSuffix(trimmed, ":")
			currentRule = ruleName
			continue
		}

		// Parse key-value pairs
		parts := strings.SplitN(trimmed, ":", 2)
		if len(parts) == 2 && currentRule != "" {
			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])

			ruleCfg, exists := config.Rules[currentRule]
			if !exists {
				ruleCfg = RuleConfig{}
			}

			switch key {
			case "disabled":
				// Strip inline comments (text after #)
				if idx := strings.Index(value, "#"); idx != -1 {
					value = strings.TrimSpace(value[:idx])
				}
				ruleCfg.Disabled = strings.ToLower(value) == "true" || value == "1" || value == "yes"
			case "severity":
				value = strings.ToLower(value)
				if value == "error" || value == "warning" || value == "info" {
					ruleCfg.Severity = value
				}
			default:
				if ruleCfg.Options == nil {
					ruleCfg.Options = make(map[string]any)
				}
				ruleCfg.Options[key] = value
			}

			config.Rules[currentRule] = ruleCfg
		}
	}

	return config, nil
}

// GetRuleConfig returns the configuration for a specific rule, or empty config if not present.
func (c *Config) GetRuleConfig(ruleID string) RuleConfig {
	if cfg, exists := c.Rules[ruleID]; exists {
		return cfg
	}
	return RuleConfig{}
}

// IsRuleDisabled returns true if the specified rule is disabled in config.
func (c *Config) IsRuleDisabled(ruleID string) bool {
	cfg := c.GetRuleConfig(ruleID)
	return cfg.Disabled
}

// GetSeverityOverride returns a custom severity for a rule, or empty string if not configured.
func (c *Config) GetSeverityOverride(ruleID string) string {
	cfg := c.GetRuleConfig(ruleID)
	return cfg.Severity
}
