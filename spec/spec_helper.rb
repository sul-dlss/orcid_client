# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter 'spec'

  if ENV['CI']
    require 'simplecov_json_formatter'

    formatter SimpleCov::Formatter::JSONFormatter
  end
end

require 'sul_orcid_client'
require 'byebug'
require 'webmock/rspec'
require 'cocina/models'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

WebMock.enable!

# the fake client ID and secret used in spec tests for Orcid API (and used to sanitize)
FAKE_CLIENT_ID = 'abc123'
FAKE_CLIENT_SECRET = 'def456'

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.allow_http_connections_when_no_cassette = true
  c.hook_into :webmock
  c.default_cassette_options = {
    record: :once
  }
  c.configure_rspec_metadata!

  # API client_id and secret sent in authorization request
  c.filter_sensitive_data(FAKE_CLIENT_ID) do |interaction|
    token_match = interaction.request.body.match(/client_id=(.{8}-.{4}-.{4}-.{4}-.{12})/)
    token_match&.captures&.first
  end
  c.filter_sensitive_data(FAKE_CLIENT_SECRET) do |interaction|
    token_match = interaction.request.body.match(/client_secret=(.{8}-.{4}-.{4}-.{4}-.{12})/)
    token_match&.captures&.first
  end
  # API authorization access token received from authorization request
  c.filter_sensitive_data('private_access_token') do |interaction|
    token_match = interaction.response.body.match(/"access_token":"(.*?)"/)
    token_match&.captures&.first
  end
  # MaIS API authorization access token sent in later requests
  c.filter_sensitive_data('private_bearer_token') do |interaction|
    auth = interaction.request.headers['Authorization']
    if auth.is_a? Array
      bearer = auth.grep(/bearer/i).first
      bearer&.gsub(/bearer /i, '')
    end
  end
end
