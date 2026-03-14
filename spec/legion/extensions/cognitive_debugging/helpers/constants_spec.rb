# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDebugging::Helpers::Constants do
  describe 'ERROR_TYPES' do
    it 'contains 8 error types' do
      expect(described_class::ERROR_TYPES.size).to eq(8)
    end

    it 'includes :inconsistency' do
      expect(described_class::ERROR_TYPES).to include(:inconsistency)
    end

    it 'includes :circular_logic' do
      expect(described_class::ERROR_TYPES).to include(:circular_logic)
    end

    it 'includes :overconfidence' do
      expect(described_class::ERROR_TYPES).to include(:overconfidence)
    end

    it 'includes :confirmation_bias' do
      expect(described_class::ERROR_TYPES).to include(:confirmation_bias)
    end

    it 'is frozen' do
      expect(described_class::ERROR_TYPES).to be_frozen
    end
  end

  describe 'CORRECTION_STRATEGIES' do
    it 'contains 7 strategies' do
      expect(described_class::CORRECTION_STRATEGIES.size).to eq(7)
    end

    it 'includes :retrace' do
      expect(described_class::CORRECTION_STRATEGIES).to include(:retrace)
    end

    it 'includes :devil_advocate' do
      expect(described_class::CORRECTION_STRATEGIES).to include(:devil_advocate)
    end

    it 'is frozen' do
      expect(described_class::CORRECTION_STRATEGIES).to be_frozen
    end
  end

  describe 'capacity limits' do
    it 'sets MAX_ERRORS to 300' do
      expect(described_class::MAX_ERRORS).to eq(300)
    end

    it 'sets MAX_TRACES to 500' do
      expect(described_class::MAX_TRACES).to eq(500)
    end

    it 'sets MAX_CORRECTIONS to 200' do
      expect(described_class::MAX_CORRECTIONS).to eq(200)
    end
  end

  describe '.severity_label' do
    it 'returns :trivial for 0.0' do
      expect(described_class.severity_label(0.0)).to eq(:trivial)
    end

    it 'returns :trivial for 0.1' do
      expect(described_class.severity_label(0.1)).to eq(:trivial)
    end

    it 'returns :minor for 0.2' do
      expect(described_class.severity_label(0.2)).to eq(:minor)
    end

    it 'returns :moderate for 0.4' do
      expect(described_class.severity_label(0.4)).to eq(:moderate)
    end

    it 'returns :major for 0.6' do
      expect(described_class.severity_label(0.6)).to eq(:major)
    end

    it 'returns :critical for 0.8' do
      expect(described_class.severity_label(0.8)).to eq(:critical)
    end

    it 'returns :critical for 1.0' do
      expect(described_class.severity_label(1.0)).to eq(:critical)
    end
  end

  describe 'STATUS_LABELS' do
    it 'contains expected statuses' do
      expect(described_class::STATUS_LABELS).to include(:detected, :traced, :correcting, :resolved, :unresolvable)
    end
  end
end
