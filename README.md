# lex-cognitive-debugging

Self-debugging system for cognitive processes in LegionIO. Detects reasoning errors, traces their causal chain through cognitive phases, proposes corrective strategies, and tracks resolution effectiveness.

## What It Does

Cognitive debugging models the metacognitive capacity to catch and fix reasoning failures before they propagate into actions. An error is detected with a type and severity, then traced through a causal investigation (steps + root cause). One or more corrections are proposed using defined strategies, applied, and measured for effectiveness. The system tracks per-type error frequencies, per-phase detection rates, and per-strategy effectiveness averages — enabling ongoing quality assessment of the agent's own reasoning.

Eight error types cover the common failure modes: inconsistency, circular logic, ungrounded claims, overconfidence, logical fallacies, missing evidence, false analogy, and confirmation bias. Seven correction strategies map to standard epistemic repair techniques: retrace, reframe, weaken_confidence, seek_evidence, decompose, analogize, and devil_advocate.

## Usage

```ruby
client = Legion::Extensions::CognitiveDebugging::Client.new

# Detect a reasoning error
result = client.detect_error(
  error_type: :overconfidence,
  description: 'Predicted outcome with 0.95 confidence after only two data points',
  severity: 0.7,
  source_phase: :prediction_engine,
  confidence_at_detection: 0.8
)
error_id = result[:error_id]

# Trace the causal chain
client.trace_error(
  error_id: error_id,
  steps: ['checked prediction log', 'found insufficient evidence base'],
  root_cause: 'recency bias from last two successful predictions',
  confidence: 0.75
)

# Propose and apply a correction
correction = client.propose_correction(
  error_id: error_id,
  strategy: :weaken_confidence,
  description: 'Reduce confidence floor until five+ data points available'
)
correction_id = correction[:correction_id]

client.apply_correction(correction_id: correction_id)
client.measure_correction(correction_id: correction_id, effectiveness: 0.8)
client.resolve_error(error_id: error_id)

# Analysis
client.active_errors
client.errors_by_type
client.most_common_error_type
client.most_effective_strategy
client.correction_success_rate
client.debugging_report
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
