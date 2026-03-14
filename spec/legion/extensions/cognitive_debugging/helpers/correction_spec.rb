# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveDebugging::Helpers::Correction do
  let(:correction) do
    described_class.new(error_id: 'error-uuid', strategy: :retrace, description: 'Re-examine assumptions')
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(correction.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets error_id' do
      expect(correction.error_id).to eq('error-uuid')
    end

    it 'sets strategy' do
      expect(correction.strategy).to eq(:retrace)
    end

    it 'sets description' do
      expect(correction.description).to eq('Re-examine assumptions')
    end

    it 'initializes applied as false' do
      expect(correction.applied).to be false
    end

    it 'initializes effectiveness as nil' do
      expect(correction.effectiveness).to be_nil
    end
  end

  describe '#apply!' do
    it 'sets applied to true' do
      correction.apply!
      expect(correction.applied).to be true
    end

    it 'returns self for chaining' do
      expect(correction.apply!).to be(correction)
    end
  end

  describe '#measure_effectiveness!' do
    it 'sets effectiveness' do
      correction.measure_effectiveness!(0.8)
      expect(correction.effectiveness).to eq(0.8)
    end

    it 'clamps effectiveness to [0, 1]' do
      correction.measure_effectiveness!(1.5)
      expect(correction.effectiveness).to eq(1.0)
    end

    it 'clamps negative values to 0.0' do
      correction.measure_effectiveness!(-0.2)
      expect(correction.effectiveness).to eq(0.0)
    end

    it 'returns self for chaining' do
      expect(correction.measure_effectiveness!(0.7)).to be(correction)
    end
  end

  describe '#effective?' do
    it 'returns false when effectiveness is nil' do
      expect(correction.effective?).to be false
    end

    it 'returns true when effectiveness >= 0.6' do
      correction.measure_effectiveness!(0.6)
      expect(correction.effective?).to be true
    end

    it 'returns true for high effectiveness' do
      correction.measure_effectiveness!(0.9)
      expect(correction.effective?).to be true
    end

    it 'returns false when effectiveness < 0.6' do
      correction.measure_effectiveness!(0.5)
      expect(correction.effective?).to be false
    end
  end

  describe '#to_h' do
    it 'includes expected keys' do
      h = correction.to_h
      expect(h).to include(:id, :error_id, :strategy, :description, :applied, :effectiveness, :effective)
    end

    it 'reflects effective? result' do
      correction.measure_effectiveness!(0.7)
      expect(correction.to_h[:effective]).to be true
    end
  end
end
