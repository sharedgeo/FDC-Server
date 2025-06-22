# frozen_string_literal: true

class JwtDebuggerController < ApplicationController
  def debug
    token = token_from_header
    unless token
      message = 'No token provided in Authorization header.'
      Rails.logger.warn(message)
      return render json: { status: 'invalid', reason: message }, status: :bad_request
    end

    Rails.logger.info "Received token for debugging: #{token}"

    begin
      decoded_token = JsonWebToken.verify(token)
      message = 'Token is valid.'
      Rails.logger.info message
      Rails.logger.info "Payload: #{decoded_token[:payload].inspect}"
      Rails.logger.info "Header: #{decoded_token[:header].inspect}"
      render json: { status: 'valid', data: decoded_token }
    rescue StandardError => e
      Rails.logger.error("Error: #{e.message}: \n\t#{e.backtrace.join("\n\t")}")
      render json: { status: 'invalid', reason: e.message }, status: :unauthorized
    end
  end

  private

  def token_from_header
    request.headers['Authorization']&.split(' ')&.last
  end
end
