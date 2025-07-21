# frozen_string_literal: true

class Feature < ApplicationRecord
  belongs_to :user
  belongs_to :ticket

  validates :geom, presence: true

  # Geom needs to be a postgis geom
  def geom=(geojson)
    self[:geom] =
      if geojson.blank?
        nil
      elsif geojson.instance_of?(String)
        geojson
      else
        RGeo::GeoJSON.decode(
          geojson, json_parser: :json,
                   geo_factory: RGeo::Geos.factory(srid: 6344)
        )
      end
  end
end
