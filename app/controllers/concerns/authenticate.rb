
# Authentication code share by ApplicationController and ActiveStorage::Blobs::RedirectController
# See https://guides.rubyonrails.org/active_storage_overview.html#authenticated-controllers
module Authenticate
  extend ActiveSupport::Concern

  protected

  def authenticate_request!
    render json: { status: 'error', message: 'Not Authorized' }, status: :unauthorized unless current_user
  end

  def current_user
    return @current_user if @current_user

    token = token_from_header
    return nil unless token

    begin
      decoded_token = JsonWebToken.verify(token)
      email = decoded_token.dig(:payload, 'email')
      @current_user = User.includes(:features, :ticket_attachments).find_or_create_by(email_address: email)
    rescue StandardError => e
      Rails.logger.error("Authentication error: #{e.message}")
      nil
    end
  end

  private

  def token_from_header
    request.headers['Authorization']&.split(' ')&.last
  end
end

