# frozen_string_literal: true

class FeaturesController < ApplicationController
  before_action :authenticate_request!

  def create
    features_params = feature_params[:features]
    if features_params.blank?
      return render json: { status: 'error', message: 'features parameter is required.' }, status: :bad_request
    end

    begin
      current_user.features.create!(features_params)
      render json: { status: 'success', message: 'Feature(s) created successfully.' }, status: :ok
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
    params.permit(features: [:geom])
  end
end
