# frozen_string_literal: true

class Feature < ApplicationRecord
  include Geom4326

  belongs_to :user
  belongs_to :ticket
  belongs_to :feature_class

  validates :geom, presence: true
  validates :label, length: { maximum: 50 }
  validates :notes, length: { maximum: 250 }

  def geom=(geojson)
    self[:geom] =
      if geojson.blank?
        nil
      elsif geojson.instance_of?(String)
        geojson
      else
        wgs84_factory = RGeo::Geographic.spherical_factory(srid: 4326)

        geom_4326 = RGeo::GeoJSON.decode( geojson, json_parser: :json, geo_factory: wgs84_factory)

        target_factory = RGeo::Cartesian.factory(srid: SridConstants::SRID_6344, proj4: :proj4)
        RGeo::Feature.cast(geom_4326, factory: target_factory, project: true)
      end
  end
end
