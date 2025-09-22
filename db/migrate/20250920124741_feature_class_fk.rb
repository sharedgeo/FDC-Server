class FeatureClassFk < ActiveRecord::Migration[7.1]
  def change
    add_reference :features, :feature_class, type: :text, null: true, foreign_key: { to_table: :feature_class }

    execute <<-SQL
      INSERT INTO feature_class (id, code, name, color_mapserv, color_hex)
      VALUES ('reference', 'REF', 'Reference', '128 128 128', '#808080')
      ON CONFLICT (id) DO NOTHING;
    SQL

    execute "UPDATE features SET feature_class_id = 'reference' WHERE feature_class_id IS NULL"

    change_column_null :features, :feature_class_id, false
    change_column_default :features, :feature_class_id, 'reference'
  end
end
