# frozen_string_literal: true

require 'legion/extensions/cognitive_debugging/helpers/constants'
require 'legion/extensions/cognitive_debugging/helpers/reasoning_error'
require 'legion/extensions/cognitive_debugging/helpers/causal_trace'
require 'legion/extensions/cognitive_debugging/helpers/correction'
require 'legion/extensions/cognitive_debugging/helpers/debugging_engine'
require 'legion/extensions/cognitive_debugging/runners/cognitive_debugging'

module Legion
  module Extensions
    module CognitiveDebugging
      class Client
        include Runners::CognitiveDebugging

        def initialize(engine: nil, **)
          @engine = engine || Helpers::DebuggingEngine.new
        end

        private

        attr_reader :engine
      end
    end
  end
end
