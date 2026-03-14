# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDebugging
      module Helpers
        module Constants
          MAX_ERRORS      = 300
          MAX_TRACES      = 500
          MAX_CORRECTIONS = 200

          ERROR_TYPES = %i[
            inconsistency
            circular_logic
            ungrounded_claim
            overconfidence
            logical_fallacy
            missing_evidence
            false_analogy
            confirmation_bias
          ].freeze

          CORRECTION_STRATEGIES = %i[
            retrace
            reframe
            weaken_confidence
            seek_evidence
            decompose
            analogize
            devil_advocate
          ].freeze

          # Range-based severity labels: 0.0..1.0 -> label
          SEVERITY_LABELS = [
            { range: (0.0...0.2), label: :trivial  },
            { range: (0.2...0.4), label: :minor    },
            { range: (0.4...0.6), label: :moderate },
            { range: (0.6...0.8), label: :major    },
            { range: (0.8..1.0),  label: :critical }
          ].freeze

          STATUS_LABELS = %i[detected traced correcting resolved unresolvable].freeze

          module_function

          def severity_label(severity)
            entry = SEVERITY_LABELS.find { |e| e[:range].cover?(severity) }
            entry ? entry[:label] : :critical
          end
        end
      end
    end
  end
end
