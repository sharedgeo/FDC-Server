# frozen_string_literal: true

class FeaturesController < ApplicationController
  before_action :authenticate_request!

  def create
    begin
      feature = current_user.features.create!(feature_params)
      render json: { status: 'success', message: 'Feature created successfully.', feature_id: feature.id },
             status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { status: 'error', message: e.message }, status: :unprocessable_entity
    rescue ActionController::ParameterMissing => e
      render json: { status: 'error', message: e.message }, status: :bad_request
    end
  end

  def update
    feature = current_user.features.find_by(id: params[:id])

    if feature
      if feature.update(feature_params)
        render json: { status: 'success', message: 'Feature updated successfully.' }, status: :ok
      else
        render json: { status: 'error', message: feature.errors.full_messages.to_sentence },
               status: :unprocessable_entity
      end
    else
      render json: { status: 'error', message: 'Feature not found.' }, status: :not_found
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
    params.require(:feature).permit(:ticket_id, :label, :notes, :feature_class_id, :unknown, geom: {})
  end
end
