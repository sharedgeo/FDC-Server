class TicketAttachment < ActiveRecord::Migration[7.1]
  def change
    create_table :ticket_attachments do |t|
      t.references :user
      t.references :ticket
      t.timestamps
    end
  end
end
