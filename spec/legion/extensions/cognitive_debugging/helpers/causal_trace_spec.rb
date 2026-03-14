# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDebugging::Helpers::CausalTrace do
  let(:trace) do
    described_class.new(error_id: 'error-uuid', root_cause: :faulty_premise, confidence: 0.8)
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(trace.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets error_id' do
      expect(trace.error_id).to eq('error-uuid')
    end

    it 'sets root_cause' do
      expect(trace.root_cause).to eq(:faulty_premise)
    end

    it 'clamps confidence to [0, 1]' do
      t = described_class.new(error_id: 'x', root_cause: :y, confidence: 1.5)
      expect(t.confidence).to eq(1.0)
    end

    it 'initializes empty steps' do
      expect(trace.steps).to be_empty
    end
  end

  describe '#add_step!' do
    it 'appends a step with phase, description, and timestamp' do
      trace.add_step!(phase: :emotional_evaluation, description: 'Urgency spike caused premature conclusion')
      expect(trace.steps.size).to eq(1)
      step = trace.steps.first
      expect(step[:phase]).to eq(:emotional_evaluation)
      expect(step[:description]).to eq('Urgency spike caused premature conclusion')
      expect(step[:timestamp]).to be_a(Time)
    end

    it 'returns self for chaining' do
      result = trace.add_step!(phase: :tick, description: 'step 1')
      expect(result).to be(trace)
    end

    it 'accumulates multiple steps' do
      trace.add_step!(phase: :tick, description: 'step 1')
      trace.add_step!(phase: :memory_retrieval, description: 'step 2')
      trace.add_step!(phase: :prediction_engine, description: 'step 3')
      expect(trace.steps.size).to eq(3)
    end
  end

  describe '#depth' do
    it 'returns 0 for empty trace' do
      expect(trace.depth).to eq(0)
    end

    it 'returns step count' do
      trace.add_step!(phase: :tick, description: 'a')
      trace.add_step!(phase: :tick, description: 'b')
      expect(trace.depth).to eq(2)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      trace.add_step!(phase: :tick, description: 'step')
      h = trace.to_h
      expect(h).to include(:id, :error_id, :steps, :root_cause, :confidence, :depth)
    end

    it 'includes depth in hash' do
      trace.add_step!(phase: :tick, description: 'step')
      expect(trace.to_h[:depth]).to eq(1)
    end

    it 'returns dup of steps' do
      trace.add_step!(phase: :tick, description: 'step')
      h = trace.to_h
      expect(h[:steps]).not_to be(trace.steps)
    end
  end
end
