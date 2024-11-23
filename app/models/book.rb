# frozen_string_literal: true

# Book model
class Book < ApplicationRecord
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :title, uniqueness: true

  belongs_to :author
end
