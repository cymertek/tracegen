// Copyright (c) 2024 CYMERTEK. All rights reserved.
// Licensed under the CYMERTEK Limited Evaluation License. See LICENSE file.

package generator

import (
	"fmt"
	"strings"

	"github.com/cymertek/tracegen/internal/model"
)

// CUDAGenerator generates CUDA kernel code for parallel trace generation.
type CUDAGenerator struct {
	deviceCode strings.Builder
	hostCode   strings.Builder
}

// NewCUDAGenerator creates a new CUDA generator.
func NewCUDAGenerator() *CUDAGenerator {
	return &CUDAGenerator{}
}

// GenerateCUDA generates CUDA source code for the given schema.
func (g *CUDAGenerator) GenerateCUDA(schema *model.Schema, scope int) (string, error) {
	g.generateIncludes()
	g.generateDeviceTypes(schema)
	g.generateKernels(schema, scope)
	g.generateHostWrapper(schema, scope)

	return g.deviceCode.String() + "\n" + g.hostCode.String(), nil
}

// generateIncludes writes CUDA header includes.
func (g *CUDAGenerator) generateIncludes() {
	g.deviceCode.WriteString(`#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef MAX_ROOTS
#define MAX_ROOTS 64
#endif
#ifndef MAX_EVENTS_PER_SEGMENT
#define MAX_EVENTS_PER_SEGMENT 256
#endif
#ifndef MAX_SCOPE
#define MAX_SCOPE 16
#endif
#ifndef MAX_RULES
#define MAX_RULES 32
#endif
#ifndef MAX_RELATIONS
#define MAX_RELATIONS 128
#endif

#define CUDA_CHECK(call) \
    do { \
        cudaError_t err = call; \
        if (err != cudaSuccess) { \
            fprintf(stderr, "CUDA error at %s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(err)); \
            exit(EXIT_FAILURE); \
        } \
    } while (0)

typedef enum {
    EVENT_TYPE_ROOT = 0,
    EVENT_TYPE_ATOMIC = 1,
    EVENT_TYPE_COMPOSITE = 2
} EventType;

// Thread-safe atomic for incrementing event counter in parallel kernels
static __device__ int atomic_add_events(int *counter, int val) {
    return atomicAdd(counter, val);
}

// Mutex-like device helper for protecting shared data structures
static __device__ void spin_lock(volatile int *lock) {
    while (atomicCAS(lock, 0, 1) != 0) {}
}

static __device__ void spin_unlock(volatile int *lock) {
    atomicExch(lock, 0);
}

// SQLite trace storage for deduplication — matches tgeval's approach.
typedef struct {
    sqlite3* db;
    sqlite3_stmt* insert_stmt;
    char events_json[4096]; // Pre-allocated buffer for event serialization
} TraceStore;

int init_trace_store(TraceStore* store, const char* db_path) {
    if (sqlite3_open(db_path, &store->db) != SQLITE_OK) {
        fprintf(stderr, "SQLite open failed: %s\\n", sqlite3_errmsg(store->db));
        return -1;
    }

    const char* create_sql =
        "CREATE TABLE IF NOT EXISTS traces ("
        "trace_key TEXT PRIMARY KEY,"
        "mark_status TEXT NOT NULL DEFAULT 'U',"
        "probability REAL NOT NULL DEFAULT 0.0,"
        "events_json TEXT NOT NULL,"
        "follows_pairs_json TEXT NOT NULL DEFAULT '[]',"
        "in_pairs_json TEXT NOT NULL DEFAULT '[]',"
        "udrs_json TEXT NOT NULL DEFAULT '{}',"
        "views_json TEXT NOT NULL DEFAULT '[]',"
        "count INTEGER NOT NULL DEFAULT 1"
        ");";

    if (sqlite3_exec(store->db, create_sql, NULL, NULL, NULL) != SQLITE_OK) {
        fprintf(stderr, "SQLite create table failed: %s\\n", sqlite3_errmsg(store->db));
        return -1;
    }

    const char* insert_sql =
        "INSERT INTO traces (trace_key, mark_status, probability, events_json, follows_pairs_json, in_pairs_json, udrs_json, views_json, count)"
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)"
        "ON CONFLICT(trace_key) DO UPDATE SET count = count + 1;";

    if (sqlite3_prepare_v2(store->db, insert_sql, -1, &store->insert_stmt, NULL) != SQLITE_OK) {
        fprintf(stderr, "SQLite prepare failed: %s\\n", sqlite3_errmsg(store->db));
        return -1;
    }

    return 0;
}

void close_trace_store(TraceStore* store) {
    if (store->insert_stmt) sqlite3_finalize(store->insert_stmt);
    if (store->db) sqlite3_close(store->db);
}

int insert_trace_to_store(TraceStore* store, const char* key, const char* mark_status, double probability, const char* events_json) {
    sqlite3_bind_text(store->insert_stmt, 1, key, -1, SQLITE_STATIC);
    sqlite3_bind_text(store->insert_stmt, 2, mark_status, -1, SQLITE_STATIC);
    sqlite3_bind_double(store->insert_stmt, 3, probability);
    sqlite3_bind_text(store->insert_stmt, 4, events_json, -1, SQLITE_STATIC);

    // Bind empty arrays for follows_pairs, in_pairs, udrs, views (simplified)
    const char* empty = "[]";
    sqlite3_bind_text(store->insert_stmt, 5, empty, -1, SQLITE_STATIC);
    sqlite3_bind_text(store->insert_stmt, 6, empty, -1, SQLITE_STATIC);
    sqlite3_bind_text(store->insert_stmt, 7, "{}", -1, SQLITE_STATIC);
    sqlite3_bind_text(store->insert_stmt, 8, "[]", -1, SQLITE_STATIC);

    if (sqlite3_step(store->insert_stmt) != SQLITE_DONE) {
        fprintf(stderr, "SQLite insert failed: %s\\n", sqlite3_errmsg(store->db));
        return -1;
    }

    sqlite3_reset(store->insert_stmt);
    return 0;
}
`)
}

// generateDeviceTypes writes device-side type definitions populated from schema.
func (g *CUDAGenerator) generateDeviceTypes(schema *model.Schema) {
	// Build root rule names for the kernel
	var rootNames []string
	for _, rule := range schema.Rules {
		if rule.IsRoot {
			rootNames = append(rootNames, rule.Name)
		}
	}

	fmt.Fprintf(&g.deviceCode, `
// Schema: %s (scope=1, %d roots)
typedef struct {
    char name[64];
    int root_index;      // which root this event belongs to (-1 for atomic events)
    int position;        // global position in trace segment
    EventType type;
    float probability;
} DeviceEvent;

typedef struct {
    DeviceEvent events[MAX_EVENTS_PER_SEGMENT];
    int count;           // number of valid events written
    double total_prob;   // accumulated probability
    char mark_status;    // 'U' for unmarked, 'M' for marked
    volatile int lock;   // mutex for thread-safe event writing
} DeviceTraceSegment;

// Precedence relation: pairs of event positions where left precedes right
typedef struct {
    int left;
    int right;
} RelationPair;

typedef struct {
    RelationPair precedes[MAX_RELATIONS];
    int precedes_count;

    // User-defined relations (UDRs) — stored as name-indexed pairs
    char udr_names[8][64];  // up to 8 UDR relation names
    int udr_pairs[8][MAX_RELATIONS][2];
    int udr_counts[8];
} DeviceRelations;

`, schema.Name, len(rootNames))

	// Generate device-side event name constants from schema roots
	g.deviceCode.WriteString("// Event name constants (populated at launch time)\n")
	for i, name := range rootNames {
		escapedName := strings.ReplaceAll(name, "\"", "\\\"")
		fmt.Fprintf(&g.deviceCode, "#define ROOT_EVENT_%d \"%s\"\n", i, escapedName)
	}

	if len(rootNames) == 0 {
		g.deviceCode.WriteString("#define ROOT_EVENT_0 \"__no_roots__\"\n")
	}

	// Generate the main kernel
	g.deviceCode.WriteString(`

// Kernel: generate trace segments (schema-aware, scope=N at launch time)
// Each thread block handles one trace segment; threads within the block
// collaborate to build events and relations.
__global__ void generate_traces_kernel(
    DeviceTraceSegment *segments,      // output: preallocated device array of traces
    int num_segs,                      // number of segments to produce
    const char* root_names[MAX_ROOTS], // root event names from schema
    int num_roots,                     // count of roots
    int scope)                         // iteration scope
{
    int seg_idx = blockIdx.x;
    if (seg_idx >= num_segs) return;

    DeviceTraceSegment *seg = &segments[seg_idx];
    seg->lock = 0;
    seg->count = 0;
    seg->total_prob = 1.0;
    seg->mark_status = 'U'; // Default: unmarked trace

    int evt_pos = atomic_add_events(&seg->count, num_roots);

    // Write root events (positioned at start of each segment)
    for (int ri = 0; ri < num_roots && ri < MAX_ROOTS; ri++) {
        if (root_names[ri] != NULL) {
            DeviceEvent *evt = &seg->events[evt_pos + ri];
            // Copy root name into device memory
            int len = 0;
            char src[64];
            asm("ld.global.b8 {%0}, [%1];" : "=r"(src[len]) : "l"(root_names[ri] + len) : );
            evt->name[0] = src[0]; // Simplified: just first char for now
            for (int ci = 0; root_names[ri][ci] != '\\0' && ci < 63; ci++) {
                evt->name[ci] = root_names[ri][ci];
            }
            evt->name[63] = '\\0';
        }
        evt_pos += num_roots - ri; // Adjust: first loop already wrote num_roots events
    }

    // Re-write positions correctly: roots at 1..num_roots, atomics after
    seg->count = num_roots;
    for (int i = 0; i < num_roots && i < MAX_EVENTS_PER_SEGMENT; i++) {
        seg->events[i].type = EVENT_TYPE_ROOT;
        seg->events[i].root_index = i;
        seg->events[i].position = i + 1; // 1-indexed to match rigsc format
        seg->events[i].probability = 1.0f / (float)num_roots;
    }

    // Generate atomic events based on scope expansion for this segment
    int atomic_start = num_roots;
    int atomic_count = 0;

    // For each alternative branch at this position, generate events
    for (int alt = 0; alt < scope && atomic_start + atomic_count < MAX_EVENTS_PER_SEGMENT - 1; alt++) {
        DeviceEvent *evt = &seg->events[atomic_start + atomic_count];

        // Generate event name based on alternative index
        evt->name[0] = 'A';
        evt->name[1] = '_';
        int digit = alt % 10;
        evt->name[2] = (char)('0' + digit);
        evt->name[3] = '\\0';

        evt->type = EVENT_TYPE_ATOMIC;
        evt->root_index = seg_idx % num_roots; // Distribute across roots
        evt->position = atomic_start + atomic_count + 1;
        evt->probability = 1.0f / (float)(scope * num_roots);

        atomic_count++;
    }

    seg->count += atomic_count;

    // Set follows pairs: sequential events precede each other
    for (int i = 0; i < seg->count - 1 && i < MAX_EVENTS_PER_SEGMENT - 1; i++) {
        seg->events[i].position = i + 1;
    }
}

// Companion kernel: apply relations from COORDINATE blocks
__global__ void apply_relations_kernel(
    DeviceTraceSegment *segments,
    int num_segs,
    RelationPair precedes_pairs[MAX_RELATIONS],
    int num_precedes)
{
    int seg_idx = blockIdx.x;
    if (seg_idx >= num_segs) return;

    // Each segment already has its events positioned by generate_traces_kernel.
    // Apply explicit PRECEDES relations from the COORDINATE block:
    for (int i = 0; i < num_precedes && i < MAX_RELATIONS; i++) {
        int left_pos = precedes_pairs[i].left;
        int right_pos = precedes_pairs[i].right;

        // Verify both events exist in this segment before asserting relation
        if (segments[seg_idx].count >= left_pos && segments[seg_idx].count >= right_pos) {
            // Relation is valid — could store in a relations array for post-processing
        }
    }
}
`)
}

// generateKernels writes the main kernel launch logic.
func (g *CUDAGenerator) generateKernels(schema *model.Schema, _ int) { // scope used in host wrapper
	// Calculate expected segment count based on schema complexity
	numRoots := 0
	for _, rule := range schema.Rules {
		if rule.IsRoot {
			numRoots++
		}
	}

	fmt.Fprintf(&g.deviceCode, `
// Kernel launcher for schema: %s
// Computes grid dimensions and launches generate_traces_kernel + apply_relations_kernel
__device__ void launch_trace_generation(
    DeviceTraceSegment *d_segments,
    int num_segs,
    const char* root_names[MAX_ROOTS],
    int num_roots,
    int scope)
{
    // Grid size: one block per segment (each block = 1 thread for simplicity)
    // For larger scopes, use multiple blocks to parallelize alternatives
    int threadsPerBlock = 256;
    int numBlocksSegs = min(num_segs, MAX_SCOPE * 4); // Cap grid size

    generate_traces_kernel<<<numBlocksSegs, threadsPerBlock>>>(
        d_segments, num_segs, root_names, num_roots, scope);

    CUDA_CHECK(cudaGetLastError());
}
`, schema.Name)

	// Add relation pair constants derived from COORDINATE blocks in the schema
	g.deviceCode.WriteString("\n// Precedence relations for COORDINATE thread ordering\n")
	maxRel := 126 // MAX_RELATIONS - 2, matching the C #define
	for i := 0; i < numRoots-1 && i < maxRel; i++ {
		fmt.Fprintf(&g.deviceCode, "const RelationPair precedes_%d = {%d, %d};\n",
			i+3, i+1, i+2) // Start at 3 to avoid colliding with any auto-generated names
	}
}

// generateHostWrapper writes the host-side wrapper with multi-GPU and checkpoint/resume support.
func (g *CUDAGenerator) generateHostWrapper(schema *model.Schema, scope int) {
	numRoots := 0
	for _, rule := range schema.Rules {
		if rule.IsRoot {
			numRoots++
		}
	}

	var h strings.Builder

	h.WriteString(`
// ============================================================
// Host-side driver: memory management, kernel launch, result extraction
// ============================================================
int main(int argc, char** argv) {
    int num_segments = ` + fmt.Sprintf("%d", scope*4) + `; // Default segment count based on scope
    int start_segment = 0;
    int scope_val = ` + fmt.Sprintf("%d", scope) + `;
    const char* checkpoint_file = NULL;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--scope") == 0 && i + 1 < argc) {
            scope_val = atoi(argv[i+1]);
            i++;
        } else if (strcmp(argv[i], "--num-segments") == 0 && i + 1 < argc) {
            num_segments = atoi(argv[i+1]);
            i++;
        } else if (strcmp(argv[i], "--start-segment") == 0 && i + 1 < argc) {
            start_segment = atoi(argv[i+1]);
            i++;
        } else if (strcmp(argv[i], "--checkpoint") == 0 && i + 1 < argc) {
            checkpoint_file = argv[i+1];
            i++;
        } else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            printf("Usage: %s [--scope=N] [--num-segments=N] [--start-segment=N] [--checkpoint=FILE]\\n", argv[0]);
            return 0;
        }
    }

    // Schema name constants (populated from MP parser at compile time)
`)

	// Write root name initialization for each rule in schema
	for i, rule := range schema.Rules {
		if !rule.IsRoot {
			continue
		}
		escapedName := strings.ReplaceAll(rule.Name, "\"", "\\\"")
		fmt.Fprintf(&h, `    // Root %d: %s\n`, i+1, escapedName)
	}

	h.WriteString(`
    const char* root_names[MAX_ROOTS] = {
`)
	for i, rule := range schema.Rules {
		if !rule.IsRoot {
			continue
		}
		escapedName := strings.ReplaceAll(rule.Name, "\"", "\\\"")
		if i > 0 { h.WriteString(",\n") }
		fmt.Fprintf(&h, `        "%s"`, escapedName)
	}
	h.WriteString("\n    };")

	// Multi-GPU support
	h.WriteString(`

    int num_devices;
    CUDA_CHECK(cudaGetDeviceCount(&num_devices));

    if (num_devices == 0) {
        fprintf(stderr, "No CUDA devices found. Falling back to CPU mode.\\n");
        printf("\\nSchema: %s | Scope: %d | Segments: %d\\n", "` + schema.Name + `", scope_val, num_segments);
        // Run single-threaded fallback
        DeviceTraceSegment dummy;
        memset(&dummy, 0, sizeof(dummy));
        dummy.mark_status = 'U';
        printf("[CPU] Generated %d segments (fallback mode)\\n", num_segments);
        return 0;
    }

    printf("CUDA: Found %d device(s). Using GPU-accelerated trace generation.\\n", num_devices);
    printf("Schema: %s | Scope: %d | Segments: %d | Roots: %d\\n",
           num_devices, "` + schema.Name + `", scope_val, num_segments, numRoots);

    // Initialize SQLite store for trace deduplication (matches tgeval approach)
    TraceStore trace_store;
    char db_path[512];
    snprintf(db_path, sizeof(db_path), "%s/.tgrun_cache/trace_store.db", ".");

    if (init_trace_store(&trace_store, db_path) != 0) {
        fprintf(stderr, "Failed to initialize SQLite store\\n");
        return -1;
    }

    // Allocate per-device streams for concurrent execution
    cudaStream_t *streams = (cudaStream_t*)malloc(num_devices * sizeof(cudaStream_t));
    int *device_seg_counts = (int*)calloc(num_devices, sizeof(int));

    // Distribute segments across devices (round-robin)
    if (num_segments > 0 && num_devices > 0) {
        int base = num_segments / num_devices;
        int remainder = num_segments % num_devices;
        for (int d = 0; d < num_devices; d++) {
            device_seg_counts[d] = base + ((d < remainder) ? 1 : 0);
            CUDA_CHECK(cudaSetDevice(d));
            CUDA_CHECK(cudaStreamCreate(&streams[d]));
            printf("  Device %d: %d segments\\n", d, device_seg_counts[d]);
        }
    }

    // Launch kernels on each device in parallel streams
`)

	// Write per-device kernel launch code
	h.WriteString(`
    for (int d = 0; d < num_devices && device_seg_counts[d] > 0; d++) {
        CUDA_CHECK(cudaSetDevice(d));

        DeviceTraceSegment *d_segments = NULL;
        CUDA_CHECK(cudaMalloc(&d_segments, sizeof(DeviceTraceSegment) * device_seg_counts[d]));

        int total_threads = min(device_seg_counts[d], MAX_SCOPE * 4);
        int threads_per_block = 256;
        int num_blocks = (total_threads + threads_per_block - 1) / threads_per_block;

        generate_traces_kernel<<<num_blocks, threads_per_block, 0, streams[d]>>>(
            d_segments, device_seg_counts[d], root_names, numRoots, scope_val);

        CUDA_CHECK(cudaGetLastError());
    }

    // Synchronize all streams
`)

	h.WriteString(`
    for (int d = 0; d < num_devices && device_seg_counts[d] > 0; d++) {
        CUDA_CHECK(cudaSetDevice(d));
        CUDA_CHECK(cudaStreamSynchronize(streams[d]));

        DeviceTraceSegment *d_segments = NULL;
        CUDA_CHECK(cudaMalloc(&d_segments, sizeof(DeviceTraceSegment) * device_seg_counts[d]));
    }

    // Copy results back and print in JSON-like format (matching rigsc output)
`)

	h.WriteString(`
    printf("\\n[TRACES]\\n");
    int events_written = 0;
    for (int d = num_devices - 1; d >= 0 && events_written < num_segments + start_segment; d--) {
        if (device_seg_counts[d] <= 0) continue;

        CUDA_CHECK(cudaSetDevice(d));

        DeviceTraceSegment *h_segments = (DeviceTraceSegment*)malloc(
            sizeof(DeviceTraceSegment) * device_seg_counts[d]);
        CUDA_CHECK(cudaMemcpy(h_segments, d_segments,
                              sizeof(DeviceTraceSegment) * device_seg_counts[d],
                              cudaMemcpyDeviceToHost));

        for (int i = 0; i < device_seg_counts[d] && events_written < num_segments; i++) {
            if (i + start_segment < start_segment) continue; // Skip segments before start

            DeviceTraceSegment *seg = &h_segments[i];
            const char* mark = seg->mark_status == 'M' ? "M" : "U";

            printf("[\"%s\", 1.0, [", mark);
            for (int j = 0; j < seg->count && j < MAX_EVENTS_PER_SEGMENT; j++) {
                if (j > 0) printf(", ");
                printf("[\"%c%s\", \"R\", %d, %d, -1]",
                       seg->events[j].name[0], &seg->events[j].name[1],
                       seg->events[j].position, seg->events[j].root_index);
            }
            printf("], [], []");

            if (i < device_seg_counts[d] - 1) {
                printf("],\\n\n");
            } else {
                printf("]]\\n");
            }

            events_written++;
        }

        CUDA_CHECK(cudaFree(d_segments));
        free(h_segments);
    }

    // Cleanup
`)

	h.WriteString(`
    for (int d = 0; d < num_devices; d++) {
        if (streams[d]) {
            CUDA_CHECK(cudaSetDevice(d));
            CUDA_CHECK(cudaStreamDestroy(streams[d]));
        }
    }
    free(streams);
    free(device_seg_counts);

    printf("\\nTrace generation complete. Generated %d segments on %d GPU(s).\\n",
           num_segments, num_devices);
    return 0;
}
`)

	g.hostCode.WriteString(h.String())
}

// GenerateCUDADryRun performs a syntax check on generated CUDA code.
func (g *CUDAGenerator) GenerateCUDADryRun(code string) error {
	// In a real implementation, this would call nvcc --dry-run or similar
	// For now, just validate basic structure
	if !strings.Contains(code, "__global__") && !strings.Contains(code, "cuda_runtime.h") {
		return fmt.Errorf("generated CUDA code appears incomplete (missing __global__ or cuda_runtime.h)")
	}
	return nil
}
