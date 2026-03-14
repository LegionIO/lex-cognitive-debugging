# frozen_string_literal: true

require 'legion/extensions/cognitive_debugging/client'

RSpec.describe Legion::Extensions::CognitiveDebugging::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:detect_error)
    expect(client).to respond_to(:trace_error)
    expect(client).to respond_to(:propose_correction)
    expect(client).to respond_to(:apply_correction)
    expect(client).to respond_to(:measure_correction)
    expect(client).to respond_to(:resolve_error)
    expect(client).to respond_to(:active_errors)
    expect(client).to respond_to(:resolved_errors)
    expect(client).to respond_to(:errors_by_type)
    expect(client).to respond_to(:errors_by_phase)
    expect(client).to respond_to(:most_common_error_type)
    expect(client).to respond_to(:most_effective_strategy)
    expect(client).to respond_to(:correction_success_rate)
    expect(client).to respond_to(:debugging_report)
    expect(client).to respond_to(:snapshot)
  end

  it 'accepts an injected engine' do
    engine = Legion::Extensions::CognitiveDebugging::Helpers::DebuggingEngine.new
    client = described_class.new(engine: engine)
    result = client.detect_error(
      error_type:              :overconfidence,
      description:             'Test injection',
      severity:                0.5,
      source_phase:            :tick,
      confidence_at_detection: 0.8
    )
    expect(result[:success]).to be true
    expect(engine.errors.size).to eq(1)
  end

  it 'creates a fresh engine when none injected' do
    c1 = described_class.new
    c2 = described_class.new
    c1.detect_error(error_type: :inconsistency, description: 'x', severity: 0.5,
                    source_phase: :tick, confidence_at_detection: 0.5)
    expect(c2.active_errors[:count]).to eq(0)
  end
end
