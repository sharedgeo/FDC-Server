# frozen_string_literal: true

class ProfilesController < ApplicationController
  include Rails.application.routes.url_helpers
  before_action :authenticate_request!

  def show
    documents = current_user.documents.map do |doc|
      {
        signed_id: doc.signed_id,
        filename: doc.filename.to_s,
        url: url_for(doc),
        content_type: doc.content_type,
        byte_size: doc.byte_size
      }
    end

    render json: {
      status: 'success',
      data: {
        id: current_user.id,
        email_address: current_user.email_address,
        features: current_user.features.as_json(only: %i[id geom]),
        documents: documents
      }
    }, status: :ok
  end
end
