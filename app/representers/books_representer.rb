# frozen_string_literal: true

# Serializer for book responses
class BooksRepresenter
  def initialize(books, request)
    @books = books
    @request = request
  end

  # rubocop:disable Metrics/MethodLength
  def as_json
    if books.respond_to?(:map)
      {
        message: action_message,
        success: true,
        total_books: Book.count,
        current_number: books.count,
        data: books.compact.map { |book| book_to_json(book) }
      }
    else
      {
        message: action_message,
        success: true,
        data: book_to_json(books)
      }
    end
  end

  # rubocop:enable Metrics/MetricLength

  private

  attr_reader :books, :request

  def book_to_json(book)
    {
      id: book.id,
      title: book.title,
      author_id: book.author.id,
      author_name: "#{book.author.first_name} #{book.author.last_name}",
      author_age: book.author.age,
      created_at: book.created_at.iso8601(3),
      updated_at: book.updated_at.iso8601(3)
    }
  end

  def action_message
    messages = {
      GET: books.respond_to?(:map) ? "Books retrieved successfully" : "Book retrieved successfully",
      POST: "Book created successfully",
      PUT: "Book updated successfully",
      PATCH: "Book updated successfully"
    }

    messages.fetch(request.method.to_sym, "Success")
  end
end
