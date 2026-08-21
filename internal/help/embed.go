// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package help provides embedded documentation for tgrun, including GPU setup guides and troubleshooting.
package help

import _ "embed"

//go:embed setup-gpu.md
var SetupGPU string

//go:embed troubleshooting.md
var Troubleshooting string

//go:embed architecture.md
var Architecture string

//go:embed quick-reference.md
var QuickReference string
