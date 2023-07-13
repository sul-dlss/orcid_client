# frozen_string_literal: true

require "active_support/core_ext/module/delegation"
require "active_support/core_ext/hash/indifferent_access"

require "faraday"
require "faraday/retry"
require "oauth2"
require "singleton"
require "zeitwerk"

# Load the gem's internal dependencies: use Zeitwerk instead of needing to manually require classes
Zeitwerk::Loader.for_gem.setup

# Client for interacting with ORCID API
class SulOrcidClient
  include Singleton

  class InvalidTokenError < StandardError; end

  class << self
    # @param client_id [String] the client identifier registered with Orcid
    # @param client_secret [String] the client secret to authenticate with Orcid
    # @param base_url [String] the base URL for the API
    # @param base_public_url [String] the base public URL for the API
    # @param base_auth_url [String] the base authorization URL for the API
    def configure(client_id:, client_secret:, base_url:, base_public_url:, base_auth_url:)
      instance.base_url = base_url
      instance.base_public_url = base_public_url
      instance.client_id = client_id
      instance.client_secret = client_secret
      instance.base_auth_url = base_auth_url
      self
    end

    delegate :fetch_works, :fetch_work, :fetch_name, :search, :add_work, :update_work, :delete_work, to: :instance
  end

  attr_accessor :base_url, :base_public_url, :base_auth_url, :client_id, :client_secret

  # Fetch the works for a researcher.
  # Model for the response: https://pub.orcid.org/v3.0/#!/Development_Public_API_v3.0/viewWorksv3
  # @param [string] ORCID ID for the researcher
  # @return [Hash]
  def fetch_works(orcidid:)
    get("/v3.0/#{base_orcidid(orcidid)}/works")
  end

  # Fetch the details for a work
  def fetch_work(orcidid:, put_code:)
    get("/v3.0/#{base_orcidid(orcidid)}/work/#{put_code}")
  end

  # Fetches the name for a user given an orcidid
  def fetch_name(orcidid:)
    match = /[0-9xX]{4}-[0-9xX]{4}-[0-9xX]{4}-[0-9xX]{4}/.match(orcidid)
    raise "invalid orcidid provided" unless match

    response = public_conn.get("/v3.0/#{match[0]&.upcase}/personal-details")
    case response.status
    when 200
      resp_json = JSON.parse(response.body)
      [resp_json.dig("name", "given-names", "value"),
        resp_json.dig("name", "family-name", "value")]
    else
      raise "ORCID.org API returned #{response.status} (#{response.body}) for: #{orcidid}"
    end
  end

  # Run a generalized search query against ORCID
  # see https://info.orcid.org/documentation/api-tutorials/api-tutorial-searching-the-orcid-registry
  # @param [query] query to pass to ORCID
  # @param [expanded] set to true or false (defaults to false) to indicate an expanded query results (see ORCID docs)
  def search(query:, expanded: false)
    if expanded
      search_method = "expanded-search"
      response_name = "expanded-result"
    else
      search_method = "search"
      response_name = "result"
    end

    # this is the maximum number of rows ORCID allows in their response currently
    max_num_returned = 1000
    total_response = get("/v3.0/#{search_method}/?q=#{query}&rows=#{max_num_returned}")
    num_results = total_response["num-found"]

    return total_response if num_results <= max_num_returned

    num_pages = (num_results / max_num_returned.to_f).ceil

    # we already have page 1 of the results
    (1..num_pages - 1).each do |page_num|
      response = get("/v3.0/#{search_method}/?q=#{query}&start=#{(page_num * max_num_returned) + 1}&rows=#{max_num_returned}")
      total_response[response_name] += response[response_name]
    end

    total_response
  end

  # Add a new work for a researcher.
  # @param [string] ORCID ID for the researcher
  # @param [Hash] work in correct data structure for ORCID work
  # @param [string] access token
  # @return [string] put-code
  def add_work(orcidid:, work:, token:)
    response = conn_with_token(token).post("/v3.0/#{base_orcidid(orcidid)}/work",
      work.to_json,
      "Content-Type" => "application/json")

    case response.status
    when 201
      response["Location"].match(%r{work/(\d+)})[1]
    when 401
      raise InvalidTokenError,
        "Invalid token for #{orcidid} - ORCID.org API returned #{response.status} (#{response.body})"
    when 409
      match = response.body.match(/put-code (\d+)\./)
      raise "ORCID.org API returned a 409, but could not find put-code" unless match

      match[1]
    else
      raise "ORCID.org API returned #{response.status} (#{response.body}) for: #{work.to_json}"
    end
  end

  # Update an existing work for a researcher.
  # @param [String] orcidid an ORCiD ID for the researcher
  # @param [Hash] work a work in correct data structure for ORCID work
  # @param [String] token an ORCiD API access token
  # @param [String] put_code the PUT code
  # @return [Boolean] true if update succeeded
  # @raise [RuntimeError] if the API response status is not successful
  def update_work(orcidid:, work:, token:, put_code:)
    response = conn_with_token(token).put("/v3.0/#{base_orcidid(orcidid)}/work/#{put_code}",
      work.merge({"put-code" => put_code}).to_json,
      "Content-Type" => "application/vnd.orcid+json")

    raise "ORCID.org API returned #{response.status} when updating #{put_code} for #{orcidid}" unless response.status == 200
    true
  end

  # Delete a work
  # @param [string] ORCID ID for the researcher
  # @param [string] put-code
  # @param [string] access token
  # @return [boolean] true if delete succeeded
  def delete_work(orcidid:, put_code:, token:)
    response = conn_with_token(token).delete("/v3.0/#{base_orcidid(orcidid)}/work/#{put_code}")

    case response.status
    when 204
      true
    when 404
      false
    else
      raise "ORCID.org API returned #{response.status} when deleting #{put_code} for #{orcidid}"
    end
  end

  private

  def get(url)
    response = conn.get(url)
    raise "ORCID.org API returned #{response.status}" if response.status != 200

    JSON.parse(response.body).with_indifferent_access
  end

  def client_token
    client = OAuth2::Client.new(client_id, client_secret, site: base_auth_url)
    token = client.client_credentials.get_token({scope: "/read-public"})
    token.token
  end

  # @return [Faraday::Connection]
  def conn
    @conn ||= conn_with_token(client_token)
  end

  # @return [Faraday::Connection]
  def public_conn
    conn = Faraday.new(url: base_public_url) do |faraday|
      faraday.request :retry, max: 5,
        interval: 0.5,
        interval_randomness: 0.5,
        backoff_factor: 2
    end
    conn.options.timeout = 500
    conn.options.open_timeout = 10
    conn.headers = headers
    conn
  end

  # @return [Faraday::Connection]
  def conn_with_token(token)
    conn = Faraday.new(url: base_url) do |faraday|
      faraday.request :retry, max: 3,
        interval: 0.5,
        interval_randomness: 0.5,
        backoff_factor: 2
    end
    conn.options.timeout = 500
    conn.options.open_timeout = 10
    conn.headers = headers
    conn.headers[:authorization] = "Bearer #{token}"
    conn
  end

  def headers
    {
      "Accept" => "application/json",
      "User-Agent" => "stanford-library-sul-pub"
    }
  end

  # Extract the ID part from an ORCID ID.
  # For example, 0000-0003-3437-349X from https://sandbox.orcid.org/0000-0003-3437-349X.
  # @param [string] orcidid
  # @return [string] base of ORCID ID
  def base_orcidid(orcidid)
    orcidid[-19, 19]
  end
end
