# frozen_string_literal: true

class Ticket < ApplicationRecord
  has_many :features
  has_many :ticket_attachments

  def geom_as_4326
    self.class.select('st_transform(geom, 4326) as tmp_geom').find(id).tmp_geom
  rescue StandardError
    ''
  end
end
