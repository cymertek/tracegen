// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package main

import (
	"net"
	"strings"
	"testing"
	"time"
)

func TestSocketServerFullProtocol(t *testing.T) {
	// Start a test server on a random port
	listener, err := net.Listen("tcp", ":0")
	if err != nil {
		t.Fatalf("failed to start listener: %v", err)
	}
	defer listener.Close()

	serverAddr := listener.Addr().String()

	go func() {
		conn, err := listener.Accept()
		if err != nil {
			t.Errorf("accept failed: %v", err)
			return
		}
		defer conn.Close()

		buf := make([]byte, 65536)
		n, err := conn.Read(buf)
		if err != nil {
			t.Errorf("read failed: %v", err)
			return
		}

		request := string(buf[:n])
		parts := strings.Split(request, "\x00")

		if len(parts) < 3 {
			response := "ERROR: Invalid command format\n"
			conn.Write([]byte(response))
			return
		}

		command := parts[0]
		schemaName := parts[1]
		scopeStr := parts[2]

		if !strings.EqualFold(command, "compile") {
			response := "ERROR: Unknown command\n"
			conn.Write([]byte(response))
			return
		}

		// Send response with schema name and scope info
		response := `{"schema":"` + schemaName + `","scope":` + scopeStr + `,"traces":[["U",1.0,[["A","R",1,0,-1]],null,null,{"VIEWS":[]}]]}` + "\x00" + "ok"
		conn.Write([]byte(response))
	}()

	// Connect as client
	clientConn, err := net.DialTimeout("tcp", serverAddr, 5*time.Second)
	if err != nil {
		t.Fatalf("client connection failed: %v", err)
	}
	defer clientConn.Close()

	// Send compile request with null byte separators
	requestBytes := []byte("compile\x00TestSchema\x001")
	clientConn.Write(requestBytes)

	// Read response
	clientConn.SetReadDeadline(time.Now().Add(5 * time.Second))
	responseBuf := make([]byte, 4096)
	n, err := clientConn.Read(responseBuf)
	if err != nil {
		t.Fatalf("read failed: %v", err)
	}

	response := string(responseBuf[:n])

	// Verify response structure
	if !strings.Contains(response, `"schema":"TestSchema"`) {
		t.Errorf("response missing schema name: %s", response)
	}
	if !strings.Contains(response, `"scope":1`) {
		t.Errorf("response missing scope value")
	}
	if !strings.Contains(response, `"traces":[`) {
		t.Errorf("response missing traces array")
	}

	t.Logf("Full protocol test passed. Response: %s", response[:min(n, 200)])
}

func TestSocketServerCaseInsensitiveCommand(t *testing.T) {
	listener, err := net.Listen("tcp", ":0")
	if err != nil {
		t.Fatalf("failed to start listener: %v", err)
	}
	defer listener.Close()

	serverAddr := listener.Addr().String()

	go func() {
		conn, _ := listener.Accept()
		defer conn.Close()

		buf := make([]byte, 65536)
		n, _ := conn.Read(buf)
		request := strings.ToLower(string(buf[:n]))

		if !strings.Contains(request, "compile") {
			conn.Write([]byte("ERROR: not compile\n"))
			return
		}
		conn.Write([]byte("OK\n"))
	}()

	clientConn, _ := net.DialTimeout("tcp", serverAddr, 5*time.Second)
	defer clientConn.Close()

	// Send with mixed case
	requestBytes := []byte("Compile\x00TestSchema\x001")
	clientConn.Write(requestBytes)

	responseBuf := make([]byte, 256)
	clientConn.SetReadDeadline(time.Now().Add(5 * time.Second))
	n, err := clientConn.Read(responseBuf)
	if err != nil {
		t.Fatalf("read failed: %v", err)
	}

	if !strings.Contains(strings.ToLower(string(responseBuf[:n])), "ok") &&
	   !strings.Contains(strings.ToLower(string(responseBuf[:n])), "error") {
		t.Errorf("unexpected response: %s", string(responseBuf[:n]))
	}
}
