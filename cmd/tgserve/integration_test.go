// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package main

import (
	"bytes"
	"fmt"
	"net"
	"strings"
	"testing"
	"time"
)

func TestSocketServerIntegration(t *testing.T) {
	// Start a test server on a random port
	listener, err := net.Listen("tcp", ":0")
	if err != nil {
		t.Fatalf("failed to start listener: %v", err)
	}
	defer listener.Close()

	serverAddr := listener.Addr().String()
	fmt.Printf("Integration test server listening on %s\n", serverAddr)

	// Start server goroutine (simulating what main does)
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
		fmt.Printf("Received request: %q\n", strings.ReplaceAll(request, "\x00", "\\x00"))

		// Parse the command (same logic as main.go)
		parts := strings.Split(request, "\x00")

		if len(parts) < 3 {
			response := fmt.Sprintf("ERROR: Invalid command format. Expected: compile\\0schema_name\\0scope\n")
			conn.Write([]byte(response))
			return
		}

		command := parts[0]
		schemaName := parts[1]
		scopeStr := parts[2]

		if !strings.EqualFold(command, "compile") {
			response := fmt.Sprintf("ERROR: Unknown command %q. Expected 'compile'\n", command)
			conn.Write([]byte(response))
			return
		}

		fmt.Printf("Compiling schema %q with scope %s\n", schemaName, scopeStr)

		// Send a successful response (in real server, this would be JSON traces)
		response := fmt.Sprintf(`{"status":"success","schema":"%s","scope":%s}`+"\x00", schemaName, scopeStr)
		conn.Write([]byte(response))
	}()

	// Connect as client with proper Gryphon protocol format
	clientConn, err := net.DialTimeout("tcp", serverAddr, 5*time.Second)
	if err != nil {
		t.Fatalf("client connection failed: %v", err)
	}
	defer clientConn.Close()

	// Build request with null byte separators (Gryphon protocol format)
	requestBytes := []byte{
		'c', 'o', 'm', 'p', 'i', 'l', 'e', // "compile" command
		0,                                    // null byte separator
		'S', 'c', 'h', 'e', 'm', 'a', 'N', 'a', 'm', 'e', // schema name
		0,                                    // null byte separator
		'1',                                  // scope = 1
	}

	fmt.Printf("Sending request: %q\n", strings.ReplaceAll(string(requestBytes), "\x00", "\\x00"))
	_, err = clientConn.Write(requestBytes)
	if err != nil {
		t.Fatalf("write failed: %v", err)
	}

	// Read response with timeout
	clientConn.SetReadDeadline(time.Now().Add(5 * time.Second))
	responseBuf := make([]byte, 4096)
	n, err := clientConn.Read(responseBuf)
	if err != nil {
		t.Fatalf("read failed: %v", err)
	}

	response := string(responseBuf[:n])
	fmt.Printf("Response (%d bytes): %s\n", n, response)

	// Verify response contains expected data
	if !strings.Contains(response, `"schema":"SchemaName"`) {
		t.Errorf("response missing schema name: %s", response)
	}

	if !strings.Contains(response, `"scope":1`) {
		t.Errorf("response missing scope value: %s", response)
	}

	fmt.Println("Integration test passed!")
}

func TestSocketServerInvalidProtocol(t *testing.T) {
	// Test that the server correctly handles malformed requests

	listener, err := net.Listen("tcp", ":0")
	if err != nil {
		t.Fatalf("failed to start listener: %v", err)
	}
	defer listener.Close()

	serverAddr := listener.Addr().String()

	go func() {
		conn, err := listener.Accept()
		if err != nil {
			return
		}
		defer conn.Close()

		buf := make([]byte, 65536)
		n, _ := conn.Read(buf)
		request := string(buf[:n])

		parts := strings.Split(request, "\x00")

		if len(parts) < 3 {
			response := "ERROR: Invalid command format. Expected: compile\\0schema_name\\0scope\n"
			conn.Write([]byte(response))
			return
		}

		command := parts[0]
		if !strings.EqualFold(command, "compile") {
			response := fmt.Sprintf("ERROR: Unknown command %q. Expected 'compile'\n", command)
			conn.Write([]byte(response))
			return
		}

		// Should not reach here for invalid requests
		t.Error("should have returned error before this point")
	}()

	clientConn, err := net.DialTimeout("tcp", serverAddr, 5*time.Second)
	if err != nil {
		t.Fatalf("client connection failed: %v", err)
	}
	defer clientConn.Close()

	// Send invalid request (missing null byte separator)
	invalidRequest := "compileSchemaName1" // No null bytes
	clientConn.Write([]byte(invalidRequest))

	responseBuf := make([]byte, 4096)
	clientConn.SetReadDeadline(time.Now().Add(5 * time.Second))
	n, err := clientConn.Read(responseBuf)
	if err != nil {
		t.Fatalf("read failed: %v", err)
	}

	response := string(responseBuf[:n])
	fmt.Printf("Invalid request response: %s\n", response)

	if !strings.Contains(strings.ToLower(response), "error") {
		t.Errorf("expected error response for invalid protocol, got: %s", response)
	}
}

func TestSocketServerMultipleConnections(t *testing.T) {
	// Test that the server can handle multiple sequential connections

	listener, err := net.Listen("tcp", ":0")
	if err != nil {
		t.Fatalf("failed to start listener: %v", err)
	}
	defer listener.Close()

	serverAddr := listener.Addr().String()

	connectionCount := 3
	receivedRequests := make(chan string, connectionCount)

	go func() {
		for i := 0; i < connectionCount; i++ {
			conn, err := listener.Accept()
			if err != nil {
				t.Errorf("accept %d failed: %v", i+1, err)
				return
			}

			go func(c net.Conn, idx int) {
				defer c.Close()
				buf := make([]byte, 65536)
				n, _ := c.Read(buf)
				request := string(buf[:n])
				receivedRequests <- request

				response := fmt.Sprintf("OK connection_%d", idx+1)
				c.Write([]byte(response))
			}(conn, i)
		}
	}()

	// Connect multiple times
	for i := 0; i < connectionCount; i++ {
		clientConn, err := net.DialTimeout("tcp", serverAddr, 5*time.Second)
		if err != nil {
			t.Fatalf("client %d connection failed: %v", i+1, err)
		}

		request := fmt.Sprintf("compile\x00TestSchema_%d\x00%d", i+1, i+1)
		clientConn.Write([]byte(request))

		responseBuf := make([]byte, 4096)
		clientConn.SetReadDeadline(time.Now().Add(5 * time.Second))
		n, err := clientConn.Read(responseBuf)
		if err != nil {
			t.Fatalf("client %d read failed: %v", i+1, err)
		}

		response := string(responseBuf[:n])
		fmt.Printf("Client %d response: %s\n", i+1, response)

		expectedResponse := fmt.Sprintf("OK connection_%d", i+1)
		if response != expectedResponse {
			t.Errorf("client %d: expected %q, got %q", i+1, expectedResponse, response)
		}

		clientConn.Close()
	}

	// Verify all requests were received
	close(receivedRequests)
	var received []string
	for req := range receivedRequests {
		received = append(received, req)
	}

	if len(received) != connectionCount {
		t.Errorf("expected %d requests, got %d", connectionCount, len(received))
	}

	for i, req := range received {
		expectedSchema := fmt.Sprintf("compile\x00TestSchema_%d\x00%d", i+1, i+1)
		if !bytes.Equal([]byte(req), []byte(expectedSchema)) {
			t.Errorf("request %d: expected %q, got %q", i+1, expectedSchema, req)
		}
	}

	fmt.Printf("Multiple connections test passed! (%d connections handled)\n", connectionCount)
}
