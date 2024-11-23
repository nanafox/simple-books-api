class AddIndexOnTitleToBooks < ActiveRecord::Migration[7.2]
  def change
    add_index :books, :title
  end
end
