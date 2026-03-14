# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveDebugging
      module Helpers
        class ReasoningError
          attr_reader :id, :error_type, :description, :severity, :source_phase,
                      :confidence_at_detection, :trace_ids, :correction_ids,
                      :created_at, :resolved_at, :status

          def initialize(error_type:, description:, severity:, source_phase:, confidence_at_detection:)
            @id                       = SecureRandom.uuid
            @error_type               = error_type
            @description              = description
            @severity                 = severity.clamp(0.0, 1.0).round(10)
            @source_phase             = source_phase
            @confidence_at_detection  = confidence_at_detection.clamp(0.0, 1.0).round(10)
            @status                   = :detected
            @trace_ids                = []
            @correction_ids           = []
            @created_at               = Time.now.utc
            @resolved_at              = nil
          end

          def detect!
            @status = :detected
            self
          end

          def trace!(trace_id)
            @trace_ids << trace_id
            @status = :traced
            self
          end

          def correct!(correction_id)
            @correction_ids << correction_id
            @status = :correcting
            self
          end

          def resolve!
            @status      = :resolved
            @resolved_at = Time.now.utc
            self
          end

          def mark_unresolvable!
            @status      = :unresolvable
            @resolved_at = Time.now.utc
            self
          end

          def severe?
            @severity >= 0.7
          end

          def resolved?
            @status == :resolved
          end

          def active?
            !%i[resolved unresolvable].include?(@status)
          end

          def severity_label
            Constants.severity_label(@severity)
          end

          def to_h
            {
              id:                      @id,
              error_type:              @error_type,
              description:             @description,
              severity:                @severity,
              severity_label:          severity_label,
              source_phase:            @source_phase,
              confidence_at_detection: @confidence_at_detection,
              status:                  @status,
              trace_ids:               @trace_ids.dup,
              correction_ids:          @correction_ids.dup,
              created_at:              @created_at,
              resolved_at:             @resolved_at
            }
          end
        end
      end
    end
  end
end
