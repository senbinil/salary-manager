require "json"
require "net/http"
require "timeout"

# Minimal HTTP client for Frankfurter's public v2 rates endpoint. The client
# returns observations as provided; snapshot selection and validation belong to
# the importer so this adapter stays independent of application models.
class FrankfurterClient
  class Error < StandardError; end

  DEFAULT_BASE_URL = "https://api.frankfurter.dev"
  REQUEST_TIMEOUT = 20

  def initialize(base_url: ENV.fetch("FRANKFURTER_API_BASE_URL", DEFAULT_BASE_URL))
    @base_uri = URI.parse(base_url)
  end

  def fetch_rates(base:, from:, to:)
    uri = rates_uri(base:, from:, to:)
    response = Timeout.timeout(REQUEST_TIMEOUT) { Net::HTTP.get_response(uri) }
    status = response.code.to_i
    raise Error, "Frankfurter returned HTTP #{status}" unless status.between?(200, 299)

    rows = JSON.parse(response.body)
    raise Error, "Frankfurter returned an unexpected response" unless rows.is_a?(Array)
    raise Error, "Frankfurter returned malformed rate rows" unless rows.all? { |row| row.is_a?(Hash) }

    rows
  rescue JSON::ParserError, TypeError => error
    raise Error, "Could not parse Frankfurter response: #{error.message}"
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, Timeout::Error => error
    raise Error, "Frankfurter request failed: #{error.class}"
  end

  private

  def rates_uri(base:, from:, to:)
    uri = @base_uri + "/v2/rates"
    uri.query = URI.encode_www_form(
      base: base,
      from: from.iso8601,
      to: to.iso8601,
      expand: "providers"
    )
    uri
  end
end
