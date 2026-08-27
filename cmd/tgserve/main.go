// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package main implements the Gryphon-compatible socket server for trace generation.
package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"strings"
	"sync"
	"syscall"

	"github.com/cymertek/tracegen/internal/generator"
	"github.com/cymertek/tracegen/internal/parser"
)

const version = "1.0.0"

// Server represents the Gryphon-compatible socket server.
type Server struct {
	addr     string
	listener net.Listener
	mu       sync.Mutex
	conns    map[net.Conn]bool
}

// NewServer creates a new socket server instance.
func NewServer(addr string) *Server {
	return &Server{
		addr:  addr,
		conns: make(map[net.Conn]bool),
	}
}

// Start begins listening for connections.
func (s *Server) Start() error {
	var err error
	s.listener, err = net.Listen("tcp", s.addr)
	if err != nil {
		return fmt.Errorf("failed to start server on %s: %w", s.addr, err)
	}

	log.Printf("[INFO] Socket server listening on %s", s.addr)
	log.Printf("[INFO] Version: %s", version)

	// Handle graceful shutdown
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigCh
		log.Println("[INFO] Received shutdown signal")
		s.Stop()
		os.Exit(0)
	}()

	// Accept connections in a loop
	for {
		conn, err := s.listener.Accept()
		if err != nil {
			log.Printf("[ERROR] Failed to accept connection: %v", err)
			continue
		}

		s.mu.Lock()
		s.conns[conn] = true
		s.mu.Unlock()

		go s.handleConnection(conn)
	}
}

// Stop gracefully shuts down the server.
func (s *Server) Stop() {
	log.Println("[INFO] Stopping socket server...")

	s.mu.Lock()
	defer s.mu.Unlock()

	for conn := range s.conns {
		conn.Close()
		delete(s.conns, conn)
	}

	if s.listener != nil {
		s.listener.Close()
	}

	log.Println("[INFO] Server stopped")
}

// handleConnection processes a single client connection.
func (s *Server) handleConnection(conn net.Conn) {
	defer func() {
		conn.Close()
		s.mu.Lock()
		delete(s.conns, conn)
		s.mu.Unlock()
	}()

	log.Printf("[INFO] New connection from %s", conn.RemoteAddr())

	buf := make([]byte, 65536)
	n, err := conn.Read(buf)
	if err != nil {
		log.Printf("[ERROR] Failed to read from %s: %v", conn.RemoteAddr(), err)
		return
	}

	request := string(buf[:n])
	log.Printf("[DEBUG] Received request: %q", request)

	// Parse the command (format: "compile\0schema_name\0scope\0compressed_mp_code")
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

	log.Printf("[INFO] Received compile request for schema %q with scope %s", schemaName, scopeStr)

	// Parse scope (default to 1 if not provided or invalid)
	scope := 1
	if len(parts) > 3 && parts[3] != "" {
		fmt.Sscanf(parts[3], "%d", &scope)
	}

	log.Printf("[INFO] Compiling schema %q with scope %d", schemaName, scope)

	// Generate traces (using CPU backend for now)
	traces, err := generateTracesCPU(schemaName, []byte(request), int64(scope))
	if err != nil {
		response := fmt.Sprintf("ERROR: Trace generation failed: %v\n", err)
		conn.Write([]byte(response))
		return
	}

	// Format response as JSON
	jsonOutput, err := generator.MarshalToJSON(traces)
	if err != nil {
		response := fmt.Sprintf("ERROR: Failed to format traces: %v\n", err)
		conn.Write([]byte(response))
		return
	}

	// Send response back to client
	log.Printf("[INFO] Sending %d trace segments to %s", len(traces), conn.RemoteAddr())
	_, err = conn.Write([]byte(jsonOutput + "\n"))
	if err != nil {
		log.Printf("[ERROR] Failed to send response to %s: %v", conn.RemoteAddr(), err)
		return
	}

	log.Printf("[INFO] Response sent successfully")
}

// generateTracesCPU generates traces using the CPU backend.
func generateTracesCPU(schemaName string, mpCode []byte, scope int64) ([]generator.TraceSegment, error) {
	// Parse MP code into AST
	lexer := parser.NewLexer(string(mpCode))
	tokens, err := lexer.Tokenize()
	if err != nil {
		return nil, fmt.Errorf("lexing failed: %w", err)
	}

	p := parser.NewParser(tokens)
	schemaNode, err := p.Parse()
	if err != nil {
		return nil, fmt.Errorf("parsing failed: %w", err)
	}

	log.Printf("[INFO] Parsed schema %q with %d rules and %d coordinates",
		schemaNode.Name, len(schemaNode.Rules), len(schemaNode.Coordinates))

	// Generate traces using CPU backend
	gen := generator.NewCPUGenerator(int64(scope))
	traces, err := gen.GenerateTraces(schemaNode, int(scope))
	if err != nil {
		return nil, fmt.Errorf("trace generation failed: %w", err)
	}

	return traces, nil
}

func main() {
	var (
		port     int
		addr     string
		showHelp bool
		showVer  bool
	)

	flag.IntVar(&port, "p", 9876, "Port to listen on")
	flag.StringVar(&addr, "a", "", "Address to bind (default: all interfaces)")
	flag.BoolVar(&showHelp, "h", false, "Show help")
	flag.BoolVar(&showVer, "v", false, "Show version")

	flag.Parse()

	if showVer {
		fmt.Printf("tgserve - Gryphon-compatible socket server v%s\n", version)
		os.Exit(0)
	}

	if showHelp || flag.NArg() > 0 {
		printUsage()
		os.Exit(0)
	}

	// Build listen address
	listenAddr := fmt.Sprintf(":%d", port)
	if addr != "" {
		listenAddr = fmt.Sprintf("%s:%d", addr, port)
	}

	server := NewServer(listenAddr)
	if err := server.Start(); err != nil {
		log.Fatalf("[FATAL] %v", err)
	}
}

func printUsage() {
	fmt.Println(`tgserve - Gryphon-compatible socket server for trace generation

Usage:
  tgserve [flags]

Flags:
  -p int      Port to listen on (default: 9876)
  -a string   Address to bind (e.g., "127.0.0.1")
  -h          Show this help message
  -v          Show version information

Protocol:
  The server accepts Gryphon-compatible compile commands in the format:
    compile <schema_name>\0<scope>\0<lzma_compressed_mp_code>

  Response format:
    JSON array of trace segments with log text appended after null byte

Example:
  tgserve -p 9876
  tgserve -a 127.0.0.1 -p 9877`)
}

