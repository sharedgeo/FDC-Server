# frozen_string_literal: true

class ProfilesController < ApplicationController
  include Rails.application.routes.url_helpers
  before_action :authenticate_request!

  def show
    tickets = current_user.all_tickets.map do |ticket|
      documents = ticket.ticket_attachments.flat_map do |attachment|
        attachment.documents.map do |doc|
          {
            signed_id: doc.signed_id,
            filename: doc.filename.to_s,
            url: url_for(doc),
            content_type: doc.content_type,
            byte_size: doc.byte_size
          }
        end
      end

      ticket.as_json(only: %i[id ticket_no]).merge(
        features: ticket.features.where(user: current_user).as_json(only: %i[id geom]),
        documents: documents.select do |doc|
          current_user.ticket_attachments.joins(:documents_attachments)
                      .where(active_storage_attachments: { blob_id: ActiveStorage::Blob.find_signed(doc[:signed_id]).id })
                      .exists?
        end
      )
    end

    render json: {
      status: 'success',
      data: {
        id: current_user.id,
        email_address: current_user.email_address,
        tickets: tickets
      }
    }, status: :ok
  end
end
