// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package formatter implements MP language formatting with configuration support.
package formatter

import (
	"fmt"
	"os"
	"strings"
)

// Config holds all formatting configuration options.
type Config struct {
	IndentWidth   int    `yaml:"indent_width"`
	LineWidth     int    `yaml:"line_width"`
	CommentStyle  string `yaml:"comment_style"` // "mp" or "c"
	MaxBlankLines int    `yaml:"max_blank_lines"`
}

// DefaultConfig returns a Config with sensible defaults.
func DefaultConfig() *Config {
	return &Config{
		IndentWidth:   4,
		LineWidth:     100,
		CommentStyle:  "mp", // (* ... *) style by default
		MaxBlankLines: 2,    // Collapse runs of >2 blank lines to 2
	}
}

// LoadConfig reads configuration from a YAML file. Falls back to defaults if file not found.
func LoadConfig(path string) *Config {
	config := DefaultConfig()

	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			return config // Use defaults if config file doesn't exist
		}
		fmt.Fprintf(os.Stderr, "Warning: could not read config %s: %v\n", path, err)
		return config
	}

	// Simple YAML parsing (no external dependency for now)
	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.SplitN(line, ":", 2)
		if len(parts) != 2 {
			continue
		}

		key := strings.TrimSpace(parts[0])
		value := strings.TrimSpace(parts[1])

		switch key {
		case "indent_width":
			if _, err := fmt.Sscanf(value, "%d", &config.IndentWidth); err != nil {
				fmt.Fprintf(os.Stderr, "Warning: invalid indent_width in config: %v\n", err)
			}
		case "line_width":
			if _, err := fmt.Sscanf(value, "%d", &config.LineWidth); err != nil {
				fmt.Fprintf(os.Stderr, "Warning: invalid line_width in config: %v\n", err)
			}
		case "comment_style":
			config.CommentStyle = value
		case "max_blank_lines":
			if _, err := fmt.Sscanf(value, "%d", &config.MaxBlankLines); err != nil {
				fmt.Fprintf(os.Stderr, "Warning: invalid max_blank_lines in config: %v\n", err)
			}
		}
	}

	return config
}

// SaveConfig writes configuration to a YAML file.
func (c *Config) SaveConfig(path string) error {
	content := fmt.Sprintf(`# tgfmt configuration file
# See documentation for all options

indent_width: %d
line_width: %d
comment_style: "%s"
`, c.IndentWidth, c.LineWidth, c.CommentStyle)

	return os.WriteFile(path, []byte(content), 0644)
}
