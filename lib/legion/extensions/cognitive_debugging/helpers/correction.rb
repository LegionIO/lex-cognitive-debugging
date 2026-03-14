# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveDebugging
      module Helpers
        class Correction
          attr_reader :id, :error_id, :strategy, :description, :applied, :effectiveness

          def initialize(error_id:, strategy:, description:)
            @id            = SecureRandom.uuid
            @error_id      = error_id
            @strategy      = strategy
            @description   = description
            @applied       = false
            @effectiveness = nil
          end

          def apply!
            @applied = true
            self
          end

          def measure_effectiveness!(score)
            @effectiveness = score.clamp(0.0, 1.0).round(10)
            self
          end

          def effective?
            return false if @effectiveness.nil?

            @effectiveness >= 0.6
          end

          def to_h
            {
              id:            @id,
              error_id:      @error_id,
              strategy:      @strategy,
              description:   @description,
              applied:       @applied,
              effectiveness: @effectiveness,
              effective:     effective?
            }
          end
        end
      end
    end
  end
end
