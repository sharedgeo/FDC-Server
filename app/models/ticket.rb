# frozen_string_literal: true

class Ticket < ApplicationRecord
  include Geom4326

  has_many :bookmarks
  has_many :features
  has_many :ticket_attachments
  attr_accessor :bookmark_id

  def decorate(user)
    bookmark = bookmarks.find_by(user:)
    self.bookmark_id = bookmark&.id
  end

  def api_attributes
    tmp = attributes.except('geom')
    tmp[:bookmark_id] = bookmark_id
    tmp
  end

  def to_geojson
    geometry = RGeo::GeoJSON.encode(geom_as_4326)
    properties = api_attributes

    {
      type: 'Feature',
      geometry: geometry,
      properties: properties
    }
  end
end
