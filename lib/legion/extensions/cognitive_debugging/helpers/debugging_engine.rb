# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDebugging
      module Helpers
        class DebuggingEngine
          attr_reader :errors, :traces, :corrections

          def initialize
            @errors      = {}
            @traces      = {}
            @corrections = {}
          end

          def detect_error(error_type:, description:, severity:, source_phase:, confidence_at_detection:)
            return nil unless Constants::ERROR_TYPES.include?(error_type)
            return nil if @errors.size >= Constants::MAX_ERRORS

            err = ReasoningError.new(
              error_type:              error_type,
              description:             description,
              severity:                severity,
              source_phase:            source_phase,
              confidence_at_detection: confidence_at_detection
            )
            @errors[err.id] = err
            err
          end

          def trace_error(error_id:, steps:, root_cause:, confidence:)
            err = @errors[error_id]
            return nil unless err
            return nil if @traces.size >= Constants::MAX_TRACES

            trace = CausalTrace.new(error_id: error_id, root_cause: root_cause, confidence: confidence)
            steps.each { |s| trace.add_step!(phase: s.fetch(:phase), description: s.fetch(:description)) }
            @traces[trace.id] = trace
            err.trace!(trace.id)
            trace
          end

          def propose_correction(error_id:, strategy:, description:)
            err = @errors[error_id]
            return nil unless err
            return nil unless Constants::CORRECTION_STRATEGIES.include?(strategy)
            return nil if @corrections.size >= Constants::MAX_CORRECTIONS

            correction = Correction.new(error_id: error_id, strategy: strategy, description: description)
            @corrections[correction.id] = correction
            err.correct!(correction.id)
            correction
          end

          def apply_correction(correction_id:)
            correction = @corrections[correction_id]
            return nil unless correction

            correction.apply!
          end

          def measure_correction(correction_id:, effectiveness:)
            correction = @corrections[correction_id]
            return nil unless correction

            correction.measure_effectiveness!(effectiveness)
          end

          def resolve_error(error_id:)
            err = @errors[error_id]
            return nil unless err

            err.resolve!
          end

          def active_errors
            @errors.values.select(&:active?)
          end

          def resolved_errors
            @errors.values.select(&:resolved?)
          end

          def errors_by_type
            @errors.values.group_by(&:error_type).transform_values(&:length)
          end

          def errors_by_phase
            @errors.values.group_by(&:source_phase).transform_values(&:length)
          end

          def most_common_error_type
            tally = errors_by_type
            return nil if tally.empty?

            tally.max_by { |_, count| count }&.first
          end

          def most_effective_strategy
            applied = @corrections.values.select { |c| !c.effectiveness.nil? }
            return nil if applied.empty?

            by_strategy = applied.group_by(&:strategy)
            best = by_strategy.max_by do |_, list|
              scores = list.map(&:effectiveness)
              scores.sum.round(10) / scores.size
            end
            best&.first
          end

          def error_rate_by_phase
            errors_by_phase
          end

          def correction_success_rate
            applied = @corrections.values.select(&:applied)
            return 0.0 if applied.empty?

            measured = applied.select { |c| !c.effectiveness.nil? }
            return 0.0 if measured.empty?

            effective_count = measured.count(&:effective?)
            (effective_count.to_f / measured.size).round(10)
          end

          def debugging_report
            {
              total_errors:           @errors.size,
              active_errors:          active_errors.size,
              resolved_errors:        resolved_errors.size,
              total_traces:           @traces.size,
              total_corrections:      @corrections.size,
              correction_success_rate: correction_success_rate,
              most_common_error_type: most_common_error_type,
              most_effective_strategy: most_effective_strategy,
              errors_by_type:         errors_by_type,
              error_rate_by_phase:    error_rate_by_phase
            }
          end

          def to_h
            {
              errors:      @errors.transform_values(&:to_h),
              traces:      @traces.transform_values(&:to_h),
              corrections: @corrections.transform_values(&:to_h)
            }
          end
        end
      end
    end
  end
end
