# frozen_string_literal: true

class Ticket < ApplicationRecord

  def geom_as_4326
    self.class.select('st_transform(geom, 4326) as tmp_geom').find(id).tmp_geom
  rescue StandardError
    ''
  end

end
