# db/migrate/20240906162222_change_book_id_to_uuid.rb
# frozen_string_literal: true

class ChangeBookIdToUuid < ActiveRecord::Migration[7.2]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    change_table :books do |t|
      t.remove :id

      t.uuid :id, default: 'gen_random_uuid()', null: false, primary_key: true
    end
  end
end
