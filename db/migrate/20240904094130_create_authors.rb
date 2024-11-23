class CreateAuthors < ActiveRecord::Migration[7.2]
  def change
    create_table :authors do |t|
      t.string :first_name
      t.string :last_name
      t.integer :age

      t.timestamps
    end
  end
end
