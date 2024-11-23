class CreateBooks < ActiveRecord::Migration[7.2]
  def change
    create_table :books do |t|
      t.belongs_to :author, index: true, foreign_key: true
      t.string :title

      t.timestamps
    end
  end
end
