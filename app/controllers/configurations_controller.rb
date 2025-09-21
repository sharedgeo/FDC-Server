# frozen_string_literal: true

class ConfigurationsController < ApplicationController
  before_action :authenticate_request!

  def show
    feature_classes = FeatureClass.all.map do |feature_class|
      feature_class.as_json(only: %i[id code name color_mapserv color_hex])
    end

    render json: {
      status: 'success',
      data: {
        feature_classes: feature_classes
      }
    }, status: :ok
  end
end