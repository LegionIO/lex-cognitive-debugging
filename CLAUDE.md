# lex-cognitive-debugging

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Self-debugging system for cognitive processes in LegionIO — detects reasoning errors, traces causal chains, and applies corrective strategies. Models the metacognitive capacity to catch and fix one's own reasoning failures before they propagate into actions.

## Gem Info

- **Gem name**: `lex-cognitive-debugging`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CognitiveDebugging`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_debugging/
  cognitive_debugging.rb
  version.rb
  client.rb
  helpers/
    constants.rb
    debugging_engine.rb
    reasoning_error.rb
    causal_trace.rb
    correction.rb
  runners/
    cognitive_debugging.rb
```

## Key Constants

From `helpers/constants.rb`:

- `ERROR_TYPES` — `%i[inconsistency circular_logic ungrounded_claim overconfidence logical_fallacy missing_evidence false_analogy confirmation_bias]`
- `CORRECTION_STRATEGIES` — `%i[retrace reframe weaken_confidence seek_evidence decompose analogize devil_advocate]`
- `STATUS_LABELS` — `%i[detected traced correcting resolved unresolvable]`
- `MAX_ERRORS` = `300`, `MAX_TRACES` = `500`, `MAX_CORRECTIONS` = `200`
- `SEVERITY_LABELS` — array-of-hashes: `0.0-0.2` = `:trivial`, `0.2-0.4` = `:minor`, `0.4-0.6` = `:moderate`, `0.6-0.8` = `:major`, `0.8-1.0` = `:critical`
- `severity_label(severity)` — `module_function` for label lookup

## Runners

All methods in `Runners::CognitiveDebugging`:

- `detect_error(error_type:, description:, severity:, source_phase:, confidence_at_detection: 0.5)` — registers a detected reasoning error; validates error_type
- `trace_error(error_id:, steps:, root_cause:, confidence: 0.5)` — creates a causal trace for an error; records investigation path and root cause
- `propose_correction(error_id:, strategy:, description:)` — proposes a correction strategy; validates against `CORRECTION_STRATEGIES`
- `apply_correction(correction_id:)` — marks correction as applied
- `measure_correction(correction_id:, effectiveness:)` — records effectiveness score; `effective?` if effectiveness > 0.5
- `resolve_error(error_id:)` — marks error as fully resolved
- `active_errors` — all unresolved errors
- `resolved_errors` — all resolved errors
- `errors_by_type` — tally by error type
- `errors_by_phase` — tally by source phase (where the error was detected)
- `most_common_error_type` — error type with highest frequency
- `most_effective_strategy` — correction strategy with best effectiveness score
- `correction_success_rate` — ratio of effective corrections to total applied
- `debugging_report` — full report: totals, by-type breakdown, strategy effectiveness
- `snapshot` — raw state dump for inspection

## Helpers

- `DebuggingEngine` — manages errors, traces, and corrections. Tracks strategy effectiveness as running average.
- `ReasoningError` — has `error_type`, `description`, `severity`, `source_phase`, `status`. Status transitions: `detected` -> `traced` -> `correcting` -> `resolved/unresolvable`.
- `CausalTrace` — investigation record with `steps` array, `root_cause`, `confidence`, `depth` (steps count).
- `Correction` — proposed fix with `strategy`, `description`, `applied`, `effectiveness`.

## Integration Points

- `lex-cognitive-blindspot` registration: when `detect_error` fires for `error_type: :ungrounded_claim` or `:confirmation_bias`, those should also register blindspots via `discovered_by: :error_analysis`.
- `lex-tick` can call `debugging_report` in an introspection phase to surface active errors for decision-making.
- `source_phase` connects errors back to the tick phase where they were detected — enables per-phase error rates for architecture quality assessment.

## Development Notes

- `ERROR_TYPES` and `CORRECTION_STRATEGIES` are validated in runners — invalid values return `{ success: false, error: :invalid_error_type }`.
- `SEVERITY_LABELS` uses an array-of-hashes structure (not a frozen Hash with range keys) — `severity_label` is a `module_function` for lookup.
- `measure_correction` records effectiveness but does not auto-resolve the parent error — callers must explicitly call `resolve_error`.
- `most_effective_strategy` returns the strategy with the highest average effectiveness across all applied corrections in its category.
