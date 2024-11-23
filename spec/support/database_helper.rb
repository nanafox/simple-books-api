# frozen_string_literal: true

# spec/support/database_helper.rb
module DatabaseHelper
  def reset_primary_key_sequences
    ActiveRecord::Base.connection.reset_pk_sequence!('books')
    ActiveRecord::Base.connection.reset_pk_sequence!('authors')
  end
end
