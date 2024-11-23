class Author < ApplicationRecord
  has_many :books, dependent: :destroy
  validates_associated :books

  validates_presence_of :first_name, :last_name, :age

  validates :first_name, length: { minimum: 3, maximum: 100 }
  validates :last_name, length: { minimum: 3, maximum: 100 }
end
