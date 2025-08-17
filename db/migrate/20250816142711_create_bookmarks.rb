class CreateBookmarks < ActiveRecord::Migration[7.1]
  def change
    create_table :bookmarks do |t|
      t.references :user
      t.references :ticket
      t.timestamps
    end
  end
end
