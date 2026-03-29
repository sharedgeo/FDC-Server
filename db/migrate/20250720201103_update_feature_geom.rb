# frozen_string_literal: true

class UpdateFeatureGeom < ActiveRecord::Migration[7.1]
  def change
    change_column :features, :geom, :geometry, limit: { srid: 6344, type: 'multi_polygon' },
                                               using: 'ST_GeomFromText(geom, 6344)'
    add_index :features, :geom, using: :gist
  end
end
