// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

// Package store provides SQLite-backed trace storage with key-based deduplication.
// Traces are stored in a database where each unique trace gets one row, and a count
// field tracks how many times that trace pattern appeared during generation.
package store

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	_ "modernc.org/sqlite" // pure Go SQLite driver - no CGO needed
)

// TraceRecord represents a stored trace segment with deduplication count.
type TraceRecord struct {
	Key           string `json:"-"`
	MarkStatus    string `json:"mark_status"`
	Probability   float64 `json:"probability"`
	Events        any     `json:"events"` // []any of event tuples
	FollowsPairs  any     `json:"follows_pairs"`
	InPairs       any     `json:"in_pairs"`
	UDRs          any     `json:"udrs,omitempty"`
	Views         any     `json:"views,omitempty"`
	Count         int64   `json:"count"` // how many times this pattern appeared
}

// SQLiteStore manages trace storage with automatic deduplication via a local SQLite database.
type SQLiteStore struct {
	db          *sql.DB
	path        string
	closed      bool
	buffered    []bufferedRecord
	flushOnNext bool
}

// bufferedRecord holds one insert prepared for batching into a transaction.
type bufferedRecord struct {
	key           string
	markStatus    string
	probability   float64
	eventsJSON    string
	followsPairs  string
	inPairs       string
	udrsJSON      string
	viewsJSON     string
}

// NewSQLiteStore opens or creates a SQLite database in the given directory.
// The database file is named "trace_store.db" and lives next to user's working files.
func NewSQLiteStore(dir string) (*SQLiteStore, error) {
	if dir == "" || dir == "." {
		dir = "./"
	}

	dbPath := filepath.Join(dir, ".tgrun_cache", "trace_store.db")

	// Ensure cache directory exists
	cacheDir := filepath.Dir(dbPath)
	if err := os.MkdirAll(cacheDir, 0755); err != nil {
		return nil, fmt.Errorf("creating cache dir: %w", err)
	}

	db, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf("opening sqlite store: %w", err)
	}

	// Enable WAL mode for better concurrent performance and reduce drive hammering
	if _, err := db.Exec("PRAGMA journal_mode=WAL"); err != nil {
		db.Close()
		return nil, fmt.Errorf("setting WAL mode: %w", err)
	}

	store := &SQLiteStore{db: db, path: dbPath}

	// Create table if not exists (idempotent)
	if err := store.createTable(); err != nil {
		db.Close()
		return nil, fmt.Errorf("creating trace store table: %w", err)
	}

	return store, nil
}

// createTable initializes the traces table for deduplication.
func (s *SQLiteStore) createTable() error {
	query := `
	CREATE TABLE IF NOT EXISTS traces (
		trace_key TEXT PRIMARY KEY,
		mark_status TEXT NOT NULL DEFAULT 'U',
		probability REAL NOT NULL DEFAULT 0.0,
		events_json TEXT NOT NULL,
		follows_pairs_json TEXT NOT NULL DEFAULT '[]',
		in_pairs_json TEXT NOT NULL DEFAULT '[]',
		udrs_json TEXT NOT NULL DEFAULT '{}',
		views_json TEXT NOT NULL DEFAULT '[]',
		count INTEGER NOT NULL DEFAULT 1
	);`

	if _, err := s.db.Exec(query); err != nil {
		return fmt.Errorf("creating traces table: %w", err)
	}

	indexQuery := `CREATE INDEX IF NOT EXISTS idx_traces_count ON traces(count DESC);`
	if _, err := s.db.Exec(indexQuery); err != nil {
		return fmt.Errorf("creating index: %w", err)
	}

	return nil
}

// InsertOrIncrement buffers a new trace or increments the count for an existing one.
// Inserts are batched into transactions to prevent drive hammering.
func (s *SQLiteStore) InsertOrIncrement(key string, record TraceRecord) error {
	eventsJSON, err := json.Marshal(record.Events)
	if err != nil {
		return fmt.Errorf("marshaling events: %w", err)
	}

	followsPairsJSON, err := json.Marshal(record.FollowsPairs)
	if err != nil {
		return fmt.Errorf("marshaling follows_pairs: %w", err)
	}

	inPairsJSON, err := json.Marshal(record.InPairs)
	if err != nil {
		return fmt.Errorf("marshaling in_pairs: %w", err)
	}

	udrsJSON, _ := json.Marshal(record.UDRs)
	viewsJSON, _ := json.Marshal(record.Views)

	s.buffered = append(s.buffered, bufferedRecord{
		key:          key,
		markStatus:   record.MarkStatus,
		probability:  record.Probability,
		eventsJSON:   string(eventsJSON),
		followsPairs: string(followsPairsJSON),
		inPairs:      string(inPairsJSON),
		udrsJSON:     string(udrsJSON),
		viewsJSON:    string(viewsJSON),
	})

	// Auto-flush when buffer reaches 100 records to prevent drive hammering
	if len(s.buffered) >= 100 {
		return s.Flush()
	}

	s.flushOnNext = true
	return nil
}

// Flush commits all buffered records to SQLite in a single transaction.
func (s *SQLiteStore) Flush() error {
	if len(s.buffered) == 0 {
		s.flushOnNext = false
		return nil
	}

	tx, err := s.db.Begin()
	if err != nil {
		return fmt.Errorf("beginning transaction: %w", err)
	}

	stmt, err := tx.Prepare(`
		INSERT INTO traces (trace_key, mark_status, probability, events_json, follows_pairs_json, in_pairs_json, udrs_json, views_json, count)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)
		ON CONFLICT(trace_key) DO UPDATE SET count = count + 1
	`)
	if err != nil {
		tx.Rollback() //nolint:errcheck
		return fmt.Errorf("preparing statement: %w", err)
	}
	defer stmt.Close()

	for _, rec := range s.buffered {
		if _, err := stmt.Exec(rec.key, rec.markStatus, rec.probability, rec.eventsJSON, rec.followsPairs, rec.inPairs, rec.udrsJSON, rec.viewsJSON); err != nil {
			tx.Rollback() //nolint:errcheck
			return fmt.Errorf("executing insert: %w", err)
		}
	}

	if err := tx.Commit(); err != nil {
		tx.Rollback() //nolint:errcheck
		return fmt.Errorf("committing transaction: %w", err)
	}

	s.buffered = s.buffered[:0]
	s.flushOnNext = false
	return nil
}

// GetAllTraces retrieves all stored traces sorted by key (deterministic order).
func (s *SQLiteStore) GetAllTraces() ([]TraceRecord, error) {
	if err := s.Flush(); err != nil {
		return nil, fmt.Errorf("flushing before read: %w", err)
	}

	query := `SELECT trace_key, mark_status, probability, events_json, follows_pairs_json, in_pairs_json, udrs_json, views_json, count FROM traces ORDER BY trace_key`

	rows, err := s.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("querying traces: %w", err)
	}
	defer rows.Close()

	var records []TraceRecord
	for rows.Next() {
		var r TraceRecord
		var eventsJSON, followsPairsJSON, inPairsJSON, udrsJSON, viewsJSON string

		if err := rows.Scan(&r.Key, &r.MarkStatus, &r.Probability, &eventsJSON, &followsPairsJSON, &inPairsJSON, &udrsJSON, &viewsJSON, &r.Count); err != nil {
			return nil, fmt.Errorf("scanning trace row: %w", err)
		}

		if err := json.Unmarshal([]byte(eventsJSON), &r.Events); err != nil {
			return nil, fmt.Errorf("unmarshaling events for key %s: %w", r.Key, err)
		}
		if err := json.Unmarshal([]byte(followsPairsJSON), &r.FollowsPairs); err != nil {
			return nil, fmt.Errorf("unmarshaling follows_pairs for key %s: %w", r.Key, err)
		}
		if err := json.Unmarshal([]byte(inPairsJSON), &r.InPairs); err != nil {
			return nil, fmt.Errorf("unmarshaling in_pairs for key %s: %w", r.Key, err)
		}
		if err := json.Unmarshal([]byte(udrsJSON), &r.UDRs); err != nil {
			r.UDRs = map[string][]int{} // fallback empty
		}
		if err := json.Unmarshal([]byte(viewsJSON), &r.Views); err != nil {
			r.Views = []any{} // fallback empty
		}

		records = append(records, r)
	}

	return records, rows.Err()
}

// TotalTraces returns the total number of unique trace keys stored.
func (s *SQLiteStore) TotalTraces() (int64, error) {
	if err := s.Flush(); err != nil {
		return 0, fmt.Errorf("flushing before count: %w", err)
	}
	var count int64
	err := s.db.QueryRow("SELECT COUNT(*) FROM traces").Scan(&count)
	return count, err
}

// TotalInstances returns the sum of all counts (total trace instances before dedup).
func (s *SQLiteStore) TotalInstances() (int64, error) {
	if err := s.Flush(); err != nil {
		return 0, fmt.Errorf("flushing before count: %w", err)
	}
	var total int64
	err := s.db.QueryRow("SELECT SUM(count) FROM traces").Scan(&total)
	return total, err
}

// QueryAllTracesCursor returns a row cursor for streaming iteration over all stored traces.
// Caller must call rows.Close() when done iterating.
func (s *SQLiteStore) QueryAllTracesCursor() (*sql.Rows, error) {
	if s.flushOnNext || len(s.buffered) > 0 {
		if err := s.Flush(); err != nil {
			return nil, fmt.Errorf("flushing before cursor: %w", err)
		}
	}

	query := `SELECT trace_key, mark_status, probability, events_json, follows_pairs_json, in_pairs_json, udrs_json, views_json, count FROM traces ORDER BY trace_key`
	return s.db.Query(query)
}

// QueryCount returns the number of unique trace keys stored via a pure SQL query.
func (s *SQLiteStore) QueryCount() (int64, error) {
	if err := s.Flush(); err != nil {
		return 0, fmt.Errorf("flushing before count: %w", err)
	}
	var count int64
	err := s.db.QueryRow("SELECT COUNT(*) FROM traces").Scan(&count)
	return count, err
}

// Close shuts down the SQLite connection and cleans up WAL files.
func (s *SQLiteStore) Close() error {
	if s.closed {
		return nil
	}
	s.closed = true
	// Flush any remaining buffered records before closing
	if len(s.buffered) > 0 {
		s.Flush() //nolint:errcheck
	}
	return s.db.Close()
}

// ClearAll removes all traces from the store but keeps the database file.
func (s *SQLiteStore) ClearAll() error {
	if _, err := s.db.Exec("DELETE FROM traces"); err != nil {
		return err
	}
	s.buffered = s.buffered[:0] // clear any buffered records after delete
	return nil
}

// GenerateTraceKey creates a deterministic hash key for a trace based on its combined event sequence.
func GenerateTraceKey(events any) string {
	data, err := json.Marshal(events)
	if err != nil {
		return fmt.Sprintf("error:%v", err)
	}

	var h uint32 = 2166136261 // FNV offset basis
	for _, b := range data {
		h ^= uint32(b)
		h *= 16777619 // FNV prime
	}

	return fmt.Sprintf("%08x", h) + ":" + string(data[:min(len(data), 50)])
}
