class RebuildTicket < ActiveRecord::Migration[7.1]
  def change
    drop_table :tickets

    create_table :tickets do |t|
      t.text :ticket_no
      t.text :ticket_type
      t.text :ticket_url
      t.multi_polygon :geom, srid: 6344
      t.timestamp :publish_date
      t.timestamp :purge_date
      t.timestamp :created_at
      t.index :geom, using: :gist
    end
  end
end
