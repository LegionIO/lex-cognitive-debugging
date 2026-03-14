# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDebugging
      module Runners
        module CognitiveDebugging
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def detect_error(error_type:, description:, severity:, source_phase:, confidence_at_detection: 0.5, **)
            unless Helpers::Constants::ERROR_TYPES.include?(error_type)
              Legion::Logging.debug "[cognitive_debugging] detect_error: invalid error_type=#{error_type}"
              return { success: false, error: :invalid_error_type, valid: Helpers::Constants::ERROR_TYPES }
            end

            err = engine.detect_error(
              error_type:              error_type,
              description:             description,
              severity:                severity,
              source_phase:            source_phase,
              confidence_at_detection: confidence_at_detection
            )

            if err
              Legion::Logging.info "[cognitive_debugging] error detected: id=#{err.id[0..7]} type=#{error_type} " \
                                   "phase=#{source_phase} severity=#{err.severity_label}"
              { success: true, error_id: err.id, error_type: error_type, severity_label: err.severity_label }
            else
              Legion::Logging.warn "[cognitive_debugging] detect_error: engine returned nil (cap reached?)"
              { success: false, error: :cap_reached }
            end
          end

          def trace_error(error_id:, steps:, root_cause:, confidence: 0.5, **)
            trace = engine.trace_error(
              error_id:   error_id,
              steps:      steps,
              root_cause: root_cause,
              confidence: confidence
            )

            if trace
              Legion::Logging.info "[cognitive_debugging] error traced: error_id=#{error_id[0..7]} " \
                                   "trace_id=#{trace.id[0..7]} depth=#{trace.depth} root_cause=#{root_cause}"
              { success: true, trace_id: trace.id, depth: trace.depth, root_cause: root_cause }
            else
              Legion::Logging.debug "[cognitive_debugging] trace_error: error_id=#{error_id[0..7]} not found or cap"
              { success: false, error: :not_found_or_cap }
            end
          end

          def propose_correction(error_id:, strategy:, description:, **)
            unless Helpers::Constants::CORRECTION_STRATEGIES.include?(strategy)
              Legion::Logging.debug "[cognitive_debugging] propose_correction: invalid strategy=#{strategy}"
              return { success: false, error: :invalid_strategy, valid: Helpers::Constants::CORRECTION_STRATEGIES }
            end

            correction = engine.propose_correction(error_id: error_id, strategy: strategy, description: description)

            if correction
              Legion::Logging.info "[cognitive_debugging] correction proposed: error_id=#{error_id[0..7]} " \
                                   "correction_id=#{correction.id[0..7]} strategy=#{strategy}"
              { success: true, correction_id: correction.id, strategy: strategy }
            else
              Legion::Logging.debug "[cognitive_debugging] propose_correction: error_id=#{error_id[0..7]} not found"
              { success: false, error: :not_found }
            end
          end

          def apply_correction(correction_id:, **)
            correction = engine.apply_correction(correction_id: correction_id)

            if correction
              Legion::Logging.info "[cognitive_debugging] correction applied: id=#{correction_id[0..7]}"
              { success: true, correction_id: correction_id, applied: true }
            else
              Legion::Logging.debug "[cognitive_debugging] apply_correction: id=#{correction_id[0..7]} not found"
              { success: false, error: :not_found }
            end
          end

          def measure_correction(correction_id:, effectiveness:, **)
            correction = engine.measure_correction(correction_id: correction_id, effectiveness: effectiveness)

            if correction
              Legion::Logging.info "[cognitive_debugging] correction measured: id=#{correction_id[0..7]} " \
                                   "effectiveness=#{correction.effectiveness} effective=#{correction.effective?}"
              { success: true, correction_id: correction_id, effectiveness: correction.effectiveness,
                effective: correction.effective? }
            else
              Legion::Logging.debug "[cognitive_debugging] measure_correction: id=#{correction_id[0..7]} not found"
              { success: false, error: :not_found }
            end
          end

          def resolve_error(error_id:, **)
            err = engine.resolve_error(error_id: error_id)

            if err
              Legion::Logging.info "[cognitive_debugging] error resolved: id=#{error_id[0..7]}"
              { success: true, error_id: error_id, resolved: true }
            else
              Legion::Logging.debug "[cognitive_debugging] resolve_error: id=#{error_id[0..7]} not found"
              { success: false, error: :not_found }
            end
          end

          def active_errors(**)
            errors = engine.active_errors
            Legion::Logging.debug "[cognitive_debugging] active_errors: count=#{errors.size}"
            { success: true, errors: errors.map(&:to_h), count: errors.size }
          end

          def resolved_errors(**)
            errors = engine.resolved_errors
            Legion::Logging.debug "[cognitive_debugging] resolved_errors: count=#{errors.size}"
            { success: true, errors: errors.map(&:to_h), count: errors.size }
          end

          def errors_by_type(**)
            tally = engine.errors_by_type
            Legion::Logging.debug "[cognitive_debugging] errors_by_type: types=#{tally.keys.join(',')}"
            { success: true, tally: tally }
          end

          def errors_by_phase(**)
            tally = engine.errors_by_phase
            Legion::Logging.debug "[cognitive_debugging] errors_by_phase: phases=#{tally.keys.join(',')}"
            { success: true, tally: tally }
          end

          def most_common_error_type(**)
            type = engine.most_common_error_type
            Legion::Logging.debug "[cognitive_debugging] most_common_error_type: type=#{type}"
            { success: true, error_type: type }
          end

          def most_effective_strategy(**)
            strategy = engine.most_effective_strategy
            Legion::Logging.debug "[cognitive_debugging] most_effective_strategy: strategy=#{strategy}"
            { success: true, strategy: strategy }
          end

          def correction_success_rate(**)
            rate = engine.correction_success_rate
            Legion::Logging.debug "[cognitive_debugging] correction_success_rate: rate=#{rate}"
            { success: true, rate: rate }
          end

          def debugging_report(**)
            report = engine.debugging_report
            Legion::Logging.info "[cognitive_debugging] debugging_report: total_errors=#{report[:total_errors]} " \
                                 "active=#{report[:active_errors]}"
            { success: true, report: report }
          end

          def snapshot(**)
            data = engine.to_h
            Legion::Logging.debug "[cognitive_debugging] snapshot: errors=#{data[:errors].size} " \
                                  "traces=#{data[:traces].size} corrections=#{data[:corrections].size}"
            { success: true, snapshot: data }
          end

          private

          def engine
            @engine ||= Helpers::DebuggingEngine.new
          end
        end
      end
    end
  end
end
