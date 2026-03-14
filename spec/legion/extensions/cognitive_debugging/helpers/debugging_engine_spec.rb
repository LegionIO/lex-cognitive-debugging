# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDebugging::Helpers::DebuggingEngine do
  subject(:engine) { described_class.new }

  let(:base_error_args) do
    {
      error_type:              :inconsistency,
      description:             'Claim A contradicts Claim B',
      severity:                0.6,
      source_phase:            :prediction_engine,
      confidence_at_detection: 0.8
    }
  end

  def add_error(overrides = {})
    engine.detect_error(**base_error_args.merge(overrides))
  end

  describe '#initialize' do
    it 'starts with empty errors' do
      expect(engine.errors).to be_empty
    end

    it 'starts with empty traces' do
      expect(engine.traces).to be_empty
    end

    it 'starts with empty corrections' do
      expect(engine.corrections).to be_empty
    end
  end

  describe '#detect_error' do
    it 'creates and stores a ReasoningError' do
      err = add_error
      expect(err).to be_a(Legion::Extensions::CognitiveDebugging::Helpers::ReasoningError)
      expect(engine.errors[err.id]).to be(err)
    end

    it 'returns nil for invalid error_type' do
      result = engine.detect_error(**base_error_args.merge(error_type: :not_real))
      expect(result).to be_nil
    end

    it 'assigns unique ids to multiple errors' do
      e1 = add_error
      e2 = add_error(error_type: :circular_logic)
      expect(e1.id).not_to eq(e2.id)
    end

    it 'stores all valid error types without error' do
      Legion::Extensions::CognitiveDebugging::Helpers::Constants::ERROR_TYPES.each do |type|
        result = engine.detect_error(**base_error_args.merge(error_type: type))
        expect(result).not_to be_nil
      end
    end
  end

  describe '#trace_error' do
    let(:err) { add_error }

    it 'creates a CausalTrace and links it to the error' do
      steps = [{ phase: :prediction_engine, description: 'Overconfident prior' }]
      trace = engine.trace_error(error_id: err.id, steps: steps, root_cause: :bad_prior, confidence: 0.7)
      expect(trace).to be_a(Legion::Extensions::CognitiveDebugging::Helpers::CausalTrace)
      expect(err.trace_ids).to include(trace.id)
      expect(err.status).to eq(:traced)
    end

    it 'returns nil for unknown error_id' do
      result = engine.trace_error(error_id: 'nope', steps: [], root_cause: :unknown, confidence: 0.5)
      expect(result).to be_nil
    end

    it 'stores the trace in the engine' do
      steps = [{ phase: :tick, description: 'step 1' }]
      trace = engine.trace_error(error_id: err.id, steps: steps, root_cause: :loop, confidence: 0.5)
      expect(engine.traces[trace.id]).to be(trace)
    end

    it 'builds steps correctly' do
      steps = [
        { phase: :emotional_evaluation, description: 'First step' },
        { phase: :memory_retrieval,     description: 'Second step' }
      ]
      trace = engine.trace_error(error_id: err.id, steps: steps, root_cause: :bias, confidence: 0.8)
      expect(trace.depth).to eq(2)
    end
  end

  describe '#propose_correction' do
    let(:err) { add_error }

    it 'creates a Correction and links it to the error' do
      correction = engine.propose_correction(error_id: err.id, strategy: :retrace,
                                             description: 'Retrace reasoning path')
      expect(correction).to be_a(Legion::Extensions::CognitiveDebugging::Helpers::Correction)
      expect(err.correction_ids).to include(correction.id)
      expect(err.status).to eq(:correcting)
    end

    it 'returns nil for invalid strategy' do
      result = engine.propose_correction(error_id: err.id, strategy: :not_a_strategy, description: 'x')
      expect(result).to be_nil
    end

    it 'returns nil for unknown error_id' do
      result = engine.propose_correction(error_id: 'nope', strategy: :retrace, description: 'x')
      expect(result).to be_nil
    end

    it 'stores correction in engine' do
      correction = engine.propose_correction(error_id: err.id, strategy: :reframe, description: 'reframe it')
      expect(engine.corrections[correction.id]).to be(correction)
    end
  end

  describe '#apply_correction' do
    it 'marks correction as applied' do
      err = add_error
      correction = engine.propose_correction(error_id: err.id, strategy: :retrace, description: 'x')
      engine.apply_correction(correction_id: correction.id)
      expect(correction.applied).to be true
    end

    it 'returns nil for unknown correction_id' do
      expect(engine.apply_correction(correction_id: 'nope')).to be_nil
    end
  end

  describe '#measure_correction' do
    it 'sets effectiveness on the correction' do
      err = add_error
      correction = engine.propose_correction(error_id: err.id, strategy: :retrace, description: 'x')
      engine.measure_correction(correction_id: correction.id, effectiveness: 0.85)
      expect(correction.effectiveness).to eq(0.85)
    end

    it 'returns nil for unknown correction_id' do
      expect(engine.measure_correction(correction_id: 'nope', effectiveness: 0.5)).to be_nil
    end
  end

  describe '#resolve_error' do
    it 'resolves the error' do
      err = add_error
      engine.resolve_error(error_id: err.id)
      expect(err.status).to eq(:resolved)
    end

    it 'returns nil for unknown error_id' do
      expect(engine.resolve_error(error_id: 'nope')).to be_nil
    end
  end

  describe '#active_errors' do
    it 'returns errors that are not resolved' do
      e1 = add_error
      e2 = add_error(error_type: :circular_logic)
      engine.resolve_error(error_id: e1.id)
      active = engine.active_errors
      expect(active).to include(e2)
      expect(active).not_to include(e1)
    end
  end

  describe '#resolved_errors' do
    it 'returns only resolved errors' do
      e1 = add_error
      add_error(error_type: :circular_logic)
      engine.resolve_error(error_id: e1.id)
      expect(engine.resolved_errors).to contain_exactly(e1)
    end
  end

  describe '#errors_by_type' do
    it 'returns a tally hash by error_type' do
      add_error(error_type: :inconsistency)
      add_error(error_type: :inconsistency)
      add_error(error_type: :overconfidence)
      tally = engine.errors_by_type
      expect(tally[:inconsistency]).to eq(2)
      expect(tally[:overconfidence]).to eq(1)
    end
  end

  describe '#errors_by_phase' do
    it 'returns a tally hash by source_phase' do
      add_error(source_phase: :prediction_engine)
      add_error(source_phase: :prediction_engine)
      add_error(source_phase: :emotional_evaluation)
      tally = engine.errors_by_phase
      expect(tally[:prediction_engine]).to eq(2)
      expect(tally[:emotional_evaluation]).to eq(1)
    end
  end

  describe '#most_common_error_type' do
    it 'returns nil when no errors' do
      expect(engine.most_common_error_type).to be_nil
    end

    it 'returns the most frequent error type' do
      add_error(error_type: :overconfidence)
      add_error(error_type: :overconfidence)
      add_error(error_type: :inconsistency)
      expect(engine.most_common_error_type).to eq(:overconfidence)
    end
  end

  describe '#most_effective_strategy' do
    it 'returns nil when no measured corrections' do
      expect(engine.most_effective_strategy).to be_nil
    end

    it 'returns the strategy with highest average effectiveness' do
      err = add_error
      c1 = engine.propose_correction(error_id: err.id, strategy: :retrace, description: 'x')
      c2 = engine.propose_correction(error_id: err.id, strategy: :reframe, description: 'y')
      engine.measure_correction(correction_id: c1.id, effectiveness: 0.4)
      engine.measure_correction(correction_id: c2.id, effectiveness: 0.9)
      expect(engine.most_effective_strategy).to eq(:reframe)
    end
  end

  describe '#error_rate_by_phase' do
    it 'is an alias for errors_by_phase' do
      add_error(source_phase: :tick)
      expect(engine.error_rate_by_phase).to eq(engine.errors_by_phase)
    end
  end

  describe '#correction_success_rate' do
    it 'returns 0.0 when no corrections applied' do
      expect(engine.correction_success_rate).to eq(0.0)
    end

    it 'returns 0.0 when applied but none measured' do
      err = add_error
      c = engine.propose_correction(error_id: err.id, strategy: :retrace, description: 'x')
      engine.apply_correction(correction_id: c.id)
      expect(engine.correction_success_rate).to eq(0.0)
    end

    it 'calculates the ratio of effective corrections' do
      err = add_error
      c1 = engine.propose_correction(error_id: err.id, strategy: :retrace, description: 'a')
      c2 = engine.propose_correction(error_id: err.id, strategy: :reframe, description: 'b')
      engine.apply_correction(correction_id: c1.id)
      engine.apply_correction(correction_id: c2.id)
      engine.measure_correction(correction_id: c1.id, effectiveness: 0.8)
      engine.measure_correction(correction_id: c2.id, effectiveness: 0.3)
      expect(engine.correction_success_rate).to eq(0.5)
    end
  end

  describe '#debugging_report' do
    it 'returns a hash with expected keys' do
      report = engine.debugging_report
      expect(report).to include(
        :total_errors, :active_errors, :resolved_errors,
        :total_traces, :total_corrections,
        :correction_success_rate, :most_common_error_type,
        :most_effective_strategy, :errors_by_type, :error_rate_by_phase
      )
    end

    it 'reflects current state' do
      add_error
      report = engine.debugging_report
      expect(report[:total_errors]).to eq(1)
      expect(report[:active_errors]).to eq(1)
    end
  end

  describe '#to_h' do
    it 'returns nested hashes for errors, traces, corrections' do
      err = add_error
      steps = [{ phase: :tick, description: 'step' }]
      engine.trace_error(error_id: err.id, steps: steps, root_cause: :bias, confidence: 0.6)
      engine.propose_correction(error_id: err.id, strategy: :retrace, description: 'x')
      h = engine.to_h
      expect(h[:errors]).to be_a(Hash)
      expect(h[:traces]).to be_a(Hash)
      expect(h[:corrections]).to be_a(Hash)
      expect(h[:errors][err.id]).to include(:error_type)
    end
  end
end
