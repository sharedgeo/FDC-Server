# frozen_string_literal: true

class DocumentsController < ApplicationController
  before_action :authenticate_request!
  before_action :set_ticket_attachment, only: [:create]

  def create
    signed_ids = document_params[:document_signed_ids]
    if signed_ids.blank?
      return render json: { status: 'error', message: 'document_signed_ids parameter is required.' },
                    status: :bad_request
    end

    @ticket_attachment.documents.attach(signed_ids)
    render json: { status: 'success', message: 'Document(s) attached successfully.' }, status: :ok
  end

  def destroy
    blob = ActiveStorage::Blob.find_signed(params[:id])
    attachment = ActiveStorage::Attachment.find_by(blob_id: blob.id)

    if attachment&.record&.user == current_user
      attachment.purge
      if attachment.record.documents.empty? # last document
        attachment.record.destroy
      end
      render json: { status: 'success', message: 'Document deleted successfully.' }, status: :ok
    else
      render json: { status: 'error', message: 'Document not found or unauthorized.' }, status: :not_found
    end
  end

  private

  def set_ticket_attachment
    ticket = Ticket.find(document_params[:ticket_id])
    @ticket_attachment = current_user.ticket_attachments.find_or_create_by(ticket: ticket)
  end

  def document_params
    params.permit(:ticket_id, document_signed_ids: [])
  end
end
