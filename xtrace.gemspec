# frozen_string_literal: true

require_relative 'lib/xtrace/version'

Gem::Specification.new do |spec|
  spec.name = 'xtrace'
  spec.version = Xtrace::VERSION
  spec.authors = ['llk23r']
  # spec.email = ["mail.acharyarahul.now@gmail.com"]

  spec.summary = 'Trace your rails code callstack'
  spec.description = 'View the entire flow of a program control in the rails application'
  # spec.homepage = "TODO: Put your gem's website or public repo URL here."
  spec.required_ruby_version = '>= 2.6.0'

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.end_with?('.gem') ||  # Exclude .gem files
        f.start_with?('bin/', 'test/', 'spec/', 'features/', '.git', '.circleci', 'appveyor', 'Gemfile')
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
