# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDebugging::Helpers::ReasoningError do
  let(:error) do
    described_class.new(
      error_type:              :inconsistency,
      description:             'Contradicting earlier claim',
      severity:                0.75,
      source_phase:            :prediction_engine,
      confidence_at_detection: 0.9
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(error.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets error_type' do
      expect(error.error_type).to eq(:inconsistency)
    end

    it 'sets description' do
      expect(error.description).to eq('Contradicting earlier claim')
    end

    it 'clamps severity to [0, 1]' do
      e = described_class.new(error_type: :overconfidence, description: 'x',
                              severity: 1.5, source_phase: :tick, confidence_at_detection: 0.5)
      expect(e.severity).to eq(1.0)
    end

    it 'clamps confidence_at_detection to [0, 1]' do
      e = described_class.new(error_type: :overconfidence, description: 'x',
                              severity: 0.5, source_phase: :tick, confidence_at_detection: -0.1)
      expect(e.confidence_at_detection).to eq(0.0)
    end

    it 'initializes status as :detected' do
      expect(error.status).to eq(:detected)
    end

    it 'initializes empty trace_ids' do
      expect(error.trace_ids).to be_empty
    end

    it 'initializes empty correction_ids' do
      expect(error.correction_ids).to be_empty
    end

    it 'sets created_at' do
      expect(error.created_at).to be_a(Time)
    end

    it 'initializes resolved_at as nil' do
      expect(error.resolved_at).to be_nil
    end
  end

  describe '#detect!' do
    it 'sets status to :detected' do
      error.trace!('trace-1')
      error.detect!
      expect(error.status).to eq(:detected)
    end
  end

  describe '#trace!' do
    it 'adds trace_id and sets status to :traced' do
      error.trace!('some-trace-uuid')
      expect(error.trace_ids).to include('some-trace-uuid')
      expect(error.status).to eq(:traced)
    end

    it 'accumulates multiple trace_ids' do
      error.trace!('trace-1')
      error.trace!('trace-2')
      expect(error.trace_ids.size).to eq(2)
    end
  end

  describe '#correct!' do
    it 'adds correction_id and sets status to :correcting' do
      error.correct!('correction-uuid')
      expect(error.correction_ids).to include('correction-uuid')
      expect(error.status).to eq(:correcting)
    end
  end

  describe '#resolve!' do
    it 'sets status to :resolved and resolved_at' do
      error.resolve!
      expect(error.status).to eq(:resolved)
      expect(error.resolved_at).to be_a(Time)
    end
  end

  describe '#mark_unresolvable!' do
    it 'sets status to :unresolvable and resolved_at' do
      error.mark_unresolvable!
      expect(error.status).to eq(:unresolvable)
      expect(error.resolved_at).to be_a(Time)
    end
  end

  describe '#severe?' do
    it 'returns true when severity >= 0.7' do
      expect(error.severe?).to be true
    end

    it 'returns false when severity < 0.7' do
      e = described_class.new(error_type: :minor_type, description: 'x',
                              severity: 0.5, source_phase: :tick, confidence_at_detection: 0.5)
      expect(e.severe?).to be false
    end
  end

  describe '#resolved?' do
    it 'returns false for a new error' do
      expect(error.resolved?).to be false
    end

    it 'returns true after resolve!' do
      error.resolve!
      expect(error.resolved?).to be true
    end
  end

  describe '#active?' do
    it 'returns true for :detected status' do
      expect(error.active?).to be true
    end

    it 'returns false after resolved' do
      error.resolve!
      expect(error.active?).to be false
    end

    it 'returns false after mark_unresolvable!' do
      error.mark_unresolvable!
      expect(error.active?).to be false
    end
  end

  describe '#severity_label' do
    it 'returns :major for severity 0.75' do
      expect(error.severity_label).to eq(:major)
    end
  end

  describe '#to_h' do
    it 'returns a hash with expected keys' do
      h = error.to_h
      expect(h).to include(:id, :error_type, :description, :severity, :severity_label,
                           :source_phase, :confidence_at_detection, :status,
                           :trace_ids, :correction_ids, :created_at, :resolved_at)
    end

    it 'returns dup of trace_ids array' do
      h = error.to_h
      expect(h[:trace_ids]).not_to be(error.trace_ids)
    end
  end
end
