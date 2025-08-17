# frozen_string_literal: true

class Ticket < ApplicationRecord
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

  # FIXME: Decide where transform takes place
  def geom_as_4326
    self.class.select('st_transform(geom, 4326) as tmp_geom').find(id).tmp_geom
  rescue StandardError
    ''
  end
end
