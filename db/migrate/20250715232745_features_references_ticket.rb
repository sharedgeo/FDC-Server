class FeaturesReferencesTicket < ActiveRecord::Migration[7.1]
  def change
    add_reference :features, :ticket, index: true, foreign_key: true
  end
end
