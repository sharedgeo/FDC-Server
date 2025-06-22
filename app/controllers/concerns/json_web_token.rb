# frozen_string_literal: true

require 'net/http'
require 'uri'

module JsonWebToken
  # Verify Issuer and Audience
  VALIDATION_OPTIONS = {
    algorithm: 'RS256', # The algorithm used to sign the token
    verify_iss: true,
    verify_aud: true,
    iss: ENV['OIDC_ISSUER_URL'],
    aud: ENV['OIDC_API_AUDIENCE']
  }.freeze

  # Main method to decode and verify the token
  def self.verify(token)
    payload, header = JWT.decode(token, nil, true, validation_options_with_jwks)

    { payload: payload, header: header }
  rescue JWT::DecodeError => e
    # Handle specific errors for better client feedback
    raise "Invalid token: #{e.message}"
  end

  # Build the validation options hash, dynamically adding the jwks loader
  def self.validation_options_with_jwks
    VALIDATION_OPTIONS.merge(jwks: jwks_loader)
  end

  # The jwks_loader is a lambda that the JWT gem will use to fetch keys.
  # The `invalidate` parameter allows the gem to request a refetch if a key is not found.
  def self.jwks_loader
    lambda do |options|
      # TODO: Cache this lookup
      # The `invalidate` parameter is true if the kid was not found in the cache
      # and a refetch should be attempted.
      @jwks = nil if options[:invalidate]
      @jwks ||= fetch_jwks
    end
  end

  # Fetches the JWKS from the OIDC provider.
  def self.fetch_jwks
    jwks_uri = URI(ENV['OIDC_JWKS_URL'])
    response = Net::HTTP.get(jwks_uri)
    JSON.parse(response)
  end
end
