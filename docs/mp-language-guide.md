# MP Language Guide for CYMERTEK CUDA Trace Generator

This guide covers writing MP (Monterey Phoenix) behavioral event grammar files compatible with the trace generator. The language syntax follows the Firebird specification (MP v4.0).

## Introduction to MP Behavioral Event Grammar

MP is a formal specification language for describing system behaviors as sets of events with ordering and nesting relations. Unlike traditional programming languages that specify step-by-step algorithms, MP describes **what** behaviors are valid without prescribing **how** to execute them.

### Core Concepts

- **Event**: An abstraction of an activity or action (e.g., `send`, `receive`, `login`)
- **Trace**: A specific execution path through events with defined relations
- **Schema**: Collection of event rules and composition operations that define valid behaviors
- **Grammar Rule**: Defines structure for a particular event type using patterns

### What MP Models Look Like

MP models specify system behaviors declaratively:

```mp
SCHEMA message_flow
ROOT Sender: (* send *);
ROOT Receiver: (* receive *);
COORDINATE
    $x: send FROM Sender,
    $y: receive FROM Receiver
DO
    ADD $x PRECEDES $y;
OD;
END SCHEMA;
```

This schema says: "A valid behavior consists of a Sender that sends messages and a Receiver that receives them, with each send preceded by a corresponding receive."

## File Structure

MP files use the `.mp` extension. A complete MP model contains:

1. **Schema header**: `SCHEMA name; ... END SCHEMA;`
2. **Event rules**: Define atomic and composite event types
3. **Composition operations**: Coordinate behaviors across roots
4. **Constraints**: ENSURE blocks for context conditions

### Minimal Valid MP File

```mp
SCHEMA empty_schema;
END SCHEMA;
```

This schema has no events or rules — it generates zero traces (no behavior to specify).

## Event Grammar Rules

Event grammar rules define the structure of event types using **event patterns**.

### Atomic Events

Atomic events are leaf nodes in the behavior tree. They have no internal structure:

```mp
SCHEMA simple_events
ROOT Sender: send;
END SCHEMA;
```

This defines a single root event `Sender` that consists of one atomic event `send`. The trace generator will produce one trace containing just `[send]`.

### Composite Events with Sequences

Use parentheses to sequence events under PRECEDES relation:

```mp
SCHEMA login_flow
ROOT LoginProcess: (login_start perform_login login_complete);
END SCHEMA;
```

This specifies that `perform_login` must follow `login_start`, and `login_complete` must follow `perform_login`. The generated trace will have three events with PRECEDES relations between consecutive pairs.

### Iteration Patterns

MP supports several iteration patterns for repeated behaviors:

#### Zero or More Times (`(* ... *)`)

```mp
SCHEMA retry_logic
ROOT Client: (* send_request receive_response *);
END SCHEMA;
```

The `(* ... *)` pattern means "repeat the enclosed events zero or more times." With scope=2, this generates traces where the sequence appears 0, 1, or 2 times.

#### One or More Times (`(+ ... +)`)

```mp
SCHEMA at_least_once
ROOT Worker: (+ process_job +);
END SCHEMA;
```

The `(+ ... +)` pattern requires at least one iteration. With scope=3, this generates traces with 1, 2, or 3 iterations of `process_job`.

#### Set Patterns (`{+ ... +}`)

```mp
SCHEMA concurrent_tasks
ROOT TaskManager: {+ assign_task receive_status +};
END SCHEMA;
```

The `{+ ... +}` pattern represents a set of concurrent events. The order within the set is not specified (all permutations are valid traces).

## Composition Operations

Composition operations coordinate behaviors across multiple root events.

### COORDINATE

COORDINATE synchronizes event sets from different roots:

```mp
SCHEMA producer_consumer
ROOT Producer: (* produce_item *);
ROOT Consumer: (* consume_item *);
COORDINATE
    $p: produce_item FROM Producer,
    $c: consume_item FROM Consumer
DO
    ADD $p PRECEDES $c;
OD;
END SCHEMA;
```

This coordinates `produce_item` events from `Producer` with `consume_item` events from `Consumer`, adding a PRECEDES relation between matched pairs.

### SHARE ALL

SHARE ensures corresponding events across roots have matching attributes:

```mp
SCHEMA shared_data
ROOT Writer: (+ write_data +);
ROOT Reader: (+ read_data +);
Writer, Reader SHARE ALL data;
END SCHEMA;
```

Events `write_data` and `read_data` must share the same `data` attribute value for a valid trace.

### Conditional Composition (IF/THEN/FI)

Apply composition operations conditionally based on event attributes:

```mp
SCHEMA conditional_flow
ROOT Router: (* check_route route_request *);
COORDINATE
    $r: check_route FROM Router
DO
    IF #check_route.route_type == "fast" THEN
        ADD $r PRECEDES fast_path;
    ELSE
        ADD $r PRECEDES slow_path;
    FI;
OD;
END SCHEMA;
```

## ENSURE Constraints

ENSURE blocks define context conditions that must hold for valid traces:

### Simple Conditions

```mp
SCHEMA security_policy
ROOT AuthServer: (* authenticate user *);
BUILD {
    ENSURE FOREACH $u: user FROM AuthServer
        (#authenticate.success == TRUE);
};
END SCHEMA;
```

This constraint requires that all `user` events in the trace must have a corresponding successful authentication.

### Quantified Conditions

Use `FORALL`, `EXISTS`, or `FOREACH` to quantify over event sets:

```mp
SCHEMA resource_limits
ROOT Service: (* request_resource release_resource *);
BUILD {
    ENSURE FORALL $r: request_resource FROM Service
        (#request_resource.count <= 10);
};
END SCHEMA;
```

Limits the number of `request_resource` events to at most 10 per trace.

### Navigation Directions

Reference events relative to the current context using navigation directions:

- **BEFORE**: Events that precede the current event in PRECEDES relation
- **AFTER**: Events that follow the current event
- **INSIDE**: Events nested within the current event
- **OUTSIDE**: Events containing the current event (transitive closure of IN)

```mp
SCHEMA temporal_constraint
ROOT Workflow: (* start_step complete_step *);
BUILD {
    ENSURE FOREACH $s: start_step FROM Workflow,
                  $c: complete_step FROM Workflow
        ($c BEFORE $s -> #complete_step.duration <= 5);
};
END SCHEMA;
```

## Attribute Assignments

Attributes store data associated with events. MP supports three attribute types:

### NUMBER Attributes

Numeric values for counting or measuring:

```mp
SCHEMA counter_example
ROOT Counter: (* increment decrement *);
NUMBER count;
Counter ATTRIBUTES count;
END SCHEMA;
```

The `count` attribute tracks the current value after each operation.

### INTERVAL Attributes

Time intervals with BEFORE/CONTAINS/EQUAL relations:

```mp
SCHEMA timing_example
ROOT Timer: (* start_timer wait_duration stop_timer *);
INTERVAL duration;
Timer ATTRIBUTES duration;
END SCHEMA;
```

The `duration` interval tracks the elapsed time between `start_timer` and `stop_timer`.

### BOOLEAN Attributes

True/false flags for event properties:

```mp
SCHEMA flag_example
ROOT Monitor: (* check_status alert_user *);
BOOLEAN is_critical;
Monitor ATTRIBUTES is_critical;
END SCHEMA;
```

The `is_critical` boolean indicates whether the checked status requires immediate attention.

## Probability Annotations

Assign probabilities to alternative event patterns for stochastic trace generation:

### Basic Probabilities

```mp
SCHEMA probabilistic_flow
ROOT DecisionPoint: (success <<0.8>> | failure <<0.2>>);
END SCHEMA;
```

The `<<0.8>>` annotation means the `success` branch has 80% probability of being selected. The trace generator samples alternatives according to these probabilities.

### Strict Probabilities

Use strict probabilities for deterministic selection:

```mp
SCHEMA strict_choice
ROOT Router: (fast_path <<1.0>> | slow_path <<0.0>>);
END SCHEMA;
```

With `<<1.0>>`, only `fast_path` is ever selected (deterministic behavior).

## Comments and Documentation

MP supports two comment styles:

### MP-Style Comments (`(* ... *)`)

Used for iteration scopes and inline documentation:

```mp
SCHEMA commented_example
ROOT Worker: (* process_batch *);  // Iteration scope
END SCHEMA;
```

### C-Style Comments (`/* ... */`)

For multi-line documentation:

```mp
SCHEMA documented_schema
/*
 * This schema models a simple request-response pattern.
 * 
 * Events:
 *   - send_request: Client initiates a request
 *   - receive_response: Server responds to the request
 */
ROOT Client: (* send_request receive_response *);
END SCHEMA;
```

## Complete Example: Authentication System

Here's a complete MP model for an authentication system with multiple features:

```mp
SCHEMA auth_system
/*
 * Models user authentication with login, session management, and logout.
 */

// Define atomic events
ROOT User: (* login_attempt authenticate_user logout_session *);
ROOT AuthServer: (* validate_credentials grant_access revoke_access *);

// Set up shared attributes
NUMBER login_attempts;
INTERVAL session_duration;
BOOLEAN is_authenticated;

User ATTRIBUTES login_attempts, session_duration, is_authenticated;
AuthServer ATTRIBUTES login_attempts, is_authenticated;

// Coordinate behaviors
COORDINATE
    $u: login_attempt FROM User,
    $a: validate_credentials FROM AuthServer
DO
    ADD $u PRECEDES $a;
OD;

COORDINATE
    $a: grant_access FROM AuthServer,
    $u: authenticate_user FROM User
DO
    ADD $a PRECEDES $u;
    SET $u.is_authenticated := TRUE;
OD;

// Define composition operations
User, AuthServer SHARE ALL login_attempts;

// Add constraints
BUILD {
    ENSURE FORALL $u: login_attempt FROM User
        (#login_attempt.login_attempts <= 3);
    
    ENSURE FOREACH $a: grant_access FROM AuthServer,
                  $u: authenticate_user FROM User
        ($u is_authenticated == TRUE);
};

END SCHEMA;
```

### Running This Example

```bash
# Generate traces with scope=2 (up to 2 login attempts)
tracegen run auth_system.mp --scope=2 -v

# Expected output (simplified):
# [INFO] Parsing MP file: auth_system.mp (89 tokens)
# [INFO] Backend selected: cuda (GPU available on device 0)
# [INFO] Generated CUDA kernel: trace_generation_kernel<<<gridDim name="{1,1,1}, blockDim={256,1,1}">>>
# [INFO] Executing trace generator (scope=2)...
# [INFO] Generated 4 traces in 12ms
# [INFO] Output written to auth_system.json
```

## Syntax Reference

### Keywords

| Keyword | Description | Example |
|---------|-------------|---------|
| `SCHEMA` | Begin schema definition | `SCHEMA my_schema;` |
| `END SCHEMA` | End schema definition | `END SCHEMA;` |
| `ROOT` | Define root event type | `ROOT Sender: ...;` |
| `COORDINATE` | Start coordination block | `COORDINATE $x: ... DO ... OD;` |
| `DO` / `OD` | Begin/end composition operations | `DO ADD ... OD;` |
| `BUILD` | Define ENSURE constraints | `BUILD { ENSURE ... };` |
| `ENSURE` | Assert context condition | `ENSURE FORALL $x: ...` |
| `IF` / `THEN` / `ELSE` / `FI` | Conditional composition | `IF cond THEN op ELSE op FI;` |
| `SHARE ALL` | Require attribute matching | `A, B SHARE ALL attr;` |

### Event Patterns

| Pattern | Description | Example |
|---------|-------------|---------|
| `(A B C)` | Sequence (PRECEDES) | `(login logout);` |
| `{A B}` | Concurrent set | `{read write};` |
| `(* A *)` | Zero or more iterations | `(* retry *);` |
| `(+ A +)` | One or more iterations | `(+ process +);` |
| `<P>` | Probability annotation | `(success <<0.8>>);` |

### Attribute Types

| Type | Description | Example |
|------|-------------|---------|
| `NUMBER` | Numeric value | `NUMBER count;` |
| `INTERVAL` | Time interval | `INTERVAL duration;` |
| `BOOLEAN` | True/false flag | `BOOLEAN is_active;` |

### Navigation Directions

| Direction | Description | Example |
|-----------|-------------|---------|
| `BEFORE` | Preceding events (PRECEDES) | `$y BEFORE $x` |
| `AFTER` | Following events | `$z AFTER $y` |
| `INSIDE` | Nested events (IN relation) | `$w INSIDE $v` |
| `OUTSIDE` | Containing events | `$t OUTSIDE $s` |

## Next Steps

- **Getting Started**: [docs/getting-started.md](getting-started.md) — Installation and first run
- **Command Reference**: [docs/command-reference.md](command-reference.md) — All flags and options
- **GPU Acceleration**: [docs/gpu-acceleration.md](gpu-acceleration.md) — CUDA configuration
