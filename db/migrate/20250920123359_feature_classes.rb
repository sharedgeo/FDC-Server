class FeatureClasses < ActiveRecord::Migration[7.1]
  def change
    create_table :feature_class, id: false do |t|
      t.text :id, null: false, primary_key: true
      t.text :name, null: false
      t.text :code, null: false
      t.text :color_mapserv
      t.text :color_hex
    end
  end
end
