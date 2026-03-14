# frozen_string_literal: true

require 'legion/extensions/cognitive_debugging/version'
require 'legion/extensions/cognitive_debugging/helpers/constants'
require 'legion/extensions/cognitive_debugging/helpers/reasoning_error'
require 'legion/extensions/cognitive_debugging/helpers/causal_trace'
require 'legion/extensions/cognitive_debugging/helpers/correction'
require 'legion/extensions/cognitive_debugging/helpers/debugging_engine'
require 'legion/extensions/cognitive_debugging/runners/cognitive_debugging'

module Legion
  module Extensions
    module CognitiveDebugging
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
