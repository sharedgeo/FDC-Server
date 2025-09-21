class FeatureClassFk < ActiveRecord::Migration[7.1]
  def change
    add_reference :features, :feature_class, type: :text, null: true, foreign_key: { to_table: :feature_class }

    # Set default value for existing records
    execute "UPDATE features SET feature_class_id = 'reference' WHERE feature_class_id IS NULL"

    # Now make the column non-null with default
    change_column_null :features, :feature_class_id, false
    change_column_default :features, :feature_class_id, 'reference'
  end
end
