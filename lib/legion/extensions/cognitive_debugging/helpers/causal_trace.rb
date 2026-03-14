# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveDebugging
      module Helpers
        class CausalTrace
          attr_reader :id, :error_id, :steps, :root_cause, :confidence

          def initialize(error_id:, root_cause:, confidence:)
            @id         = SecureRandom.uuid
            @error_id   = error_id
            @root_cause = root_cause
            @confidence = confidence.clamp(0.0, 1.0).round(10)
            @steps      = []
          end

          def add_step!(phase:, description:)
            @steps << {
              phase:       phase,
              description: description,
              timestamp:   Time.now.utc
            }
            self
          end

          def depth
            @steps.size
          end

          def to_h
            {
              id:         @id,
              error_id:   @error_id,
              steps:      @steps.map(&:dup),
              root_cause: @root_cause,
              confidence: @confidence,
              depth:      depth
            }
          end
        end
      end
    end
  end
end
