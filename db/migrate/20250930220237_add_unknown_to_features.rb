# frozen_string_literal: true

class AddUnknownToFeatures < ActiveRecord::Migration[7.1]
  def change
    add_column :features, :unknown, :boolean, default: false
  end
end
