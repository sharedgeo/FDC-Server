# frozen_string_literal: true

class CreateFeatureTable < ActiveRecord::Migration[7.1]
  def change
    create_table :features do |t|
      t.references :user
      t.text :geom
      t.timestamps
    end
  end
end
