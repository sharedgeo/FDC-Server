# frozen_string_literal: true

class FeaturesController < ApplicationController
  before_action :authenticate_request!

  def create
    ticket = Ticket.find(feature_params[:ticket_id])
    geom = feature_params[:geom]

    return render json: { status: 'error', message: 'geom parameter is required.' }, status: :bad_request if geom.blank?

    begin
      feature = current_user.features.create!(geom: geom, ticket: ticket)
      render json: { status: 'success', message: 'Feature created successfully.', feature_id: feature.id },
             status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { status: 'error', message: e.message }, status: :unprocessable_entity
    end
  end

  def destroy
    feature = current_user.features.find_by(id: params[:id])

    if feature
      feature.destroy
      render json: { status: 'success', message: 'Feature deleted successfully.' }, status: :ok
    else
      render json: { status: 'error', message: 'Feature not found.' }, status: :not_found
    end
  end

  private

  def feature_params
    params.permit(:ticket_id, :geom)
  end
end
