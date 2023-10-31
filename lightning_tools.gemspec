require_relative 'lib/lightning_tools/version'

Gem::Specification.new do |spec|
  spec.name          = "lightning-tools"
  spec.version       = LightningTools::VERSION
  spec.authors       = ["Alby Contributors"]
  spec.email         = ["hello@getalby.com"]

  spec.summary       = %q{Lightning tools implementation for ruby}
  spec.description   = %q{Collection of helpful building blocks and tools to develop Bitcoin Lightning web apps.}
  spec.homepage      = "https://github.com/getAlby/ruby-lightning-tools"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/getAlby/ruby-lightning-tools"
  # spec.metadata['funding'] = 'lightning:hello@getalby.com'
  spec.files         = Dir['lib/**/*.rb']

  spec.add_runtime_dependency 'json', '~> 2.6'
  spec.add_runtime_dependency 'http', '~> 5.1'
  spec.add_runtime_dependency 'bech32', '~> 1.1'
  spec.add_runtime_dependency 'redis', '~> 5.0'
end
