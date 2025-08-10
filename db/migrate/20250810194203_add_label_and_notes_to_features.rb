class AddLabelAndNotesToFeatures < ActiveRecord::Migration[7.1]
  def change
    add_column :features, :label, :string, limit: 50
    add_column :features, :notes, :string, limit: 250
  end
end
