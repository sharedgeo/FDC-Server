# frozen_string_literal: true

class DocumentsController < ApplicationController
  before_action :authenticate_request!

  def create
    signed_ids = document_params[:document_signed_ids]
    if signed_ids.blank?
      return render json: { status: 'error', message: 'document_signed_ids parameter is required.' }, status: :bad_request
    end

    current_user.documents.attach(signed_ids)
    render json: { status: 'success', message: 'Document(s) attached successfully.' }, status: :ok
  end

  def destroy
    begin
      blob = ActiveStorage::Blob.find_signed!(params[:id])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      return render json: { status: 'error', message: 'Invalid signed ID.' }, status: :unprocessable_entity
    end

    attachment = current_user.documents_attachments.find_by(blob_id: blob.id)

    if attachment
      attachment.purge
      render json: { status: 'success', message: 'Document deleted successfully.' }, status: :ok
    else
      render json: { status: 'error', message: 'Document not found for this user.' }, status: :not_found
    end
  end

  private

  def document_params
    params.permit(document_signed_ids: [])
  end
end
