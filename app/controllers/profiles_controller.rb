# frozen_string_literal: true

class ProfilesController < ApplicationController
  include Rails.application.routes.url_helpers
  before_action :authenticate_request!

  # FIXME: Requirement needed. Current user can only access attachments and features they create
  def show
    tickets = current_user.all_tickets.map do |ticket|
      documents = ticket.ticket_attachments.where(user: current_user).flat_map do |attachment|
        # FIXME: url_for for url didn't add the path. Possible to revert rails_blob_url at some point.
        attachment.documents.map do |doc|
          {
            signed_id: doc.signed_id,
            filename: doc.filename.to_s,
            url: rails_blob_url(doc, script_name: ENV['RAILS_RELATIVE_URL_ROOT']),
            content_type: doc.content_type,
            byte_size: doc.byte_size
          }
        end
      end

      features = ticket.features.includes(:feature_class).where(user: current_user)
      feature_collection = RGeo::GeoJSON.encode(
        RGeo::GeoJSON::FeatureCollection.new(
          features.map do |feature|
            RGeo::GeoJSON::Feature.new(feature.geom_as_4326, feature.id,
                                       { id: feature.id,
                                         ticket_id: feature.ticket_id,
                                         ticket_no: feature.ticket.ticket_no,
                                         label: feature.label,
                                         feature_class_name: feature.feature_class.name,
                                         feature_class_id: feature.feature_class_id,
                                         feature_color_hex: feature.feature_class.color_hex,
                                         notes: feature.notes })
          end
        )
      )

      ticket.as_json(only: %i[id ticket_no], methods: :bookmark_id).merge(
        features: feature_collection,
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
