# frozen_string_literal: true

class UsersController < ApplicationController
  def me
    token = token_from_header
    unless token
      message = 'No token provided in Authorization header.'
      return render json: { status: 'error', message: message }, status: :unauthorized
    end

    begin
      decoded_token = JsonWebToken.verify(token)
      email = decoded_token.dig(:payload, 'email')

      unless email
        message = 'Email not found in token payload.'
        return render json: { status: 'error', message: message }, status: :unprocessable_entity
      end

      user = User.includes(documents_attachments: :blob).find_by(email_address: email)

      if user
        user_data = user.as_json.merge(
          documents: user.documents.map do |doc|
            {
              filename: doc.filename.to_s,
              content_type: doc.content_type,
              byte_size: doc.byte_size
            }
          end
        )
        render json: { status: 'success', data: user_data }
      else
        message = "User with email '#{email}' not found."
        render json: { status: 'error', message: message }, status: :not_found
      end
    rescue StandardError => e
      message = "Token is invalid. Reason: #{e.message}"
      Rails.logger.error("Error: #{e.message}: \n\t#{e.backtrace.join("\n\t")}")
      render json: { status: 'error', message: message }, status: :unauthorized
    end
  end

  def create_documents
    token = token_from_header
    unless token
      message = 'No token provided in Authorization header.'
      return render json: { status: 'error', message: message }, status: :unauthorized
    end

    begin
      decoded_token = JsonWebToken.verify(token)
      email = decoded_token.dig(:payload, 'email')

      unless email
        message = 'Email not found in token payload.'
        return render json: { status: 'error', message: message }, status: :unprocessable_entity
      end

      user = User.find_or_create_by!(email_address: email)

      if document_params[:document_signed_ids].present?
        user.documents.attach(document_params[:document_signed_ids])

        user_data = user.as_json.merge(
          documents: user.documents.map do |doc|
            {
              filename: doc.filename.to_s,
              content_type: doc.content_type,
              byte_size: doc.byte_size
            }
          end
        )

        render json: { status: 'success', data: user_data }
      else
        message = 'document_signed_ids parameter is required and must be an array of signed IDs.'
        render json: { status: 'error', message: message }, status: :bad_request
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { status: 'error', message: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      message = "Token is invalid. Reason: #{e.message}"
      Rails.logger.error("Error: #{e.message}: \n\t#{e.backtrace.join("\n\t")}")
      render json: { status: 'error', message: message }, status: :unauthorized
    end
  end

  private

  def token_from_header
    request.headers['Authorization']&.split(' ')&.last
  end

  def document_params
    params.permit(document_signed_ids: [])
  end
end
