# frozen_string_literal: true

require 'legion/extensions/cognitive_debugging/client'

RSpec.describe Legion::Extensions::CognitiveDebugging::Runners::CognitiveDebugging do
  subject(:client) { Legion::Extensions::CognitiveDebugging::Client.new }

  let(:base_error_kwargs) do
    {
      error_type:              :inconsistency,
      description:             'Claim X contradicts Claim Y',
      severity:                0.6,
      source_phase:            :prediction_engine,
      confidence_at_detection: 0.85
    }
  end

  def detect_one(overrides = {})
    client.detect_error(**base_error_kwargs.merge(overrides))
  end

  describe '#detect_error' do
    it 'returns success: true with an error_id' do
      result = detect_one
      expect(result[:success]).to be true
      expect(result[:error_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns the error_type' do
      result = detect_one
      expect(result[:error_type]).to eq(:inconsistency)
    end

    it 'includes severity_label' do
      result = detect_one
      expect(result[:severity_label]).to be_a(Symbol)
    end

    it 'returns success: false for invalid error_type' do
      result = client.detect_error(**base_error_kwargs.merge(error_type: :not_real))
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_error_type)
    end

    it 'returns valid error types on failure' do
      result = client.detect_error(**base_error_kwargs.merge(error_type: :bogus))
      expect(result[:valid]).to include(:inconsistency)
    end

    it 'uses default confidence_at_detection of 0.5 when omitted' do
      result = client.detect_error(error_type: :overconfidence, description: 'x',
                                   severity: 0.5, source_phase: :tick)
      expect(result[:success]).to be true
    end
  end

  describe '#trace_error' do
    let(:error_id) { detect_one[:error_id] }
    let(:steps) do
      [
        { phase: :emotional_evaluation, description: 'Urgency spike' },
        { phase: :prediction_engine,    description: 'Premature conclusion' }
      ]
    end

    it 'returns success: true with trace_id and depth' do
      result = client.trace_error(error_id: error_id, steps: steps, root_cause: :bad_prior, confidence: 0.7)
      expect(result[:success]).to be true
      expect(result[:trace_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:depth]).to eq(2)
    end

    it 'returns root_cause in response' do
      result = client.trace_error(error_id: error_id, steps: steps, root_cause: :bad_prior, confidence: 0.7)
      expect(result[:root_cause]).to eq(:bad_prior)
    end

    it 'returns success: false for unknown error_id' do
      result = client.trace_error(error_id: 'nope', steps: steps, root_cause: :x, confidence: 0.5)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found_or_cap)
    end

    it 'uses default confidence of 0.5 when omitted' do
      result = client.trace_error(error_id: error_id, steps: steps, root_cause: :x)
      expect(result[:success]).to be true
    end
  end

  describe '#propose_correction' do
    let(:error_id) { detect_one[:error_id] }

    it 'returns success: true with correction_id and strategy' do
      result = client.propose_correction(error_id: error_id, strategy: :retrace,
                                         description: 'Re-examine from start')
      expect(result[:success]).to be true
      expect(result[:correction_id]).to match(/\A[0-9a-f-]{36}\z/)
      expect(result[:strategy]).to eq(:retrace)
    end

    it 'returns success: false for invalid strategy' do
      result = client.propose_correction(error_id: error_id, strategy: :invalid_strat, description: 'x')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_strategy)
    end

    it 'returns valid strategies on failure' do
      result = client.propose_correction(error_id: error_id, strategy: :bad, description: 'x')
      expect(result[:valid]).to include(:retrace, :devil_advocate)
    end

    it 'returns success: false for unknown error_id' do
      result = client.propose_correction(error_id: 'nope', strategy: :retrace, description: 'x')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#apply_correction' do
    let(:correction_id) do
      error_id = detect_one[:error_id]
      client.propose_correction(error_id: error_id, strategy: :retrace, description: 'x')[:correction_id]
    end

    it 'returns success: true and applied: true' do
      result = client.apply_correction(correction_id: correction_id)
      expect(result[:success]).to be true
      expect(result[:applied]).to be true
    end

    it 'returns success: false for unknown correction_id' do
      result = client.apply_correction(correction_id: 'nope')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#measure_correction' do
    let(:correction_id) do
      error_id = detect_one[:error_id]
      client.propose_correction(error_id: error_id, strategy: :reframe, description: 'x')[:correction_id]
    end

    it 'returns effectiveness and effective flag' do
      result = client.measure_correction(correction_id: correction_id, effectiveness: 0.8)
      expect(result[:success]).to be true
      expect(result[:effectiveness]).to eq(0.8)
      expect(result[:effective]).to be true
    end

    it 'returns effective: false for low score' do
      result = client.measure_correction(correction_id: correction_id, effectiveness: 0.4)
      expect(result[:effective]).to be false
    end

    it 'returns success: false for unknown correction_id' do
      result = client.measure_correction(correction_id: 'nope', effectiveness: 0.5)
      expect(result[:success]).to be false
    end
  end

  describe '#resolve_error' do
    let(:error_id) { detect_one[:error_id] }

    it 'returns success: true and resolved: true' do
      result = client.resolve_error(error_id: error_id)
      expect(result[:success]).to be true
      expect(result[:resolved]).to be true
    end

    it 'returns success: false for unknown error_id' do
      result = client.resolve_error(error_id: 'nope')
      expect(result[:success]).to be false
    end
  end

  describe '#active_errors' do
    it 'returns a list of active errors' do
      detect_one
      result = client.active_errors
      expect(result[:success]).to be true
      expect(result[:count]).to be >= 1
      expect(result[:errors]).to be_an(Array)
    end

    it 'does not include resolved errors' do
      eid = detect_one[:error_id]
      client.resolve_error(error_id: eid)
      result = client.active_errors
      ids = result[:errors].map { |e| e[:id] }
      expect(ids).not_to include(eid)
    end
  end

  describe '#resolved_errors' do
    it 'returns empty list when nothing resolved' do
      result = client.resolved_errors
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'includes resolved errors' do
      eid = detect_one[:error_id]
      client.resolve_error(error_id: eid)
      result = client.resolved_errors
      ids = result[:errors].map { |e| e[:id] }
      expect(ids).to include(eid)
    end
  end

  describe '#errors_by_type' do
    it 'returns a tally hash' do
      detect_one(error_type: :overconfidence)
      detect_one(error_type: :overconfidence)
      result = client.errors_by_type
      expect(result[:success]).to be true
      expect(result[:tally][:overconfidence]).to eq(2)
    end
  end

  describe '#errors_by_phase' do
    it 'returns a tally by source_phase' do
      detect_one(source_phase: :emotional_evaluation)
      result = client.errors_by_phase
      expect(result[:success]).to be true
      expect(result[:tally][:emotional_evaluation]).to be >= 1
    end
  end

  describe '#most_common_error_type' do
    it 'returns nil when no errors' do
      result = client.most_common_error_type
      expect(result[:success]).to be true
      expect(result[:error_type]).to be_nil
    end

    it 'returns the most frequent type' do
      detect_one(error_type: :circular_logic)
      detect_one(error_type: :circular_logic)
      detect_one(error_type: :missing_evidence)
      result = client.most_common_error_type
      expect(result[:error_type]).to eq(:circular_logic)
    end
  end

  describe '#most_effective_strategy' do
    it 'returns nil when no measured corrections' do
      result = client.most_effective_strategy
      expect(result[:success]).to be true
      expect(result[:strategy]).to be_nil
    end

    it 'returns the best-performing strategy' do
      eid = detect_one[:error_id]
      c1 = client.propose_correction(error_id: eid, strategy: :retrace, description: 'x')
      c2 = client.propose_correction(error_id: eid, strategy: :seek_evidence, description: 'y')
      client.measure_correction(correction_id: c1[:correction_id], effectiveness: 0.3)
      client.measure_correction(correction_id: c2[:correction_id], effectiveness: 0.95)
      result = client.most_effective_strategy
      expect(result[:strategy]).to eq(:seek_evidence)
    end
  end

  describe '#correction_success_rate' do
    it 'returns 0.0 when no corrections' do
      result = client.correction_success_rate
      expect(result[:success]).to be true
      expect(result[:rate]).to eq(0.0)
    end

    it 'calculates correct rate after measuring' do
      eid = detect_one[:error_id]
      c1 = client.propose_correction(error_id: eid, strategy: :retrace, description: 'a')
      c2 = client.propose_correction(error_id: eid, strategy: :reframe, description: 'b')
      client.apply_correction(correction_id: c1[:correction_id])
      client.apply_correction(correction_id: c2[:correction_id])
      client.measure_correction(correction_id: c1[:correction_id], effectiveness: 0.9)
      client.measure_correction(correction_id: c2[:correction_id], effectiveness: 0.9)
      result = client.correction_success_rate
      expect(result[:rate]).to eq(1.0)
    end
  end

  describe '#debugging_report' do
    it 'returns success: true with a complete report' do
      detect_one
      result = client.debugging_report
      expect(result[:success]).to be true
      expect(result[:report]).to include(:total_errors, :active_errors, :correction_success_rate)
    end
  end

  describe '#snapshot' do
    it 'returns success: true with snapshot data' do
      detect_one
      result = client.snapshot
      expect(result[:success]).to be true
      expect(result[:snapshot]).to include(:errors, :traces, :corrections)
    end
  end
end
