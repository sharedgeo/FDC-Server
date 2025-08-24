class ChangeFeatureGeomType < ActiveRecord::Migration[7.1]
  def change
    change_column :features, :geom, :geometry, limit: { srid: 6344, type: "geometry" }
  end
end
