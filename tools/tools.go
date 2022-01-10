//go:build tools
// +build tools

package tools

import (
	_ "github.com/golangci/golangci-lint/cmd/golangci-lint"
	_ "github.com/onsi/ginkgo/v2"
	_ "gotest.tools/gotestsum"
	_ "mvdan.cc/sh/v3/cmd/shfmt"
)
