# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "sul_orcid_client/version"

Gem::Specification.new do |spec|
  spec.name = "sul_orcid_client"
  spec.version = SulOrcidClient::VERSION
  spec.authors = ["Peter Mangiafico", "Justin Littman"]
  spec.email = ["pmangiafico@stanford.edu", "jlittman@stanford.edu"]

  spec.summary = "Interface for interacting with the ORCID API."
  spec.description = "This provides API interaction with the ORCID API"
  spec.homepage = "https://github.com/sul-dlss/sul_orcid_client"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/sul-dlss/sul_orcid_client"
  spec.metadata["changelog_uri"] = "https://github.com/sul-dlss/sul_orcid_client/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", ">= 4.2", "< 8"
  spec.add_dependency "faraday"
  spec.add_dependency "faraday-retry"
  spec.add_dependency "oauth2"
  spec.add_dependency "zeitwerk"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "standard", "~> 1.29.0" # Pinning until https://github.com/standardrb/standard-custom/pull/5
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"
end
