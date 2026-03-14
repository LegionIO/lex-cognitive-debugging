# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_debugging/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-debugging'
  spec.version       = Legion::Extensions::CognitiveDebugging::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Cognitive Debugging'
  spec.description   = 'Self-debugging system for cognitive processes in LegionIO — detects reasoning errors, ' \
                       'traces causal chains, and applies corrective strategies'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-debugging'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-cognitive-debugging'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-cognitive-debugging'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-cognitive-debugging'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-cognitive-debugging/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-cognitive-debugging.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
end
