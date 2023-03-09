lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "re_sorcery/version"

Gem::Specification.new do |spec|
  spec.name          = "re_sorcery"
  spec.version       = ReSorcery::VERSION
  spec.authors       = ["Spencer Christiansen"]
  spec.email         = ["jc.spencer92@gmail.com"]

  spec.summary       = "Create resources with run-time payload type checking and link validation"
  spec.homepage      = "https://github.com/spejamchr/re_sorcery"
  spec.license       = "MIT"

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.required_ruby_version = '~> 3.1'

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/spejamchr/re_sorcery"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.3"
  spec.add_development_dependency "minitest", "~> 5.16"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 13.0"
end
