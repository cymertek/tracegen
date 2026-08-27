# tgfmt — Formatting Rules Reference

`tgfmt` is a code formatter for MP (Monterey Phoenix) behavioral event grammar files (`.mp`). It normalizes indentation and line spacing while preserving comment styles. Comment *style* decisions are handled by `tglint`, the linter.

Configuration lives in `.tgfmt.yml`:

```yaml
indent_width: 4    # Spaces per nesting level; also tab → space width
line_width: 100      # Maximum recommended line width (informational)
comment_style: "c"   # Reserved for future use — currently preserved as-is
```

---

## Rule 1: Tabs Become Spaces

All tabs in non-comment lines are converted to spaces. One tab = `indent_width` spaces (default 4). Comments preserve their original whitespace.

**Abnormal:**
```mp
ROOT ExampleRule:	(* atomic event *);
DO
	ADD $x PRECEDES $y; OD;
```

**Normal:**
```mp
ROOT ExampleRule:    (* atomic event *);
DO
    ADD $x PRECEDES $y; OD;
```

---

## Rule 2: Nesting Depth Indentation

`DO`, `BUILD`, and lines ending with `do` open a block (depth increases). `OD;`, `FI;`, and lines ending with `od;` or `fi;` close a block (depth decreases). Lines inside a block are indented by `nestingDepth × indent_width`.

**Abnormal:**
```mp
SCHEMA TestSchema

ROOT RootRule: (* event *);

DO
ADD $x PRECEDES $y;
    ADD $z EQUALS $w;
OD;
```

**Normal:**
```mp
SCHEMA TestSchema

ROOT RootRule: (* event *);

DO
    ADD $x PRECEDES $y;
    ADD $z EQUALS $w;
OD;
```

---

## Rule 3: Blank Line Collapse

Multiple consecutive blank lines are collapsed to a single blank line. A file always ends with exactly one newline character.

**Abnormal:**
```mp
SCHEMA TestSchema


ROOT Rule: (* event *);



DO
    ...; OD;
```

**Normal:**
```mp
SCHEMA TestSchema

ROOT Rule: (* event *);

DO
    ...; OD;
```

---

## Rule 4: Trailing Whitespace Removal

Every line has trailing spaces and tabs stripped. Only visible content remains on each line.

**Abnormal (spaces shown as ·):**
```mp
ROOT ExampleRule: (* atomic event *);···
DO···
    ADD $x PRECEDES $y;···
OD;···
```

**Normal:**
```mp
ROOT ExampleRule: (* atomic event *);
DO
    ADD $x PRECEDES $y;
OD;
```

---

## Rule 5: Consecutive Comment Alignment

When multiple comment lines appear together (separated only by blank lines), they are aligned to a common baseline. The minimum indentation in the group becomes column 0, and relative offsets between lines are preserved. Blank lines inside a comment group are kept as-is.

**Abnormal:**
```mp
// Comment at zero indent
    // Indented four spaces
        // Indented eight spaces
// Back to zero indent
```

**Normal:**
```mp
// Comment at zero indent
// Indented four spaces
//     Indented eight spaces
// Back to zero indent
```

---

## Rule 6: Multi-line Block Comments

`/* ... */` and `(* ... *)` comments that span multiple lines are detected as a single group. Inner lines lose their leading whitespace relative to the group minimum, but blank lines within the block are preserved. The comment *style* (`/*`, `(*`, or `//`) is never converted.

**Abnormal:**
```mp
/* This is a multi-line
   comment with varying
       indentation levels

   that should be normalized */
SCHEMA TestSchema;
```

**Normal:**
```mp
/* This is a multi-line
comment with varying
indentation levels

that should be normalized */
SCHEMA TestSchema;
```

---

## Rule 7: Comment Style Preservation

tgfmt does **not** convert between comment styles. `//`, `(* *)`, and `/* */` are all preserved exactly as written. The `comment_style` config option is reserved for future use but currently has no effect.

**Abnormal (no conversion occurs — this is correct behavior):**
```mp
SCHEMA TestSchema  // Inline C-style comment

ROOT Rule: (* MP-style event *);  // Also preserved
/* Block comment — stays */       // Stays too
```

This rule exists so that the linter (`tglint`) can enforce style consistency separately from formatting.

---

## What tgfmt does NOT touch

| Concern | Handled by |
|---------|-----------|
| Naming conventions (keywords, identifiers) | tglint |
| Line width enforcement (hard wrap) | tglint |
| Comment style consistency (`//` vs `(* *)`) | tglint |
| Structural rules (required blocks, ordering) | tglint |
| Blank-line placement between sections | tglint |

tgfmt's scope is intentionally narrow: indentation, blank lines, trailing whitespace, and comment alignment. Everything else belongs to the linter.
