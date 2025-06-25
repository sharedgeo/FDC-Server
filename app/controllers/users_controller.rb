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

      user = User.includes(:features, documents_attachments: :blob).find_by(email_address: email)

      if user
        user_data = user.as_json.merge(
          documents: user.documents.map do |doc|
            {
              filename: doc.filename.to_s,
              content_type: doc.content_type,
              byte_size: doc.byte_size,
              signed_id: doc.signed_id
            }
          end,
          features: user.features.map do |feature|
            {
              id: feature.id,
              geom: feature.geom
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
              byte_size: doc.byte_size,
              signed_id: doc.signed_id
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

  def create_features
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

      if feature_params[:features].present?
        feature_params[:features].each do |feature_data|
          Feature.create!(user:, geom: feature_data[:geom])
        end

        user_data = user.as_json.merge(
          documents: user.documents.map do |doc|
            {
              filename: doc.filename.to_s,
              content_type: doc.content_type,
              byte_size: doc.byte_size,
              signed_id: doc.signed_id
            }
          end,
          features: Feature.where(user:).map do |feature|
            {
              id: feature.id,
              geom: feature.geom
            }
          end
        )

        render json: { status: 'success', data: user_data }
      else
        message = 'features parameter is required and must be an array of feature objects.'
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

  def delete_features
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

      user = User.find_by(email_address: email)
      unless user
        message = "User with email '#{email}' not found."
        return render json: { status: 'error', message: message }, status: :not_found
      end

      feature_ids = delete_features_params[:feature_ids]
      if feature_ids.blank?
        message = 'feature_ids parameter is required and must be an array of feature IDs.'
        return render json: { status: 'error', message: message }, status: :bad_request
      end

      features_to_delete = user.features.where(id: feature_ids)
      deleted_count = features_to_delete.count

      if deleted_count.zero?
        return render json: { status: 'error', message: 'No matching features found for this user.' },
                      status: :not_found
      end

      features_to_delete.destroy_all

      render json: { status: 'success', message: "#{deleted_count} feature(s) deleted successfully." }
    rescue StandardError => e
      message = "Token is invalid. Reason: #{e.message}"
      Rails.logger.error("Error: #{e.message}: \n\t#{e.backtrace.join("\n\t")}")
      render json: { status: 'error', message: message }, status: :unauthorized
    end
  end

  def delete_documents
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

      user = User.find_by(email_address: email)
      unless user
        message = "User with email '#{email}' not found."
        return render json: { status: 'error', message: message }, status: :not_found
      end

      signed_ids = document_params[:document_signed_ids]
      if signed_ids.blank?
        message = 'document_signed_ids parameter is required and must be an array of signed IDs.'
        return render json: { status: 'error', message: message }, status: :bad_request
      end

      blobs = signed_ids.map { |sid| ActiveStorage::Blob.find_signed!(sid) }

      attachments = user.documents.where(blob_id: blobs.map(&:id))
      deleted_count = attachments.count

      if deleted_count.zero?
        return render json: { status: 'error', message: 'No matching documents found for this user.' },
                      status: :not_found
      end

      attachments.each(&:purge)

      render json: { status: 'success', message: "#{deleted_count} document(s) deleted successfully." }
    rescue ActiveRecord::RecordNotFound
      render json: { status: 'error', message: 'One or more documents were not found.' }, status: :not_found
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      render json: { status: 'error', message: 'One or more signed IDs are invalid.' }, status: :unprocessable_entity
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

  def feature_params
    params.permit(features: [:geom])
  end

  def delete_features_params
    params.permit(feature_ids: [])
  end
end
